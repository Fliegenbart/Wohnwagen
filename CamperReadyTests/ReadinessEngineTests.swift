import XCTest
@testable import CamperReady

final class ReadinessEngineTests: XCTestCase {
    func testWeightTurnsRedWhenOverloaded() {
        let input = WeightAssessmentInput(
            vehicleName: "Testmobil",
            gvwrKg: 3500,
            baseWeightKg: 3000,
            freshWaterCapacityL: 100,
            gasBottleCount: 2,
            gasBottleSizeKg: 11,
            gasBottleFillPercent: 100,
            packingItems: [WeightContributor(label: "Bikes", weightKg: 120)],
            passengers: [WeightContributor(label: "Crew", weightKg: 190)],
            freshWaterLiters: 100,
            rearCarrierLoadKg: 55,
            roofLoadKg: 40,
            extraLoadKg: 30,
            bikesOnRearCarrier: true,
            hasMeasuredAxleValues: false,
            frontAxleMeasuredKg: nil,
            rearAxleMeasuredKg: nil
        )

        let result = ReadinessEngine.assessWeight(input)

        XCTAssertEqual(result.status, .red)
        XCTAssertEqual(result.remainingMarginKg.map(Int.init), -57)
    }

    func testWeightStaysYellowWhenAxleRiskIsUnknown() {
        let input = WeightAssessmentInput(
            vehicleName: "Testmobil",
            gvwrKg: 3500,
            baseWeightKg: 2900,
            freshWaterCapacityL: 100,
            gasBottleCount: 2,
            gasBottleSizeKg: 11,
            gasBottleFillPercent: 100,
            packingItems: [WeightContributor(label: "Bikes", weightKg: 34)],
            passengers: [WeightContributor(label: "Crew", weightKg: 150)],
            freshWaterLiters: 20,
            rearCarrierLoadKg: 42,
            roofLoadKg: 12,
            extraLoadKg: 10,
            bikesOnRearCarrier: true,
            hasMeasuredAxleValues: false,
            frontAxleMeasuredKg: nil,
            rearAxleMeasuredKg: nil
        )

        let result = ReadinessEngine.assessWeight(input)

        XCTAssertEqual(result.status, .yellow)
        XCTAssertEqual(result.axleRisk, .elevated)
    }

    func testExpiredDocumentIsBlocking() {
        let expired = DocumentRecord(
            vehicleID: UUID(),
            country: .de,
            category: .gasInspection,
            title: "Gasprüfung",
            validUntil: Calendar.current.date(byAdding: .day, value: -3, to: .now),
            sourceLabel: "Test",
            notes: "",
            isStatusRelevant: true,
            isBlockingWhenExpired: true
        )

        let result = ReadinessEngine.evaluateLegal(documents: [expired], now: .now)

        XCTAssertEqual(result.status, .red)
        XCTAssertTrue(result.summary.contains("abgelaufen"))
    }

    func testAnnualizedFixedCostUsesRecurrence() {
        let fixedCost = CostEntry(
            vehicleID: UUID(),
            date: .now,
            category: .other,
            amountEUR: 80,
            notes: "Versicherung",
            isRecurringFixedCost: true,
            recurrence: .monthly
        )

        XCTAssertEqual(ReadinessEngine.annualizedAmount(for: fixedCost), 960, accuracy: 0.001)
    }

    func testCSVRowEscapesDelimitersAndQuotes() {
        let row = ExportService.csvRow(["Hallo;Welt", #"=SUM(A1:A2)"#, #"A "Quote""#])

        XCTAssertEqual(row, "\"Hallo;Welt\";\"'=SUM(A1:A2)\";\"A \"\"Quote\"\"\"")
    }

    func testCSVFieldFlattensNewlines() {
        let field = ExportService.csvField("Zeile 1\nZeile 2")

        XCTAssertEqual(field, "\"Zeile 1 Zeile 2\"")
    }

    func testPlaceDraftCannotSaveWithBlankTitleOrInvalidCoordinates() {
        var draft = PlaceDraft(place: nil)
        draft.title = "   "
        draft.latitude = 91
        draft.longitude = 13.4

        XCTAssertFalse(draft.canSave)

        draft.title = "Ruhiger Stellplatz"
        draft.latitude = 48.1
        draft.longitude = 190

        XCTAssertFalse(draft.canSave)
    }

    func testPlaceDraftNormalizesRatingToValidRange() {
        var draft = PlaceDraft(place: nil)
        draft.personalRating = 8
        XCTAssertEqual(draft.normalizedRating, 5)

        draft.personalRating = 0
        XCTAssertNil(draft.normalizedRating)

        draft.personalRating = 4
        XCTAssertEqual(draft.normalizedRating, 4)
    }
}
