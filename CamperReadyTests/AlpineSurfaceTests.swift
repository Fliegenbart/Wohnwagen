import XCTest
import SwiftUI
@testable import CamperReady

final class AlpineSurfaceTests: XCTestCase {
    func testSurfaceMetricsMatchDesignRoles() {
        XCTAssertEqual(AlpineSurfaceMetrics.metrics(for: .section).cornerRadius, 24)
        XCTAssertEqual(AlpineSurfaceMetrics.metrics(for: .raised).cornerRadius, 18)
        XCTAssertTrue(AlpineSurfaceMetrics.metrics(for: .focus).isDark)
        XCTAssertEqual(AlpineSurfaceMetrics.metrics(for: .focus).cornerRadius, 24)
        XCTAssertLessThan(AlpineSurfaceMetrics.metrics(for: .section).shadowOpacity, 0.03)
        XCTAssertLessThan(AlpineSurfaceMetrics.metrics(for: .focus).shadowOpacity, 0.10)
    }

    func testSurfaceStyleCentralizesRoleSpecificValues() {
        let section = AlpineSurfaceStyle.style(for: .section)
        XCTAssertEqual(section.metrics, AlpineSurfaceMetrics(cornerRadius: 24, isDark: false, shadowOpacity: 0.025))
        XCTAssertEqual(section.background, .surface)
        XCTAssertEqual(section.contentInsets, EdgeInsets(top: 20, leading: 18, bottom: 20, trailing: 18))
        XCTAssertEqual(section.shadowRadius, 10)
        XCTAssertEqual(section.shadowYOffset, 6)

        let raised = AlpineSurfaceStyle.style(for: .raised)
        XCTAssertEqual(raised.background, .surfaceRaised)
        XCTAssertEqual(raised.metrics, AlpineSurfaceMetrics(cornerRadius: 18, isDark: false, shadowOpacity: 0.035))
        XCTAssertEqual(raised.contentInsets, EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
        XCTAssertEqual(raised.shadowRadius, 8)
        XCTAssertEqual(raised.shadowYOffset, 4)

        let focus = AlpineSurfaceStyle.style(for: .focus)
        XCTAssertEqual(focus.background, .petrol)
        XCTAssertEqual(focus.metrics, AlpineSurfaceMetrics(cornerRadius: 24, isDark: true, shadowOpacity: 0.08))
        XCTAssertEqual(focus.contentInsets, EdgeInsets(top: 22, leading: 20, bottom: 22, trailing: 20))
        XCTAssertEqual(focus.shadowRadius, 14)
        XCTAssertEqual(focus.shadowYOffset, 8)
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

    func testScenicCardLayoutBecomesCompactBeforeItBreaks() {
        let regular = ScenicCardLayout.metrics(forScreenWidth: 430, emphasis: .support)
        XCTAssertFalse(regular.prefersVertical)
        XCTAssertEqual(regular.titleSize, 22)

        let compact = ScenicCardLayout.metrics(forScreenWidth: 390, emphasis: .support)
        XCTAssertFalse(compact.prefersVertical)
        XCTAssertLessThan(compact.artworkSize.width, regular.artworkSize.width)
        XCTAssertLessThan(compact.containerSize.width, regular.containerSize.width)
        XCTAssertEqual(compact.titleSize, 20)
    }

    func testScenicHeroLayoutFallsBackToVerticalOnVeryNarrowWidths() {
        let narrow = ScenicCardLayout.metrics(forScreenWidth: 318, emphasis: .hero)
        XCTAssertTrue(narrow.prefersVertical)
        XCTAssertEqual(narrow.titleSize, 20)
        XCTAssertGreaterThan(narrow.minimumHeight, 220)
    }
}
