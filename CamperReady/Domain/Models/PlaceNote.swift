import Foundation
import SwiftData

@Model
final class PlaceNote {
    var id: UUID
    var vehicleID: UUID
    var title: String
    var latitude: Double
    var longitude: Double
    var typeRaw: String
    var personalRating: Int?
    var notes: String
    var costEUR: Double?
    var dateLastUsed: Date?
    var attachmentPath: String?

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        title: String,
        latitude: Double,
        longitude: Double,
        type: PlaceType,
        personalRating: Int? = nil,
        notes: String = "",
        costEUR: Double? = nil,
        dateLastUsed: Date? = nil,
        attachmentPath: String? = nil
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.title = title
        self.latitude = latitude
        self.longitude = longitude
        self.typeRaw = type.rawValue
        self.personalRating = personalRating
        self.notes = notes
        self.costEUR = costEUR
        self.dateLastUsed = dateLastUsed
        self.attachmentPath = attachmentPath
    }

    var type: PlaceType {
        get { PlaceType(rawValue: typeRaw) ?? .stopover }
        set { typeRaw = newValue.rawValue }
    }
}
