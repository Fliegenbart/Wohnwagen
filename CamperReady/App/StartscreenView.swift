import SwiftUI

struct StartscreenView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var highlightVisible = false

    var body: some View {
        AppCanvas {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 12) {
                    Text(AppLaunchCopy.title)
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .tracking(0.4)
                        .foregroundStyle(AppTheme.ink)

                    Text(AppLaunchCopy.subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.mutedInk)
                }

                loaderLine

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .task {
            guard !reduceMotion else {
                highlightVisible = true
                return
            }

            withAnimation(.easeInOut(duration: AppLaunchTiming.fadeDurationSeconds).repeatForever(autoreverses: true)) {
                highlightVisible = true
            }
        }
    }

    private var loaderLine: some View {
        Capsule()
            .fill(AppTheme.ink.opacity(0.08))
            .frame(width: 124, height: 3)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.petrol.opacity(0.82))
                    .frame(width: 52, height: 3)
                    .opacity(highlightVisible ? 1 : 0.42)
            }
    }
}
