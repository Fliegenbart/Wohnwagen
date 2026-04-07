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
        .foregroundStyle(AppTheme.ink)
        .background(
            Capsule(style: .continuous)
                .fill(backgroundColor)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status")
        .accessibilityValue(text)
        .accessibilityHint("Zeigt den aktuellen Bereitschaftszustand an.")
    }

    private var color: Color {
        AppTheme.statusColor(status)
    }

    private var backgroundColor: Color {
        switch status {
        case .green:
            AppTheme.green.opacity(0.12)
        case .yellow:
            AppTheme.sand
        case .red:
            AppTheme.red.opacity(0.12)
        }
    }
}
