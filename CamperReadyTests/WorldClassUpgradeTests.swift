import Foundation
import SwiftData
import XCTest
@testable import CamperReady

@MainActor
final class WorldClassUpgradeTests: XCTestCase {
    func testWeightEditorCreatesPersistentAndTripSpecificItems() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vehicle = VehicleProfile(name: "Atlas", vehicleKind: .motorhome, brand: "Hymer", model: "ML-T")
        let trip = Trip(vehicleID: vehicle.id, title: "Wochenende", startDate: .now, isActive: true)
        context.insert(vehicle)
        context.insert(trip)
        vehicle.trips.append(trip)

        let persistentDraft = PackingItemDraftData(
            name: "Geschirr",
            category: .kitchen,
            quantity: 1,
            unitWeightKg: 12,
            isPersistent: true,
            includeInCurrentLoad: true
        )

        let persistentItem = try WeightEditorService.savePackingItem(
            draft: persistentDraft,
            existingItem: nil,
            vehicle: vehicle,
            trip: trip,
            context: context
        )

        XCTAssertNil(persistentItem.tripID)

        let tripDraft = PackingItemDraftData(
            name: "Räder",
            category: .bikes,
            quantity: 2,
            unitWeightKg: 17,
            isPersistent: false,
            includeInCurrentLoad: true
        )

        let tripItem = try WeightEditorService.savePackingItem(
            draft: tripDraft,
            existingItem: nil,
            vehicle: vehicle,
            trip: trip,
            context: context
        )

        XCTAssertEqual(tripItem.tripID, trip.id)
        XCTAssertEqual(vehicle.packingItems.count, 2)
    }

    func testWeightEditorEnsuresBaseLoadSettings() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vehicle = VehicleProfile(name: "Atlas", vehicleKind: .motorhome, brand: "Hymer", model: "ML-T")
        context.insert(vehicle)

        let settings = try WeightEditorService.ensureLoadSettings(vehicle: vehicle, trip: nil, context: context)

        XCTAssertEqual(settings.vehicleID, vehicle.id)
        XCTAssertNil(settings.tripID)
        XCTAssertEqual(vehicle.loadSettings.count, 1)
    }

    func testWeightEditorCreatesAndDeletesPassengers() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vehicle = VehicleProfile(name: "Atlas", vehicleKind: .motorhome, brand: "Hymer", model: "ML-T")
        let trip = Trip(vehicleID: vehicle.id, title: "Bayern", startDate: .now, isActive: true)
        context.insert(vehicle)
        context.insert(trip)
        vehicle.trips.append(trip)

        let passenger = try WeightEditorService.savePassenger(
            draft: PassengerDraftData(name: "Mila", weightKg: 68, isDriver: true, isPersistent: false),
            existingPassenger: nil,
            vehicle: vehicle,
            trip: trip,
            context: context
        )

        XCTAssertEqual(passenger.tripID, trip.id)
        XCTAssertEqual(vehicle.passengers.count, 1)

        try WeightEditorService.deletePassenger(passenger, from: vehicle, context: context)

        XCTAssertTrue(vehicle.passengers.isEmpty)
    }

    func testChecklistEditorComputesStateFromRequiredItems() {
        let checklistID = UUID()
        let items = [
            ChecklistItemRecord(checklistID: checklistID, title: "Strom trennen", isRequired: true, isCompleted: true, sortOrder: 0),
            ChecklistItemRecord(checklistID: checklistID, title: "Gas sichern", isRequired: true, isCompleted: false, sortOrder: 1)
        ]

        XCTAssertEqual(ChecklistEditorService.computeState(items: items), .inProgress)

        let completedItems = items.map { item -> ChecklistItemRecord in
            item.isCompleted = true
            return item
        }
        XCTAssertEqual(ChecklistEditorService.computeState(items: completedItems), .complete)
    }

    func testChecklistEditorSavesAndReordersItems() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vehicle = VehicleProfile(name: "Atlas", vehicleKind: .motorhome, brand: "Hymer", model: "ML-T")
        context.insert(vehicle)
        let checklist = try ChecklistEditorService.startChecklist(mode: .departure, vehicle: vehicle, trip: nil, context: context)

        let custom = try ChecklistEditorService.saveItem(
            draft: ChecklistItemDraftData(title: "Kamera sichern", details: "", isRequired: false, contributesToReadiness: false),
            to: checklist,
            existingItem: nil,
            context: context
        )

        XCTAssertTrue(checklist.items.contains(where: { $0.id == custom.id }))

        try ChecklistEditorService.moveItem(custom, in: checklist, direction: -1, context: context)

        let ordered = checklist.items.sorted { $0.sortOrder < $1.sortOrder }
        XCTAssertTrue(ordered.contains(where: { $0.id == custom.id }))
    }

    func testReminderPlannerCreatesDocumentAndDeparturePlans() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 20, to: .now)!
        let document = DocumentRecord(
            vehicleID: UUID(),
            country: .de,
            category: .gasInspection,
            title: "Gasprüfung",
            validUntil: futureDate,
            sourceLabel: "TÜV"
        )

        let trip = Trip(
            vehicleID: UUID(),
            title: "Bodensee",
            startDate: Calendar.current.date(byAdding: .day, value: 2, to: .now)!,
            isActive: true
        )
        let checklist = ChecklistRun(vehicleID: trip.vehicleID, tripID: trip.id, mode: .departure, title: "Abfahrt", state: .inProgress)
        let item = ChecklistItemRecord(checklistID: checklist.id, title: "Stützen hoch", isRequired: true, isCompleted: false, sortOrder: 0)

        let plans = ReminderPlanner.plans(
            documents: [document],
            maintenance: [],
            checklists: [checklist],
            checklistItems: [item],
            trips: [trip],
            currentOdometerKm: nil,
            now: .now
        )

        XCTAssertTrue(plans.contains(where: { $0.identifier.contains("document") }))
        XCTAssertTrue(plans.contains(where: { $0.identifier.contains("departure") }))
    }

    func testReminderPlannerCreatesMaintenancePlanWhenDueKilometersAreClose() {
        let maintenance = MaintenanceEntry(
            vehicleID: UUID(),
            date: .now,
            odometerKm: 50000,
            category: .inspection,
            title: "Inspektion",
            nextDueOdometerKm: 50300
        )

        let plans = ReminderPlanner.plans(
            documents: [],
            maintenance: [maintenance],
            checklists: [],
            checklistItems: [],
            trips: [],
            currentOdometerKm: 50050,
            now: .now
        )

        XCTAssertTrue(plans.contains(where: { $0.identifier.contains("maintenance.km") }))
    }

    func testNavigationStateMapsReadinessActionsToTabs() {
        let navigation = AppNavigationState()

        navigation.navigate(for: .documents)
        XCTAssertEqual(navigation.selectedTab, .logbook)
        XCTAssertEqual(navigation.pendingRoute, .logbook(.documents))

        navigation.navigate(for: .departureChecklist)
        XCTAssertEqual(navigation.selectedTab, .checklists)
        XCTAssertEqual(navigation.pendingRoute, .checklist(mode: .departure))
    }

    func testSampleDataIsDisabledForProductionLaunches() {
        XCTAssertFalse(AppReleaseConfiguration.shouldSeedSampleDataOnFirstLaunch)
    }

    func testActiveVehicleResolverKeepsStoredVehicleWhenItExists() {
        let vehicleA = VehicleProfile(name: "Atlas", vehicleKind: .motorhome, brand: "Hymer", model: "ML-T")
        let vehicleB = VehicleProfile(name: "Nova", vehicleKind: .campervan, brand: "Pössl", model: "Summit")

        let resolution = ActiveVehicleResolver.resolve(
            storedVehicleID: vehicleB.id,
            vehicles: [vehicleA, vehicleB]
        )

        XCTAssertEqual(resolution.selectedVehicleID, vehicleB.id)
        XCTAssertFalse(resolution.needsSelection)
    }

    func testActiveVehicleResolverAutoSelectsSingleVehicle() {
        let vehicle = VehicleProfile(name: "Atlas", vehicleKind: .motorhome, brand: "Hymer", model: "ML-T")

        let resolution = ActiveVehicleResolver.resolve(
            storedVehicleID: nil,
            vehicles: [vehicle]
        )

        XCTAssertEqual(resolution.selectedVehicleID, vehicle.id)
        XCTAssertFalse(resolution.needsSelection)
    }

    func testActiveVehicleResolverRequestsSelectionWhenMultipleVehiclesExistWithoutValidChoice() {
        let vehicleA = VehicleProfile(name: "Atlas", vehicleKind: .motorhome, brand: "Hymer", model: "ML-T")
        let vehicleB = VehicleProfile(name: "Nova", vehicleKind: .campervan, brand: "Pössl", model: "Summit")

        let resolution = ActiveVehicleResolver.resolve(
            storedVehicleID: UUID(),
            vehicles: [vehicleA, vehicleB]
        )

        XCTAssertNil(resolution.selectedVehicleID)
        XCTAssertTrue(resolution.needsSelection)
    }

    func testAttachmentStoreImportsAndDeletesFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = AttachmentStore(rootDirectory: root)
        let source = root.appendingPathComponent("source.pdf")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("Beleg".utf8).write(to: source)

        let storedPath = try store.importFile(from: source)
        let storedURL = try XCTUnwrap(store.url(for: storedPath))

        XCTAssertTrue(FileManager.default.fileExists(atPath: storedURL.path))

        try store.deleteAttachment(at: storedPath)

        XCTAssertFalse(FileManager.default.fileExists(atPath: storedURL.path))
    }

    func testAttachmentStoreRejectsUnsupportedFileTypes() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = AttachmentStore(rootDirectory: root)
        let source = root.appendingPathComponent("notiz.txt")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("Nur Text".utf8).write(to: source)

        XCTAssertThrowsError(try store.importFile(from: source)) { error in
            XCTAssertEqual(error as? AttachmentStoreError, .unsupportedType)
        }
    }

    func testPersistenceControllerPreparesProtectedStoreDirectory() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)

        let storeURL = try PersistenceController.preparePersistentStoreLocation(baseDirectory: root)
        try Data().write(to: storeURL)
        XCTAssertNoThrow(try PersistenceController.protectPersistentStoreArtifacts(at: storeURL))

        XCTAssertEqual(storeURL.lastPathComponent, "default.store")
        XCTAssertEqual(storeURL.deletingLastPathComponent().lastPathComponent, PersistenceController.storeDirectoryName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.deletingLastPathComponent().path))
    }

    func testExportServiceCreatesVehicleArchiveJSON() throws {
        let vehicle = VehicleProfile(name: "Atlas", vehicleKind: .motorhome, brand: "Hymer", model: "ML-T")

        let file = try ExportService.exportVehicleArchive(
            vehicle: vehicle,
            trips: [],
            packingItems: [],
            passengers: [],
            loadSettings: [],
            checklists: [],
            checklistItems: [],
            maintenance: [],
            documents: [],
            places: [],
            costs: []
        )

        let data = try Data(contentsOf: file.url)
        let content = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(content.contains("\"name\" : \"Atlas\""))
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: PersistenceController.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: PersistenceController.schema, configurations: [configuration])
    }
}
