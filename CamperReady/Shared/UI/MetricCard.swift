import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedInk)
                Spacer()
                Circle()
                    .fill(AppTheme.accent.opacity(0.14))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: systemImage)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                    }
            }
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22, strokeColor: AppTheme.panelHairline)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}
