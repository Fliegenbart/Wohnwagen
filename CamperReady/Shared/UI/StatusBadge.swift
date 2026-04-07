import SwiftUI

enum StatusBadgeSurface {
    case light
    case dark
}

struct StatusBadge: View {
    let status: ReadinessStatus
    let text: String
    let surface: StatusBadgeSurface

    init(status: ReadinessStatus, text: String, surface: StatusBadgeSurface = .light) {
        self.status = status
        self.text = text
        self.surface = surface
    }

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
        .foregroundStyle(foregroundColor)
        .background(
            Capsule(style: .continuous)
                .fill(backgroundColor)
        )
        .overlay {
            if let borderColor {
                Capsule(style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status")
        .accessibilityValue(text)
        .accessibilityHint("Zeigt den aktuellen Bereitschaftszustand an.")
    }

    private var color: Color {
        AppTheme.statusColor(status)
    }

    private var backgroundColor: Color {
        switch surface {
        case .light:
            switch status {
            case .green:
                AppTheme.green.opacity(0.12)
            case .yellow:
                AppTheme.sand
            case .red:
                AppTheme.red.opacity(0.12)
            }
        case .dark:
            Color.white.opacity(0.10)
        }
    }

    private var foregroundColor: Color {
        switch surface {
        case .light:
            AppTheme.ink
        case .dark:
            .white
        }
    }

    private var borderColor: Color? {
        switch surface {
        case .light:
            nil
        case .dark:
            Color.white.opacity(0.18)
        }
    }

}
