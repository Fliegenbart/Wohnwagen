import SwiftUI

struct AppLaunchContainerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsStartscreen = true
    @State private var hasStartedLaunch = false

    var body: some View {
        ZStack {
            RootTabView()

            if showsStartscreen {
                StartscreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            guard !hasStartedLaunch else { return }
            hasStartedLaunch = true
            await dismissStartscreenAfterPause()
        }
    }

    private func dismissStartscreenAfterPause() async {
        let pause = AppLaunchTiming.holdDuration(reduceMotion: reduceMotion)
        let nanoseconds = UInt64(pause * 1_000_000_000)

        try? await Task.sleep(nanoseconds: nanoseconds)

        guard !Task.isCancelled else { return }

        if reduceMotion {
            showsStartscreen = false
            return
        }

        withAnimation(.easeOut(duration: AppLaunchTiming.fadeDurationSeconds)) {
            showsStartscreen = false
        }
    }
}
