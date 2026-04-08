import SwiftUI

enum AppTheme {
    static let canvas = Color(red: 0.976, green: 0.976, blue: 0.973)
    static let canvasSoft = Color(red: 0.969, green: 0.973, blue: 0.969)
    static let canvasWarm = Color(red: 0.983, green: 0.970, blue: 0.944)
    static let surface = Color(red: 0.976, green: 0.976, blue: 0.973)
    static let surfaceLow = Color(red: 0.953, green: 0.957, blue: 0.953)
    static let surfaceRaised = Color.white
    static let surfaceHigh = Color(red: 0.906, green: 0.910, blue: 0.906)
    static let surfaceHighest = Color(red: 0.882, green: 0.890, blue: 0.886)
    static let petrol = Color(red: 0.0, green: 0.275, blue: 0.333)
    static let petrolBright = Color(red: 0.0, green: 0.372, blue: 0.451)
    static let petrolSoft = Color(red: 0.176, green: 0.412, blue: 0.471)
    static let sky = Color(red: 0.698, green: 0.922, blue: 1.0)
    static let skySoft = Color(red: 0.875, green: 0.962, blue: 1.0)
    static let mint = Color(red: 0.714, green: 0.937, blue: 0.843)
    static let mintSoft = Color(red: 0.882, green: 0.972, blue: 0.929)
    static let coral = Color(red: 0.988, green: 0.620, blue: 0.506)
    static let coralSoft = Color(red: 1.0, green: 0.871, blue: 0.826)
    static let lavender = Color(red: 0.835, green: 0.792, blue: 1.0)
    static let lavenderSoft = Color(red: 0.938, green: 0.925, blue: 1.0)
    static let sun = Color(red: 1.0, green: 0.859, blue: 0.455)
    static let sunSoft = Color(red: 1.0, green: 0.935, blue: 0.706)
    static let primaryFixed = Color(red: 0.698, green: 0.922, blue: 1.0)
    static let primaryFixedDim = Color(red: 0.545, green: 0.819, blue: 0.909)
    static let secondaryFixed = Color(red: 0.690, green: 0.937, blue: 0.855)
    static let secondaryFixedDim = Color(red: 0.584, green: 0.827, blue: 0.745)
    static let tertiaryFixed = Color(red: 1.0, green: 0.867, blue: 0.714)
    static let tertiaryFixedDim = Color(red: 1.0, green: 0.725, blue: 0.352)
    static let onPrimaryFixed = Color(red: 0.0, green: 0.122, blue: 0.153)
    static let onPrimaryFixedVariant = Color(red: 0.0, green: 0.306, blue: 0.373)
    static let onSecondaryFixed = Color(red: 0.0, green: 0.125, blue: 0.094)
    static let onSecondaryFixedVariant = Color(red: 0.043, green: 0.314, blue: 0.251)
    static let onTertiaryFixed = Color(red: 0.165, green: 0.094, blue: 0.000)
    static let onTertiaryFixedVariant = Color(red: 0.392, green: 0.247, blue: 0.000)
    static let sand = Color(red: 0.976, green: 0.941, blue: 0.863)
    static let sandSoft = Color(red: 1.0, green: 0.867, blue: 0.714)
    static let ink = Color(red: 0.098, green: 0.110, blue: 0.110)
    static let mutedInk = Color(red: 0.36, green: 0.38, blue: 0.40)
    static let outline = Color(red: 0.435, green: 0.475, blue: 0.486)
    static let outlineVariant = Color(red: 0.749, green: 0.784, blue: 0.800)
    static let green = Color(red: 0.14, green: 0.70, blue: 0.39)
    static let greenSoft = Color(red: 0.702, green: 0.933, blue: 0.843)
    static let yellow = Color(red: 0.98, green: 0.74, blue: 0.05)
    static let yellowSoft = Color(red: 1.0, green: 0.867, blue: 0.714)
    static let red = Color(red: 0.90, green: 0.28, blue: 0.22)
    static let redSoft = Color(red: 1.0, green: 0.853, blue: 0.839)
    static let asphalt = Color(red: 0.16, green: 0.18, blue: 0.22)

    // Bestehende Screens nutzen diese Namen noch außerhalb dieses Tasks.
    static let accent = petrolBright
    static let accentSoft = sand.opacity(0.78)
    static let accentWarm = sand
    static let accentSky = sky
    static let subtleBorder = ink.opacity(0.04)

    static let canvasGradient = LinearGradient(
        colors: [canvasWarm, skySoft.opacity(0.42), canvas, Color.white],
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
            LinearGradient(
                colors: [
                    AppTheme.canvasWarm,
                    AppTheme.skySoft.opacity(0.44),
                    AppTheme.canvas,
                    AppTheme.mintSoft.opacity(0.42),
                    AppTheme.canvas
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
                .ignoresSafeArea()

            Circle()
                .fill(AppTheme.primaryFixed.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 56)
                .offset(x: -128, y: -220)
                .allowsHitTesting(false)

            Circle()
                .fill(AppTheme.coral.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 58)
                .offset(x: 160, y: -96)
                .allowsHitTesting(false)

            Circle()
                .fill(AppTheme.secondaryFixed.opacity(0.16))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: 120, y: 320)
                .allowsHitTesting(false)

            Circle()
                .fill(AppTheme.lavender.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 60)
                .offset(x: -180, y: 380)
                .allowsHitTesting(false)

            content
        }
        .tint(AppTheme.accent)
    }
}

// Legacy glassCard entfernt – bewusst keine überdekorierten Karten mehr
