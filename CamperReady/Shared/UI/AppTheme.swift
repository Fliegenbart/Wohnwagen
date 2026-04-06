import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.09, green: 0.57, blue: 0.67)
    static let accentWarm = Color(red: 0.92, green: 0.47, blue: 0.23)
    static let accentSoft = Color(red: 0.28, green: 0.69, blue: 0.77)
    static let canvasTop = Color(red: 0.96, green: 0.94, blue: 0.90)
    static let canvasMiddle = Color(red: 0.86, green: 0.90, blue: 0.92)
    static let canvasBottom = Color(red: 0.78, green: 0.84, blue: 0.89)
    static let cardFill = Color.white.opacity(0.64)
    static let cardBorder = Color.white.opacity(0.42)
    static let panelFill = Color(red: 0.98, green: 0.97, blue: 0.95).opacity(0.82)
    static let panelStrong = Color(red: 0.96, green: 0.95, blue: 0.92).opacity(0.94)
    static let panelHairline = Color.white.opacity(0.58)
    static let fieldFill = Color.white.opacity(0.52)
    static let ink = Color(red: 0.11, green: 0.12, blue: 0.13)
    static let mutedInk = Color(red: 0.38, green: 0.39, blue: 0.40)
    static let green = Color(red: 0.18, green: 0.66, blue: 0.42)
    static let yellow = Color(red: 0.90, green: 0.62, blue: 0.16)
    static let red = Color(red: 0.87, green: 0.35, blue: 0.25)
    static let asphalt = Color(red: 0.18, green: 0.20, blue: 0.23)
    static let metal = Color(red: 0.49, green: 0.55, blue: 0.60)
    static let sand = Color(red: 0.78, green: 0.71, blue: 0.58)
    static let sky = Color(red: 0.74, green: 0.82, blue: 0.88)

    static let canvasGradient = LinearGradient(
        colors: [canvasTop, canvasMiddle, canvasBottom, accentSoft.opacity(0.34)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panelGradient = LinearGradient(
        colors: [panelStrong, panelFill],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let roadHeroGradient = LinearGradient(
        colors: [
            Color(red: 0.81, green: 0.84, blue: 0.83),
            Color(red: 0.59, green: 0.73, blue: 0.76),
            Color(red: 0.23, green: 0.34, blue: 0.39),
            Color(red: 0.16, green: 0.13, blue: 0.16)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let roadFogGradient = LinearGradient(
        colors: [Color.white.opacity(0.34), accentSoft.opacity(0.08), Color.black.opacity(0.26)],
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
            LinearGradient(colors: [green.opacity(0.96), Color(red: 0.42, green: 0.82, blue: 0.58)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .yellow:
            LinearGradient(colors: [yellow.opacity(0.94), Color(red: 0.97, green: 0.78, blue: 0.33)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .red:
            LinearGradient(colors: [red.opacity(0.95), Color(red: 0.95, green: 0.54, blue: 0.39)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
                    .frame(width: 360, height: 360)
                    .blur(radius: 48)
                    .offset(x: 150, y: -150)
                Circle()
                    .fill(AppTheme.accentWarm.opacity(0.14))
                    .frame(width: 280, height: 280)
                    .blur(radius: 38)
                    .offset(x: -120, y: 20)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.24), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 180)
                    .blur(radius: 24)
                Spacer()
            }
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.clear,
                    AppTheme.asphalt.opacity(0.08)
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
