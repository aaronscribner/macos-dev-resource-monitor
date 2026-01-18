import Foundation

/// Records when a threshold breach occurs
struct ThresholdEvent: Identifiable, Codable, Hashable {
    static func == (lhs: ThresholdEvent, rhs: ThresholdEvent) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    let id: UUID
    let timestamp: Date
    let triggerType: TriggerType
    let triggerValue: Double
    let threshold: Double
    let allProcesses: [ProcessInfo]  // Snapshot of all processes at time of breach

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        triggerType: TriggerType,
        triggerValue: Double,
        threshold: Double,
        allProcesses: [ProcessInfo]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.triggerType = triggerType
        self.triggerValue = triggerValue
        self.threshold = threshold
        self.allProcesses = allProcesses
    }

    enum TriggerType: String, Codable, CaseIterable {
        case cpu = "CPU"
        case memory = "Memory"

        var displayName: String {
            rawValue
        }

        var icon: String {
            switch self {
            case .cpu: return "cpu"
            case .memory: return "memorychip"
            }
        }
    }

    /// Human-readable description of the event
    var description: String {
        let valueStr = String(format: "%.1f%%", triggerValue)
        let thresholdStr = String(format: "%.1f%%", threshold)
        return "\(triggerType.displayName) reached \(valueStr) (threshold: \(thresholdStr))"
    }

    /// Top processes at time of breach, sorted by the trigger type's metric
    var topProcessesByTrigger: [ProcessInfo] {
        switch triggerType {
        case .cpu:
            return allProcesses.sorted { $0.cpuPercent > $1.cpuPercent }
        case .memory:
            return allProcesses.sorted { $0.memoryMB > $1.memoryMB }
        }
    }
}

/// Container for storing events (used for JSON serialization)
struct ThresholdEventsContainer: Codable {
    var events: [ThresholdEvent]
}
