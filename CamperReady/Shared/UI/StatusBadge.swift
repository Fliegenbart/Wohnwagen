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
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 9, weight: .semibold, design: .default))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .textCase(.uppercase)
                .tracking(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
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
            AppTheme.surfaceRaised
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
            color.opacity(0.22)
        case .dark:
            Color.white.opacity(0.16)
        }
    }

}
