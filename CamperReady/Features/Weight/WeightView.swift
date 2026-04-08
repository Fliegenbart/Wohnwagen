import SwiftData
import SwiftUI

struct WeightView: View {
    @EnvironmentObject private var activeVehicleStore: ActiveVehicleStore
    @EnvironmentObject private var navigation: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @Query(sort: \PackingItem.name) private var packingItems: [PackingItem]
    @Query(sort: \PassengerLoad.name) private var passengers: [PassengerLoad]
    @Query(sort: \TripLoadSettings.id) private var loadSettings: [TripLoadSettings]
    @State private var packingItemFormContext: PackingItemFormContext?
    @State private var passengerFormContext: PassengerFormContext?
    @State private var loadSettingsFormContext: LoadSettingsFormContext?
    @State private var hasAppeared = false

    var body: some View {
        let vehicle = activeVehicleStore.activeVehicle(in: vehicles)
        let trip = AppDataLocator.activeTrip(for: vehicle, trips: trips)
        let activeSettings = AppDataLocator.loadSettings(for: vehicle, trip: trip, settings: loadSettings)
        let vehicleItems = AppDataLocator.packingItems(for: vehicle, trip: trip, items: packingItems)
        let vehiclePassengers = AppDataLocator.passengers(for: vehicle, trip: trip, passengers: passengers)
        let assessment = AppDataLocator.weightAssessment(
            vehicle: vehicle,
            trip: trip,
            items: packingItems,
            passengers: passengers,
            settings: activeSettings
        )
        let presentation = WeightPresentation.make(assessment: assessment, tripTitle: trip?.title)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                FeatureHeader(
                    eyebrow: "Sicherheitswerte",
                    title: "Beladung",
                    subtitle: "Prüfe Reserve, Wasser und Zusatzlasten vor der Abfahrt."
                )

                if let vehicle {
                    CamperSceneCard(
                        mood: .weight,
                        eyebrow: "Beladung",
                        title: "Gewicht freundlich im Blick.",
                        subtitle: "Alles Wichtige für die Abfahrt liegt auf einen Blick vor dir.",
                        badge: assessment.status.title
                    )

                    analysisPanel(
                        vehicle: vehicle,
                        trip: trip,
                        assessment: assessment,
                        presentation: presentation,
                        settings: activeSettings
                    )

                    weightSection(title: "Beladung", subtitle: "Pflege Wasser, Gas und Zusatzlasten für diese Fahrt.") {
                        if let activeSettings {
                            LoadSettingsSummaryCard(vehicle: vehicle, loadSettings: activeSettings) {
                                loadSettingsFormContext = LoadSettingsFormContext(settings: activeSettings, trip: trip)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Für diese Fahrt ist noch keine Beladung hinterlegt.")
                                    .foregroundStyle(AppTheme.mutedInk)
                                Button("Beladung anlegen") {
                                    loadSettingsFormContext = LoadSettingsFormContext(settings: nil, trip: trip)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }

                    weightSection(title: "Das wiegt am meisten", subtitle: "Die größten Lasten stehen hier zuerst.") {
                        let topContributors = Array(assessment.contributors.prefix(6))
                        if topContributors.isEmpty {
                            Text("Bisher sind noch keine größeren Gewichte erfasst.")
                                .foregroundStyle(AppTheme.mutedInk)
                        } else {
                            ForEach(topContributors) { contributor in
                                WeightContributorRow(
                                    contributor: contributor,
                                    maxWeightKg: topContributors.first?.weightKg ?? contributor.weightKg
                                )
                                if contributor.id != topContributors.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    weightSection(title: "Packliste", subtitle: "Pflege Packstücke und Gewichte für diese Fahrt.") {
                        Button("Packstück hinzufügen") {
                            packingItemFormContext = PackingItemFormContext(item: nil, trip: trip)
                        }
                        .buttonStyle(.borderedProminent)

                        if vehicleItems.isEmpty {
                            Text("Du hast noch keine Packstücke hinterlegt.")
                                .foregroundStyle(AppTheme.mutedInk)
                        } else {
                            ForEach(vehicleItems) { item in
                                Button {
                                    packingItemFormContext = PackingItemFormContext(item: item, trip: trip)
                                } label: {
                                    PackingItemRow(item: item)
                                }
                                .buttonStyle(.plain)

                                if item.id != vehicleItems.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    weightSection(title: "Mitfahrende", subtitle: "Pflege Personen und Gewichte für diese Fahrt.") {
                        Button("Mitfahrende hinzufügen") {
                            passengerFormContext = PassengerFormContext(passenger: nil, trip: trip)
                        }
                        .buttonStyle(.borderedProminent)

                        if vehiclePassengers.isEmpty {
                            Text("Du hast noch keine Mitfahrenden erfasst.")
                                .foregroundStyle(AppTheme.mutedInk)
                        } else {
                            ForEach(vehiclePassengers) { person in
                                Button {
                                    passengerFormContext = PassengerFormContext(passenger: person, trip: trip)
                                } label: {
                                    PassengerRow(person: person)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    weightSection(title: "Hinweise", subtitle: "Hinweise aus den hinterlegten Daten.") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Die Berechnung ist absichtlich vorsichtig. Achslasten bewerten wir nur mit echten Messwerten oder bei klaren Risikomustern.")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.mutedInk)

                            if assessment.warnings.isEmpty {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(AppTheme.green)
                                    Text("Aktuell sind keine zusätzlichen Gewichtsrisiken erkennbar.")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.ink)
                                }
                            } else {
                                ForEach(assessment.warnings, id: \.self) { warning in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(AppTheme.yellow)
                                        Text(warning)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(AppTheme.ink)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppTheme.yellow.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Kein Fahrzeug",
                        systemImage: "scalemass",
                        description: Text("Lege ein Fahrzeug an, damit du Reserve und Beladung prüfen kannst.")
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $packingItemFormContext) { context in
            if let vehicle {
                PackingItemFormView(vehicle: vehicle, trip: context.trip, existingItem: context.item)
            }
        }
        .sheet(item: $passengerFormContext) { context in
            if let vehicle {
                PassengerFormView(vehicle: vehicle, trip: context.trip, existingPassenger: context.passenger)
            }
        }
        .sheet(item: $loadSettingsFormContext) { context in
            if let vehicle {
                LoadSettingsFormView(vehicle: vehicle, trip: context.trip, existingSettings: context.settings)
            }
        }
        .onAppear {
            handlePendingRoute(navigation.pendingRoute)
        }
        .onChange(of: navigation.pendingRoute) { _, route in
            handlePendingRoute(route)
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

    private func analysisPanel(
        vehicle: VehicleProfile,
        trip: Trip?,
        assessment: WeightAssessmentOutput,
        presentation: WeightPresentation,
        settings: TripLoadSettings?
    ) -> some View {
        let compactLayout = UIScreen.main.bounds.width < 402

        return VStack(alignment: .leading, spacing: 12) {
            AlpineSurface(role: .raised) {
                VStack(alignment: .leading, spacing: 18) {
                    LoadDistributionArtwork()

                    Text("Fahrzeugchassis: \(vehicle.vehicleKind.title) \(Int(vehicle.gvwrKg ?? 0)) kg")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.7)
                        .foregroundStyle(AppTheme.mutedInk)
                }
            }

            if compactLayout {
                VStack(spacing: 12) {
                    axleMetricCard(
                        title: "Hinterachse",
                        value: vehicle.rearAxleMeasuredKg.map { "\($0.kgString)" } ?? "Unbekannt",
                        progress: axleProgress(for: vehicle.rearAxleMeasuredKg, baseline: vehicle.gvwrKg)
                    )

                    axleMetricCard(
                        title: "Vorderachse",
                        value: vehicle.frontAxleMeasuredKg.map { "\($0.kgString)" } ?? "Unbekannt",
                        progress: axleProgress(for: vehicle.frontAxleMeasuredKg, baseline: vehicle.gvwrKg)
                    )
                }
            } else {
                HStack(spacing: 12) {
                    axleMetricCard(
                        title: "Hinterachse",
                        value: vehicle.rearAxleMeasuredKg.map { "\($0.kgString)" } ?? "Unbekannt",
                        progress: axleProgress(for: vehicle.rearAxleMeasuredKg, baseline: vehicle.gvwrKg)
                    )

                    axleMetricCard(
                        title: "Vorderachse",
                        value: vehicle.frontAxleMeasuredKg.map { "\($0.kgString)" } ?? "Unbekannt",
                        progress: axleProgress(for: vehicle.frontAxleMeasuredKg, baseline: vehicle.gvwrKg)
                    )
                }
            }

            AlpineSurface(role: .focus) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Gesamtgewicht")
                                .font(.caption.weight(.bold))
                                .textCase(.uppercase)
                                .tracking(0.8)
                                .foregroundStyle(.white.opacity(0.76))

                            Text(presentation.headline)
                                .font(.system(size: 30, weight: .semibold, design: .default))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.84)
                        }

                        Spacer()

                        StatusBadge(status: assessment.status, text: assessment.status.title, surface: .dark)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(weightSummaryValue(for: assessment))
                            .font(.system(size: 42, weight: .semibold, design: .default))
                            .foregroundStyle(.white)
                        Text("kg")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                        Spacer()
                    }

                    Text(weightSupportLine(vehicle: vehicle, trip: trip, assessment: assessment))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
                        metricRow(title: "Reserve", value: assessment.remainingMarginKg.map { $0.kgString } ?? "—")
                        metricRow(title: "Achsrisko", value: axleLabel(for: assessment.axleRisk))
                    }

                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                            .fill(.white.opacity(0.18))
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 999, style: .continuous)
                                    .fill(AppTheme.secondaryFixed)
                                    .frame(width: proxy.size.width * weightProgress(for: assessment, gvwr: vehicle.gvwrKg), height: 10)
                            }
                    }
                    .frame(height: 10)
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 16)
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.70))

            Spacer()

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
        }
    }

    private func axleMetricCard(title: String, value: String, progress: Double) -> some View {
        AlpineSurface(role: .raised) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(AppTheme.mutedInk)
                    Spacer()
                    Image(systemName: "straighten")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.petrol)
                }

                Text(value)
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(AppTheme.surfaceHigh)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                .fill(AppTheme.petrol)
                                .frame(width: proxy.size.width * progress, height: 6)
                        }
                }
                .frame(height: 6)
            }
        }
    }

    private func axleProgress(for value: Double?, baseline: Double?) -> Double {
        guard let value, let baseline, baseline > 0 else { return 0.25 }
        return min(max(value / baseline, 0.1), 1)
    }

    private func weightSummaryValue(for assessment: WeightAssessmentOutput) -> String {
        guard let value = assessment.estimatedGrossWeightKg else { return "—" }
        return "\(Int(value.rounded()))"
    }

    private func axleLabel(for risk: LoadRiskLevel) -> String {
        switch risk {
        case .low:
            return "Niedrig"
        case .elevated:
            return "Erhöht"
        case .measured:
            return "Gemessen"
        }
    }

    private func weightProgress(for assessment: WeightAssessmentOutput, gvwr: Double?) -> Double {
        guard let total = assessment.estimatedGrossWeightKg, let gvwr, gvwr > 0 else {
            return 0.0
        }
        return min(max(total / max(gvwr, 1), 0), 1)
    }

    private func weightSupportLine(vehicle: VehicleProfile, trip: Trip?, assessment: WeightAssessmentOutput) -> String {
        if assessment.status == .green {
            return trip.map { "\(vehicle.name) hat für \($0.title) noch ausreichend Reserve und keine auffälligen Lastmuster." }
                ?? "\(vehicle.name) bleibt aktuell in einem plausiblen Gewichtsfenster."
        }

        if assessment.status == .red {
            return "Die aktuelle Beladung ist für die Abfahrt nicht plausibel. Reduziere Last oder senke Wasserstand, bevor du losfährst."
        }

        return "Die Beladung ist noch nicht eindeutig unkritisch. Prüfe Reserve, Wasserstand und mögliche Achslast-Risiken vor der Abfahrt."
    }

    private func weightSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .tracking(-0.3)
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(AppTheme.mutedInk)
            }
            content()
        }
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 18)
    }

    private func handlePendingRoute(_ route: AppPendingRoute?) {
        guard route == .weight else { return }
        navigation.clearPendingRoute()
    }
}

private struct PackingItemFormContext: Identifiable {
    let id = UUID()
    let item: PackingItem?
    let trip: Trip?
}

private struct PassengerFormContext: Identifiable {
    let id = UUID()
    let passenger: PassengerLoad?
    let trip: Trip?
}

private struct LoadSettingsFormContext: Identifiable {
    let id = UUID()
    let settings: TripLoadSettings?
    let trip: Trip?
}

private struct LoadSettingsSummaryCard: View {
    let vehicle: VehicleProfile
    let loadSettings: TripLoadSettings
    let onEdit: () -> Void

    var body: some View {
        SectionCard(title: "Beladung für diese Reise") {
            VStack(alignment: .leading, spacing: 10) {
                summaryRow("Frischwasser", "\(Int(loadSettings.freshWaterLiters.rounded())) l")
                summaryRow("Grauwasser", "\(Int(loadSettings.greyWaterLiters.rounded())) l")
                summaryRow("Gasflaschen", "\(Int(loadSettings.gasBottleFillPercent.rounded())) %")
                summaryRow("Heckträger", "\(Int(loadSettings.rearCarrierLoadKg.rounded())) kg")
                summaryRow("Dachlast", "\(Int(loadSettings.roofLoadKg.rounded())) kg")
                summaryRow("Zusatzlast", "\(Int(loadSettings.extraLoadKg.rounded())) kg")
                if loadSettings.bikesOnRearCarrier {
                    Text("Fahrräder am Heckträger sind berücksichtigt.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.mutedInk)
                }
                Button("Beladung bearbeiten", action: onEdit)
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.ink)
            Spacer()
            Text(value)
                .foregroundStyle(AppTheme.mutedInk)
        }
        .font(.subheadline.weight(.medium))
    }
}

private struct WeightContributorRow: View {
    let contributor: WeightContributor
    let maxWeightKg: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(contributor.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text(contributor.weightKg.kgString)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.mutedInk)
            }

            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(AppTheme.accent.opacity(0.12))
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                            .fill(AppTheme.accent)
                            .frame(width: max(proxy.size.width * (contributor.weightKg / max(maxWeightKg, 1)), 16))
                    }
            }
            .frame(height: 8)
        }
    }
}

private struct PackingItemRow: View {
    let item: PackingItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .foregroundStyle(AppTheme.ink)
                Text(item.category.title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
            }

            Spacer()

            if item.isPersistent {
                Text("Dauerhaft")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            Text(item.totalWeightKg.kgString)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.mutedInk)
        }
    }
}

private struct PassengerRow: View {
    let person: PassengerLoad

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(person.isDriver ? "Fahrer:in" : "Mitfahrend")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.mutedInk)
            }

            Spacer()

            Text(person.weightKg.kgString)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.mutedInk)
        }
    }
}

private struct PackingItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vehicle: VehicleProfile
    let trip: Trip?
    let existingItem: PackingItem?

    @State private var draft: PackingItemDraftData
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?

    init(vehicle: VehicleProfile, trip: Trip?, existingItem: PackingItem?) {
        self.vehicle = vehicle
        self.trip = trip
        self.existingItem = existingItem
        _draft = State(initialValue: PackingItemDraftData(item: existingItem))
    }

    var body: some View {
        NavigationStack {
            RoadSheetScaffold(
                eyebrow: "Gewicht",
                title: existingItem == nil ? "Packstück hinzufügen" : "Packstück anpassen",
                subtitle: SheetCopy.packingItemSubtitle,
                systemImage: "shippingbox.fill"
            ) {
                Form {
                    Section("Packstück") {
                        TextField("Name", text: $draft.name)
                        Picker("Kategorie", selection: $draft.category) {
                            ForEach(WeightCategory.allCases) { category in
                                Text(category.title).tag(category)
                            }
                        }
                        TextField("Menge", value: $draft.quantity, format: .number)
                            .keyboardType(.numberPad)
                        TextField("Gewicht pro Stück (kg)", value: $draft.unitWeightKg, format: .number)
                            .keyboardType(.decimalPad)
                    }

                    Section("Gültigkeit") {
                        Toggle("Für alle Reisen merken", isOn: $draft.isPersistent)
                        Toggle("Bei dieser Beladung berücksichtigen", isOn: $draft.includeInCurrentLoad)
                    }

                    if existingItem != nil {
                        Section {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Packstück löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle(existingItem == nil ? "Packstück hinzufügen" : "Packstück bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Packstück wirklich löschen?", isPresented: $showDeleteConfirmation) {
                Button("Löschen", role: .destructive) {
                    deleteItem()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Dieses Packstück wird aus deiner Liste entfernt.")
            }
            .alert("Packstück konnte nicht gespeichert werden", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Bitte prüfe deine Eingaben.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingItem == nil ? "Sichern" : "Fertig") {
                        saveItem()
                    }
                    .disabled(!draft.canSave)
                }
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func saveItem() {
        do {
            _ = try WeightEditorService.savePackingItem(
                draft: draft,
                existingItem: existingItem,
                vehicle: vehicle,
                trip: trip,
                context: modelContext
            )
            dismiss()
        } catch {
            errorMessage = "Das Packstück konnte nicht gespeichert werden."
        }
    }

    private func deleteItem() {
        guard let existingItem else { return }
        do {
            try WeightEditorService.deletePackingItem(existingItem, from: vehicle, context: modelContext)
            dismiss()
        } catch {
            errorMessage = "Das Packstück konnte nicht gelöscht werden."
        }
    }
}

private struct PassengerFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vehicle: VehicleProfile
    let trip: Trip?
    let existingPassenger: PassengerLoad?

    @State private var draft: PassengerDraftData
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?

    init(vehicle: VehicleProfile, trip: Trip?, existingPassenger: PassengerLoad?) {
        self.vehicle = vehicle
        self.trip = trip
        self.existingPassenger = existingPassenger
        _draft = State(initialValue: PassengerDraftData(passenger: existingPassenger))
    }

    var body: some View {
        NavigationStack {
            RoadSheetScaffold(
                eyebrow: "Gewicht",
                title: existingPassenger == nil ? "Mitfahrende hinzufügen" : "Mitfahrende anpassen",
                subtitle: SheetCopy.passengerSubtitle,
                systemImage: "person.2.fill"
            ) {
                Form {
                    Section("Mitfahrende Person") {
                        TextField("Name", text: $draft.name)
                        TextField("Gewicht in kg", value: $draft.weightKg, format: .number)
                            .keyboardType(.decimalPad)
                        Toggle("Fahrer:in", isOn: $draft.isDriver)
                        Toggle("Für alle Reisen merken", isOn: $draft.isPersistent)
                    }

                    if existingPassenger != nil {
                        Section {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Mitfahrende Person löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle(existingPassenger == nil ? "Mitfahrende hinzufügen" : "Mitfahrende bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Eintrag wirklich löschen?", isPresented: $showDeleteConfirmation) {
                Button("Löschen", role: .destructive) {
                    deletePassenger()
                }
                Button("Abbrechen", role: .cancel) {}
            }
            .alert("Eintrag konnte nicht gespeichert werden", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Bitte prüfe Name und Gewicht.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingPassenger == nil ? "Sichern" : "Fertig") {
                        savePassenger()
                    }
                    .disabled(!draft.canSave)
                }
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func savePassenger() {
        do {
            _ = try WeightEditorService.savePassenger(
                draft: draft,
                existingPassenger: existingPassenger,
                vehicle: vehicle,
                trip: trip,
                context: modelContext
            )
            dismiss()
        } catch {
            errorMessage = "Die mitfahrende Person konnte nicht gespeichert werden."
        }
    }

    private func deletePassenger() {
        guard let existingPassenger else { return }
        do {
            try WeightEditorService.deletePassenger(existingPassenger, from: vehicle, context: modelContext)
            dismiss()
        } catch {
            errorMessage = "Der Eintrag konnte nicht gelöscht werden."
        }
    }
}

private struct LoadSettingsFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vehicle: VehicleProfile
    let trip: Trip?
    let existingSettings: TripLoadSettings?

    @State private var draft: LoadSettingsDraftData
    @State private var errorMessage: String?

    init(vehicle: VehicleProfile, trip: Trip?, existingSettings: TripLoadSettings?) {
        self.vehicle = vehicle
        self.trip = trip
        self.existingSettings = existingSettings
        _draft = State(initialValue: LoadSettingsDraftData(settings: existingSettings))
    }

    var body: some View {
        NavigationStack {
            RoadSheetScaffold(
                eyebrow: "Gewicht",
                title: "Beladung festlegen",
                subtitle: SheetCopy.loadSettingsSubtitle,
                systemImage: "gauge.with.needle.fill"
            ) {
                Form {
                    Section("Wasser & Gas") {
                        Stepper("Frischwasser: \(Int(draft.freshWaterLiters.rounded())) l", value: $draft.freshWaterLiters, in: 0...(vehicle.freshWaterCapacityL ?? 120), step: 5)
                        Stepper("Grauwasser: \(Int(draft.greyWaterLiters.rounded())) l", value: $draft.greyWaterLiters, in: 0...(vehicle.greyWaterCapacityL ?? 120), step: 5)
                        Stepper("Gasflaschenfüllstand: \(Int(draft.gasBottleFillPercent.rounded())) %", value: $draft.gasBottleFillPercent, in: 0...100, step: 10)
                    }

                    Section("Zusatzlasten") {
                        Stepper("Heckträger: \(Int(draft.rearCarrierLoadKg.rounded())) kg", value: $draft.rearCarrierLoadKg, in: 0...150, step: 2)
                        Stepper("Dachlast: \(Int(draft.roofLoadKg.rounded())) kg", value: $draft.roofLoadKg, in: 0...150, step: 2)
                        Stepper("Zusatzlast: \(Int(draft.extraLoadKg.rounded())) kg", value: $draft.extraLoadKg, in: 0...200, step: 2)
                        Toggle("Fahrräder am Heckträger", isOn: $draft.bikesOnRearCarrier)
                    }

                    Section("Notiz") {
                        TextEditor(text: $draft.notes)
                            .frame(minHeight: 120)
                    }
                }
            }
            .navigationTitle("Beladung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Beladung konnte nicht gespeichert werden", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Bitte versuche es noch einmal.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        saveSettings()
                    }
                }
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func saveSettings() {
        do {
            _ = try WeightEditorService.saveLoadSettings(
                draft: draft,
                existingSettings: existingSettings,
                vehicle: vehicle,
                trip: trip,
                context: modelContext
            )
            dismiss()
        } catch {
            errorMessage = "Die Beladung konnte nicht gespeichert werden."
        }
    }
}

#Preview {
    NavigationStack {
        WeightView()
            .environmentObject(AppNavigationState())
            .environmentObject(ActiveVehicleStore())
    }
    .modelContainer(PreviewStore.container)
}
