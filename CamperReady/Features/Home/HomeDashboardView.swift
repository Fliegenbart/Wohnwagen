import SwiftData
import SwiftUI

struct HomeDashboardView: View {
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

    @State private var showVehicleSheet = false
    @State private var showInfoSheet = false
    @State private var exportFile: ExportFile?
    @State private var hasAppeared = false

    var body: some View {
        let vehicle = AppDataLocator.primaryVehicle(in: vehicles)
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
                                showVehicleSheet = true
                            } label: {
                                actionRow(title: "Fahrzeugprofil bearbeiten", subtitle: "Stammdaten und Kapazitäten pflegen", systemImage: "car.circle", tint: AppTheme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("CamperReady")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showInfoSheet = true
                } label: {
                    Label("Info", systemImage: "info.circle")
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
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showVehicleSheet) {
            VehicleProfileView(vehicle: vehicle)
        }
        .sheet(isPresented: $showInfoSheet) {
            AppInfoView()
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
        ZStack(alignment: .bottomLeading) {
            heroBackground(status: snapshot.overallStatus)

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CamperReady")
                            .font(.system(size: 34, weight: .black, design: .serif))
                            .foregroundStyle(.white)
                        Text("Vor der Fahrt")
                            .font(.caption.weight(.bold))
                            .textCase(.uppercase)
                            .tracking(1.4)
                            .foregroundStyle(.white.opacity(0.76))
                    }

                    Spacer()

                    StatusBadge(status: snapshot.overallStatus, text: snapshot.overallStatus.compactTitle)
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 18)

                VStack(alignment: .leading, spacing: 12) {
                    Text(snapshot.overallHeadline)
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                    Text(heroSupportLine(snapshot: snapshot, trip: trip))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
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
                        .foregroundStyle(AppTheme.ink)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Vor Abfahrt prüfen")
                    .accessibilityHint("Öffnet die Checklisten für die Abfahrt.")

                    HStack(spacing: 14) {
                        heroMeta(label: snapshot.vehicleName, systemImage: "car.side.fill")
                        heroMeta(label: trip?.title ?? "Keine Reise geplant", systemImage: "map")
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity, minHeight: 470, maxHeight: 540, alignment: .bottomLeading)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: AppTheme.asphalt.opacity(0.24), radius: 34, x: 0, y: 20)
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 22)
        .accessibilityElement(children: .contain)
    }

    private func heroBackground(status: ReadinessStatus) -> some View {
        ZStack {
            Rectangle()
                .fill(AppTheme.roadHeroGradient)

            Rectangle()
                .fill(AppTheme.roadFogGradient)

            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.asphalt.opacity(0.92), Color.black.opacity(0.98)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 180)
                    .overlay(alignment: .top) {
                        HStack(spacing: 30) {
                            ForEach(0..<5, id: \.self) { _ in
                                Capsule()
                                    .fill(Color.white.opacity(0.55))
                                    .frame(width: 36, height: 4)
                            }
                        }
                        .offset(y: 20)
                    }
            }

            LinearGradient(
                colors: [Color.clear, AppTheme.statusColor(status).opacity(0.26)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "car.side.fill")
                        .font(.system(size: 170, weight: .black))
                        .foregroundStyle(.white.opacity(0.18))
                        .padding(.trailing, 10)
                        .padding(.bottom, 118)
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 150, height: 150)
                        .blur(radius: 28)
                        .offset(x: 55, y: -30)
                }
                Spacer()
            }
        }
    }

    private func heroMeta(label: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
            Text(label)
                .lineLimit(1)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.white.opacity(0.88))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.58), in: Capsule())
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
        }
    }

    private func plainSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading(title: title, subtitle: subtitle)
            content()
        }
        .padding(.top, 4)
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(animation(for: 6, baseDelay: 0.24), value: hasAppeared)
    }

    private func sectionHeading(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)
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
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
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
                .foregroundStyle(AppTheme.mutedInk)
        }
        .padding(.vertical, 8)
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
        ZStack(alignment: .bottomLeading) {
            heroBackground(status: .yellow)

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CamperReady")
                            .font(.system(size: 34, weight: .black, design: .serif))
                            .foregroundStyle(.white)
                        Text("Los geht's mit deinem Fahrzeug")
                            .font(.caption.weight(.bold))
                            .textCase(.uppercase)
                            .tracking(1.4)
                            .foregroundStyle(.white.opacity(0.76))
                    }

                    Spacer()

                    StatusBadge(status: .yellow, text: "Einrichten")
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 18)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Noch nicht startklar")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Lege zuerst dein Fahrzeug an. Danach siehst du vor jeder Fahrt Gewicht, Fristen und wichtige Checks an einem Ort.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.84))
                }

                Button {
                    showVehicleSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Fahrzeug anlegen")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.footnote.weight(.bold))
                    }
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity, minHeight: 470, maxHeight: 540, alignment: .bottomLeading)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: AppTheme.asphalt.opacity(0.24), radius: 34, x: 0, y: 20)
    }
}

#Preview {
    NavigationStack {
        HomeDashboardView()
            .environmentObject(AppNavigationState())
    }
    .modelContainer(PreviewStore.container)
}

private struct ReadinessStripRow: View {
    let result: ReadinessDimensionResult
    let isActionable: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(AppTheme.statusColor(result.status))
                .frame(width: 11, height: 11)
                .padding(.top, 7)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(result.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Text(result.status.title)
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(AppTheme.statusColor(result.status))
                }

                Text(result.summary)
                    .font(.title3.weight(.bold))
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
                    .foregroundStyle(AppTheme.mutedInk)
                    .padding(.top, 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(result.title)
        .accessibilityValue([result.summary, result.reasons.first, result.nextAction]
            .compactMap { $0 }
            .joined(separator: ". "))
    }
}
