import Foundation
import SwiftData

@Model
final class VehicleProfile {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var isPrimary: Bool
    var name: String
    var vehicleKindRaw: String
    var brand: String
    var model: String
    var year: Int?
    var licensePlate: String
    var countryCode: String
    var gvwrKg: Double?
    var curbWeightKg: Double?
    var measuredEmptyWeightKg: Double?
    var frontAxleMeasuredKg: Double?
    var rearAxleMeasuredKg: Double?
    var frontAxleLimitKg: Double?
    var rearAxleLimitKg: Double?
    var freshWaterCapacityL: Double?
    var greyWaterCapacityL: Double?
    var fuelTankCapacityL: Double?
    var gasBottleCount: Int?
    var gasBottleSizeKg: Double?
    var gasBottleTypeRaw: String?
    var serviceIntervalMonths: Int?
    var serviceIntervalKm: Int?
    var notes: String
    var attachmentPath: String?
    @Relationship(deleteRule: .cascade) var trips: [Trip] = []
    @Relationship(deleteRule: .cascade) var packingItems: [PackingItem] = []
    @Relationship(deleteRule: .cascade) var passengers: [PassengerLoad] = []
    @Relationship(deleteRule: .cascade) var loadSettings: [TripLoadSettings] = []
    @Relationship(deleteRule: .cascade) var checklists: [ChecklistRun] = []
    @Relationship(deleteRule: .cascade) var maintenanceEntries: [MaintenanceEntry] = []
    @Relationship(deleteRule: .cascade) var documents: [DocumentRecord] = []
    @Relationship(deleteRule: .cascade) var places: [PlaceNote] = []
    @Relationship(deleteRule: .cascade) var costs: [CostEntry] = []

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isPrimary: Bool = true,
        name: String,
        vehicleKind: VehicleKind,
        brand: String,
        model: String,
        year: Int? = nil,
        licensePlate: String = "",
        country: CountryPreset = .de,
        gvwrKg: Double? = nil,
        curbWeightKg: Double? = nil,
        measuredEmptyWeightKg: Double? = nil,
        frontAxleMeasuredKg: Double? = nil,
        rearAxleMeasuredKg: Double? = nil,
        frontAxleLimitKg: Double? = nil,
        rearAxleLimitKg: Double? = nil,
        freshWaterCapacityL: Double? = nil,
        greyWaterCapacityL: Double? = nil,
        fuelTankCapacityL: Double? = nil,
        gasBottleCount: Int? = nil,
        gasBottleSizeKg: Double? = nil,
        gasBottleType: GasBottleType? = nil,
        serviceIntervalMonths: Int? = nil,
        serviceIntervalKm: Int? = nil,
        notes: String = "",
        attachmentPath: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPrimary = isPrimary
        self.name = name
        self.vehicleKindRaw = vehicleKind.rawValue
        self.brand = brand
        self.model = model
        self.year = year
        self.licensePlate = licensePlate
        self.countryCode = country.rawValue
        self.gvwrKg = gvwrKg
        self.curbWeightKg = curbWeightKg
        self.measuredEmptyWeightKg = measuredEmptyWeightKg
        self.frontAxleMeasuredKg = frontAxleMeasuredKg
        self.rearAxleMeasuredKg = rearAxleMeasuredKg
        self.frontAxleLimitKg = frontAxleLimitKg
        self.rearAxleLimitKg = rearAxleLimitKg
        self.freshWaterCapacityL = freshWaterCapacityL
        self.greyWaterCapacityL = greyWaterCapacityL
        self.fuelTankCapacityL = fuelTankCapacityL
        self.gasBottleCount = gasBottleCount
        self.gasBottleSizeKg = gasBottleSizeKg
        self.gasBottleTypeRaw = gasBottleType?.rawValue
        self.serviceIntervalMonths = serviceIntervalMonths
        self.serviceIntervalKm = serviceIntervalKm
        self.notes = notes
        self.attachmentPath = attachmentPath
    }

    var vehicleKind: VehicleKind {
        get { VehicleKind(rawValue: vehicleKindRaw) ?? .campervan }
        set { vehicleKindRaw = newValue.rawValue }
    }

    var country: CountryPreset {
        get { CountryPreset(rawValue: countryCode) ?? .de }
        set { countryCode = newValue.rawValue }
    }

    var gasBottleType: GasBottleType? {
        get { gasBottleTypeRaw.flatMap(GasBottleType.init(rawValue:)) }
        set { gasBottleTypeRaw = newValue?.rawValue }
    }

    var preferredBaseWeightKg: Double? {
        measuredEmptyWeightKg ?? curbWeightKg
    }
}
