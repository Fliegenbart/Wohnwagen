import Foundation

struct SummaryStat: Equatable, Identifiable {
    let title: String
    let value: String

    var id: String { title }
}

struct LogbookPresentation: Equatable {
    let stats: [SummaryStat]

    static func make(totalDistance: Double, totalSpend: Double, readinessAverage: Int) -> Self {
        LogbookPresentation(stats: [
            SummaryStat(title: "Distanz", value: "\(Int(totalDistance)) km"),
            SummaryStat(title: "Investition", value: totalSpend.euroString),
            SummaryStat(title: "Bereitschaft", value: "\(readinessAverage) %")
        ])
    }
}
