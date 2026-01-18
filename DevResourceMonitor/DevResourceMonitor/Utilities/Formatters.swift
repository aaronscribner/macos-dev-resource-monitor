import Foundation

/// Formatting utilities for display
enum Formatters {
    // MARK: - Number Formatters

    /// Format a percentage value (e.g., "45.2%")
    static func percentage(_ value: Double, decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f%%", value)
    }

    /// Format memory in MB or GB as appropriate
    static func memory(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        } else if mb >= 100 {
            return String(format: "%.0f MB", mb)
        } else {
            return String(format: "%.1f MB", mb)
        }
    }

    /// Format memory with full precision
    static func memoryDetailed(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.2f GB", mb / 1024)
        } else {
            return String(format: "%.1f MB", mb)
        }
    }

    /// Format CPU percentage
    static func cpu(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f%%", value)
        } else if value >= 10 {
            return String(format: "%.1f%%", value)
        } else {
            return String(format: "%.2f%%", value)
        }
    }

    /// Format a number with thousands separator
    static func number(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Date Formatters

    /// Format a date for display in charts (time only for today, date for older)
    static func chartDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return timeFormatter.string(from: date)
        } else {
            return shortDateFormatter.string(from: date)
        }
    }

    /// Format a date with time
    static func dateTime(_ date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    /// Format time only
    static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// Format relative time (e.g., "5 minutes ago")
    static func relativeTime(_ date: Date) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Private Formatters

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    // MARK: - Duration Formatting

    /// Format a duration in seconds to human readable
    static func duration(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "< 1 min"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes) min"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d"
        }
    }

    // MARK: - Trend Formatting

    /// Format a percentage change with sign
    static func percentChange(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", value))%"
    }
}
