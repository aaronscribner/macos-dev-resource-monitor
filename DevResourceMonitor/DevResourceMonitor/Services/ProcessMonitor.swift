import Foundation
import Combine
import Darwin

/// Represents CPU usage for a single core
struct CoreUsage: Identifiable {
    let id: Int  // Core index
    let usage: Double  // 0-100%
}

/// Service responsible for monitoring system processes and their resource usage
@MainActor
class ProcessMonitor: ObservableObject {
    @Published var processes: [ProcessInfo] = []
    @Published var isMonitoring: Bool = false
    @Published var lastUpdate: Date?
    @Published var totalSystemMemoryMB: Double = 0
    @Published var usedSystemMemoryMB: Double = 0
    @Published var perCoreUsage: [CoreUsage] = []

    private var timer: Timer?
    private var pollInterval: TimeInterval
    private var previousCPUInfo: [processor_info_t] = []
    private var previousCPUTicks: [[Int64]] = []

    init(pollInterval: TimeInterval = 5.0) {
        self.pollInterval = pollInterval
        self.totalSystemMemoryMB = Self.getSystemMemory()
        // Initialize per-core tracking
        initializeCPUTracking()
    }

    private func initializeCPUTracking() {
        let coreCount = ProcessInfo.systemCoreCount
        perCoreUsage = (0..<coreCount).map { CoreUsage(id: $0, usage: 0) }
        previousCPUTicks = Array(repeating: [0, 0, 0, 0], count: coreCount)
    }

    /// Start monitoring processes at the configured interval
    func startMonitoring() {
        guard !isMonitoring else {
            print("ProcessMonitor: Already monitoring, skipping start")
            return
        }
        print("ProcessMonitor: Starting monitoring with interval \(pollInterval)s")
        isMonitoring = true

        // Fetch immediately
        Task {
            await fetchProcesses()
        }

        // Then schedule periodic updates
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchProcesses()
            }
        }
    }

    /// Stop monitoring
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    /// Update the polling interval
    func updatePollInterval(_ interval: TimeInterval) {
        pollInterval = interval
        if isMonitoring {
            stopMonitoring()
            startMonitoring()
        }
    }

    /// Force an immediate refresh
    func refresh() async {
        await fetchProcesses()
    }

    /// Fetch current process list using ps command
    private func fetchProcesses() async {
        print("ProcessMonitor: Starting to fetch processes...")

        // Capture previous ticks before going to background thread
        let prevTicks = self.previousCPUTicks

        // Fetch processes, per-core CPU, and system memory in parallel
        let (fetchedProcesses, coreUsages, newTicks, usedMemory) = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let processes = Self.parseProcessList()
                let (cores, updatedTicks) = Self.fetchPerCoreCPU(previousTicks: prevTicks)
                let memoryUsed = Self.fetchSystemMemoryUsage()
                print("ProcessMonitor: Parsed \(processes.count) processes")
                continuation.resume(returning: (processes, cores, updatedTicks, memoryUsed))
            }
        }

        // Set these BEFORE processes, since processes triggers the ViewModel binding
        self.perCoreUsage = coreUsages
        self.previousCPUTicks = newTicks
        self.usedSystemMemoryMB = usedMemory
        self.lastUpdate = Date()
        self.processes = fetchedProcesses  // This triggers snapshot creation - must be last
        print("ProcessMonitor: Updated with \(fetchedProcesses.count) processes, totalCPU: \(self.totalCPU), usedMemory: \(usedMemory) MB")
    }

    /// Fetch per-core CPU usage using Mach host_processor_info
    nonisolated private static func fetchPerCoreCPU(previousTicks: [[Int64]]) -> ([CoreUsage], [[Int64]]) {
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )

        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            return ([], previousTicks)
        }

        var coreUsages: [CoreUsage] = []
        var newPreviousTicks: [[Int64]] = []
        let cpuLoadInfo = UnsafeBufferPointer(
            start: cpuInfo,
            count: Int(numCPUInfo)
        )

        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i

            let user = Int64(cpuLoadInfo[offset + Int(CPU_STATE_USER)])
            let system = Int64(cpuLoadInfo[offset + Int(CPU_STATE_SYSTEM)])
            let idle = Int64(cpuLoadInfo[offset + Int(CPU_STATE_IDLE)])
            let nice = Int64(cpuLoadInfo[offset + Int(CPU_STATE_NICE)])

            // Calculate delta from previous reading
            var usage: Double = 0
            if i < previousTicks.count {
                let prevTicks = previousTicks[i]
                let deltaUser = user - prevTicks[0]
                let deltaSystem = system - prevTicks[1]
                let deltaIdle = idle - prevTicks[2]
                let deltaNice = nice - prevTicks[3]

                let totalDelta = deltaUser + deltaSystem + deltaIdle + deltaNice
                if totalDelta > 0 {
                    let activeDelta = deltaUser + deltaSystem + deltaNice
                    usage = Double(activeDelta) / Double(totalDelta) * 100.0
                }
            }

            coreUsages.append(CoreUsage(id: i, usage: max(0, min(100, usage))))
            newPreviousTicks.append([user, system, idle, nice])
        }

        // Deallocate the memory
        let dataSize = Int(numCPUInfo) * MemoryLayout<integer_t>.size
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(dataSize))

        return (coreUsages, newPreviousTicks)
    }

    /// Parse process list from ps command output
    nonisolated private static func parseProcessList() -> [ProcessInfo] {
        // Use ps command to get process information
        // Format: pid, %cpu, rss (in KB), ppid, comm
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-axo", "pid,pcpu,rss,ppid,comm"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
        } catch {
            print("Failed to run ps command: \(error)")
            return []
        }

        // Read data BEFORE waitUntilExit to avoid deadlock when buffer fills
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        guard let output = String(data: data, encoding: .utf8) else {
            print("Failed to decode ps output")
            return []
        }

        print("ProcessMonitor: ps output length: \(output.count) chars")

        var processes: [ProcessInfo] = []
        let lines = output.components(separatedBy: "\n")

        // Skip header line
        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Parse the line - fields are separated by whitespace
            let components = trimmed.split(separator: " ", maxSplits: 4, omittingEmptySubsequences: true)
            guard components.count >= 5 else { continue }

            guard let pid = Int32(components[0]),
                  let cpu = Double(components[1]),
                  let rssKB = Double(components[2]),
                  let ppid = Int32(components[3]) else {
                continue
            }

            let commandPath = String(components[4])
            let name = Self.extractProcessName(from: commandPath)
            let memoryMB = rssKB / 1024.0

            let process = ProcessInfo(
                id: pid,
                name: name,
                commandPath: commandPath,
                cpuPercent: cpu,
                memoryMB: memoryMB,
                parentPID: ppid
            )
            processes.append(process)
        }

        return processes
    }

    /// Extract the process name from the command path
    nonisolated private static func extractProcessName(from commandPath: String) -> String {
        // Get the last component of the path
        let components = commandPath.components(separatedBy: "/")
        return components.last ?? commandPath
    }

    /// Get total system memory in MB
    private static func getSystemMemory() -> Double {
        var size: size_t = MemoryLayout<UInt64>.size
        var memory: UInt64 = 0

        let result = sysctlbyname("hw.memsize", &memory, &size, nil, 0)
        if result == 0 {
            return Double(memory) / (1024 * 1024)
        }
        return 0
    }

    /// Fetch actual system memory usage using Mach VM statistics
    nonisolated private static func fetchSystemMemoryUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) { statsPtr in
            statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return 0
        }

        let pageSize = Double(vm_kernel_page_size)

        // Calculate used memory matching Activity Monitor's "Memory Used":
        // App Memory (active + wired) + Compressed
        // Note: inactive memory is reclaimable and NOT counted as "used"
        let active = Double(stats.active_count) * pageSize
        let wired = Double(stats.wire_count) * pageSize
        let compressed = Double(stats.compressor_page_count) * pageSize

        let usedBytes = active + wired + compressed
        return usedBytes / (1024 * 1024)  // Convert to MB
    }
}

// MARK: - Filtering and Sorting

extension ProcessMonitor {
    /// Get processes sorted by CPU usage (descending)
    var processesByCPU: [ProcessInfo] {
        processes.sorted { $0.cpuPercent > $1.cpuPercent }
    }

    /// Get processes sorted by memory usage (descending)
    var processesByMemory: [ProcessInfo] {
        processes.sorted { $0.memoryMB > $1.memoryMB }
    }

    /// Get top N processes by CPU
    func topByCPU(_ count: Int) -> [ProcessInfo] {
        Array(processesByCPU.prefix(count))
    }

    /// Get top N processes by memory
    func topByMemory(_ count: Int) -> [ProcessInfo] {
        Array(processesByMemory.prefix(count))
    }

    /// Total CPU usage based on per-core kernel data (average across all cores)
    var totalCPU: Double {
        guard !perCoreUsage.isEmpty else { return 0 }
        return perCoreUsage.reduce(0) { $0 + $1.usage } / Double(perCoreUsage.count)
    }

    /// Total CPU from process summation (for category breakdown calculations)
    var totalProcessCPU: Double {
        processes.reduce(0) { $0 + $1.cpuPercent }
    }

    /// Total memory usage in MB (from system-level Mach API)
    var totalMemoryMB: Double {
        usedSystemMemoryMB
    }

    /// Total memory from process summation (for category breakdown calculations)
    var totalProcessMemoryMB: Double {
        processes.reduce(0) { $0 + $1.memoryMB }
    }

    /// Memory usage as percentage (based on actual system memory usage)
    var memoryPercent: Double {
        guard totalSystemMemoryMB > 0 else { return 0 }
        return (usedSystemMemoryMB / totalSystemMemoryMB) * 100
    }
}
