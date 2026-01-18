import Foundation

/// User preferences and settings
struct AppSettings: Codable {
    // Polling
    var pollIntervalSeconds: Double = 5.0

    // Thresholds
    var cpuThreshold: Double = 80.0
    var memoryThreshold: Double = 80.0
    var thresholdsEnabled: Bool = true
    var thresholdCooldownSeconds: Double = 60.0

    // Notifications
    var notificationsEnabled: Bool = true
    var soundEnabled: Bool = false
    var silentLogging: Bool = false

    // Display
    var showInMenuBar: Bool = true
    var showPercentInMenuBar: Bool = true
    var defaultViewMode: ViewMode = .grouped
    var defaultHistoryChartMode: HistoryChartMode = .bar
    var fontSizeScale: Double = 4.0  // Additional points added to base font sizes

    // History
    var historyRetentionDays: Int = 30

    // Launch
    var launchAtLogin: Bool = false

    enum ViewMode: String, Codable, CaseIterable {
        case grouped = "Grouped"
        case detailed = "Detailed"
    }

    enum HistoryChartMode: String, Codable, CaseIterable {
        case bar = "Bar"
        case line = "Line"
    }

    static let `default` = AppSettings()
}

/// Keys for UserDefaults storage
enum SettingsKey: String {
    case pollInterval = "pollIntervalSeconds"
    case cpuThreshold = "cpuThreshold"
    case memoryThreshold = "memoryThreshold"
    case thresholdsEnabled = "thresholdsEnabled"
    case thresholdCooldown = "thresholdCooldownSeconds"
    case notificationsEnabled = "notificationsEnabled"
    case soundEnabled = "soundEnabled"
    case silentLogging = "silentLogging"
    case showInMenuBar = "showInMenuBar"
    case showPercentInMenuBar = "showPercentInMenuBar"
    case defaultViewMode = "defaultViewMode"
    case defaultHistoryChartMode = "defaultHistoryChartMode"
    case fontSizeScale = "fontSizeScale"
    case historyRetentionDays = "historyRetentionDays"
    case launchAtLogin = "launchAtLogin"
}
