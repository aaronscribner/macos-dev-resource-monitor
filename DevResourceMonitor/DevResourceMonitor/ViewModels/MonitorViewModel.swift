import Foundation
import Combine
import SwiftUI

/// Main view model that coordinates monitoring, aggregation, and UI state
@MainActor
class MonitorViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var processes: [ProcessInfo] = []
    @Published var categoryUsages: [CategoryUsage] = []
    @Published var groupedByApp: [GroupedProcessInfo] = []
    @Published var currentSnapshot: ResourceSnapshot?
    @Published var isMonitoring: Bool = false
    @Published var lastUpdate: Date?

    @Published var viewMode: AppSettings.ViewMode = .grouped
    @Published var sortBy: SortOption = .cpu

    // MARK: - Services

    let processMonitor: ProcessMonitor
    let resourceAggregator: ResourceAggregator
    let historyManager: HistoryManager
    let thresholdMonitor: ThresholdMonitor
    let notificationService: NotificationService

    // MARK: - Settings

    @Published var settings: AppSettings

    // MARK: - Categories

    @Published var categories: [AppCategory]

    private var cancellables = Set<AnyCancellable>()
    private var snapshotTimer: Timer?

    // MARK: - Initialization

    init() {
        // Initialize services first
        let hm = HistoryManager()
        let ns = NotificationService()

        // Load settings and categories
        let loadedSettings = hm.loadSettings()
        let loadedCategories = hm.loadCategories() ?? AppCategory.defaultCategories

        // Now assign to stored properties
        self.historyManager = hm
        self.notificationService = ns
        self.settings = loadedSettings
        self.categories = loadedCategories

        // Initialize monitors using loaded values
        self.processMonitor = ProcessMonitor(pollInterval: loadedSettings.pollIntervalSeconds)
        self.resourceAggregator = ResourceAggregator(categories: loadedCategories)

        self.thresholdMonitor = ThresholdMonitor(
            historyManager: hm,
            notificationService: ns,
            cpuThreshold: loadedSettings.cpuThreshold,
            memoryThreshold: loadedSettings.memoryThreshold,
            cooldownDuration: loadedSettings.thresholdCooldownSeconds,
            isEnabled: loadedSettings.thresholdsEnabled
        )

        // Configure notification service
        ns.updateSettings(
            notificationsEnabled: loadedSettings.notificationsEnabled,
            soundEnabled: loadedSettings.soundEnabled
        )
        ns.requestAuthorization()
        ns.registerCategories()

        // Set up subscriptions
        setupSubscriptions()

        // Cleanup old data
        hm.cleanup(keepDays: loadedSettings.historyRetentionDays)

        // Start monitoring automatically
        startMonitoring()
    }

    // MARK: - Subscriptions

    private func setupSubscriptions() {
        // When process monitor updates, aggregate the data
        processMonitor.$processes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] processes in
                self?.handleProcessUpdate(processes)
            }
            .store(in: &cancellables)

        processMonitor.$isMonitoring
            .assign(to: &$isMonitoring)

        processMonitor.$lastUpdate
            .assign(to: &$lastUpdate)
    }

    // MARK: - Process Updates

    private func handleProcessUpdate(_ processes: [ProcessInfo]) {
        print("MonitorViewModel: Received \(processes.count) processes")
        self.processes = processes

        // Aggregate by category
        categoryUsages = resourceAggregator.groupByCategory(processes)
        print("MonitorViewModel: Created \(categoryUsages.count) category usages")

        // Group by app
        groupedByApp = resourceAggregator.groupByApp(processes)

        // Create snapshot
        let snapshot = resourceAggregator.createSnapshot(
            from: processes,
            totalSystemMemoryMB: processMonitor.totalSystemMemoryMB,
            totalCPU: processMonitor.totalCPU,
            totalMemoryMB: processMonitor.totalMemoryMB
        )
        currentSnapshot = snapshot
        print("MonitorViewModel: Snapshot created - CPU: \(snapshot.totalCPU), Memory: \(snapshot.totalMemoryMB) MB")

        // Check thresholds
        thresholdMonitor.check(snapshot: snapshot, allProcesses: processes)
    }

    // MARK: - Control Methods

    func startMonitoring() {
        processMonitor.startMonitoring()

        // Start periodic snapshot saving (every minute)
        snapshotTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.saveCurrentSnapshot()
            }
        }
    }

    func stopMonitoring() {
        processMonitor.stopMonitoring()
        snapshotTimer?.invalidate()
        snapshotTimer = nil
    }

    func refresh() async {
        await processMonitor.refresh()
    }

    private func saveCurrentSnapshot() {
        guard let snapshot = currentSnapshot else { return }
        historyManager.saveSnapshot(snapshot)
    }

    // MARK: - Settings

    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings

        // Update poll interval
        processMonitor.updatePollInterval(newSettings.pollIntervalSeconds)

        // Update threshold monitor
        thresholdMonitor.updateSettings(
            cpuThreshold: newSettings.cpuThreshold,
            memoryThreshold: newSettings.memoryThreshold,
            cooldownDuration: newSettings.thresholdCooldownSeconds,
            isEnabled: newSettings.thresholdsEnabled
        )

        // Update notification service
        notificationService.updateSettings(
            notificationsEnabled: newSettings.notificationsEnabled,
            soundEnabled: newSettings.soundEnabled
        )

        // Save settings
        historyManager.saveSettings(newSettings)
    }

    // MARK: - Categories

    func updateCategories(_ newCategories: [AppCategory]) {
        categories = newCategories
        resourceAggregator.updateCategories(newCategories)
        historyManager.saveCategories(newCategories)

        // Re-aggregate with new categories
        handleProcessUpdate(processes)
    }

    // MARK: - Computed Properties

    /// Raw CPU usage (can exceed 100% on multi-core systems)
    var totalCPU: Double {
        currentSnapshot?.totalCPU ?? 0
    }

    /// CPU usage as percentage of total system capacity (0-100%)
    var cpuPercent: Double {
        currentSnapshot?.cpuPercent ?? 0
    }

    /// Number of CPU cores
    var cpuCoreCount: Int {
        currentSnapshot?.cpuCoreCount ?? ProcessInfo.systemCoreCount
    }

    var totalMemoryMB: Double {
        currentSnapshot?.totalMemoryMB ?? 0
    }

    var memoryPercent: Double {
        currentSnapshot?.memoryPercent ?? 0
    }

    var totalSystemMemoryMB: Double {
        processMonitor.totalSystemMemoryMB
    }

    /// Per-core CPU usage
    var perCoreUsage: [CoreUsage] {
        processMonitor.perCoreUsage
    }

    var sortedCategoryUsages: [CategoryUsage] {
        switch sortBy {
        case .cpu:
            return categoryUsages.sorted { $0.cpuPercent > $1.cpuPercent }
        case .memory:
            return categoryUsages.sorted { $0.memoryMB > $1.memoryMB }
        case .name:
            return categoryUsages.sorted { $0.name < $1.name }
        }
    }

    var sortedGroupedByApp: [GroupedProcessInfo] {
        switch sortBy {
        case .cpu:
            return groupedByApp.sorted { $0.totalCPU > $1.totalCPU }
        case .memory:
            return groupedByApp.sorted { $0.totalMemoryMB > $1.totalMemoryMB }
        case .name:
            return groupedByApp.sorted { $0.name < $1.name }
        }
    }

    // MARK: - Sorting

    enum SortOption: String, CaseIterable {
        case cpu = "CPU"
        case memory = "Memory"
        case name = "Name"
    }
}
