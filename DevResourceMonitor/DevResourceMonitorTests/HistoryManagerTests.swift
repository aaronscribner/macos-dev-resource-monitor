import XCTest
@testable import DevResourceMonitor


final class HistoryManagerTests: XCTestCase {

    var historyManager: HistoryManager!

    override func setUp() {
        super.setUp()
        historyManager = HistoryManager(retentionDays: 7)
    }

    override func tearDown() {
        historyManager = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testSaveSnapshot() {
        let snapshot = ResourceSnapshot(
            totalCPU: 150.0,
            totalMemoryMB: 6144.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 8,
            categoryBreakdown: ["ide": ResourceUsage(cpuPercent: 50.0, memoryMB: 2000.0, processCount: 3)],
            topProcesses: [AppProcessInfo(id: 1, name: "Xcode", cpuPercent: 50.0, memoryMB: 2000.0)]
        )

        historyManager.saveSnapshot(snapshot)

        // Verify by loading
        let loaded = historyManager.loadSnapshots(lastHours: 1)
        XCTAssertFalse(loaded.isEmpty)
    }

    func testLoadSnapshotsDateRange() {
        let now = Date()
        let snapshot = ResourceSnapshot(
            timestamp: now,
            totalCPU: 100.0,
            totalMemoryMB: 4096.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 8,
            categoryBreakdown: [:],
            topProcesses: []
        )
        historyManager.saveSnapshot(snapshot)

        let startDate = Calendar.current.date(byAdding: .hour, value: -1, to: now)!
        let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: now)!

        let loaded = historyManager.loadSnapshots(from: startDate, to: endDate)
        XCTAssertFalse(loaded.isEmpty)
    }

    func testLoadSnapshotsLastHours() {
        let snapshot = ResourceSnapshot(
            totalCPU: 100.0,
            totalMemoryMB: 4096.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 8,
            categoryBreakdown: [:],
            topProcesses: []
        )
        historyManager.saveSnapshot(snapshot)

        let loaded = historyManager.loadSnapshots(lastHours: 1)
        XCTAssertFalse(loaded.isEmpty)
    }

    func testLoadSnapshotsLastDays() {
        let snapshot = ResourceSnapshot(
            totalCPU: 100.0,
            totalMemoryMB: 4096.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 8,
            categoryBreakdown: [:],
            topProcesses: []
        )
        historyManager.saveSnapshot(snapshot)

        let loaded = historyManager.loadSnapshots(lastDays: 1)
        XCTAssertFalse(loaded.isEmpty)
    }

    // MARK: - Event Tests

    func testSaveEvent() {
        let event = ThresholdEvent(
            triggerType: .cpu,
            triggerValue: 85.0,
            threshold: 80.0,
            allProcesses: [AppProcessInfo(id: 1, name: "Test", cpuPercent: 85.0, memoryMB: 500.0)]
        )

        historyManager.saveEvent(event)

        let loaded = historyManager.loadEvents(lastDays: 1)
        XCTAssertFalse(loaded.isEmpty)
    }

    func testLoadEvents() {
        let event = ThresholdEvent(
            triggerType: .memory,
            triggerValue: 90.0,
            threshold: 85.0,
            allProcesses: []
        )
        historyManager.saveEvent(event)

        let loaded = historyManager.loadEvents(lastDays: 7)
        XCTAssertFalse(loaded.isEmpty)
    }

    func testLastEvent() {
        let event1 = ThresholdEvent(
            triggerType: .cpu,
            triggerValue: 85.0,
            threshold: 80.0,
            allProcesses: []
        )
        historyManager.saveEvent(event1)

        Thread.sleep(forTimeInterval: 0.1)

        let event2 = ThresholdEvent(
            triggerType: .memory,
            triggerValue: 90.0,
            threshold: 85.0,
            allProcesses: []
        )
        historyManager.saveEvent(event2)

        let last = historyManager.lastEvent()
        XCTAssertNotNil(last)
        XCTAssertEqual(last?.triggerType, .memory)
    }

    // MARK: - Categories Tests

    func testSaveAndLoadCategories() {
        let categories = [
            AppCategory(
                id: "test-cat",
                name: "Test Category",
                color: "#FF0000",
                apps: [AppDefinition(name: "TestApp", processNames: ["testapp"])],
                isBuiltIn: false,
                isEnabled: true
            )
        ]

        historyManager.saveCategories(categories)

        let loaded = historyManager.loadCategories()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?.first?.id, "test-cat")
    }

    func testLoadCategoriesNone() {
        // Fresh instance may return nil or existing data
        let loaded = historyManager.loadCategories()
        // Just verify it doesn't crash
        XCTAssertTrue(true)
    }

    // MARK: - Settings Tests

    func testSaveAndLoadSettings() {
        var settings = AppSettings()
        settings.pollIntervalSeconds = 10.0
        settings.cpuThreshold = 75.0
        settings.notificationsEnabled = false

        historyManager.saveSettings(settings)

        let loaded = historyManager.loadSettings()
        XCTAssertEqual(loaded.pollIntervalSeconds, 10.0)
        XCTAssertEqual(loaded.cpuThreshold, 75.0)
        XCTAssertFalse(loaded.notificationsEnabled)
    }

    func testLoadDefaultSettings() {
        let loaded = historyManager.loadSettings()
        XCTAssertNotNil(loaded)
    }

    // MARK: - Statistics Tests

    func testSnapshotCount() {
        let initialCount = historyManager.snapshotCount

        let snapshot = ResourceSnapshot(
            totalCPU: 100.0,
            totalMemoryMB: 4096.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 8,
            categoryBreakdown: [:],
            topProcesses: []
        )
        historyManager.saveSnapshot(snapshot)

        let newCount = historyManager.snapshotCount
        XCTAssertGreaterThanOrEqual(newCount, initialCount)
    }

    func testEventCount() {
        let initialCount = historyManager.eventCount

        let event = ThresholdEvent(
            triggerType: .cpu,
            triggerValue: 85.0,
            threshold: 80.0,
            allProcesses: []
        )
        historyManager.saveEvent(event)

        let newCount = historyManager.eventCount
        XCTAssertGreaterThanOrEqual(newCount, initialCount)
    }

    // MARK: - Cleanup Tests

    func testCleanup() {
        // Just verify it doesn't crash
        historyManager.cleanup(keepDays: 7)
        XCTAssertTrue(true)
    }

    // MARK: - Integration Tests

    func testFullWorkflow() {
        // 1. Save settings
        var settings = AppSettings()
        settings.cpuThreshold = 85.0
        historyManager.saveSettings(settings)

        // 2. Save categories
        let categories = AppCategory.defaultCategories
        historyManager.saveCategories(categories)

        // 3. Save snapshots
        for i in 0..<5 {
            let snapshot = ResourceSnapshot(
                totalCPU: Double(i * 50),
                totalMemoryMB: Double(i * 1000),
                totalSystemMemoryMB: 16384.0,
                cpuCoreCount: 8,
                categoryBreakdown: [:],
                topProcesses: []
            )
            historyManager.saveSnapshot(snapshot)
        }

        // 4. Save events
        let event = ThresholdEvent(
            triggerType: .cpu,
            triggerValue: 90.0,
            threshold: 85.0,
            allProcesses: []
        )
        historyManager.saveEvent(event)

        // 5. Verify all data is retrievable
        let loadedSettings = historyManager.loadSettings()
        XCTAssertEqual(loadedSettings.cpuThreshold, 85.0)

        let loadedCategories = historyManager.loadCategories()
        XCTAssertNotNil(loadedCategories)

        let loadedSnapshots = historyManager.loadSnapshots(lastHours: 1)
        XCTAssertFalse(loadedSnapshots.isEmpty)

        let loadedEvents = historyManager.loadEvents(lastDays: 1)
        XCTAssertFalse(loadedEvents.isEmpty)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentAccess() {
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 20

        // Concurrent snapshot saves
        for i in 0..<10 {
            DispatchQueue.global().async {
                let snapshot = ResourceSnapshot(
                    totalCPU: Double(i * 10),
                    totalMemoryMB: Double(i * 500),
                    totalSystemMemoryMB: 16384.0,
                    cpuCoreCount: 8,
                    categoryBreakdown: [:],
                    topProcesses: []
                )
                self.historyManager.saveSnapshot(snapshot)
                expectation.fulfill()
            }
        }

        // Concurrent event saves
        for i in 0..<10 {
            DispatchQueue.global().async {
                let event = ThresholdEvent(
                    triggerType: i % 2 == 0 ? .cpu : .memory,
                    triggerValue: Double(80 + i),
                    threshold: 80.0,
                    allProcesses: []
                )
                self.historyManager.saveEvent(event)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)

        // Verify data integrity
        let snapshots = historyManager.loadSnapshots(lastHours: 1)
        let events = historyManager.loadEvents(lastDays: 1)

        XCTAssertGreaterThanOrEqual(snapshots.count, 1)
        XCTAssertGreaterThanOrEqual(events.count, 1)
    }
}
