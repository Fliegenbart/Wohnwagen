import SwiftUI

struct StatusBadge: View {
    let status: ReadinessStatus
    let text: String

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .textCase(.uppercase)
                .tracking(0.9)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .foregroundStyle(color)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.22), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status")
        .accessibilityValue(text)
        .accessibilityHint("Zeigt den aktuellen Bereitschaftszustand an.")
    }

    private var color: Color {
        AppTheme.statusColor(status)
    }
}
