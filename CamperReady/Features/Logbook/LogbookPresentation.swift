import Foundation

struct SummaryStat: Equatable, Identifiable {
    let title: String
    let value: String

    var id: String { title }
}

struct LogbookPresentation: Equatable {
    let stats: [SummaryStat]

    static func make(totalDistance: Double, totalSpend: Double, readinessOpenItems: Int?) -> Self {
        LogbookPresentation(stats: [
            SummaryStat(title: "Distanz", value: "\(Int(totalDistance)) km"),
            SummaryStat(title: "Investiert", value: totalSpend.euroString),
            SummaryStat(title: "Status", value: readinessValue(for: readinessOpenItems))
        ])
    }

    private static func readinessValue(for readinessOpenItems: Int?) -> String {
        guard let readinessOpenItems else {
            return "Noch kein Camper"
        }

        return readinessOpenItems == 0 ? "Bereit" : "\(readinessOpenItems) offen"
    }
}
