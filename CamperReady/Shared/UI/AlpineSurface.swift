import SwiftUI

enum AlpineSurfaceRole {
    case section
    case raised
    case focus
}

enum AlpineSurfaceBackground: Equatable {
    case surfaceLow
    case surfaceRaised
    case petrol

    var color: Color {
        switch self {
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
                background: .surfaceLow,
                metrics: .init(cornerRadius: 28, isDark: false, shadowOpacity: 0.04),
                contentInsets: EdgeInsets(top: 22, leading: 20, bottom: 22, trailing: 20),
                shadowRadius: 16,
                shadowYOffset: 10
            )
        case .raised:
            .init(
                role: role,
                background: .surfaceRaised,
                metrics: .init(cornerRadius: 22, isDark: false, shadowOpacity: 0.05),
                contentInsets: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
                shadowRadius: 14,
                shadowYOffset: 8
            )
        case .focus:
            .init(
                role: role,
                background: .petrol,
                metrics: .init(cornerRadius: 28, isDark: true, shadowOpacity: 0.12),
                contentInsets: EdgeInsets(top: 24, leading: 22, bottom: 24, trailing: 22),
                shadowRadius: 20,
                shadowYOffset: 12
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

        content
            .padding(style.contentInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(style.background.color)
            .clipShape(RoundedRectangle(cornerRadius: style.metrics.cornerRadius, style: .continuous))
            .shadow(
                color: AppTheme.ink.opacity(style.metrics.shadowOpacity),
                radius: style.shadowRadius,
                x: 0,
                y: style.shadowYOffset
            )
            .overlay {
                RoundedRectangle(cornerRadius: style.metrics.cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.outlineVariant.opacity(style.role == .focus ? 0 : 0.14), lineWidth: style.role == .focus ? 0 : 0.75)
            }
    }
}
