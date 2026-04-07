import XCTest
@testable import CamperReady

final class AlpineSurfaceTests: XCTestCase {
    func testSurfaceMetricsMatchDesignRoles() {
        XCTAssertEqual(AlpineSurfaceMetrics.metrics(for: .section).cornerRadius, 24)
        XCTAssertEqual(AlpineSurfaceMetrics.metrics(for: .raised).cornerRadius, 20)
        XCTAssertTrue(AlpineSurfaceMetrics.metrics(for: .focus).isDark)
        XCTAssertGreaterThan(AlpineSurfaceMetrics.metrics(for: .focus).shadowOpacity, 0.05)
    }
}
