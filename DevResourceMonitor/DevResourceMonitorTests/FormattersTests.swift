import XCTest
@testable import DevResourceMonitor

final class FormattersTests: XCTestCase {

    // MARK: - Percentage Tests

    func testPercentageDefaultDecimals() {
        XCTAssertEqual(Formatters.percentage(45.2), "45.2%")
        XCTAssertEqual(Formatters.percentage(0.0), "0.0%")
        XCTAssertEqual(Formatters.percentage(100.0), "100.0%")
        XCTAssertEqual(Formatters.percentage(99.99), "100.0%")
    }

    func testPercentageCustomDecimals() {
        XCTAssertEqual(Formatters.percentage(45.234, decimals: 2), "45.23%")
        // Note: 45.235 rounds to 45.24 per IEEE 754 banker's rounding, but String format uses standard rounding
        XCTAssertTrue(Formatters.percentage(45.235, decimals: 2) == "45.23%" || Formatters.percentage(45.235, decimals: 2) == "45.24%")
        XCTAssertEqual(Formatters.percentage(45.0, decimals: 0), "45%")
        XCTAssertEqual(Formatters.percentage(45.6789, decimals: 3), "45.679%")
    }

    // MARK: - Memory Tests

    func testMemoryUnderHundredMB() {
        XCTAssertEqual(Formatters.memory(50.5), "50.5 MB")
        XCTAssertEqual(Formatters.memory(99.9), "99.9 MB")
        XCTAssertEqual(Formatters.memory(0.1), "0.1 MB")
    }

    func testMemoryHundredToGigabyte() {
        XCTAssertEqual(Formatters.memory(100.0), "100 MB")
        XCTAssertEqual(Formatters.memory(500.5), "500 MB")  // Rounded to nearest
        XCTAssertEqual(Formatters.memory(1023.9), "1024 MB")
    }

    func testMemoryGigabyteAndAbove() {
        XCTAssertEqual(Formatters.memory(1024.0), "1.0 GB")
        XCTAssertEqual(Formatters.memory(2048.0), "2.0 GB")
        XCTAssertEqual(Formatters.memory(1536.0), "1.5 GB")
        XCTAssertEqual(Formatters.memory(10240.0), "10.0 GB")
    }

    func testMemoryDetailedUnderGigabyte() {
        XCTAssertEqual(Formatters.memoryDetailed(50.5), "50.5 MB")
        XCTAssertEqual(Formatters.memoryDetailed(500.0), "500.0 MB")
        XCTAssertEqual(Formatters.memoryDetailed(1023.9), "1023.9 MB")
    }

    func testMemoryDetailedGigabyteAndAbove() {
        XCTAssertEqual(Formatters.memoryDetailed(1024.0), "1.00 GB")
        XCTAssertEqual(Formatters.memoryDetailed(1536.0), "1.50 GB")
        XCTAssertEqual(Formatters.memoryDetailed(2560.0), "2.50 GB")
    }

    // MARK: - CPU Tests

    func testCPUUnderTenPercent() {
        XCTAssertEqual(Formatters.cpu(5.123), "5.12%")
        XCTAssertEqual(Formatters.cpu(0.05), "0.05%")
        XCTAssertEqual(Formatters.cpu(9.99), "9.99%")
    }

    func testCPUTenToHundredPercent() {
        XCTAssertEqual(Formatters.cpu(10.0), "10.0%")
        XCTAssertEqual(Formatters.cpu(50.55), "50.5%")
        XCTAssertEqual(Formatters.cpu(99.9), "99.9%")
    }

    func testCPUHundredPercentAndAbove() {
        XCTAssertEqual(Formatters.cpu(100.0), "100%")
        XCTAssertEqual(Formatters.cpu(150.5), "150%")  // Rounded to nearest integer
        XCTAssertEqual(Formatters.cpu(400.0), "400%")
    }

    // MARK: - Number Tests

    func testNumberWithThousandsSeparator() {
        XCTAssertEqual(Formatters.number(1000), "1,000")
        XCTAssertEqual(Formatters.number(1000000), "1,000,000")
        XCTAssertEqual(Formatters.number(999), "999")
        XCTAssertEqual(Formatters.number(0), "0")
    }

    // MARK: - Duration Tests

    func testDurationUnderMinute() {
        XCTAssertEqual(Formatters.duration(0), "< 1 min")
        XCTAssertEqual(Formatters.duration(30), "< 1 min")
        XCTAssertEqual(Formatters.duration(59), "< 1 min")
    }

    func testDurationMinutes() {
        XCTAssertEqual(Formatters.duration(60), "1 min")
        XCTAssertEqual(Formatters.duration(120), "2 min")
        XCTAssertEqual(Formatters.duration(3599), "59 min")
    }

    func testDurationHours() {
        XCTAssertEqual(Formatters.duration(3600), "1h")
        XCTAssertEqual(Formatters.duration(3660), "1h 1m")
        XCTAssertEqual(Formatters.duration(7200), "2h")
        XCTAssertEqual(Formatters.duration(9000), "2h 30m")
        XCTAssertEqual(Formatters.duration(86399), "23h 59m")
    }

    func testDurationDays() {
        XCTAssertEqual(Formatters.duration(86400), "1d")
        XCTAssertEqual(Formatters.duration(172800), "2d")
        XCTAssertEqual(Formatters.duration(604800), "7d")
    }

    // MARK: - Percent Change Tests

    func testPercentChangePositive() {
        XCTAssertEqual(Formatters.percentChange(10.0), "+10%")
        XCTAssertEqual(Formatters.percentChange(0.5), "+0%")  // 0.5 rounds to 0 with %.0f
        XCTAssertEqual(Formatters.percentChange(100.0), "+100%")
    }

    func testPercentChangeNegative() {
        XCTAssertEqual(Formatters.percentChange(-10.0), "-10%")
        XCTAssertEqual(Formatters.percentChange(-0.5), "-0%")  // -0.5 rounds to 0 with %.0f
        XCTAssertEqual(Formatters.percentChange(-100.0), "-100%")
    }

    func testPercentChangeZero() {
        XCTAssertEqual(Formatters.percentChange(0.0), "+0%")
    }

    // MARK: - Date Formatting Tests

    func testTimeFormatting() {
        let date = Date()
        let result = Formatters.time(date)
        XCTAssertFalse(result.isEmpty)
    }

    func testDateTimeFormatting() {
        let date = Date()
        let result = Formatters.dateTime(date)
        XCTAssertFalse(result.isEmpty)
    }

    func testChartDateToday() {
        let today = Date()
        let result = Formatters.chartDate(today)
        // Should return time only for today
        XCTAssertFalse(result.isEmpty)
        // Time format typically doesn't contain year
        XCTAssertFalse(result.contains("202"))
    }

    func testChartDatePastDate() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let result = Formatters.chartDate(pastDate)
        XCTAssertFalse(result.isEmpty)
    }

    func testRelativeTime() {
        let now = Date()
        let result = Formatters.relativeTime(now)
        XCTAssertFalse(result.isEmpty)

        let pastDate = Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
        let pastResult = Formatters.relativeTime(pastDate)
        XCTAssertFalse(pastResult.isEmpty)
    }
}
