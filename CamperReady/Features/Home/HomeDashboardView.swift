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

    private func homeWeightCard(
        vehicle: VehicleProfile,
        trip: Trip?,
        weight: WeightAssessmentOutput,
        settings: TripLoadSettings?
    ) -> some View {
        let marginText = weight.remainingMarginKg.map { value -> String in
            if value >= 0 {
                return "Noch \(Int(value.rounded())) kg Luft"
            }
            return "\(Int(value.rounded())) kg zu viel"
        } ?? "Werte fehlen"
        let grossText = weight.estimatedGrossWeightKg.map { "\(Int($0.rounded()))" } ?? "—"
        let progress = min(max((weight.estimatedGrossWeightKg ?? 0) / max(vehicle.gvwrKg ?? 1, 1), 0), 1)

        return AlpineSurface(role: .raised) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "scalemass")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppTheme.petrol)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.primaryFixed.opacity(0.28), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Text("Gesamtgewicht")
                            .font(.system(size: 22, weight: .medium, design: .default))
                            .foregroundStyle(AppTheme.ink)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Deine Reserve")
                            .font(.caption.weight(.bold))
                            .textCase(.uppercase)
                            .tracking(0.7)
                            .foregroundStyle(AppTheme.mutedInk)
                        Text(marginText)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(weight.remainingMarginKg.map { $0 >= 0 ? AppTheme.green : AppTheme.red } ?? AppTheme.petrol)
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(grossText)
                        .font(.system(size: 42, weight: .semibold, design: .default))
                        .foregroundStyle(AppTheme.petrol)
                    Text("kg")
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundStyle(AppTheme.mutedInk)
                    Spacer()
                }

                Text(weight.summary)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                            .fill(AppTheme.surfaceHigh)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 999, style: .continuous)
                                    .fill(AppTheme.petrol)
                                    .frame(width: proxy.size.width * progress, height: 10)
                            }
                    }
                    .frame(height: 10)

                    HStack {
                        Text("von \(Int((vehicle.gvwrKg ?? 0).rounded())) kg erlaubt")
                        Spacer()
                        Text(weight.nextAction ?? (settings == nil ? "Beladung noch offen" : "Beladung ist erfasst"))
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedInk)
                }
            }
        }
    }

    private func homeMoodCard(vehicle: VehicleProfile, trip: Trip?, snapshot: DashboardSnapshot) -> some View {
        let layout = ScenicCardLayout.metrics(forScreenWidth: UIScreen.main.bounds.width, emphasis: .hero)

        return AlpineSurface(role: .raised) {
            Group {
                if layout.prefersVertical {
                    VStack(alignment: .leading, spacing: 14) {
                        homeMoodText(vehicle: vehicle, trip: trip, snapshot: snapshot, layout: layout)
                        homeMoodArtwork(layout: layout)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                } else {
                    HStack(alignment: .center, spacing: 16) {
                        homeMoodText(vehicle: vehicle, trip: trip, snapshot: snapshot, layout: layout)
                        Spacer(minLength: 0)
                        homeMoodArtwork(layout: layout)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: layout.minimumHeight, alignment: .leading)
        }
    }

    private func homeMoodText(
        vehicle: VehicleProfile,
        trip: Trip?,
        snapshot: DashboardSnapshot,
        layout: ScenicCardLayout
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            StatusBadge(status: snapshot.overallStatus, text: snapshot.overallStatus.title)

            Text(vehicle.name)
                .font(.system(size: layout.titleSize, weight: .semibold, design: .default))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(layout.prefersVertical ? 3 : 2)
                .minimumScaleFactor(0.82)

            Text(trip.map { "Unterwegs: \($0.title)" } ?? "Noch keine Reise aktiv.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            Text(snapshot.openItemsCount == 0 ? "Sieht gut aus — alles im grünen Bereich." : "\(snapshot.openItemsCount) Punkte verdienen noch einen Blick.")
                .font(.footnote.weight(.medium))
                .foregroundStyle(AppTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func homeMoodArtwork(layout: ScenicCardLayout) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.skySoft.opacity(0.74),
                            AppTheme.mintSoft.opacity(0.64),
                            AppTheme.canvasWarm.opacity(0.58)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(AppTheme.sun.opacity(0.26))
                .frame(width: layout.prefersVertical ? 56 : 50, height: layout.prefersVertical ? 56 : 50)
                .offset(x: 40, y: -28)

            Circle()
                .fill(AppTheme.coral.opacity(0.20))
                .frame(width: layout.prefersVertical ? 38 : 34, height: layout.prefersVertical ? 38 : 34)
                .offset(x: -50, y: 34)

            CamperSceneArtwork(mood: .home)
                .frame(width: layout.artworkSize.width, height: layout.artworkSize.height)
                .shadow(color: AppTheme.ink.opacity(0.08), radius: 12, x: 0, y: 8)
                .padding(6)
        }
        .frame(width: layout.containerSize.width, height: layout.containerSize.height)
    }

    private func homeQuickActionCard(title: String, subtitle: String, systemImage: String, tint: Color, action: ReadinessActionKind) -> some View {
        Button {
            navigation.navigate(for: action)
        } label: {
            AlpineSurface(role: .focus) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                            .frame(width: 34, height: 34)
                            .background(tint.opacity(0.20), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.system(size: 22, weight: .semibold, design: .default))
                            .foregroundStyle(.white)
                        Text(subtitle)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.white.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func homeChecklistCard(departureChecklist: ChecklistRun?, requiredCount: Int, completedRequired: Int) -> some View {
        let progress = requiredCount == 0 ? 0 : Double(completedRequired) / Double(requiredCount)
        let state = departureChecklist?.state ?? .notStarted
        let title = ChecklistPresentation.make(
            title: "Vor der Abfahrt",
            state: state,
            completedRequired: completedRequired,
            requiredCount: requiredCount
        )

        return AlpineSurface(role: .raised) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Checkliste")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(AppTheme.mutedInk)
                    Spacer()
                    Text(title.progressText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.petrol)
                }

                HStack(alignment: .center, spacing: 14) {
                    ZipProgressRing(progress: progress, text: "\(Int(progress * 100))%", accent: AppTheme.green, size: 78)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title.title)
                            .font(.system(size: 21, weight: .medium, design: .default))
                            .foregroundStyle(AppTheme.ink)
                        Text(title.stateText)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                    Spacer()
                }

                Button {
                    navigation.navigate(for: .departureChecklist)
                } label: {
                    HStack {
                        Text("Weitermachen")
                            .font(.footnote.weight(.bold))
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.bold))
                    }
                    .foregroundStyle(AppTheme.petrol)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func homeSystemsCard(vehicle: VehicleProfile, trip: Trip?, maintenance: [MaintenanceEntry], settings: TripLoadSettings?, snapshot: DashboardSnapshot) -> some View {
        let compactLayout = ScenicCardLayout.metrics(forScreenWidth: UIScreen.main.bounds.width, emphasis: .support).sizeClass != .regular

        return AlpineSurface(role: .section) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Gut versorgt unterwegs")
                                .font(.caption.weight(.bold))
                                .textCase(.uppercase)
                                .tracking(0.8)
                                .foregroundStyle(AppTheme.mutedInk)
                            Text("Alles ruhig")
                                .font(.system(size: 22, weight: .medium, design: .default))
                                .foregroundStyle(AppTheme.ink)
                        }
                        Spacer()
                        StatusBadge(status: snapshot.overallStatus, text: snapshot.overallStatus.title)
                    }

                    if compactLayout {
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                homeSystemChip(
                                    title: "Gas",
                                    value: gasValue(for: vehicle, settings: settings),
                                    systemImage: "flame.fill",
                                    tint: AppTheme.tertiaryFixed
                                )
                                homeSystemChip(
                                    title: "Frischwasser",
                                    value: waterValue(for: vehicle, trip: trip),
                                    systemImage: "drop.fill",
                                    tint: AppTheme.petrolBright
                                )
                            }

                            homeSystemChip(
                                title: "Wartung",
                                value: maintenanceValue(for: maintenance),
                                systemImage: "wrench.and.screwdriver.fill",
                                tint: AppTheme.green
                            )
                        }
                    } else {
                        HStack(spacing: 10) {
                            homeSystemChip(
                                title: "Gas",
                                value: gasValue(for: vehicle, settings: settings),
                                systemImage: "flame.fill",
                                tint: AppTheme.tertiaryFixed
                            )
                            homeSystemChip(
                                title: "Frischwasser",
                                value: waterValue(for: vehicle, trip: trip),
                                systemImage: "drop.fill",
                                tint: AppTheme.petrolBright
                            )
                            homeSystemChip(
                                title: "Wartung",
                                value: maintenanceValue(for: maintenance),
                                systemImage: "wrench.and.screwdriver.fill",
                                tint: AppTheme.green
                            )
                        }
                    }
                }

                CamperSceneArtwork(mood: .home)
                    .frame(width: compactLayout ? 168 : 210, height: compactLayout ? 108 : 132)
                    .offset(x: compactLayout ? 12 : 26, y: compactLayout ? 16 : 20)
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, minHeight: compactLayout ? 212 : 190, alignment: .leading)
        }
    }

    private func homeSystemChip(title: String, value: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text(value)
                .font(.subheadline.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(AppTheme.onPrimaryFixedVariant)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func gasValue(for vehicle: VehicleProfile, settings: TripLoadSettings?) -> String {
        if let settings, settings.gasBottleFillPercent > 0 {
            return "\(Int(settings.gasBottleFillPercent.rounded())) %"
        }
        guard let count = vehicle.gasBottleCount, count > 0 else {
            return "Noch offen"
        }
        return "\(count) Flaschen"
    }

    private func waterValue(for vehicle: VehicleProfile, trip: Trip?) -> String {
        let liters = vehicle.freshWaterCapacityL ?? 0
        guard liters > 0 else { return "Noch offen" }
        return "\(Int(liters.rounded())) Liter"
    }

    private func maintenanceValue(for entries: [MaintenanceEntry]) -> String {
        if let nextDate = entries.compactMap(\.nextDueDate).sorted().first {
            return nextDate.shortDateString()
        }
        return "\(entries.count) Einträge"
    }

    private func homeUtilityStrip(presentation: HomeDashboardPresentation) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(presentation.overviewRows.prefix(3)) { row in
                    homeUtilityChip(row)
                }
            }
        }
    }

    private func homeUtilityChip(_ row: HomeOverviewRow) -> some View {
        let background: Color = switch row.status {
        case .green: AppTheme.secondaryFixed
        case .yellow: AppTheme.tertiaryFixed
        case .red: AppTheme.redSoft
        }

        let foreground: Color = switch row.status {
        case .green: AppTheme.onSecondaryFixedVariant
        case .yellow: AppTheme.onTertiaryFixedVariant
        case .red: AppTheme.red
        }

        return VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: row.systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(row.title)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(0.7)
            }
            Text(row.summary)
                .font(.footnote.weight(.bold))
                .lineLimit(1)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func primaryActionPanel(_ action: HomePrimaryAction) -> some View {
        Button {
            navigation.navigate(for: action.action)
        } label: {
            AlpineSurface(role: .focus) {
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: primaryActionSystemImage(for: action.action))
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

    private func primaryActionSystemImage(for action: ReadinessActionKind) -> String {
        switch action {
        case .weight:
            return "scalemass"
        case .documents:
            return "doc.text"
        case .maintenance:
            return "wrench.and.screwdriver"
        case .departureChecklist:
            return "checklist"
        case .costs:
            return "eurosign.circle"
        case .places:
            return "map"
        case .vehicleProfile:
            return "car.circle"
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
