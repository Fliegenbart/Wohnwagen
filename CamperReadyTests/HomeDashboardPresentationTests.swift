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

        XCTAssertEqual(presentation.focusEyebrow, "Dokumente & Fristen")
        XCTAssertEqual(presentation.focusTitle, "Gasprüfung abgelaufen")
        XCTAssertEqual(presentation.focusDetail, "Nachweis erneuern")
        XCTAssertEqual(presentation.focusSystemImage, "doc.text")
        XCTAssertEqual(presentation.focusStatus, .red)
        XCTAssertEqual(presentation.overviewRows.map(\.title), ["Gewicht", "Dokumente & Fristen", "Wartung"])
        XCTAssertEqual(presentation.primaryAction.title, "Dokumente prüfen")
        XCTAssertEqual(presentation.primaryAction.subtitle, "Nachweis erneuern")
        XCTAssertEqual(presentation.primaryAction.action, .documents)
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

        XCTAssertEqual(presentation.focusEyebrow, "Gewicht")
        XCTAssertEqual(presentation.focusTitle, "+220 kg Reserve")
        XCTAssertEqual(presentation.focusDetail, "Das ist dein ruhigster Kontrollblick vor der Fahrt.")
        XCTAssertEqual(presentation.focusSystemImage, "scalemass")
        XCTAssertEqual(presentation.focusStatus, .green)
        XCTAssertEqual(presentation.focusAction, .weight)
        XCTAssertEqual(presentation.overviewRows.count, 2)
        XCTAssertEqual(presentation.primaryAction.title, "Vor der Fahrt kurz checken")
        XCTAssertEqual(presentation.primaryAction.action, .departureChecklist)
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

        XCTAssertEqual(presentation.focusEyebrow, "Gewicht")
        XCTAssertEqual(presentation.focusTitle, "+220 kg Reserve")
        XCTAssertEqual(presentation.focusDetail, "Das ist dein ruhigster Kontrollblick vor der Fahrt.")
        XCTAssertEqual(presentation.focusAction, .weight)
        XCTAssertEqual(presentation.primaryAction.subtitle, "Die Abfahrts-Checkliste bleibt dein letzter ruhiger Kontrollblick.")
    }

    func testPresentationUsesDimensionMetadataForTieBreakingAndOverviewRows() {
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

        XCTAssertEqual(presentation.focusEyebrow, "Dokumente & Fristen")
        XCTAssertEqual(presentation.focusTitle, "Gasprüfung abgelaufen")
        XCTAssertEqual(presentation.primaryAction.action, .documents)
        XCTAssertEqual(presentation.overviewRows.map(\.systemImage), ["wrench.and.screwdriver", "doc.text", "scalemass"])
    }
}
