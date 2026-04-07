import XCTest
@testable import CamperReady

final class LogbookPresentationTests: XCTestCase {
    func testLogbookPresentationKeepsStatsInEditorialOrder() {
        let presentation = LogbookPresentation.make(totalDistance: 4280, totalSpend: 1842, readinessAverage: 94)

        XCTAssertEqual(presentation.stats.map(\.title), ["Distanz", "Investition", "Bereitschaft"])
    }
}
