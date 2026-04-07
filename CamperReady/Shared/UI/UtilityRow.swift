import SwiftUI

struct UtilityRowContent: Equatable {
    let title: String
    let subtitle: String
    let systemImage: String
}

struct UtilityRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let titleColor: Color
    let subtitleColor: Color

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        titleColor: Color = AppTheme.ink,
        subtitleColor: Color = AppTheme.mutedInk
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.titleColor = titleColor
        self.subtitleColor = subtitleColor
    }

    init(
        content: UtilityRowContent,
        tint: Color,
        titleColor: Color = AppTheme.ink,
        subtitleColor: Color = AppTheme.mutedInk
    ) {
        self.init(
            title: content.title,
            subtitle: content.subtitle,
            systemImage: content.systemImage,
            tint: tint,
            titleColor: titleColor,
            subtitleColor: subtitleColor
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(titleColor)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(subtitleColor)
            }

            Spacer()
        }
        .padding(.vertical, 10)
    }
}
