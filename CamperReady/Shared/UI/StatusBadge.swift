import SwiftUI

struct StatusBadge: View {
    let status: ReadinessStatus
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.35), lineWidth: 1)
                }
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .textCase(.uppercase)
                .tracking(0.7)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .foregroundStyle(color)
        .background(
            Capsule(style: .continuous)
                .fill(color.opacity(0.18))
                .overlay {
                    Capsule(style: .continuous)
                        .fill(.thinMaterial.opacity(0.26))
                }
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.16), radius: 18, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status")
        .accessibilityValue(text)
        .accessibilityHint("Zeigt den aktuellen Bereitschaftszustand an.")
    }

    private var color: Color {
        AppTheme.statusColor(status)
    }
}
