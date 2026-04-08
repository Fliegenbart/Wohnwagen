import SwiftData
import SwiftUI

struct CostsView: View {
    @EnvironmentObject private var activeVehicleStore: ActiveVehicleStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @Query(sort: \CostEntry.date, order: .reverse) private var costs: [CostEntry]

    @State private var exportFile: ExportFile?
    @State private var tripFormContext: TripFormContext?
    @State private var costFormContext: CostFormContext?
    @State private var hasAppeared = false

    var body: some View {
        let vehicle = activeVehicleStore.activeVehicle(in: vehicles)
        let trip = AppDataLocator.activeTrip(for: vehicle, trips: trips)
        let vehicleTrips = trips
            .filter { $0.vehicleID == vehicle?.id }
            .sorted(by: { $0.startDate > $1.startDate })
        let vehicleCosts = AppDataLocator.costs(for: vehicle, costs: costs)
        let tripCosts = vehicleCosts.filter { $0.tripID == trip?.id && !$0.isRecurringFixedCost }
        let fixedCosts = vehicleCosts.filter(\.isRecurringFixedCost)
        let tripTotal = tripCosts.reduce(0) { $0 + $1.amountEUR }
        let tripNights = max(tripCosts.compactMap(\.nights).reduce(0, +), 1)
        let distance = trip?.plannedDistanceKm ?? 0
        let annualFixed = fixedCosts.reduce(0) { $0 + ReadinessEngine.annualizedAmount(for: $1) }
        let annualVariable = vehicleCosts
            .filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .year) && !$0.isRecurringFixedCost }
            .reduce(0) { $0 + $1.amountEUR }
        let annualTotal = annualFixed + annualVariable
        let presentation = CostsPresentation.make(
            tripTotal: tripTotal,
            perNight: tripTotal / Double(tripNights),
            perHundredKm: distance > 0 ? (tripTotal / distance * 100) : nil,
            annualTotal: annualTotal
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let vehicle {
                    FeatureHeader(
                        eyebrow: vehicle.name,
                        title: "Kosten",
                        subtitle: "Reisekosten und feste Ausgaben für deinen aktiven Camper."
                    )
                    .opacity(hasAppeared ? 1 : 0.01)
                    .offset(y: hasAppeared ? 0 : 10)

                    summaryBlock(
                        stats: presentation.stats,
                        title: "Überblick",
                        subtitle: trip == nil
                            ? "Ohne aktive Reise siehst du hier Fixkosten und noch nicht zugeordnete Ausgaben."
                            : "Die wichtigsten Werte für \(trip?.title ?? "deine Reise") auf einen Blick."
                    )

                    costSection(title: "Aktive Reise", subtitle: trip == nil ? "Leg eine Reise an, damit neue Kosten sauber zugeordnet werden." : "Neue variable Kosten landen automatisch bei der aktiven Reise.") {
                        if let trip {
                            VStack(alignment: .leading, spacing: 12) {
                                Button {
                                    tripFormContext = TripFormContext(trip: trip)
                                } label: {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "map.fill")
                                            .font(.headline)
                                            .foregroundStyle(AppTheme.accent)
                                            .frame(width: 36, height: 36)
                                            .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(trip.title)
                                                .font(.headline.weight(.semibold))
                                                .foregroundStyle(AppTheme.ink)
                                            if !trip.destinationSummary.isEmpty {
                                                Text(trip.destinationSummary)
                                                    .font(.subheadline)
                                                    .foregroundStyle(AppTheme.mutedInk)
                                            }
                                            Text("Seit dem \(trip.startDate.shortDateString())")
                                                .font(.footnote)
                                                .foregroundStyle(AppTheme.mutedInk)
                                        }

                                        Spacer()

                                        Image(systemName: "square.and.pencil")
                                            .font(.footnote.weight(.bold))
                                            .foregroundStyle(AppTheme.mutedInk)
                                    }
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)

                                Button("Neue Reise starten") {
                                    tripFormContext = TripFormContext(trip: nil)
                                }
                                .buttonStyle(.bordered)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Gerade keine Reise aktiv.")
                                    .foregroundStyle(AppTheme.mutedInk)
                                Button("Neue Reise") {
                                    tripFormContext = TripFormContext(trip: nil)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }

                    costSection(
                        title: trip == nil ? "Reisekosten" : "Kosten dieser Reise",
                        subtitle: trip == nil
                            ? "Diese Einträge sind noch keiner aktiven Reise zugeordnet."
                            : "Alle Einträge der aktiven Reise."
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Button(trip == nil ? "Kosten eintragen" : "Kosten für diese Reise eintragen") {
                                costFormContext = CostFormContext(cost: nil)
                            }
                            .buttonStyle(.borderedProminent)

                            if tripCosts.isEmpty {
                                Text(trip == nil ? "Sobald du etwas einträgst, taucht es hier auf." : "Noch keine Kosten für diese Reise.")
                                    .foregroundStyle(AppTheme.mutedInk)
                            } else {
                                ForEach(tripCosts) { cost in
                                    Button {
                                        costFormContext = CostFormContext(cost: cost)
                                    } label: {
                                        CostRow(cost: cost)
                                    }
                                    .buttonStyle(.plain)

                                    if cost.id != tripCosts.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                    costSection(title: "Fixkosten", subtitle: "Versicherung, Stellplatzmiete und andere wiederkehrende Ausgaben.") {
                        VStack(alignment: .leading, spacing: 12) {
                            Button("Laufende Kosten hinzufügen") {
                                costFormContext = CostFormContext(cost: nil, startsAsFixedCost: true)
                            }
                            .buttonStyle(.bordered)

                            if fixedCosts.isEmpty {
                                Text("Noch keine laufenden Kosten hinterlegt.")
                                    .foregroundStyle(AppTheme.mutedInk)
                            } else {
                                ForEach(fixedCosts) { cost in
                                    Button {
                                        costFormContext = CostFormContext(cost: cost)
                                    } label: {
                                        FixedCostRow(cost: cost)
                                    }
                                    .buttonStyle(.plain)

                                    if cost.id != fixedCosts.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Noch kein Camper",
                        systemImage: "eurosign.circle",
                        description: Text("Leg zuerst deinen Camper an — dann behältst du alle Kosten im Blick.")
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if vehicle != nil {
                        Button(trip == nil ? "Neue Reise" : "Reise bearbeiten") {
                            tripFormContext = TripFormContext(trip: trip)
                        }

                        Button("Kosten eintragen") {
                            costFormContext = CostFormContext(cost: nil)
                        }

                        Button("Laufende Kosten hinzufügen") {
                            costFormContext = CostFormContext(cost: nil, startsAsFixedCost: true)
                        }

                        if !vehicleCosts.isEmpty {
                            Divider()
                            Button("Kosten als CSV exportieren") {
                                exportFile = try? ExportService.exportCostsCSV(costs: vehicleCosts)
                            }
                        }
                    }

                    if let exportFile {
                        ShareLink(item: exportFile.url) {
                            Label("Letzte Datei teilen", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Label("Mehr", systemImage: "ellipsis.circle")
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $tripFormContext) { context in
            if let vehicle {
                TripFormView(vehicle: vehicle, existingTrip: context.trip, allTrips: vehicleTrips)
            }
        }
        .sheet(item: $costFormContext) { context in
            if let vehicle {
                CostEntryFormView(vehicle: vehicle, activeTrip: trip, existingCost: context.cost, startsAsFixedCost: context.startsAsFixedCost)
            }
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

    private func costSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedInk)
            }
            AlpineSurface(role: .section) {
                content()
            }
        }
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 18)
    }

    private func summaryBlock(stats: [SummaryStat], title: String, subtitle: String) -> some View {
        AlpineSurface(role: .section) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .tracking(-0.3)
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                    summaryStatRow(stat)

                    if index < stats.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 14)
    }

    @ViewBuilder
    private func summaryStatRow(_ stat: SummaryStat) -> some View {
        if CalmSummaryRowLayout.prefersVertical(for: dynamicTypeSize) {
            summaryStatRowVertical(stat)
        } else {
            ViewThatFits(in: .horizontal) {
                summaryStatRowHorizontal(stat)
                summaryStatRowVertical(stat)
            }
        }
    }

    private func summaryStatRowHorizontal(_ stat: SummaryStat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(stat.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.mutedInk)

            Spacer(minLength: 12)

            Text(stat.value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.trailing)
        }
    }

    private func summaryStatRowVertical(_ stat: SummaryStat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stat.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.mutedInk)
            Text(stat.value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct CostRow: View {
    let cost: CostEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.headline)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 36, height: 36)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(cost.category.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(cost.notes.isEmpty ? cost.date.shortDateString() : cost.notes)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(cost.amountEUR.euroString)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                Image(systemName: "square.and.pencil")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch cost.category {
        case .fuel: "fuelpump.fill"
        case .toll: "road.lanes"
        case .ferry: "ferry.fill"
        case .campsite: "parkingsign.circle.fill"
        case .gas: "flame.fill"
        case .electricity: "bolt.fill"
        case .waterDisposal: "drop.fill"
        case .workshop: "wrench.and.screwdriver.fill"
        case .other: "ellipsis.circle.fill"
        }
    }
}

private struct FixedCostRow: View {
    let cost: CostEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(cost.notes.isEmpty ? cost.category.title : cost.notes)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(recurrenceLabel)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(ReadinessEngine.annualizedAmount(for: cost).euroString)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                Image(systemName: "square.and.pencil")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
        .padding(.vertical, 4)
    }

    private var recurrenceLabel: String {
        switch cost.recurrence {
        case .monthly: "Monatlich"
        case .quarterly: "Vierteljährlich"
        case .yearly: "Jährlich"
        case nil: "Einmalig"
        }
    }
}

private struct TripFormContext: Identifiable {
    let id = UUID()
    let trip: Trip?
}

private struct CostFormContext: Identifiable {
    let id = UUID()
    let cost: CostEntry?
    let startsAsFixedCost: Bool

    init(cost: CostEntry?, startsAsFixedCost: Bool? = nil) {
        self.cost = cost
        self.startsAsFixedCost = startsAsFixedCost ?? cost?.isRecurringFixedCost ?? false
    }
}

private struct TripDraft {
    var title: String
    var startDate: Date
    var hasEndDate: Bool
    var endDate: Date
    var destinationSummary: String
    var hasPlannedDistance: Bool
    var plannedDistanceKm: Double
    var isActive: Bool
    var notes: String

    init(trip: Trip?) {
        title = trip?.title ?? ""
        startDate = trip?.startDate ?? .now
        hasEndDate = trip?.endDate != nil
        endDate = trip?.endDate ?? .now
        destinationSummary = trip?.destinationSummary ?? ""
        hasPlannedDistance = trip?.plannedDistanceKm != nil
        plannedDistanceKm = trip?.plannedDistanceKm ?? 350
        isActive = trip?.isActive ?? true
        notes = trip?.notes ?? ""
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct CostDraft {
    var date: Date
    var category: CostCategory
    var amountEUR: Double
    var notes: String
    var isRecurringFixedCost: Bool
    var recurrence: FixedCostInterval
    var hasOdometer: Bool
    var odometerKm: Double
    var hasNights: Bool
    var nights: Int
    var hasLiters: Bool
    var liters: Double

    init(cost: CostEntry?, startsAsFixedCost: Bool = false) {
        date = cost?.date ?? .now
        category = cost?.category ?? .fuel
        amountEUR = cost?.amountEUR ?? 0
        notes = cost?.notes ?? ""
        isRecurringFixedCost = cost?.isRecurringFixedCost ?? startsAsFixedCost
        recurrence = cost?.recurrence ?? .yearly
        hasOdometer = cost?.odometerKm != nil
        odometerKm = cost?.odometerKm ?? 42000
        hasNights = cost?.nights != nil
        nights = cost?.nights ?? 1
        hasLiters = cost?.liters != nil
        liters = cost?.liters ?? 40
    }

    var canSave: Bool { amountEUR > 0 }
}

private struct TripFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vehicle: VehicleProfile
    let existingTrip: Trip?
    let allTrips: [Trip]

    @State private var draft: TripDraft
    @State private var showDeleteConfirmation = false

    init(vehicle: VehicleProfile, existingTrip: Trip?, allTrips: [Trip]) {
        self.vehicle = vehicle
        self.existingTrip = existingTrip
        self.allTrips = allTrips
        _draft = State(initialValue: TripDraft(trip: existingTrip))
    }

    var body: some View {
        NavigationStack {
            RoadSheetScaffold(
                eyebrow: "Kosten",
                title: existingTrip == nil ? "Neue Reise" : "Reise anpassen",
                subtitle: SheetCopy.tripSubtitle,
                systemImage: "road.lanes"
            ) {
                Form {
                    Section {
                        TextField("z. B. Osterwochenende am Chiemsee", text: $draft.title)
                        TextField("Ziel oder Route", text: $draft.destinationSummary)
                        DatePicker("Start", selection: $draft.startDate, displayedComponents: .date)
                    } header: {
                        Text("Reise")
                    } footer: {
                        Text("Gib der Reise einen Namen, den du später sofort wiedererkennst.")
                    }

                    Section {
                        Toggle("Enddatum eintragen", isOn: $draft.hasEndDate.animation())
                        if draft.hasEndDate {
                            DatePicker("Ende", selection: $draft.endDate, displayedComponents: .date)
                        }

                        Toggle("Geplante Strecke eintragen", isOn: $draft.hasPlannedDistance.animation())
                        if draft.hasPlannedDistance {
                            TextField("Kilometer", value: $draft.plannedDistanceKm, format: .number)
                                .keyboardType(.decimalPad)
                        }

                        Toggle("Als aktive Reise verwenden", isOn: $draft.isActive)
                    } header: {
                        Text("Planung")
                    } footer: {
                        Text("Es kann immer nur eine Reise gleichzeitig aktiv sein. Wenn du diese aktivierst, wird die andere beendet.")
                    }

                    Section("Notizen") {
                        TextEditor(text: $draft.notes)
                            .frame(minHeight: 120)
                    }

                    if existingTrip != nil {
                        Section {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Reise löschen", systemImage: "trash")
                            }
                        } footer: {
                            Text("Bisherige Kosten bleiben erhalten — sie werden nur keiner Reise mehr zugeordnet.")
                        }
                    }
                }
            }
            .navigationTitle(existingTrip == nil ? "Neue Reise starten" : "Reise anpassen")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Reise wirklich entfernen?", isPresented: $showDeleteConfirmation) {
                Button("Entfernen", role: .destructive) {
                    deleteTrip()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Die Reise wird entfernt. Deine Kosten bleiben aber erhalten.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingTrip == nil ? "Speichern" : "Fertig") {
                        saveTrip()
                    }
                    .disabled(!draft.canSave)
                }
            }
        }
    }

    private func saveTrip() {
        guard draft.canSave else { return }

        if draft.isActive {
            for trip in allTrips where trip.id != existingTrip?.id {
                trip.isActive = false
            }
        }

        if let existingTrip {
            existingTrip.title = draft.title
            existingTrip.startDate = draft.startDate
            existingTrip.endDate = draft.hasEndDate ? draft.endDate : nil
            existingTrip.destinationSummary = draft.destinationSummary
            existingTrip.plannedDistanceKm = draft.hasPlannedDistance ? draft.plannedDistanceKm : nil
            existingTrip.isActive = draft.isActive
            existingTrip.notes = draft.notes
        } else {
            let trip = Trip(
                vehicleID: vehicle.id,
                title: draft.title,
                startDate: draft.startDate,
                endDate: draft.hasEndDate ? draft.endDate : nil,
                destinationSummary: draft.destinationSummary,
                plannedDistanceKm: draft.hasPlannedDistance ? draft.plannedDistanceKm : nil,
                isActive: draft.isActive,
                notes: draft.notes
            )
            modelContext.insert(trip)
            vehicle.trips.append(trip)
        }

        vehicle.updatedAt = .now
        try? modelContext.save()
        dismiss()
    }

    private func deleteTrip() {
        guard let existingTrip else { return }

        for cost in vehicle.costs where cost.tripID == existingTrip.id {
            cost.tripID = nil
        }

        vehicle.trips.removeAll { $0.id == existingTrip.id }
        vehicle.updatedAt = .now
        modelContext.delete(existingTrip)
        try? modelContext.save()
        dismiss()
    }
}

private struct CostEntryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vehicle: VehicleProfile
    let activeTrip: Trip?
    let existingCost: CostEntry?
    let startsAsFixedCost: Bool

    @State private var draft: CostDraft
    @State private var showDeleteConfirmation = false

    init(vehicle: VehicleProfile, activeTrip: Trip?, existingCost: CostEntry?, startsAsFixedCost: Bool) {
        self.vehicle = vehicle
        self.activeTrip = activeTrip
        self.existingCost = existingCost
        self.startsAsFixedCost = startsAsFixedCost
        _draft = State(initialValue: CostDraft(cost: existingCost, startsAsFixedCost: startsAsFixedCost))
    }

    var body: some View {
        NavigationStack {
            RoadSheetScaffold(
                eyebrow: "Kosten",
                title: existingCost == nil ? "Kosten eintragen" : "Kosten anpassen",
                subtitle: SheetCopy.costEntrySubtitle,
                systemImage: "eurosign.circle.fill"
            ) {
                Form {
                    Section {
                        DatePicker("Datum", selection: $draft.date, displayedComponents: .date)
                        Picker("Kategorie", selection: $draft.category) {
                            ForEach(CostCategory.allCases) { category in
                                Text(category.title).tag(category)
                            }
                        }
                        TextField("Betrag in €", value: $draft.amountEUR, format: .number)
                            .keyboardType(.decimalPad)
                        TextField("Notiz", text: $draft.notes)
                    } header: {
                        Text("Wofür?")
                    } footer: {
                        Text("Tanken, Maut, Stellplatz, Werkstatt …")
                    }

                    Section {
                        Toggle("Als regelmäßige Kosten speichern", isOn: $draft.isRecurringFixedCost.animation())

                        if draft.isRecurringFixedCost {
                            Picker("Intervall", selection: $draft.recurrence) {
                                Text("Monatlich").tag(FixedCostInterval.monthly)
                                Text("Vierteljährlich").tag(FixedCostInterval.quarterly)
                                Text("Jährlich").tag(FixedCostInterval.yearly)
                            }
                        } else if let activeTrip {
                            LabeledContent("Gehört zu", value: activeTrip.title)
                        } else {
                            Text("Wird ohne Reise gespeichert. Sobald eine Reise aktiv ist, ordnest du neue Kosten direkt zu.")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.mutedInk)
                        }
                    } header: {
                        Text("Zuordnung")
                    }

                    Section("Noch ein paar Details") {
                        Toggle("Kilometerstand speichern", isOn: $draft.hasOdometer.animation())
                        if draft.hasOdometer {
                            TextField("Kilometerstand", value: $draft.odometerKm, format: .number)
                                .keyboardType(.decimalPad)
                        }

                        Toggle("Nächte speichern", isOn: $draft.hasNights.animation())
                        if draft.hasNights {
                            Stepper("Nächte: \(draft.nights)", value: $draft.nights, in: 1...90)
                        }

                        Toggle("Liter speichern", isOn: $draft.hasLiters.animation())
                        if draft.hasLiters {
                            TextField("Liter", value: $draft.liters, format: .number)
                                .keyboardType(.decimalPad)
                        }
                    }

                    if existingCost != nil {
                        Section {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Kosten löschen", systemImage: "trash")
                            }
                        } footer: {
                            Text("Der Eintrag verschwindet aus deiner Übersicht.")
                        }
                    }
                }
            }
            .navigationTitle(existingCost == nil ? "Kosten eintragen" : "Kosten bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Kosten wirklich entfernen?", isPresented: $showDeleteConfirmation) {
                Button("Entfernen", role: .destructive) {
                    deleteCost()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Dieser Eintrag wird dauerhaft entfernt.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingCost == nil ? "Speichern" : "Fertig") {
                        saveCost()
                    }
                    .disabled(!draft.canSave)
                }
            }
        }
    }

    private func saveCost() {
        guard draft.canSave else { return }

        let tripID = draft.isRecurringFixedCost ? nil : (existingCost?.tripID ?? activeTrip?.id)

        if let existingCost {
            existingCost.date = draft.date
            existingCost.category = draft.category
            existingCost.amountEUR = draft.amountEUR
            existingCost.notes = draft.notes
            existingCost.tripID = tripID
            existingCost.isRecurringFixedCost = draft.isRecurringFixedCost
            existingCost.recurrence = draft.isRecurringFixedCost ? draft.recurrence : nil
            existingCost.odometerKm = draft.hasOdometer ? draft.odometerKm : nil
            existingCost.nights = draft.hasNights ? draft.nights : nil
            existingCost.liters = draft.hasLiters ? draft.liters : nil
        } else {
            let cost = CostEntry(
                vehicleID: vehicle.id,
                tripID: tripID,
                date: draft.date,
                category: draft.category,
                amountEUR: draft.amountEUR,
                odometerKm: draft.hasOdometer ? draft.odometerKm : nil,
                nights: draft.hasNights ? draft.nights : nil,
                liters: draft.hasLiters ? draft.liters : nil,
                notes: draft.notes,
                isRecurringFixedCost: draft.isRecurringFixedCost,
                recurrence: draft.isRecurringFixedCost ? draft.recurrence : nil
            )
            modelContext.insert(cost)
            vehicle.costs.append(cost)
        }

        vehicle.updatedAt = .now
        try? modelContext.save()
        dismiss()
    }

    private func deleteCost() {
        guard let existingCost else { return }
        vehicle.costs.removeAll { $0.id == existingCost.id }
        vehicle.updatedAt = .now
        modelContext.delete(existingCost)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        CostsView()
            .environmentObject(ActiveVehicleStore())
    }
    .modelContainer(PreviewStore.container)
}
