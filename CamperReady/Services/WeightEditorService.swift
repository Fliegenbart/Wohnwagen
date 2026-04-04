import Foundation
import SwiftData

struct PackingItemDraftData {
    var name: String
    var category: WeightCategory
    var quantity: Int
    var unitWeightKg: Double
    var isPersistent: Bool
    var includeInCurrentLoad: Bool

    init(
        name: String = "",
        category: WeightCategory = .other,
        quantity: Int = 1,
        unitWeightKg: Double = 0,
        isPersistent: Bool = false,
        includeInCurrentLoad: Bool = true
    ) {
        self.name = name
        self.category = category
        self.quantity = quantity
        self.unitWeightKg = unitWeightKg
        self.isPersistent = isPersistent
        self.includeInCurrentLoad = includeInCurrentLoad
    }

    init(item: PackingItem?) {
        self.name = item?.name ?? ""
        self.category = item?.category ?? .other
        self.quantity = item?.quantity ?? 1
        self.unitWeightKg = item?.unitWeightKg ?? 0
        self.isPersistent = item?.isPersistent ?? false
        self.includeInCurrentLoad = item?.includeInCurrentLoad ?? true
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        quantity > 0 &&
        unitWeightKg >= 0
    }
}

struct PassengerDraftData {
    var name: String
    var weightKg: Double
    var isDriver: Bool
    var isPersistent: Bool

    init(name: String = "", weightKg: Double = 75, isDriver: Bool = false, isPersistent: Bool = false) {
        self.name = name
        self.weightKg = weightKg
        self.isDriver = isDriver
        self.isPersistent = isPersistent
    }

    init(passenger: PassengerLoad?) {
        self.name = passenger?.name ?? ""
        self.weightKg = passenger?.weightKg ?? 75
        self.isDriver = passenger?.isDriver ?? false
        self.isPersistent = passenger?.tripID == nil
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && weightKg > 0
    }
}

struct LoadSettingsDraftData {
    var freshWaterLiters: Double
    var greyWaterLiters: Double
    var gasBottleFillPercent: Double
    var rearCarrierLoadKg: Double
    var roofLoadKg: Double
    var extraLoadKg: Double
    var bikesOnRearCarrier: Bool
    var notes: String

    init(settings: TripLoadSettings?) {
        self.freshWaterLiters = settings?.freshWaterLiters ?? 20
        self.greyWaterLiters = settings?.greyWaterLiters ?? 0
        self.gasBottleFillPercent = settings?.gasBottleFillPercent ?? 100
        self.rearCarrierLoadKg = settings?.rearCarrierLoadKg ?? 0
        self.roofLoadKg = settings?.roofLoadKg ?? 0
        self.extraLoadKg = settings?.extraLoadKg ?? 0
        self.bikesOnRearCarrier = settings?.bikesOnRearCarrier ?? false
        self.notes = settings?.notes ?? ""
    }
}

@MainActor
enum WeightEditorService {
    static func savePackingItem(
        draft: PackingItemDraftData,
        existingItem: PackingItem?,
        vehicle: VehicleProfile,
        trip: Trip?,
        context: ModelContext
    ) throws -> PackingItem {
        guard draft.canSave else {
            throw CocoaError(.validationStringTooShort)
        }

        let item = existingItem ?? PackingItem(
            vehicleID: vehicle.id,
            tripID: draft.isPersistent ? nil : trip?.id,
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: draft.category,
            quantity: draft.quantity,
            unitWeightKg: draft.unitWeightKg,
            isPersistent: draft.isPersistent,
            includeInCurrentLoad: draft.includeInCurrentLoad
        )

        item.vehicleID = vehicle.id
        item.tripID = draft.isPersistent ? nil : trip?.id
        item.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        item.category = draft.category
        item.quantity = draft.quantity
        item.unitWeightKg = draft.unitWeightKg
        item.isPersistent = draft.isPersistent
        item.includeInCurrentLoad = draft.includeInCurrentLoad

        if existingItem == nil {
            context.insert(item)
            attach(item, to: &vehicle.packingItems)
        }

        vehicle.updatedAt = .now
        try context.save()
        return item
    }

    static func deletePackingItem(_ item: PackingItem, from vehicle: VehicleProfile, context: ModelContext) throws {
        vehicle.packingItems.removeAll { $0.id == item.id }
        vehicle.updatedAt = .now
        context.delete(item)
        try context.save()
    }

    static func savePassenger(
        draft: PassengerDraftData,
        existingPassenger: PassengerLoad?,
        vehicle: VehicleProfile,
        trip: Trip?,
        context: ModelContext
    ) throws -> PassengerLoad {
        guard draft.canSave else {
            throw CocoaError(.validationStringTooShort)
        }

        let passenger = existingPassenger ?? PassengerLoad(
            vehicleID: vehicle.id,
            tripID: draft.isPersistent ? nil : trip?.id,
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            weightKg: draft.weightKg,
            isDriver: draft.isDriver
        )

        passenger.vehicleID = vehicle.id
        passenger.tripID = draft.isPersistent ? nil : trip?.id
        passenger.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        passenger.weightKg = draft.weightKg
        passenger.isDriver = draft.isDriver

        if existingPassenger == nil {
            context.insert(passenger)
            attach(passenger, to: &vehicle.passengers)
        }

        vehicle.updatedAt = .now
        try context.save()
        return passenger
    }

    static func deletePassenger(_ passenger: PassengerLoad, from vehicle: VehicleProfile, context: ModelContext) throws {
        vehicle.passengers.removeAll { $0.id == passenger.id }
        vehicle.updatedAt = .now
        context.delete(passenger)
        try context.save()
    }

    static func ensureLoadSettings(vehicle: VehicleProfile, trip: Trip?, context: ModelContext) throws -> TripLoadSettings {
        if let existing = vehicle.loadSettings.first(where: { $0.tripID == trip?.id }) {
            return existing
        }

        let settings = TripLoadSettings(vehicleID: vehicle.id, tripID: trip?.id)
        context.insert(settings)
        attach(settings, to: &vehicle.loadSettings)
        vehicle.updatedAt = .now
        try context.save()
        return settings
    }

    static func saveLoadSettings(
        draft: LoadSettingsDraftData,
        existingSettings: TripLoadSettings?,
        vehicle: VehicleProfile,
        trip: Trip?,
        context: ModelContext
    ) throws -> TripLoadSettings {
        let settings = try existingSettings ?? ensureLoadSettings(vehicle: vehicle, trip: trip, context: context)
        settings.vehicleID = vehicle.id
        settings.tripID = trip?.id
        settings.freshWaterLiters = max(draft.freshWaterLiters, 0)
        settings.greyWaterLiters = max(draft.greyWaterLiters, 0)
        settings.gasBottleFillPercent = min(max(draft.gasBottleFillPercent, 0), 100)
        settings.rearCarrierLoadKg = max(draft.rearCarrierLoadKg, 0)
        settings.roofLoadKg = max(draft.roofLoadKg, 0)
        settings.extraLoadKg = max(draft.extraLoadKg, 0)
        settings.bikesOnRearCarrier = draft.bikesOnRearCarrier
        settings.notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        vehicle.updatedAt = .now
        try context.save()
        return settings
    }

    private static func attach<T: Identifiable>(_ item: T, to collection: inout [T]) where T.ID: Equatable {
        guard collection.contains(where: { $0.id == item.id }) == false else { return }
        collection.append(item)
    }
}
