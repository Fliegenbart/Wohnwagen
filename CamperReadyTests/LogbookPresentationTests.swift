import XCTest
@testable import CamperReady

final class LogbookPresentationTests: XCTestCase {
    func testLogbookPresentationKeepsStatsInEditorialOrder() {
        let presentation = LogbookPresentation.make(totalDistance: 4280, totalSpend: 1842, readinessOpenItems: 2)

        XCTAssertEqual(presentation.stats.map(\.title), ["Distanz", "Investiert", "Status"])
        XCTAssertEqual(presentation.stats.last?.value, "2 offen")
    }

    func testLogbookPresentationUsesReadyCopyWhenNoOpenItemsExist() {
        let presentation = LogbookPresentation.make(totalDistance: 4280, totalSpend: 1842, readinessOpenItems: 0)

        XCTAssertEqual(presentation.stats.last?.value, "Bereit")
    }

    func testLogbookPresentationUsesNeutralCopyWhenNoVehicleIsAvailable() {
        let presentation = LogbookPresentation.make(totalDistance: 0, totalSpend: 0, readinessOpenItems: nil)

        XCTAssertEqual(presentation.stats.last?.value, "Noch kein Camper")
    }
}
