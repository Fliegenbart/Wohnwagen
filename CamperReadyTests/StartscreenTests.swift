import XCTest
@testable import CamperReady

final class StartscreenTests: XCTestCase {
    func testLaunchCopyAndTimingConstantsMatchSpecification() {
        XCTAssertEqual(AppLaunchCopy.title, "CamperReady")
        XCTAssertEqual(AppLaunchCopy.subtitle, "Bereit fuer die Abfahrt.")
        XCTAssertEqual(AppLaunchTiming.holdDurationSeconds, 0.85)
        XCTAssertEqual(AppLaunchTiming.fadeDurationSeconds, 0.35)
    }

    func testLaunchHoldDurationUsesShorterPauseWhenReducedMotionIsEnabled() {
        let defaultDuration = AppLaunchTiming.holdDuration(reduceMotion: false)
        let reducedMotionDuration = AppLaunchTiming.holdDuration(reduceMotion: true)

        XCTAssertEqual(defaultDuration, AppLaunchTiming.holdDurationSeconds)
        XCTAssertLessThan(reducedMotionDuration, defaultDuration)
    }
}
