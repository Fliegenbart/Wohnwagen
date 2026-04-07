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

        let progressText: String
        if requiredCount == 0 {
            progressText = switch state {
            case .notStarted: "Keine Pflichtpunkte hinterlegt"
            case .inProgress: "Keine Pflichtpunkte hinterlegt, Checkliste in Arbeit"
            case .complete: "Keine Pflichtpunkte hinterlegt, Checkliste als fertig markiert"
            }
        } else {
            progressText = "\(completedRequired) von \(requiredCount) Pflichtpunkten erledigt"
        }

        return ChecklistPresentation(
            title: title,
            stateText: stateText,
            progressText: progressText
        )
    }
}
