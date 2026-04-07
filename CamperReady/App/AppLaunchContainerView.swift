import SwiftUI

struct AppLaunchContainerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var launchSession: AppLaunchSession

    @MainActor
    init() {
        _launchSession = StateObject(wrappedValue: AppLaunchSession())
    }

    @MainActor
    init(launchSession: AppLaunchSession) {
        _launchSession = StateObject(wrappedValue: launchSession)
    }

    var body: some View {
        ZStack {
            if launchSession.isReady {
                RootTabView()
                    .transition(.opacity)
            } else {
                StartscreenView()
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: AppLaunchTiming.fadeDurationSeconds), value: launchSession.isReady)
        .task {
            await launchSession.start(reduceMotion: reduceMotion)
        }
    }
}
