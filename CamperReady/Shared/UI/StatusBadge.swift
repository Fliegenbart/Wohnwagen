import SwiftUI

struct StatusBadge: View {
    let status: ReadinessStatus
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .foregroundStyle(color)
        .background(.ultraThinMaterial.opacity(0.65), in: Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.38), lineWidth: 1)
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
