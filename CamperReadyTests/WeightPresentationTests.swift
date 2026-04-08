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
        XCTAssertEqual(presentation.primaryMetrics.map(\.title), ["Gesamtgewicht", "Achslast"])
        XCTAssertEqual(presentation.primaryMetrics.map(\.value), ["3050 kg", "Niedrig"])
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
        XCTAssertEqual(presentation.primaryMetrics.map(\.value), ["Noch nicht erfasst", "Niedrig"])
        XCTAssertEqual(
            presentation.confidenceNote,
            "Schätzung bleibt vorsichtig, bis zGG und Leergewicht vollständig sind."
        )
    }

    func testWeightPresentationMapsAxleRiskStatesWithoutLosingInformation() {
        XCTAssertEqual(makePresentation(axleRisk: .low).primaryMetrics.last?.value, "Niedrig")
        XCTAssertEqual(makePresentation(axleRisk: .elevated).primaryMetrics.last?.value, "Erhöht")
        XCTAssertEqual(makePresentation(axleRisk: .measured).primaryMetrics.last?.value, "Gemessen")
    }

    func testWeightPresentationHighlightsMeasuredAxleConfidence() {
        XCTAssertEqual(
            makePresentation(axleRisk: .measured).confidenceNote,
            "Achslast basiert auf echten Messwerten."
        )
    }

    func testWeightMetricUsesStableIdentityFromContent() {
        let firstMetric = WeightMetric(title: "Gesamtgewicht", value: "3050 kg")
        let secondMetric = WeightMetric(title: "Gesamtgewicht", value: "9999 kg")

        XCTAssertEqual(firstMetric.id, secondMetric.id)
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
