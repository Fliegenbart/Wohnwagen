import SwiftData
import SwiftUI

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]
    @AppStorage("camperready.hasDismissedOnboarding") private var hasDismissedOnboarding = false
    @StateObject private var navigation = AppNavigationState()
    @State private var didBootstrap = false
    @State private var showOnboarding = false

    var body: some View {
        AppCanvas {
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
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        }
        .environmentObject(navigation)
        .task {
            guard !didBootstrap else { return }
            didBootstrap = true
            if AppReleaseConfiguration.shouldSeedSampleDataOnFirstLaunch {
                try? SampleDataSeeder.seedIfNeeded(context: modelContext)
            }
            let documents = (try? modelContext.fetch(FetchDescriptor<DocumentRecord>())) ?? []
            await NotificationManager.shared.rescheduleDocumentRemindersIfAuthorized(documents: documents)
            updateOnboardingPresentation()
        }
        .onChange(of: vehicles.count) { _, _ in
            updateOnboardingPresentation()
        }
        .onChange(of: hasDismissedOnboarding) { _, _ in
            updateOnboardingPresentation()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            FirstRunOnboardingView(
                isPresented: $showOnboarding,
                hasDismissedOnboarding: $hasDismissedOnboarding
            )
        }
    }

    private func updateOnboardingPresentation() {
        showOnboarding = !AppReleaseConfiguration.shouldSeedSampleDataOnFirstLaunch && vehicles.isEmpty && !hasDismissedOnboarding
    }
}

#Preview {
    RootTabView()
        .modelContainer(PreviewStore.container)
}
