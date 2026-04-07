import SwiftUI

enum AppTheme {
    static let canvas = Color(red: 0.976, green: 0.976, blue: 0.973)
    static let surfaceLow = Color(red: 0.953, green: 0.957, blue: 0.953)
    static let surfaceRaised = Color.white
    static let petrol = Color(red: 0.0, green: 0.275, blue: 0.333)
    static let petrolBright = Color(red: 0.0, green: 0.372, blue: 0.451)
    static let sand = Color(red: 0.976, green: 0.941, blue: 0.863)
    static let ink = Color(red: 0.098, green: 0.110, blue: 0.110)
    static let mutedInk = Color(red: 0.36, green: 0.38, blue: 0.40)
    static let green = Color(red: 0.14, green: 0.70, blue: 0.39)
    static let yellow = Color(red: 0.98, green: 0.74, blue: 0.05)
    static let red = Color(red: 0.90, green: 0.28, blue: 0.22)
    static let asphalt = Color(red: 0.16, green: 0.18, blue: 0.22)

    // Bestehende Screens nutzen diese Namen noch außerhalb dieses Tasks.
    static let accent = petrolBright
    static let accentSoft = sand.opacity(0.75)
    static let accentWarm = sand
    static let surface = surfaceRaised
    static let subtleBorder = ink.opacity(0.04)

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
