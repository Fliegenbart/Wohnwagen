import SwiftUI

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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .tracking(0.9)
                .foregroundStyle(eyebrowColor)

            Text(title)
                .font(.system(size: 34, weight: .semibold, design: .default))
                .tracking(-0.6)
                .foregroundStyle(titleColor)
                .lineLimit(3)
                .minimumScaleFactor(0.82)

            Text(subtitle)
                .font(.callout)
                .foregroundStyle(subtitleColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
