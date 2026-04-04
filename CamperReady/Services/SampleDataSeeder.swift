import Foundation
import SwiftData

@MainActor
enum SampleDataSeeder {
    static func seedIfNeeded(context: ModelContext) throws {
        let descriptor = FetchDescriptor<VehicleProfile>()
        let existingCount = try context.fetchCount(descriptor)
        guard existingCount == 0 else { return }

        let vehicle = VehicleProfile(
            name: "WohnWagen Atlas",
            vehicleKind: .motorhome,
            brand: "Hymer",
            model: "ML-T 570",
            year: 2021,
            licensePlate: "M-CR 271",
            country: .de,
            gvwrKg: 3500,
            measuredEmptyWeightKg: 2930,
            freshWaterCapacityL: 100,
            greyWaterCapacityL: 110,
            fuelTankCapacityL: 93,
            gasBottleCount: 2,
            gasBottleSizeKg: 11,
            gasBottleType: .steel,
            serviceIntervalMonths: 12,
            serviceIntervalKm: 20000,
            notes: "Persönliches Bereitschafts-Cockpit für Touren in DACH."
        )
        context.insert(vehicle)

        let trip = Trip(
            vehicleID: vehicle.id,
            title: "Bodensee Wochenendtour",
            startDate: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now,
            endDate: Calendar.current.date(byAdding: .day, value: 6, to: .now),
            destinationSummary: "Lindau und Bregenz",
            plannedDistanceKm: 420,
            isActive: true,
            notes: "Schnelle Frühlingsrunde mit zwei Fahrrädern."
        )
        context.insert(trip)
        vehicle.trips.append(trip)

        let loadSettings = TripLoadSettings(
            vehicleID: vehicle.id,
            tripID: trip.id,
            freshWaterLiters: 20,
            greyWaterLiters: 5,
            gasBottleFillPercent: 100,
            rearCarrierLoadKg: 42,
            roofLoadKg: 12,
            extraLoadKg: 18,
            bikesOnRearCarrier: true,
            notes: "Mit Heckträger und Werkzeugkiste."
        )
        context.insert(loadSettings)
        vehicle.loadSettings.append(loadSettings)

        let passengers = [
            PassengerLoad(vehicleID: vehicle.id, tripID: trip.id, name: "David", weightKg: 84, isDriver: true),
            PassengerLoad(vehicleID: vehicle.id, tripID: trip.id, name: "Lea", weightKg: 68)
        ]
        passengers.forEach(context.insert)
        vehicle.passengers.append(contentsOf: passengers)

        let packingItems = [
            PackingItem(vehicleID: vehicle.id, tripID: trip.id, name: "Geschirrbox", category: .kitchen, quantity: 1, unitWeightKg: 18, isPersistent: true),
            PackingItem(vehicleID: vehicle.id, tripID: trip.id, name: "Klappstühle", category: .campingFurniture, quantity: 2, unitWeightKg: 4.5, isPersistent: true),
            PackingItem(vehicleID: vehicle.id, tripID: trip.id, name: "Campingtisch", category: .campingFurniture, quantity: 1, unitWeightKg: 7, isPersistent: true),
            PackingItem(vehicleID: vehicle.id, tripID: trip.id, name: "Werkzeugkiste", category: .tools, quantity: 1, unitWeightKg: 14, isPersistent: true),
            PackingItem(vehicleID: vehicle.id, tripID: trip.id, name: "Wanderrucksäcke", category: .outdoor, quantity: 2, unitWeightKg: 6, isPersistent: false),
            PackingItem(vehicleID: vehicle.id, tripID: trip.id, name: "Zwei Trekkingräder", category: .bikes, quantity: 2, unitWeightKg: 17, isPersistent: false),
            PackingItem(vehicleID: vehicle.id, tripID: trip.id, name: "Kabel und Technik", category: .tech, quantity: 1, unitWeightKg: 10, isPersistent: true),
            PackingItem(vehicleID: vehicle.id, tripID: trip.id, name: "Kleidung Wochenende", category: .clothing, quantity: 2, unitWeightKg: 6, isPersistent: false)
        ]
        packingItems.forEach(context.insert)
        vehicle.packingItems.append(contentsOf: packingItems)

        let departureTemplate = ChecklistTemplateLibrary.makeChecklist(mode: .departure, vehicleID: vehicle.id, tripID: trip.id)
        departureTemplate.0.state = .inProgress
        departureTemplate.0.isPinned = true
        context.insert(departureTemplate.0)
        vehicle.checklists.append(departureTemplate.0)
        departureTemplate.1.enumerated().forEach { index, item in
            if index < 7 { item.isCompleted = true }
            context.insert(item)
        }

        let winterTemplate = ChecklistTemplateLibrary.makeChecklist(mode: .winterize, vehicleID: vehicle.id, tripID: nil)
        winterTemplate.0.state = .inProgress
        winterTemplate.0.updatedAt = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        context.insert(winterTemplate.0)
        vehicle.checklists.append(winterTemplate.0)
        winterTemplate.1.enumerated().forEach { index, item in
            if index < 8 { item.isCompleted = true }
            context.insert(item)
        }

        let maintenanceEntries = [
            MaintenanceEntry(
                vehicleID: vehicle.id,
                date: Calendar.current.date(byAdding: .month, value: -10, to: .now) ?? .now,
                odometerKm: 41200,
                category: .inspection,
                title: "Jahresinspektion",
                costEUR: 490,
                notes: "Werkstatt in München.",
                nextDueDate: Calendar.current.date(byAdding: .day, value: 18, to: .now),
                nextDueOdometerKm: 61200
            ),
            MaintenanceEntry(
                vehicleID: vehicle.id,
                date: Calendar.current.date(byAdding: .month, value: -14, to: .now) ?? .now,
                odometerKm: 39800,
                category: .battery,
                title: "Aufbaubatterie Check",
                costEUR: 89,
                notes: "Alles ok.",
                nextDueDate: Calendar.current.date(byAdding: .month, value: 10, to: .now)
            ),
            MaintenanceEntry(
                vehicleID: vehicle.id,
                date: Calendar.current.date(byAdding: .month, value: -13, to: .now) ?? .now,
                odometerKm: 40050,
                category: .leakTest,
                title: "Dichtigkeitsprüfung",
                costEUR: 145,
                notes: "Kein Befund.",
                nextDueDate: Calendar.current.date(byAdding: .day, value: -7, to: .now)
            )
        ]
        maintenanceEntries.forEach(context.insert)
        vehicle.maintenanceEntries.append(contentsOf: maintenanceEntries)

        let documents = [
            DocumentRecord(
                vehicleID: vehicle.id,
                country: .de,
                category: .gasInspection,
                title: "Gasprüfung",
                validUntil: Calendar.current.date(byAdding: .month, value: -1, to: .now),
                sourceLabel: "DVFG / Herstellerunterlagen",
                notes: "Regeln können sich ändern. Bitte lokale Vorgaben prüfen.",
                isStatusRelevant: true,
                isBlockingWhenExpired: true
            ),
            DocumentRecord(
                vehicleID: vehicle.id,
                country: .de,
                category: .roadworthiness,
                title: "HU",
                validUntil: Calendar.current.date(byAdding: .day, value: 24, to: .now),
                sourceLabel: "TÜV Süd",
                notes: "Fristen nur als persönliche Erinnerung nutzen.",
                isStatusRelevant: true,
                isBlockingWhenExpired: true
            ),
            DocumentRecord(
                vehicleID: vehicle.id,
                country: .at,
                category: .toll,
                title: "Österreich Vignette",
                validUntil: Calendar.current.date(byAdding: .month, value: 6, to: .now),
                sourceLabel: "ASFINAG",
                notes: "Vor Grenzübertritt Zustand prüfen.",
                isStatusRelevant: false,
                isBlockingWhenExpired: false
            )
        ]
        documents.forEach(context.insert)
        vehicle.documents.append(contentsOf: documents)

        let places = [
            PlaceNote(
                vehicleID: vehicle.id,
                title: "Lindau am See",
                latitude: 47.5459,
                longitude: 9.6836,
                type: .stopover,
                personalRating: 4,
                notes: "Keile nötig, nachts ruhig, Entsorgung morgens entspannt.",
                costEUR: 18,
                dateLastUsed: Calendar.current.date(byAdding: .month, value: -5, to: .now)
            ),
            PlaceNote(
                vehicleID: vehicle.id,
                title: "Bregenz Servicepunkt",
                latitude: 47.5031,
                longitude: 9.7471,
                type: .dump,
                personalRating: 3,
                notes: "Einfahrt eng, aber gutes Ablassen von Grauwasser.",
                costEUR: 4,
                dateLastUsed: Calendar.current.date(byAdding: .month, value: -2, to: .now)
            )
        ]
        places.forEach(context.insert)
        vehicle.places.append(contentsOf: places)

        let costs = [
            CostEntry(vehicleID: vehicle.id, tripID: trip.id, date: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now, category: .fuel, amountEUR: 96, odometerKm: 42000, liters: 52, notes: "Diesel vor Abfahrt"),
            CostEntry(vehicleID: vehicle.id, tripID: trip.id, date: .now, category: .toll, amountEUR: 9.90, notes: "Maut Österreich"),
            CostEntry(vehicleID: vehicle.id, tripID: trip.id, date: .now, category: .campsite, amountEUR: 56, nights: 2, notes: "Stellplatz Bodensee"),
            CostEntry(vehicleID: vehicle.id, tripID: trip.id, date: .now, category: .gas, amountEUR: 24.50, notes: "Gasflasche getauscht"),
            CostEntry(vehicleID: vehicle.id, date: .now, category: .other, amountEUR: 78, notes: "Versicherung", isRecurringFixedCost: true, recurrence: .monthly),
            CostEntry(vehicleID: vehicle.id, date: .now, category: .other, amountEUR: 168, notes: "Jahressteuer", isRecurringFixedCost: true, recurrence: .yearly)
        ]
        costs.forEach(context.insert)
        vehicle.costs.append(contentsOf: costs)

        try context.save()
    }
}
