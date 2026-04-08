import XCTest
import SwiftUI
@testable import CamperReady

final class GaragePresentationTests: XCTestCase {
    func testGaragePresentationKeepsActiveVehicleFirst() {
        let a = VehicleProfile(name: "Atlas", vehicleKind: .motorhome, brand: "Hymer", model: "ML-T")
        let b = VehicleProfile(name: "Nova", vehicleKind: .campervan, brand: "Pössl", model: "Summit")

        let presentation = GaragePresentation.make(vehicles: [a, b], activeVehicleID: b.id)

        XCTAssertEqual(presentation.orderedVehicleIDs.first, b.id)
    }

    func testGaragePresentationUsesStableIDOrderWhenCreatedAtMatches() {
        let createdAt = Date(timeIntervalSince1970: 1_234)
        let earlierID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let laterID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        let first = makeVehicle(id: laterID, createdAt: createdAt, name: "Berg")
        let second = makeVehicle(id: earlierID, createdAt: createdAt, name: "Tal")

        let presentation = GaragePresentation.make(vehicles: [first, second], activeVehicleID: nil)

        XCTAssertEqual(presentation.orderedVehicleIDs, [earlierID, laterID])
    }

    func testGaragePresentationTreatsMissingActiveVehicleLikeNoActiveVehicle() {
        let createdAt = Date(timeIntervalSince1970: 1_234)
        let earlierID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let laterID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let missingID = UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!

        let first = makeVehicle(id: laterID, createdAt: createdAt, name: "Berg")
        let second = makeVehicle(id: earlierID, createdAt: createdAt, name: "Tal")

        let presentation = GaragePresentation.make(vehicles: [first, second], activeVehicleID: missingID)

        XCTAssertEqual(presentation.orderedVehicleIDs, [earlierID, laterID])
    }

    func testGarageRowLayoutPrefersStackedMetadataAtAccessibilitySizes() {
        XCTAssertTrue(GarageRowLayout.prefersStackedMetadata(for: DynamicTypeSize.accessibility1))
        XCTAssertFalse(GarageRowLayout.prefersStackedMetadata(for: DynamicTypeSize.large))
    }

    private func makeVehicle(id: UUID, createdAt: Date, name: String) -> VehicleProfile {
        VehicleProfile(
            id: id,
            createdAt: createdAt,
            updatedAt: createdAt,
            name: name,
            vehicleKind: .motorhome,
            brand: "Hymer",
            model: "ML-T"
        )
    }
}
