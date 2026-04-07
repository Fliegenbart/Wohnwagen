import Foundation

struct HomeActionRow: Equatable, Identifiable {
    let dimensionTitle: String
    let title: String
    let subtitle: String
    let systemImage: String
    let status: ReadinessStatus

    var id: String { dimensionTitle }
}

struct HomeDashboardPresentation: Equatable {
    let focusTitle: String
    let focusSubtitle: String
    let actionRows: [HomeActionRow]

    static func make(snapshot: DashboardSnapshot, tripTitle: String?) -> Self {
        let actionRows = snapshot.dimensions
            .filter { $0.status != .green }
            .map { result in
                HomeActionRow(
                    dimensionTitle: result.title,
                    title: result.summary,
                    subtitle: result.nextAction ?? result.reasons.first ?? "Jetzt prüfen",
                    systemImage: systemImage(for: result.title),
                    status: result.status
                )
            }

        return HomeDashboardPresentation(
            focusTitle: snapshot.overallHeadline,
            focusSubtitle: tripTitle ?? snapshot.nextTripTitle,
            actionRows: actionRows
        )
    }

    private static func systemImage(for dimensionTitle: String) -> String {
        switch dimensionTitle {
        case "Gewicht":
            "scalemass"
        case "Gas & Dokumente":
            "doc.text"
        case "Wartung":
            "wrench.and.screwdriver"
        case "Wasser / Winter":
            "drop"
        case "Kosten":
            "eurosign.circle"
        default:
            "checklist"
        }
    }
}
