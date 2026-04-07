# CamperReady Startscreen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a brief, premium startscreen that appears on every cold app launch, then fades into the existing onboarding-or-cockpit flow without changing the routing rules.

**Architecture:** Keep `RootTabView` as the source of truth for onboarding and active-vehicle routing. Add a small app-launch container above it in `CamperReadyApp.swift` that shows a dedicated startscreen view for a short fixed duration, then fades it out. Keep the copy and timing in tiny shared helpers so the screen is easy to tune and unit test.

**Tech Stack:** SwiftUI, SwiftData, XCTest, `xcodebuild`

---

## File Map

- Create: `CamperReady/App/AppLaunchCopy.swift`
  Purpose: centralize the short brand-first startscreen copy.
- Create: `CamperReady/App/AppLaunchTiming.swift`
  Purpose: centralize the short display duration and fade timing.
- Create: `CamperReady/App/StartscreenView.swift`
  Purpose: render the short branded launch surface with minimal motion.
- Create: `CamperReady/App/AppLaunchContainerView.swift`
  Purpose: overlay the startscreen above the existing root flow and dismiss it automatically.
- Modify: `CamperReady/App/CamperReadyApp.swift`
  Purpose: point the app entry at the new launch container instead of `RootTabView` directly.
- Test: `CamperReadyTests/StartscreenTests.swift`
  Purpose: lock down the brand copy and launch timing.

## Task 1: Add the launch copy and timing helpers

**Files:**
- Create: `CamperReady/App/AppLaunchCopy.swift`
- Create: `CamperReady/App/AppLaunchTiming.swift`
- Create: `CamperReadyTests/StartscreenTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import CamperReady

final class StartscreenTests: XCTestCase {
    func testLaunchCopyStaysBrandFirstAndMinimal() {
        XCTAssertEqual(AppLaunchCopy.title, "CamperReady")
        XCTAssertEqual(AppLaunchCopy.subtitle, "Bereit fuer die Abfahrt.")
        XCTAssertEqual(AppLaunchTiming.holdDurationSeconds, 0.85, accuracy: 0.0001)
    }
}
```

- [ ] **Step 2: Run the targeted test and confirm it fails**

Run:

```bash
xcodebuild test -project CamperReady.xcodeproj -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' -only-testing:CamperReadyTests/StartscreenTests
```

Expected: FAIL because `AppLaunchCopy` and `AppLaunchTiming` do not exist yet.

- [ ] **Step 3: Add the minimal helpers**

```swift
import Foundation

enum AppLaunchCopy {
    static let title = "CamperReady"
    static let subtitle = "Bereit fuer die Abfahrt."
}
```

```swift
import Foundation

enum AppLaunchTiming {
    static let holdDurationSeconds: TimeInterval = 0.85
    static let fadeDurationSeconds: TimeInterval = 0.35
}
```

- [ ] **Step 4: Run the targeted test again and confirm it passes**

Run:

```bash
xcodebuild test -project CamperReady.xcodeproj -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' -only-testing:CamperReadyTests/StartscreenTests
```

Expected: PASS with 1 test, 0 failures.

- [ ] **Step 5: Commit the helpers**

```bash
git add CamperReady/App/AppLaunchCopy.swift CamperReady/App/AppLaunchTiming.swift CamperReadyTests/StartscreenTests.swift
git commit -m "feat: add launch copy helpers"
```

## Task 2: Build the startscreen and wire it into the app entry

**Files:**
- Create: `CamperReady/App/StartscreenView.swift`
- Create: `CamperReady/App/AppLaunchContainerView.swift`
- Modify: `CamperReady/App/CamperReadyApp.swift`

- [ ] **Step 1: Add the launch container and the startscreen**

```swift
import SwiftUI

struct AppLaunchContainerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShowingLaunchScreen = true
    @State private var didStartLaunch = false

    var body: some View {
        ZStack {
            RootTabView()
                .opacity(isShowingLaunchScreen ? 0.01 : 1)
                .accessibilityHidden(isShowingLaunchScreen)

            if isShowingLaunchScreen {
                StartscreenView()
                    .transition(.opacity)
            }
        }
        .task {
            guard !didStartLaunch else { return }
            didStartLaunch = true

            let hold = reduceMotion ? 0.35 : AppLaunchTiming.holdDurationSeconds
            try? await Task.sleep(nanoseconds: UInt64(hold * 1_000_000_000))

            withAnimation(.easeOut(duration: AppLaunchTiming.fadeDurationSeconds)) {
                isShowingLaunchScreen = false
            }
        }
    }
}
```

```swift
import SwiftUI

struct StartscreenView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAppeared = false
    @State private var pulse = false

    var body: some View {
        AppCanvas {
            ZStack {
                LinearGradient(
                    colors: [
                        AppTheme.canvas,
                        AppTheme.sand.opacity(0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 12) {
                        Text(AppLaunchCopy.title)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .tracking(-0.8)

                        Text(AppLaunchCopy.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.mutedInk)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(isAppeared ? 1 : 0)
                    .offset(y: isAppeared ? 0 : 10)
                    .accessibilityElement(children: .combine)

                    Spacer()

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(AppTheme.petrol.opacity(0.12))
                        .frame(width: 128, height: 3)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                .fill(AppTheme.petrol)
                                .frame(width: 42, height: 3)
                                .offset(x: pulse ? 86 : 0)
                                .animation(
                                    pulse
                                        ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                                        : .default,
                                    value: pulse
                                )
                        }
                        .opacity(isAppeared ? 1 : 0)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 40)
            }
        }
        .task {
            if reduceMotion {
                isAppeared = true
                pulse = true
            } else {
                withAnimation(.easeOut(duration: 0.55)) {
                    isAppeared = true
                }
                pulse = true
            }
        }
    }
}
```

```swift
import SwiftData
import SwiftUI

@main
struct CamperReadyApp: App {
    private let bootstrap: PersistenceBootstrap
    @StateObject private var persistenceStatus: PersistenceStatus
    @StateObject private var activeVehicleStore = ActiveVehicleStore()

    init() {
        let bootstrap = PersistenceController.makeProductionBootstrap()
        self.bootstrap = bootstrap
        _persistenceStatus = StateObject(wrappedValue: PersistenceStatus(warningMessage: bootstrap.warningMessage))
    }

    var body: some Scene {
        WindowGroup {
            AppLaunchContainerView()
                .environmentObject(persistenceStatus)
                .environmentObject(activeVehicleStore)
        }
        .modelContainer(bootstrap.container)
    }
}
```

- [ ] **Step 2: Verify the app still respects the existing start flow**

Keep `RootTabView` unchanged so its current onboarding and vehicle-selection rules still run after the startscreen fades:

```swift
.fullScreenCover(isPresented: $showOnboarding) {
    FirstRunOnboardingView(
        isPresented: $showOnboarding,
        hasDismissedOnboarding: $hasDismissedOnboarding
    )
}
.fullScreenCover(
    isPresented: Binding(
        get: { !showOnboarding && activeVehicleStore.needsSelection },
        set: { _ in }
    )
) {
    VehicleSelectionView()
}
```

- [ ] **Step 3: Run the full build and a launch-focused test pass**

Run:

```bash
xcodebuild build -project CamperReady.xcodeproj -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1'
```

Run:

```bash
xcodebuild test -project CamperReady.xcodeproj -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1'
```

Expected: PASS, with the new launch copy test included.

- [ ] **Step 4: Commit the launch UI**

```bash
git add CamperReady/App/CamperReadyApp.swift CamperReady/App/AppLaunchContainerView.swift CamperReady/App/StartscreenView.swift
git commit -m "feat: add branded launch screen"
```

## Task 3: Verify the handoff on device and finish

**Files:**
- Review the new app launch files in `CamperReady/App`
- Review `CamperReadyTests/StartscreenTests.swift`

- [ ] **Step 1: Check the simulator launch path**

Run the app in the Simulator and confirm:
- the startscreen appears first
- it fades away quickly
- the user lands in the correct existing flow afterward
- no extra onboarding or selection regressions were introduced

- [ ] **Step 2: Run the final repository-wide test pass**

Run:

```bash
xcodebuild test -project CamperReady.xcodeproj -scheme CamperReady -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1'
```

Expected: PASS, no new warnings from the startscreen change.

- [ ] **Step 3: Commit the final polish if any follow-up tweaks were needed**

```bash
git add CamperReady CamperReadyTests
git commit -m "feat: finish startscreen polish"
```

## Self-Review

- The spec requirement is covered: the screen is short, branded, and shown on every cold launch.
- The existing onboarding and vehicle selection flow is preserved by keeping `RootTabView` in charge of routing.
- The plan has a failing test before production code.
- The plan avoids placeholders and keeps the scope to one feature.
- The file boundaries are small: one helper for copy, one for timing, one container, one screen, one app entry change.
