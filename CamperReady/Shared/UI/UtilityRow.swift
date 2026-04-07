import SwiftUI

struct UtilityRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let titleColor: Color
    let subtitleColor: Color
    let trailingSystemImage: String?
    let trailingTint: Color?

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        titleColor: Color = AppTheme.ink,
        subtitleColor: Color = AppTheme.mutedInk,
        trailingSystemImage: String? = nil,
        trailingTint: Color? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.titleColor = titleColor
        self.subtitleColor = subtitleColor
        self.trailingSystemImage = trailingSystemImage
        self.trailingTint = trailingTint
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

            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(trailingTint ?? tint)
            }
        }
        .padding(.vertical, 10)
    }
}
