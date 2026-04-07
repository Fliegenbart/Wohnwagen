import Foundation
import SwiftUI

struct ActiveVehicleResolution: Equatable {
    let selectedVehicleID: UUID?
    let needsSelection: Bool
}

enum ActiveVehicleResolver {
    static func resolve(storedVehicleID: UUID?, vehicles: [VehicleProfile]) -> ActiveVehicleResolution {
        guard !vehicles.isEmpty else {
            return ActiveVehicleResolution(selectedVehicleID: nil, needsSelection: false)
        }

        if let storedVehicleID, vehicles.contains(where: { $0.id == storedVehicleID }) {
            return ActiveVehicleResolution(selectedVehicleID: storedVehicleID, needsSelection: false)
        }

        if vehicles.count == 1, let onlyVehicle = vehicles.first {
            return ActiveVehicleResolution(selectedVehicleID: onlyVehicle.id, needsSelection: false)
        }

        return ActiveVehicleResolution(selectedVehicleID: nil, needsSelection: true)
    }
}

@MainActor
final class ActiveVehicleStore: ObservableObject {
    static let storageKey = "camperready.selectedVehicleID"

    @Published private(set) var selectedVehicleID: UUID?
    @Published private(set) var needsSelection = false

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let rawID = defaults.string(forKey: Self.storageKey),
           let vehicleID = UUID(uuidString: rawID) {
            selectedVehicleID = vehicleID
        }
    }

    func reconcile(with vehicles: [VehicleProfile]) {
        let resolution = ActiveVehicleResolver.resolve(
            storedVehicleID: selectedVehicleID,
            vehicles: vehicles
        )

        selectedVehicleID = resolution.selectedVehicleID
        needsSelection = resolution.needsSelection
        persistSelection()
        syncPrimaryFlag(in: vehicles)
    }

    func select(_ vehicle: VehicleProfile) {
        select(vehicle.id)
    }

    func select(_ vehicleID: UUID?) {
        selectedVehicleID = vehicleID
        needsSelection = false
        persistSelection()
    }

    func activeVehicle(in vehicles: [VehicleProfile]) -> VehicleProfile? {
        guard let selectedVehicleID else { return nil }
        return vehicles.first(where: { $0.id == selectedVehicleID })
    }

    private func persistSelection() {
        if let selectedVehicleID {
            defaults.set(selectedVehicleID.uuidString, forKey: Self.storageKey)
        } else {
            defaults.removeObject(forKey: Self.storageKey)
        }
    }

    private func syncPrimaryFlag(in vehicles: [VehicleProfile]) {
        for vehicle in vehicles {
            let shouldBePrimary = vehicle.id == selectedVehicleID
            guard vehicle.isPrimary != shouldBePrimary else { continue }
            vehicle.isPrimary = shouldBePrimary
            vehicle.updatedAt = .now
        }
    }
}
