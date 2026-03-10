import Foundation
import SwiftData

@Model
final class PackingItem {
    var id: UUID
    var vehicleID: UUID
    var tripID: UUID?
    var name: String
    var categoryRaw: String
    var quantity: Int
    var unitWeightKg: Double
    var isPersistent: Bool
    var includeInCurrentLoad: Bool

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        tripID: UUID? = nil,
        name: String,
        category: WeightCategory,
        quantity: Int = 1,
        unitWeightKg: Double,
        isPersistent: Bool = false,
        includeInCurrentLoad: Bool = true
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.tripID = tripID
        self.name = name
        self.categoryRaw = category.rawValue
        self.quantity = quantity
        self.unitWeightKg = unitWeightKg
        self.isPersistent = isPersistent
        self.includeInCurrentLoad = includeInCurrentLoad
    }

    var category: WeightCategory {
        get { WeightCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var totalWeightKg: Double {
        Double(quantity) * unitWeightKg
    }
}
