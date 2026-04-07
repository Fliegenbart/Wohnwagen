import SwiftUI

struct FeatureHeaderContent: Equatable {
    let eyebrow: String
    let title: String
    let subtitle: String
}

struct FeatureHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let eyebrowColor: Color
    let titleColor: Color
    let subtitleColor: Color

    init(
        eyebrow: String,
        title: String,
        subtitle: String,
        eyebrowColor: Color = AppTheme.mutedInk,
        titleColor: Color = AppTheme.ink,
        subtitleColor: Color = AppTheme.mutedInk
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.eyebrowColor = eyebrowColor
        self.titleColor = titleColor
        self.subtitleColor = subtitleColor
    }

    init(
        content: FeatureHeaderContent,
        eyebrowColor: Color = AppTheme.mutedInk,
        titleColor: Color = AppTheme.ink,
        subtitleColor: Color = AppTheme.mutedInk
    ) {
        self.init(
            eyebrow: content.eyebrow,
            title: content.title,
            subtitle: content.subtitle,
            eyebrowColor: eyebrowColor,
            titleColor: titleColor,
            subtitleColor: subtitleColor
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(eyebrowColor)

            Text(title)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(titleColor)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(subtitleColor)
        }
    }
}
