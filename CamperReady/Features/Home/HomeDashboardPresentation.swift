import Foundation

struct HomeActionRow: Equatable, Identifiable {
    let dimensionTitle: String
    let title: String
    let subtitle: String
    let systemImage: String
    let status: ReadinessStatus
    let action: ReadinessActionKind?

    var id: String { dimensionTitle }
}

struct HomeOverviewRow: Equatable, Identifiable {
    let title: String
    let summary: String
    let systemImage: String
    let status: ReadinessStatus
    let action: ReadinessActionKind?

    var id: String { title }
}

struct HomeDashboardPresentation: Equatable {
    let focusTitle: String
    let focusSubtitle: String
    let focusDetail: String
    let focusContext: String
    let overviewRows: [HomeOverviewRow]
    let actionRows: [HomeActionRow]

    static func make(snapshot: DashboardSnapshot, tripTitle: String?) -> Self {
        let focusContext = tripTitle ?? snapshot.nextTripTitle
        let overviewRows = snapshot.dimensions.map { result in
            HomeOverviewRow(
                title: result.title,
                summary: result.summary,
                systemImage: result.metadata.systemImage,
                status: result.status,
                action: result.metadata.action
            )
        }

        let actionRows = snapshot.dimensions
            .filter { $0.status != .green }
            .sorted { lhs, rhs in
                if lhs.status == rhs.status {
                    return lhs.metadata.sortOrder < rhs.metadata.sortOrder
                }
                return lhs.status.rawValue > rhs.status.rawValue
            }
            .map { result in
                HomeActionRow(
                    dimensionTitle: result.title,
                    title: result.summary,
                    subtitle: result.nextAction ?? result.reasons.first ?? "Jetzt prüfen",
                    systemImage: result.metadata.systemImage,
                    status: result.status,
                    action: result.metadata.action
                )
            }
        let primaryOpenDimension = actionRows.first

        return HomeDashboardPresentation(
            focusTitle: snapshot.overallHeadline,
            focusSubtitle: primaryOpenDimension?.title ?? focusContext,
            focusDetail: primaryOpenDimension?.subtitle ?? greenDetail(snapshot: snapshot, tripTitle: tripTitle),
            focusContext: focusContext,
            overviewRows: overviewRows,
            actionRows: actionRows
        )
    }

    private static func greenDetail(snapshot: DashboardSnapshot, tripTitle: String?) -> String {
        if let tripTitle {
            return "\(snapshot.vehicleName) ist für \(tripTitle) einsatzbereit."
        }
        return "\(snapshot.vehicleName) ist fahrbereit. Alle Kernbereiche sind im grünen Bereich."
    }
}
