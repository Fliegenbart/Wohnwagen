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

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if vehicleChecklists.isEmpty {
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
                } else {
                    checklistHero(selectedChecklist: selectedChecklist, progress: progress, completedRequired: completedRequired, requiredCount: requiredItems.count)

                    checklistSection(title: "Checklisten", subtitle: "Wähle die Liste, die gerade zu deiner Situation passt.") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(vehicleChecklists) { checklist in
                                    ChecklistModeCard(
                                        checklist: checklist,
                                        isSelected: checklist.id == selectedChecklist?.id
                                    )
                                    .onTapGesture {
                                        selectedChecklistID = checklist.id
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    if let selectedChecklist {
                        checklistSection(title: selectedChecklist.title, subtitle: "Diese Punkte solltest du hier abhaken, bevor du weitermachst.") {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    StatusBadge(status: status(for: selectedChecklist), text: stateLabel(for: selectedChecklist.state))
                                    Spacer()
                                    Text("\(completedRequired)/\(max(requiredItems.count, 1)) Pflichtpunkte")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.mutedInk)
                                }

                                ProgressView(value: progress)
                                    .progressViewStyle(.linear)
                                    .tint(AppTheme.statusColor(status(for: selectedChecklist)))

                                HStack(spacing: 12) {
                                    Button("Punkt hinzufügen") {
                                        checklistItemFormContext = ChecklistItemFormContext(checklist: selectedChecklist, item: nil)
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button(selectedChecklist.isPinned ? "Lösen" : "Anheften") {
                                        togglePinned(selectedChecklist)
                                    }
                                    .buttonStyle(.bordered)
                                }

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

    private func checklistHero(
        selectedChecklist: ChecklistRun?,
        progress: Double,
        completedRequired: Int,
        requiredCount: Int
    ) -> some View {
        let heroStatus = selectedChecklist.map { status(for: $0) } ?? .yellow
        let shape = RoundedRectangle(cornerRadius: 34, style: .continuous)

        return ZStack(alignment: .bottomLeading) {
            checklistHeroBackground(status: heroStatus)

            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CamperReady")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("Checklisten")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.78))
                    }

                    Spacer()

                    StatusBadge(status: heroStatus, text: heroStatus.title)
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 18)

                VStack(alignment: .leading, spacing: 12) {
                    Text(selectedChecklist?.mode.title ?? "Checklisten")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.74)
                    Text(checklistSupportLine(selectedChecklist: selectedChecklist, completedRequired: completedRequired, requiredCount: requiredCount))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.84))
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(.white)

                    HStack(spacing: 12) {
                        heroPill(title: "Fortschritt", value: "\(Int((progress * 100).rounded())) %")
                        heroPill(title: "Pflicht", value: "\(completedRequired)/\(max(requiredCount, 1))")
                    }

                    if let selectedChecklist {
                        heroMeta(label: selectedChecklist.title, systemImage: selectedChecklist.mode.iconName)
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 360, alignment: .bottomLeading)
        .compositingGroup()
        .mask(shape)
        .overlay {
            shape
                .strokeBorder(AppTheme.asphalt.opacity(0.18), lineWidth: 1.6)
        }
        .overlay {
            shape
                .strokeBorder(Color.white.opacity(0.34), lineWidth: 0.8)
        }
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
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
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
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func checklistHeroBackground(status: ReadinessStatus) -> some View {
        ZStack {
            Rectangle()
                .fill(AppTheme.roadHeroGradient)

            Rectangle()
                .fill(AppTheme.roadFogGradient)

            Circle()
                .fill(AppTheme.accent.opacity(0.18))
                .frame(width: 172, height: 172)
                .blur(radius: 34)
                .offset(x: 118, y: -102)

            Circle()
                .fill(AppTheme.accentWarm.opacity(0.12))
                .frame(width: 150, height: 150)
                .blur(radius: 38)
                .offset(x: -104, y: 92)

            LinearGradient(
                colors: [Color.clear, AppTheme.statusColor(status).opacity(0.28)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "checklist.checked")
                        .font(.system(size: 102, weight: .bold))
                        .foregroundStyle(.white.opacity(0.16))
                        .padding(.trailing, 18)
                        .padding(.bottom, 30)
                }
            }
        }
    }

    private func checklistSupportLine(selectedChecklist: ChecklistRun?, completedRequired: Int, requiredCount: Int) -> String {
        guard let selectedChecklist else {
            return "Wähle eine Checkliste aus, damit du Schritt für Schritt prüfen kannst, was noch zu tun ist."
        }

        if requiredCount == 0 {
            return "Für \(selectedChecklist.title) sind noch keine Pflichtpunkte hinterlegt. Ergänze Aufgaben, wenn du mehr festhalten möchtest."
        }

        return "In \(selectedChecklist.title) sind \(completedRequired) von \(requiredCount) Pflichtpunkten erledigt."
    }

    private func checklistSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
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

    private func stateLabel(for state: ChecklistState) -> String {
        switch state {
        case .notStarted: "Nicht gestartet"
        case .inProgress: "Läuft"
        case .complete: "Erledigt"
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

private struct ChecklistModeCard: View {
    let checklist: ChecklistRun
    let isSelected: Bool

    var body: some View {
        let tint = AppTheme.statusColor(status)

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: checklist.mode.iconName)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : tint)
                Spacer()
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(.white.opacity(0.92)) : AnyShapeStyle(tint))
                    .frame(width: 24, height: 6)
            }

            Text(checklist.mode.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : AppTheme.ink)

            HStack(spacing: 8) {
                Text(stateText)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(isSelected ? .white.opacity(0.92) : tint)
                Text(checklist.updatedAt.shortDateString())
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .white.opacity(0.82) : AppTheme.mutedInk)
            }
        }
        .padding(16)
        .frame(width: 176, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.18) : AppTheme.asphalt.opacity(0.08), lineWidth: 1)
        )
    }

    private var status: ReadinessStatus {
        switch checklist.state {
        case .complete: .green
        case .inProgress: .yellow
        case .notStarted: .yellow
        }
    }

    private var background: LinearGradient {
        if isSelected {
            return AppTheme.statusGradient(status)
        }
        return LinearGradient(
            colors: [Color.white.opacity(0.54), Color.white.opacity(0.46)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var stateText: String {
        switch checklist.state {
        case .complete: "Erledigt"
        case .inProgress: "Läuft"
        case .notStarted: "Offen"
        }
    }
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
