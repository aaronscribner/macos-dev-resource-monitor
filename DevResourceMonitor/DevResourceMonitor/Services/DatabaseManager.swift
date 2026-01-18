import Foundation
import SQLite3

/// SQLite-based storage manager for resource snapshots and threshold events
class DatabaseManager {
    private var db: OpaquePointer?
    private let dbPath: URL
    private let retentionDays: Int

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Serial queue to ensure thread-safe database access
    private let queue = DispatchQueue(label: "com.devresourcemonitor.database", qos: .userInitiated)

    init(retentionDays: Int = 7) {
        self.retentionDays = retentionDays

        // Set up encoder/decoder for JSON fields
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Set up database path
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("DevResourceMonitor", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        dbPath = appDir.appendingPathComponent("monitor.db")

        // Open database and create tables (synchronous on queue)
        queue.sync {
            self.openDatabaseInternal()
            self.createTablesInternal()
        }

        // Cleanup old data
        cleanup()
    }

    deinit {
        _ = queue.sync {
            sqlite3_close(db)
        }
    }

    // MARK: - Database Setup (Internal - must be called on queue)

    private func openDatabaseInternal() {
        let result = sqlite3_open(dbPath.path, &db)
        if result != SQLITE_OK {
            print("Error opening database at \(dbPath.path): \(errorMessageInternal()) (code: \(result))")
            db = nil
        } else {
            print("Database opened successfully at \(dbPath.path)")
        }
    }

    private var isOpen: Bool {
        return db != nil
    }

    private func errorMessageInternal() -> String {
        if let db = db {
            return String(cString: sqlite3_errmsg(db))
        }
        return "Database not open"
    }

    private func createTablesInternal() {
        // Create snapshots table
        executeSQLInternal("""
            CREATE TABLE IF NOT EXISTS snapshots (
                id TEXT PRIMARY KEY,
                timestamp REAL NOT NULL,
                total_cpu REAL NOT NULL,
                total_memory_mb REAL NOT NULL,
                total_system_memory_mb REAL NOT NULL,
                category_breakdown TEXT NOT NULL,
                top_processes TEXT NOT NULL
            )
        """)
        executeSQLInternal("CREATE INDEX IF NOT EXISTS idx_snapshots_timestamp ON snapshots(timestamp)")

        // Create threshold events table
        executeSQLInternal("""
            CREATE TABLE IF NOT EXISTS threshold_events (
                id TEXT PRIMARY KEY,
                timestamp REAL NOT NULL,
                trigger_type TEXT NOT NULL,
                trigger_value REAL NOT NULL,
                threshold REAL NOT NULL,
                all_processes TEXT NOT NULL
            )
        """)
        executeSQLInternal("CREATE INDEX IF NOT EXISTS idx_events_timestamp ON threshold_events(timestamp)")

        // Create settings table
        executeSQLInternal("""
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            )
        """)

        // Create categories table
        executeSQLInternal("""
            CREATE TABLE IF NOT EXISTS categories (
                id TEXT PRIMARY KEY,
                data TEXT NOT NULL
            )
        """)
    }

    private func executeSQLInternal(_ sql: String) {
        guard isOpen else {
            print("Database not open, cannot execute SQL")
            return
        }
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            if let errMsg = errMsg {
                print("SQL Error: \(String(cString: errMsg))")
                sqlite3_free(errMsg)
            }
        }
    }

    // MARK: - Snapshots

    func saveSnapshot(_ snapshot: ResourceSnapshot) {
        queue.sync {
            saveSnapshotInternal(snapshot)
        }
    }

    private func saveSnapshotInternal(_ snapshot: ResourceSnapshot) {
        guard isOpen else { return }

        let sql = """
        INSERT OR REPLACE INTO snapshots
        (id, timestamp, total_cpu, total_memory_mb, total_system_memory_mb, category_breakdown, top_processes)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing save snapshot statement: \(errorMessageInternal())")
            return
        }
        defer { sqlite3_finalize(statement) }

        let categoryJSON = (try? encoder.encode(snapshot.categoryBreakdown)) ?? Data()
        let processesJSON = (try? encoder.encode(snapshot.topProcesses)) ?? Data()

        sqlite3_bind_text(statement, 1, snapshot.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(statement, 2, snapshot.timestamp.timeIntervalSince1970)
        sqlite3_bind_double(statement, 3, snapshot.totalCPU)
        sqlite3_bind_double(statement, 4, snapshot.totalMemoryMB)
        sqlite3_bind_double(statement, 5, snapshot.totalSystemMemoryMB)
        sqlite3_bind_text(statement, 6, String(data: categoryJSON, encoding: .utf8), -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 7, String(data: processesJSON, encoding: .utf8), -1, SQLITE_TRANSIENT)

        if sqlite3_step(statement) != SQLITE_DONE {
            print("Error saving snapshot: \(errorMessageInternal())")
        }
    }

    func loadSnapshots(from startDate: Date, to endDate: Date) -> [ResourceSnapshot] {
        return queue.sync {
            loadSnapshotsInternal(from: startDate, to: endDate)
        }
    }

    private func loadSnapshotsInternal(from startDate: Date, to endDate: Date) -> [ResourceSnapshot] {
        guard isOpen else { return [] }

        let sql = """
        SELECT id, timestamp, total_cpu, total_memory_mb, total_system_memory_mb, category_breakdown, top_processes
        FROM snapshots
        WHERE timestamp >= ? AND timestamp <= ?
        ORDER BY timestamp ASC
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing load snapshots statement: \(errorMessageInternal())")
            return []
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_double(statement, 1, startDate.timeIntervalSince1970)
        sqlite3_bind_double(statement, 2, endDate.timeIntervalSince1970)

        var snapshots: [ResourceSnapshot] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idStr = sqlite3_column_text(statement, 0),
                  let id = UUID(uuidString: String(cString: idStr)),
                  let categoryStr = sqlite3_column_text(statement, 5),
                  let processesStr = sqlite3_column_text(statement, 6) else {
                continue
            }

            let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
            let totalCPU = sqlite3_column_double(statement, 2)
            let totalMemoryMB = sqlite3_column_double(statement, 3)
            let totalSystemMemoryMB = sqlite3_column_double(statement, 4)

            let categoryData = String(cString: categoryStr).data(using: .utf8) ?? Data()
            let processesData = String(cString: processesStr).data(using: .utf8) ?? Data()

            let categoryBreakdown = (try? decoder.decode([String: ResourceUsage].self, from: categoryData)) ?? [:]
            let topProcesses = (try? decoder.decode([ProcessInfo].self, from: processesData)) ?? []

            let snapshot = ResourceSnapshot(
                id: id,
                timestamp: timestamp,
                totalCPU: totalCPU,
                totalMemoryMB: totalMemoryMB,
                totalSystemMemoryMB: totalSystemMemoryMB,
                categoryBreakdown: categoryBreakdown,
                topProcesses: topProcesses
            )
            snapshots.append(snapshot)
        }

        return snapshots
    }

    func loadSnapshots(lastHours hours: Int) -> [ResourceSnapshot] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -hours, to: endDate) ?? endDate
        return loadSnapshots(from: startDate, to: endDate)
    }

    func loadSnapshots(lastDays days: Int) -> [ResourceSnapshot] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        return loadSnapshots(from: startDate, to: endDate)
    }

    // MARK: - Threshold Events

    func saveEvent(_ event: ThresholdEvent) {
        queue.sync {
            saveEventInternal(event)
        }
    }

    private func saveEventInternal(_ event: ThresholdEvent) {
        guard isOpen else { return }

        let sql = """
        INSERT OR REPLACE INTO threshold_events
        (id, timestamp, trigger_type, trigger_value, threshold, all_processes)
        VALUES (?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing save event statement: \(errorMessageInternal())")
            return
        }
        defer { sqlite3_finalize(statement) }

        let processesJSON = (try? encoder.encode(event.allProcesses)) ?? Data()

        sqlite3_bind_text(statement, 1, event.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(statement, 2, event.timestamp.timeIntervalSince1970)
        sqlite3_bind_text(statement, 3, event.triggerType.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(statement, 4, event.triggerValue)
        sqlite3_bind_double(statement, 5, event.threshold)
        sqlite3_bind_text(statement, 6, String(data: processesJSON, encoding: .utf8), -1, SQLITE_TRANSIENT)

        if sqlite3_step(statement) != SQLITE_DONE {
            print("Error saving event: \(errorMessageInternal())")
        }
    }

    func loadEvents(lastDays days: Int) -> [ThresholdEvent] {
        return queue.sync {
            loadEventsInternal(lastDays: days)
        }
    }

    private func loadEventsInternal(lastDays days: Int) -> [ThresholdEvent] {
        guard isOpen else { return [] }

        let sql = """
        SELECT id, timestamp, trigger_type, trigger_value, threshold, all_processes
        FROM threshold_events
        WHERE timestamp >= ?
        ORDER BY timestamp DESC
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing load events statement: \(errorMessageInternal())")
            return []
        }
        defer { sqlite3_finalize(statement) }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        sqlite3_bind_double(statement, 1, cutoffDate.timeIntervalSince1970)

        var events: [ThresholdEvent] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idStr = sqlite3_column_text(statement, 0),
                  let id = UUID(uuidString: String(cString: idStr)),
                  let triggerTypeStr = sqlite3_column_text(statement, 2),
                  let triggerType = ThresholdEvent.TriggerType(rawValue: String(cString: triggerTypeStr)),
                  let processesStr = sqlite3_column_text(statement, 5) else {
                continue
            }

            let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
            let triggerValue = sqlite3_column_double(statement, 3)
            let threshold = sqlite3_column_double(statement, 4)

            let processesData = String(cString: processesStr).data(using: .utf8) ?? Data()
            let allProcesses = (try? decoder.decode([ProcessInfo].self, from: processesData)) ?? []

            let event = ThresholdEvent(
                id: id,
                timestamp: timestamp,
                triggerType: triggerType,
                triggerValue: triggerValue,
                threshold: threshold,
                allProcesses: allProcesses
            )
            events.append(event)
        }

        return events
    }

    func lastEvent() -> ThresholdEvent? {
        return loadEvents(lastDays: 7).first
    }

    // MARK: - Settings

    func loadSettings() -> AppSettings {
        return queue.sync {
            loadSettingsInternal()
        }
    }

    private func loadSettingsInternal() -> AppSettings {
        guard isOpen else { return AppSettings.default }

        let sql = "SELECT value FROM settings WHERE key = 'app_settings'"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return AppSettings.default
        }
        defer { sqlite3_finalize(statement) }

        if sqlite3_step(statement) == SQLITE_ROW,
           let valueStr = sqlite3_column_text(statement, 0) {
            let data = String(cString: valueStr).data(using: .utf8) ?? Data()
            if let settings = try? decoder.decode(AppSettings.self, from: data) {
                return settings
            }
        }

        return AppSettings.default
    }

    func saveSettings(_ settings: AppSettings) {
        queue.sync {
            saveSettingsInternal(settings)
        }
    }

    private func saveSettingsInternal(_ settings: AppSettings) {
        guard isOpen else { return }

        let sql = "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing save settings statement: \(errorMessageInternal())")
            return
        }
        defer { sqlite3_finalize(statement) }

        guard let data = try? encoder.encode(settings),
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }

        sqlite3_bind_text(statement, 1, "app_settings", -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, jsonString, -1, SQLITE_TRANSIENT)

        if sqlite3_step(statement) != SQLITE_DONE {
            print("Error saving settings: \(errorMessageInternal())")
        }
    }

    // MARK: - Categories

    func loadCategories() -> [AppCategory]? {
        return queue.sync {
            loadCategoriesInternal()
        }
    }

    private func loadCategoriesInternal() -> [AppCategory]? {
        guard isOpen else { return nil }

        let sql = "SELECT data FROM categories WHERE id = 'all_categories'"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_finalize(statement) }

        if sqlite3_step(statement) == SQLITE_ROW,
           let valueStr = sqlite3_column_text(statement, 0) {
            let data = String(cString: valueStr).data(using: .utf8) ?? Data()
            if let container = try? decoder.decode(CategoriesContainer.self, from: data) {
                return container.categories
            }
        }

        return nil
    }

    func saveCategories(_ categories: [AppCategory]) {
        queue.sync {
            saveCategoriesInternal(categories)
        }
    }

    private func saveCategoriesInternal(_ categories: [AppCategory]) {
        guard isOpen else { return }

        let sql = "INSERT OR REPLACE INTO categories (id, data) VALUES (?, ?)"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing save categories statement: \(errorMessageInternal())")
            return
        }
        defer { sqlite3_finalize(statement) }

        let container = CategoriesContainer(categories: categories)
        guard let data = try? encoder.encode(container),
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }

        sqlite3_bind_text(statement, 1, "all_categories", -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, jsonString, -1, SQLITE_TRANSIENT)

        if sqlite3_step(statement) != SQLITE_DONE {
            print("Error saving categories: \(errorMessageInternal())")
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        queue.sync {
            cleanupInternal()
        }
    }

    private func cleanupInternal() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        let cutoffTimestamp = cutoffDate.timeIntervalSince1970

        let deleteSnapshots = "DELETE FROM snapshots WHERE timestamp < \(cutoffTimestamp)"
        let deleteEvents = "DELETE FROM threshold_events WHERE timestamp < \(cutoffTimestamp)"

        executeSQLInternal(deleteSnapshots)
        executeSQLInternal(deleteEvents)

        // Vacuum to reclaim space
        executeSQLInternal("VACUUM")
    }

    // MARK: - Statistics

    func getSnapshotCount() -> Int {
        return queue.sync {
            getSnapshotCountInternal()
        }
    }

    private func getSnapshotCountInternal() -> Int {
        guard isOpen else { return 0 }

        let sql = "SELECT COUNT(*) FROM snapshots"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_finalize(statement) }

        if sqlite3_step(statement) == SQLITE_ROW {
            return Int(sqlite3_column_int(statement, 0))
        }
        return 0
    }

    func getEventCount() -> Int {
        return queue.sync {
            getEventCountInternal()
        }
    }

    private func getEventCountInternal() -> Int {
        guard isOpen else { return 0 }

        let sql = "SELECT COUNT(*) FROM threshold_events"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_finalize(statement) }

        if sqlite3_step(statement) == SQLITE_ROW {
            return Int(sqlite3_column_int(statement, 0))
        }
        return 0
    }
}

// MARK: - SQLite Transient

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
