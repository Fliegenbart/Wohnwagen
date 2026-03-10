import Foundation
import SwiftData

@Model
final class ChecklistItemRecord {
    var id: UUID
    var checklistID: UUID
    var title: String
    var details: String
    var isRequired: Bool
    var isCompleted: Bool
    var contributesToReadiness: Bool
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        checklistID: UUID,
        title: String,
        details: String = "",
        isRequired: Bool = true,
        isCompleted: Bool = false,
        contributesToReadiness: Bool = true,
        sortOrder: Int
    ) {
        self.id = id
        self.checklistID = checklistID
        self.title = title
        self.details = details
        self.isRequired = isRequired
        self.isCompleted = isCompleted
        self.contributesToReadiness = contributesToReadiness
        self.sortOrder = sortOrder
    }
}
