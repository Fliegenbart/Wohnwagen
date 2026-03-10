import Foundation
import SwiftData

@Model
final class MaintenanceEntry {
    var id: UUID
    var vehicleID: UUID
    var date: Date
    var odometerKm: Double?
    var categoryRaw: String
    var title: String
    var costEUR: Double?
    var notes: String
    var nextDueDate: Date?
    var nextDueOdometerKm: Double?
    var attachmentPath: String?

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        date: Date,
        odometerKm: Double? = nil,
        category: MaintenanceCategory,
        title: String,
        costEUR: Double? = nil,
        notes: String = "",
        nextDueDate: Date? = nil,
        nextDueOdometerKm: Double? = nil,
        attachmentPath: String? = nil
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.date = date
        self.odometerKm = odometerKm
        self.categoryRaw = category.rawValue
        self.title = title
        self.costEUR = costEUR
        self.notes = notes
        self.nextDueDate = nextDueDate
        self.nextDueOdometerKm = nextDueOdometerKm
        self.attachmentPath = attachmentPath
    }

    var category: MaintenanceCategory {
        get { MaintenanceCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }
}
