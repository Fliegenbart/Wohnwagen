import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        AlpineSurface(role: .raised) {
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.sky, AppTheme.coral, AppTheme.sun],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 54, height: 4)

                HStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.petrolBright)

                    Text(title)
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.6)
                        .foregroundStyle(AppTheme.mutedInk)

                    Spacer()
                }

                Text(value)
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}
