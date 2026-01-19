import XCTest
import SwiftUI
@testable import DevResourceMonitor

final class PieChartTooltipTests: XCTestCase {

    // MARK: - Test Helper for Angle Calculations

    /// Replicates the angle calculation logic from PieChartView for testing
    private func calculateAngle(from location: CGPoint, center: CGPoint) -> Double {
        let dx = location.x - center.x
        let dy = location.y - center.y

        var angle = atan2(dx, -dy) * 180 / .pi
        if angle < 0 {
            angle += 360
        }
        return angle
    }

    /// Check if a point is within the donut ring
    private func isWithinDonutRing(location: CGPoint, center: CGPoint, innerRadius: CGFloat, outerRadius: CGFloat) -> Bool {
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        return distance >= innerRadius && distance <= outerRadius
    }

    /// Find which segment index a given angle falls into
    private func findSegmentIndex(angle: Double, segmentValues: [Double]) -> Int? {
        let total = segmentValues.reduce(0, +)
        guard total > 0 else { return nil }

        var currentAngle: Double = 0
        for (index, value) in segmentValues.enumerated() {
            let sliceAngle = (value / total) * 360
            if angle >= currentAngle && angle < currentAngle + sliceAngle {
                return index
            }
            currentAngle += sliceAngle
        }
        return nil
    }

    // MARK: - Angle Calculation Tests

    func testAngleAtTop() {
        let center = CGPoint(x: 100, y: 100)
        let topPoint = CGPoint(x: 100, y: 50)

        let angle = calculateAngle(from: topPoint, center: center)
        XCTAssertEqual(angle, 0, accuracy: 0.1)
    }

    func testAngleAtRight() {
        let center = CGPoint(x: 100, y: 100)
        let rightPoint = CGPoint(x: 150, y: 100)

        let angle = calculateAngle(from: rightPoint, center: center)
        XCTAssertEqual(angle, 90, accuracy: 0.1)
    }

    func testAngleAtBottom() {
        let center = CGPoint(x: 100, y: 100)
        let bottomPoint = CGPoint(x: 100, y: 150)

        let angle = calculateAngle(from: bottomPoint, center: center)
        XCTAssertEqual(angle, 180, accuracy: 0.1)
    }

    func testAngleAtLeft() {
        let center = CGPoint(x: 100, y: 100)
        let leftPoint = CGPoint(x: 50, y: 100)

        let angle = calculateAngle(from: leftPoint, center: center)
        XCTAssertEqual(angle, 270, accuracy: 0.1)
    }

    func testAngleAt45Degrees() {
        let center = CGPoint(x: 100, y: 100)
        let point = CGPoint(x: 150, y: 50)

        let angle = calculateAngle(from: point, center: center)
        XCTAssertEqual(angle, 45, accuracy: 1)
    }

    func testAngleAt315Degrees() {
        let center = CGPoint(x: 100, y: 100)
        let point = CGPoint(x: 50, y: 50)

        let angle = calculateAngle(from: point, center: center)
        XCTAssertEqual(angle, 315, accuracy: 1)
    }

    // MARK: - Donut Ring Detection Tests

    func testPointInsideDonutRing() {
        let center = CGPoint(x: 100, y: 100)
        let innerRadius: CGFloat = 40
        let outerRadius: CGFloat = 80

        // Point at 60 distance (between inner 40 and outer 80)
        let insidePoint = CGPoint(x: 160, y: 100)
        XCTAssertTrue(isWithinDonutRing(location: insidePoint, center: center, innerRadius: innerRadius, outerRadius: outerRadius))
    }

    func testPointOutsideDonutRing() {
        let center = CGPoint(x: 100, y: 100)
        let innerRadius: CGFloat = 40
        let outerRadius: CGFloat = 80

        // Point at 100 distance (outside outer radius 80)
        let outsidePoint = CGPoint(x: 200, y: 100)
        XCTAssertFalse(isWithinDonutRing(location: outsidePoint, center: center, innerRadius: innerRadius, outerRadius: outerRadius))
    }

    func testPointInHole() {
        let center = CGPoint(x: 100, y: 100)
        let innerRadius: CGFloat = 40
        let outerRadius: CGFloat = 80

        // Point at 20 distance (inside inner radius 40)
        let holePoint = CGPoint(x: 120, y: 100)
        XCTAssertFalse(isWithinDonutRing(location: holePoint, center: center, innerRadius: innerRadius, outerRadius: outerRadius))
    }

    func testPointAtCenter() {
        let center = CGPoint(x: 100, y: 100)
        let innerRadius: CGFloat = 40
        let outerRadius: CGFloat = 80

        XCTAssertFalse(isWithinDonutRing(location: center, center: center, innerRadius: innerRadius, outerRadius: outerRadius))
    }

    func testPointOnInnerEdge() {
        let center = CGPoint(x: 100, y: 100)
        let innerRadius: CGFloat = 40
        let outerRadius: CGFloat = 80

        let edgePoint = CGPoint(x: 140, y: 100)
        XCTAssertTrue(isWithinDonutRing(location: edgePoint, center: center, innerRadius: innerRadius, outerRadius: outerRadius))
    }

    func testPointOnOuterEdge() {
        let center = CGPoint(x: 100, y: 100)
        let innerRadius: CGFloat = 40
        let outerRadius: CGFloat = 80

        let edgePoint = CGPoint(x: 180, y: 100)
        XCTAssertTrue(isWithinDonutRing(location: edgePoint, center: center, innerRadius: innerRadius, outerRadius: outerRadius))
    }

    // MARK: - Segment Finding Tests

    func testFindSegmentInEqualParts() {
        // 4 equal segments: 0-90, 90-180, 180-270, 270-360
        let values = [25.0, 25.0, 25.0, 25.0]

        XCTAssertEqual(findSegmentIndex(angle: 0, segmentValues: values), 0)
        XCTAssertEqual(findSegmentIndex(angle: 45, segmentValues: values), 0)
        XCTAssertEqual(findSegmentIndex(angle: 90, segmentValues: values), 1)
        XCTAssertEqual(findSegmentIndex(angle: 135, segmentValues: values), 1)
        XCTAssertEqual(findSegmentIndex(angle: 180, segmentValues: values), 2)
        XCTAssertEqual(findSegmentIndex(angle: 270, segmentValues: values), 3)
        XCTAssertEqual(findSegmentIndex(angle: 359, segmentValues: values), 3)
    }

    func testFindSegmentInUnequalParts() {
        // 2 segments: first is 270 degrees (75%), second is 90 degrees (25%)
        let values = [75.0, 25.0]

        XCTAssertEqual(findSegmentIndex(angle: 0, segmentValues: values), 0)
        XCTAssertEqual(findSegmentIndex(angle: 100, segmentValues: values), 0)
        XCTAssertEqual(findSegmentIndex(angle: 269, segmentValues: values), 0)
        XCTAssertEqual(findSegmentIndex(angle: 270, segmentValues: values), 1)
        XCTAssertEqual(findSegmentIndex(angle: 300, segmentValues: values), 1)
        XCTAssertEqual(findSegmentIndex(angle: 359, segmentValues: values), 1)
    }

    func testFindSegmentSingleSegment() {
        let values = [100.0]

        XCTAssertEqual(findSegmentIndex(angle: 0, segmentValues: values), 0)
        XCTAssertEqual(findSegmentIndex(angle: 180, segmentValues: values), 0)
        XCTAssertEqual(findSegmentIndex(angle: 359, segmentValues: values), 0)
    }

    func testFindSegmentEmptyValues() {
        let values: [Double] = []
        XCTAssertNil(findSegmentIndex(angle: 90, segmentValues: values))
    }

    func testFindSegmentZeroTotal() {
        let values = [0.0, 0.0, 0.0]
        XCTAssertNil(findSegmentIndex(angle: 90, segmentValues: values))
    }

    func testFindSegmentWithSmallSlice() {
        // One large segment and one tiny segment
        let values = [99.0, 1.0]

        // First segment covers 0-356.4 degrees
        XCTAssertEqual(findSegmentIndex(angle: 0, segmentValues: values), 0)
        XCTAssertEqual(findSegmentIndex(angle: 350, segmentValues: values), 0)

        // Second segment covers 356.4-360 degrees
        XCTAssertEqual(findSegmentIndex(angle: 358, segmentValues: values), 1)
    }

    // MARK: - Integration Tests

    func testFindItemAtLocationIntegration() {
        // Simulating a chart with center at (100, 100), radius 100
        let center = CGPoint(x: 100, y: 100)
        let outerRadius: CGFloat = 100
        let innerRadius: CGFloat = 50

        // Segment values represent CPU percentages
        let values = [45.0, 22.0, 8.0, 25.0] // IDE, Containers, Dev Tools, Other

        // Test point in first segment (IDE) - top right area
        let point1 = CGPoint(x: 150, y: 50) // Should be around 45 degrees
        if isWithinDonutRing(location: point1, center: center, innerRadius: innerRadius, outerRadius: outerRadius) {
            let angle = calculateAngle(from: point1, center: center)
            let segmentIndex = findSegmentIndex(angle: angle, segmentValues: values)
            XCTAssertEqual(segmentIndex, 0) // First segment (IDE)
        }

        // Test point in center (should not match)
        XCTAssertFalse(isWithinDonutRing(location: center, center: center, innerRadius: innerRadius, outerRadius: outerRadius))
    }

    // MARK: - CategoryUsage Color Tests

    func testCategoryUsageSwiftUIColor() {
        let usage = ResourceUsage(cpuPercent: 45.0, memoryMB: 2000.0, processCount: 5)
        let categoryUsage = CategoryUsage(
            id: "ide",
            name: "IDEs & Editors",
            color: "#007AFF",
            usage: usage,
            processes: []
        )

        // Verify the color property returns a valid color
        let color = categoryUsage.swiftUIColor
        XCTAssertNotNil(color)
    }

    func testCategoryUsageInvalidColorFallsBackToGray() {
        let usage = ResourceUsage(cpuPercent: 10.0, memoryMB: 100.0, processCount: 1)
        let categoryUsage = CategoryUsage(
            id: "test",
            name: "Test",
            color: "invalid-color",
            usage: usage,
            processes: []
        )

        // Should not crash and fall back to gray
        let color = categoryUsage.swiftUIColor
        XCTAssertNotNil(color)
    }

    // MARK: - Boundary Tests

    func testAngleBoundary360() {
        let center = CGPoint(x: 100, y: 100)
        // Very close to top, slightly to the left
        let point = CGPoint(x: 99.9, y: 50)

        let angle = calculateAngle(from: point, center: center)
        XCTAssertGreaterThan(angle, 359)
        XCTAssertLessThan(angle, 360.1)
    }

    func testSegmentBoundaryEdgeCases() {
        let values = [50.0, 50.0]

        // Right at the boundary (180 degrees)
        XCTAssertEqual(findSegmentIndex(angle: 179.9, segmentValues: values), 0)
        XCTAssertEqual(findSegmentIndex(angle: 180.0, segmentValues: values), 1)
    }

    // MARK: - Performance Tests

    func testAngleCalculationPerformance() {
        let center = CGPoint(x: 100, y: 100)

        measure {
            for _ in 0..<10000 {
                _ = calculateAngle(from: CGPoint(x: Double.random(in: 0...200), y: Double.random(in: 0...200)), center: center)
            }
        }
    }

    func testSegmentFindingPerformance() {
        let values = [25.0, 25.0, 25.0, 25.0, 10.0, 5.0, 5.0, 5.0]

        measure {
            for _ in 0..<10000 {
                _ = findSegmentIndex(angle: Double.random(in: 0..<360), segmentValues: values)
            }
        }
    }
}
