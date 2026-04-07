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
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
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
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AppTheme.asphalt.opacity(0.05), radius: 10, x: 0, y: 6)
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
            Capsule()
                .fill(AppTheme.accent.opacity(0.88))
                .frame(width: 68, height: 6)

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(eyebrow)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(14)
                    .background(AppTheme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Text(subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.white.opacity(0.74),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(AppTheme.asphalt.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: AppTheme.ink.opacity(0.06), radius: 16, x: 0, y: 8)
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
