import XCTest
@testable import CamperReady

final class StartscreenTests: XCTestCase {
    func testLaunchCopyAndTimingConstantsMatchSpecification() {
        XCTAssertEqual(AppLaunchCopy.title, "CamperReady")
        XCTAssertEqual(AppLaunchCopy.subtitle, "Bereit fuer die Abfahrt.")
        XCTAssertEqual(AppLaunchTiming.holdDurationSeconds, 0.85)
        XCTAssertEqual(AppLaunchTiming.fadeDurationSeconds, 0.35)
    }
}
