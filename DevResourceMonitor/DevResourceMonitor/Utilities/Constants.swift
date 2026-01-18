import Foundation
import SwiftUI

/// App-wide constants
enum Constants {
    // MARK: - App Info

    static let appName = "DevResourceMonitor"
    static let appVersion = "1.0.0"

    // MARK: - Polling

    static let defaultPollInterval: TimeInterval = 5.0
    static let minPollInterval: TimeInterval = 1.0
    static let maxPollInterval: TimeInterval = 60.0

    // MARK: - Thresholds

    static let defaultCPUThreshold: Double = 80.0
    static let defaultMemoryThreshold: Double = 80.0
    static let defaultCooldownDuration: TimeInterval = 60.0

    // MARK: - History

    static let defaultRetentionDays = 30
    static let maxRetentionDays = 365
    static let snapshotSaveInterval: TimeInterval = 60.0  // Save every minute

    // MARK: - UI

    static let menuBarPopoverWidth: CGFloat = 320
    static let menuBarPopoverHeight: CGFloat = 400
    static let mainWindowMinWidth: CGFloat = 800
    static let mainWindowMinHeight: CGFloat = 600

    // MARK: - Charts

    static let defaultChartBuckets = 30
    static let pieChartInnerRadius: CGFloat = 0.5

    // MARK: - Colors

    enum Colors {
        static let cpu = Color.blue
        static let memory = Color.green
        static let warning = Color.orange
        static let danger = Color.red
        static let success = Color.green
        static let neutral = Color.gray

        // Category default colors
        static let categoryColors: [String] = [
            "#007AFF",  // Blue
            "#34C759",  // Green
            "#FF9500",  // Orange
            "#AF52DE",  // Purple
            "#5856D6",  // Indigo
            "#FF3B30",  // Red
            "#00C7BE",  // Teal
            "#FF2D55",  // Pink
            "#5AC8FA",  // Light Blue
            "#FFCC00"   // Yellow
        ]
    }

    // MARK: - File Paths

    enum Paths {
        static let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("DevResourceMonitor", isDirectory: true)

        static let history = appSupport.appendingPathComponent("history", isDirectory: true)
        static let events = appSupport.appendingPathComponent("threshold-events", isDirectory: true)
        static let settings = appSupport.appendingPathComponent("settings.json")
        static let categories = appSupport.appendingPathComponent("categories.json")
    }

    // MARK: - Keyboard Shortcuts

    enum Shortcuts {
        static let refresh = KeyEquivalent("r")
        static let settings = KeyEquivalent(",")
        static let quit = KeyEquivalent("q")
    }
}
