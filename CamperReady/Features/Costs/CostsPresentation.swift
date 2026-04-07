import Foundation

struct CostsPresentation: Equatable {
    let stats: [SummaryStat]

    static func make(tripTotal: Double, perNight: Double, perHundredKm: Double?, annualTotal: Double) -> Self {
        CostsPresentation(stats: [
            SummaryStat(title: "Diese Reise", value: tripTotal.euroString),
            SummaryStat(title: "Pro Nacht", value: perNight.euroString),
            SummaryStat(title: "Pro 100 km", value: perHundredKm.map { $0.euroString } ?? "Offen"),
            SummaryStat(title: "Dieses Jahr", value: annualTotal.euroString)
        ])
    }
}
