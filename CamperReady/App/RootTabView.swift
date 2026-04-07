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
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        appearance.backgroundColor = UIColor(AppTheme.surface).withAlphaComponent(0.90)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.accent)]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppTheme.mutedInk).withAlphaComponent(0.72)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.mutedInk).withAlphaComponent(0.72)]
        appearance.shadowColor = UIColor(AppTheme.accent).withAlphaComponent(0.10)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        AppCanvas {
            VStack(spacing: 0) {
                if let warningMessage = persistenceStatus.warningMessage {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.yellow)
                        Text(warningMessage)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(AppTheme.ink)
                        Spacer()
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }

                TabView(selection: $navigation.selectedTab) {
                    NavigationStack {
                        HomeDashboardView()
                    }
                    .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.systemImage) }
                    .tag(AppTab.home)

                    NavigationStack {
                        WeightView()
                    }
                    .tabItem { Label(AppTab.weight.title, systemImage: AppTab.weight.systemImage) }
                    .tag(AppTab.weight)

                    NavigationStack {
                        ChecklistsView()
                    }
                    .tabItem { Label(AppTab.checklists.title, systemImage: AppTab.checklists.systemImage) }
                    .tag(AppTab.checklists)

                    NavigationStack {
                        LogbookView()
                    }
                    .tabItem { Label(AppTab.logbook.title, systemImage: AppTab.logbook.systemImage) }
                    .tag(AppTab.logbook)

                    NavigationStack {
                        CostsView()
                    }
                    .tabItem { Label(AppTab.costs.title, systemImage: AppTab.costs.systemImage) }
                    .tag(AppTab.costs)
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(.thinMaterial, for: .tabBar)
            }
        }
        .environmentObject(navigation)
        .task {
            guard !didBootstrap else { return }
            didBootstrap = true
            if AppReleaseConfiguration.shouldSeedSampleDataOnFirstLaunch {
                try? SampleDataSeeder.seedIfNeeded(context: modelContext)
            }
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
        showOnboarding = !AppReleaseConfiguration.shouldSeedSampleDataOnFirstLaunch && vehicles.isEmpty && !hasDismissedOnboarding
        activeVehicleStore.reconcile(with: vehicles)
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
