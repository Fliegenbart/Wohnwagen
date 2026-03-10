import SwiftData
import SwiftUI

struct ChecklistsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @Query(sort: \ChecklistRun.updatedAt, order: .reverse) private var checklists: [ChecklistRun]
    @Query(sort: \ChecklistItemRecord.sortOrder) private var items: [ChecklistItemRecord]
    @State private var selectedChecklistID: UUID?

    var body: some View {
        let vehicle = AppDataLocator.primaryVehicle(in: vehicles)
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
                    ContentUnavailableView(
                        "Noch kein Modus gestartet",
                        systemImage: "checklist",
                        description: Text("Starte Abfahrt, Einwintern oder einen anderen Modus, damit der Status ins Cockpit zurückspielt.")
                    )
                } else {
                    checklistHero(selectedChecklist: selectedChecklist, progress: progress, completedRequired: completedRequired, requiredCount: requiredItems.count)

                    SectionCard(title: "Modi") {
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
                        SectionCard(title: selectedChecklist.title) {
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

                                ForEach(selectedItems) { item in
                                    ChecklistItemRow(item: item) {
                                        refreshState(for: selectedChecklist)
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
                    ForEach(ChecklistMode.allCases) { mode in
                        Button(mode.title) {
                            startChecklist(mode: mode, vehicleID: vehicle?.id, tripID: trip?.id)
                        }
                    }
                } label: {
                    Label("Neuer Modus", systemImage: "plus.circle")
                }
            }
        }
        .onAppear {
            selectedChecklistID = selectedChecklistID ?? vehicleChecklists.first?.id
        }
        .onChange(of: vehicleChecklists.count) { _, _ in
            selectedChecklistID = selectedChecklistID ?? vehicleChecklists.first?.id
        }
    }

    private func checklistHero(
        selectedChecklist: ChecklistRun?,
        progress: Double,
        completedRequired: Int,
        requiredCount: Int
    ) -> some View {
        let heroStatus = selectedChecklist.map { status(for: $0) } ?? .yellow

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aktiver Betriebsmodus")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.78))
                    Text(selectedChecklist?.mode.title ?? "Checklisten")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(selectedChecklist?.title ?? "Keine aktive Auswahl")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                StatusBadge(status: heroStatus, text: heroStatus.title)
                    .background(.white.opacity(0.14), in: Capsule())
            }

            Text(requiredCount == 0 ? "Noch keine Pflichtpunkte hinterlegt." : "\(completedRequired) von \(requiredCount) Pflichtpunkten erledigt")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.white)

            HStack(spacing: 10) {
                heroPill(title: "Fortschritt", value: "\(Int((progress * 100).rounded())) %")
                heroPill(title: "Pflicht", value: "\(completedRequired)/\(max(requiredCount, 1))")
                heroPill(title: "Status", value: stateLabel(for: selectedChecklist?.state ?? .notStarted))
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.statusGradient(heroStatus), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: AppTheme.statusColor(heroStatus).opacity(0.28), radius: 28, x: 0, y: 16)
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
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func startChecklist(mode: ChecklistMode, vehicleID: UUID?, tripID: UUID?) {
        guard let vehicleID else { return }
        let bundle = ChecklistTemplateLibrary.makeChecklist(mode: mode, vehicleID: vehicleID, tripID: tripID)
        modelContext.insert(bundle.0)
        bundle.1.forEach(modelContext.insert)
        try? modelContext.save()
        selectedChecklistID = bundle.0.id
    }

    private func refreshState(for checklist: ChecklistRun) {
        let checklistItems = AppDataLocator.checklistItems(for: checklist, items: items)
        let requiredItems = checklistItems.filter(\.isRequired)
        let completed = requiredItems.filter(\.isCompleted).count

        if completed == 0 {
            checklist.state = .notStarted
        } else if completed == requiredItems.count {
            checklist.state = .complete
        } else {
            checklist.state = .inProgress
        }
        checklist.updatedAt = .now
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
                    .frame(width: 34, height: 34)
                    .background((isSelected ? Color.white.opacity(0.18) : tint.opacity(0.12)), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Spacer()
                StatusBadge(status: status, text: status.title)
            }

            Text(checklist.mode.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : AppTheme.ink)

            Text(checklist.updatedAt.shortDateString())
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? .white.opacity(0.82) : AppTheme.mutedInk)
        }
        .padding(16)
        .frame(width: 176, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.18) : tint.opacity(0.16), lineWidth: 1)
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
            colors: [AppTheme.cardFill, Color.white.opacity(0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct ChecklistItemRow: View {
    @Bindable var item: ChecklistItemRecord
    let onToggle: () -> Void

    var body: some View {
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
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(item.isCompleted ? AppTheme.green.opacity(0.10) : Color.white.opacity(0.60))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(item.isCompleted ? AppTheme.green.opacity(0.20) : Color.white.opacity(0.70), lineWidth: 1)
        )
        .onChange(of: item.isCompleted) { _, _ in
            onToggle()
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
    }
    .modelContainer(PreviewStore.container)
}
