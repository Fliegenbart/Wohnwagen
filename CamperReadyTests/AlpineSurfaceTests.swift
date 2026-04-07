import XCTest
import SwiftUI
@testable import CamperReady

final class AlpineSurfaceTests: XCTestCase {
    func testSurfaceMetricsMatchDesignRoles() {
        XCTAssertEqual(AlpineSurfaceMetrics.metrics(for: .section).cornerRadius, 24)
        XCTAssertEqual(AlpineSurfaceMetrics.metrics(for: .raised).cornerRadius, 20)
        XCTAssertTrue(AlpineSurfaceMetrics.metrics(for: .focus).isDark)
        XCTAssertGreaterThan(AlpineSurfaceMetrics.metrics(for: .focus).shadowOpacity, 0.05)
    }

    func testSurfaceStyleCentralizesRoleSpecificValues() {
        let section = AlpineSurfaceStyle.style(for: .section)
        XCTAssertEqual(section.metrics, AlpineSurfaceMetrics(cornerRadius: 24, isDark: false, shadowOpacity: 0.00))
        XCTAssertEqual(section.background, .surfaceLow)
        XCTAssertEqual(section.contentInsets, EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
        XCTAssertEqual(section.shadowRadius, 12)
        XCTAssertEqual(section.shadowYOffset, 8)

        let focus = AlpineSurfaceStyle.style(for: .focus)
        XCTAssertEqual(focus.background, .petrol)
        XCTAssertEqual(focus.contentInsets, EdgeInsets(top: 22, leading: 20, bottom: 22, trailing: 20))
        XCTAssertEqual(focus.shadowRadius, 18)
        XCTAssertEqual(focus.shadowYOffset, 12)
    }

    func testRoadSheetHeaderFeedsSharedHeaderAndUtilityRow() {
        let header = RoadSheetHeader(
            eyebrow: "Planung",
            title: "Gewicht prüfen",
            subtitle: "Alle Lasten vor der Abfahrt kontrollieren",
            systemImage: "scalemass.fill"
        )

        XCTAssertEqual(
            header.featureHeader.eyebrow,
            "Planung"
        )
        XCTAssertEqual(header.featureHeader.title, "Gewicht prüfen")
        XCTAssertEqual(header.featureHeader.subtitle, "Alle Lasten vor der Abfahrt kontrollieren")
        XCTAssertEqual(
            header.utilityRow.title,
            "Planung"
        )
        XCTAssertEqual(header.utilityRow.subtitle, "Alle Lasten vor der Abfahrt kontrollieren")
        XCTAssertEqual(header.utilityRow.systemImage, "scalemass.fill")
    }

    func testFeatureHeaderAndUtilityRowStorePlainContentWithoutWrapperTypes() {
        let featureHeader = FeatureHeader(eyebrow: "Fleet", title: "Dein Fahrzeug", subtitle: "Technik im Blick")
        XCTAssertEqual(featureHeader.eyebrow, "Fleet")
        XCTAssertEqual(featureHeader.title, "Dein Fahrzeug")
        XCTAssertEqual(featureHeader.subtitle, "Technik im Blick")

        let utilityRow = UtilityRow(
            title: "Papiere",
            subtitle: "HU bis August",
            systemImage: "doc.text.fill",
            tint: AppTheme.petrolBright
        )
        XCTAssertEqual(utilityRow.title, "Papiere")
        XCTAssertEqual(utilityRow.subtitle, "HU bis August")
        XCTAssertEqual(utilityRow.systemImage, "doc.text.fill")
    }
}
