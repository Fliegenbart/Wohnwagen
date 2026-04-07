import Foundation

struct ChecklistPresentation: Equatable {
    let title: String
    let stateText: String
    let progressText: String

    static func make(title: String, state: ChecklistState, completedRequired: Int, requiredCount: Int) -> Self {
        let stateText: String = switch state {
        case .notStarted: "Nicht begonnen"
        case .inProgress: "In Arbeit"
        case .complete: "Fertig"
        }

        return ChecklistPresentation(
            title: title,
            stateText: stateText,
            progressText: "\(completedRequired) von \(requiredCount) Pflichtpunkten erledigt"
        )
    }
}
