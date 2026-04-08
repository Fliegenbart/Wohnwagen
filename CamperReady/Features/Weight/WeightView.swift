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
        let topContributors = Array(assessment.contributors.prefix(4))

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                FeatureHeader(
                    eyebrow: "Gewicht & Reserve",
                    title: "Beladung",
                    subtitle: "Gesamtgewicht, Reserve und die wichtigsten Lasten für diese Fahrt."
                )

                if let vehicle {
                    analysisPanel(
                        vehicle: vehicle,
                        assessment: assessment,
                        presentation: presentation
                    )

                    weightSection(title: "Beladung", subtitle: "Wasser, Gas und Zusatzlasten für diese Fahrt anpassen.") {
                        VStack(alignment: .leading, spacing: 14) {
                            if let activeSettings {
                                LoadSettingsSummaryCard(loadSettings: activeSettings) {
                                    loadSettingsFormContext = LoadSettingsFormContext(settings: activeSettings, trip: trip)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Für diese Fahrt ist noch keine Beladung eingetragen. Kein Stress — das geht schnell.")
                                        .foregroundStyle(AppTheme.mutedInk)
                                    Button("Beladung eintragen") {
                                        loadSettingsFormContext = LoadSettingsFormContext(settings: nil, trip: trip)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }

                            if !topContributors.isEmpty {
                                Divider()

                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Größte Lasten")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(AppTheme.mutedInk)

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
                        }
                    }

                    weightSection(title: "Packliste", subtitle: "Deine Packstücke und ihr Gewicht für diese Fahrt.") {
                        Button("Neues Packstück") {
                            packingItemFormContext = PackingItemFormContext(item: nil, trip: trip)
                        }
                        .buttonStyle(.borderedProminent)

                        if vehicleItems.isEmpty {
                            Text("Noch keine Packstücke eingetragen.")
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

                    weightSection(title: "Mitfahrende", subtitle: "Wer fährt mit? Personen und Gewicht für diese Fahrt.") {
                        Button("Person hinzufügen") {
                            passengerFormContext = PassengerFormContext(passenger: nil, trip: trip)
                        }
                        .buttonStyle(.borderedProminent)

                        if vehiclePassengers.isEmpty {
                            Text("Noch niemand eingetragen.")
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

                    weightSection(title: "Hinweise", subtitle: "Was uns bei deinen Daten auffällt.") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Wir rechnen absichtlich vorsichtig. Achslasten bewerten wir nur mit echten Messwerten oder bei klaren Auffälligkeiten.")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.mutedInk)

                            if assessment.warnings.isEmpty {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(AppTheme.green)
                                    Text("Aktuell sieht alles unproblematisch aus.")
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
                        "Noch kein Camper",
                        systemImage: "scalemass",
                        description: Text("Leg deinen Camper an — dann kannst du Reserve und Beladung prüfen.")
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
        assessment: WeightAssessmentOutput,
        presentation: WeightPresentation
    ) -> some View {
        let compactSignals = UIScreen.main.bounds.width < 402

        return VStack(alignment: .leading, spacing: 12) {
            AlpineSurface(role: .focus) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Beladungsanalyse")
                                .font(.caption.weight(.bold))
                                .textCase(.uppercase)
                                .tracking(0.8)
                                .foregroundStyle(.white.opacity(0.76))

                            Text(presentation.support)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.82))
                        }

                        Spacer()

                        StatusBadge(status: assessment.status, text: assessment.status.title, surface: .dark)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(weightSummaryValue(for: assessment))
                            .font(.system(size: 46, weight: .semibold, design: .default))
                            .foregroundStyle(.white)
                        Text("kg")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                        Spacer()
                    }

                    Text("Aktuelles Gesamtgewicht")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.80))

                    if compactSignals {
                        VStack(spacing: 10) {
                            weightHeroSignalCard(
                                title: "Reserve",
                                value: presentation.headline,
                                systemImage: "scalemass.fill",
                                accent: .white.opacity(0.92)
                            )
                            weightHeroSignalCard(
                                title: "Achslast",
                                value: presentation.axleRiskLabel,
                                systemImage: "gauge.with.dots.needle.50percent",
                                accent: axleRiskAccent(for: assessment.axleRisk)
                            )
                        }
                    } else {
                        HStack(spacing: 10) {
                            weightHeroSignalCard(
                                title: "Reserve",
                                value: presentation.headline,
                                systemImage: "scalemass.fill",
                                accent: .white.opacity(0.92)
                            )
                            weightHeroSignalCard(
                                title: "Achslast",
                                value: presentation.axleRiskLabel,
                                systemImage: "gauge.with.dots.needle.50percent",
                                accent: axleRiskAccent(for: assessment.axleRisk)
                            )
                        }
                    }

                    Text(presentation.confidenceNote)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)

                    if let nextAction = assessment.nextAction {
                        Text(nextAction)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.70))
                            .fixedSize(horizontal: false, vertical: true)
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

                    HStack(spacing: 12) {
                        Text("zGG \(vehicle.gvwrKg?.kgString ?? "—")")
                        Spacer()
                        Text(vehicle.vehicleKind.title)
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.70))
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 16)
    }

    private func weightHeroSignalCard(title: String, value: String, systemImage: String, accent: Color) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 32, height: 32)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.68))

                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func weightSummaryValue(for assessment: WeightAssessmentOutput) -> String {
        guard let value = assessment.estimatedGrossWeightKg else { return "—" }
        return "\(Int(value.rounded()))"
    }

    private func weightProgress(for assessment: WeightAssessmentOutput, gvwr: Double?) -> Double {
        guard let total = assessment.estimatedGrossWeightKg, let gvwr, gvwr > 0 else {
            return 0.0
        }
        return min(max(total / max(gvwr, 1), 0), 1)
    }

    private func axleRiskAccent(for risk: LoadRiskLevel) -> Color {
        switch risk {
        case .low:
            return .white.opacity(0.92)
        case .elevated:
            return AppTheme.yellow
        case .measured:
            return AppTheme.green
        }
    }

    private func weightSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        SectionCard(title: title, subtitle: subtitle) {
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
    let loadSettings: TripLoadSettings
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            summaryRow("Frischwasser", "\(Int(loadSettings.freshWaterLiters.rounded())) l")
            summaryRow("Grauwasser", "\(Int(loadSettings.greyWaterLiters.rounded())) l")
            summaryRow("Gasflaschen", "\(Int(loadSettings.gasBottleFillPercent.rounded())) %")
            summaryRow("Heckträger", "\(Int(loadSettings.rearCarrierLoadKg.rounded())) kg")
            summaryRow("Dachlast", "\(Int(loadSettings.roofLoadKg.rounded())) kg")
            summaryRow("Zusatzlast", "\(Int(loadSettings.extraLoadKg.rounded())) kg")
            if loadSettings.bikesOnRearCarrier {
                Text("Fahrräder am Heckträger sind mit eingerechnet.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.mutedInk)
            }
            Button("Beladung anpassen", action: onEdit)
                .buttonStyle(.borderedProminent)
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
                Text("Dauerhaft dabei")
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
                title: existingItem == nil ? "Neues Packstück" : "Packstück anpassen",
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
                        TextField("Gewicht pro Stück in kg", value: $draft.unitWeightKg, format: .number)
                            .keyboardType(.decimalPad)
                    }

                    Section("Mitfahrt-Typ") {
                        Toggle("Für alle Reisen merken", isOn: $draft.isPersistent)
                        Toggle("Bei dieser Beladung berücksichtigen", isOn: $draft.includeInCurrentLoad)
                    }

                    if existingItem != nil {
                        Section {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Packstück entfernen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle(existingItem == nil ? "Neues Packstück" : "Packstück bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Packstück wirklich entfernen?", isPresented: $showDeleteConfirmation) {
                Button("Entfernen", role: .destructive) {
                    deleteItem()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Das Packstück verschwindet aus deiner Liste.")
            }
            .alert("Das hat leider nicht geklappt", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Bitte schau nochmal über deine Eingaben.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingItem == nil ? "Speichern" : "Fertig") {
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
            errorMessage = "Das hat leider nicht geklappt."
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
                title: existingPassenger == nil ? "Person hinzufügen" : "Person anpassen",
                subtitle: SheetCopy.passengerSubtitle,
                systemImage: "person.2.fill"
            ) {
                Form {
                    Section("Wer fährt mit?") {
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
                                Label("Person entfernen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle(existingPassenger == nil ? "Person hinzufügen" : "Person anpassen")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Wirklich entfernen?", isPresented: $showDeleteConfirmation) {
                Button("Entfernen", role: .destructive) {
                    deletePassenger()
                }
                Button("Abbrechen", role: .cancel) {}
            }
            .alert("Das hat leider nicht geklappt", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Bitte prüf Name und Gewicht nochmal.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingPassenger == nil ? "Speichern" : "Fertig") {
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
                title: "Beladung für die Fahrt",
                subtitle: SheetCopy.loadSettingsSubtitle,
                systemImage: "gauge.with.needle.fill"
            ) {
                Form {
                    Section("Frischwasser & Gas") {
                        Stepper("Frischwasser: \(Int(draft.freshWaterLiters.rounded())) Liter", value: $draft.freshWaterLiters, in: 0...(vehicle.freshWaterCapacityL ?? 120), step: 5)
                        Stepper("Grauwasser: \(Int(draft.greyWaterLiters.rounded())) Liter", value: $draft.greyWaterLiters, in: 0...(vehicle.greyWaterCapacityL ?? 120), step: 5)
                        Stepper("Gas: ca. \(Int(draft.gasBottleFillPercent.rounded())) % gefüllt", value: $draft.gasBottleFillPercent, in: 0...100, step: 10)
                    }

                    Section("Zusatzlasten") {
                        Stepper("Heckträger: \(Int(draft.rearCarrierLoadKg.rounded())) kg", value: $draft.rearCarrierLoadKg, in: 0...150, step: 2)
                        Stepper("Dachlast: \(Int(draft.roofLoadKg.rounded())) kg", value: $draft.roofLoadKg, in: 0...150, step: 2)
                        Stepper("Sonstiges obendrauf: \(Int(draft.extraLoadKg.rounded())) kg", value: $draft.extraLoadKg, in: 0...200, step: 2)
                        Toggle("Fahrräder am Heckträger", isOn: $draft.bikesOnRearCarrier)
                    }

                    Section("Notiz") {
                        TextEditor(text: $draft.notes)
                            .frame(minHeight: 120)
                    }
                }
            }
            .navigationTitle("Beladung anpassen")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Das hat leider nicht geklappt", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Versuch es nochmal — manchmal klemmt’s kurz.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
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
            errorMessage = "Das hat leider nicht geklappt."
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
