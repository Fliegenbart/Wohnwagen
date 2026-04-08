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
    let confidenceNote: String

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
            ],
            confidenceNote: confidenceNote(for: assessment)
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

    private static func confidenceNote(for assessment: WeightAssessmentOutput) -> String {
        guard assessment.estimatedGrossWeightKg != nil else {
            return "Schätzung bleibt vorsichtig, bis zGG und Leergewicht vollständig sind."
        }

        switch assessment.axleRisk {
        case .measured:
            return "Achslast basiert auf echten Messwerten."
        case .elevated:
            return "Schätzung ist vorsichtig. Achslast besser prüfen."
        case .low:
            return "Schätzung wirkt aktuell plausibel."
        }
    }
}
