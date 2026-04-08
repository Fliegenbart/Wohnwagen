import Foundation

struct WeightMetric: Identifiable, Equatable {
    let id: String
    let title: String
    let value: String

    init(title: String, value: String) {
        self.id = title
        self.title = title
        self.value = value
    }
}

struct WeightPresentation: Equatable {
    let headline: String
    let support: String
    let primaryMetrics: [WeightMetric]

    static func make(assessment: WeightAssessmentOutput, tripTitle: String?) -> Self {
        WeightPresentation(
            headline: assessment.summary,
            support: tripTitle ?? "Aktuelle Fahrt",
            primaryMetrics: [
                WeightMetric(
                    title: "Gesamtgewicht",
                    value: assessment.estimatedGrossWeightKg?.kgString ?? "Noch nicht erfasst"
                ),
                WeightMetric(
                    title: "Achslast",
                    value: axleLabel(for: assessment.axleRisk)
                )
            ]
        )
    }

    private static func axleLabel(for risk: LoadRiskLevel) -> String {
        switch risk {
        case .low:
            "Niedrig"
        case .elevated:
            "Erhöht"
        case .measured:
            "Gemessen"
        }
    }
}
