import Foundation

/// View model for trend analysis
@MainActor
class TrendsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var categoryTrends: [CategoryTrend] = []
    @Published var appTrends: [AppTrend] = []
    @Published var isLoading: Bool = false

    // MARK: - Services

    private let historyManager: HistoryManager
    private let categories: [AppCategory]

    // MARK: - Initialization

    init(historyManager: HistoryManager, categories: [AppCategory]) {
        self.historyManager = historyManager
        self.categories = categories
    }

    // MARK: - Data Loading

    func loadTrends() {
        isLoading = true

        Task {
            // Load data for current and previous week
            let currentWeekSnapshots = await loadSnapshots(daysAgo: 0, duration: 7)
            let previousWeekSnapshots = await loadSnapshots(daysAgo: 7, duration: 7)

            // Calculate category trends
            categoryTrends = calculateCategoryTrends(
                current: currentWeekSnapshots,
                previous: previousWeekSnapshots
            )

            // Calculate app trends
            appTrends = calculateAppTrends(
                current: currentWeekSnapshots,
                previous: previousWeekSnapshots
            )

            isLoading = false
        }
    }

    private func loadSnapshots(daysAgo: Int, duration: Int) async -> [ResourceSnapshot] {
        let manager = self.historyManager
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let endDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -duration, to: endDate) ?? endDate

                let snapshots = manager.loadSnapshots(from: startDate, to: endDate)
                continuation.resume(returning: snapshots)
            }
        }
    }

    // MARK: - Trend Calculations

    private func calculateCategoryTrends(
        current: [ResourceSnapshot],
        previous: [ResourceSnapshot]
    ) -> [CategoryTrend] {
        var trends: [CategoryTrend] = []

        for category in categories {
            let currentAvgCPU = averageCPU(for: category.id, in: current)
            let previousAvgCPU = averageCPU(for: category.id, in: previous)

            let currentAvgMemory = averageMemory(for: category.id, in: current)
            let previousAvgMemory = averageMemory(for: category.id, in: previous)

            let cpuChange = calculatePercentChange(from: previousAvgCPU, to: currentAvgCPU)
            let memoryChange = calculatePercentChange(from: previousAvgMemory, to: currentAvgMemory)

            trends.append(CategoryTrend(
                categoryID: category.id,
                categoryName: category.name,
                categoryColor: category.color,
                currentWeekAvgCPU: currentAvgCPU,
                previousWeekAvgCPU: previousAvgCPU,
                cpuPercentChange: cpuChange,
                cpuTrend: trendDirection(cpuChange),
                currentWeekAvgMemoryMB: currentAvgMemory,
                previousWeekAvgMemoryMB: previousAvgMemory,
                memoryPercentChange: memoryChange,
                memoryTrend: trendDirection(memoryChange)
            ))
        }

        // Sort by absolute change (most significant first)
        return trends.sorted { abs($0.cpuPercentChange) > abs($1.cpuPercentChange) }
    }

    private func calculateAppTrends(
        current: [ResourceSnapshot],
        previous: [ResourceSnapshot]
    ) -> [AppTrend] {
        // Aggregate by app name from top processes
        var currentAppUsage: [String: (cpu: Double, memory: Double, count: Int)] = [:]
        var previousAppUsage: [String: (cpu: Double, memory: Double, count: Int)] = [:]

        for snapshot in current {
            for process in snapshot.topProcesses {
                let appName = process.appName ?? process.name
                let existing = currentAppUsage[appName] ?? (0, 0, 0)
                currentAppUsage[appName] = (
                    existing.cpu + process.cpuPercent,
                    existing.memory + process.memoryMB,
                    existing.count + 1
                )
            }
        }

        for snapshot in previous {
            for process in snapshot.topProcesses {
                let appName = process.appName ?? process.name
                let existing = previousAppUsage[appName] ?? (0, 0, 0)
                previousAppUsage[appName] = (
                    existing.cpu + process.cpuPercent,
                    existing.memory + process.memoryMB,
                    existing.count + 1
                )
            }
        }

        // Calculate trends for apps that appear in both weeks
        let allApps = Set(currentAppUsage.keys).union(previousAppUsage.keys)
        var trends: [AppTrend] = []

        for appName in allApps {
            let current = currentAppUsage[appName]
            let previous = previousAppUsage[appName]

            let currentAvgCPU = current.map { $0.cpu / Double($0.count) } ?? 0
            let previousAvgCPU = previous.map { $0.cpu / Double($0.count) } ?? 0

            let currentAvgMemory = current.map { $0.memory / Double($0.count) } ?? 0
            let previousAvgMemory = previous.map { $0.memory / Double($0.count) } ?? 0

            let cpuChange = calculatePercentChange(from: previousAvgCPU, to: currentAvgCPU)
            let memoryChange = calculatePercentChange(from: previousAvgMemory, to: currentAvgMemory)

            // Only include apps with meaningful usage
            if currentAvgCPU > 0.1 || previousAvgCPU > 0.1 {
                trends.append(AppTrend(
                    appName: appName,
                    currentWeekAvgCPU: currentAvgCPU,
                    previousWeekAvgCPU: previousAvgCPU,
                    cpuPercentChange: cpuChange,
                    cpuTrend: trendDirection(cpuChange),
                    currentWeekAvgMemoryMB: currentAvgMemory,
                    previousWeekAvgMemoryMB: previousAvgMemory,
                    memoryPercentChange: memoryChange,
                    memoryTrend: trendDirection(memoryChange)
                ))
            }
        }

        return trends.sorted { abs($0.cpuPercentChange) > abs($1.cpuPercentChange) }
    }

    // MARK: - Helper Methods

    private func averageCPU(for categoryID: String, in snapshots: [ResourceSnapshot]) -> Double {
        let values = snapshots.compactMap { $0.categoryBreakdown[categoryID]?.cpuPercent }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func averageMemory(for categoryID: String, in snapshots: [ResourceSnapshot]) -> Double {
        let values = snapshots.compactMap { $0.categoryBreakdown[categoryID]?.memoryMB }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func calculatePercentChange(from previous: Double, to current: Double) -> Double {
        guard previous > 0 else {
            return current > 0 ? 100 : 0
        }
        return ((current - previous) / previous) * 100
    }

    private func trendDirection(_ percentChange: Double) -> TrendDirection {
        if percentChange > 5 {
            return .up
        } else if percentChange < -5 {
            return .down
        } else {
            return .stable
        }
    }
}

// MARK: - Trend Models

enum TrendDirection: String {
    case up = "up"
    case down = "down"
    case stable = "stable"

    var icon: String {
        switch self {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .up: return "#FF3B30"  // Red for increase (bad for resources)
        case .down: return "#34C759"  // Green for decrease (good)
        case .stable: return "#8E8E93"  // Gray for stable
        }
    }
}

struct CategoryTrend: Identifiable {
    let id = UUID()
    let categoryID: String
    let categoryName: String
    let categoryColor: String

    let currentWeekAvgCPU: Double
    let previousWeekAvgCPU: Double
    let cpuPercentChange: Double
    let cpuTrend: TrendDirection

    let currentWeekAvgMemoryMB: Double
    let previousWeekAvgMemoryMB: Double
    let memoryPercentChange: Double
    let memoryTrend: TrendDirection

    var summary: String {
        if cpuTrend == .stable && memoryTrend == .stable {
            return "Usage is stable"
        }

        var parts: [String] = []

        if cpuTrend != .stable {
            let direction = cpuTrend == .up ? "up" : "down"
            parts.append("CPU \(direction) \(String(format: "%.0f", abs(cpuPercentChange)))%")
        }

        if memoryTrend != .stable {
            let direction = memoryTrend == .up ? "up" : "down"
            parts.append("Memory \(direction) \(String(format: "%.0f", abs(memoryPercentChange)))%")
        }

        return parts.joined(separator: ", ")
    }
}

struct AppTrend: Identifiable {
    let id = UUID()
    let appName: String

    let currentWeekAvgCPU: Double
    let previousWeekAvgCPU: Double
    let cpuPercentChange: Double
    let cpuTrend: TrendDirection

    let currentWeekAvgMemoryMB: Double
    let previousWeekAvgMemoryMB: Double
    let memoryPercentChange: Double
    let memoryTrend: TrendDirection

    var summary: String {
        if cpuTrend == .stable && memoryTrend == .stable {
            return "Usage is stable"
        }

        var parts: [String] = []

        if cpuTrend != .stable {
            let direction = cpuTrend == .up ? "up" : "down"
            parts.append("CPU \(direction) \(String(format: "%.0f", abs(cpuPercentChange)))%")
        }

        if memoryTrend != .stable {
            let direction = memoryTrend == .up ? "up" : "down"
            parts.append("Memory \(direction) \(String(format: "%.0f", abs(memoryPercentChange)))%")
        }

        return parts.joined(separator: ", ")
    }
}
