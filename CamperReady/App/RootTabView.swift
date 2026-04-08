import SwiftData
import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var activeVehicleStore: ActiveVehicleStore
    @EnvironmentObject private var persistenceStatus: PersistenceStatus
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]
    @Query(sort: \DocumentRecord.title) private var documents: [DocumentRecord]
    @Query(sort: \MaintenanceEntry.date, order: .reverse) private var maintenanceEntries: [MaintenanceEntry]
    @Query(sort: \ChecklistRun.updatedAt, order: .reverse) private var checklists: [ChecklistRun]
    @Query(sort: \ChecklistItemRecord.sortOrder) private var checklistItems: [ChecklistItemRecord]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @Query(sort: \CostEntry.date, order: .reverse) private var costs: [CostEntry]
    @AppStorage("camperready.hasDismissedOnboarding") private var hasDismissedOnboarding = false
    @StateObject private var navigation = AppNavigationState()
    @State private var didBootstrap = false
    @State private var showOnboarding = false

    init() {
    }

    var body: some View {
        let vehicle = activeVehicleStore.activeVehicle(in: vehicles)
        let trip = AppDataLocator.activeTrip(for: vehicle, trips: trips)
        let weight = AppDataLocator.weightAssessment(vehicle: vehicle, trip: trip, items: [], passengers: [], settings: nil)
        let maintenance = AppDataLocator.maintenance(for: vehicle, entries: maintenanceEntries)
        let costsForVehicle = AppDataLocator.costs(for: vehicle, costs: costs)
        let snapshot = ReadinessEngine.buildDashboard(
            vehicle: vehicle,
            nextTrip: trip,
            weight: weight,
            documents: AppDataLocator.documents(for: vehicle, documents: documents),
            maintenance: maintenance,
            checklists: AppDataLocator.checklists(for: vehicle, checklists: checklists),
            checklistItems: checklistItems,
            costs: costsForVehicle,
            currentOdometerKm: AppDataLocator.currentOdometerKm(maintenance: maintenance, costs: costsForVehicle)
        )

        AppCanvas {
            ZStack {
                TabView(selection: $navigation.selectedTab) {
                    NavigationStack {
                        HomeDashboardView()
                    }
                    .tag(AppTab.home)

                    NavigationStack {
                        WeightView()
                    }
                    .tag(AppTab.weight)

                    NavigationStack {
                        ChecklistsView()
                    }
                    .tag(AppTab.checklists)

                    NavigationStack {
                        LogbookView()
                    }
                    .tag(AppTab.logbook)

                    NavigationStack {
                        CostsView()
                    }
                    .tag(AppTab.costs)
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    ZipTopBar(trailing: {
                        topBarTrailing(snapshot: snapshot)
                    }, onMenuTap: {
                        navigation.navigate(for: .vehicleProfile)
                    })

                    if let warningMessage = persistenceStatus.warningMessage {
                        persistenceBanner(message: warningMessage)
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ZipBottomNavigationBar(selectedTab: $navigation.selectedTab, onAddTap: {
                    navigation.navigate(for: .vehicleProfile)
                })
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
        }
        .environmentObject(navigation)
        .task {
            guard !didBootstrap else { return }
            didBootstrap = true
            updatePresentationState()
        }
        .task(id: reminderRefreshKey) {
            guard didBootstrap else { return }
            await NotificationManager.shared.rescheduleAllIfAuthorized(context: modelContext)
        }
        .onChange(of: vehicleIDsToken) { _, _ in
            updatePresentationState()
        }
        .onChange(of: hasDismissedOnboarding) { _, _ in
            updatePresentationState()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            FirstRunOnboardingView(
                isPresented: $showOnboarding,
                hasDismissedOnboarding: $hasDismissedOnboarding
            )
        }
        .sheet(
            isPresented: Binding(
                get: { navigation.pendingRoute == .vehicleProfile },
                set: { presented in
                    if !presented {
                        navigation.clearPendingRoute()
                    }
                }
            )
        ) {
            GarageView()
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { !showOnboarding && activeVehicleStore.needsSelection },
                set: { _ in }
            )
        ) {
            VehicleSelectionView()
        }
    }

    private func updatePresentationState() {
        showOnboarding = vehicles.isEmpty && !hasDismissedOnboarding
        activeVehicleStore.reconcile(with: vehicles)
    }

    @ViewBuilder
    private func topBarTrailing(snapshot: DashboardSnapshot?) -> some View {
        switch navigation.selectedTab {
        case .home:
            if let snapshot {
                StatusBadge(status: snapshot.overallStatus, text: snapshot.overallStatus.title)
            } else {
                ZipStatusPill(title: "Bereit", tint: AppTheme.petrol)
            }
        case .weight:
            ZipAvatarBubble(systemImage: "scalemass")
        case .checklists:
            ZipStatusPill(title: "Checklisten", tint: AppTheme.petrolBright)
        case .logbook:
            ZipAvatarBubble(systemImage: "book.closed.fill")
        case .costs:
            ZipStatusPill(title: "Kosten", tint: AppTheme.green)
        }
    }

    private func persistenceBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.yellow)
            Text(message)
                .font(.footnote.weight(.medium))
                .foregroundStyle(AppTheme.ink)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .padding(.top, 8)
        .background(AppTheme.surface.opacity(0.92))
    }

    private var vehicleIDsToken: String {
        vehicles.map(\.id.uuidString).sorted().joined(separator: ",")
    }

    private var reminderRefreshKey: String {
        let documentToken = documents.map { "\($0.id.uuidString)-\($0.validUntil?.timeIntervalSince1970 ?? 0)" }.joined(separator: ",")
        let maintenanceToken = maintenanceEntries.map { "\($0.id.uuidString)-\($0.nextDueDate?.timeIntervalSince1970 ?? 0)-\($0.nextDueOdometerKm ?? 0)" }.joined(separator: ",")
        let checklistToken = checklists.map { "\($0.id.uuidString)-\($0.updatedAt.timeIntervalSince1970)-\($0.stateRaw)" }.joined(separator: ",")
        let checklistItemToken = checklistItems.map { "\($0.id.uuidString)-\($0.isCompleted)-\($0.sortOrder)" }.joined(separator: ",")
        let tripToken = trips.map { "\($0.id.uuidString)-\($0.startDate.timeIntervalSince1970)-\($0.isActive)" }.joined(separator: ",")
        let costToken = costs.map { "\($0.id.uuidString)-\($0.odometerKm ?? 0)" }.joined(separator: ",")
        return [documentToken, maintenanceToken, checklistToken, checklistItemToken, tripToken, costToken].joined(separator: "|")
    }
}

#Preview {
    RootTabView()
        .environmentObject(PersistenceStatus())
        .environmentObject(ActiveVehicleStore())
        .modelContainer(PreviewStore.container)
}
