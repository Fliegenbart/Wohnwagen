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
        XCTAssertEqual(presentation.primaryMetrics.map(\.title), ["Gesamtgewicht", "Achslast"])
    }

    func testWeightPresentationEqualityUsesVisibleMetricContent() {
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

        XCTAssertEqual(
            WeightPresentation.make(assessment: output, tripTitle: "Bodensee"),
            WeightPresentation.make(assessment: output, tripTitle: "Bodensee")
        )
    }
}
