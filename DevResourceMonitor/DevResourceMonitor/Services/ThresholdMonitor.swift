import Foundation
import Combine

/// Monitors resource usage and triggers events when thresholds are exceeded
@MainActor
class ThresholdMonitor: ObservableObject {
    @Published var cpuThreshold: Double
    @Published var memoryThreshold: Double
    @Published var isEnabled: Bool
    @Published var lastEvent: ThresholdEvent?

    private var cooldownActive = false
    private var cooldownDuration: TimeInterval
    private var cooldownTimer: Timer?

    private let historyManager: HistoryManager
    private let notificationService: NotificationService

    init(
        historyManager: HistoryManager,
        notificationService: NotificationService,
        cpuThreshold: Double = 80.0,
        memoryThreshold: Double = 80.0,
        cooldownDuration: TimeInterval = 60.0,
        isEnabled: Bool = true
    ) {
        self.historyManager = historyManager
        self.notificationService = notificationService
        self.cpuThreshold = cpuThreshold
        self.memoryThreshold = memoryThreshold
        self.cooldownDuration = cooldownDuration
        self.isEnabled = isEnabled

        // Load last event
        self.lastEvent = historyManager.lastEvent()
    }

    /// Check if thresholds are exceeded and trigger events if needed
    func check(snapshot: ResourceSnapshot, allProcesses: [ProcessInfo]) {
        guard isEnabled, !cooldownActive else { return }

        // Check CPU threshold (using normalized percentage of total system capacity)
        if snapshot.cpuPercent > cpuThreshold {
            let event = ThresholdEvent(
                triggerType: .cpu,
                triggerValue: snapshot.cpuPercent,
                threshold: cpuThreshold,
                allProcesses: allProcesses
            )
            triggerEvent(event)
            return  // Only trigger one event at a time
        }

        // Check memory threshold
        if snapshot.memoryPercent > memoryThreshold {
            let event = ThresholdEvent(
                triggerType: .memory,
                triggerValue: snapshot.memoryPercent,
                threshold: memoryThreshold,
                allProcesses: allProcesses
            )
            triggerEvent(event)
        }
    }

    /// Trigger a threshold event
    private func triggerEvent(_ event: ThresholdEvent) {
        // Save event
        historyManager.saveEvent(event)
        lastEvent = event

        // Send notification
        notificationService.sendThresholdAlert(event)

        // Start cooldown
        startCooldown()
    }

    /// Start the cooldown period
    private func startCooldown() {
        cooldownActive = true

        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: cooldownDuration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.cooldownActive = false
            }
        }
    }

    /// Update settings
    func updateSettings(
        cpuThreshold: Double? = nil,
        memoryThreshold: Double? = nil,
        cooldownDuration: TimeInterval? = nil,
        isEnabled: Bool? = nil
    ) {
        if let cpu = cpuThreshold {
            self.cpuThreshold = cpu
        }
        if let memory = memoryThreshold {
            self.memoryThreshold = memory
        }
        if let cooldown = cooldownDuration {
            self.cooldownDuration = cooldown
        }
        if let enabled = isEnabled {
            self.isEnabled = enabled
        }
    }

    /// Time since last event
    var timeSinceLastEvent: String? {
        guard let event = lastEvent else { return nil }

        let interval = Date().timeIntervalSince(event.timestamp)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}
