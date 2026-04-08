import XCTest
@testable import CamperReady

final class WeightPresentationTests: XCTestCase {
    func testWeightPresentationBuildsLargeReserveHeadline() {
        let output = WeightAssessmentOutput(
            status: .green,
            estimatedGrossWeightKg: 3050,
            remainingMarginKg: 450,
            summary: "+450 kg Reserve",
            warnings: [],
            nextAction: "Aktuelle Beladung speichern",
            contributors: [],
            axleRisk: .low,
            waterComparisonDeltaKg: 80
        )

        let presentation = WeightPresentation.make(assessment: output, tripTitle: "Bodensee")

        XCTAssertEqual(presentation.headline, "+450 kg Reserve")
        XCTAssertEqual(presentation.support, "Bodensee")
        XCTAssertEqual(presentation.axleRiskLabel, "Niedrig")
        XCTAssertEqual(presentation.confidenceNote, "Schätzung wirkt aktuell plausibel.")
    }

    func testWeightPresentationFallsBackToCurrentTripSupport() {
        let output = WeightAssessmentOutput(
            status: .green,
            estimatedGrossWeightKg: nil,
            remainingMarginKg: nil,
            summary: "Unklare Reserve",
            warnings: [],
            nextAction: nil,
            contributors: [],
            axleRisk: .low,
            waterComparisonDeltaKg: 0
        )

        let presentation = WeightPresentation.make(assessment: output, tripTitle: nil)

        XCTAssertEqual(presentation.support, "Aktuelle Fahrt")
        XCTAssertEqual(presentation.axleRiskLabel, "Niedrig")
        XCTAssertEqual(
            presentation.confidenceNote,
            "Schätzung bleibt vorsichtig, bis zGG und Leergewicht vollständig sind."
        )
    }

    func testWeightPresentationMapsAxleRiskStatesWithoutLosingInformation() {
        XCTAssertEqual(makePresentation(axleRisk: .low).axleRiskLabel, "Niedrig")
        XCTAssertEqual(makePresentation(axleRisk: .elevated).axleRiskLabel, "Erhöht")
        XCTAssertEqual(makePresentation(axleRisk: .measured).axleRiskLabel, "Gemessen")
    }

    func testWeightPresentationHighlightsMeasuredAxleConfidence() {
        XCTAssertEqual(
            makePresentation(axleRisk: .measured).confidenceNote,
            "Achslast basiert auf echten Messwerten."
        )
    }

    func testWeightPresentationUsesCautiousConfidenceForElevatedAxleRisk() {
        XCTAssertEqual(
            makePresentation(axleRisk: .elevated).confidenceNote,
            "Schätzung ist vorsichtig. Achslast besser prüfen."
        )
    }

    private func makePresentation(axleRisk: LoadRiskLevel) -> WeightPresentation {
        let output = WeightAssessmentOutput(
            status: .green,
            estimatedGrossWeightKg: 3050,
            remainingMarginKg: 450,
            summary: "+450 kg Reserve",
            warnings: [],
            nextAction: "Aktuelle Beladung speichern",
            contributors: [],
            axleRisk: axleRisk,
            waterComparisonDeltaKg: 80
        )

        return WeightPresentation.make(assessment: output, tripTitle: "Bodensee")
    }
}
