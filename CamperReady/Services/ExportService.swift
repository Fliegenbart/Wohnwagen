import Foundation
import UIKit

struct ExportFile {
    let title: String
    let url: URL
}

enum ExportService {
    static func exportCostsCSV(costs: [CostEntry]) throws -> ExportFile {
        let header = csvRow(["Datum", "Kategorie", "Betrag EUR", "Notiz"])
        let rows = costs
            .sorted(by: { $0.date > $1.date })
            .map {
                csvRow([
                    $0.date.shortDateString(),
                    $0.category.title,
                    euroString($0.amountEUR),
                    $0.notes
                ])
            }
            .joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CamperReady-Kosten.csv")
        try (header + "\n" + rows).write(to: url, atomically: true, encoding: .utf8)
        return ExportFile(title: "Kosten CSV", url: url)
    }

    static func exportMaintenanceCSV(entries: [MaintenanceEntry]) throws -> ExportFile {
        let header = csvRow(["Datum", "Kategorie", "Titel", "Kosten EUR", "Notiz"])
        let rows = entries
            .sorted(by: { $0.date > $1.date })
            .map {
                csvRow([
                    $0.date.shortDateString(),
                    $0.category.title,
                    $0.title,
                    euroString($0.costEUR ?? 0),
                    $0.notes
                ])
            }
            .joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CamperReady-Wartung.csv")
        try (header + "\n" + rows).write(to: url, atomically: true, encoding: .utf8)
        return ExportFile(title: "Wartung CSV", url: url)
    }

    static func exportDashboardPDF(snapshot: DashboardSnapshot) throws -> ExportFile {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CamperReady-Dashboard.pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            let headline = [
                "CamperReady Bereitschaftsbericht",
                snapshot.vehicleName,
                snapshot.nextTripTitle,
                snapshot.overallHeadline
            ].joined(separator: "\n")

            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 6
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .paragraphStyle: paragraph
            ]
            headline.draw(in: CGRect(x: 40, y: 40, width: 515, height: 120), withAttributes: attributes)

            let body = snapshot.dimensions.map { result in
                "\(result.title): \(result.summary)\n\(result.reasons.joined(separator: " "))\nNächster Schritt: \(result.nextAction ?? "Kein weiterer Schritt nötig.")"
            }.joined(separator: "\n\n")
            body.draw(in: CGRect(x: 40, y: 180, width: 515, height: 600), withAttributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .paragraphStyle: paragraph
            ])
        }
        return ExportFile(title: "Dashboard PDF", url: url)
    }

    static func exportVehicleArchive(
        vehicle: VehicleProfile,
        trips: [Trip],
        packingItems: [PackingItem],
        passengers: [PassengerLoad],
        loadSettings: [TripLoadSettings],
        checklists: [ChecklistRun],
        checklistItems: [ChecklistItemRecord],
        maintenance: [MaintenanceEntry],
        documents: [DocumentRecord],
        places: [PlaceNote],
        costs: [CostEntry]
    ) throws -> ExportFile {
        let archive = VehicleArchiveSnapshot(
            exportedAt: .now,
            vehicle: VehicleSnapshot(vehicle),
            trips: trips
                .filter { $0.vehicleID == vehicle.id }
                .map(TripSnapshot.init),
            packingItems: packingItems
                .filter { $0.vehicleID == vehicle.id }
                .map(PackingItemSnapshot.init),
            passengers: passengers
                .filter { $0.vehicleID == vehicle.id }
                .map(PassengerSnapshot.init),
            loadSettings: loadSettings
                .filter { $0.vehicleID == vehicle.id }
                .map(LoadSettingsSnapshot.init),
            checklists: checklists
                .filter { $0.vehicleID == vehicle.id }
                .map { checklist in
                    ChecklistSnapshot(
                        checklist,
                        items: checklistItems.filter { $0.checklistID == checklist.id }.map(ChecklistItemSnapshot.init)
                    )
                },
            maintenance: maintenance
                .filter { $0.vehicleID == vehicle.id }
                .map(MaintenanceSnapshot.init),
            documents: documents
                .filter { $0.vehicleID == vehicle.id }
                .map(DocumentSnapshot.init),
            places: places
                .filter { $0.vehicleID == vehicle.id }
                .map(PlaceSnapshot.init),
            costs: costs
                .filter { $0.vehicleID == vehicle.id }
                .map(CostSnapshot.init)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(archive)

        let fileName = "CamperReady-\(sanitizedFileName(vehicle.name))-Archiv.json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return ExportFile(title: "Datenarchiv", url: url)
    }

    static func csvRow(_ fields: [String]) -> String {
        fields.map(csvField).joined(separator: ";")
    }

    static func csvField(_ value: String) -> String {
        let normalized = value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\n", with: " ")
        let escaped = normalized.replacingOccurrences(of: "\"", with: "\"\"")
        let prefixed = needsFormulaEscape(escaped) ? "'\(escaped)" : escaped
        return "\"\(prefixed)\""
    }

    static func euroString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    private static func needsFormulaEscape(_ value: String) -> Bool {
        guard let first = value.first else { return false }
        return ["=", "+", "-", "@"].contains(String(first))
    }

    private static func sanitizedFileName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
    }
}

private struct VehicleArchiveSnapshot: Encodable {
    let exportedAt: Date
    let vehicle: VehicleSnapshot
    let trips: [TripSnapshot]
    let packingItems: [PackingItemSnapshot]
    let passengers: [PassengerSnapshot]
    let loadSettings: [LoadSettingsSnapshot]
    let checklists: [ChecklistSnapshot]
    let maintenance: [MaintenanceSnapshot]
    let documents: [DocumentSnapshot]
    let places: [PlaceSnapshot]
    let costs: [CostSnapshot]
}

private struct VehicleSnapshot: Encodable {
    let id: UUID
    let name: String
    let vehicleKind: String
    let brand: String
    let model: String
    let year: Int?
    let licensePlate: String
    let gvwrKg: Double?
    let preferredBaseWeightKg: Double?
    let countryCode: String

    init(_ vehicle: VehicleProfile) {
        self.id = vehicle.id
        self.name = vehicle.name
        self.vehicleKind = vehicle.vehicleKind.title
        self.brand = vehicle.brand
        self.model = vehicle.model
        self.year = vehicle.year
        self.licensePlate = vehicle.licensePlate
        self.gvwrKg = vehicle.gvwrKg
        self.preferredBaseWeightKg = vehicle.preferredBaseWeightKg
        self.countryCode = vehicle.countryCode
    }
}

private struct TripSnapshot: Encodable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date?
    let destinationSummary: String
    let plannedDistanceKm: Double?
    let isActive: Bool

    init(_ trip: Trip) {
        self.id = trip.id
        self.title = trip.title
        self.startDate = trip.startDate
        self.endDate = trip.endDate
        self.destinationSummary = trip.destinationSummary
        self.plannedDistanceKm = trip.plannedDistanceKm
        self.isActive = trip.isActive
    }
}

private struct PackingItemSnapshot: Encodable {
    let id: UUID
    let tripID: UUID?
    let name: String
    let category: String
    let quantity: Int
    let unitWeightKg: Double
    let isPersistent: Bool
    let includeInCurrentLoad: Bool

    init(_ item: PackingItem) {
        self.id = item.id
        self.tripID = item.tripID
        self.name = item.name
        self.category = item.category.title
        self.quantity = item.quantity
        self.unitWeightKg = item.unitWeightKg
        self.isPersistent = item.isPersistent
        self.includeInCurrentLoad = item.includeInCurrentLoad
    }
}

private struct PassengerSnapshot: Encodable {
    let id: UUID
    let tripID: UUID?
    let name: String
    let weightKg: Double
    let isDriver: Bool

    init(_ passenger: PassengerLoad) {
        self.id = passenger.id
        self.tripID = passenger.tripID
        self.name = passenger.name
        self.weightKg = passenger.weightKg
        self.isDriver = passenger.isDriver
    }
}

private struct LoadSettingsSnapshot: Encodable {
    let id: UUID
    let tripID: UUID?
    let freshWaterLiters: Double
    let greyWaterLiters: Double
    let gasBottleFillPercent: Double
    let rearCarrierLoadKg: Double
    let roofLoadKg: Double
    let extraLoadKg: Double
    let bikesOnRearCarrier: Bool
    let notes: String

    init(_ settings: TripLoadSettings) {
        self.id = settings.id
        self.tripID = settings.tripID
        self.freshWaterLiters = settings.freshWaterLiters
        self.greyWaterLiters = settings.greyWaterLiters
        self.gasBottleFillPercent = settings.gasBottleFillPercent
        self.rearCarrierLoadKg = settings.rearCarrierLoadKg
        self.roofLoadKg = settings.roofLoadKg
        self.extraLoadKg = settings.extraLoadKg
        self.bikesOnRearCarrier = settings.bikesOnRearCarrier
        self.notes = settings.notes
    }
}

private struct ChecklistSnapshot: Encodable {
    let id: UUID
    let tripID: UUID?
    let mode: String
    let title: String
    let createdAt: Date
    let updatedAt: Date
    let state: String
    let isPinned: Bool
    let items: [ChecklistItemSnapshot]

    init(_ checklist: ChecklistRun, items: [ChecklistItemSnapshot]) {
        self.id = checklist.id
        self.tripID = checklist.tripID
        self.mode = checklist.mode.title
        self.title = checklist.title
        self.createdAt = checklist.createdAt
        self.updatedAt = checklist.updatedAt
        self.state = checklist.state.rawValue
        self.isPinned = checklist.isPinned
        self.items = items.sorted { $0.sortOrder < $1.sortOrder }
    }
}

private struct ChecklistItemSnapshot: Encodable {
    let id: UUID
    let title: String
    let details: String
    let isRequired: Bool
    let isCompleted: Bool
    let contributesToReadiness: Bool
    let sortOrder: Int

    init(_ item: ChecklistItemRecord) {
        self.id = item.id
        self.title = item.title
        self.details = item.details
        self.isRequired = item.isRequired
        self.isCompleted = item.isCompleted
        self.contributesToReadiness = item.contributesToReadiness
        self.sortOrder = item.sortOrder
    }
}

private struct MaintenanceSnapshot: Encodable {
    let id: UUID
    let date: Date
    let odometerKm: Double?
    let category: String
    let title: String
    let costEUR: Double?
    let notes: String
    let nextDueDate: Date?
    let nextDueOdometerKm: Double?
    let attachmentPath: String?

    init(_ entry: MaintenanceEntry) {
        self.id = entry.id
        self.date = entry.date
        self.odometerKm = entry.odometerKm
        self.category = entry.category.title
        self.title = entry.title
        self.costEUR = entry.costEUR
        self.notes = entry.notes
        self.nextDueDate = entry.nextDueDate
        self.nextDueOdometerKm = entry.nextDueOdometerKm
        self.attachmentPath = entry.attachmentPath
    }
}

private struct DocumentSnapshot: Encodable {
    let id: UUID
    let country: String
    let category: String
    let title: String
    let validUntil: Date?
    let sourceLabel: String
    let notes: String
    let attachmentPath: String?

    init(_ document: DocumentRecord) {
        self.id = document.id
        self.country = document.country.title
        self.category = document.category.title
        self.title = document.title
        self.validUntil = document.validUntil
        self.sourceLabel = document.sourceLabel
        self.notes = document.notes
        self.attachmentPath = document.attachmentPath
    }
}

private struct PlaceSnapshot: Encodable {
    let id: UUID
    let title: String
    let latitude: Double
    let longitude: Double
    let type: String
    let personalRating: Int?
    let notes: String
    let costEUR: Double?
    let dateLastUsed: Date?
    let attachmentPath: String?

    init(_ place: PlaceNote) {
        self.id = place.id
        self.title = place.title
        self.latitude = place.latitude
        self.longitude = place.longitude
        self.type = place.type.title
        self.personalRating = place.personalRating
        self.notes = place.notes
        self.costEUR = place.costEUR
        self.dateLastUsed = place.dateLastUsed
        self.attachmentPath = place.attachmentPath
    }
}

private struct CostSnapshot: Encodable {
    let id: UUID
    let tripID: UUID?
    let date: Date
    let category: String
    let amountEUR: Double
    let notes: String
    let odometerKm: Double?
    let nights: Int?
    let isRecurringFixedCost: Bool

    init(_ cost: CostEntry) {
        self.id = cost.id
        self.tripID = cost.tripID
        self.date = cost.date
        self.category = cost.category.title
        self.amountEUR = cost.amountEUR
        self.notes = cost.notes
        self.odometerKm = cost.odometerKm
        self.nights = cost.nights
        self.isRecurringFixedCost = cost.isRecurringFixedCost
    }
}
