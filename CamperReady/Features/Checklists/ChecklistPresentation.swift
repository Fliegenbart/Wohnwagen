import Foundation

struct ChecklistWorkflowSections {
    let openItems: [ChecklistItemRecord]
    let completedItems: [ChecklistItemRecord]

    static func make(items: [ChecklistItemRecord]) -> Self {
        ChecklistWorkflowSections(
            openItems: items.filter { !$0.isCompleted },
            completedItems: items.filter(\.isCompleted)
        )
    }
}

struct ChecklistPresentation: Equatable {
    let title: String
    let stateText: String
    let progressText: String
    let focusText: String

    static func make(
        title: String,
        state: ChecklistState,
        completedRequired: Int,
        requiredCount: Int,
        nextRequiredTitle: String? = nil
    ) -> Self {
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

        let focusText: String
        if let nextRequiredTitle, !nextRequiredTitle.isEmpty {
            focusText = "Als Nächstes: \(nextRequiredTitle)"
        } else if requiredCount > 0, completedRequired >= requiredCount {
            focusText = "Alle Pflichtpunkte sind erledigt."
        } else {
            focusText = switch state {
            case .notStarted: "Noch nichts abgehakt."
            case .inProgress: "Die nächsten offenen Punkte warten noch."
            case .complete: "Alle Pflichtpunkte sind erledigt."
            }
        }

        return ChecklistPresentation(
            title: title,
            stateText: stateText,
            progressText: progressText,
            focusText: focusText
        )
    }
}
