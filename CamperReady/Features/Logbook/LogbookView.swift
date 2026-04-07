import MapKit
import SwiftData
import SwiftUI

private enum LogbookSection: String, CaseIterable, Identifiable {
    case maintenance
    case documents
    case places

    var id: String { rawValue }

    var title: String {
        switch self {
        case .maintenance: "Wartung"
        case .documents: "Dokumente"
        case .places: "Orte"
        }
    }
}

struct LogbookView: View {
    @EnvironmentObject private var activeVehicleStore: ActiveVehicleStore
    @EnvironmentObject private var navigation: AppNavigationState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]
    @Query(sort: \MaintenanceEntry.date, order: .reverse) private var maintenanceEntries: [MaintenanceEntry]
    @Query(sort: \DocumentRecord.validUntil) private var documents: [DocumentRecord]
    @Query(sort: \PlaceNote.dateLastUsed, order: .reverse) private var placeNotes: [PlaceNote]
    @Query(sort: \CostEntry.date, order: .reverse) private var costs: [CostEntry]

    @State private var selectedSection: LogbookSection = .maintenance
    @State private var exportFile: ExportFile?
    @State private var maintenanceFormContext: MaintenanceFormContext?
    @State private var documentFormContext: DocumentFormContext?
    @State private var placeFormContext: PlaceFormContext?
    @State private var hasAppeared = false

    var body: some View {
        let vehicle = activeVehicleStore.activeVehicle(in: vehicles)
        let vehicleMaintenance = AppDataLocator.maintenance(for: vehicle, entries: maintenanceEntries)
        let vehicleDocuments = AppDataLocator.documents(for: vehicle, documents: documents)
        let vehiclePlaces = AppDataLocator.places(for: vehicle, places: placeNotes)
        let vehicleCosts = AppDataLocator.costs(for: vehicle, costs: costs)
        let currentOdometerKm = AppDataLocator.currentOdometerKm(maintenance: vehicleMaintenance, costs: vehicleCosts)
        let readinessOpenItems = vehicle == nil ? 0 : [
            ReadinessEngine.evaluateLegal(documents: vehicleDocuments).status,
            ReadinessEngine.evaluateMaintenance(entries: vehicleMaintenance, currentOdometerKm: currentOdometerKm).status
        ]
        .filter { $0 != .green }
        .count
        let presentation = LogbookPresentation.make(
            totalDistance: currentOdometerKm ?? 0,
            totalSpend: vehicleMaintenance.compactMap(\.costEUR).reduce(0, +),
            readinessOpenItems: readinessOpenItems
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeatureHeader(
                    eyebrow: "Journey history",
                    title: "Logbuch",
                    subtitle: "Wartung, Dokumente und Orte in einer ruhigen Chronologie."
                )
                .opacity(hasAppeared ? 1 : 0.01)
                .offset(y: hasAppeared ? 0 : 10)

                summaryStats(presentation.stats, emphasisTitle: "Bereitschaft")

                AlpineSurface(role: .section) {
                    Picker("Bereich", selection: $selectedSection) {
                        ForEach(LogbookSection.allCases) { section in
                            Text(section.title).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                switch selectedSection {
                case .maintenance:
                    logbookSection(title: "Wartung", subtitle: "Hier siehst du, was gemacht wurde und was als Nächstes ansteht.") {
                        VStack(alignment: .leading, spacing: 12) {
                            if vehicle != nil {
                                Button("Wartung eintragen") {
                                    maintenanceFormContext = MaintenanceFormContext(entry: nil)
                                }
                                .buttonStyle(.borderedProminent)
                            }

                            if vehicleMaintenance.isEmpty {
                                Text("Du hast noch keine Wartung eingetragen.")
                                    .foregroundStyle(AppTheme.mutedInk)
                            } else {
                                ForEach(vehicleMaintenance) { entry in
                                    Button {
                                        maintenanceFormContext = MaintenanceFormContext(entry: entry)
                                    } label: {
                                        MaintenanceRow(entry: entry)
                                    }
                                    .buttonStyle(.plain)

                                    if entry.id != vehicleMaintenance.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                case .documents:
                    logbookSection(title: "Dokumente & Fristen", subtitle: "Hier behältst du wichtige Nachweise und Termine im Blick.") {
                        VStack(alignment: .leading, spacing: 12) {
                            if vehicle != nil {
                                Button("Dokument hinzufügen") {
                                    documentFormContext = DocumentFormContext(document: nil)
                                }
                                .buttonStyle(.borderedProminent)
                            }

                            Text("Hinweis: Die Fristen sind persönliche Erinnerungen. Bitte prüfe bei Bedarf selbst die aktuellen Regeln.")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.mutedInk)

                            if vehicleDocuments.isEmpty {
                                Text("Du hast noch keine Dokumente oder Fristen erfasst.")
                                    .foregroundStyle(AppTheme.mutedInk)
                            } else {
                                ForEach(vehicleDocuments) { document in
                                    Button {
                                        documentFormContext = DocumentFormContext(document: document)
                                    } label: {
                                        DocumentRow(document: document)
                                    }
                                    .buttonStyle(.plain)

                                    if document.id != vehicleDocuments.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                case .places:
                    logbookSection(title: "Eigene Platznotizen", subtitle: "Hier sammelst du deine eigenen Erfahrungen zu Orten.") {
                        VStack(alignment: .leading, spacing: 12) {
                            if vehicle != nil {
                                Button("Ort hinzufügen") {
                                    placeFormContext = PlaceFormContext(place: nil)
                                }
                                .buttonStyle(.borderedProminent)
                            }

                            if vehiclePlaces.isEmpty {
                                ContentUnavailableView(
                                    "Noch keine Orte gespeichert",
                                    systemImage: "map",
                                    description: Text("Speichere hier deine eigenen Platznotizen und Erfahrungen.")
                                )
                            } else {
                                Map(initialPosition: .region(region(for: vehiclePlaces))) {
                                    ForEach(vehiclePlaces) { place in
                                        Marker(place.title, coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude))
                                    }
                                }
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                                ForEach(vehiclePlaces) { place in
                                    Button {
                                        placeFormContext = PlaceFormContext(place: place)
                                    } label: {
                                        PlaceRow(place: place)
                                    }
                                    .buttonStyle(.plain)

                                    if place.id != vehiclePlaces.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
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
                        switch selectedSection {
                        case .maintenance:
                            Button("Wartung eintragen") {
                                maintenanceFormContext = MaintenanceFormContext(entry: nil)
                            }
                        case .documents:
                            Button("Dokument hinzufügen") {
                                documentFormContext = DocumentFormContext(document: nil)
                            }
                        case .places:
                            Button("Ort hinzufügen") {
                                placeFormContext = PlaceFormContext(place: nil)
                            }
                        }
                    }

                    if selectedSection == .maintenance && !vehicleMaintenance.isEmpty {
                        Divider()
                        Button("Wartung als CSV exportieren") {
                            exportFile = try? ExportService.exportMaintenanceCSV(entries: vehicleMaintenance)
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
        .sheet(item: $maintenanceFormContext) { context in
            if let vehicle {
                MaintenanceEntryFormView(vehicle: vehicle, existingEntry: context.entry)
            }
        }
        .sheet(item: $documentFormContext) { context in
            if let vehicle {
                DocumentRecordFormView(vehicle: vehicle, existingDocument: context.document)
            }
        }
        .sheet(item: $placeFormContext) { context in
            if let vehicle {
                PlaceNoteFormView(vehicle: vehicle, existingPlace: context.place)
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
        .onAppear {
            handlePendingRoute()
        }
        .onChange(of: navigation.pendingRoute) { _, _ in
            handlePendingRoute()
        }
    }

    private func logbookSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
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

    private func summaryStats(_ stats: [SummaryStat], emphasisTitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(stats) { stat in
                AlpineSurface(role: stat.title == emphasisTitle ? .section : .raised) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(stat.title.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.mutedInk)
                        Text(stat.value)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                    }
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 14)
    }

    private func region(for places: [PlaceNote]) -> MKCoordinateRegion {
        guard let first = places.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 47.8, longitude: 10.2),
                span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
            )
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.6, longitudeDelta: 0.6)
        )
    }

    private func handlePendingRoute() {
        guard case let .logbook(route)? = navigation.pendingRoute else { return }
        switch route {
        case .maintenance:
            selectedSection = .maintenance
        case .documents:
            selectedSection = .documents
        case .places:
            selectedSection = .places
        }
        navigation.clearPendingRoute()
    }
}

private struct MaintenanceRow: View {
    let entry: MaintenanceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text(entry.date.shortDateString())
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.mutedInk)
            }

            HStack(spacing: 8) {
                Text(entry.category.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.accent.opacity(0.10), in: Capsule())

                if let cost = entry.costEUR {
                    Text(cost.euroString)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.64), in: Capsule())
                }
            }

            if let dueDate = entry.nextDueDate {
                Label("Nächste Fälligkeit: \(dueDate.shortDateString())", systemImage: "calendar.badge.clock")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.mutedInk)
            }

            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.ink)
            }

            Label("Bearbeiten", systemImage: "square.and.pencil")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedInk)
        }
        .padding(.vertical, 4)
    }
}

private struct DocumentRow: View {
    let document: DocumentRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(document.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                if let validUntil = document.validUntil {
                    Text(validUntil.shortDateString())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(statusColor.opacity(0.12), in: Capsule())
                }
            }

            Text(document.sourceLabel)
                .font(.caption)
                .foregroundStyle(AppTheme.mutedInk)

            if !document.notes.isEmpty {
                Text(document.notes)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.ink)
            }

            Label("Bearbeiten", systemImage: "square.and.pencil")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedInk)
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        guard let validUntil = document.validUntil else { return AppTheme.mutedInk }
        if validUntil < .now {
            return AppTheme.red
        }
        if let thirtyDaysOut = Calendar.current.date(byAdding: .day, value: 30, to: .now), validUntil < thirtyDaysOut {
            return AppTheme.yellow
        }
        return AppTheme.green
    }
}

private struct PlaceRow: View {
    let place: PlaceNote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(place.type.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                Spacer()
                if let rating = place.personalRating {
                    Text("\(rating)/5")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.64), in: Capsule())
                }
            }

            if !place.notes.isEmpty {
                Text(place.notes)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.ink)
            }

            if let lastUsed = place.dateLastUsed {
                Text("Zuletzt genutzt: \(lastUsed.shortDateString())")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
            }

            Label("Bearbeiten", systemImage: "square.and.pencil")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedInk)
        }
        .padding(.vertical, 4)
    }
}

private struct MaintenanceFormContext: Identifiable {
    let id = UUID()
    let entry: MaintenanceEntry?
}

private struct DocumentFormContext: Identifiable {
    let id = UUID()
    let document: DocumentRecord?
}

private struct PlaceFormContext: Identifiable {
    let id = UUID()
    let place: PlaceNote?
}

private struct MaintenanceDraft {
    var date: Date
    var category: MaintenanceCategory
    var title: String
    var hasOdometer: Bool
    var odometerKm: Double
    var hasCost: Bool
    var costEUR: Double
    var notes: String
    var hasNextDueDate: Bool
    var nextDueDate: Date
    var hasNextDueKm: Bool
    var nextDueOdometerKm: Double
    var attachmentPath: String?

    init(entry: MaintenanceEntry?) {
        date = entry?.date ?? .now
        category = entry?.category ?? .inspection
        title = entry?.title ?? ""
        hasOdometer = entry?.odometerKm != nil
        odometerKm = entry?.odometerKm ?? 42000
        hasCost = entry?.costEUR != nil
        costEUR = entry?.costEUR ?? 0
        notes = entry?.notes ?? ""
        hasNextDueDate = entry?.nextDueDate != nil
        nextDueDate = entry?.nextDueDate ?? .now
        hasNextDueKm = entry?.nextDueOdometerKm != nil
        nextDueOdometerKm = entry?.nextDueOdometerKm ?? 50000
        attachmentPath = entry?.attachmentPath
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct DocumentDraft {
    var country: CountryPreset
    var category: DocumentCategory
    var title: String
    var hasValidUntil: Bool
    var validUntil: Date
    var remind90Days: Bool
    var remind30Days: Bool
    var remind7Days: Bool
    var sourceLabel: String
    var notes: String
    var isStatusRelevant: Bool
    var isBlockingWhenExpired: Bool
    var attachmentPath: String?

    init(document: DocumentRecord?) {
        country = document?.country ?? .de
        category = document?.category ?? .registration
        title = document?.title ?? ""
        hasValidUntil = document?.validUntil != nil
        validUntil = document?.validUntil ?? .now
        remind90Days = document?.remind90Days ?? true
        remind30Days = document?.remind30Days ?? true
        remind7Days = document?.remind7Days ?? true
        sourceLabel = document?.sourceLabel ?? ""
        notes = document?.notes ?? ""
        isStatusRelevant = document?.isStatusRelevant ?? true
        isBlockingWhenExpired = document?.isBlockingWhenExpired ?? true
        attachmentPath = document?.attachmentPath
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct PlaceDraft {
    var title: String
    var latitude: Double
    var longitude: Double
    var type: PlaceType
    var personalRating: Int?
    var notes: String
    var costEUR: Double?
    var dateLastUsed: Date?
    var attachmentPath: String?

    init(place: PlaceNote?) {
        title = place?.title ?? ""
        latitude = place?.latitude ?? 47.8
        longitude = place?.longitude ?? 10.2
        type = place?.type ?? .stopover
        personalRating = place?.personalRating
        notes = place?.notes ?? ""
        costEUR = place?.costEUR
        dateLastUsed = place?.dateLastUsed
        attachmentPath = place?.attachmentPath
    }

    var canSave: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty
            && (-90...90).contains(latitude)
            && (-180...180).contains(longitude)
    }

    var normalizedRating: Int? {
        guard let personalRating else { return nil }
        guard personalRating >= 1 else { return nil }
        return min(personalRating, 5)
    }
}

private struct MaintenanceEntryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vehicle: VehicleProfile
    let existingEntry: MaintenanceEntry?
    private let attachmentStore = AttachmentStore()

    @State private var draft: MaintenanceDraft
    @State private var showDeleteConfirmation = false

    init(vehicle: VehicleProfile, existingEntry: MaintenanceEntry?) {
        self.vehicle = vehicle
        self.existingEntry = existingEntry
        _draft = State(initialValue: MaintenanceDraft(entry: existingEntry))
    }

    var body: some View {
        NavigationStack {
            RoadSheetScaffold(
                eyebrow: "Logbuch",
                title: existingEntry == nil ? "Wartung eintragen" : "Wartung anpassen",
                subtitle: "Halte fest, was erledigt wurde und wann der nächste Schritt fällig ist.",
                systemImage: "wrench.adjustable.fill"
            ) {
                Form {
                    Section {
                        DatePicker("Datum", selection: $draft.date, displayedComponents: .date)
                        Picker("Kategorie", selection: $draft.category) {
                            ForEach(MaintenanceCategory.allCases) { category in
                                Text(category.title).tag(category)
                            }
                        }
                        TextField("Titel", text: $draft.title)
                    } header: {
                        Text("Eintrag")
                    }

                    Section("Zusätzliche Angaben") {
                        Toggle("Kilometerstand speichern", isOn: $draft.hasOdometer.animation())
                        if draft.hasOdometer {
                            TextField("Kilometerstand", value: $draft.odometerKm, format: .number)
                                .keyboardType(.decimalPad)
                        }

                        Toggle("Kosten speichern", isOn: $draft.hasCost.animation())
                        if draft.hasCost {
                            TextField("Kosten in EUR", value: $draft.costEUR, format: .number)
                                .keyboardType(.decimalPad)
                        }
                    }

                    Section("Nächste Fälligkeit") {
                        Toggle("Nächstes Datum speichern", isOn: $draft.hasNextDueDate.animation())
                        if draft.hasNextDueDate {
                            DatePicker("Nächstes Datum", selection: $draft.nextDueDate, displayedComponents: .date)
                        }

                        Toggle("Nächsten Kilometerstand speichern", isOn: $draft.hasNextDueKm.animation())
                        if draft.hasNextDueKm {
                            TextField("Nächster Kilometerstand", value: $draft.nextDueOdometerKm, format: .number)
                                .keyboardType(.decimalPad)
                        }
                    }

                    Section("Notizen") {
                        TextEditor(text: $draft.notes)
                            .frame(minHeight: 120)
                    }

                    AttachmentSection(
                        storedPath: $draft.attachmentPath,
                        helperText: "Hier kannst du Fotos oder Belege zu diesem Eintrag lokal auf dem iPhone ablegen."
                    )

                    if existingEntry != nil {
                        Section {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Wartung löschen", systemImage: "trash")
                            }
                        } footer: {
                            Text("Nutze das nur, wenn der Eintrag wirklich weg soll.")
                        }
                    }
                }
            }
            .navigationTitle(existingEntry == nil ? "Wartung eintragen" : "Wartung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Wartung wirklich löschen?", isPresented: $showDeleteConfirmation) {
                Button("Löschen", role: .destructive) {
                    deleteEntry()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Der Eintrag wird aus deinem Logbuch entfernt.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingEntry == nil ? "Sichern" : "Fertig") {
                        saveEntry()
                    }
                    .disabled(!draft.canSave)
                }
            }
        }
    }

    private func saveEntry() {
        guard draft.canSave else { return }

        if let existingEntry {
            existingEntry.date = draft.date
            existingEntry.category = draft.category
            existingEntry.title = draft.title
            existingEntry.odometerKm = draft.hasOdometer ? draft.odometerKm : nil
            existingEntry.costEUR = draft.hasCost ? draft.costEUR : nil
            existingEntry.notes = draft.notes
            existingEntry.nextDueDate = draft.hasNextDueDate ? draft.nextDueDate : nil
            existingEntry.nextDueOdometerKm = draft.hasNextDueKm ? draft.nextDueOdometerKm : nil
            existingEntry.attachmentPath = draft.attachmentPath
        } else {
            let entry = MaintenanceEntry(
                vehicleID: vehicle.id,
                date: draft.date,
                odometerKm: draft.hasOdometer ? draft.odometerKm : nil,
                category: draft.category,
                title: draft.title,
                costEUR: draft.hasCost ? draft.costEUR : nil,
                notes: draft.notes,
                nextDueDate: draft.hasNextDueDate ? draft.nextDueDate : nil,
                nextDueOdometerKm: draft.hasNextDueKm ? draft.nextDueOdometerKm : nil,
                attachmentPath: draft.attachmentPath
            )
            modelContext.insert(entry)
            vehicle.maintenanceEntries.append(entry)
        }

        vehicle.updatedAt = .now
        try? modelContext.save()
        dismiss()
    }

    private func deleteEntry() {
        guard let existingEntry else { return }
        try? attachmentStore.deleteAttachment(at: existingEntry.attachmentPath)
        vehicle.maintenanceEntries.removeAll { $0.id == existingEntry.id }
        vehicle.updatedAt = .now
        modelContext.delete(existingEntry)
        try? modelContext.save()
        dismiss()
    }
}

private struct DocumentRecordFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vehicle: VehicleProfile
    let existingDocument: DocumentRecord?
    private let attachmentStore = AttachmentStore()

    @State private var draft: DocumentDraft
    @State private var showDeleteConfirmation = false

    init(vehicle: VehicleProfile, existingDocument: DocumentRecord?) {
        self.vehicle = vehicle
        self.existingDocument = existingDocument
        _draft = State(initialValue: DocumentDraft(document: existingDocument))
    }

    var body: some View {
        NavigationStack {
            RoadSheetScaffold(
                eyebrow: "Logbuch",
                title: existingDocument == nil ? "Dokument hinzufügen" : "Dokument anpassen",
                subtitle: "Speichere Fristen und Nachweise so, dass du sie vor der Abfahrt schnell wiederfindest.",
                systemImage: "doc.text.fill"
            ) {
                Form {
                    Section {
                        TextField("Titel", text: $draft.title)
                        Picker("Kategorie", selection: $draft.category) {
                            ForEach(DocumentCategory.allCases) { category in
                                Text(category.title).tag(category)
                            }
                        }
                        Picker("Land", selection: $draft.country) {
                            ForEach(CountryPreset.allCases) { country in
                                Text(country.title).tag(country)
                            }
                        }
                    } header: {
                        Text("Dokument")
                    }

                    Section("Frist") {
                        Toggle("Gültig-bis-Datum speichern", isOn: $draft.hasValidUntil.animation())
                        if draft.hasValidUntil {
                            DatePicker("Gültig bis", selection: $draft.validUntil, displayedComponents: .date)
                        }

                        Toggle("Im Status berücksichtigen", isOn: $draft.isStatusRelevant)
                        Toggle("Bei Ablauf als kritisch markieren", isOn: $draft.isBlockingWhenExpired)
                    }

                    Section("Erinnerungen") {
                        Toggle("90 Tage vorher", isOn: $draft.remind90Days)
                        Toggle("30 Tage vorher", isOn: $draft.remind30Days)
                        Toggle("7 Tage vorher", isOn: $draft.remind7Days)
                    }

                    Section("Quelle & Notizen") {
                        TextField("Quelle oder Hinweis", text: $draft.sourceLabel)
                        TextEditor(text: $draft.notes)
                            .frame(minHeight: 120)
                    }

                    AttachmentSection(
                        storedPath: $draft.attachmentPath,
                        helperText: "Hier kannst du einen Nachweis, ein PDF oder ein Foto lokal hinterlegen."
                    )

                    if existingDocument != nil {
                        Section {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Dokument löschen", systemImage: "trash")
                            }
                        } footer: {
                            Text("Die gespeicherte Frist und der Nachweis werden entfernt.")
                        }
                    }
                }
            }
            .navigationTitle(existingDocument == nil ? "Dokument hinzufügen" : "Dokument bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Dokument wirklich löschen?", isPresented: $showDeleteConfirmation) {
                Button("Löschen", role: .destructive) {
                    deleteDocument()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Dieses Dokument verschwindet aus deinem Status und aus den Erinnerungen.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingDocument == nil ? "Sichern" : "Fertig") {
                        saveDocument()
                    }
                    .disabled(!draft.canSave)
                }
            }
        }
    }

    private func saveDocument() {
        guard draft.canSave else { return }

        if let existingDocument {
            existingDocument.country = draft.country
            existingDocument.category = draft.category
            existingDocument.title = draft.title
            existingDocument.validUntil = draft.hasValidUntil ? draft.validUntil : nil
            existingDocument.remind90Days = draft.remind90Days
            existingDocument.remind30Days = draft.remind30Days
            existingDocument.remind7Days = draft.remind7Days
            existingDocument.sourceLabel = draft.sourceLabel
            existingDocument.notes = draft.notes
            existingDocument.isStatusRelevant = draft.isStatusRelevant
            existingDocument.isBlockingWhenExpired = draft.isBlockingWhenExpired
            existingDocument.attachmentPath = draft.attachmentPath
        } else {
            let document = DocumentRecord(
                vehicleID: vehicle.id,
                country: draft.country,
                category: draft.category,
                title: draft.title,
                validUntil: draft.hasValidUntil ? draft.validUntil : nil,
                remind90Days: draft.remind90Days,
                remind30Days: draft.remind30Days,
                remind7Days: draft.remind7Days,
                sourceLabel: draft.sourceLabel,
                notes: draft.notes,
                attachmentPath: draft.attachmentPath,
                isStatusRelevant: draft.isStatusRelevant,
                isBlockingWhenExpired: draft.isBlockingWhenExpired
            )
            modelContext.insert(document)
            vehicle.documents.append(document)
        }

        vehicle.updatedAt = .now
        try? modelContext.save()

        let allDocuments = (try? modelContext.fetch(FetchDescriptor<DocumentRecord>())) ?? []
        Task {
            await NotificationManager.shared.rescheduleDocumentRemindersIfAuthorized(documents: allDocuments)
        }

        dismiss()
    }

    private func deleteDocument() {
        guard let existingDocument else { return }
        try? attachmentStore.deleteAttachment(at: existingDocument.attachmentPath)
        vehicle.documents.removeAll { $0.id == existingDocument.id }
        vehicle.updatedAt = .now
        modelContext.delete(existingDocument)
        try? modelContext.save()

        let allDocuments = (try? modelContext.fetch(FetchDescriptor<DocumentRecord>())) ?? []
        Task {
            await NotificationManager.shared.rescheduleDocumentRemindersIfAuthorized(documents: allDocuments)
        }

        dismiss()
    }
}

private struct PlaceNoteFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vehicle: VehicleProfile
    let existingPlace: PlaceNote?
    private let attachmentStore = AttachmentStore()

    @State private var draft: PlaceDraft
    @State private var showDeleteConfirmation = false

    init(vehicle: VehicleProfile, existingPlace: PlaceNote?) {
        self.vehicle = vehicle
        self.existingPlace = existingPlace
        _draft = State(initialValue: PlaceDraft(place: existingPlace))
    }

    var body: some View {
        NavigationStack {
            RoadSheetScaffold(
                eyebrow: "Logbuch",
                title: existingPlace == nil ? "Ort merken" : "Ort anpassen",
                subtitle: "Speichere gute Stopps, Ver- und Entsorgung oder eigene Hinweise für später.",
                systemImage: "mappin.and.ellipse"
            ) {
                Form {
                    Section {
                        TextField("Name des Ortes", text: $draft.title)
                        Picker("Art", selection: $draft.type) {
                            ForEach(PlaceType.allCases) { type in
                                Text(type.title).tag(type)
                            }
                        }
                    } header: {
                        Text("Ort")
                    } footer: {
                        Text("Zum Beispiel ein Stellplatz, eine Entsorgung oder eine gute Wasserstelle.")
                    }

                    Section("Koordinaten") {
                        TextField("Breitengrad", value: $draft.latitude, format: .number.precision(.fractionLength(4)))
                            .keyboardType(.decimalPad)
                        TextField("Längengrad", value: $draft.longitude, format: .number.precision(.fractionLength(4)))
                            .keyboardType(.decimalPad)
                        Text("Wenn du die Werte aus Karten oder Apple Maps einfügst, reicht das schon.")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.mutedInk)
                    }

                    Section("Eigene Notizen") {
                        TextEditor(text: $draft.notes)
                            .frame(minHeight: 120)
                    }

                    AttachmentSection(
                        storedPath: $draft.attachmentPath,
                        helperText: "Hier kannst du Fotos oder einen Beleg für diesen Ort hinterlegen."
                    )

                    Section("Zusätzliche Angaben") {
                        Toggle("Bewertung speichern", isOn: hasRatingBinding)
                        if draft.personalRating != nil {
                            Stepper("Bewertung: \(draft.normalizedRating ?? 4)/5", value: ratingBinding, in: 1...5)
                        }

                        Toggle("Kosten speichern", isOn: hasCostBinding)
                        if draft.costEUR != nil {
                            TextField("Kosten in EUR", value: costBinding, format: .number)
                                .keyboardType(.decimalPad)
                        }

                        Toggle("Zuletzt genutzt speichern", isOn: hasLastUsedBinding)
                        if draft.dateLastUsed != nil {
                            DatePicker("Zuletzt genutzt", selection: lastUsedBinding, displayedComponents: .date)
                        }
                    }

                    if existingPlace != nil {
                        Section {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Ort löschen", systemImage: "trash")
                            }
                        } footer: {
                            Text("Die Notiz und die Kartenmarkierung werden entfernt.")
                        }
                    }
                }
            }
            .navigationTitle(existingPlace == nil ? "Ort hinzufügen" : "Ort bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Ort wirklich löschen?", isPresented: $showDeleteConfirmation) {
                Button("Löschen", role: .destructive) {
                    deletePlace()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Der Ort verschwindet aus deinem Logbuch und von der Karte.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingPlace == nil ? "Sichern" : "Fertig") {
                        savePlace()
                    }
                    .disabled(!draft.canSave)
                }
            }
        }
    }

    private var hasRatingBinding: Binding<Bool> {
        Binding(
            get: { draft.personalRating != nil },
            set: { newValue in
                draft.personalRating = newValue ? (draft.normalizedRating ?? 4) : nil
            }
        )
    }

    private var ratingBinding: Binding<Int> {
        Binding(
            get: { draft.normalizedRating ?? 4 },
            set: { draft.personalRating = $0 }
        )
    }

    private var hasCostBinding: Binding<Bool> {
        Binding(
            get: { draft.costEUR != nil },
            set: { newValue in
                draft.costEUR = newValue ? max(draft.costEUR ?? 0, 0) : nil
            }
        )
    }

    private var costBinding: Binding<Double> {
        Binding(
            get: { draft.costEUR ?? 0 },
            set: { draft.costEUR = $0 }
        )
    }

    private var hasLastUsedBinding: Binding<Bool> {
        Binding(
            get: { draft.dateLastUsed != nil },
            set: { newValue in
                draft.dateLastUsed = newValue ? (draft.dateLastUsed ?? .now) : nil
            }
        )
    }

    private var lastUsedBinding: Binding<Date> {
        Binding(
            get: { draft.dateLastUsed ?? .now },
            set: { draft.dateLastUsed = $0 }
        )
    }

    private func savePlace() {
        guard draft.canSave else { return }

        if let existingPlace {
            existingPlace.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
            existingPlace.latitude = draft.latitude
            existingPlace.longitude = draft.longitude
            existingPlace.type = draft.type
            existingPlace.personalRating = draft.normalizedRating
            existingPlace.notes = draft.notes
            existingPlace.costEUR = draft.costEUR
            existingPlace.dateLastUsed = draft.dateLastUsed
            existingPlace.attachmentPath = draft.attachmentPath
        } else {
            let place = PlaceNote(
                vehicleID: vehicle.id,
                title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                latitude: draft.latitude,
                longitude: draft.longitude,
                type: draft.type,
                personalRating: draft.normalizedRating,
                notes: draft.notes,
                costEUR: draft.costEUR,
                dateLastUsed: draft.dateLastUsed,
                attachmentPath: draft.attachmentPath
            )
            modelContext.insert(place)
            vehicle.places.append(place)
        }

        vehicle.updatedAt = .now
        try? modelContext.save()
        dismiss()
    }

    private func deletePlace() {
        guard let existingPlace else { return }
        try? attachmentStore.deleteAttachment(at: existingPlace.attachmentPath)
        vehicle.places.removeAll { $0.id == existingPlace.id }
        vehicle.updatedAt = .now
        modelContext.delete(existingPlace)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        LogbookView()
            .environmentObject(AppNavigationState())
            .environmentObject(ActiveVehicleStore())
    }
    .modelContainer(PreviewStore.container)
}
