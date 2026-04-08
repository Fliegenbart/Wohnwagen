import Foundation

struct ChecklistTemplateItem {
    let title: String
    let details: String
    let isRequired: Bool
    let contributesToReadiness: Bool
}

enum ChecklistTemplateLibrary {
    static func makeChecklist(mode: ChecklistMode, vehicleID: UUID, tripID: UUID?) -> (ChecklistRun, [ChecklistItemRecord]) {
        let checklist = ChecklistRun(
            vehicleID: vehicleID,
            tripID: tripID,
            mode: mode,
            title: mode.title,
            createdAt: .now,
            updatedAt: .now,
            state: .notStarted,
            isPinned: mode == .departure
        )

        let items = template(for: mode).enumerated().map { index, item in
            ChecklistItemRecord(
                checklistID: checklist.id,
                title: item.title,
                details: item.details,
                isRequired: item.isRequired,
                isCompleted: false,
                contributesToReadiness: item.contributesToReadiness,
                sortOrder: index
            )
        }

        checklist.items = items

        return (checklist, items)
    }

    static func template(for mode: ChecklistMode) -> [ChecklistTemplateItem] {
        switch mode {
        case .departure:
            [
                .init(title: "Fenster und Dachluken zu?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Stützen eingefahren?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Landstrom getrennt?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Grauwasser gecheckt?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Toilettenkassette in Ordnung?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Kühlschrank auf den richtigen Modus gestellt?", details: "", isRequired: false, contributesToReadiness: true),
                .init(title: "Gas geschlossen und gesichert?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Ladung gesichert?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Reifendruck noch aktuell?", details: "", isRequired: false, contributesToReadiness: true),
                .init(title: "Dokumente dabei?", details: "", isRequired: true, contributesToReadiness: true)
            ]
        case .arrival:
            [
                .init(title: "Stellplatz einigermaßen eben?", details: "Keile eingepackt, falls nötig?", isRequired: true, contributesToReadiness: false),
                .init(title: "Strom angeschlossen?", details: "", isRequired: false, contributesToReadiness: false),
                .init(title: "Wasseranschluss passt?", details: "", isRequired: false, contributesToReadiness: false),
                .init(title: "Markise und Fenster gesichert?", details: "", isRequired: false, contributesToReadiness: false)
            ]
        case .shortStop:
            [
                .init(title: "Kurzer Sicherheitscheck", details: "Fenster, Gas, Ladung", isRequired: true, contributesToReadiness: true),
                .init(title: "Bereit zum Weiterfahren?", details: "", isRequired: true, contributesToReadiness: false)
            ]
        case .storage:
            [
                .init(title: "Batterie geladen?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Verderbliches raus?", details: "", isRequired: true, contributesToReadiness: false),
                .init(title: "Lüftung und Feuchtigkeit gecheckt?", details: "", isRequired: true, contributesToReadiness: true)
            ]
        case .winterize:
            [
                .init(title: "Frischwasser abgelassen?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Boiler leer?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Leitungen offen?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Pumpe aus?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Grauwasser abgelassen?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Toilette sauber?", details: "", isRequired: false, contributesToReadiness: false),
                .init(title: "Batterie im Lagermodus?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Gasflaschen zu?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Verderbliches raus?", details: "", isRequired: true, contributesToReadiness: false),
                .init(title: "Lüftung und Feuchtigkeit gecheckt?", details: "", isRequired: true, contributesToReadiness: true)
            ]
        case .deWinterize:
            [
                .init(title: "Wasseranlage dicht?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Boiler geschlossen?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Pumpe läuft?", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Gas getestet?", details: "", isRequired: true, contributesToReadiness: true)
            ]
        }
    }
}
