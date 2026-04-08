import SwiftUI

struct StartscreenView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var highlightVisible = false

    var body: some View {
        AppCanvas {
            VStack(spacing: 18) {
                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    Text(AppLaunchCopy.title)
                        .font(.system(size: 34, weight: .semibold, design: .default))
                        .tracking(0.2)
                        .foregroundStyle(AppTheme.ink)

                    Text(AppLaunchCopy.subtitle)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppTheme.mutedInk)
                }

                loaderLine

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 40)
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
            .fill(AppTheme.ink.opacity(0.06))
            .frame(width: 92, height: 2)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.ink.opacity(0.22))
                    .frame(width: 24, height: 2)
                    .opacity(highlightVisible ? 0.78 : 0.28)
            }
    }
}
