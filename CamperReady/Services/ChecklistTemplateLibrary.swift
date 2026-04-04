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
                .init(title: "Fenster und Dachluken geschlossen", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Stützen und Hubstützen eingefahren", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Landstrom getrennt", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Grauwasser in Ordnung", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Toilettenkassette ok", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Kühlschrank-Modus geprüft", details: "", isRequired: false, contributesToReadiness: true),
                .init(title: "Gas geschlossen / gesichert", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Ladung gesichert", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Reifendruck vor kurzem geprüft", details: "", isRequired: false, contributesToReadiness: true),
                .init(title: "Dokumente an Bord", details: "", isRequired: true, contributesToReadiness: true)
            ]
        case .arrival:
            [
                .init(title: "Stellplatz eingeebnet", details: "Keile falls nötig", isRequired: true, contributesToReadiness: false),
                .init(title: "Strom angeschlossen", details: "", isRequired: false, contributesToReadiness: false),
                .init(title: "Wasseranschluss geprüft", details: "", isRequired: false, contributesToReadiness: false),
                .init(title: "Markise / Fenster sicher", details: "", isRequired: false, contributesToReadiness: false)
            ]
        case .shortStop:
            [
                .init(title: "Schneller Sicherheitscheck", details: "Fenster, Gas, Ladung", isRequired: true, contributesToReadiness: true),
                .init(title: "Parken für Weiterfahrt vorbereitet", details: "", isRequired: true, contributesToReadiness: false)
            ]
        case .storage:
            [
                .init(title: "Batterie-Ladezustand geprüft", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Perishables entfernt", details: "", isRequired: true, contributesToReadiness: false),
                .init(title: "Belüftung / Feuchtigkeit geprüft", details: "", isRequired: true, contributesToReadiness: true)
            ]
        case .winterize:
            [
                .init(title: "Frischwasser abgelassen", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Boiler entleert", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Leitungen geöffnet", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Pumpe ausgeschaltet", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Grauwasser leer", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Toilette gereinigt", details: "", isRequired: false, contributesToReadiness: false),
                .init(title: "Batterie im Lagermodus", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Gasflaschen geschlossen", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Verderbliches entfernt", details: "", isRequired: true, contributesToReadiness: false),
                .init(title: "Belüftung / Feuchtigkeit geprüft", details: "", isRequired: true, contributesToReadiness: true)
            ]
        case .deWinterize:
            [
                .init(title: "Wasseranlage auf Dichtheit geprüft", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Boiler geschlossen", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Pumpe aktiviert", details: "", isRequired: true, contributesToReadiness: true),
                .init(title: "Gasversorgung getestet", details: "", isRequired: true, contributesToReadiness: true)
            ]
        }
    }
}
