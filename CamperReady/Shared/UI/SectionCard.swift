import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentWarm, AppTheme.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 44, height: 4)
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedInk)
                }
            }
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 26, strokeColor: AppTheme.panelHairline)
        .accessibilityElement(children: .contain)
    }
}

struct RoadSheetHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(eyebrow)
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(1.1)
                        .foregroundStyle(.white.opacity(0.76))
                    Text(title)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Text(subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.84))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppTheme.asphalt.opacity(0.95), AppTheme.accent.opacity(0.78), AppTheme.metal.opacity(0.84)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: AppTheme.ink.opacity(0.12), radius: 24, x: 0, y: 12)
    }
}

struct RoadSheetScaffold<Content: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String
    let content: Content

    init(
        eyebrow: String,
        title: String,
        subtitle: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        AppCanvas {
            VStack(spacing: 12) {
                RoadSheetHeader(
                    eyebrow: eyebrow,
                    title: title,
                    subtitle: subtitle,
                    systemImage: systemImage
                )
                content
                    .roadFormSurface()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
    }
}

private struct RoadFormModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(Color.clear)
    }
}

extension View {
    func roadFormSurface() -> some View {
        modifier(RoadFormModifier())
    }
}
