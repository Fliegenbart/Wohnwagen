import SwiftUI

struct FeatureHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.mutedInk)

            Text(title)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)
        }
    }
}
