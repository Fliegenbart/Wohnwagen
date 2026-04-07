import Foundation

struct GaragePresentation: Equatable {
    let orderedVehicleIDs: [UUID]

    static func make(vehicles: [VehicleProfile], activeVehicleID: UUID?) -> Self {
        let sorted = vehicles.sorted { lhs, rhs in
            if lhs.id == activeVehicleID { return true }
            if rhs.id == activeVehicleID { return false }
            return lhs.createdAt < rhs.createdAt
        }

        return GaragePresentation(orderedVehicleIDs: sorted.map(\.id))
    }
}
