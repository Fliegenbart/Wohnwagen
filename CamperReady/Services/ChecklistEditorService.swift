import Foundation
import SwiftData

struct ChecklistItemDraftData {
    var title: String
    var details: String
    var isRequired: Bool
    var contributesToReadiness: Bool

    init(
        title: String = "",
        details: String = "",
        isRequired: Bool = true,
        contributesToReadiness: Bool = true
    ) {
        self.title = title
        self.details = details
        self.isRequired = isRequired
        self.contributesToReadiness = contributesToReadiness
    }

    init(item: ChecklistItemRecord?) {
        self.title = item?.title ?? ""
        self.details = item?.details ?? ""
        self.isRequired = item?.isRequired ?? true
        self.contributesToReadiness = item?.contributesToReadiness ?? true
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

@MainActor
enum ChecklistEditorService {
    static func startChecklist(mode: ChecklistMode, vehicle: VehicleProfile, trip: Trip?, context: ModelContext) throws -> ChecklistRun {
        let bundle = ChecklistTemplateLibrary.makeChecklist(mode: mode, vehicleID: vehicle.id, tripID: trip?.id)
        context.insert(bundle.0)
        bundle.1.forEach(context.insert)
        attach(bundle.0, to: &vehicle.checklists)
        vehicle.updatedAt = .now
        try context.save()
        return bundle.0
    }

    static func saveItem(
        draft: ChecklistItemDraftData,
        to checklist: ChecklistRun,
        existingItem: ChecklistItemRecord?,
        context: ModelContext
    ) throws -> ChecklistItemRecord {
        guard draft.canSave else {
            throw CocoaError(.validationStringTooShort)
        }

        let item = existingItem ?? ChecklistItemRecord(
            checklistID: checklist.id,
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            details: draft.details.trimmingCharacters(in: .whitespacesAndNewlines),
            isRequired: draft.isRequired,
            isCompleted: false,
            contributesToReadiness: draft.contributesToReadiness,
            sortOrder: nextSortOrder(for: checklist)
        )

        item.checklistID = checklist.id
        item.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        item.details = draft.details.trimmingCharacters(in: .whitespacesAndNewlines)
        item.isRequired = draft.isRequired
        item.contributesToReadiness = draft.contributesToReadiness

        if existingItem == nil {
            context.insert(item)
            attach(item, to: &checklist.items)
        }

        refreshState(for: checklist)
        try context.save()
        return item
    }

    static func deleteItem(_ item: ChecklistItemRecord, from checklist: ChecklistRun, context: ModelContext) throws {
        checklist.items.removeAll { $0.id == item.id }
        context.delete(item)
        normalizeSortOrder(in: checklist)
        refreshState(for: checklist)
        try context.save()
    }

    static func reset(checklist: ChecklistRun, context: ModelContext) throws {
        checklist.items.forEach { $0.isCompleted = false }
        checklist.state = .notStarted
        checklist.updatedAt = .now
        try context.save()
    }

    static func markComplete(checklist: ChecklistRun, context: ModelContext) throws {
        checklist.items.filter(\.isRequired).forEach { $0.isCompleted = true }
        checklist.state = .complete
        checklist.updatedAt = .now
        try context.save()
    }

    static func togglePinned(checklist: ChecklistRun, context: ModelContext) throws {
        checklist.isPinned.toggle()
        checklist.updatedAt = .now
        try context.save()
    }

    static func deleteChecklist(_ checklist: ChecklistRun, from vehicle: VehicleProfile, context: ModelContext) throws {
        vehicle.checklists.removeAll { $0.id == checklist.id }
        context.delete(checklist)
        vehicle.updatedAt = .now
        try context.save()
    }

    static func moveItem(_ item: ChecklistItemRecord, in checklist: ChecklistRun, direction: Int, context: ModelContext) throws {
        var ordered = checklist.items.sorted { $0.sortOrder < $1.sortOrder }
        guard let index = ordered.firstIndex(where: { $0.id == item.id }) else { return }
        let newIndex = index + direction
        guard ordered.indices.contains(newIndex) else { return }
        ordered.swapAt(index, newIndex)
        for (offset, checklistItem) in ordered.enumerated() {
            checklistItem.sortOrder = offset
        }
        checklist.updatedAt = .now
        try context.save()
    }

    static func refreshState(for checklist: ChecklistRun) {
        checklist.state = computeState(items: checklist.items)
        checklist.updatedAt = .now
    }

    static func computeState(items: [ChecklistItemRecord]) -> ChecklistState {
        let relevant = items.filter(\.isRequired)
        let itemsToCheck = relevant.isEmpty ? items : relevant
        guard itemsToCheck.isEmpty == false else { return .notStarted }

        let completedCount = itemsToCheck.filter(\.isCompleted).count
        if completedCount == 0 {
            return .notStarted
        }
        if completedCount == itemsToCheck.count {
            return .complete
        }
        return .inProgress
    }

    private static func nextSortOrder(for checklist: ChecklistRun) -> Int {
        (checklist.items.map(\.sortOrder).max() ?? -1) + 1
    }

    private static func normalizeSortOrder(in checklist: ChecklistRun) {
        for (offset, item) in checklist.items.sorted(by: { $0.sortOrder < $1.sortOrder }).enumerated() {
            item.sortOrder = offset
        }
    }

    private static func attach<T: Identifiable>(_ item: T, to collection: inout [T]) where T.ID: Equatable {
        guard collection.contains(where: { $0.id == item.id }) == false else { return }
        collection.append(item)
    }
}
