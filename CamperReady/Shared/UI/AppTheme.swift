import SwiftUI

enum AppTheme {
    // Primary accent: ruhiges Petrol mit genügend Sättigung für klare Akzente
    static let accent = Color(red: 0.07, green: 0.45, blue: 0.63)
    static let accentSoft = Color(red: 0.61, green: 0.74, blue: 0.82)
    static let accentWarm = Color(red: 0.94, green: 0.56, blue: 0.37)

    // Ruhiger Canvas ohne Deko-Layer
    static let canvas = Color(red: 0.97, green: 0.98, blue: 0.99)
    static let surface = Color.white
    static let subtleBorder = Color.black.opacity(0.04)

    static let ink = Color(red: 0.09, green: 0.11, blue: 0.14)
    static let mutedInk = Color(red: 0.36, green: 0.38, blue: 0.40)
    static let green = Color(red: 0.14, green: 0.70, blue: 0.39)
    static let yellow = Color(red: 0.98, green: 0.74, blue: 0.05)
    static let red = Color(red: 0.90, green: 0.28, blue: 0.22)
    static let asphalt = Color(red: 0.16, green: 0.18, blue: 0.22)

    static let canvasGradient = LinearGradient(
        colors: [canvas, Color.white],
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
            AppTheme.canvas
                .ignoresSafeArea()
            content
        }
        .tint(AppTheme.accent)
    }
}

// Legacy glassCard entfernt – bewusst keine überdekorierten Karten mehr
