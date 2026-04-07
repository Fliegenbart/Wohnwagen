import XCTest
@testable import CamperReady

final class ChecklistPresentationTests: XCTestCase {
    func testChecklistPresentationBuildsReadableProgressCopy() {
        let presentation = ChecklistPresentation.make(
            title: "Abfahrt",
            state: .inProgress,
            completedRequired: 8,
            requiredCount: 12
        )

        XCTAssertEqual(presentation.title, "Abfahrt")
        XCTAssertEqual(presentation.progressText, "8 von 12 Pflichtpunkten erledigt")
        XCTAssertEqual(presentation.stateText, "In Arbeit")
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

    func testChecklistPresentationUsesHelpfulCopyWhenNoRequiredItemsExist() {
        let presentation = ChecklistPresentation.make(
            title: "Kurzstopp",
            state: .complete,
            completedRequired: 0,
            requiredCount: 0
        )

        XCTAssertEqual(presentation.progressText, "Keine Pflichtpunkte hinterlegt, allgemeine Punkte erledigt")
        XCTAssertFalse(presentation.progressText.contains("0 von 0"))
    }
}
