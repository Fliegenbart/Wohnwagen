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
            VStack(alignment: .leading, spacing: 12) {
                if let subtitle, !subtitle.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 20, weight: .semibold, design: .default))
                            .tracking(-0.2)
                            .foregroundStyle(AppTheme.ink)

                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                } else {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .tracking(-0.2)
                        .foregroundStyle(AppTheme.ink)
                }
                content
            }
        }
        .accessibilityElement(children: .contain)
    }
}
