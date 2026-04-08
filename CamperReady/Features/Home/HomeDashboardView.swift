import SwiftData
import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject private var activeVehicleStore: ActiveVehicleStore
    @EnvironmentObject private var navigation: AppNavigationState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @Query(sort: \PackingItem.name) private var packingItems: [PackingItem]
    @Query(sort: \PassengerLoad.name) private var passengers: [PassengerLoad]
    @Query(sort: \TripLoadSettings.id) private var loadSettings: [TripLoadSettings]
    @Query(sort: \ChecklistRun.updatedAt, order: .reverse) private var checklists: [ChecklistRun]
    @Query(sort: \ChecklistItemRecord.sortOrder) private var checklistItems: [ChecklistItemRecord]
    @Query(sort: \MaintenanceEntry.date, order: .reverse) private var maintenanceEntries: [MaintenanceEntry]
    @Query(sort: \DocumentRecord.title) private var documents: [DocumentRecord]
    @Query(sort: \CostEntry.date, order: .reverse) private var costs: [CostEntry]

    @State private var hasAppeared = false

    var body: some View {
        let vehicle = activeVehicleStore.activeVehicle(in: vehicles)
        let trip = AppDataLocator.activeTrip(for: vehicle, trips: trips)
        let settings = AppDataLocator.loadSettings(for: vehicle, trip: trip, settings: loadSettings)
        let weight = AppDataLocator.weightAssessment(vehicle: vehicle, trip: trip, items: packingItems, passengers: passengers, settings: settings)
        let vehicleMaintenance = AppDataLocator.maintenance(for: vehicle, entries: maintenanceEntries)
        let vehicleCosts = AppDataLocator.costs(for: vehicle, costs: costs)
        let vehicleChecklists = AppDataLocator.checklists(for: vehicle, checklists: checklists)
        let snapshot = ReadinessEngine.buildDashboard(
            vehicle: vehicle,
            nextTrip: trip,
            weight: weight,
            documents: AppDataLocator.documents(for: vehicle, documents: documents),
            maintenance: vehicleMaintenance,
            checklists: vehicleChecklists,
            checklistItems: checklistItems,
            costs: vehicleCosts,
            currentOdometerKm: AppDataLocator.currentOdometerKm(maintenance: vehicleMaintenance, costs: vehicleCosts)
        )
        let presentation = HomeDashboardPresentation.make(snapshot: snapshot, tripTitle: trip?.title)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let vehicle {
                    FeatureHeader(
                        eyebrow: "Heute im Cockpit",
                        title: homeHeadline(for: snapshot),
                        subtitle: homeSubtitle(vehicle: vehicle, tripTitle: trip?.title, snapshot: snapshot)
                    )

                    VStack(spacing: 14) {
                        primaryActionPanel(presentation.primaryAction)
                        focusPanel(presentation: presentation)
                        readinessOverviewPanel(presentation: presentation)
                    }
                } else {
                    emptyStateHero
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 44)
            .padding(.bottom, 28)
            .opacity(hasAppeared ? 1 : 0.01)
            .offset(y: hasAppeared ? 0 : 12)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            guard !hasAppeared else { return }
            if reduceMotion {
                hasAppeared = true
            } else {
                withAnimation(.easeOut(duration: 0.7)) {
                    hasAppeared = true
                }
            }
        }
    }

    private func homeHeadline(for snapshot: DashboardSnapshot) -> String {
        switch snapshot.overallStatus {
        case .green:
            return "Alles klar — gute Fahrt!"
        case .yellow:
            return "Noch \(snapshot.openItemsCount) offene Punkte."
        case .red:
            return "Noch nicht ganz soweit."
        }
    }

    private func homeSubtitle(vehicle: VehicleProfile, tripTitle: String?, snapshot: DashboardSnapshot) -> String {
        let trip = tripTitle ?? snapshot.nextTripTitle
        return "\(vehicle.name) · \(trip)"
    }

    private func primaryActionPanel(_ action: HomePrimaryAction) -> some View {
        Button {
            navigation.navigate(for: action.action)
        } label: {
            AlpineSurface(role: .focus) {
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: action.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.96))
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(action.title)
                            .font(.system(size: 21, weight: .semibold, design: .default))
                            .foregroundStyle(.white)
                        Text(action.subtitle)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.white.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.forward")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 12)
    }

    @ViewBuilder
    private func focusPanel(presentation: HomeDashboardPresentation) -> some View {
        let content = AlpineSurface(role: .raised) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: presentation.focusSystemImage)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.statusColor(presentation.focusStatus))
                        .frame(width: 36, height: 36)
                        .background(AppTheme.surfaceLow, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(presentation.focusEyebrow)
                            .font(.caption.weight(.bold))
                            .textCase(.uppercase)
                            .tracking(0.8)
                            .foregroundStyle(AppTheme.mutedInk)
                        Text(presentation.focusTitle)
                            .font(.system(size: 25, weight: .semibold, design: .default))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(3)
                            .minimumScaleFactor(0.84)
                    }

                    Spacer()

                    StatusBadge(status: presentation.focusStatus, text: presentation.focusStatus.compactTitle)
                }

                Text(presentation.focusDetail)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)

                if presentation.focusAction != nil {
                    HStack(spacing: 8) {
                        Text("Zum Bereich")
                            .font(.footnote.weight(.bold))
                        Image(systemName: "arrow.up.forward")
                            .font(.footnote.weight(.bold))
                    }
                    .foregroundStyle(AppTheme.statusColor(presentation.focusStatus))
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 14)

        if let action = presentation.focusAction {
            Button {
                navigation.navigate(for: action)
            } label: {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }

    private func readinessOverviewPanel(presentation: HomeDashboardPresentation) -> some View {
        AlpineSurface(role: .section) {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeading(
                    title: "Unterstützende Systeme",
                    subtitle: "Alles Weitere bleibt hier ruhig erreichbar."
                )

                VStack(spacing: 0) {
                    ForEach(Array(presentation.overviewRows.enumerated()), id: \.element.id) { index, row in
                        if let action = row.action {
                            Button {
                                navigation.navigate(for: action)
                            } label: {
                                overviewRow(row, showsArrow: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            overviewRow(row, showsArrow: false)
                        }

                        if index != presentation.overviewRows.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 16)
    }

    private func sectionHeading(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func overviewRow(_ row: HomeOverviewRow, showsArrow: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: row.systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.statusColor(row.status))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(row.summary)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            StatusBadge(status: row.status, text: row.status.compactTitle)

            if showsArrow {
                Image(systemName: "arrow.up.forward")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(AppTheme.statusColor(row.status))
            }
        }
        .padding(.vertical, 10)
    }

    private var emptyStateHero: some View {
        AlpineSurface(role: .section) {
            VStack(alignment: .leading, spacing: 16) {
                StatusBadge(status: .yellow, text: "Einrichten")

                Text("Noch nicht ganz startklar")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text("Leg zuerst deinen Camper an — danach findest du hier vor jeder Fahrt alles Wichtige auf einen Blick.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.mutedInk)

                Button {
                    navigation.navigate(for: .vehicleProfile)
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Zur Garage")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.footnote.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeDashboardView()
            .environmentObject(AppNavigationState())
            .environmentObject(ActiveVehicleStore())
    }
    .modelContainer(PreviewStore.container)
}
