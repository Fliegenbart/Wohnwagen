import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.18, green: 0.56, blue: 0.64)
    static let accentWarm = Color(red: 0.91, green: 0.53, blue: 0.39)
    static let accentSoft = Color(red: 0.63, green: 0.77, blue: 0.79)
    static let accentSun = Color(red: 0.94, green: 0.77, blue: 0.33)
    static let canvasTop = Color(red: 0.98, green: 0.97, blue: 0.95)
    static let canvasMiddle = Color(red: 0.94, green: 0.96, blue: 0.94)
    static let canvasBottom = Color(red: 0.91, green: 0.94, blue: 0.96)
    static let cardFill = Color.white.opacity(0.76)
    static let cardBorder = Color.white.opacity(0.58)
    static let panelFill = Color(red: 0.98, green: 0.97, blue: 0.95).opacity(0.96)
    static let panelStrong = Color(red: 1.00, green: 0.99, blue: 0.97).opacity(0.99)
    static let panelHairline = Color.white.opacity(0.82)
    static let fieldFill = Color.white.opacity(0.72)
    static let ink = Color(red: 0.11, green: 0.12, blue: 0.13)
    static let mutedInk = Color(red: 0.38, green: 0.39, blue: 0.40)
    static let green = Color(red: 0.12, green: 0.84, blue: 0.45)
    static let yellow = Color(red: 1.00, green: 0.76, blue: 0.05)
    static let red = Color(red: 0.97, green: 0.28, blue: 0.22)
    static let asphalt = Color(red: 0.18, green: 0.20, blue: 0.23)
    static let metal = Color(red: 0.49, green: 0.55, blue: 0.60)
    static let sand = Color(red: 0.78, green: 0.71, blue: 0.58)
    static let sky = Color(red: 0.74, green: 0.82, blue: 0.88)

    static let canvasGradient = LinearGradient(
        colors: [canvasTop, canvasMiddle, canvasBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panelGradient = LinearGradient(
        colors: [panelStrong, Color.white.opacity(0.94), panelFill],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let roadHeroGradient = LinearGradient(
        colors: [
            Color(red: 0.86, green: 0.92, blue: 0.93),
            Color(red: 0.66, green: 0.77, blue: 0.80),
            Color(red: 0.38, green: 0.52, blue: 0.58),
            Color(red: 0.16, green: 0.23, blue: 0.28)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let roadFogGradient = LinearGradient(
        colors: [Color.white.opacity(0.48), accentWarm.opacity(0.12), accent.opacity(0.12), Color.black.opacity(0.16)],
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
            LinearGradient(colors: [green.opacity(0.99), Color(red: 0.48, green: 0.94, blue: 0.62)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .yellow:
            LinearGradient(colors: [yellow.opacity(0.98), Color(red: 1.00, green: 0.90, blue: 0.30)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .red:
            LinearGradient(colors: [red.opacity(0.99), Color(red: 1.00, green: 0.56, blue: 0.30)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
                    .fill(AppTheme.accent.opacity(0.14))
                    .frame(width: 320, height: 320)
                    .blur(radius: 72)
                    .offset(x: 150, y: -180)
                Circle()
                    .fill(AppTheme.accentWarm.opacity(0.12))
                    .frame(width: 260, height: 260)
                    .blur(radius: 58)
                    .offset(x: -110, y: 56)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.34), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 140)
                    .blur(radius: 18)
                Spacer()
            }
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.white.opacity(0.06),
                    Color.clear,
                    AppTheme.accent.opacity(0.06),
                    AppTheme.asphalt.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
                    .fill(AppTheme.panelGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .shadow(color: AppTheme.ink.opacity(0.08), radius: 28, x: 0, y: 14)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 22, strokeColor: Color = AppTheme.cardBorder) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, strokeColor: strokeColor))
    }
}
