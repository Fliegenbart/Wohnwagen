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

        XCTAssertEqual(presentation.progressText, "8 von 12 Pflichtpunkten erledigt")
        XCTAssertEqual(presentation.stateText, "In Arbeit")
    }
}
