import XCTest
@testable import CamperReady

final class ChecklistPresentationTests: XCTestCase {
    func testChecklistPresentationBuildsReadableProgressCopy() {
        let presentation = ChecklistPresentation.make(
            title: "Abfahrt",
            state: .inProgress,
            completedRequired: 8,
            requiredCount: 12,
            nextRequiredTitle: "Gas abdrehen"
        )

        XCTAssertEqual(presentation.title, "Abfahrt")
        XCTAssertEqual(presentation.progressText, "8 von 12 Pflichtpunkten erledigt")
        XCTAssertEqual(presentation.stateText, "In Arbeit")
        XCTAssertEqual(presentation.focusText, "Als Nächstes: Gas abdrehen")
    }

    func testChecklistPresentationMapsAllStatesToGermanLabels() {
        let cases: [(ChecklistState, String)] = [
            (.notStarted, "Nicht begonnen"),
            (.inProgress, "In Arbeit"),
            (.complete, "Fertig")
        ]

        for (state, expectedStateText) in cases {
            let presentation = ChecklistPresentation.make(
                title: "Ankunft",
                state: state,
                completedRequired: 0,
                requiredCount: 3
            )

            XCTAssertEqual(presentation.title, "Ankunft")
            XCTAssertEqual(presentation.stateText, expectedStateText)
        }
    }

    func testChecklistPresentationUsesTruthfulCopyWhenNoRequiredItemsExist() {
        let cases: [(ChecklistState, String)] = [
            (.notStarted, "Keine Pflichtpunkte hinterlegt"),
            (.inProgress, "Keine Pflichtpunkte hinterlegt, Checkliste in Arbeit"),
            (.complete, "Keine Pflichtpunkte hinterlegt, Checkliste als fertig markiert")
        ]

        for (state, expectedProgressText) in cases {
            let presentation = ChecklistPresentation.make(
                title: "Kurzstopp",
                state: state,
                completedRequired: 0,
                requiredCount: 0
            )

            XCTAssertEqual(presentation.title, "Kurzstopp")
            XCTAssertEqual(presentation.progressText, expectedProgressText)
            XCTAssertFalse(presentation.progressText.contains("0 von 0"))
        }
    }

    func testChecklistPresentationFallsBackToStateSummaryWhenAllRequiredItemsAreDone() {
        let presentation = ChecklistPresentation.make(
            title: "Abfahrt",
            state: .complete,
            completedRequired: 4,
            requiredCount: 4,
            nextRequiredTitle: nil
        )

        XCTAssertEqual(presentation.focusText, "Alle Pflichtpunkte sind erledigt.")
    }

    func testChecklistWorkflowSectionsKeepOpenItemsFocusedAndCompletedAccessible() {
        let checklistID = UUID()
        let items = [
            ChecklistItemRecord(checklistID: checklistID, title: "Gas prüfen", isCompleted: false, sortOrder: 0),
            ChecklistItemRecord(checklistID: checklistID, title: "Strom trennen", isCompleted: true, sortOrder: 1),
            ChecklistItemRecord(checklistID: checklistID, title: "Fenster schließen", isCompleted: false, sortOrder: 2)
        ]

        let sections = ChecklistWorkflowSections.make(items: items)

        XCTAssertEqual(sections.openItems.map(\.title), ["Gas prüfen", "Fenster schließen"])
        XCTAssertEqual(sections.completedItems.map(\.title), ["Strom trennen"])
    }
}
