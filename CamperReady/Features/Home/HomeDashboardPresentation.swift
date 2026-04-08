import Foundation

struct HomePrimaryAction: Equatable {
    let title: String
    let subtitle: String
    let action: ReadinessActionKind
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
    let focusEyebrow: String
    let focusTitle: String
    let focusDetail: String
    let focusSystemImage: String
    let focusStatus: ReadinessStatus
    let focusAction: ReadinessActionKind?
    let primaryAction: HomePrimaryAction
    let overviewRows: [HomeOverviewRow]

    static func make(snapshot: DashboardSnapshot, tripTitle: String?) -> Self {
        let overviewRows = snapshot.dimensions.map { result in
            HomeOverviewRow(
                title: result.title,
                summary: result.summary,
                systemImage: result.metadata.systemImage,
                status: result.status,
                action: result.metadata.action
            )
        }

        let primaryOpenDimension = snapshot.dimensions
            .filter { $0.status != .green }
            .sorted { lhs, rhs in
                if lhs.status == rhs.status {
                    return lhs.metadata.sortOrder < rhs.metadata.sortOrder
                }
                return lhs.status.rawValue > rhs.status.rawValue
            }
            .first

        if let primaryOpenDimension {
            return HomeDashboardPresentation(
                focusEyebrow: primaryOpenDimension.title,
                focusTitle: primaryOpenDimension.summary,
                focusDetail: primaryOpenDimension.nextAction ?? primaryOpenDimension.reasons.first ?? "Kurz prüfen",
                focusSystemImage: primaryOpenDimension.metadata.systemImage,
                focusStatus: primaryOpenDimension.status,
                focusAction: primaryOpenDimension.metadata.action,
                primaryAction: primaryAction(for: primaryOpenDimension),
                overviewRows: overviewRows
            )
        }

        return HomeDashboardPresentation(
            focusEyebrow: "Alles bestätigt",
            focusTitle: greenDetail(snapshot: snapshot, tripTitle: tripTitle),
            focusDetail: "Alle Bereiche stehen auf Grün.",
            focusSystemImage: "checkmark.circle",
            focusStatus: .green,
            focusAction: nil,
            primaryAction: HomePrimaryAction(
                title: "Vor der Fahrt kurz checken",
                subtitle: "Die Abfahrts-Checkliste bleibt dein letzter ruhiger Kontrollblick.",
                action: .departureChecklist
            ),
            overviewRows: overviewRows,
        )
    }

    private static func primaryAction(for dimension: ReadinessDimensionResult) -> HomePrimaryAction {
        let metadata = dimension.metadata
        return HomePrimaryAction(
            title: primaryActionTitle(for: metadata.action),
            subtitle: dimension.nextAction ?? dimension.summary,
            action: metadata.action ?? .departureChecklist
        )
    }

    private static func primaryActionTitle(for action: ReadinessActionKind?) -> String {
        switch action {
        case .weight:
            return "Gewicht prüfen"
        case .documents:
            return "Dokumente prüfen"
        case .maintenance:
            return "Wartung ansehen"
        case .departureChecklist:
            return "Checkliste öffnen"
        case .costs:
            return "Kosten prüfen"
        case .places:
            return "Orte ansehen"
        case .vehicleProfile:
            return "Garage öffnen"
        case nil:
            return "Jetzt prüfen"
        }
    }

    private static func greenDetail(snapshot: DashboardSnapshot, tripTitle: String?) -> String {
        if let tripTitle {
            return "\(snapshot.vehicleName) ist bereit für \(tripTitle)."
        }
        return "\(snapshot.vehicleName) ist startklar — alles sieht gut aus."
    }
}
