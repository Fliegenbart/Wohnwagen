import Foundation

struct HomePrimaryAction: Equatable {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: ReadinessActionKind
}

private struct HomePrimaryActionDescriptor {
    let title: String
    let systemImage: String
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

        let greenConfirmationDimension = snapshot.dimensions
            .sorted { lhs, rhs in
                lhs.metadata.sortOrder < rhs.metadata.sortOrder
            }
            .first
            ?? snapshot.dimensions.first

        return HomeDashboardPresentation(
            focusEyebrow: greenConfirmationDimension?.title ?? "Alles bestätigt",
            focusTitle: greenConfirmationDimension?.summary ?? greenDetail(snapshot: snapshot, tripTitle: tripTitle),
            focusDetail: greenConfirmationDimension?.nextAction ?? "Das ist dein ruhigster Kontrollblick vor der Fahrt.",
            focusSystemImage: greenConfirmationDimension?.metadata.systemImage ?? "checkmark.circle",
            focusStatus: greenConfirmationDimension?.status ?? .green,
            focusAction: greenConfirmationDimension?.metadata.action,
            primaryAction: HomePrimaryAction(
                title: "Vor der Fahrt kurz checken",
                subtitle: "Die Abfahrts-Checkliste bleibt dein letzter ruhiger Kontrollblick.",
                systemImage: "checklist",
                action: .departureChecklist
            ),
            overviewRows: overviewRows,
        )
    }

    static func makePrimaryAction(for action: ReadinessActionKind?, subtitle: String) -> HomePrimaryAction {
        let descriptor = primaryActionDescriptor(for: action)
        return HomePrimaryAction(
            title: descriptor.title,
            subtitle: subtitle,
            systemImage: descriptor.systemImage,
            action: action ?? .departureChecklist
        )
    }

    private static func primaryAction(for dimension: ReadinessDimensionResult) -> HomePrimaryAction {
        let metadata = dimension.metadata
        return makePrimaryAction(
            for: metadata.action,
            subtitle: dimension.nextAction ?? dimension.summary
        )
    }

    private static func primaryActionDescriptor(for action: ReadinessActionKind?) -> HomePrimaryActionDescriptor {
        switch action {
        case .weight:
            return HomePrimaryActionDescriptor(title: "Gewicht prüfen", systemImage: "scalemass")
        case .documents:
            return HomePrimaryActionDescriptor(title: "Dokumente prüfen", systemImage: "doc.text")
        case .maintenance:
            return HomePrimaryActionDescriptor(title: "Wartung ansehen", systemImage: "wrench.and.screwdriver")
        case .departureChecklist:
            return HomePrimaryActionDescriptor(title: "Checkliste öffnen", systemImage: "checklist")
        case .costs:
            return HomePrimaryActionDescriptor(title: "Kosten prüfen", systemImage: "eurosign.circle")
        case .places:
            return HomePrimaryActionDescriptor(title: "Orte ansehen", systemImage: "map")
        case .vehicleProfile:
            return HomePrimaryActionDescriptor(title: "Garage öffnen", systemImage: "car.circle")
        case nil:
            return HomePrimaryActionDescriptor(title: "Jetzt prüfen", systemImage: "checklist")
        }
    }

    private static func greenDetail(snapshot: DashboardSnapshot, tripTitle: String?) -> String {
        if let tripTitle {
            return "\(snapshot.vehicleName) ist bereit für \(tripTitle)."
        }
        return "\(snapshot.vehicleName) ist startklar — alles sieht gut aus."
    }
}
