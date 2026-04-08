import SwiftUI

enum AppTheme {
    static let canvas = Color(red: 0.965, green: 0.968, blue: 0.963)
    static let canvasSoft = Color(red: 0.954, green: 0.959, blue: 0.954)
    static let canvasWarm = Color(red: 0.973, green: 0.969, blue: 0.960)
    static let surface = Color(red: 0.984, green: 0.985, blue: 0.982)
    static let surfaceLow = Color(red: 0.961, green: 0.965, blue: 0.960)
    static let surfaceRaised = Color(red: 0.992, green: 0.993, blue: 0.991)
    static let surfaceHigh = Color(red: 0.934, green: 0.940, blue: 0.936)
    static let surfaceHighest = Color(red: 0.905, green: 0.913, blue: 0.910)
    static let petrol = Color(red: 0.055, green: 0.275, blue: 0.319)
    static let petrolBright = Color(red: 0.141, green: 0.360, blue: 0.402)
    static let petrolSoft = Color(red: 0.302, green: 0.476, blue: 0.505)
    static let sky = Color(red: 0.778, green: 0.858, blue: 0.879)
    static let skySoft = Color(red: 0.902, green: 0.936, blue: 0.943)
    static let mint = Color(red: 0.792, green: 0.866, blue: 0.830)
    static let mintSoft = Color(red: 0.908, green: 0.944, blue: 0.924)
    static let coral = Color(red: 0.804, green: 0.678, blue: 0.631)
    static let coralSoft = Color(red: 0.928, green: 0.895, blue: 0.878)
    static let lavender = Color(red: 0.772, green: 0.768, blue: 0.840)
    static let lavenderSoft = Color(red: 0.914, green: 0.913, blue: 0.938)
    static let sun = Color(red: 0.866, green: 0.744, blue: 0.456)
    static let sunSoft = Color(red: 0.951, green: 0.917, blue: 0.829)
    static let primaryFixed = sky
    static let primaryFixedDim = Color(red: 0.678, green: 0.760, blue: 0.784)
    static let secondaryFixed = mint
    static let secondaryFixedDim = Color(red: 0.709, green: 0.787, blue: 0.753)
    static let tertiaryFixed = Color(red: 0.932, green: 0.842, blue: 0.717)
    static let tertiaryFixedDim = Color(red: 0.851, green: 0.703, blue: 0.482)
    static let onPrimaryFixed = Color(red: 0.098, green: 0.165, blue: 0.196)
    static let onPrimaryFixedVariant = Color(red: 0.208, green: 0.318, blue: 0.345)
    static let onSecondaryFixed = Color(red: 0.110, green: 0.180, blue: 0.149)
    static let onSecondaryFixedVariant = Color(red: 0.220, green: 0.333, blue: 0.286)
    static let onTertiaryFixed = Color(red: 0.216, green: 0.153, blue: 0.071)
    static let onTertiaryFixedVariant = Color(red: 0.424, green: 0.302, blue: 0.184)
    static let sand = Color(red: 0.950, green: 0.922, blue: 0.857)
    static let sandSoft = Color(red: 0.973, green: 0.952, blue: 0.906)
    static let ink = Color(red: 0.122, green: 0.141, blue: 0.149)
    static let mutedInk = Color(red: 0.395, green: 0.424, blue: 0.435)
    static let outline = Color(red: 0.565, green: 0.596, blue: 0.608)
    static let outlineVariant = Color(red: 0.824, green: 0.842, blue: 0.840)
    static let green = Color(red: 0.275, green: 0.602, blue: 0.414)
    static let greenSoft = Color(red: 0.862, green: 0.927, blue: 0.888)
    static let yellow = Color(red: 0.789, green: 0.622, blue: 0.220)
    static let yellowSoft = Color(red: 0.951, green: 0.900, blue: 0.802)
    static let red = Color(red: 0.733, green: 0.365, blue: 0.314)
    static let redSoft = Color(red: 0.952, green: 0.885, blue: 0.867)
    static let asphalt = Color(red: 0.220, green: 0.247, blue: 0.278)

    // Bestehende Screens nutzen diese Namen noch außerhalb dieses Tasks.
    static let accent = petrol
    static let accentSoft = petrolSoft.opacity(0.18)
    static let accentWarm = sand
    static let accentSky = sky
    static let subtleBorder = ink.opacity(0.06)

    static let canvasGradient = LinearGradient(
        colors: [canvasWarm, canvasSoft, canvas, surface],
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
            LinearGradient(colors: [green, greenSoft], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .yellow:
            LinearGradient(colors: [yellow, yellowSoft], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .red:
            LinearGradient(colors: [red, redSoft], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct AppCanvas<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        AppTheme.canvasGradient
            .ignoresSafeArea()
            .overlay {
                content
            }
        .tint(AppTheme.accent)
    }
}

// Legacy glassCard entfernt – bewusst keine überdekorierten Karten mehr
