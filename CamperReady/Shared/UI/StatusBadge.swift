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
                .frame(width: 7, height: 7)
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .default))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .textCase(.uppercase)
                .tracking(1.1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
                AppTheme.mintSoft
            case .yellow:
                AppTheme.sunSoft
            case .red:
                AppTheme.coralSoft
            }
        case .dark:
            Color.white.opacity(0.12)
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
            color.opacity(0.18)
        case .dark:
            Color.white.opacity(0.22)
        }
    }

}
