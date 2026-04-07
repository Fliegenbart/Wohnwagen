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
        let vehicle = activeVehicleStore.activeVehicle(in: vehicles)
        let trip = AppDataLocator.activeTrip(for: vehicle, trips: trips)
        let vehicleChecklists = AppDataLocator.checklists(for: vehicle, checklists: checklists)
        let selectedChecklist = vehicleChecklists.first(where: { $0.id == selectedChecklistID }) ?? vehicleChecklists.first
        let selectedItems = AppDataLocator.checklistItems(for: selectedChecklist, items: items)
        let requiredItems = selectedItems.filter(\.isRequired)
        let completedRequired = requiredItems.filter(\.isCompleted).count
        let progress = requiredItems.isEmpty ? 0 : Double(completedRequired) / Double(requiredItems.count)
        let presentation = ChecklistPresentation.make(
            title: selectedChecklist?.title ?? "Checklisten",
            state: selectedChecklist?.state ?? .notStarted,
            completedRequired: completedRequired,
            requiredCount: requiredItems.count
        )
        let heroStatus = selectedChecklist.map(status(for:)) ?? .yellow

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if vehicleChecklists.isEmpty {
                    SectionCard(title: "Noch keine Checkliste gestartet", subtitle: "Starte einen Modus wie Abfahrt oder Einwintern, damit du offene Punkte direkt siehst.") {
                        VStack(alignment: .leading, spacing: 16) {
                            ContentUnavailableView(
                                "Noch keine Checkliste gestartet",
                                systemImage: "checklist",
                                description: Text("Starte eine Checkliste wie Abfahrt oder Einwintern, damit du offene Punkte direkt siehst.")
                            )

                            if let vehicle {
                                ForEach(ChecklistMode.allCases) { mode in
                                    Button(mode.title) {
                                        startChecklist(mode: mode, vehicle: vehicle, trip: trip)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                    }
                    .opacity(hasAppeared ? 1 : 0.01)
                    .offset(y: hasAppeared ? 0 : 16)
                } else {
                    FeatureHeader(
                        eyebrow: "Checklist mode",
                        title: selectedChecklist?.title ?? "Checklisten",
                        subtitle: presentation.progressText
                    )
                    .opacity(hasAppeared ? 1 : 0.01)
                    .offset(y: hasAppeared ? 0 : 10)

                    AlpineSurface(role: .raised) {
                        VStack(alignment: .leading, spacing: 12) {
                            StatusBadge(status: heroStatus, text: presentation.stateText)

                            ProgressView(value: progress)
                                .progressViewStyle(.linear)
                                .tint(AppTheme.statusColor(heroStatus))

                            HStack(spacing: 12) {
                                Button("Punkt hinzufügen") {
                                    guard let selectedChecklist else { return }
                                    checklistItemFormContext = ChecklistItemFormContext(checklist: selectedChecklist, item: nil)
                                }
                                .buttonStyle(.borderedProminent)

                                Button(selectedChecklist?.isPinned == true ? "Lösen" : "Anheften") {
                                    guard let selectedChecklist else { return }
                                    togglePinned(selectedChecklist)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .opacity(hasAppeared ? 1 : 0.01)
                    .offset(y: hasAppeared ? 0 : 16)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Aktive Modi")
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(AppTheme.mutedInk)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(vehicleChecklists) { checklist in
                                    Button {
                                        selectedChecklistID = checklist.id
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(checklist.title)
                                            if checklist.isPinned {
                                                Image(systemName: "pin.fill")
                                                    .font(.caption2)
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
                        SectionCard(title: "Aktive Punkte", subtitle: "Diese Punkte solltest du jetzt abhaken, bevor du weitermachst.") {
                            VStack(alignment: .leading, spacing: 14) {
                                if selectedItems.isEmpty {
                                    Text("Diese Checkliste hat noch keine Punkte.")
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

                        Button(selectedChecklist.isPinned ? "Anheftung lösen" : "Anheften") {
                            togglePinned(selectedChecklist)
                        }

                        Button("Pflichtpunkte als erledigt markieren") {
                            markChecklistComplete(selectedChecklist)
                        }

                        Button("Zurücksetzen") {
                            resetChecklist(selectedChecklist)
                        }

                        Button(role: .destructive) {
                            checklistToDelete = selectedChecklist
                        } label: {
                            Text("Checkliste löschen")
                        }
                    }
                } label: {
                    Label("Neue Checkliste", systemImage: "plus.circle")
                }
            }
        }
        .sheet(item: $checklistItemFormContext) { context in
            ChecklistItemFormView(checklist: context.checklist, existingItem: context.item)
        }
        .alert("Checkliste wirklich löschen?", isPresented: deleteChecklistBinding) {
            Button("Löschen", role: .destructive) {
                if let checklistToDelete {
                    deleteChecklist(checklistToDelete, vehicle: vehicle)
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Diese Checkliste und alle Punkte darin werden entfernt.")
        }
        .alert("Checkliste konnte nicht gespeichert werden", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Bitte versuche es noch einmal.")
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
                title: existingItem == nil ? "Punkt ergänzen" : "Punkt anpassen",
                subtitle: "Halte fest, was bei diesem Modus wirklich geprüft werden soll.",
                systemImage: "checklist.checked"
            ) {
                Form {
                    Section("Punkt") {
                        TextField("Titel", text: $draft.title)
                        TextField("Details", text: $draft.details, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                        Toggle("Pflichtpunkt", isOn: $draft.isRequired)
                        Toggle("Für Bereitschaft relevant", isOn: $draft.contributesToReadiness)
                    }
                }
            }
            .navigationTitle(existingItem == nil ? "Punkt hinzufügen" : "Punkt bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Punkt konnte nicht gespeichert werden", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Bitte gib mindestens einen Titel an.")
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
            _ = try ChecklistEditorService.saveItem(
                draft: draft,
                to: checklist,
                existingItem: existingItem,
                context: modelContext
            )
            dismiss()
        } catch {
            errorMessage = "Der Punkt konnte nicht gespeichert werden."
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
