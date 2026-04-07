import XCTest
@testable import CamperReady

final class HomeDashboardPresentationTests: XCTestCase {
    func testPresentationShapesFocusPanelFromHighestPriorityOpenDimension() {
        let snapshot = DashboardSnapshot(
            vehicleName: "Atlas",
            nextTripTitle: "Bodensee",
            overallStatus: .yellow,
            overallHeadline: "2 Punkte offen",
            openItemsCount: 2,
            dimensions: [
                ReadinessDimensionResult(title: "Gewicht", status: .green, summary: "+220 kg Reserve", reasons: [], nextAction: nil),
                ReadinessDimensionResult(title: "Gas & Dokumente", status: .red, summary: "Gasprüfung abgelaufen", reasons: ["Gasprüfung abgelaufen"], nextAction: "Nachweis erneuern"),
                ReadinessDimensionResult(title: "Wartung", status: .yellow, summary: "Service bald fällig", reasons: ["In 250 km fällig"], nextAction: "Termin planen")
            ],
            blockingItems: ["Gasprüfung abgelaufen"]
        )

        let presentation = HomeDashboardPresentation.make(snapshot: snapshot, tripTitle: "Bodensee")

        XCTAssertEqual(presentation.focusTitle, "2 Punkte offen")
        XCTAssertEqual(presentation.focusSubtitle, "Gasprüfung abgelaufen")
        XCTAssertEqual(presentation.focusDetail, "Nachweis erneuern")
        XCTAssertEqual(presentation.focusContext, "Bodensee")
        XCTAssertEqual(presentation.actionRows.count, 2)
        XCTAssertEqual(presentation.actionRows.first?.title, "Gasprüfung abgelaufen")
    }

    func testPresentationFallsBackToTripWhenNoOpenDimensionsExist() {
        let snapshot = DashboardSnapshot(
            vehicleName: "Atlas",
            nextTripTitle: "Bodensee",
            overallStatus: .green,
            overallHeadline: "Abfahrbereit",
            openItemsCount: 0,
            dimensions: [
                ReadinessDimensionResult(title: "Gewicht", status: .green, summary: "+220 kg Reserve", reasons: [], nextAction: nil),
                ReadinessDimensionResult(title: "Gas & Dokumente", status: .green, summary: "Alles gültig", reasons: [], nextAction: nil)
            ],
            blockingItems: []
        )

        let presentation = HomeDashboardPresentation.make(snapshot: snapshot, tripTitle: "Bodensee")

        XCTAssertEqual(presentation.focusTitle, "Abfahrbereit")
        XCTAssertEqual(presentation.focusSubtitle, "Bodensee")
        XCTAssertEqual(presentation.focusDetail, "Atlas ist für Bodensee einsatzbereit.")
        XCTAssertTrue(presentation.actionRows.isEmpty)
    }
}
