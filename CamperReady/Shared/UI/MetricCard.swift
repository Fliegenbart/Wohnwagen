import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedInk)
                Spacer()
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
            }
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.54))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.asphalt.opacity(0.08), lineWidth: 1)
        )
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(AppTheme.accent)
                .frame(width: 34, height: 4)
                .padding(.top, 12)
                .padding(.leading, 18)
        }
        .shadow(color: AppTheme.ink.opacity(0.05), radius: 12, x: 0, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}
