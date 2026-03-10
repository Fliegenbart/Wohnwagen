import Foundation
import SwiftData

@Model
final class DocumentRecord {
    var id: UUID
    var vehicleID: UUID
    var countryCode: String
    var categoryRaw: String
    var title: String
    var validUntil: Date?
    var remind90Days: Bool
    var remind30Days: Bool
    var remind7Days: Bool
    var sourceLabel: String
    var notes: String
    var attachmentPath: String?
    var isStatusRelevant: Bool
    var isBlockingWhenExpired: Bool

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        country: CountryPreset = .de,
        category: DocumentCategory,
        title: String,
        validUntil: Date? = nil,
        remind90Days: Bool = true,
        remind30Days: Bool = true,
        remind7Days: Bool = true,
        sourceLabel: String = "",
        notes: String = "",
        attachmentPath: String? = nil,
        isStatusRelevant: Bool = true,
        isBlockingWhenExpired: Bool = true
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.countryCode = country.rawValue
        self.categoryRaw = category.rawValue
        self.title = title
        self.validUntil = validUntil
        self.remind90Days = remind90Days
        self.remind30Days = remind30Days
        self.remind7Days = remind7Days
        self.sourceLabel = sourceLabel
        self.notes = notes
        self.attachmentPath = attachmentPath
        self.isStatusRelevant = isStatusRelevant
        self.isBlockingWhenExpired = isBlockingWhenExpired
    }

    var country: CountryPreset {
        get { CountryPreset(rawValue: countryCode) ?? .de }
        set { countryCode = newValue.rawValue }
    }

    var category: DocumentCategory {
        get { DocumentCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }
}
