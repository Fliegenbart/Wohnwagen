import Foundation

enum AppDataLocator {
    static func primaryVehicle(in vehicles: [VehicleProfile]) -> VehicleProfile? {
        vehicles.first(where: \.isPrimary) ?? vehicles.first
    }

    static func activeTrip(for vehicle: VehicleProfile?, trips: [Trip]) -> Trip? {
        guard let vehicle else { return nil }
        return trips
            .filter { $0.vehicleID == vehicle.id }
            .sorted { lhs, rhs in
                if lhs.isActive == rhs.isActive {
                    return lhs.startDate < rhs.startDate
                }
                return lhs.isActive && !rhs.isActive
            }
            .first
    }

    static func loadSettings(for vehicle: VehicleProfile?, trip: Trip?, settings: [TripLoadSettings]) -> TripLoadSettings? {
        guard let vehicle else { return nil }
        return settings.first { setting in
            setting.vehicleID == vehicle.id && setting.tripID == trip?.id
        } ?? settings.first { $0.vehicleID == vehicle.id && $0.tripID == nil }
    }

    static func packingItems(for vehicle: VehicleProfile?, trip: Trip?, items: [PackingItem]) -> [PackingItem] {
        guard let vehicle else { return [] }
        return items.filter {
            $0.vehicleID == vehicle.id &&
            $0.includeInCurrentLoad &&
            ($0.tripID == nil || $0.tripID == trip?.id)
        }
    }

    static func passengers(for vehicle: VehicleProfile?, trip: Trip?, passengers: [PassengerLoad]) -> [PassengerLoad] {
        guard let vehicle else { return [] }
        return passengers.filter { $0.vehicleID == vehicle.id && ($0.tripID == nil || $0.tripID == trip?.id) }
    }

    static func documents(for vehicle: VehicleProfile?, documents: [DocumentRecord]) -> [DocumentRecord] {
        guard let vehicle else { return [] }
        return documents.filter { $0.vehicleID == vehicle.id }
    }

    static func maintenance(for vehicle: VehicleProfile?, entries: [MaintenanceEntry]) -> [MaintenanceEntry] {
        guard let vehicle else { return [] }
        return entries.filter { $0.vehicleID == vehicle.id }
    }

    static func checklists(for vehicle: VehicleProfile?, checklists: [ChecklistRun]) -> [ChecklistRun] {
        guard let vehicle else { return [] }
        return checklists.filter { $0.vehicleID == vehicle.id }.sorted(by: { $0.updatedAt > $1.updatedAt })
    }

    static func checklistItems(for checklist: ChecklistRun?, items: [ChecklistItemRecord]) -> [ChecklistItemRecord] {
        guard let checklist else { return [] }
        return items.filter { $0.checklistID == checklist.id }.sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    static func costs(for vehicle: VehicleProfile?, costs: [CostEntry]) -> [CostEntry] {
        guard let vehicle else { return [] }
        return costs.filter { $0.vehicleID == vehicle.id }.sorted(by: { $0.date > $1.date })
    }

    static func places(for vehicle: VehicleProfile?, places: [PlaceNote]) -> [PlaceNote] {
        guard let vehicle else { return [] }
        return places.filter { $0.vehicleID == vehicle.id }.sorted(by: { ($0.dateLastUsed ?? .distantPast) > ($1.dateLastUsed ?? .distantPast) })
    }

    static func currentOdometerKm(maintenance: [MaintenanceEntry], costs: [CostEntry]) -> Double? {
        let maintenanceKm = maintenance.compactMap(\.odometerKm).max()
        let costKm = costs.compactMap(\.odometerKm).max()
        return [maintenanceKm, costKm].compactMap { $0 }.max()
    }

    static func weightAssessment(
        vehicle: VehicleProfile?,
        trip: Trip?,
        items: [PackingItem],
        passengers: [PassengerLoad],
        settings: TripLoadSettings?
    ) -> WeightAssessmentOutput {
        let packingContributors = packingItems(for: vehicle, trip: trip, items: items).map {
            WeightContributor(label: $0.name, weightKg: $0.totalWeightKg)
        }
        let passengerContributors = self.passengers(for: vehicle, trip: trip, passengers: passengers).map {
            WeightContributor(label: $0.name, weightKg: $0.weightKg)
        }

        let input = WeightAssessmentInput(
            vehicleName: vehicle?.name ?? "",
            gvwrKg: vehicle?.gvwrKg,
            baseWeightKg: vehicle?.preferredBaseWeightKg,
            freshWaterCapacityL: vehicle?.freshWaterCapacityL,
            gasBottleCount: vehicle?.gasBottleCount ?? 0,
            gasBottleSizeKg: vehicle?.gasBottleSizeKg,
            gasBottleFillPercent: settings?.gasBottleFillPercent ?? 0,
            packingItems: packingContributors,
            passengers: passengerContributors,
            freshWaterLiters: settings?.freshWaterLiters ?? 0,
            rearCarrierLoadKg: settings?.rearCarrierLoadKg ?? 0,
            roofLoadKg: settings?.roofLoadKg ?? 0,
            extraLoadKg: settings?.extraLoadKg ?? 0,
            bikesOnRearCarrier: settings?.bikesOnRearCarrier ?? false,
            hasMeasuredAxleValues: vehicle?.frontAxleMeasuredKg != nil || vehicle?.rearAxleMeasuredKg != nil,
            frontAxleMeasuredKg: vehicle?.frontAxleMeasuredKg,
            rearAxleMeasuredKg: vehicle?.rearAxleMeasuredKg
        )
        return ReadinessEngine.assessWeight(input)
    }
}
