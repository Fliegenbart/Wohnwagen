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
        AlpineSurface(role: .section) {
            VStack(alignment: .leading, spacing: 14) {
                if let subtitle, !subtitle.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.ink)

                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                } else {
                    Text(title)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                }
                content
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct RoadSheetHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        AlpineSurface(role: .focus) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(eyebrow.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.sand.opacity(0.92))
                    Text(title)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.sand)
                    .padding(14)
                    .background(AppTheme.petrolBright.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
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
