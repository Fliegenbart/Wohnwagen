import SwiftUI

enum ScenicCardEmphasis {
    case hero
    case support
}

enum ScenicCardSizeClass {
    case regular
    case compact
    case vertical
}

struct ScenicCardLayout: Equatable {
    let sizeClass: ScenicCardSizeClass
    let titleSize: CGFloat
    let artworkSize: CGSize
    let containerSize: CGSize
    let minimumHeight: CGFloat

    var prefersVertical: Bool {
        sizeClass == .vertical
    }

    static func metrics(forScreenWidth width: CGFloat, emphasis: ScenicCardEmphasis) -> ScenicCardLayout {
        switch emphasis {
        case .hero:
            if width <= 320 {
                return ScenicCardLayout(
                    sizeClass: .vertical,
                    titleSize: 20,
                    artworkSize: CGSize(width: 232, height: 140),
                    containerSize: CGSize(width: 248, height: 148),
                    minimumHeight: 246
                )
            } else if width < 402 {
                return ScenicCardLayout(
                    sizeClass: .compact,
                    titleSize: 20,
                    artworkSize: CGSize(width: 122, height: 94),
                    containerSize: CGSize(width: 134, height: 100),
                    minimumHeight: 140
                )
            } else {
                return ScenicCardLayout(
                    sizeClass: .regular,
                    titleSize: 22,
                    artworkSize: CGSize(width: 148, height: 110),
                    containerSize: CGSize(width: 160, height: 116),
                    minimumHeight: 146
                )
            }
        case .support:
            if width <= 320 {
                return ScenicCardLayout(
                    sizeClass: .vertical,
                    titleSize: 20,
                    artworkSize: CGSize(width: 236, height: 144),
                    containerSize: CGSize(width: 252, height: 152),
                    minimumHeight: 250
                )
            } else if width < 402 {
                return ScenicCardLayout(
                    sizeClass: .compact,
                    titleSize: 20,
                    artworkSize: CGSize(width: 128, height: 96),
                    containerSize: CGSize(width: 140, height: 104),
                    minimumHeight: 148
                )
            } else {
                return ScenicCardLayout(
                    sizeClass: .regular,
                    titleSize: 22,
                    artworkSize: CGSize(width: 156, height: 116),
                    containerSize: CGSize(width: 168, height: 120),
                    minimumHeight: 152
                )
            }
        }
    }
}

struct ZipTopBar<Trailing: View>: View {
    let trailing: Trailing
    let onMenuTap: () -> Void

    init(@ViewBuilder trailing: () -> Trailing, onMenuTap: @escaping () -> Void) {
        self.trailing = trailing()
        self.onMenuTap = onMenuTap
    }

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onMenuTap) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.petrol)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.surfaceRaised, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(AppTheme.outlineVariant.opacity(0.6), lineWidth: 1)
                    }
            }
            .accessibilityLabel("Menü")

            Text("CamperReady")
                .font(.system(size: 21, weight: .semibold, design: .default))
                .foregroundStyle(AppTheme.ink)
                .tracking(-0.3)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 8)

            trailing
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(AppTheme.surface.opacity(0.96))
        .overlay(alignment: .bottom) {
            Divider()
                .opacity(0.08)
        }
    }
}

struct ZipBottomNavigationBar: View {
    @Binding var selectedTab: AppTab
    let onAddTap: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            HStack(spacing: 8) {
                ForEach(AppTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 16, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 10, weight: .bold, design: .default))
                                .textCase(.uppercase)
                                .tracking(0.7)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .foregroundStyle(selectedTab == tab ? AppTheme.petrol : AppTheme.mutedInk)
                        .background {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AppTheme.petrol.opacity(0.10))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(AppTheme.petrol.opacity(0.12), lineWidth: 1)
                                    }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(AppTheme.surface.opacity(0.98), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(AppTheme.outlineVariant.opacity(0.55), lineWidth: 1)
            }
            .shadow(color: AppTheme.ink.opacity(0.04), radius: 10, x: 0, y: 4)

            Button(action: onAddTap) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.petrol)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    }
                    .shadow(color: AppTheme.ink.opacity(0.10), radius: 6, x: 0, y: 4)
            }
            .offset(x: -10, y: -8)
            .accessibilityLabel("Neue Aufgabe")
        }
    }
}

struct ZipStatusPill: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.system(size: 9, weight: .semibold, design: .default))
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(tint)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.surfaceRaised)
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(tint.opacity(0.18), lineWidth: 1)
            }
    }
}

struct ZipAvatarBubble: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(AppTheme.petrol)
            .frame(width: 38, height: 38)
            .background(AppTheme.surfaceRaised, in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(AppTheme.outlineVariant.opacity(0.6), lineWidth: 1)
            }
    }
}

struct ZipProgressRing: View {
    let progress: Double
    let text: String
    let accent: Color
    let size: CGFloat

    init(progress: Double, text: String, accent: Color, size: CGFloat = 96) {
        self.progress = progress
        self.text = text
        self.accent = accent
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.surfaceHigh, lineWidth: 10)
            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(accent, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(-90))
            Text(text)
                .font(.system(size: size * 0.18, weight: .semibold, design: .default))
                .foregroundStyle(AppTheme.petrol)
        }
        .frame(width: size, height: size)
    }
}

struct CamperSilhouetteArtwork: View {
    let accent: Color

    init(accent: Color = .white.opacity(0.15)) {
        self.accent = accent
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 52, style: .continuous)
                .fill(accent.opacity(0.40))
                .frame(width: 220, height: 106)
                .offset(y: 10)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(accent.opacity(0.70))
                .frame(width: 176, height: 74)
                .offset(x: -8, y: -2)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(accent.opacity(0.46))
                .frame(width: 52, height: 34)
                .offset(x: 36, y: -10)

            Circle()
                .fill(accent.opacity(0.72))
                .frame(width: 24, height: 24)
                .offset(x: -58, y: 45)

            Circle()
                .fill(accent.opacity(0.72))
                .frame(width: 24, height: 24)
                .offset(x: 64, y: 45)
        }
    }
}

struct LoadDistributionArtwork: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.skySoft,
                            AppTheme.mintSoft,
                            AppTheme.canvasWarm
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 176)

            Circle()
                .fill(AppTheme.sun.opacity(0.55))
                .frame(width: 72, height: 72)
                .offset(x: 106, y: -46)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.78))
                .frame(width: 230, height: 90)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(AppTheme.outlineVariant.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
                )

            HStack(spacing: 12) {
                loadZone(title: "GARAGE", icon: "shippingbox.fill", color: AppTheme.petrol)
                loadZone(title: "KÜCHE", icon: "fork.knife", color: AppTheme.coral)
                loadZone(title: "WASSER", icon: "drop.fill", color: AppTheme.petrolBright)
            }
            .padding(.horizontal, 24)

            Path { path in
                path.move(to: CGPoint(x: 28, y: 142))
                path.addCurve(to: CGPoint(x: 130, y: 120), control1: CGPoint(x: 56, y: 126), control2: CGPoint(x: 94, y: 108))
                path.addCurve(to: CGPoint(x: 240, y: 150), control1: CGPoint(x: 166, y: 132), control2: CGPoint(x: 204, y: 164))
            }
            .stroke(AppTheme.petrol.opacity(0.18), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            .frame(height: 176)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadZone(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .default))
                .tracking(0.8)
        }
        .foregroundStyle(color)
        .frame(width: 62, height: 62)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(color.opacity(0.18), lineWidth: 1)
        )
    }
}

enum CamperSceneMood {
    case home
    case weight
    case garage
    case logbook
    case costs
    case checklists

    var palette: CamperScenePalette {
        switch self {
        case .home:
            return .init(
                background: [AppTheme.skySoft, AppTheme.mintSoft, AppTheme.canvasWarm],
                sun: AppTheme.sun,
                cloud: Color.white.opacity(0.58),
                hillNear: AppTheme.secondaryFixed.opacity(0.58),
                hillFar: AppTheme.primaryFixed.opacity(0.42),
                road: AppTheme.surfaceHighest.opacity(0.82),
                body: AppTheme.petrol,
                cabin: AppTheme.petrolBright,
                window: AppTheme.sky.opacity(0.82),
                wheel: AppTheme.ink,
                accent: AppTheme.coral,
                accentTwo: AppTheme.sandSoft,
                highlight: Color.white.opacity(0.94)
            )
        case .weight:
            return .init(
                background: [AppTheme.skySoft, AppTheme.mintSoft, AppTheme.canvasWarm],
                sun: AppTheme.sunSoft,
                cloud: Color.white.opacity(0.50),
                hillNear: AppTheme.mint.opacity(0.70),
                hillFar: AppTheme.secondaryFixed.opacity(0.38),
                road: AppTheme.surfaceHighest.opacity(0.90),
                body: AppTheme.petrol,
                cabin: AppTheme.petrolBright,
                window: AppTheme.sky.opacity(0.78),
                wheel: AppTheme.ink,
                accent: AppTheme.green,
                accentTwo: AppTheme.sun,
                highlight: Color.white.opacity(0.92)
            )
        case .garage:
            return .init(
                background: [AppTheme.lavenderSoft, AppTheme.skySoft, AppTheme.canvasWarm],
                sun: AppTheme.sunSoft,
                cloud: Color.white.opacity(0.56),
                hillNear: AppTheme.lavender.opacity(0.65),
                hillFar: AppTheme.primaryFixed.opacity(0.40),
                road: AppTheme.surfaceHighest.opacity(0.88),
                body: AppTheme.petrol,
                cabin: AppTheme.petrolBright,
                window: AppTheme.sky.opacity(0.82),
                wheel: AppTheme.ink,
                accent: AppTheme.coral,
                accentTwo: AppTheme.lavender,
                highlight: Color.white.opacity(0.92)
            )
        case .logbook:
            return .init(
                background: [AppTheme.sandSoft.opacity(0.82), AppTheme.coralSoft, AppTheme.canvasWarm],
                sun: AppTheme.sunSoft,
                cloud: Color.white.opacity(0.52),
                hillNear: AppTheme.coral.opacity(0.44),
                hillFar: AppTheme.tertiaryFixed.opacity(0.42),
                road: AppTheme.surfaceHighest.opacity(0.90),
                body: AppTheme.petrol,
                cabin: AppTheme.petrolBright,
                window: AppTheme.sky.opacity(0.80),
                wheel: AppTheme.ink,
                accent: AppTheme.coral,
                accentTwo: AppTheme.sun,
                highlight: Color.white.opacity(0.94)
            )
        case .costs:
            return .init(
                background: [AppTheme.skySoft, AppTheme.sunSoft, AppTheme.canvasWarm],
                sun: AppTheme.sun,
                cloud: Color.white.opacity(0.56),
                hillNear: AppTheme.sunSoft.opacity(0.85),
                hillFar: AppTheme.mint.opacity(0.42),
                road: AppTheme.surfaceHighest.opacity(0.90),
                body: AppTheme.petrol,
                cabin: AppTheme.petrolBright,
                window: AppTheme.sky.opacity(0.82),
                wheel: AppTheme.ink,
                accent: AppTheme.coral,
                accentTwo: AppTheme.green,
                highlight: Color.white.opacity(0.94)
            )
        case .checklists:
            return .init(
                background: [AppTheme.skySoft, AppTheme.mintSoft, AppTheme.lavenderSoft],
                sun: AppTheme.sunSoft,
                cloud: Color.white.opacity(0.56),
                hillNear: AppTheme.secondaryFixed.opacity(0.50),
                hillFar: AppTheme.lavender.opacity(0.48),
                road: AppTheme.surfaceHighest.opacity(0.90),
                body: AppTheme.petrol,
                cabin: AppTheme.petrolBright,
                window: AppTheme.sky.opacity(0.82),
                wheel: AppTheme.ink,
                accent: AppTheme.green,
                accentTwo: AppTheme.sun,
                highlight: Color.white.opacity(0.94)
            )
        }
    }
}

struct CamperScenePalette {
    let background: [Color]
    let sun: Color
    let cloud: Color
    let hillNear: Color
    let hillFar: Color
    let road: Color
    let body: Color
    let cabin: Color
    let window: Color
    let wheel: Color
    let accent: Color
    let accentTwo: Color
    let highlight: Color
}

struct CamperSceneArtwork: View {
    let mood: CamperSceneMood

    init(mood: CamperSceneMood) {
        self.mood = mood
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let palette = mood.palette
            let radius = min(size.width, size.height) * 0.18

            ZStack {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: palette.background,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(palette.sun.opacity(0.88))
                    .frame(width: size.width * 0.24, height: size.width * 0.24)
                    .offset(x: size.width * 0.25, y: -size.height * 0.28)

                Ellipse()
                    .fill(palette.cloud.opacity(0.90))
                    .frame(width: size.width * 0.22, height: size.height * 0.10)
                    .offset(x: -size.width * 0.22, y: -size.height * 0.27)

                Ellipse()
                    .fill(palette.cloud.opacity(0.72))
                    .frame(width: size.width * 0.14, height: size.height * 0.07)
                    .offset(x: -size.width * 0.03, y: -size.height * 0.31)

                HillShape(peaks: [
                    CGPoint(x: 0.0, y: size.height * 0.72),
                    CGPoint(x: 0.24, y: size.height * 0.56),
                    CGPoint(x: 0.52, y: size.height * 0.68),
                    CGPoint(x: 0.82, y: size.height * 0.50),
                    CGPoint(x: 1.0, y: size.height * 0.62)
                ])
                .fill(palette.hillFar)

                HillShape(peaks: [
                    CGPoint(x: 0.0, y: size.height * 0.82),
                    CGPoint(x: 0.18, y: size.height * 0.64),
                    CGPoint(x: 0.47, y: size.height * 0.80),
                    CGPoint(x: 0.72, y: size.height * 0.60),
                    CGPoint(x: 1.0, y: size.height * 0.72)
                ])
                .fill(palette.hillNear)

                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)

                Path { path in
                    path.move(to: CGPoint(x: size.width * 0.12, y: size.height * 0.80))
                    path.addQuadCurve(to: CGPoint(x: size.width * 0.88, y: size.height * 0.80), control: CGPoint(x: size.width * 0.50, y: size.height * 0.58))
                }
                .stroke(palette.road, style: StrokeStyle(lineWidth: max(size.height * 0.06, 6), lineCap: .round))

                Path { path in
                    path.move(to: CGPoint(x: size.width * 0.20, y: size.height * 0.79))
                    path.addQuadCurve(to: CGPoint(x: size.width * 0.80, y: size.height * 0.79), control: CGPoint(x: size.width * 0.50, y: size.height * 0.67))
                }
                .stroke(palette.highlight.opacity(0.65), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 8]))

                camperBody(size: size, palette: palette)
                    .offset(y: size.height * 0.03)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
    }

    @ViewBuilder
    private func camperBody(size: CGSize, palette: CamperScenePalette) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: size.width * 0.08, style: .continuous)
                .fill(Color.white.opacity(0.88))
                .frame(width: size.width * 0.46, height: size.height * 0.25)
                .overlay(
                    RoundedRectangle(cornerRadius: size.width * 0.08, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.42), lineWidth: 1)
                )

            RoundedRectangle(cornerRadius: size.width * 0.07, style: .continuous)
                .fill(palette.cabin.opacity(0.94))
                .frame(width: size.width * 0.20, height: size.height * 0.20)
                .offset(x: size.width * 0.26, y: -size.height * 0.01)

            RoundedRectangle(cornerRadius: size.width * 0.03, style: .continuous)
                .fill(palette.window.opacity(0.92))
                .frame(width: size.width * 0.11, height: size.height * 0.08)
                .offset(x: size.width * 0.31, y: -size.height * 0.005)

            RoundedRectangle(cornerRadius: size.width * 0.028, style: .continuous)
                .fill(palette.window.opacity(0.70))
                .frame(width: size.width * 0.08, height: size.height * 0.07)
                .offset(x: size.width * 0.12, y: -size.height * 0.005)

            RoundedRectangle(cornerRadius: size.width * 0.012, style: .continuous)
                .fill(palette.accent.opacity(0.92))
                .frame(width: size.width * 0.11, height: 4)
                .offset(x: size.width * 0.08, y: -size.height * 0.085)

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(palette.wheel)
                .frame(width: size.width * 0.08, height: size.width * 0.08)
                .offset(x: size.width * 0.09, y: size.height * 0.06)

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(palette.wheel)
                .frame(width: size.width * 0.08, height: size.width * 0.08)
                .offset(x: size.width * 0.29, y: size.height * 0.06)

            Circle()
                .fill(palette.accentTwo.opacity(0.88))
                .frame(width: size.width * 0.035, height: size.width * 0.035)
                .offset(x: size.width * 0.40, y: -size.height * 0.085)
        }
        .frame(width: size.width, height: size.height)
    }
}

struct CamperSceneCard: View {
    let mood: CamperSceneMood
    let eyebrow: String
    let title: String
    let subtitle: String
    let badge: String?

    init(mood: CamperSceneMood, eyebrow: String, title: String, subtitle: String, badge: String? = nil) {
        self.mood = mood
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
    }

    var body: some View {
        let layout = ScenicCardLayout.metrics(forScreenWidth: UIScreen.main.bounds.width, emphasis: .support)

        AlpineSurface(role: .raised) {
            Group {
                if layout.prefersVertical {
                    VStack(alignment: .leading, spacing: 14) {
                        textContent(layout: layout)
                        artworkContainer(layout: layout)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                } else {
                    HStack(alignment: .center, spacing: 14) {
                        textContent(layout: layout)
                        Spacer(minLength: 0)
                        artworkContainer(layout: layout)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: layout.minimumHeight, alignment: .leading)
        }
    }

    private func textContent(layout: ScenicCardLayout) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(0.9)
                    .foregroundStyle(AppTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Spacer(minLength: 8)
                if let badge {
                    ZipStatusPill(title: badge, tint: AppTheme.petrol)
                }
            }

            Text(title)
                .font(.system(size: layout.titleSize, weight: .semibold, design: .default))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(layout.prefersVertical ? 3 : 2)
                .minimumScaleFactor(0.84)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(layout.prefersVertical ? nil : 4)
        }
    }

    private func artworkContainer(layout: ScenicCardLayout) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            mood.palette.background[0].opacity(0.72),
                            mood.palette.background[1].opacity(0.62),
                            mood.palette.background[2].opacity(0.56)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(mood.palette.sun.opacity(0.28))
                .frame(width: layout.prefersVertical ? 56 : 48, height: layout.prefersVertical ? 56 : 48)
                .offset(x: layout.prefersVertical ? 54 : 38, y: -28)

            Circle()
                .fill(mood.palette.accent.opacity(0.18))
                .frame(width: layout.prefersVertical ? 38 : 34, height: layout.prefersVertical ? 38 : 34)
                .offset(x: layout.prefersVertical ? -56 : -48, y: 34)

            CamperSceneArtwork(mood: mood)
                .frame(width: layout.artworkSize.width, height: layout.artworkSize.height)
                .shadow(color: AppTheme.ink.opacity(0.08), radius: 12, x: 0, y: 8)
                .padding(6)
        }
        .frame(width: layout.containerSize.width, height: layout.containerSize.height)
    }
}

private struct HillShape: Shape {
    let peaks: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = peaks.first else { return path }

        func point(_ normalized: CGPoint) -> CGPoint {
            CGPoint(
                x: rect.minX + normalized.x * rect.width,
                y: rect.minY + normalized.y
            )
        }

        path.move(to: point(first))
        for index in 1..<peaks.count {
            let previous = point(peaks[index - 1])
            let current = point(peaks[index])
            let midX = (previous.x + current.x) / 2
            path.addQuadCurve(
                to: current,
                control: CGPoint(x: midX, y: min(previous.y, current.y) - rect.height * 0.18)
            )
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
