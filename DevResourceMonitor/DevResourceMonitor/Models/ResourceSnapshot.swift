import Foundation

/// A point-in-time snapshot of system resource usage
struct ResourceSnapshot: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let totalCPU: Double  // Average CPU across all cores (0-100%)
    let totalMemoryMB: Double
    let totalSystemMemoryMB: Double
    let cpuCoreCount: Int
    let categoryBreakdown: [String: ResourceUsage]
    let topProcesses: [ProcessInfo]

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        totalCPU: Double,
        totalMemoryMB: Double,
        totalSystemMemoryMB: Double,
        cpuCoreCount: Int = ProcessInfo.systemCoreCount,
        categoryBreakdown: [String: ResourceUsage],
        topProcesses: [ProcessInfo]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.totalCPU = totalCPU
        self.totalMemoryMB = totalMemoryMB
        self.totalSystemMemoryMB = totalSystemMemoryMB
        self.cpuCoreCount = cpuCoreCount
        self.categoryBreakdown = categoryBreakdown
        self.topProcesses = topProcesses
    }

    /// CPU usage as a percentage of total system capacity (0-100%)
    var cpuPercent: Double {
        totalCPU  // Already normalized to 0-100% from per-core average
    }

    /// Memory usage as a percentage of total system memory
    var memoryPercent: Double {
        guard totalSystemMemoryMB > 0 else { return 0 }
        return (totalMemoryMB / totalSystemMemoryMB) * 100
    }
}

/// Resource usage breakdown for a category or app
struct ResourceUsage: Codable {
    let cpuPercent: Double
    let memoryMB: Double
    let processCount: Int

    init(cpuPercent: Double = 0, memoryMB: Double = 0, processCount: Int = 0) {
        self.cpuPercent = cpuPercent
        self.memoryMB = memoryMB
        self.processCount = processCount
    }

    static func + (lhs: ResourceUsage, rhs: ResourceUsage) -> ResourceUsage {
        ResourceUsage(
            cpuPercent: lhs.cpuPercent + rhs.cpuPercent,
            memoryMB: lhs.memoryMB + rhs.memoryMB,
            processCount: lhs.processCount + rhs.processCount
        )
    }
}

/// Category usage with additional metadata for display
struct CategoryUsage: Identifiable {
    let id: String  // category ID
    let name: String
    let color: String
    let usage: ResourceUsage
    let processes: [ProcessInfo]

    var cpuPercent: Double { usage.cpuPercent }
    var memoryMB: Double { usage.memoryMB }
    var processCount: Int { usage.processCount }
}
