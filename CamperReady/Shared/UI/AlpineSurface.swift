import SwiftUI

enum AlpineSurfaceRole {
    case section
    case raised
    case focus
}

struct AlpineSurfaceMetrics: Equatable {
    let cornerRadius: CGFloat
    let isDark: Bool
    let shadowOpacity: Double

    static func metrics(for role: AlpineSurfaceRole) -> Self {
        switch role {
        case .section:
            .init(cornerRadius: 24, isDark: false, shadowOpacity: 0.00)
        case .raised:
            .init(cornerRadius: 20, isDark: false, shadowOpacity: 0.04)
        case .focus:
            .init(cornerRadius: 24, isDark: true, shadowOpacity: 0.08)
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
        let metrics = AlpineSurfaceMetrics.metrics(for: role)

        content
            .padding(contentInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous))
            .shadow(
                color: AppTheme.ink.opacity(metrics.shadowOpacity),
                radius: metrics.isDark ? 18 : 12,
                x: 0,
                y: metrics.isDark ? 12 : 8
            )
    }

    private var backgroundColor: Color {
        switch role {
        case .section:
            AppTheme.surfaceLow
        case .raised:
            AppTheme.surfaceRaised
        case .focus:
            AppTheme.petrol
        }
    }

    private var contentInsets: EdgeInsets {
        switch role {
        case .section:
            EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        case .raised:
            EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        case .focus:
            EdgeInsets(top: 22, leading: 20, bottom: 22, trailing: 20)
        }
    }
}
