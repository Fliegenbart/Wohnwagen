import SwiftUI

enum AlpineSurfaceRole {
    case section
    case raised
    case focus
}

enum AlpineSurfaceBackground: Equatable {
    case surface
    case surfaceLow
    case surfaceRaised
    case petrol

    var color: Color {
        switch self {
        case .surface:
            AppTheme.surface
        case .surfaceLow:
            AppTheme.surfaceLow
        case .surfaceRaised:
            AppTheme.surfaceRaised
        case .petrol:
            AppTheme.petrol
        }
    }
}

struct AlpineSurfaceMetrics: Equatable {
    let cornerRadius: CGFloat
    let isDark: Bool
    let shadowOpacity: Double

    static func metrics(for role: AlpineSurfaceRole) -> Self {
        AlpineSurfaceStyle.style(for: role).metrics
    }
}

struct AlpineSurfaceStyle: Equatable {
    let role: AlpineSurfaceRole
    let background: AlpineSurfaceBackground
    let metrics: AlpineSurfaceMetrics
    let contentInsets: EdgeInsets
    let shadowRadius: CGFloat
    let shadowYOffset: CGFloat

    static func style(for role: AlpineSurfaceRole) -> Self {
        switch role {
        case .section:
            .init(
                role: role,
                background: .surface,
                metrics: .init(cornerRadius: 24, isDark: false, shadowOpacity: 0.025),
                contentInsets: EdgeInsets(top: 20, leading: 18, bottom: 20, trailing: 18),
                shadowRadius: 10,
                shadowYOffset: 6
            )
        case .raised:
            .init(
                role: role,
                background: .surfaceRaised,
                metrics: .init(cornerRadius: 18, isDark: false, shadowOpacity: 0.035),
                contentInsets: EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15),
                shadowRadius: 8,
                shadowYOffset: 4
            )
        case .focus:
            .init(
                role: role,
                background: .petrol,
                metrics: .init(cornerRadius: 24, isDark: true, shadowOpacity: 0.08),
                contentInsets: EdgeInsets(top: 22, leading: 20, bottom: 22, trailing: 20),
                shadowRadius: 14,
                shadowYOffset: 8
            )
        }
    }
}

struct AlpineSurface<Content: View>: View {
    let role: AlpineSurfaceRole
    let content: Content

    init(role: AlpineSurfaceRole = .section, @ViewBuilder content: () -> Content) {
        self.role = role
        self.content = content()
    }

    var body: some View {
        let style = AlpineSurfaceStyle.style(for: role)
        let shape = RoundedRectangle(cornerRadius: style.metrics.cornerRadius, style: .continuous)
        let borderColor: Color = switch style.role {
        case .section:
            AppTheme.outlineVariant.opacity(0.55)
        case .raised:
            AppTheme.outlineVariant.opacity(0.42)
        case .focus:
            Color.white.opacity(0.08)
        }

        content
            .padding(style.contentInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(style.background.color))
            .shadow(
                color: AppTheme.ink.opacity(style.metrics.shadowOpacity),
                radius: style.shadowRadius,
                x: 0,
                y: style.shadowYOffset
            )
            .overlay {
                shape
                    .strokeBorder(borderColor, lineWidth: 1)
            }
    }
}
