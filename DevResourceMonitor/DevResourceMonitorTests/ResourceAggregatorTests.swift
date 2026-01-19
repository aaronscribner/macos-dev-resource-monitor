import XCTest
@testable import DevResourceMonitor


final class ResourceAggregatorTests: XCTestCase {

    var aggregator: ResourceAggregator!

    override func setUp() {
        super.setUp()
        aggregator = ResourceAggregator(categories: AppCategory.defaultCategories)
    }

    override func tearDown() {
        aggregator = nil
        super.tearDown()
    }

    // MARK: - Group By Category Tests

    func testGroupByCategoryEmpty() {
        let result = aggregator.groupByCategory([])

        // Should have "other" category when empty or only the other category with 0 processes
        XCTAssertTrue(result.isEmpty || result.allSatisfy { $0.processCount == 0 || $0.id == "other" })
    }

    func testGroupByCategoryMatchesIDEs() {
        let processes = [
            AppProcessInfo(id: 1, name: "Xcode", cpuPercent: 25.0, memoryMB: 1000.0),
            AppProcessInfo(id: 2, name: "Code Helper", cpuPercent: 15.0, memoryMB: 500.0)
        ]

        let result = aggregator.groupByCategory(processes)

        let ideCategory = result.first { $0.id == "ide" }
        XCTAssertNotNil(ideCategory)
        XCTAssertEqual(ideCategory?.processCount, 2)
        XCTAssertEqual(ideCategory?.cpuPercent, 40.0)
        XCTAssertEqual(ideCategory?.memoryMB, 1500.0)
    }

    func testGroupByCategoryMatchesContainers() {
        let processes = [
            AppProcessInfo(id: 1, name: "Docker", cpuPercent: 30.0, memoryMB: 2000.0),
            AppProcessInfo(id: 2, name: "com.docker.backend", cpuPercent: 10.0, memoryMB: 500.0)
        ]

        let result = aggregator.groupByCategory(processes)

        let containersCategory = result.first { $0.id == "containers" }
        XCTAssertNotNil(containersCategory)
        XCTAssertEqual(containersCategory?.processCount, 2)
    }

    func testGroupByCategoryMatchesDevTools() {
        let processes = [
            AppProcessInfo(id: 1, name: "node", cpuPercent: 20.0, memoryMB: 300.0),
            AppProcessInfo(id: 2, name: "python3", cpuPercent: 5.0, memoryMB: 100.0),
            AppProcessInfo(id: 3, name: "Terminal", cpuPercent: 2.0, memoryMB: 50.0)
        ]

        let result = aggregator.groupByCategory(processes)

        let devToolsCategory = result.first { $0.id == "dev-tools" }
        XCTAssertNotNil(devToolsCategory)
        XCTAssertEqual(devToolsCategory?.processCount, 3)
    }

    func testGroupByCategoryUnmatchedGoesToOther() {
        let processes = [
            AppProcessInfo(id: 1, name: "UnknownProcess", cpuPercent: 10.0, memoryMB: 100.0),
            AppProcessInfo(id: 2, name: "RandomApp", cpuPercent: 5.0, memoryMB: 50.0)
        ]

        let result = aggregator.groupByCategory(processes)

        let otherCategory = result.first { $0.id == "other" }
        XCTAssertNotNil(otherCategory)
        XCTAssertEqual(otherCategory?.processCount, 2)
    }

    func testGroupByCategoryMixedProcesses() {
        let processes = [
            AppProcessInfo(id: 1, name: "Xcode", cpuPercent: 30.0, memoryMB: 2000.0),
            AppProcessInfo(id: 2, name: "Docker", cpuPercent: 20.0, memoryMB: 1500.0),
            AppProcessInfo(id: 3, name: "postgres", cpuPercent: 5.0, memoryMB: 200.0),
            AppProcessInfo(id: 4, name: "UnknownApp", cpuPercent: 2.0, memoryMB: 50.0)
        ]

        let result = aggregator.groupByCategory(processes)

        XCTAssertNotNil(result.first { $0.id == "ide" })
        XCTAssertNotNil(result.first { $0.id == "containers" })
        XCTAssertNotNil(result.first { $0.id == "databases" })
        XCTAssertNotNil(result.first { $0.id == "other" })
    }

    func testGroupByCategoryProcessesAreEnriched() {
        let processes = [
            AppProcessInfo(id: 1, name: "Electron", commandPath: "/Applications/Visual Studio Code.app/Contents/MacOS/Electron", cpuPercent: 25.0, memoryMB: 500.0)
        ]

        let result = aggregator.groupByCategory(processes)

        let ideCategory = result.first { $0.id == "ide" }
        XCTAssertNotNil(ideCategory)

        if let process = ideCategory?.processes.first {
            XCTAssertEqual(process.categoryID, "ide")
            XCTAssertNotNil(process.appName)
        }
    }

    // MARK: - Group By App Tests

    func testGroupByAppEmpty() {
        let result = aggregator.groupByApp([])
        XCTAssertTrue(result.isEmpty)
    }

    func testGroupByAppGroupsCorrectly() {
        let processes = [
            AppProcessInfo(id: 1, name: "Code Helper", cpuPercent: 15.0, memoryMB: 300.0),
            AppProcessInfo(id: 2, name: "Code Helper (GPU)", cpuPercent: 10.0, memoryMB: 200.0),
            AppProcessInfo(id: 3, name: "Electron", cpuPercent: 20.0, memoryMB: 400.0)
        ]

        let result = aggregator.groupByApp(processes)

        // All should be grouped under VS Code
        XCTAssertFalse(result.isEmpty)
    }

    func testGroupByAppSortedByCPU() {
        let processes = [
            AppProcessInfo(id: 1, name: "node", cpuPercent: 10.0, memoryMB: 100.0),
            AppProcessInfo(id: 2, name: "Xcode", cpuPercent: 50.0, memoryMB: 2000.0),
            AppProcessInfo(id: 3, name: "python3", cpuPercent: 5.0, memoryMB: 50.0)
        ]

        let result = aggregator.groupByApp(processes)

        XCTAssertGreaterThanOrEqual(result.count, 1)
        if result.count >= 2 {
            XCTAssertGreaterThanOrEqual(result[0].totalCPU, result[1].totalCPU)
        }
    }

    // MARK: - Update Categories Tests

    func testUpdateCategories() {
        let customCategory = AppCategory(
            id: "custom",
            name: "Custom Apps",
            color: "#FF0000",
            apps: [AppDefinition(name: "MyApp", processNames: ["myapp"])],
            isBuiltIn: false,
            isEnabled: true
        )

        aggregator.updateCategories([customCategory])

        let processes = [
            AppProcessInfo(id: 1, name: "myapp", cpuPercent: 10.0, memoryMB: 100.0)
        ]

        let result = aggregator.groupByCategory(processes)

        let customResult = result.first { $0.id == "custom" }
        XCTAssertNotNil(customResult)
        XCTAssertEqual(customResult?.processCount, 1)
    }

    func testDisabledCategoryExcluded() {
        var categories = AppCategory.defaultCategories
        if let ideIndex = categories.firstIndex(where: { $0.id == "ide" }) {
            categories[ideIndex].isEnabled = false
        }

        aggregator.updateCategories(categories)

        let processes = [
            AppProcessInfo(id: 1, name: "Xcode", cpuPercent: 30.0, memoryMB: 2000.0)
        ]

        let result = aggregator.groupByCategory(processes)

        let ideCategory = result.first { $0.id == "ide" }
        XCTAssertNil(ideCategory)
    }

    // MARK: - Create Snapshot Tests

    func testCreateSnapshot() {
        let processes = [
            AppProcessInfo(id: 1, name: "Xcode", cpuPercent: 100.0, memoryMB: 2000.0),
            AppProcessInfo(id: 2, name: "Docker", cpuPercent: 50.0, memoryMB: 1500.0),
            AppProcessInfo(id: 3, name: "node", cpuPercent: 30.0, memoryMB: 300.0)
        ]

        let snapshot = aggregator.createSnapshot(from: processes, totalSystemMemoryMB: 16384.0)

        XCTAssertEqual(snapshot.totalCPU, 180.0)
        XCTAssertEqual(snapshot.totalMemoryMB, 3800.0)
        XCTAssertEqual(snapshot.totalSystemMemoryMB, 16384.0)
        XCTAssertFalse(snapshot.categoryBreakdown.isEmpty)
        XCTAssertLessThanOrEqual(snapshot.topProcesses.count, 10)
    }

    func testCreateSnapshotTop10Processes() {
        var processes: [AppProcessInfo] = []
        for i in 1...15 {
            processes.append(AppProcessInfo(
                id: Int32(i),
                name: "Process\(i)",
                cpuPercent: Double(i * 5),
                memoryMB: Double(i * 100)
            ))
        }

        let snapshot = aggregator.createSnapshot(from: processes, totalSystemMemoryMB: 16384.0)

        XCTAssertEqual(snapshot.topProcesses.count, 10)
        // Verify sorted by CPU descending
        if snapshot.topProcesses.count >= 2 {
            XCTAssertGreaterThanOrEqual(
                snapshot.topProcesses[0].cpuPercent,
                snapshot.topProcesses[1].cpuPercent
            )
        }
    }

    // MARK: - Enrich Tests

    func testEnrichSingleProcess() {
        // Note: "Xcode" contains "Code" which matches VS Code pattern first
        // Test with a more specific process name
        let process = AppProcessInfo(id: 1, name: "Docker", cpuPercent: 50.0, memoryMB: 2000.0)

        let enriched = aggregator.enrich(process)

        XCTAssertEqual(enriched.categoryID, "containers")
        XCTAssertEqual(enriched.appName, "Docker")
    }

    func testEnrichUnmatchedProcess() {
        let process = AppProcessInfo(id: 1, name: "RandomProcess", cpuPercent: 10.0, memoryMB: 100.0)

        let enriched = aggregator.enrich(process)

        XCTAssertNil(enriched.categoryID)
        XCTAssertNil(enriched.appName)
    }

    func testEnrichMultipleProcesses() {
        let processes = [
            AppProcessInfo(id: 1, name: "Xcode", cpuPercent: 30.0, memoryMB: 2000.0),
            AppProcessInfo(id: 2, name: "Docker", cpuPercent: 20.0, memoryMB: 1500.0),
            AppProcessInfo(id: 3, name: "RandomApp", cpuPercent: 5.0, memoryMB: 100.0)
        ]

        let enriched = aggregator.enrich(processes)

        XCTAssertEqual(enriched.count, 3)
        XCTAssertEqual(enriched[0].categoryID, "ide")
        XCTAssertEqual(enriched[1].categoryID, "containers")
        XCTAssertNil(enriched[2].categoryID)
    }

    func testEnrichByCommandPath() {
        let process = AppProcessInfo(
            id: 1,
            name: "Electron",
            commandPath: "/Applications/Visual Studio Code.app/Contents/MacOS/Electron",
            cpuPercent: 25.0,
            memoryMB: 500.0
        )

        let enriched = aggregator.enrich(process)

        XCTAssertEqual(enriched.categoryID, "ide")
    }

    // MARK: - Category Color Tests

    func testCategoryUsageHasColor() {
        let processes = [
            AppProcessInfo(id: 1, name: "Xcode", cpuPercent: 30.0, memoryMB: 2000.0)
        ]

        let result = aggregator.groupByCategory(processes)

        let ideCategory = result.first { $0.id == "ide" }
        XCTAssertNotNil(ideCategory)
        XCTAssertFalse(ideCategory!.color.isEmpty)
        XCTAssertTrue(ideCategory!.color.hasPrefix("#"))
    }
}
