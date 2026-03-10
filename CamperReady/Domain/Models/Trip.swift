import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var vehicleID: UUID
    var title: String
    var startDate: Date
    var endDate: Date?
    var destinationSummary: String
    var plannedDistanceKm: Double?
    var isActive: Bool
    var notes: String

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        title: String,
        startDate: Date,
        endDate: Date? = nil,
        destinationSummary: String = "",
        plannedDistanceKm: Double? = nil,
        isActive: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.destinationSummary = destinationSummary
        self.plannedDistanceKm = plannedDistanceKm
        self.isActive = isActive
        self.notes = notes
    }
}
