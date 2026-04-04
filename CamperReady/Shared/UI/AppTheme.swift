import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.16, green: 0.50, blue: 0.85)
    static let canvasTop = Color(red: 0.95, green: 0.93, blue: 0.89)
    static let canvasBottom = Color(red: 0.82, green: 0.87, blue: 0.92)
    static let cardFill = Color.white.opacity(0.72)
    static let cardBorder = Color.white.opacity(0.55)
    static let ink = Color(red: 0.10, green: 0.11, blue: 0.12)
    static let mutedInk = Color(red: 0.35, green: 0.37, blue: 0.39)
    static let green = Color(red: 0.24, green: 0.60, blue: 0.34)
    static let yellow = Color(red: 0.84, green: 0.56, blue: 0.13)
    static let red = Color(red: 0.80, green: 0.30, blue: 0.22)
    static let asphalt = Color(red: 0.20, green: 0.22, blue: 0.25)
    static let metal = Color(red: 0.50, green: 0.56, blue: 0.61)
    static let sand = Color(red: 0.79, green: 0.72, blue: 0.59)
    static let sky = Color(red: 0.72, green: 0.83, blue: 0.92)

    static let canvasGradient = LinearGradient(
        colors: [canvasTop, canvasBottom, sky.opacity(0.85)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let roadHeroGradient = LinearGradient(
        colors: [
            Color(red: 0.67, green: 0.79, blue: 0.88),
            Color(red: 0.54, green: 0.64, blue: 0.69),
            Color(red: 0.23, green: 0.24, blue: 0.27),
            Color(red: 0.14, green: 0.14, blue: 0.15)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let roadFogGradient = LinearGradient(
        colors: [Color.white.opacity(0.30), Color.clear, Color.black.opacity(0.24)],
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
            LinearGradient(colors: [green.opacity(0.96), Color(red: 0.44, green: 0.73, blue: 0.48)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .yellow:
            LinearGradient(colors: [yellow.opacity(0.94), Color(red: 0.93, green: 0.73, blue: 0.31)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .red:
            LinearGradient(colors: [red.opacity(0.95), Color(red: 0.90, green: 0.48, blue: 0.36)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
                    .fill(AppTheme.accent.opacity(0.10))
                    .frame(width: 360, height: 360)
                    .blur(radius: 40)
                    .offset(x: 140, y: -130)
                Circle()
                    .fill(AppTheme.sand.opacity(0.14))
                    .frame(width: 260, height: 260)
                    .blur(radius: 34)
                    .offset(x: -130, y: 10)
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
