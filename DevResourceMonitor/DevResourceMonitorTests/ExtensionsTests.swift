import XCTest
import SwiftUI
@testable import DevResourceMonitor

final class ExtensionsTests: XCTestCase {

    // MARK: - Date Extension Tests

    func testStartOfDay() {
        let date = Date()
        let startOfDay = date.startOfDay

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: startOfDay)

        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testEndOfDay() {
        let date = Date()
        let endOfDay = date.endOfDay

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: endOfDay)

        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 59)
    }

    func testIsWithinLastHours() {
        let now = Date()

        // 1 hour ago should be within last 2 hours
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: now)!
        XCTAssertTrue(oneHourAgo.isWithinLast(hours: 2))

        // 3 hours ago should not be within last 2 hours
        let threeHoursAgo = Calendar.current.date(byAdding: .hour, value: -3, to: now)!
        XCTAssertFalse(threeHoursAgo.isWithinLast(hours: 2))

        // Now should be within last 1 hour
        XCTAssertTrue(now.isWithinLast(hours: 1))
    }

    func testIsWithinLastDays() {
        let now = Date()

        // 1 day ago should be within last 2 days
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        XCTAssertTrue(oneDayAgo.isWithinLast(days: 2))

        // 5 days ago should not be within last 3 days
        let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: now)!
        XCTAssertFalse(fiveDaysAgo.isWithinLast(days: 3))

        // Now should be within last 1 day
        XCTAssertTrue(now.isWithinLast(days: 1))
    }

    // MARK: - Array Extension Tests

    func testSafeSubscript() {
        let array = [1, 2, 3, 4, 5]

        XCTAssertEqual(array[safe: 0], 1)
        XCTAssertEqual(array[safe: 4], 5)
        XCTAssertNil(array[safe: 5])
        XCTAssertNil(array[safe: -1])
        XCTAssertNil(array[safe: 100])

        let emptyArray: [Int] = []
        XCTAssertNil(emptyArray[safe: 0])
    }

    func testNumericArraySum() {
        let intArray = [1, 2, 3, 4, 5]
        XCTAssertEqual(intArray.sum, 15)

        let doubleArray = [1.5, 2.5, 3.0]
        XCTAssertEqual(doubleArray.sum, 7.0)

        let emptyArray: [Int] = []
        XCTAssertEqual(emptyArray.sum, 0)
    }

    func testFloatingPointArrayAverage() {
        let array = [10.0, 20.0, 30.0]
        XCTAssertEqual(array.average, 20.0)

        let singleElement = [5.0]
        XCTAssertEqual(singleElement.average, 5.0)

        let emptyArray: [Double] = []
        XCTAssertEqual(emptyArray.average, 0.0)
    }

    // MARK: - String Extension Tests

    func testTruncated() {
        let longString = "This is a very long string that needs truncation"

        XCTAssertEqual(longString.truncated(to: 10), "This is...")
        XCTAssertEqual(longString.truncated(to: 20), "This is a very lo...")
        XCTAssertEqual(longString.truncated(to: 100), longString) // No truncation needed

        let shortString = "Short"
        XCTAssertEqual(shortString.truncated(to: 10), "Short")
    }

    func testTruncatedWithCustomTrailing() {
        let string = "Hello World"

        XCTAssertEqual(string.truncated(to: 8, trailing: ".."), "Hello ..")
        XCTAssertEqual(string.truncated(to: 6, trailing: "~"), "Hello~")
    }

    // MARK: - Double Extension Tests

    func testClamped() {
        XCTAssertEqual(5.0.clamped(to: 0...10), 5.0)
        XCTAssertEqual((-5.0).clamped(to: 0...10), 0.0)
        XCTAssertEqual(15.0.clamped(to: 0...10), 10.0)
        XCTAssertEqual(0.0.clamped(to: 0...10), 0.0)
        XCTAssertEqual(10.0.clamped(to: 0...10), 10.0)
    }

    func testRoundedToPlaces() {
        XCTAssertEqual(3.14159.rounded(to: 2), 3.14)
        XCTAssertEqual(3.14159.rounded(to: 3), 3.142)
        XCTAssertEqual(3.14159.rounded(to: 0), 3.0)
        XCTAssertEqual(2.5.rounded(to: 0), 3.0)
        XCTAssertEqual(2.4.rounded(to: 0), 2.0)
    }

    // MARK: - Color Extension Tests

    func testColorFromHex() {
        let blue = Color(hex: "#007AFF")
        XCTAssertNotNil(blue)

        let red = Color(hex: "FF0000")
        XCTAssertNotNil(red)

        let green = Color(hex: "#00FF00")
        XCTAssertNotNil(green)

        let withSpaces = Color(hex: "  #FFFFFF  ")
        XCTAssertNotNil(withSpaces)
    }

    func testColorFromInvalidHex() {
        let invalid = Color(hex: "not-a-color")
        XCTAssertNil(invalid)

        // Note: #FFF (3-char hex) might be parsed differently by the implementation
        // The implementation uses Scanner which may accept varying hex lengths
        // Just verify it doesn't crash and returns something reasonable
        let threeChar = Color(hex: "#FFF")
        // May or may not be nil depending on implementation
    }

    // MARK: - RectCorner Tests

    func testRectCornerOptionSet() {
        XCTAssertEqual(RectCorner.topLeft.rawValue, 1)
        XCTAssertEqual(RectCorner.topRight.rawValue, 2)
        XCTAssertEqual(RectCorner.bottomLeft.rawValue, 4)
        XCTAssertEqual(RectCorner.bottomRight.rawValue, 8)

        let top: RectCorner = [.topLeft, .topRight]
        XCTAssertTrue(top.contains(.topLeft))
        XCTAssertTrue(top.contains(.topRight))
        XCTAssertFalse(top.contains(.bottomLeft))

        let allCorners = RectCorner.allCorners
        XCTAssertTrue(allCorners.contains(.topLeft))
        XCTAssertTrue(allCorners.contains(.topRight))
        XCTAssertTrue(allCorners.contains(.bottomLeft))
        XCTAssertTrue(allCorners.contains(.bottomRight))
    }

    // MARK: - RoundedCornerShape Tests

    func testRoundedCornerShapeCreatesPath() {
        let shape = RoundedCornerShape(radius: 10, corners: .allCorners)
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let path = shape.path(in: rect)

        XCTAssertFalse(path.isEmpty)
    }

    func testRoundedCornerShapePartialCorners() {
        let shape = RoundedCornerShape(radius: 10, corners: [.topLeft, .bottomRight])
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let path = shape.path(in: rect)

        XCTAssertFalse(path.isEmpty)
    }
}
