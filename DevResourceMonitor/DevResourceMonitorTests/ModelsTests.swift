import XCTest
@testable import DevResourceMonitor


final class ModelsTests: XCTestCase {

    // MARK: - AppSettings Tests

    func testAppSettingsDefaultValues() {
        let settings = AppSettings.default
        XCTAssertEqual(settings.pollIntervalSeconds, 5.0)
        XCTAssertEqual(settings.cpuThreshold, 80.0)
        XCTAssertEqual(settings.memoryThreshold, 80.0)
        XCTAssertTrue(settings.thresholdsEnabled)
        XCTAssertEqual(settings.thresholdCooldownSeconds, 60.0)
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertFalse(settings.soundEnabled)
        XCTAssertFalse(settings.silentLogging)
        XCTAssertTrue(settings.showInMenuBar)
        XCTAssertTrue(settings.showPercentInMenuBar)
        XCTAssertEqual(settings.defaultViewMode, .grouped)
        XCTAssertEqual(settings.defaultHistoryChartMode, .bar)
        XCTAssertEqual(settings.fontSizeScale, 4.0)
        XCTAssertEqual(settings.historyRetentionDays, 30)
        XCTAssertFalse(settings.launchAtLogin)
    }

    func testAppSettingsCodable() throws {
        var settings = AppSettings()
        settings.pollIntervalSeconds = 10.0
        settings.cpuThreshold = 90.0
        settings.memoryThreshold = 85.0
        settings.thresholdsEnabled = false
        settings.notificationsEnabled = false
        settings.defaultViewMode = .detailed
        settings.defaultHistoryChartMode = .line

        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppSettings.self, from: data)

        XCTAssertEqual(decoded.pollIntervalSeconds, 10.0)
        XCTAssertEqual(decoded.cpuThreshold, 90.0)
        XCTAssertEqual(decoded.memoryThreshold, 85.0)
        XCTAssertFalse(decoded.thresholdsEnabled)
        XCTAssertFalse(decoded.notificationsEnabled)
        XCTAssertEqual(decoded.defaultViewMode, .detailed)
        XCTAssertEqual(decoded.defaultHistoryChartMode, .line)
    }

    func testViewModeCases() {
        XCTAssertEqual(AppSettings.ViewMode.grouped.rawValue, "Grouped")
        XCTAssertEqual(AppSettings.ViewMode.detailed.rawValue, "Detailed")
        XCTAssertEqual(AppSettings.ViewMode.allCases.count, 2)
    }

    func testHistoryChartModeCases() {
        XCTAssertEqual(AppSettings.HistoryChartMode.bar.rawValue, "Bar")
        XCTAssertEqual(AppSettings.HistoryChartMode.line.rawValue, "Line")
        XCTAssertEqual(AppSettings.HistoryChartMode.allCases.count, 2)
    }

    // MARK: - AppProcessInfo Tests

    func testProcessInfoInit() {
        let process = AppProcessInfo(
            id: 123,
            name: "TestProcess",
            commandPath: "/usr/bin/test",
            cpuPercent: 25.5,
            memoryMB: 100.0,
            parentPID: 1,
            categoryID: "dev-tools",
            appName: "Test App"
        )

        XCTAssertEqual(process.id, 123)
        XCTAssertEqual(process.name, "TestProcess")
        XCTAssertEqual(process.commandPath, "/usr/bin/test")
        XCTAssertEqual(process.cpuPercent, 25.5)
        XCTAssertEqual(process.memoryMB, 100.0)
        XCTAssertEqual(process.parentPID, 1)
        XCTAssertEqual(process.categoryID, "dev-tools")
        XCTAssertEqual(process.appName, "Test App")
    }

    func testProcessInfoDisplayName() {
        let processWithAppName = AppProcessInfo(id: 1, name: "Electron", appName: "VS Code")
        XCTAssertEqual(processWithAppName.displayName, "VS Code")

        let processWithoutAppName = AppProcessInfo(id: 2, name: "node")
        XCTAssertEqual(processWithoutAppName.displayName, "node")
    }

    func testProcessInfoEquality() {
        let process1 = AppProcessInfo(id: 123, name: "Test")
        let process2 = AppProcessInfo(id: 123, name: "Different")
        let process3 = AppProcessInfo(id: 456, name: "Test")

        XCTAssertEqual(process1, process2)
        XCTAssertNotEqual(process1, process3)
    }

    func testProcessInfoHashable() {
        let process1 = AppProcessInfo(id: 123, name: "Test")
        let process2 = AppProcessInfo(id: 123, name: "Test")

        var set = Set<AppProcessInfo>()
        set.insert(process1)
        set.insert(process2)

        XCTAssertEqual(set.count, 1)
    }

    func testProcessInfoCodable() throws {
        let process = AppProcessInfo(
            id: 123,
            name: "TestProcess",
            commandPath: "/usr/bin/test",
            cpuPercent: 25.5,
            memoryMB: 100.0,
            parentPID: 1,
            categoryID: "dev-tools",
            appName: "Test App"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(process)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppProcessInfo.self, from: data)

        XCTAssertEqual(decoded.id, 123)
        XCTAssertEqual(decoded.name, "TestProcess")
        XCTAssertEqual(decoded.cpuPercent, 25.5)
        XCTAssertEqual(decoded.memoryMB, 100.0)
    }

    func testSystemCoreCount() {
        XCTAssertGreaterThan(AppProcessInfo.systemCoreCount, 0)
    }

    // MARK: - GroupedProcessInfo Tests

    func testGroupedProcessInfoTotals() {
        let processes: [AppProcessInfo] = [
            AppProcessInfo(id: 1, name: "p1", cpuPercent: 10.0, memoryMB: 100.0),
            AppProcessInfo(id: 2, name: "p2", cpuPercent: 20.0, memoryMB: 200.0),
            AppProcessInfo(id: 3, name: "p3", cpuPercent: 30.0, memoryMB: 300.0)
        ]

        let grouped = GroupedProcessInfo(id: "test", name: "Test Group", processes: processes)

        XCTAssertEqual(grouped.totalCPU, 60.0)
        XCTAssertEqual(grouped.totalMemoryMB, 600.0)
        XCTAssertEqual(grouped.processCount, 3)
    }

    func testGroupedProcessInfoEmpty() {
        let grouped = GroupedProcessInfo(id: "empty", name: "Empty Group", processes: [])

        XCTAssertEqual(grouped.totalCPU, 0.0)
        XCTAssertEqual(grouped.totalMemoryMB, 0.0)
        XCTAssertEqual(grouped.processCount, 0)
    }

    // MARK: - ResourceUsage Tests

    func testResourceUsageInit() {
        let usage = ResourceUsage(cpuPercent: 50.0, memoryMB: 1024.0, processCount: 5)

        XCTAssertEqual(usage.cpuPercent, 50.0)
        XCTAssertEqual(usage.memoryMB, 1024.0)
        XCTAssertEqual(usage.processCount, 5)
    }

    func testResourceUsageDefaultInit() {
        let usage = ResourceUsage()

        XCTAssertEqual(usage.cpuPercent, 0.0)
        XCTAssertEqual(usage.memoryMB, 0.0)
        XCTAssertEqual(usage.processCount, 0)
    }

    func testResourceUsageAddition() {
        let usage1 = ResourceUsage(cpuPercent: 25.0, memoryMB: 500.0, processCount: 2)
        let usage2 = ResourceUsage(cpuPercent: 35.0, memoryMB: 700.0, processCount: 3)

        let combined = usage1 + usage2

        XCTAssertEqual(combined.cpuPercent, 60.0)
        XCTAssertEqual(combined.memoryMB, 1200.0)
        XCTAssertEqual(combined.processCount, 5)
    }

    func testResourceUsageCodable() throws {
        let usage = ResourceUsage(cpuPercent: 50.0, memoryMB: 1024.0, processCount: 5)

        let encoder = JSONEncoder()
        let data = try encoder.encode(usage)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ResourceUsage.self, from: data)

        XCTAssertEqual(decoded.cpuPercent, 50.0)
        XCTAssertEqual(decoded.memoryMB, 1024.0)
        XCTAssertEqual(decoded.processCount, 5)
    }

    // MARK: - ResourceSnapshot Tests

    func testResourceSnapshotCPUPercent() {
        let snapshot = ResourceSnapshot(
            totalCPU: 400.0,
            totalMemoryMB: 8192.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 8,
            categoryBreakdown: [:],
            topProcesses: []
        )

        XCTAssertEqual(snapshot.cpuPercent, 50.0)
    }

    func testResourceSnapshotCPUPercentZeroCores() {
        let snapshot = ResourceSnapshot(
            totalCPU: 400.0,
            totalMemoryMB: 8192.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 0,
            categoryBreakdown: [:],
            topProcesses: []
        )

        XCTAssertEqual(snapshot.cpuPercent, 0.0)
    }

    func testResourceSnapshotMemoryPercent() {
        let snapshot = ResourceSnapshot(
            totalCPU: 100.0,
            totalMemoryMB: 8192.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 8,
            categoryBreakdown: [:],
            topProcesses: []
        )

        XCTAssertEqual(snapshot.memoryPercent, 50.0)
    }

    func testResourceSnapshotMemoryPercentZeroSystem() {
        let snapshot = ResourceSnapshot(
            totalCPU: 100.0,
            totalMemoryMB: 8192.0,
            totalSystemMemoryMB: 0.0,
            cpuCoreCount: 8,
            categoryBreakdown: [:],
            topProcesses: []
        )

        XCTAssertEqual(snapshot.memoryPercent, 0.0)
    }

    func testResourceSnapshotCodable() throws {
        let snapshot = ResourceSnapshot(
            totalCPU: 200.0,
            totalMemoryMB: 4096.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 8,
            categoryBreakdown: ["ide": ResourceUsage(cpuPercent: 50.0, memoryMB: 2000.0, processCount: 3)],
            topProcesses: [AppProcessInfo(id: 1, name: "test")]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ResourceSnapshot.self, from: data)

        XCTAssertEqual(decoded.totalCPU, 200.0)
        XCTAssertEqual(decoded.totalMemoryMB, 4096.0)
        XCTAssertEqual(decoded.cpuCoreCount, 8)
        XCTAssertEqual(decoded.categoryBreakdown.count, 1)
        XCTAssertEqual(decoded.topProcesses.count, 1)
    }

    // MARK: - CategoryUsage Tests

    func testCategoryUsageProperties() {
        let usage = ResourceUsage(cpuPercent: 45.0, memoryMB: 2048.0, processCount: 5)
        let categoryUsage = CategoryUsage(
            id: "ide",
            name: "IDEs & Editors",
            color: "#007AFF",
            usage: usage,
            processes: []
        )

        XCTAssertEqual(categoryUsage.cpuPercent, 45.0)
        XCTAssertEqual(categoryUsage.memoryMB, 2048.0)
        XCTAssertEqual(categoryUsage.processCount, 5)
    }

    // MARK: - ThresholdEvent Tests

    func testThresholdEventInit() {
        let processes = [AppProcessInfo(id: 1, name: "test", cpuPercent: 90.0)]
        let event = ThresholdEvent(
            triggerType: .cpu,
            triggerValue: 85.0,
            threshold: 80.0,
            allProcesses: processes
        )

        XCTAssertEqual(event.triggerType, .cpu)
        XCTAssertEqual(event.triggerValue, 85.0)
        XCTAssertEqual(event.threshold, 80.0)
        XCTAssertEqual(event.allProcesses.count, 1)
    }

    func testThresholdEventDescription() {
        let event = ThresholdEvent(
            triggerType: .cpu,
            triggerValue: 85.5,
            threshold: 80.0,
            allProcesses: []
        )

        XCTAssertEqual(event.description, "CPU reached 85.5% (threshold: 80.0%)")

        let memoryEvent = ThresholdEvent(
            triggerType: .memory,
            triggerValue: 92.3,
            threshold: 85.0,
            allProcesses: []
        )

        XCTAssertEqual(memoryEvent.description, "Memory reached 92.3% (threshold: 85.0%)")
    }

    func testThresholdEventTopProcessesByTrigger() {
        let processes: [AppProcessInfo] = [
            AppProcessInfo(id: 1, name: "low", cpuPercent: 10.0, memoryMB: 500.0),
            AppProcessInfo(id: 2, name: "high", cpuPercent: 80.0, memoryMB: 100.0),
            AppProcessInfo(id: 3, name: "medium", cpuPercent: 40.0, memoryMB: 300.0)
        ]

        let cpuEvent = ThresholdEvent(
            triggerType: .cpu,
            triggerValue: 85.0,
            threshold: 80.0,
            allProcesses: processes
        )

        let cpuSorted = cpuEvent.topProcessesByTrigger
        XCTAssertEqual(cpuSorted[0].name, "high")
        XCTAssertEqual(cpuSorted[1].name, "medium")
        XCTAssertEqual(cpuSorted[2].name, "low")

        let memoryEvent = ThresholdEvent(
            triggerType: .memory,
            triggerValue: 90.0,
            threshold: 85.0,
            allProcesses: processes
        )

        let memorySorted = memoryEvent.topProcessesByTrigger
        XCTAssertEqual(memorySorted[0].name, "low")
        XCTAssertEqual(memorySorted[1].name, "medium")
        XCTAssertEqual(memorySorted[2].name, "high")
    }

    func testTriggerTypeProperties() {
        XCTAssertEqual(ThresholdEvent.TriggerType.cpu.displayName, "CPU")
        XCTAssertEqual(ThresholdEvent.TriggerType.memory.displayName, "Memory")
        XCTAssertEqual(ThresholdEvent.TriggerType.cpu.icon, "cpu")
        XCTAssertEqual(ThresholdEvent.TriggerType.memory.icon, "memorychip")
        XCTAssertEqual(ThresholdEvent.TriggerType.allCases.count, 2)
    }

    func testThresholdEventEquality() {
        let id = UUID()
        let event1 = ThresholdEvent(id: id, triggerType: .cpu, triggerValue: 85.0, threshold: 80.0, allProcesses: [])
        let event2 = ThresholdEvent(id: id, triggerType: .memory, triggerValue: 90.0, threshold: 85.0, allProcesses: [])
        let event3 = ThresholdEvent(triggerType: .cpu, triggerValue: 85.0, threshold: 80.0, allProcesses: [])

        XCTAssertEqual(event1, event2)
        XCTAssertNotEqual(event1, event3)
    }

    func testThresholdEventCodable() throws {
        let event = ThresholdEvent(
            triggerType: .cpu,
            triggerValue: 85.0,
            threshold: 80.0,
            allProcesses: [AppProcessInfo(id: 1, name: "test")]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(event)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ThresholdEvent.self, from: data)

        XCTAssertEqual(decoded.triggerType, .cpu)
        XCTAssertEqual(decoded.triggerValue, 85.0)
        XCTAssertEqual(decoded.threshold, 80.0)
        XCTAssertEqual(decoded.allProcesses.count, 1)
    }

    // MARK: - AppCategory Tests

    func testAppCategoryInit() {
        let apps = [
            AppDefinition(name: "Test App", processNames: ["test"])
        ]
        let category = AppCategory(
            id: "test-cat",
            name: "Test Category",
            color: "#FF0000",
            apps: apps,
            isBuiltIn: true,
            isEnabled: true
        )

        XCTAssertEqual(category.id, "test-cat")
        XCTAssertEqual(category.name, "Test Category")
        XCTAssertEqual(category.color, "#FF0000")
        XCTAssertEqual(category.apps.count, 1)
        XCTAssertTrue(category.isBuiltIn)
        XCTAssertTrue(category.isEnabled)
    }

    func testAppCategoryEquality() {
        let cat1 = AppCategory(id: "test", name: "Test", color: "#FF0000", apps: [])
        let cat2 = AppCategory(id: "test", name: "Different", color: "#00FF00", apps: [])
        let cat3 = AppCategory(id: "other", name: "Test", color: "#FF0000", apps: [])

        XCTAssertEqual(cat1, cat2)
        XCTAssertNotEqual(cat1, cat3)
    }

    func testAppCategoryHashable() {
        let cat1 = AppCategory(id: "test", name: "Test", color: "#FF0000", apps: [])
        let cat2 = AppCategory(id: "test", name: "Test", color: "#FF0000", apps: [])

        var set = Set<AppCategory>()
        set.insert(cat1)
        set.insert(cat2)

        XCTAssertEqual(set.count, 1)
    }

    func testDefaultCategoriesExist() {
        XCTAssertFalse(AppCategory.defaultCategories.isEmpty)
        XCTAssertGreaterThanOrEqual(AppCategory.defaultCategories.count, 7)

        let categoryIDs = AppCategory.defaultCategories.map { $0.id }
        XCTAssertTrue(categoryIDs.contains("ide"))
        XCTAssertTrue(categoryIDs.contains("containers"))
        XCTAssertTrue(categoryIDs.contains("dev-tools"))
        XCTAssertTrue(categoryIDs.contains("databases"))
        XCTAssertTrue(categoryIDs.contains("browsers"))
        XCTAssertTrue(categoryIDs.contains("other"))
    }

    // MARK: - AppDefinition Tests

    func testAppDefinitionMatchesExact() {
        let app = AppDefinition(name: "VS Code", processNames: ["Code", "Electron"], useRegex: false)

        XCTAssertTrue(app.matches(processName: "Code"))
        XCTAssertTrue(app.matches(processName: "Code Helper"))
        XCTAssertTrue(app.matches(processName: "Electron"))
        XCTAssertTrue(app.matches(processName: "code"))  // case insensitive
        // Note: The implementation uses localizedCaseInsensitiveContains, so "NotCode" would match "Code"
        XCTAssertTrue(app.matches(processName: "NotCode"))  // Contains "Code"
        XCTAssertFalse(app.matches(processName: "Safari"))  // Doesn't contain "Code" or "Electron"
    }

    func testAppDefinitionMatchesRegex() {
        let app = AppDefinition(name: "JetBrains", processNames: ["idea|webstorm|pycharm"], useRegex: true)

        XCTAssertTrue(app.matches(processName: "idea"))
        XCTAssertTrue(app.matches(processName: "webstorm"))
        XCTAssertTrue(app.matches(processName: "pycharm"))
        XCTAssertFalse(app.matches(processName: "vscode"))
    }

    func testAppDefinitionInvalidRegex() {
        let app = AppDefinition(name: "Invalid", processNames: ["[invalid"], useRegex: true)

        // Should not crash, just return false
        XCTAssertFalse(app.matches(processName: "test"))
    }

    func testAppDefinitionCodable() throws {
        let app = AppDefinition(name: "Test", processNames: ["test1", "test2"], useRegex: true)

        let encoder = JSONEncoder()
        let data = try encoder.encode(app)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppDefinition.self, from: data)

        XCTAssertEqual(decoded.name, "Test")
        XCTAssertEqual(decoded.processNames, ["test1", "test2"])
        XCTAssertTrue(decoded.useRegex)
    }
}
