import Foundation
import SwiftData

@Model
final class CostEntry {
    var id: UUID
    var vehicleID: UUID
    var tripID: UUID?
    var date: Date
    var categoryRaw: String
    var amountEUR: Double
    var odometerKm: Double?
    var nights: Int?
    var liters: Double?
    var notes: String
    var isRecurringFixedCost: Bool
    var recurrenceRaw: String?

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        tripID: UUID? = nil,
        date: Date,
        category: CostCategory,
        amountEUR: Double,
        odometerKm: Double? = nil,
        nights: Int? = nil,
        liters: Double? = nil,
        notes: String = "",
        isRecurringFixedCost: Bool = false,
        recurrence: FixedCostInterval? = nil
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.tripID = tripID
        self.date = date
        self.categoryRaw = category.rawValue
        self.amountEUR = amountEUR
        self.odometerKm = odometerKm
        self.nights = nights
        self.liters = liters
        self.notes = notes
        self.isRecurringFixedCost = isRecurringFixedCost
        self.recurrenceRaw = recurrence?.rawValue
    }

    var category: CostCategory {
        get { CostCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var recurrence: FixedCostInterval? {
        get { recurrenceRaw.flatMap(FixedCostInterval.init(rawValue:)) }
        set { recurrenceRaw = newValue?.rawValue }
    }
}
