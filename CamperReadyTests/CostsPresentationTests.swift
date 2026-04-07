import XCTest
@testable import CamperReady

final class CostsPresentationTests: XCTestCase {
    func testCostsPresentationPrioritizesTripThenNightThenAnnual() {
        let presentation = CostsPresentation.make(
            tripTotal: 642.5,
            perNight: 128.5,
            perHundredKm: 18.9,
            annualTotal: 1842
        )

        XCTAssertEqual(presentation.stats.map(\.title), ["Diese Reise", "Pro Nacht", "Pro 100 km", "Dieses Jahr"])
    }
}
