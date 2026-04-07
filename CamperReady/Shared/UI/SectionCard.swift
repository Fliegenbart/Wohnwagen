import SwiftUI

struct RoadSheetHeaderContent: Equatable {
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String

    var featureHeader: FeatureHeaderContent {
        .init(eyebrow: eyebrow, title: title, subtitle: subtitle)
    }

    var utilityRow: UtilityRowContent {
        .init(title: eyebrow, subtitle: subtitle, systemImage: systemImage)
    }
}

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
    let content: RoadSheetHeaderContent

    init(eyebrow: String, title: String, subtitle: String, systemImage: String) {
        self.content = RoadSheetHeaderContent(
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage
        )
    }

    var body: some View {
        AlpineSurface(role: .focus) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    FeatureHeader(
                        content: content.featureHeader,
                        eyebrowColor: AppTheme.sand.opacity(0.92),
                        titleColor: .white,
                        subtitleColor: .white.opacity(0.78)
                    )

                    Spacer()

                    Image(systemName: content.systemImage)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.sand)
                        .padding(14)
                        .background(AppTheme.petrolBright.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                UtilityRow(
                    content: content.utilityRow,
                    tint: AppTheme.sand,
                    titleColor: .white,
                    subtitleColor: .white.opacity(0.78)
                )
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
