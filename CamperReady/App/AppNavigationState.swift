import Foundation

enum LogbookRoute: Equatable {
    case maintenance
    case documents
    case places
}

enum AppPendingRoute: Equatable {
    case weight
    case checklist(mode: ChecklistMode)
    case logbook(LogbookRoute)
    case costs
    case vehicleProfile
}

enum ReadinessActionKind: Equatable {
    case weight
    case documents
    case maintenance
    case departureChecklist
    case costs
    case places
    case vehicleProfile
}

@MainActor
final class AppNavigationState: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var pendingRoute: AppPendingRoute?

    func navigate(for action: ReadinessActionKind) {
        switch action {
        case .weight:
            selectedTab = .weight
            pendingRoute = .weight
        case .documents:
            selectedTab = .logbook
            pendingRoute = .logbook(.documents)
        case .maintenance:
            selectedTab = .logbook
            pendingRoute = .logbook(.maintenance)
        case .departureChecklist:
            selectedTab = .checklists
            pendingRoute = .checklist(mode: .departure)
        case .costs:
            selectedTab = .costs
            pendingRoute = .costs
        case .places:
            selectedTab = .logbook
            pendingRoute = .logbook(.places)
        case .vehicleProfile:
            selectedTab = .home
            pendingRoute = .vehicleProfile
        }
    }

    func clearPendingRoute() {
        pendingRoute = nil
    }
}
