import Foundation

struct WeightMetric: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let value: String

    static func == (lhs: WeightMetric, rhs: WeightMetric) -> Bool {
        lhs.title == rhs.title && lhs.value == rhs.value
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
                    value: assessment.estimatedGrossWeightKg?.kgString ?? "Unklar"
                ),
                WeightMetric(
                    title: "Achslast",
                    value: assessment.axleRisk == .measured ? "Gemessen" : "Prüfen"
                )
            ]
        )
    }
}
