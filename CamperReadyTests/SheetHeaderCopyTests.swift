import XCTest
@testable import CamperReady

final class SheetHeaderCopyTests: XCTestCase {
    func testVehicleProfileSubtitleMatchesSharedUtilityCopy() {
        let subtitle = SheetCopy.vehicleProfileSubtitle
        XCTAssertEqual(subtitle, "Trag hier die wichtigsten Daten, Gewichte und Intervalle deines Campers ein.")
    }
}
