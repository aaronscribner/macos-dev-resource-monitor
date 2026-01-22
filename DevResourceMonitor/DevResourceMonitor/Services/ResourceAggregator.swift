import Foundation

/// Service for grouping and aggregating process data by category
class ResourceAggregator {
    private var categories: [AppCategory]

    init(categories: [AppCategory] = AppCategory.defaultCategories) {
        self.categories = categories
    }

    /// Update the category definitions
    func updateCategories(_ categories: [AppCategory]) {
        self.categories = categories
    }

    /// Get only enabled categories
    private var enabledCategories: [AppCategory] {
        categories.filter { $0.isEnabled }
    }

    /// Group processes by their matched category (only enabled categories)
    func groupByCategory(_ processes: [ProcessInfo]) -> [CategoryUsage] {
        var grouped: [String: [ProcessInfo]] = [:]

        // Initialize enabled categories with empty arrays
        for category in enabledCategories {
            grouped[category.id] = []
        }

        // Assign each process to a category (only if category is enabled)
        for process in processes {
            var enrichedProcess = process

            if let (categoryID, appName) = findCategoryAndApp(for: process) {
                enrichedProcess.categoryID = categoryID
                enrichedProcess.appName = appName
                grouped[categoryID, default: []].append(enrichedProcess)
            } else {
                // Only add to "other" if it's enabled
                if categories.first(where: { $0.id == "other" })?.isEnabled == true {
                    enrichedProcess.categoryID = "other"
                    grouped["other", default: []].append(enrichedProcess)
                }
            }
        }

        // Convert to CategoryUsage objects (only enabled categories)
        return enabledCategories.compactMap { category in
            guard let procs = grouped[category.id] else { return nil }

            let usage = ResourceUsage(
                cpuPercent: procs.reduce(0) { $0 + $1.cpuPercent },
                memoryMB: procs.reduce(0) { $0 + $1.memoryMB },
                processCount: procs.count
            )

            return CategoryUsage(
                id: category.id,
                name: category.name,
                color: category.color,
                usage: usage,
                processes: procs
            )
        }.filter { $0.processCount > 0 || $0.id == "other" }
    }

    /// Group processes by application name (for detailed view)
    func groupByApp(_ processes: [ProcessInfo]) -> [GroupedProcessInfo] {
        var grouped: [String: [ProcessInfo]] = [:]

        for process in processes {
            var enrichedProcess = process

            if let (_, appName) = findCategoryAndApp(for: process) {
                enrichedProcess.appName = appName
                grouped[appName, default: []].append(enrichedProcess)
            } else {
                // Use process name as app name for ungrouped processes
                grouped[process.name, default: []].append(enrichedProcess)
            }
        }

        return grouped.map { appName, procs in
            GroupedProcessInfo(
                id: appName,
                name: appName,
                processes: procs
            )
        }.sorted { $0.totalCPU > $1.totalCPU }
    }

    /// Find the category and app name for a process (only matches enabled categories)
    private func findCategoryAndApp(for process: ProcessInfo) -> (categoryID: String, appName: String)? {
        for category in enabledCategories {
            for app in category.apps {
                if app.matches(processName: process.name) ||
                   app.matches(processName: process.commandPath) {
                    return (category.id, app.name)
                }
            }
        }
        return nil
    }

    /// Create a resource snapshot from current process data
    func createSnapshot(
        from processes: [ProcessInfo],
        totalSystemMemoryMB: Double,
        totalCPU: Double,
        totalMemoryMB: Double
    ) -> ResourceSnapshot {
        let categoryUsages = groupByCategory(processes)

        // Build category breakdown dictionary
        var breakdown: [String: ResourceUsage] = [:]
        for usage in categoryUsages {
            breakdown[usage.id] = usage.usage
        }

        // Get top 10 processes by CPU
        let topProcesses = processes
            .sorted { $0.cpuPercent > $1.cpuPercent }
            .prefix(10)
            .map { process -> ProcessInfo in
                var enriched = process
                if let (categoryID, appName) = findCategoryAndApp(for: process) {
                    enriched.categoryID = categoryID
                    enriched.appName = appName
                }
                return enriched
            }

        return ResourceSnapshot(
            timestamp: Date(),
            totalCPU: totalCPU,
            totalMemoryMB: totalMemoryMB,
            totalSystemMemoryMB: totalSystemMemoryMB,
            categoryBreakdown: breakdown,
            topProcesses: Array(topProcesses)
        )
    }

    /// Enrich a process with category and app name information
    func enrich(_ process: ProcessInfo) -> ProcessInfo {
        var enriched = process
        if let (categoryID, appName) = findCategoryAndApp(for: process) {
            enriched.categoryID = categoryID
            enriched.appName = appName
        }
        return enriched
    }

    /// Enrich multiple processes
    func enrich(_ processes: [ProcessInfo]) -> [ProcessInfo] {
        processes.map { enrich($0) }
    }
}
