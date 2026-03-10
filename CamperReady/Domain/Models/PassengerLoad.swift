import Foundation
import SwiftData

@Model
final class PassengerLoad {
    var id: UUID
    var vehicleID: UUID
    var tripID: UUID?
    var name: String
    var weightKg: Double
    var isDriver: Bool

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        tripID: UUID? = nil,
        name: String,
        weightKg: Double,
        isDriver: Bool = false
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.tripID = tripID
        self.name = name
        self.weightKg = weightKg
        self.isDriver = isDriver
    }
}
