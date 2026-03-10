import Foundation
import SwiftData

@Model
final class TripLoadSettings {
    var id: UUID
    var vehicleID: UUID
    var tripID: UUID?
    var freshWaterLiters: Double
    var greyWaterLiters: Double
    var gasBottleFillPercent: Double
    var rearCarrierLoadKg: Double
    var roofLoadKg: Double
    var extraLoadKg: Double
    var bikesOnRearCarrier: Bool
    var notes: String

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        tripID: UUID? = nil,
        freshWaterLiters: Double = 0,
        greyWaterLiters: Double = 0,
        gasBottleFillPercent: Double = 100,
        rearCarrierLoadKg: Double = 0,
        roofLoadKg: Double = 0,
        extraLoadKg: Double = 0,
        bikesOnRearCarrier: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.tripID = tripID
        self.freshWaterLiters = freshWaterLiters
        self.greyWaterLiters = greyWaterLiters
        self.gasBottleFillPercent = gasBottleFillPercent
        self.rearCarrierLoadKg = rearCarrierLoadKg
        self.roofLoadKg = roofLoadKg
        self.extraLoadKg = extraLoadKg
        self.bikesOnRearCarrier = bikesOnRearCarrier
        self.notes = notes
    }
}
