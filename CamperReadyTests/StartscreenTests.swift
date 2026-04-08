import XCTest
@testable import CamperReady

final class StartscreenTests: XCTestCase {
    @MainActor
    func testLaunchSessionBecomesReadyAfterInjectedSleepFinishes() async {
        let session = AppLaunchSession { _ in
            await Task.yield()
        }
        let launchTask = Task {
            await session.start(reduceMotion: false)
        }

        let initiallyReady = session.isReady
        let initiallyLaunching = session.isLaunching

        XCTAssertFalse(initiallyReady)
        XCTAssertFalse(initiallyLaunching)

        await Task.yield()
        await launchTask.value

        let finishedReady = session.isReady
        let finishedLaunching = session.isLaunching

        XCTAssertTrue(finishedReady)
        XCTAssertFalse(finishedLaunching)
    }

    @MainActor
    func testLaunchSessionCancellationStopsLaunchingWithoutBecomingReady() async {
        let startedSleeping = expectation(description: "launch started sleeping")

        let session = AppLaunchSession { _ in
            startedSleeping.fulfill()

            while !Task.isCancelled {
                await Task.yield()
            }
        }
        let launchTask = Task {
            await session.start(reduceMotion: false)
        }

        await fulfillment(of: [startedSleeping], timeout: 1.0)

        let launchingBeforeCancel = session.isLaunching
        let readyBeforeCancel = session.isReady

        XCTAssertTrue(launchingBeforeCancel)
        XCTAssertFalse(readyBeforeCancel)

        launchTask.cancel()
        await launchTask.value

        let launchingAfterCancel = session.isLaunching
        let readyAfterCancel = session.isReady

        XCTAssertFalse(launchingAfterCancel)
        XCTAssertFalse(readyAfterCancel)
    }

    func testLaunchCopyAndTimingConstantsMatchSpecification() {
        XCTAssertEqual(AppLaunchCopy.title, "CamperReady")
        XCTAssertEqual(AppLaunchCopy.subtitle, "Alles dabei. Alles bereit.")
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
