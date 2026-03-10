import Foundation
import SwiftData

@Model
final class ChecklistRun {
    var id: UUID
    var vehicleID: UUID
    var tripID: UUID?
    var modeRaw: String
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var stateRaw: String
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        tripID: UUID? = nil,
        mode: ChecklistMode,
        title: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        state: ChecklistState = .notStarted,
        isPinned: Bool = false
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.tripID = tripID
        self.modeRaw = mode.rawValue
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.stateRaw = state.rawValue
        self.isPinned = isPinned
    }

    var mode: ChecklistMode {
        get { ChecklistMode(rawValue: modeRaw) ?? .departure }
        set { modeRaw = newValue.rawValue }
    }

    var state: ChecklistState {
        get { ChecklistState(rawValue: stateRaw) ?? .notStarted }
        set { stateRaw = newValue.rawValue }
    }
}
