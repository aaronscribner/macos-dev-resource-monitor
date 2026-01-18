import Foundation

/// Manages persistence of history data and threshold events using SQLite
class HistoryManager: @unchecked Sendable {
    private let database: DatabaseManager

    init(retentionDays: Int = 7) {
        database = DatabaseManager(retentionDays: retentionDays)
    }

    // MARK: - History Snapshots

    /// Save a resource snapshot
    func saveSnapshot(_ snapshot: ResourceSnapshot) {
        database.saveSnapshot(snapshot)
    }

    /// Load snapshots for a date range
    func loadSnapshots(from startDate: Date, to endDate: Date) -> [ResourceSnapshot] {
        database.loadSnapshots(from: startDate, to: endDate)
    }

    /// Load snapshots for the last N hours
    func loadSnapshots(lastHours hours: Int) -> [ResourceSnapshot] {
        database.loadSnapshots(lastHours: hours)
    }

    /// Load snapshots for the last N days
    func loadSnapshots(lastDays days: Int) -> [ResourceSnapshot] {
        database.loadSnapshots(lastDays: days)
    }

    // MARK: - Threshold Events

    /// Save a threshold event
    func saveEvent(_ event: ThresholdEvent) {
        database.saveEvent(event)
    }

    /// Load all events for the last N days
    func loadEvents(lastDays days: Int) -> [ThresholdEvent] {
        database.loadEvents(lastDays: days)
    }

    /// Get the most recent threshold event
    func lastEvent() -> ThresholdEvent? {
        database.lastEvent()
    }

    // MARK: - Cleanup

    /// Remove history older than retention period
    func cleanup(keepDays: Int) {
        database.cleanup()
    }

    // MARK: - Categories

    /// Load custom categories
    func loadCategories() -> [AppCategory]? {
        database.loadCategories()
    }

    /// Save custom categories
    func saveCategories(_ categories: [AppCategory]) {
        database.saveCategories(categories)
    }

    // MARK: - Settings

    /// Load settings
    func loadSettings() -> AppSettings {
        database.loadSettings()
    }

    /// Save settings
    func saveSettings(_ settings: AppSettings) {
        database.saveSettings(settings)
    }

    // MARK: - Statistics

    var snapshotCount: Int {
        database.getSnapshotCount()
    }

    var eventCount: Int {
        database.getEventCount()
    }
}
