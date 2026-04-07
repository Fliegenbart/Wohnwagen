# CamperReady Stitch Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild CamperReady's visual system and core screens around the Stitch reference set so the whole app feels like one calm, premium, utility-first iPhone product.

**Architecture:** Keep the current SwiftUI + SwiftData app structure, but introduce a small set of shared visual primitives and pure presentation helpers. Shared primitives handle palette, spacing, surfaces, and focus panels; feature-level presentation helpers keep the main views readable and give us a small amount of unit-testable behavior while we redesign the UI.

**Tech Stack:** SwiftUI, SwiftData, XCTest, `xcodebuild`

---

## File Map

- Modify: `CamperReady/Shared/UI/AppTheme.swift`
  Purpose: define the new Alpine Utility Zen palette, semantic surfaces, and focus gradients.
- Create: `CamperReady/Shared/UI/AlpineSurface.swift`
  Purpose: centralize surface roles, radii, fill style, and soft depth behavior.
- Create: `CamperReady/Shared/UI/FeatureHeader.swift`
  Purpose: reusable quiet screen header with eyebrow, title, support text.
- Create: `CamperReady/Shared/UI/UtilityRow.swift`
  Purpose: reusable row for action lists, summaries, and list-style sections.
- Modify: `CamperReady/Shared/UI/SectionCard.swift`
  Purpose: turn the old card component into a softer section container.
- Modify: `CamperReady/Shared/UI/MetricCard.swift`
  Purpose: replace boxed metrics with quieter utility metrics.
- Modify: `CamperReady/Shared/UI/StatusBadge.swift`
  Purpose: align status markers with the Stitch badge style.
- Modify: `CamperReady/Shared/UI/ReadinessTile.swift`
  Purpose: simplify or retire the old tile look so it no longer fights the new system.
- Create: `CamperReady/Features/Home/HomeDashboardPresentation.swift`
  Purpose: pure helper for hero copy, open-item ordering, and focus/action grouping.
- Modify: `CamperReady/Features/Home/HomeDashboardView.swift`
  Purpose: rebuild Home from card-grid to calm readiness cockpit.
- Create: `CamperReady/Features/Weight/WeightPresentation.swift`
  Purpose: pure helper for the large weight summary, reserve copy, and dominant metrics.
- Modify: `CamperReady/Features/Weight/WeightView.swift`
  Purpose: rebuild Weight around one focus panel and quieter utility sections.
- Create: `CamperReady/Features/Checklists/ChecklistPresentation.swift`
  Purpose: pure helper for checklist hero copy, progress text, and priority state.
- Modify: `CamperReady/Features/Checklists/ChecklistsView.swift`
  Purpose: simplify checklist mode selection and active-run presentation.
- Create: `CamperReady/Features/Vehicle/GaragePresentation.swift`
  Purpose: pure helper for active vehicle summary and ordered fleet display.
- Modify: `CamperReady/Features/Vehicle/GarageView.swift`
  Purpose: align Garage and vehicle selection with the Stitch fleet template.
- Modify: `CamperReady/Features/Home/FirstRunOnboardingView.swift`
  Purpose: keep first-run and empty vehicle entry visually aligned with Garage.
- Create: `CamperReady/Features/Logbook/LogbookPresentation.swift`
  Purpose: pure helper for editorial summary rows and section header text.
- Modify: `CamperReady/Features/Logbook/LogbookView.swift`
  Purpose: rebuild logbook summary and list rhythm around the Stitch reference.
- Create: `CamperReady/Features/Costs/CostsPresentation.swift`
  Purpose: pure helper for cost summary language and stat ordering.
- Modify: `CamperReady/Features/Costs/CostsView.swift`
  Purpose: align Costs with the same editorial summary + clean list structure.
- Modify: `CamperReady/Features/Vehicle/VehicleProfileView.swift`
  Purpose: bring the vehicle editor onto the same calmer sheet and field style.
- Modify: `CamperReady/Features/Home/AppInfoView.swift`
  Purpose: keep info/help chrome visually consistent with the redesign.
- Create: `CamperReady/Shared/UI/SheetCopy.swift`
  Purpose: centralize utility-first subtitles for sheets and forms.
- Modify: `CamperReady/Features/Weight/WeightView.swift:480+`
  Purpose: restyle inline weight forms.
- Modify: `CamperReady/Features/Checklists/ChecklistsView.swift:577+`
  Purpose: restyle inline checklist item forms.
- Modify: `CamperReady/Features/Logbook/LogbookView.swift:549+`
  Purpose: restyle maintenance/document/place forms.
- Modify: `CamperReady/Features/Costs/CostsView.swift:560+`
  Purpose: restyle trip and cost forms.
- Create: `CamperReadyTests/AlpineSurfaceTests.swift`
  Purpose: test the shared surface roles and metrics.
- Create: `CamperReadyTests/HomeDashboardPresentationTests.swift`
  Purpose: test Home section ordering and focus copy.
- Create: `CamperReadyTests/WeightPresentationTests.swift`
  Purpose: test weight summary composition.
- Create: `CamperReadyTests/ChecklistPresentationTests.swift`
  Purpose: test checklist summary composition.
- Create: `CamperReadyTests/GaragePresentationTests.swift`
  Purpose: test active-vehicle ordering.
- Create: `CamperReadyTests/LogbookPresentationTests.swift`
  Purpose: test editorial summary composition.
- Create: `CamperReadyTests/CostsPresentationTests.swift`
  Purpose: test cost stat ordering.
- Create: `CamperReadyTests/SheetHeaderCopyTests.swift`
  Purpose: keep sheet copy consistent and utility-first.

## Shared Reference Inputs

Use these visual references during implementation:
- `/tmp/stitch-2/stitch/readiness_cockpit/screen.png`
- `/tmp/stitch-2/stitch/weight_analysis/screen.png`
- `/tmp/stitch-2/stitch/your_fleet/screen.png`
- `/tmp/stitch-2/stitch/logbook_cost_history/screen.png`
- `/tmp/stitch-2/stitch/alpine_utility_zen/DESIGN.md`

## Task 1: Build the shared Alpine design system

**Files:**
- Create: `CamperReady/Shared/UI/AlpineSurface.swift`
- Create: `CamperReady/Shared/UI/FeatureHeader.swift`
- Create: `CamperReady/Shared/UI/UtilityRow.swift`
- Modify: `CamperReady/Shared/UI/AppTheme.swift`
- Modify: `CamperReady/Shared/UI/SectionCard.swift`
- Modify: `CamperReady/Shared/UI/MetricCard.swift`
- Modify: `CamperReady/Shared/UI/StatusBadge.swift`
- Modify: `CamperReady/Shared/UI/ReadinessTile.swift`
- Test: `CamperReadyTests/AlpineSurfaceTests.swift`

- [ ] **Step 1: Write the failing shared-style test**

```swift
import XCTest
@testable import CamperReady

final class AlpineSurfaceTests: XCTestCase {
    func testSurfaceMetricsMatchDesignRoles() {
        XCTAssertEqual(AlpineSurfaceMetrics.metrics(for: .section).cornerRadius, 24)
        XCTAssertEqual(AlpineSurfaceMetrics.metrics(for: .raised).cornerRadius, 20)
        XCTAssertTrue(AlpineSurfaceMetrics.metrics(for: .focus).isDark)
        XCTAssertGreaterThan(AlpineSurfaceMetrics.metrics(for: .focus).shadowOpacity, 0.05)
    }
}
```

- [ ] **Step 2: Run the targeted test to confirm the helper does not exist yet**

Run: `xcodebuild test -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' -only-testing:CamperReadyTests/AlpineSurfaceTests`

Expected: FAIL with missing `AlpineSurfaceMetrics` symbols.

- [ ] **Step 3: Add the shared surface helper and new theme tokens**

```swift
enum AlpineSurfaceRole {
    case section
    case raised
    case focus
}

struct AlpineSurfaceMetrics: Equatable {
    let cornerRadius: CGFloat
    let isDark: Bool
    let shadowOpacity: Double

    static func metrics(for role: AlpineSurfaceRole) -> Self {
        switch role {
        case .section: .init(cornerRadius: 24, isDark: false, shadowOpacity: 0.00)
        case .raised: .init(cornerRadius: 20, isDark: false, shadowOpacity: 0.04)
        case .focus: .init(cornerRadius: 24, isDark: true, shadowOpacity: 0.08)
        }
    }
}
```

```swift
enum AppTheme {
    static let canvas = Color(red: 0.976, green: 0.976, blue: 0.973)
    static let surfaceLow = Color(red: 0.953, green: 0.957, blue: 0.953)
    static let surfaceRaised = Color.white
    static let petrol = Color(red: 0.0, green: 0.275, blue: 0.333)
    static let petrolBright = Color(red: 0.0, green: 0.372, blue: 0.451)
    static let sand = Color(red: 0.976, green: 0.941, blue: 0.863)
    static let ink = Color(red: 0.098, green: 0.110, blue: 0.110)
}
```

- [ ] **Step 4: Replace the old boxed primitives with the new quiet primitives**

```swift
struct FeatureHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased()).font(.caption.weight(.bold)).foregroundStyle(AppTheme.mutedInk)
            Text(title).font(.system(size: 34, weight: .semibold)).foregroundStyle(AppTheme.ink)
            Text(subtitle).font(.subheadline).foregroundStyle(AppTheme.mutedInk)
        }
    }
}
```

```swift
struct UtilityRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.footnote).foregroundStyle(AppTheme.mutedInk)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }
}
```

- [ ] **Step 5: Run the shared test and the full suite**

Run: `xcodebuild test -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1'`

Expected: PASS, including the new shared-style test.

- [ ] **Step 6: Commit the shared design system**

```bash
git add CamperReady/Shared/UI CamperReadyTests/AlpineSurfaceTests.swift
git commit -m "feat: add alpine design primitives"
```

## Task 2: Redesign Home around the Stitch readiness cockpit

**Files:**
- Create: `CamperReady/Features/Home/HomeDashboardPresentation.swift`
- Modify: `CamperReady/Features/Home/HomeDashboardView.swift`
- Modify: `CamperReady/Shared/UI/ReadinessTile.swift`
- Test: `CamperReadyTests/HomeDashboardPresentationTests.swift`

- [ ] **Step 1: Write the failing Home presentation test**

```swift
import XCTest
@testable import CamperReady

final class HomeDashboardPresentationTests: XCTestCase {
    func testPresentationPromotesNonGreenDimensionsIntoActionList() {
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
        XCTAssertEqual(presentation.actionRows.count, 2)
        XCTAssertEqual(presentation.actionRows.first?.title, "Gasprüfung abgelaufen")
    }
}
```

- [ ] **Step 2: Run the targeted Home test**

Run: `xcodebuild test -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' -only-testing:CamperReadyTests/HomeDashboardPresentationTests`

Expected: FAIL because `HomeDashboardPresentation` does not exist yet.

- [ ] **Step 3: Add a small Home presentation helper**

```swift
struct HomeActionRow: Equatable, Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let status: ReadinessStatus
}

struct HomeDashboardPresentation: Equatable {
    let focusTitle: String
    let focusSubtitle: String
    let actionRows: [HomeActionRow]

    static func make(snapshot: DashboardSnapshot, tripTitle: String?) -> Self {
        let actionRows = snapshot.dimensions
            .filter { $0.status != .green }
            .map { result in
                HomeActionRow(
                    title: result.summary,
                    subtitle: result.nextAction ?? result.reasons.first ?? "Jetzt prüfen",
                    systemImage: "arrow.right",
                    status: result.status
                )
            }

        return HomeDashboardPresentation(
            focusTitle: snapshot.overallHeadline,
            focusSubtitle: tripTitle ?? snapshot.nextTripTitle,
            actionRows: actionRows
        )
    }
}
```

- [ ] **Step 4: Rebuild `HomeDashboardView` around one focus panel and quiet utility rows**

```swift
let presentation = HomeDashboardPresentation.make(snapshot: snapshot, tripTitle: trip?.title)

VStack(alignment: .leading, spacing: 20) {
    FeatureHeader(
        eyebrow: snapshot.vehicleName,
        title: "CamperReady",
        subtitle: "Dein Fahrzeugstatus vor der Abfahrt."
    )

    AlpineSurface(role: .focus) {
        VStack(alignment: .leading, spacing: 16) {
            StatusBadge(status: snapshot.overallStatus, text: snapshot.overallStatus.title)
            Text(presentation.focusTitle).font(.system(size: 32, weight: .semibold))
            Text(heroSupportLine(snapshot: snapshot, trip: trip))
            Button("Vor Abfahrt prüfen") {
                navigation.navigate(for: .departureChecklist)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    VStack(alignment: .leading, spacing: 0) {
        ForEach(presentation.actionRows) { row in
            UtilityRow(title: row.title, subtitle: row.subtitle, systemImage: "arrow.up.forward", tint: AppTheme.statusColor(row.status))
        }
    }
}
```

- [ ] **Step 5: Run Home tests and a build smoke test**

Run: `xcodebuild test -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' -only-testing:CamperReadyTests/HomeDashboardPresentationTests`

Run: `xcodebuild build -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1'`

Expected: PASS and Home compiles with the new layout.

- [ ] **Step 6: Commit the Home redesign**

```bash
git add CamperReady/Features/Home CamperReady/Shared/UI/ReadinessTile.swift CamperReadyTests/HomeDashboardPresentationTests.swift
git commit -m "feat: redesign home around stitch cockpit"
```

## Task 3: Redesign Weight around one technical focus panel

**Files:**
- Create: `CamperReady/Features/Weight/WeightPresentation.swift`
- Modify: `CamperReady/Features/Weight/WeightView.swift`
- Test: `CamperReadyTests/WeightPresentationTests.swift`

- [ ] **Step 1: Write the failing Weight presentation test**

```swift
import XCTest
@testable import CamperReady

final class WeightPresentationTests: XCTestCase {
    func testWeightPresentationBuildsLargeReserveHeadline() {
        let output = WeightAssessmentOutput(
            status: .green,
            estimatedGrossWeightKg: 3050,
            remainingMarginKg: 450,
            summary: "+450 kg Reserve",
            warnings: [],
            nextAction: "Aktuelle Beladung speichern",
            contributors: [],
            axleRisk: .low,
            waterComparisonDeltaKg: 80
        )

        let presentation = WeightPresentation.make(assessment: output, tripTitle: "Bodensee")

        XCTAssertEqual(presentation.headline, "+450 kg Reserve")
        XCTAssertEqual(presentation.primaryMetrics.map(\.title), ["Gesamtgewicht", "Achslast"])
    }
}
```

- [ ] **Step 2: Run the targeted Weight test**

Run: `xcodebuild test -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' -only-testing:CamperReadyTests/WeightPresentationTests`

Expected: FAIL because `WeightPresentation` does not exist yet.

- [ ] **Step 3: Add the Weight presentation helper**

```swift
struct WeightMetric: Equatable, Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct WeightPresentation: Equatable {
    let headline: String
    let support: String
    let primaryMetrics: [WeightMetric]

    static func make(assessment: WeightAssessmentOutput, tripTitle: String?) -> Self {
        WeightPresentation(
            headline: assessment.summary,
            support: tripTitle ?? "Aktuelle Fahrt",
            primaryMetrics: [
                WeightMetric(title: "Gesamtgewicht", value: assessment.estimatedGrossWeightKg?.kgString ?? "Unklar"),
                WeightMetric(title: "Achslast", value: assessment.axleRisk == .measured ? "Gemessen" : "Prüfen")
            ]
        )
    }
}
```

- [ ] **Step 4: Rebuild the Weight screen from many metric cards to one dominant analysis panel**

```swift
let presentation = WeightPresentation.make(assessment: assessment, tripTitle: trip?.title)

AlpineSurface(role: .focus) {
    VStack(alignment: .leading, spacing: 18) {
        Text("Load analysis").font(.caption.weight(.bold))
        Text(presentation.headline).font(.system(size: 34, weight: .semibold))
        ForEach(presentation.primaryMetrics) { metric in
            metricRow(title: metric.title, value: metric.value)
        }
    }
}
```

```swift
private func metricRow(title: String, value: String) -> some View {
    HStack {
        Text(title).font(.footnote.weight(.semibold)).foregroundStyle(.white.opacity(0.70))
        Spacer()
        Text(value).font(.headline.weight(.semibold)).foregroundStyle(.white)
    }
}
```

- [ ] **Step 5: Run Weight tests and a build**

Run: `xcodebuild test -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' -only-testing:CamperReadyTests/WeightPresentationTests`

Run: `xcodebuild build -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1'`

Expected: PASS and the Weight screen compiles with the new hierarchy.

- [ ] **Step 6: Commit the Weight redesign**

```bash
git add CamperReady/Features/Weight CamperReadyTests/WeightPresentationTests.swift
git commit -m "feat: redesign weight analysis screen"
```

## Task 4: Redesign Checklists into one active work mode

**Files:**
- Create: `CamperReady/Features/Checklists/ChecklistPresentation.swift`
- Modify: `CamperReady/Features/Checklists/ChecklistsView.swift`
- Test: `CamperReadyTests/ChecklistPresentationTests.swift`

- [ ] **Step 1: Write the failing checklist presentation test**

```swift
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
```

- [ ] **Step 2: Run the targeted checklist presentation test**

Run: `xcodebuild test -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' -only-testing:CamperReadyTests/ChecklistPresentationTests`

Expected: FAIL because `ChecklistPresentation` does not exist yet.

- [ ] **Step 3: Add the pure checklist presentation helper**

```swift
struct ChecklistPresentation: Equatable {
    let title: String
    let stateText: String
    let progressText: String

    static func make(title: String, state: ChecklistState, completedRequired: Int, requiredCount: Int) -> Self {
        let stateText: String = switch state {
        case .notStarted: "Nicht begonnen"
        case .inProgress: "In Arbeit"
        case .complete: "Fertig"
        }

        return ChecklistPresentation(
            title: title,
            stateText: stateText,
            progressText: "\(completedRequired) von \(requiredCount) Pflichtpunkten erledigt"
        )
    }
}
```

- [ ] **Step 4: Rework `ChecklistsView` around one active checklist and a lighter mode switcher**

```swift
FeatureHeader(
    eyebrow: "Checklist mode",
    title: selectedChecklist?.title ?? "Checklisten",
    subtitle: presentation.progressText
)

AlpineSurface(role: .raised) {
    VStack(alignment: .leading, spacing: 12) {
        StatusBadge(status: heroStatus, text: presentation.stateText)
        ProgressView(value: progress).tint(AppTheme.statusColor(heroStatus))
        HStack(spacing: 12) {
            Button("Punkt hinzufügen") {
                checklistItemFormContext = ChecklistItemFormContext(checklist: selectedChecklist, item: nil)
            }
            .buttonStyle(.borderedProminent)

            Button(selectedChecklist?.isPinned == true ? "Lösen" : "Anheften") {
                if let selectedChecklist { togglePinned(selectedChecklist) }
            }
            .buttonStyle(.bordered)
        }
    }
}
```

```swift
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 8) {
        ForEach(vehicleChecklists) { checklist in
            Text(checklist.title)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    (checklist.id == selectedChecklist?.id ? AppTheme.petrol.opacity(0.12) : AppTheme.surfaceLow),
                    in: Capsule()
                )
        }
    }
}
```

- [ ] **Step 5: Run checklist tests and a build**

Run: `xcodebuild test -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' -only-testing:CamperReadyTests/ChecklistPresentationTests`

Run: `xcodebuild build -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1'`

Expected: PASS and the checklist screen compiles with the new hierarchy.

- [ ] **Step 6: Commit the checklist redesign**

```bash
git add CamperReady/Features/Checklists CamperReadyTests/ChecklistPresentationTests.swift
git commit -m "feat: redesign checklist workspace"
```

## Task 5: Redesign Garage and vehicle selection using the fleet template

**Files:**
- Create: `CamperReady/Features/Vehicle/GaragePresentation.swift`
- Modify: `CamperReady/Features/Vehicle/GarageView.swift`
- Modify: `CamperReady/Features/Home/FirstRunOnboardingView.swift`
- Test: `CamperReadyTests/GaragePresentationTests.swift`

- [ ] **Step 1: Write the failing Garage presentation test**

```swift
import XCTest
@testable import CamperReady

final class GaragePresentationTests: XCTestCase {
    func testGaragePresentationKeepsActiveVehicleFirst() {
        let a = VehicleProfile(name: "Atlas", vehicleKind: .motorhome, brand: "Hymer", model: "ML-T")
        let b = VehicleProfile(name: "Nova", vehicleKind: .campervan, brand: "Pössl", model: "Summit")

        let presentation = GaragePresentation.make(vehicles: [a, b], activeVehicleID: b.id)

        XCTAssertEqual(presentation.orderedVehicleIDs.first, b.id)
    }
}
```

- [ ] **Step 2: Run the targeted Garage presentation test**

Run: `xcodebuild test -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' -only-testing:CamperReadyTests/GaragePresentationTests`

Expected: FAIL because `GaragePresentation` does not exist yet.

- [ ] **Step 3: Add the Garage presentation helper**

```swift
struct GaragePresentation: Equatable {
    let orderedVehicleIDs: [UUID]

    static func make(vehicles: [VehicleProfile], activeVehicleID: UUID?) -> Self {
        let sorted = vehicles.sorted { lhs, rhs in
            if lhs.id == activeVehicleID { return true }
            if rhs.id == activeVehicleID { return false }
            return lhs.createdAt < rhs.createdAt
        }
        return GaragePresentation(orderedVehicleIDs: sorted.map(\.id))
    }
}
```

- [ ] **Step 4: Rebuild Garage and vehicle selection with larger, calmer vehicle surfaces**

```swift
FeatureHeader(
    eyebrow: "Fleet selection",
    title: "Garage",
    subtitle: "Wähle dein aktives Fahrzeug und pflege die wichtigsten Basisdaten."
)

ForEach(orderedVehicles) { vehicle in
    AlpineSurface(role: vehicle.id == activeVehicle?.id ? .raised : .section) {
        VStack(alignment: .leading, spacing: 14) {
            Text(vehicle.name).font(.title2.weight(.semibold))
            Text([vehicle.brand, vehicle.model].joined(separator: " "))
            HStack(spacing: 12) {
                Button("Auswählen") { activeVehicleStore.select(vehicle) }
                    .buttonStyle(.borderedProminent)
                Button("Bearbeiten") { editorContext = VehicleEditorContext(vehicle: vehicle) }
                    .buttonStyle(.bordered)
            }
        }
    }
}
```

- [ ] **Step 5: Run Garage tests and a build**

Run: `xcodebuild test -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' -only-testing:CamperReadyTests/GaragePresentationTests`

Run: `xcodebuild build -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1'`

Expected: PASS and both Garage entry points compile.

- [ ] **Step 6: Commit the Garage redesign**

```bash
git add CamperReady/Features/Vehicle CamperReady/Features/Home/FirstRunOnboardingView.swift CamperReadyTests/GaragePresentationTests.swift
git commit -m "feat: redesign garage and vehicle selection"
```

## Task 6: Redesign Logbook and Costs with the editorial summary pattern

**Files:**
- Create: `CamperReady/Features/Logbook/LogbookPresentation.swift`
- Create: `CamperReady/Features/Costs/CostsPresentation.swift`
- Modify: `CamperReady/Features/Logbook/LogbookView.swift`
- Modify: `CamperReady/Features/Costs/CostsView.swift`
- Test: `CamperReadyTests/LogbookPresentationTests.swift`
- Test: `CamperReadyTests/CostsPresentationTests.swift`

- [ ] **Step 1: Write the failing Logbook and Costs tests**

```swift
import XCTest
@testable import CamperReady

final class LogbookPresentationTests: XCTestCase {
    func testLogbookPresentationKeepsStatsInEditorialOrder() {
        let presentation = LogbookPresentation.make(totalDistance: 4280, totalSpend: 1842, readinessAverage: 94)
        XCTAssertEqual(presentation.stats.map(\.title), ["Distanz", "Investition", "Bereitschaft"])
    }
}
```

```swift
final class CostsPresentationTests: XCTestCase {
    func testCostsPresentationPrioritizesTripThenNightThenAnnual() {
        let presentation = CostsPresentation.make(tripTotal: 642.5, perNight: 128.5, perHundredKm: 18.9, annualTotal: 1842)
        XCTAssertEqual(presentation.stats.map(\.title), ["Diese Reise", "Pro Nacht", "Pro 100 km", "Dieses Jahr"])
    }
}
```

- [ ] **Step 2: Run the targeted summary tests**

Run: `xcodebuild test -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' -only-testing:CamperReadyTests/LogbookPresentationTests -only-testing:CamperReadyTests/CostsPresentationTests`

Expected: FAIL because both presentation helpers are missing.

- [ ] **Step 3: Add the editorial summary helpers**

```swift
struct SummaryStat: Equatable, Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct LogbookPresentation: Equatable {
    let stats: [SummaryStat]

    static func make(totalDistance: Double, totalSpend: Double, readinessAverage: Int) -> Self {
        LogbookPresentation(stats: [
            SummaryStat(title: "Distanz", value: "\(Int(totalDistance)) km"),
            SummaryStat(title: "Investition", value: totalSpend.euroString),
            SummaryStat(title: "Bereitschaft", value: "\(readinessAverage) %")
        ])
    }
}

struct CostsPresentation: Equatable {
    let stats: [SummaryStat]

    static func make(tripTotal: Double, perNight: Double, perHundredKm: Double?, annualTotal: Double) -> Self {
        CostsPresentation(stats: [
            SummaryStat(title: "Diese Reise", value: tripTotal.euroString),
            SummaryStat(title: "Pro Nacht", value: perNight.euroString),
            SummaryStat(title: "Pro 100 km", value: perHundredKm.map { $0.euroString } ?? "Offen"),
            SummaryStat(title: "Dieses Jahr", value: annualTotal.euroString)
        ])
    }
}
```

- [ ] **Step 4: Rebuild Logbook and Costs using the same summary rhythm**

```swift
FeatureHeader(
    eyebrow: "Journey history",
    title: "Logbuch",
    subtitle: "Wartung, Dokumente und Orte in einer ruhigen Chronologie."
)

ForEach(presentation.stats) { stat in
    AlpineSurface(role: stat.title == "Bereitschaft" ? .section : .raised) {
        VStack(alignment: .leading, spacing: 6) {
            Text(stat.title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppTheme.mutedInk)
            Text(stat.value)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
        }
    }
}
```

```swift
FeatureHeader(
    eyebrow: vehicle.name,
    title: "Kosten",
    subtitle: trip?.title ?? "Kosten ohne aktive Reise"
)
```

- [ ] **Step 5: Run summary tests and the full suite**

Run: `xcodebuild test -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1'`

Expected: PASS, with the new Logbook and Costs tests included.

- [ ] **Step 6: Commit the editorial redesign**

```bash
git add CamperReady/Features/Logbook CamperReady/Features/Costs CamperReadyTests/LogbookPresentationTests.swift CamperReadyTests/CostsPresentationTests.swift
git commit -m "feat: redesign logbook and costs"
```

## Task 7: Restyle sheets, forms, and finish the app-wide polish

**Files:**
- Create: `CamperReady/Shared/UI/SheetCopy.swift`
- Modify: `CamperReady/Features/Vehicle/VehicleProfileView.swift`
- Modify: `CamperReady/Features/Home/AppInfoView.swift`
- Modify: `CamperReady/Features/Weight/WeightView.swift`
- Modify: `CamperReady/Features/Checklists/ChecklistsView.swift`
- Modify: `CamperReady/Features/Logbook/LogbookView.swift`
- Modify: `CamperReady/Features/Costs/CostsView.swift`
- Test: `CamperReadyTests/SheetHeaderCopyTests.swift`

- [ ] **Step 1: Write a failing regression test for the shared header copy used in sheets**

```swift
import XCTest
@testable import CamperReady

final class SheetHeaderCopyTests: XCTestCase {
    func testRoadSheetHeaderUsesUtilityCopyInsteadOfMarketingCopy() {
        let subtitle = SheetCopy.vehicleProfileSubtitle
        XCTAssertEqual(subtitle, "Pflege hier die Basisdaten, Gewichte und Intervalle deines Fahrzeugs.")
    }
}
```

- [ ] **Step 2: Run the targeted sheet-copy test**

Run: `xcodebuild test -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' -only-testing:CamperReadyTests/SheetHeaderCopyTests`

Expected: FAIL because `SheetCopy` does not exist yet.

- [ ] **Step 3: Add a tiny shared copy helper and apply the new sheet styling**

```swift
enum SheetCopy {
    static let vehicleProfileSubtitle = "Pflege hier die Basisdaten, Gewichte und Intervalle deines Fahrzeugs."
}
```

```swift
RoadSheetScaffold(
    eyebrow: "Fahrzeug",
    title: vehicle == nil ? "Neues Fahrzeug" : "Fahrzeug bearbeiten",
    subtitle: SheetCopy.vehicleProfileSubtitle,
    systemImage: "car.circle"
) {
    Form {
        sectionOne
        sectionTwo
    }
}
```

- [ ] **Step 4: Remove leftover old-card styling inside the inline forms**

```swift
Section {
    TextField("Titel", text: $draft.title)
        .textFieldStyle(.plain)
        .padding(12)
        .background(AppTheme.surfaceLow, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
}
```

- [ ] **Step 5: Run the full verification pass**

Run: `xcodebuild build -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1'`

Run: `xcodebuild test -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1'`

Expected: PASS, with no compile regressions and all presentation tests green.

- [ ] **Step 6: Commit the final polish**

```bash
git add CamperReady CamperReadyTests
git commit -m "feat: finish stitch redesign polish"
```

## Self-Review

### Spec coverage
- Shared palette, surfaces, and spacing: covered by Task 1
- Home from dashboard-card mosaic to calm cockpit: covered by Task 2
- Weight from mixed cards to technical focus layout: covered by Task 3
- Checklists from card-heavy flow to active work mode: covered by Task 4
- Garage / vehicle selection from utility list to fleet-style selection: covered by Task 5
- Logbook and Costs from mixed cards to editorial summary pattern: covered by Task 6
- Forms and sheets finishing pass: covered by Task 7

### Placeholder scan
- No `TODO`, `TBD`, or "similar to above" placeholders remain.
- Every task includes an explicit file list, commands, and concrete code.

### Type consistency
- Shared helper names remain consistent across tasks:
  - `AlpineSurfaceRole`
  - `AlpineSurfaceMetrics`
  - `HomeDashboardPresentation`
  - `WeightPresentation`
  - `ChecklistPresentation`
  - `GaragePresentation`
  - `LogbookPresentation`
  - `CostsPresentation`
