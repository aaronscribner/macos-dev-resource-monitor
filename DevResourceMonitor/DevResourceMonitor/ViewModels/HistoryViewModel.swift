import Foundation
import Combine

/// View model for historical data display
@MainActor
class HistoryViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var snapshots: [ResourceSnapshot] = []
    @Published var timeRange: TimeRange = .lastHour
    @Published var isLoading: Bool = false

    // MARK: - Services

    private let historyManager: HistoryManager

    // MARK: - Time Ranges

    enum TimeRange: String, CaseIterable {
        case lastHour = "1H"
        case last6Hours = "6H"
        case last24Hours = "24H"
        case last7Days = "7D"
        case last30Days = "30D"

        var displayName: String {
            switch self {
            case .lastHour: return "Last Hour"
            case .last6Hours: return "Last 6 Hours"
            case .last24Hours: return "Last 24 Hours"
            case .last7Days: return "Last 7 Days"
            case .last30Days: return "Last 30 Days"
            }
        }

        var hours: Int {
            switch self {
            case .lastHour: return 1
            case .last6Hours: return 6
            case .last24Hours: return 24
            case .last7Days: return 24 * 7
            case .last30Days: return 24 * 30
            }
        }
    }

    // MARK: - Initialization

    init(historyManager: HistoryManager) {
        self.historyManager = historyManager
    }

    // MARK: - Data Loading

    func loadData() {
        isLoading = true

        // Capture values before entering async closure to avoid main actor isolation issues
        let manager = self.historyManager
        let hours = self.timeRange.hours

        Task {
            let loaded = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let data = manager.loadSnapshots(lastHours: hours)
                    continuation.resume(returning: data)
                }
            }

            self.snapshots = loaded
            self.isLoading = false
        }
    }

    func setTimeRange(_ range: TimeRange) {
        timeRange = range
        loadData()
    }

    // MARK: - Data Aggregation

    /// Get snapshots aggregated into time buckets for chart display
    func aggregatedSnapshots(bucketCount: Int = 30) -> [AggregatedSnapshot] {
        guard !snapshots.isEmpty else { return [] }

        let startTime = snapshots.first!.timestamp
        let endTime = snapshots.last!.timestamp
        let totalDuration = endTime.timeIntervalSince(startTime)

        guard totalDuration > 0 else { return [] }

        let bucketDuration = totalDuration / Double(bucketCount)
        var buckets: [[ResourceSnapshot]] = Array(repeating: [], count: bucketCount)

        for snapshot in snapshots {
            let offset = snapshot.timestamp.timeIntervalSince(startTime)
            let bucketIndex = min(Int(offset / bucketDuration), bucketCount - 1)
            buckets[bucketIndex].append(snapshot)
        }

        return buckets.enumerated().compactMap { index, bucket in
            guard !bucket.isEmpty else { return nil }

            let timestamp = startTime.addingTimeInterval(Double(index) * bucketDuration + bucketDuration / 2)
            let avgCPU = bucket.reduce(0.0) { $0 + $1.totalCPU } / Double(bucket.count)
            let avgMemory = bucket.reduce(0.0) { $0 + $1.totalMemoryMB } / Double(bucket.count)

            // Aggregate category breakdowns
            var categoryTotals: [String: (cpu: Double, memory: Double, count: Int)] = [:]
            for snapshot in bucket {
                for (categoryID, usage) in snapshot.categoryBreakdown {
                    let current = categoryTotals[categoryID] ?? (0, 0, 0)
                    categoryTotals[categoryID] = (
                        current.cpu + usage.cpuPercent,
                        current.memory + usage.memoryMB,
                        current.count + 1
                    )
                }
            }

            let categoryBreakdown = categoryTotals.mapValues { total in
                ResourceUsage(
                    cpuPercent: total.cpu / Double(total.count),
                    memoryMB: total.memory / Double(total.count),
                    processCount: 0  // Not meaningful for aggregates
                )
            }

            return AggregatedSnapshot(
                timestamp: timestamp,
                avgCPU: avgCPU,
                avgMemoryMB: avgMemory,
                categoryBreakdown: categoryBreakdown,
                snapshotCount: bucket.count
            )
        }
    }

    /// Get peak usage values
    var peakCPU: Double {
        snapshots.map { $0.totalCPU }.max() ?? 0
    }

    var peakMemoryMB: Double {
        snapshots.map { $0.totalMemoryMB }.max() ?? 0
    }

    var avgCPU: Double {
        guard !snapshots.isEmpty else { return 0 }
        return snapshots.reduce(0.0) { $0 + $1.totalCPU } / Double(snapshots.count)
    }

    var avgMemoryMB: Double {
        guard !snapshots.isEmpty else { return 0 }
        return snapshots.reduce(0.0) { $0 + $1.totalMemoryMB } / Double(snapshots.count)
    }
}

/// Aggregated snapshot for chart display
struct AggregatedSnapshot: Identifiable {
    let id = UUID()
    let timestamp: Date
    let avgCPU: Double
    let avgMemoryMB: Double
    let categoryBreakdown: [String: ResourceUsage]
    let snapshotCount: Int
}
