import SwiftUI

struct RoadSheetHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String

    var featureHeader: FeatureHeader {
        FeatureHeader(
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle,
            eyebrowColor: AppTheme.sand.opacity(0.92),
            titleColor: .white,
            subtitleColor: .white.opacity(0.78)
        )
    }

    var utilityRow: UtilityRow {
        UtilityRow(
            title: eyebrow,
            subtitle: subtitle,
            systemImage: systemImage,
            tint: AppTheme.sand,
            titleColor: .white,
            subtitleColor: .white.opacity(0.78)
        )
    }

    var body: some View {
        AlpineSurface(role: .focus) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    featureHeader

                    Spacer()

                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.sand)
                        .padding(14)
                        .background(AppTheme.petrolBright.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                utilityRow
            }
        }
    }
}
