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

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if vehicle == nil {
                    emptyStateHero
                } else {
                    hero(snapshot: snapshot, trip: trip)
                    readinessOverview(snapshot: snapshot)

                    let actionableResults = snapshot.dimensions.filter { $0.status != .green }

                    if !actionableResults.isEmpty {
                        plainSection(title: "Jetzt klären", subtitle: "Diese Punkte solltest du vor der Abfahrt erledigen.") {
                            ForEach(actionableResults) { result in
                                if let action = actionKind(for: result) {
                                    Button {
                                        navigation.navigate(for: action)
                                    } label: {
                                        actionRow(
                                            title: result.summary,
                                            subtitle: result.nextAction ?? result.reasons.first ?? "Jetzt öffnen",
                                            systemImage: actionIcon(for: action),
                                            tint: AppTheme.statusColor(result.status)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    actionRow(
                                        title: result.summary,
                                        subtitle: result.reasons.first ?? "Bitte prüfen",
                                        systemImage: "exclamationmark.triangle.fill",
                                        tint: AppTheme.statusColor(result.status)
                                    )
                                }

                                if result.id != actionableResults.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    plainSection(title: "Schnell weiter", subtitle: "Hier kommst du direkt zu den wichtigsten Aufgaben.") {
                        VStack(alignment: .leading, spacing: 12) {
                            quickAction("Gewicht anpassen", systemImage: "scalemass", action: .weight)
                            quickAction("Dokumente prüfen", systemImage: "doc.text", action: .documents)
                            quickAction("Wartung ansehen", systemImage: "wrench.and.screwdriver", action: .maintenance)
                            quickAction("Kosten ansehen", systemImage: "eurosign.circle", action: .costs)
                            Button {
                                showGarageSheet = true
                            } label: {
                                actionRow(title: "Garage öffnen", subtitle: "Fahrzeug wählen und Stammdaten pflegen", systemImage: "car.circle", tint: AppTheme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
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

    private func hero(snapshot: DashboardSnapshot, trip: Trip?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(snapshot.vehicleName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                    Text("Bereitschaft")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.mutedInk)
                }

                Spacer()

                StatusBadge(status: snapshot.overallStatus, text: snapshot.overallStatus.compactTitle)
            }

            Text(snapshot.overallHeadline)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.82)

            Text(heroSupportLine(snapshot: snapshot, trip: trip))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                navigation.navigate(for: .departureChecklist)
            } label: {
                HStack(spacing: 12) {
                    ctaIcon
                    Text("Vor Abfahrt prüfen")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.footnote.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Vor Abfahrt prüfen")
            .accessibilityHint("Öffnet die Checklisten für die Abfahrt.")

            if let trip {
                Text(trip.title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
        .padding(18)
        .background(AppTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AppTheme.asphalt.opacity(0.04), radius: 10, x: 0, y: 6)
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 16)
        .accessibilityElement(children: .contain)
    }

    // Hintergrund entfallen – Oberfläche ist nun bewusst flach und ruhig

    private func heroMeta(label: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
            Text(label)
                .lineLimit(1)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.white.opacity(0.88))
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func heroSupportLine(snapshot: DashboardSnapshot, trip: Trip?) -> String {
        if snapshot.openItemsCount == 0 {
            return trip.map { "\(snapshot.vehicleName) ist für \($0.title) einsatzbereit." } ?? "\(snapshot.vehicleName) ist fahrbereit. Alle Kernbereiche sind im grünen Bereich."
        }
        return "\(snapshot.vehicleName) hat \(snapshot.openItemsCount) offene Bereiche. Jetzt prüfen, bevor du losfährst."
    }

    private func readinessOverview(snapshot: DashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading(
                title: "Auf einen Blick",
                subtitle: "Hier siehst du sofort, was schon passt und was noch offen ist."
            )

            VStack(spacing: 0) {
                ForEach(Array(snapshot.dimensions.enumerated()), id: \.element.id) { index, result in
                    Group {
                        if let action = actionKind(for: result) {
                            Button {
                                navigation.navigate(for: action)
                            } label: {
                                ReadinessStripRow(result: result, isActionable: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ReadinessStripRow(result: result, isActionable: false)
                        }
                    }
                    .padding(.vertical, 14)
                    .opacity(hasAppeared ? 1 : 0.01)
                    .offset(y: hasAppeared ? 0 : 18)
                    .animation(animation(for: index, baseDelay: 0.18), value: hasAppeared)

                    if index != snapshot.dimensions.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.top, 4)
        }
        .padding(.top, 6)
    }

    private func plainSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading(title: title, subtitle: subtitle)
            content()
        }
        .padding(.top, 8)
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(animation(for: 6, baseDelay: 0.24), value: hasAppeared)
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

    private func quickAction(_ title: String, systemImage: String, action: ReadinessActionKind) -> some View {
        Button {
            navigation.navigate(for: action)
        } label: {
            actionRow(title: title, subtitle: "Direkt öffnen", systemImage: systemImage, tint: AppTheme.accent)
        }
        .buttonStyle(.plain)
    }

    private func actionRow(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.mutedInk)
            }
            Spacer()
            Image(systemName: "arrow.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    private func actionKind(for result: ReadinessDimensionResult) -> ReadinessActionKind? {
        switch result.title {
        case "Gewicht":
            .weight
        case "Gas & Dokumente":
            .documents
        case "Wartung":
            .maintenance
        case "Wasser / Winter":
            .departureChecklist
        case "Kosten":
            .costs
        default:
            nil
        }
    }

    private func actionIcon(for action: ReadinessActionKind) -> String {
        switch action {
        case .weight:
            "scalemass"
        case .documents:
            "doc.text"
        case .maintenance:
            "wrench.and.screwdriver"
        case .departureChecklist:
            "checklist"
        case .costs:
            "eurosign.circle"
        case .places:
            "map"
        case .vehicleProfile:
            "car.circle"
        }
    }

    private func animation(for index: Int, baseDelay: Double) -> Animation? {
        guard !reduceMotion else { return nil }
        return .easeOut(duration: 0.65).delay(baseDelay + Double(index) * 0.05)
    }

    @ViewBuilder
    private var ctaIcon: some View {
        if reduceMotion {
            Image(systemName: "play.circle.fill")
                .font(.headline)
        } else {
            Image(systemName: "play.circle.fill")
                .font(.headline)
                .symbolEffect(.pulse, options: .repeating.speed(0.55))
        }
    }

    private var emptyStateHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CamperReady")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    Text("Los geht's mit deinem Fahrzeug")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.mutedInk)
                }

                Spacer()

                StatusBadge(status: .yellow, text: "Einrichten")
            }

            Text("Noch nicht startklar")
                .font(.system(size: 26, weight: .bold))
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
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(AppTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AppTheme.asphalt.opacity(0.04), radius: 10, x: 0, y: 6)
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

private struct ReadinessStripRow: View {
    let result: ReadinessDimensionResult
    let isActionable: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.statusColor(result.status))
                .frame(width: 8, height: 30)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(result.title)
                        .font(.footnote.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.6)
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Text(result.status.title)
                        .font(.caption2.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(AppTheme.statusColor(result.status))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.statusColor(result.status).opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Text(result.summary)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if let reason = result.reasons.first {
                    Text(reason)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let nextAction = result.nextAction {
                    Text(nextAction)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
            }

            if isActionable {
                Image(systemName: "arrow.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(AppTheme.statusColor(result.status))
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(result.title)
        .accessibilityValue([result.summary, result.reasons.first, result.nextAction]
            .compactMap { $0 }
            .joined(separator: ". "))
    }
}
