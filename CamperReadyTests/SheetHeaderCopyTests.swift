import XCTest
@testable import CamperReady

final class SheetHeaderCopyTests: XCTestCase {
    func testRoadSheetHeaderUsesUtilityCopyInsteadOfMarketingCopy() {
        let subtitle = SheetCopy.vehicleProfileSubtitle
        XCTAssertEqual(subtitle, "Pflege hier die Basisdaten, Gewichte und Intervalle deines Fahrzeugs.")
    }
}
