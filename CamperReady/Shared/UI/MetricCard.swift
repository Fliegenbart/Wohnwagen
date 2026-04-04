import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedInk)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}
