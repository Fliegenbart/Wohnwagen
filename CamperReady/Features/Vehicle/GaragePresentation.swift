import Foundation

struct GaragePresentation: Equatable {
    let orderedVehicleIDs: [UUID]

    static func make(vehicles: [VehicleProfile], activeVehicleID: UUID?) -> Self {
        let sorted = vehicles.sorted { lhs, rhs in
            if lhs.id == activeVehicleID { return true }
            if rhs.id == activeVehicleID { return false }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }

        return GaragePresentation(orderedVehicleIDs: sorted.map(\.id))
    }
}
