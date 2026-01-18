import Foundation

/// Represents a single process running on the system
struct ProcessInfo: Identifiable, Codable, Hashable {
    let id: Int32  // PID
    let name: String
    let commandPath: String
    var cpuPercent: Double
    var memoryMB: Double
    let parentPID: Int32
    var categoryID: String?
    var appName: String?  // Resolved friendly name (e.g., "VS Code" instead of "Electron")

    init(
        id: Int32,
        name: String,
        commandPath: String = "",
        cpuPercent: Double = 0,
        memoryMB: Double = 0,
        parentPID: Int32 = 0,
        categoryID: String? = nil,
        appName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.commandPath = commandPath
        self.cpuPercent = cpuPercent
        self.memoryMB = memoryMB
        self.parentPID = parentPID
        self.categoryID = categoryID
        self.appName = appName
    }

    /// Display name - uses appName if available, otherwise the process name
    var displayName: String {
        appName ?? name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ProcessInfo, rhs: ProcessInfo) -> Bool {
        lhs.id == rhs.id
    }

    /// Get the number of CPU cores on the system
    static var systemCoreCount: Int {
        Foundation.ProcessInfo.processInfo.processorCount
    }
}

/// Aggregated usage for a group of processes (e.g., all VS Code processes)
struct GroupedProcessInfo: Identifiable {
    let id: String  // appName or category ID
    let name: String
    let processes: [ProcessInfo]

    var totalCPU: Double {
        processes.reduce(0) { $0 + $1.cpuPercent }
    }

    var totalMemoryMB: Double {
        processes.reduce(0) { $0 + $1.memoryMB }
    }

    var processCount: Int {
        processes.count
    }
}
