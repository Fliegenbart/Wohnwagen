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
    @Query(sort: \PlaceNote.dateLastUsed, order: .reverse) private var places: [PlaceNote]
    @Query(sort: \CostEntry.date, order: .reverse) private var costs: [CostEntry]

    @State private var showGarageSheet = false
    @State private var showInfoSheet = false
    @State private var exportFile: ExportFile?
    @State private var hasAppeared = false

    var body: some View {
        let vehicle = activeVehicleStore.activeVehicle(in: vehicles)
        let trip = AppDataLocator.activeTrip(for: vehicle, trips: trips)
        let settings = AppDataLocator.loadSettings(for: vehicle, trip: trip, settings: loadSettings)
        let weight = AppDataLocator.weightAssessment(vehicle: vehicle, trip: trip, items: packingItems, passengers: passengers, settings: settings)
        let vehicleMaintenance = AppDataLocator.maintenance(for: vehicle, entries: maintenanceEntries)
        let vehicleCosts = AppDataLocator.costs(for: vehicle, costs: costs)
        let snapshot = ReadinessEngine.buildDashboard(
            vehicle: vehicle,
            nextTrip: trip,
            weight: weight,
            documents: AppDataLocator.documents(for: vehicle, documents: documents),
            maintenance: vehicleMaintenance,
            checklists: AppDataLocator.checklists(for: vehicle, checklists: checklists),
            checklistItems: checklistItems,
            costs: vehicleCosts,
            currentOdometerKm: AppDataLocator.currentOdometerKm(maintenance: vehicleMaintenance, costs: vehicleCosts)
        )
        let presentation = HomeDashboardPresentation.make(snapshot: snapshot, tripTitle: trip?.title)

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if vehicle == nil {
                    emptyStateHero
                } else {
                    FeatureHeader(
                        eyebrow: snapshot.vehicleName,
                        title: "CamperReady",
                        subtitle: "Dein Fahrzeugstatus vor der Abfahrt."
                    )
                    .opacity(hasAppeared ? 1 : 0.01)
                    .offset(y: hasAppeared ? 0 : 10)

                    focusPanel(snapshot: snapshot, presentation: presentation)
                    readinessOverviewPanel(presentation: presentation)
                    actionPanel(presentation: presentation)
                    quickAccessPanel()
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 40, height: 40)
                        .background(.thinMaterial, in: Circle())
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if vehicle != nil {
                        Button("Dashboard als PDF exportieren") {
                            exportFile = try? ExportService.exportDashboardPDF(snapshot: snapshot)
                        }
                        if let vehicle {
                            Button("Datenarchiv exportieren") {
                                exportFile = try? ExportService.exportVehicleArchive(
                                    vehicle: vehicle,
                                    trips: trips,
                                    packingItems: packingItems,
                                    passengers: passengers,
                                    loadSettings: loadSettings,
                                    checklists: checklists,
                                    checklistItems: checklistItems,
                                    maintenance: maintenanceEntries,
                                    documents: documents,
                                    places: places,
                                    costs: costs
                                )
                            }
                        }
                    }
                    if let exportFile {
                        ShareLink(item: exportFile.url) {
                            Label("Letzte Datei teilen", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 40, height: 40)
                        .background(.thinMaterial, in: Circle())
                }
            }
        }
        .sheet(isPresented: $showGarageSheet) {
            GarageView()
        }
        .sheet(isPresented: $showInfoSheet) {
            AppInfoView()
        }
        .onAppear {
            handlePendingRoute()
        }
        .onChange(of: navigation.pendingRoute) { _, _ in
            handlePendingRoute()
        }
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

    private func focusPanel(snapshot: DashboardSnapshot, presentation: HomeDashboardPresentation) -> some View {
        AlpineSurface(role: .focus) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    StatusBadge(status: snapshot.overallStatus, text: snapshot.overallStatus.title)
                    Spacer()
                    Text(presentation.focusContext)
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.trailing)
                }

                Text(presentation.focusTitle)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)

                Text(presentation.focusSubtitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.94))
                    .fixedSize(horizontal: false, vertical: true)

                Text(presentation.focusDetail)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    navigation.navigate(for: .departureChecklist)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "checklist")
                            .font(.subheadline.weight(.bold))
                        Text("Vor Abfahrt prüfen")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.footnote.weight(.bold))
                    }
                    .foregroundStyle(AppTheme.petrol)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.white, AppTheme.surfaceLow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Vor Abfahrt prüfen")
                .accessibilityHint("Öffnet die Checklisten für die Abfahrt.")
            }
        }
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 14)
    }

    private func actionPanel(presentation: HomeDashboardPresentation) -> some View {
        AlpineSurface(role: .section) {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeading(
                    title: presentation.actionRows.isEmpty ? "Status heute" : "Jetzt klären",
                    subtitle: presentation.actionRows.isEmpty
                        ? "Im Moment gibt es keine offenen Bereitschaftspunkte."
                        : "Die wichtigsten offenen Punkte stehen hier ruhig untereinander."
                )

                VStack(spacing: 0) {
                    if presentation.actionRows.isEmpty {
                        UtilityRow(
                            title: "Alles im grünen Bereich",
                            subtitle: "Du musst vor der Abfahrt aktuell nichts zusätzlich erledigen.",
                            systemImage: "checkmark.circle",
                            tint: AppTheme.green
                        )
                    } else {
                        ForEach(Array(presentation.actionRows.enumerated()), id: \.element.id) { index, row in
                            if let action = row.action {
                                Button {
                                    navigation.navigate(for: action)
                                } label: {
                                    UtilityRow(
                                        title: row.title,
                                        subtitle: row.subtitle,
                                        systemImage: row.systemImage,
                                        tint: AppTheme.statusColor(row.status),
                                        trailingSystemImage: "arrow.up.forward",
                                        trailingTint: AppTheme.statusColor(row.status)
                                    )
                                }
                                .buttonStyle(.plain)
                            } else {
                                UtilityRow(
                                    title: row.title,
                                    subtitle: row.subtitle,
                                    systemImage: row.systemImage,
                                    tint: AppTheme.statusColor(row.status)
                                )
                            }

                            if index != presentation.actionRows.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 18)
    }

    private func readinessOverviewPanel(presentation: HomeDashboardPresentation) -> some View {
        AlpineSurface(role: .section) {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeading(
                    title: "Bereitschaft im Überblick",
                    subtitle: "Alle Bereiche auf einen Blick, auch wenn sie schon im grünen Bereich sind."
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

    private func quickAccessPanel() -> some View {
        AlpineSurface(role: .section) {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeading(
                    title: "Schnellzugriff",
                    subtitle: "Direkt zu den Bereichen, die du vor der Fahrt am häufigsten öffnest."
                )

                VStack(spacing: 0) {
                    quickActionRow("Gewicht anpassen", subtitle: "Packliste und Reserven prüfen", systemImage: "scalemass", action: .weight)
                    Divider()
                    quickActionRow("Dokumente prüfen", subtitle: "Fristen und Nachweise ansehen", systemImage: "doc.text", action: .documents)
                    Divider()
                    quickActionRow("Wartung ansehen", subtitle: "Service und Kilometer im Blick behalten", systemImage: "wrench.and.screwdriver", action: .maintenance)
                    Divider()
                    quickActionRow("Kosten ansehen", subtitle: "Fixkosten und Reisebudget öffnen", systemImage: "eurosign.circle", action: .costs)
                    Divider()
                    Button {
                        showGarageSheet = true
                    } label: {
                        UtilityRow(
                            title: "Garage öffnen",
                            subtitle: "Fahrzeug wählen und Stammdaten pflegen",
                            systemImage: "car.circle",
                            tint: AppTheme.accent,
                            trailingSystemImage: "arrow.up.forward",
                            trailingTint: AppTheme.accent
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 20)
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

    private func quickActionRow(_ title: String, subtitle: String, systemImage: String, action: ReadinessActionKind) -> some View {
        Button {
            navigation.navigate(for: action)
        } label: {
            UtilityRow(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                tint: AppTheme.accent,
                trailingSystemImage: "arrow.up.forward",
                trailingTint: AppTheme.accent
            )
        }
        .buttonStyle(.plain)
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

                Text("Noch nicht startklar")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text("Lege zuerst dein Fahrzeug an. Danach siehst du vor jeder Fahrt Gewicht, Fristen und wichtige Checks an einem Ort.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.mutedInk)

                Button {
                    showGarageSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Garage öffnen")
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

    private func handlePendingRoute() {
        guard navigation.pendingRoute == .vehicleProfile else { return }
        showGarageSheet = true
        navigation.clearPendingRoute()
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
