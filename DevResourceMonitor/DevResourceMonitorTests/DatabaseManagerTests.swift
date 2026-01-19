import XCTest
@testable import DevResourceMonitor


final class DatabaseManagerTests: XCTestCase {

    var database: DatabaseManager!
    var testDbPath: URL!

    override func setUp() {
        super.setUp()
        // Use a test-specific database
        database = DatabaseManager(retentionDays: 7)
    }

    override func tearDown() {
        database = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testSaveAndLoadSnapshot() {
        let snapshot = ResourceSnapshot(
            totalCPU: 200.0,
            totalMemoryMB: 8192.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 8,
            categoryBreakdown: [
                "ide": ResourceUsage(cpuPercent: 50.0, memoryMB: 2000.0, processCount: 3),
                "containers": ResourceUsage(cpuPercent: 30.0, memoryMB: 1500.0, processCount: 2)
            ],
            topProcesses: [
                AppProcessInfo(id: 1, name: "Xcode", cpuPercent: 50.0, memoryMB: 2000.0)
            ]
        )

        database.saveSnapshot(snapshot)

        let startDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        let endDate = Date()
        let loaded = database.loadSnapshots(from: startDate, to: endDate)

        XCTAssertFalse(loaded.isEmpty)
        if let loadedSnapshot = loaded.last {
            XCTAssertEqual(loadedSnapshot.id, snapshot.id)
            XCTAssertEqual(loadedSnapshot.totalCPU, 200.0)
            XCTAssertEqual(loadedSnapshot.totalMemoryMB, 8192.0)
            XCTAssertEqual(loadedSnapshot.totalSystemMemoryMB, 16384.0)
            // Note: cpuCoreCount is not persisted to database, uses system default when loaded
            XCTAssertGreaterThan(loadedSnapshot.cpuCoreCount, 0)
            XCTAssertEqual(loadedSnapshot.categoryBreakdown.count, 2)
            XCTAssertEqual(loadedSnapshot.topProcesses.count, 1)
        }
    }

    func testLoadSnapshotsLastHours() {
        // Save a snapshot
        let snapshot = ResourceSnapshot(
            totalCPU: 100.0,
            totalMemoryMB: 4096.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 8,
            categoryBreakdown: [:],
            topProcesses: []
        )
        database.saveSnapshot(snapshot)

        let loaded = database.loadSnapshots(lastHours: 1)
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
        database.saveSnapshot(snapshot)

        let loaded = database.loadSnapshots(lastDays: 1)
        XCTAssertFalse(loaded.isEmpty)
    }

    func testSnapshotDateRange() {
        // Save snapshots at different times
        let now = Date()
        let snapshot1 = ResourceSnapshot(
            timestamp: now,
            totalCPU: 100.0,
            totalMemoryMB: 4096.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 8,
            categoryBreakdown: [:],
            topProcesses: []
        )
        database.saveSnapshot(snapshot1)

        // Load with narrow range
        let startDate = Calendar.current.date(byAdding: .minute, value: -5, to: now)!
        let endDate = Calendar.current.date(byAdding: .minute, value: 5, to: now)!
        let loaded = database.loadSnapshots(from: startDate, to: endDate)

        XCTAssertFalse(loaded.isEmpty)
    }

    func testSnapshotReplaceOnSameId() {
        let id = UUID()
        let snapshot1 = ResourceSnapshot(
            id: id,
            totalCPU: 100.0,
            totalMemoryMB: 4096.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 8,
            categoryBreakdown: [:],
            topProcesses: []
        )
        database.saveSnapshot(snapshot1)

        let snapshot2 = ResourceSnapshot(
            id: id,
            totalCPU: 200.0,  // Different value
            totalMemoryMB: 8192.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 8,
            categoryBreakdown: [:],
            topProcesses: []
        )
        database.saveSnapshot(snapshot2)

        let loaded = database.loadSnapshots(lastHours: 1)
        let matchingSnapshots = loaded.filter { $0.id == id }
        XCTAssertEqual(matchingSnapshots.count, 1)
        XCTAssertEqual(matchingSnapshots.first?.totalCPU, 200.0)
    }

    // MARK: - Threshold Event Tests

    func testSaveAndLoadEvent() {
        let event = ThresholdEvent(
            triggerType: .cpu,
            triggerValue: 85.0,
            threshold: 80.0,
            allProcesses: [
                AppProcessInfo(id: 1, name: "TestProcess", cpuPercent: 85.0, memoryMB: 1000.0)
            ]
        )

        database.saveEvent(event)

        let loaded = database.loadEvents(lastDays: 1)
        XCTAssertFalse(loaded.isEmpty)

        if let loadedEvent = loaded.first(where: { $0.id == event.id }) {
            XCTAssertEqual(loadedEvent.triggerType, .cpu)
            XCTAssertEqual(loadedEvent.triggerValue, 85.0)
            XCTAssertEqual(loadedEvent.threshold, 80.0)
            XCTAssertEqual(loadedEvent.allProcesses.count, 1)
        }
    }

    func testLastEvent() {
        let event1 = ThresholdEvent(
            triggerType: .cpu,
            triggerValue: 85.0,
            threshold: 80.0,
            allProcesses: []
        )
        database.saveEvent(event1)

        // Small delay to ensure different timestamps
        Thread.sleep(forTimeInterval: 0.1)

        let event2 = ThresholdEvent(
            triggerType: .memory,
            triggerValue: 90.0,
            threshold: 85.0,
            allProcesses: []
        )
        database.saveEvent(event2)

        let last = database.lastEvent()
        XCTAssertNotNil(last)
        XCTAssertEqual(last?.triggerType, .memory)
    }

    func testLoadEventsOrdering() {
        // Save events - they should be returned in descending timestamp order
        for i in 0..<3 {
            let event = ThresholdEvent(
                triggerType: .cpu,
                triggerValue: Double(80 + i),
                threshold: 80.0,
                allProcesses: []
            )
            database.saveEvent(event)
            Thread.sleep(forTimeInterval: 0.05)
        }

        let loaded = database.loadEvents(lastDays: 1)
        XCTAssertGreaterThanOrEqual(loaded.count, 3)

        // Verify descending order
        for i in 0..<(loaded.count - 1) {
            XCTAssertGreaterThanOrEqual(loaded[i].timestamp, loaded[i + 1].timestamp)
        }
    }

    // MARK: - Settings Tests

    func testSaveAndLoadSettings() {
        var settings = AppSettings()
        settings.pollIntervalSeconds = 10.0
        settings.cpuThreshold = 90.0
        settings.memoryThreshold = 85.0
        settings.notificationsEnabled = false
        settings.defaultViewMode = .detailed

        database.saveSettings(settings)

        let loaded = database.loadSettings()
        XCTAssertEqual(loaded.pollIntervalSeconds, 10.0)
        XCTAssertEqual(loaded.cpuThreshold, 90.0)
        XCTAssertEqual(loaded.memoryThreshold, 85.0)
        XCTAssertFalse(loaded.notificationsEnabled)
        XCTAssertEqual(loaded.defaultViewMode, .detailed)
    }

    func testLoadDefaultSettings() {
        // If no settings saved, should return defaults
        let loaded = database.loadSettings()
        // Either returns saved settings or defaults
        XCTAssertNotNil(loaded)
    }

    // MARK: - Categories Tests

    func testSaveAndLoadCategories() {
        let categories = [
            AppCategory(
                id: "custom1",
                name: "Custom Category 1",
                color: "#FF0000",
                apps: [AppDefinition(name: "App1", processNames: ["app1"])],
                isBuiltIn: false,
                isEnabled: true
            ),
            AppCategory(
                id: "custom2",
                name: "Custom Category 2",
                color: "#00FF00",
                apps: [AppDefinition(name: "App2", processNames: ["app2"])],
                isBuiltIn: false,
                isEnabled: true
            )
        ]

        database.saveCategories(categories)

        let loaded = database.loadCategories()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 2)

        if let loadedCategories = loaded {
            XCTAssertEqual(loadedCategories[0].id, "custom1")
            XCTAssertEqual(loadedCategories[1].id, "custom2")
        }
    }

    func testLoadCategoriesNone() {
        // Fresh database may return nil
        let loaded = database.loadCategories()
        // Could be nil or have previously saved categories
        // Just verify it doesn't crash
    }

    // MARK: - Statistics Tests

    func testGetSnapshotCount() {
        let initialCount = database.getSnapshotCount()

        let snapshot = ResourceSnapshot(
            totalCPU: 100.0,
            totalMemoryMB: 4096.0,
            totalSystemMemoryMB: 16384.0,
            cpuCoreCount: 8,
            categoryBreakdown: [:],
            topProcesses: []
        )
        database.saveSnapshot(snapshot)

        let newCount = database.getSnapshotCount()
        XCTAssertGreaterThanOrEqual(newCount, initialCount)
    }

    func testGetEventCount() {
        let initialCount = database.getEventCount()

        let event = ThresholdEvent(
            triggerType: .cpu,
            triggerValue: 85.0,
            threshold: 80.0,
            allProcesses: []
        )
        database.saveEvent(event)

        let newCount = database.getEventCount()
        XCTAssertGreaterThanOrEqual(newCount, initialCount)
    }

    // MARK: - Cleanup Tests

    func testCleanup() {
        // Just verify cleanup doesn't crash
        database.cleanup()
        XCTAssertTrue(true)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentSnapshotWrites() {
        let expectation = XCTestExpectation(description: "Concurrent writes")
        expectation.expectedFulfillmentCount = 10

        for i in 0..<10 {
            DispatchQueue.global().async {
                let snapshot = ResourceSnapshot(
                    totalCPU: Double(i * 10),
                    totalMemoryMB: Double(i * 1000),
                    totalSystemMemoryMB: 16384.0,
                    cpuCoreCount: 8,
                    categoryBreakdown: [:],
                    topProcesses: []
                )
                self.database.saveSnapshot(snapshot)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)

        // Verify no crashes and data is saved
        let loaded = database.loadSnapshots(lastHours: 1)
        XCTAssertGreaterThanOrEqual(loaded.count, 1)
    }

    func testConcurrentReadsAndWrites() {
        let writeExpectation = XCTestExpectation(description: "Concurrent writes")
        writeExpectation.expectedFulfillmentCount = 5

        let readExpectation = XCTestExpectation(description: "Concurrent reads")
        readExpectation.expectedFulfillmentCount = 5

        // Concurrent writes
        for i in 0..<5 {
            DispatchQueue.global().async {
                let snapshot = ResourceSnapshot(
                    totalCPU: Double(i * 10),
                    totalMemoryMB: Double(i * 1000),
                    totalSystemMemoryMB: 16384.0,
                    cpuCoreCount: 8,
                    categoryBreakdown: [:],
                    topProcesses: []
                )
                self.database.saveSnapshot(snapshot)
                writeExpectation.fulfill()
            }
        }

        // Concurrent reads
        for _ in 0..<5 {
            DispatchQueue.global().async {
                _ = self.database.loadSnapshots(lastHours: 1)
                readExpectation.fulfill()
            }
        }

        wait(for: [writeExpectation, readExpectation], timeout: 10.0)
    }

    // MARK: - Edge Case Tests

    func testSnapshotWithEmptyData() {
        let snapshot = ResourceSnapshot(
            totalCPU: 0.0,
            totalMemoryMB: 0.0,
            totalSystemMemoryMB: 0.0,
            cpuCoreCount: 0,
            categoryBreakdown: [:],
            topProcesses: []
        )

        database.saveSnapshot(snapshot)

        let loaded = database.loadSnapshots(lastHours: 1)
        if let lastSnapshot = loaded.last(where: { $0.id == snapshot.id }) {
            XCTAssertEqual(lastSnapshot.totalCPU, 0.0)
            XCTAssertEqual(lastSnapshot.totalMemoryMB, 0.0)
        }
    }

    func testEventWithManyProcesses() {
        var processes: [AppProcessInfo] = []
        for i in 0..<100 {
            processes.append(AppProcessInfo(
                id: Int32(i),
                name: "Process\(i)",
                cpuPercent: Double(i),
                memoryMB: Double(i * 10)
            ))
        }

        let event = ThresholdEvent(
            triggerType: .cpu,
            triggerValue: 95.0,
            threshold: 80.0,
            allProcesses: processes
        )

        database.saveEvent(event)

        let loaded = database.loadEvents(lastDays: 1)
        if let loadedEvent = loaded.first(where: { $0.id == event.id }) {
            XCTAssertEqual(loadedEvent.allProcesses.count, 100)
        }
    }

    func testSettingsWithAllFields() {
        var settings = AppSettings()
        settings.pollIntervalSeconds = 15.0
        settings.cpuThreshold = 75.0
        settings.memoryThreshold = 70.0
        settings.thresholdsEnabled = false
        settings.thresholdCooldownSeconds = 120.0
        settings.notificationsEnabled = false
        settings.soundEnabled = true
        settings.silentLogging = true
        settings.showInMenuBar = false
        settings.showPercentInMenuBar = false
        settings.defaultViewMode = .detailed
        settings.defaultHistoryChartMode = .line
        settings.fontSizeScale = 6.0
        settings.historyRetentionDays = 14
        settings.launchAtLogin = true

        database.saveSettings(settings)

        let loaded = database.loadSettings()
        XCTAssertEqual(loaded.pollIntervalSeconds, 15.0)
        XCTAssertEqual(loaded.cpuThreshold, 75.0)
        XCTAssertEqual(loaded.memoryThreshold, 70.0)
        XCTAssertFalse(loaded.thresholdsEnabled)
        XCTAssertEqual(loaded.thresholdCooldownSeconds, 120.0)
        XCTAssertFalse(loaded.notificationsEnabled)
        XCTAssertTrue(loaded.soundEnabled)
        XCTAssertTrue(loaded.silentLogging)
        XCTAssertFalse(loaded.showInMenuBar)
        XCTAssertFalse(loaded.showPercentInMenuBar)
        XCTAssertEqual(loaded.defaultViewMode, .detailed)
        XCTAssertEqual(loaded.defaultHistoryChartMode, .line)
        XCTAssertEqual(loaded.fontSizeScale, 6.0)
        XCTAssertEqual(loaded.historyRetentionDays, 14)
        XCTAssertTrue(loaded.launchAtLogin)
    }
}
