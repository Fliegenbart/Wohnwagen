import XCTest
@testable import CamperReady

final class GaragePresentationTests: XCTestCase {
    func testGaragePresentationKeepsActiveVehicleFirst() {
        let a = VehicleProfile(name: "Atlas", vehicleKind: .motorhome, brand: "Hymer", model: "ML-T")
        let b = VehicleProfile(name: "Nova", vehicleKind: .campervan, brand: "Pössl", model: "Summit")

        let presentation = GaragePresentation.make(vehicles: [a, b], activeVehicleID: b.id)

        XCTAssertEqual(presentation.orderedVehicleIDs.first, b.id)
    }
}
