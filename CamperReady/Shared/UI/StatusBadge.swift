import SwiftUI

struct StatusBadge: View {
    let status: ReadinessStatus
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
            Text(text)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .foregroundStyle(color)
        .background(color.opacity(0.12), in: Capsule())
    }

    private var color: Color {
        AppTheme.statusColor(status)
    }
}
