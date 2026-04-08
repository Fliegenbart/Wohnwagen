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
                ReadinessDimensionResult(title: "Dokumente & Fristen", status: .red, summary: "Gasprüfung abgelaufen", reasons: ["Gasprüfung abgelaufen"], nextAction: "Nachweis erneuern"),
                ReadinessDimensionResult(title: "Wartung", status: .yellow, summary: "Service bald fällig", reasons: ["In 250 km fällig"], nextAction: "Termin planen")
            ],
            blockingItems: ["Gasprüfung abgelaufen"]
        )

        let presentation = HomeDashboardPresentation.make(snapshot: snapshot, tripTitle: "Bodensee")

        XCTAssertEqual(presentation.focusTitle, "2 Punkte offen")
        XCTAssertEqual(presentation.focusSubtitle, "Gasprüfung abgelaufen")
        XCTAssertEqual(presentation.focusDetail, "Nachweis erneuern")
        XCTAssertEqual(presentation.focusContext, "Bodensee")
        XCTAssertEqual(presentation.overviewRows.map(\.title), ["Gewicht", "Dokumente & Fristen", "Wartung"])
        XCTAssertEqual(presentation.actionRows.count, 2)
        XCTAssertEqual(presentation.actionRows.first?.title, "Gasprüfung abgelaufen")
        XCTAssertEqual(presentation.actionRows.first?.systemImage, "doc.text")
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
                ReadinessDimensionResult(title: "Dokumente & Fristen", status: .green, summary: "Alles gültig", reasons: [], nextAction: nil)
            ],
            blockingItems: []
        )

        let presentation = HomeDashboardPresentation.make(snapshot: snapshot, tripTitle: "Bodensee")

        XCTAssertEqual(presentation.focusTitle, "Abfahrbereit")
        XCTAssertEqual(presentation.focusSubtitle, "Bodensee")
        XCTAssertEqual(presentation.focusDetail, "Atlas ist bereit für Bodensee.")
        XCTAssertEqual(presentation.overviewRows.count, 2)
        XCTAssertTrue(presentation.actionRows.isEmpty)
    }

    func testPresentationFallsBackWithoutExplicitTripTitle() {
        let snapshot = DashboardSnapshot(
            vehicleName: "Atlas",
            nextTripTitle: "Keine Reise geplant",
            overallStatus: .green,
            overallHeadline: "Abfahrbereit",
            openItemsCount: 0,
            dimensions: [
                ReadinessDimensionResult(title: "Gewicht", status: .green, summary: "+220 kg Reserve", reasons: [], nextAction: nil)
            ],
            blockingItems: []
        )

        let presentation = HomeDashboardPresentation.make(snapshot: snapshot, tripTitle: nil)

        XCTAssertEqual(presentation.focusContext, "Keine Reise geplant")
        XCTAssertEqual(presentation.focusSubtitle, "Keine Reise geplant")
        XCTAssertEqual(presentation.focusDetail, "Atlas ist startklar — alles sieht gut aus.")
    }

    func testPresentationUsesDimensionMetadataForTieBreakingAndActionRows() {
        let snapshot = DashboardSnapshot(
            vehicleName: "Atlas",
            nextTripTitle: "Nordsee",
            overallStatus: .red,
            overallHeadline: "Nicht bereit",
            openItemsCount: 3,
            dimensions: [
                ReadinessDimensionResult(title: "Wartung", status: .red, summary: "Service überfällig", reasons: ["Seit 400 km überzogen"], nextAction: "Termin buchen"),
                ReadinessDimensionResult(title: "Dokumente & Fristen", status: .red, summary: "Gasprüfung abgelaufen", reasons: ["Prüfung fehlt"], nextAction: "Nachweis erneuern"),
                ReadinessDimensionResult(title: "Gewicht", status: .yellow, summary: "Nur noch 50 kg Reserve", reasons: ["Wenig Reserve"], nextAction: "Beladung prüfen")
            ],
            blockingItems: ["Prüfung fehlt", "Seit 400 km überzogen"]
        )

        let presentation = HomeDashboardPresentation.make(snapshot: snapshot, tripTitle: "Nordsee")

        XCTAssertEqual(presentation.focusSubtitle, "Gasprüfung abgelaufen")
        XCTAssertEqual(presentation.actionRows.map(\.systemImage), ["doc.text", "wrench.and.screwdriver", "scalemass"])
        XCTAssertEqual(presentation.actionRows.map(\.dimensionTitle), ["Dokumente & Fristen", "Wartung", "Gewicht"])
    }
}
