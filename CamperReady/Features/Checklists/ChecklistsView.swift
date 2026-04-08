import SwiftData
import SwiftUI

struct ChecklistsView: View {
    @EnvironmentObject private var activeVehicleStore: ActiveVehicleStore
    @EnvironmentObject private var navigation: AppNavigationState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @Query(sort: \ChecklistRun.updatedAt, order: .reverse) private var checklists: [ChecklistRun]
    @Query(sort: \ChecklistItemRecord.sortOrder) private var items: [ChecklistItemRecord]
    @State private var selectedChecklistID: UUID?
    @State private var checklistItemFormContext: ChecklistItemFormContext?
    @State private var checklistToDelete: ChecklistRun?
    @State private var errorMessage: String?
    @State private var hasAppeared = false

    var body: some View {
        let compactActions = UIScreen.main.bounds.width < 402
        let vehicle = activeVehicleStore.activeVehicle(in: vehicles)
        let trip = AppDataLocator.activeTrip(for: vehicle, trips: trips)
        let vehicleChecklists = AppDataLocator.checklists(for: vehicle, checklists: checklists)
        let selectedChecklist = vehicleChecklists.first(where: { $0.id == selectedChecklistID }) ?? vehicleChecklists.first
        let selectedItems = AppDataLocator.checklistItems(for: selectedChecklist, items: items)
        let requiredItems = selectedItems.filter(\.isRequired)
        let completedRequired = requiredItems.filter(\.isCompleted).count
        let nextRequiredItem = requiredItems.first(where: { !$0.isCompleted })
        let progress = requiredItems.isEmpty
            ? ((selectedChecklist?.state == .complete) ? 1 : 0)
            : Double(completedRequired) / Double(requiredItems.count)
        let presentation = ChecklistPresentation.make(
            title: selectedChecklist?.title ?? "Checklisten",
            state: selectedChecklist?.state ?? .notStarted,
            completedRequired: completedRequired,
            requiredCount: requiredItems.count,
            nextRequiredTitle: nextRequiredItem?.title
        )
        let heroStatus = selectedChecklist.map(status(for:)) ?? .yellow

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                FeatureHeader(
                    eyebrow: "Aktiver Ablauf",
                    title: "Checklisten",
                    subtitle: vehicleChecklists.isEmpty
                        ? "Starte einen Modus und arbeite die Punkte ruhig nacheinander ab."
                        : "Wähle einen Modus und hake die offenen Pflichtpunkte nacheinander ab."
                )
                .opacity(hasAppeared ? 1 : 0.01)
                .offset(y: hasAppeared ? 0 : 10)

                if vehicleChecklists.isEmpty {
                    SectionCard(title: "Neue Checkliste starten", subtitle: "Wähl einen Modus. Die passende Liste wird direkt angelegt.") {
                        VStack(alignment: .leading, spacing: 16) {
                            ContentUnavailableView(
                                "Noch keine Checkliste gestartet",
                                systemImage: "checklist",
                                description: Text("Starte zum Beispiel eine Abfahrts- oder Winterschlaf-Checkliste — dann siehst du sofort, was noch offen ist.")
                            )

                            if let vehicle {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                                    ForEach(ChecklistMode.allCases) { mode in
                                        Button {
                                            startChecklist(mode: mode, vehicle: vehicle, trip: trip)
                                        } label: {
                                            Label(mode.title, systemImage: mode.iconName)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                        }
                    }
                    .opacity(hasAppeared ? 1 : 0.01)
                    .offset(y: hasAppeared ? 0 : 16)
                } else {
                    AlpineSurface(role: .focus) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(presentation.title)
                                        .font(.system(size: 28, weight: .semibold, design: .default))
                                        .foregroundStyle(.white)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Text(presentation.progressText)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white.opacity(0.82))
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()

                                StatusBadge(status: heroStatus, text: presentation.stateText, surface: .dark)
                            }

                            ProgressView(value: progress)
                                .progressViewStyle(.linear)
                                .tint(.white.opacity(0.88))

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Nächster Fokus")
                                    .font(.caption.weight(.bold))
                                    .textCase(.uppercase)
                                    .tracking(0.8)
                                    .foregroundStyle(.white.opacity(0.72))

                                Text(presentation.focusText)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            if compactActions {
                                VStack(alignment: .leading, spacing: 10) {
                                    Button("Neuer Punkt") {
                                        guard let selectedChecklist else { return }
                                        checklistItemFormContext = ChecklistItemFormContext(checklist: selectedChecklist, item: nil)
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button(selectedChecklist?.isPinned == true ? "Nicht mehr oben halten" : "Oben halten") {
                                        guard let selectedChecklist else { return }
                                        togglePinned(selectedChecklist)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            } else {
                                HStack(spacing: 12) {
                                    Button("Neuer Punkt") {
                                        guard let selectedChecklist else { return }
                                        checklistItemFormContext = ChecklistItemFormContext(checklist: selectedChecklist, item: nil)
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button(selectedChecklist?.isPinned == true ? "Nicht mehr oben halten" : "Oben halten") {
                                        guard let selectedChecklist else { return }
                                        togglePinned(selectedChecklist)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                    .opacity(hasAppeared ? 1 : 0.01)
                    .offset(y: hasAppeared ? 0 : 16)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Modus")
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(AppTheme.mutedInk)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(vehicleChecklists) { checklist in
                                    Button {
                                        selectedChecklistID = checklist.id
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Text(checklist.title)
                                                if checklist.isPinned {
                                                    Image(systemName: "pin.fill")
                                                        .font(.caption2)
                                                }
                                            }

                                            HStack(spacing: 6) {
                                                Circle()
                                                    .fill(AppTheme.statusColor(status(for: checklist)))
                                                    .frame(width: 6, height: 6)

                                                Text(chipStateText(for: checklist.state))
                                                    .font(.caption2.weight(.semibold))
                                                    .foregroundStyle(AppTheme.mutedInk)
                                            }
                                        }
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(checklist.id == selectedChecklist?.id ? AppTheme.petrol : AppTheme.ink)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            checklist.id == selectedChecklist?.id ? AppTheme.petrol.opacity(0.12) : AppTheme.surfaceLow,
                                            in: Capsule()
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .opacity(hasAppeared ? 1 : 0.01)
                    .offset(y: hasAppeared ? 0 : 16)

                    if let selectedChecklist {
                        SectionCard(
                            title: "Offene Punkte",
                            subtitle: nextRequiredItem == nil ? "Im Moment ist nichts Dringendes offen." : "Arbeite mit dem nächsten offenen Pflichtpunkt weiter."
                        ) {
                            VStack(alignment: .leading, spacing: 14) {
                                if selectedItems.isEmpty {
                                    Text("Diese Liste ist noch leer — füg einfach Punkte hinzu.")
                                        .foregroundStyle(AppTheme.mutedInk)
                                } else {
                                    ForEach(Array(selectedItems.enumerated()), id: \.element.id) { index, item in
                                        ChecklistItemRow(
                                            item: item,
                                            onToggle: {
                                                refreshState(for: selectedChecklist)
                                            },
                                            onEdit: {
                                                checklistItemFormContext = ChecklistItemFormContext(checklist: selectedChecklist, item: item)
                                            },
                                            onMoveUp: {
                                                moveItem(item, in: selectedChecklist, direction: -1)
                                            },
                                            onMoveDown: {
                                                moveItem(item, in: selectedChecklist, direction: 1)
                                            },
                                            onDelete: {
                                                deleteItem(item, from: selectedChecklist)
                                            },
                                            canMoveUp: index > 0,
                                            canMoveDown: index < selectedItems.count - 1
                                        )
                                    }
                                }
                            }
                        }
                        .opacity(hasAppeared ? 1 : 0.01)
                        .offset(y: hasAppeared ? 0 : 18)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("Checklisten")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if let vehicle {
                        ForEach(ChecklistMode.allCases) { mode in
                            Button(mode.title) {
                                startChecklist(mode: mode, vehicle: vehicle, trip: trip)
                            }
                        }
                    }

                    if let selectedChecklist {
                        Divider()

                        Button(selectedChecklist.isPinned ? "Nicht mehr oben halten" : "Anheften") {
                            togglePinned(selectedChecklist)
                        }

                        Button("Alle Pflichtpunkte abhaken") {
                            markChecklistComplete(selectedChecklist)
                        }

                        Button("Zurücksetzen") {
                            resetChecklist(selectedChecklist)
                        }

                        Button(role: .destructive) {
                            checklistToDelete = selectedChecklist
                        } label: {
                            Text("Checkliste entfernen")
                        }
                    }
                } label: {
                    Label("Neue Checkliste", systemImage: "plus.circle")
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $checklistItemFormContext) { context in
            ChecklistItemFormView(checklist: context.checklist, existingItem: context.item)
        }
        .alert("Diese Checkliste wirklich entfernen?", isPresented: deleteChecklistBinding) {
            Button("Entfernen", role: .destructive) {
                if let checklistToDelete {
                    deleteChecklist(checklistToDelete, vehicle: vehicle)
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Die Checkliste und alle Punkte darin gehen verloren.")
        }
        .alert("Das hat leider nicht geklappt", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Versuch es nochmal — manchmal klemmt’s kurz.")
        }
        .onAppear {
            selectedChecklistID = selectedChecklistID ?? vehicleChecklists.first?.id
            handlePendingRoute(vehicle: vehicle, trip: trip)
        }
        .onChange(of: vehicleChecklists.count) { _, _ in
            selectedChecklistID = selectedChecklistID ?? vehicleChecklists.first?.id
        }
        .onChange(of: navigation.pendingRoute) { _, _ in
            handlePendingRoute(vehicle: vehicle, trip: trip)
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

    private var deleteChecklistBinding: Binding<Bool> {
        Binding(
            get: { checklistToDelete != nil },
            set: { if !$0 { checklistToDelete = nil } }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func startChecklist(mode: ChecklistMode, vehicle: VehicleProfile, trip: Trip?) {
        do {
            let checklist = try ChecklistEditorService.startChecklist(mode: mode, vehicle: vehicle, trip: trip, context: modelContext)
            selectedChecklistID = checklist.id
        } catch {
            errorMessage = "Die Checkliste konnte nicht gestartet werden."
        }
    }

    private func refreshState(for checklist: ChecklistRun) {
        ChecklistEditorService.refreshState(for: checklist)
        try? modelContext.save()
    }

    private func status(for checklist: ChecklistRun) -> ReadinessStatus {
        switch checklist.state {
        case .complete: .green
        case .inProgress: .yellow
        case .notStarted: .yellow
        }
    }

    private func chipStateText(for state: ChecklistState) -> String {
        switch state {
        case .notStarted: "Offen"
        case .inProgress: "Läuft"
        case .complete: "Fertig"
        }
    }

    private func togglePinned(_ checklist: ChecklistRun) {
        do {
            try ChecklistEditorService.togglePinned(checklist: checklist, context: modelContext)
        } catch {
            errorMessage = "Die Anheftung konnte nicht geändert werden."
        }
    }

    private func markChecklistComplete(_ checklist: ChecklistRun) {
        do {
            try ChecklistEditorService.markComplete(checklist: checklist, context: modelContext)
        } catch {
            errorMessage = "Die Checkliste konnte nicht abgeschlossen werden."
        }
    }

    private func resetChecklist(_ checklist: ChecklistRun) {
        do {
            try ChecklistEditorService.reset(checklist: checklist, context: modelContext)
        } catch {
            errorMessage = "Die Checkliste konnte nicht zurückgesetzt werden."
        }
    }

    private func deleteChecklist(_ checklist: ChecklistRun, vehicle: VehicleProfile?) {
        guard let vehicle else { return }
        do {
            try ChecklistEditorService.deleteChecklist(checklist, from: vehicle, context: modelContext)
            selectedChecklistID = AppDataLocator.checklists(for: vehicle, checklists: checklists)
                .first(where: { $0.id != checklist.id })?.id
            checklistToDelete = nil
        } catch {
            errorMessage = "Die Checkliste konnte nicht gelöscht werden."
        }
    }

    private func deleteItem(_ item: ChecklistItemRecord, from checklist: ChecklistRun) {
        do {
            try ChecklistEditorService.deleteItem(item, from: checklist, context: modelContext)
        } catch {
            errorMessage = "Der Punkt konnte nicht gelöscht werden."
        }
    }

    private func moveItem(_ item: ChecklistItemRecord, in checklist: ChecklistRun, direction: Int) {
        do {
            try ChecklistEditorService.moveItem(item, in: checklist, direction: direction, context: modelContext)
        } catch {
            errorMessage = "Die Reihenfolge konnte nicht geändert werden."
        }
    }

    private func handlePendingRoute(vehicle: VehicleProfile?, trip: Trip?) {
        guard case let .checklist(mode)? = navigation.pendingRoute else { return }

        if let existing = AppDataLocator.checklists(for: vehicle, checklists: checklists).first(where: { $0.mode == mode }) {
            selectedChecklistID = existing.id
        } else if let vehicle {
            startChecklist(mode: mode, vehicle: vehicle, trip: trip)
        }

        navigation.clearPendingRoute()
    }
}

private struct ChecklistItemFormContext: Identifiable {
    let id = UUID()
    let checklist: ChecklistRun
    let item: ChecklistItemRecord?
}

private struct ChecklistItemRow: View {
    @Bindable var item: ChecklistItemRecord
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void
    let canMoveUp: Bool
    let canMoveDown: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $item.isCompleted) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    if !item.details.isEmpty {
                        Text(item.details)
                            .font(.caption)
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                }
            }
            .toggleStyle(.switch)
            .onChange(of: item.isCompleted) { _, _ in
                onToggle()
            }

            HStack(spacing: 12) {
                Button("Bearbeiten", action: onEdit)
                    .buttonStyle(.bordered)

                Button {
                    onMoveUp()
                } label: {
                    Image(systemName: "arrow.up")
                }
                .buttonStyle(.bordered)
                .disabled(!canMoveUp)

                Button {
                    onMoveDown()
                } label: {
                    Image(systemName: "arrow.down")
                }
                .buttonStyle(.bordered)
                .disabled(!canMoveDown)

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct ChecklistItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let checklist: ChecklistRun
    let existingItem: ChecklistItemRecord?

    @State private var draft: ChecklistItemDraftData
    @State private var errorMessage: String?

    init(checklist: ChecklistRun, existingItem: ChecklistItemRecord?) {
        self.checklist = checklist
        self.existingItem = existingItem
        _draft = State(initialValue: ChecklistItemDraftData(item: existingItem))
    }

    var body: some View {
        NavigationStack {
            RoadSheetScaffold(
                eyebrow: "Checkliste",
                title: existingItem == nil ? "Neuer Punkt" : "Punkt anpassen",
                subtitle: SheetCopy.checklistItemSubtitle,
                systemImage: "checklist.checked"
            ) {
                Form {
                    Section("Was soll geprüft werden?") {
                        TextField("Titel", text: $draft.title)
                        TextField("Details", text: $draft.details, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                        Toggle("Pflichtpunkt", isOn: $draft.isRequired)
                        Toggle("Für Status relevant", isOn: $draft.contributesToReadiness)
                    }
                }
            }
            .navigationTitle(existingItem == nil ? "Punkt hinzufügen" : "Punkt bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Das hat leider nicht geklappt", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Gib dem Punkt mindestens einen kurzen Namen.")
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
            _ = try ChecklistEditorService.saveItem(
                draft: draft,
                to: checklist,
                existingItem: existingItem,
                context: modelContext
            )
            dismiss()
        } catch {
            errorMessage = "Das hat leider nicht geklappt."
        }
    }
}

private extension ChecklistMode {
    var iconName: String {
        switch self {
        case .departure: "play.circle.fill"
        case .arrival: "parkingsign.circle.fill"
        case .shortStop: "pause.circle.fill"
        case .storage: "archivebox.circle.fill"
        case .winterize: "snowflake.circle.fill"
        case .deWinterize: "sun.max.circle.fill"
        }
    }
}

#Preview {
    NavigationStack {
        ChecklistsView()
            .environmentObject(AppNavigationState())
            .environmentObject(ActiveVehicleStore())
    }
    .modelContainer(PreviewStore.container)
}
