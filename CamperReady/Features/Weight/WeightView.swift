import SwiftData
import SwiftUI

struct WeightView: View {
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
        let vehicle = AppDataLocator.primaryVehicle(in: vehicles)
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

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let vehicle {
                    hero(vehicle: vehicle, trip: trip, assessment: assessment, settings: activeSettings)

                    weightSection(title: "Beladung", subtitle: "Hier pflegst du Wasser, Gas und Zusatzlasten für diese Fahrt.") {
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

                    weightSection(title: "Kurzüberblick", subtitle: "Die wichtigsten Werte für deine Abfahrt.") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            MetricCard(title: "Gesamt", value: assessment.estimatedGrossWeightKg?.kgString ?? "Unklar", systemImage: "truck.box.fill")
                            MetricCard(title: "Reserve", value: assessment.remainingMarginKg?.kgString ?? "Unklar", systemImage: "checkmark.shield.fill")
                            MetricCard(title: "Achslast", value: axleLabel(for: assessment.axleRisk), systemImage: "warninglight.fill")
                            MetricCard(title: "Volles Wasser", value: "+\(Int(assessment.waterComparisonDeltaKg.rounded())) kg", systemImage: "drop.fill")
                        }
                    }

                    weightSection(title: "Das wiegt am meisten", subtitle: "Hier kannst du am schnellsten Gewicht sparen.") {
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

                    weightSection(title: "Packliste", subtitle: "Hier legst du fest, was für diese Fahrt mitkommt.") {
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

                    weightSection(title: "Mitfahrende", subtitle: "Personen zählen beim Gewicht natürlich mit.") {
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

                    weightSection(title: "Worauf du achten solltest", subtitle: "Diese Hinweise helfen dir bei einer sicheren Einschätzung.") {
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
        .navigationTitle("Gewicht")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if vehicle != nil {
                        Button("Packstück hinzufügen") {
                            packingItemFormContext = PackingItemFormContext(item: nil, trip: trip)
                        }
                        Button("Mitfahrende hinzufügen") {
                            passengerFormContext = PassengerFormContext(passenger: nil, trip: trip)
                        }
                        Button("Beladung bearbeiten") {
                            loadSettingsFormContext = LoadSettingsFormContext(settings: activeSettings, trip: trip)
                        }
                    }
                } label: {
                    Label("Mehr", systemImage: "plus.circle")
                }
            }
        }
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

    private func axleLabel(for risk: LoadRiskLevel) -> String {
        switch risk {
        case .low: "Niedrig"
        case .elevated: "Erhöht"
        case .measured: "Gemessen"
        }
    }

    private func hero(
        vehicle: VehicleProfile,
        trip: Trip?,
        assessment: WeightAssessmentOutput,
        settings: TripLoadSettings?
    ) -> some View {
        ZStack(alignment: .bottomLeading) {
            weightHeroBackground(status: assessment.status)

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
                            .foregroundStyle(.white.opacity(0.78))
                    }

                    Spacer()

                    StatusBadge(status: assessment.status, text: assessment.status.title)
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 18)

                VStack(alignment: .leading, spacing: 12) {
                    Text(assessment.summary)
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    Text(weightSupportLine(vehicle: vehicle, trip: trip, assessment: assessment))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.84))
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    heroPill(title: "Reserve", value: assessment.remainingMarginKg?.kgString ?? "Unklar")
                    heroPill(title: "Achslast", value: axleLabel(for: assessment.axleRisk))
                    heroPill(title: "Wasser", value: "\(Int((settings?.freshWaterLiters ?? 0).rounded())) l")
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, minHeight: 450, maxHeight: 520, alignment: .bottomLeading)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: AppTheme.asphalt.opacity(0.24), radius: 34, x: 0, y: 20)
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 22)
    }

    private func heroPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.72))
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func weightHeroBackground(status: ReadinessStatus) -> some View {
        ZStack {
            Rectangle()
                .fill(AppTheme.roadHeroGradient)

            Rectangle()
                .fill(AppTheme.roadFogGradient)

            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.asphalt.opacity(0.92), Color.black.opacity(0.98)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 178)
                    .overlay(alignment: .top) {
                        HStack(spacing: 30) {
                            ForEach(0..<5, id: \.self) { _ in
                                Capsule()
                                    .fill(Color.white.opacity(0.50))
                                    .frame(width: 34, height: 4)
                            }
                        }
                        .offset(y: 20)
                    }
            }

            LinearGradient(
                colors: [Color.clear, AppTheme.statusColor(status).opacity(0.24)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "car.side.fill")
                        .font(.system(size: 162, weight: .black))
                        .foregroundStyle(.white.opacity(0.17))
                        .padding(.trailing, 6)
                        .padding(.bottom, 116)
                }
            }
        }
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
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.subheadline)
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
    }
    .modelContainer(PreviewStore.container)
}
