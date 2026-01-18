import Foundation
import SwiftUI

// MARK: - Font Scale Manager

/// Manages the configurable font size scale
enum FontScaleManager {
    private static let defaultScale: CGFloat = 4.0

    /// Current font size scale (reads from UserDefaults)
    static var sizeIncrease: CGFloat {
        let scale = UserDefaults.standard.double(forKey: "fontSizeScale")
        return scale > 0 ? CGFloat(scale) : defaultScale
    }
}

// MARK: - Font Extensions (Scaled with configurable increase)

extension Font {
    // Scaled semantic fonts (configurable increase from system defaults)
    static var scaledLargeTitle: Font { .system(size: 30 + FontScaleManager.sizeIncrease) }
    static var scaledTitle: Font { .system(size: 26 + FontScaleManager.sizeIncrease) }
    static var scaledTitle2: Font { .system(size: 21 + FontScaleManager.sizeIncrease) }
    static var scaledTitle3: Font { .system(size: 18 + FontScaleManager.sizeIncrease) }
    static var scaledHeadline: Font { .system(size: 17 + FontScaleManager.sizeIncrease, weight: .semibold) }
    static var scaledSubheadline: Font { .system(size: 15 + FontScaleManager.sizeIncrease) }
    static var scaledBody: Font { .system(size: 17 + FontScaleManager.sizeIncrease) }
    static var scaledCallout: Font { .system(size: 15 + FontScaleManager.sizeIncrease) }
    static var scaledFootnote: Font { .system(size: 14 + FontScaleManager.sizeIncrease) }
    static var scaledCaption: Font { .system(size: 13 + FontScaleManager.sizeIncrease) }
    static var scaledCaption2: Font { .system(size: 12 + FontScaleManager.sizeIncrease) }

    /// Scaled system font with custom size
    static func scaledSystem(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        .system(size: size + FontScaleManager.sizeIncrease, weight: weight, design: design)
    }

    /// Scaled monospaced body font
    static var scaledMonospacedBody: Font {
        .system(size: 17 + FontScaleManager.sizeIncrease, design: .monospaced)
    }
}

// MARK: - Date Extensions

extension Date {
    /// Start of the current day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of the current day
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
    }

    /// Check if date is within the last N hours
    func isWithinLast(hours: Int) -> Bool {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -hours, to: Date())!
        return self >= cutoff
    }

    /// Check if date is within the last N days
    func isWithinLast(days: Int) -> Bool {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return self >= cutoff
    }
}

// MARK: - Array Extensions

extension Array {
    /// Safely access an element at an index
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Array where Element: Numeric {
    /// Sum of all elements
    var sum: Element {
        reduce(0, +)
    }
}

extension Array where Element: BinaryFloatingPoint {
    /// Average of all elements
    var average: Element {
        guard !isEmpty else { return 0 }
        return sum / Element(count)
    }
}

// MARK: - String Extensions

extension String {
    /// Truncate string to a maximum length
    func truncated(to maxLength: Int, trailing: String = "...") -> String {
        if count <= maxLength {
            return self
        }
        return String(prefix(maxLength - trailing.count)) + trailing
    }
}

// MARK: - View Extensions

extension View {
    /// Apply a modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Round specific corners
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int

    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)

    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
    static let top: RectCorner = [.topLeft, .topRight]
    static let bottom: RectCorner = [.bottomLeft, .bottomRight]
}

struct RoundedCornerShape: Shape {
    let radius: CGFloat
    let corners: RectCorner

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let topLeft = corners.contains(.topLeft) ? radius : 0
        let topRight = corners.contains(.topRight) ? radius : 0
        let bottomLeft = corners.contains(.bottomLeft) ? radius : 0
        let bottomRight = corners.contains(.bottomRight) ? radius : 0

        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight),
                    radius: topRight, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        path.addArc(center: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight),
                    radius: bottomRight, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft),
                    radius: bottomLeft, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        path.addArc(center: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft),
                    radius: topLeft, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)

        return path
    }
}

// MARK: - Binding Extensions

extension Binding {
    /// Create a binding with a custom setter that performs additional actions
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

// MARK: - Double Extensions

extension Double {
    /// Clamp value to a range
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }

    /// Round to specified decimal places
    func rounded(to places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}
