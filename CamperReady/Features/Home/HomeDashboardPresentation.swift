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
    let focusDetail: String
    let focusContext: String
    let actionRows: [HomeActionRow]

    static func make(snapshot: DashboardSnapshot, tripTitle: String?) -> Self {
        let focusContext = tripTitle ?? snapshot.nextTripTitle
        let primaryOpenDimension = snapshot.dimensions
            .filter { $0.status != .green }
            .sorted { lhs, rhs in
                if lhs.status == rhs.status {
                    return lhs.title < rhs.title
                }
                return lhs.status.rawValue > rhs.status.rawValue
            }
            .first

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
            focusSubtitle: primaryOpenDimension?.summary ?? focusContext,
            focusDetail: primaryOpenDimension?.nextAction ?? primaryOpenDimension?.reasons.first ?? greenDetail(snapshot: snapshot, focusContext: focusContext),
            focusContext: focusContext,
            actionRows: actionRows
        )
    }

    private static func greenDetail(snapshot: DashboardSnapshot, focusContext: String) -> String {
        if focusContext == snapshot.nextTripTitle, snapshot.nextTripTitle != "Keine Reise geplant" {
            return "\(snapshot.vehicleName) ist für \(focusContext) einsatzbereit."
        }
        return "\(snapshot.vehicleName) ist fahrbereit. Alle Kernbereiche sind im grünen Bereich."
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
