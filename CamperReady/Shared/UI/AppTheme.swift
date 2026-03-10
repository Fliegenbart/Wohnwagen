import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.07, green: 0.47, blue: 0.94)
    static let canvasTop = Color(red: 0.95, green: 0.96, blue: 0.98)
    static let canvasBottom = Color(red: 0.89, green: 0.92, blue: 0.96)
    static let cardFill = Color.white.opacity(0.78)
    static let cardBorder = Color.white.opacity(0.72)
    static let ink = Color(red: 0.08, green: 0.11, blue: 0.16)
    static let mutedInk = Color(red: 0.35, green: 0.39, blue: 0.46)
    static let green = Color(red: 0.17, green: 0.61, blue: 0.36)
    static let yellow = Color(red: 0.86, green: 0.58, blue: 0.09)
    static let red = Color(red: 0.85, green: 0.27, blue: 0.25)

    static let canvasGradient = LinearGradient(
        colors: [canvasTop, canvasBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func statusColor(_ status: ReadinessStatus) -> Color {
        switch status {
        case .green: green
        case .yellow: yellow
        case .red: red
        }
    }

    static func statusGradient(_ status: ReadinessStatus) -> LinearGradient {
        switch status {
        case .green:
            LinearGradient(colors: [green.opacity(0.92), Color(red: 0.40, green: 0.75, blue: 0.51)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .yellow:
            LinearGradient(colors: [yellow.opacity(0.92), Color(red: 0.95, green: 0.76, blue: 0.33)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .red:
            LinearGradient(colors: [red.opacity(0.94), Color(red: 0.95, green: 0.53, blue: 0.43)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct AppCanvas<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppTheme.canvasGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Circle()
                    .fill(AppTheme.accent.opacity(0.08))
                    .frame(width: 320, height: 320)
                    .blur(radius: 30)
                    .offset(x: 120, y: -120)
                Spacer()
            }
            .ignoresSafeArea()

            content
        }
        .tint(AppTheme.accent)
    }
}

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let strokeColor: Color

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .shadow(color: AppTheme.ink.opacity(0.08), radius: 24, x: 0, y: 12)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 22, strokeColor: Color = AppTheme.cardBorder) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, strokeColor: strokeColor))
    }
}
