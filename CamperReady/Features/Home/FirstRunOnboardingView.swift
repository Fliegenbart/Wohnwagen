import SwiftUI

struct FirstRunOnboardingItem: Equatable {
    let title: String
    let text: String
    let systemImage: String
    let tintRole: TintRole

    enum TintRole: Equatable {
        case petrol
        case yellow
        case green

        var color: Color {
            switch self {
            case .petrol:
                AppTheme.petrol
            case .yellow:
                AppTheme.yellow
            case .green:
                AppTheme.green
            }
        }
    }
}

struct FirstRunOnboardingStep: Equatable {
    let title: String
    let text: String
}

struct FirstRunOnboardingPresentation: Equatable {
    let headerEyebrow: String
    let headerTitle: String
    let headerSubtitle: String
    let setupTitle: String
    let setupSubtitle: String
    let setupItems: [FirstRunOnboardingItem]
    let stepsTitle: String
    let steps: [FirstRunOnboardingStep]
    let footerNote: String
    let primaryActionTitle: String
    let secondaryActionTitle: String

    static let current = FirstRunOnboardingPresentation(
        headerEyebrow: "Dein Camper, dein Startpunkt",
        headerTitle: "Sag uns kurz, mit wem du unterwegs bist",
        headerSubtitle: "Ein paar Angaben reichen für den Start. Alles Weitere kannst du später ergänzen.",
        setupTitle: "Für den ersten Start wichtig",
        setupSubtitle: "CamperReady braucht nur genug, um direkt mit dem richtigen Fahrzeug weiterzuarbeiten.",
        setupItems: [
            FirstRunOnboardingItem(
                title: "Name und Fahrzeugtyp",
                text: "Damit du deinen Camper sofort wiedererkennst.",
                systemImage: "car.side",
                tintRole: .petrol
            ),
            FirstRunOnboardingItem(
                title: "Wichtige Basisdaten",
                text: "Wenn du schon etwas weißt, kannst du es direkt eintragen.",
                systemImage: "square.and.pencil",
                tintRole: .yellow
            ),
            FirstRunOnboardingItem(
                title: "Rest später in der Garage",
                text: "Gewicht, Wasser, Gas und Service kannst du jederzeit nachziehen.",
                systemImage: "checkmark.circle",
                tintRole: .green
            )
        ],
        stepsTitle: "So startest du",
        steps: [
            FirstRunOnboardingStep(
                title: "Camper anlegen",
                text: "Name, Fahrzeugtyp und die wichtigsten Daten eintragen."
            ),
            FirstRunOnboardingStep(
                title: "Später ergänzen",
                text: "Fehlende Angaben kannst du danach in der Garage ergänzen."
            )
        ],
        footerNote: "Mehr musst du für den ersten Start nicht vorbereiten.",
        primaryActionTitle: "Camper anlegen",
        secondaryActionTitle: "Erstmal nur schauen"
    )
}

private struct OnboardingRevealModifier: ViewModifier {
    let isVisible: Bool
    let offset: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0.01)
            .offset(y: isVisible ? 0 : offset)
    }
}

private extension View {
    func onboardingReveal(isVisible: Bool, offset: CGFloat) -> some View {
        modifier(OnboardingRevealModifier(isVisible: isVisible, offset: offset))
    }
}

struct FirstRunOnboardingView: View {
    @EnvironmentObject private var activeVehicleStore: ActiveVehicleStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isPresented: Bool
    @Binding var hasDismissedOnboarding: Bool

    @State private var showVehicleSheet = false
    @State private var hasAppeared = false

    private let presentation = FirstRunOnboardingPresentation.current

    var body: some View {
        NavigationStack {
            AppCanvas {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureHeader(
                            eyebrow: presentation.headerEyebrow,
                            title: presentation.headerTitle,
                            subtitle: presentation.headerSubtitle
                        )
                        .padding(.top, 12)
                        .onboardingReveal(isVisible: hasAppeared, offset: 12)

                        AlpineSurface(role: .section) {
                            VStack(alignment: .leading, spacing: 14) {
                                sectionHeading(
                                    title: presentation.setupTitle,
                                    subtitle: presentation.setupSubtitle
                                )

                                ForEach(Array(presentation.setupItems.enumerated()), id: \.offset) { _, item in
                                    onboardingLine(
                                        title: item.title,
                                        text: item.text,
                                        systemImage: item.systemImage,
                                        tint: item.tintRole.color
                                    )
                                }

                                Text("Sobald ein Camper angelegt ist, arbeitet die App mit genau diesem Fahrzeug weiter.")
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(AppTheme.mutedInk)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 2)
                            }
                        }
                        .onboardingReveal(isVisible: hasAppeared, offset: 14)

                        AlpineSurface(role: .raised) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text(presentation.stepsTitle)
                                    .font(.system(.title3, design: .default, weight: .semibold))
                                    .foregroundStyle(AppTheme.ink)

                                ForEach(Array(presentation.steps.enumerated()), id: \.offset) { index, step in
                                    onboardingStep(
                                        number: "\(index + 1)",
                                        title: step.title,
                                        text: step.text
                                    )
                                }

                                Text(presentation.footerNote)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(AppTheme.mutedInk)
                            }
                        }
                        .onboardingReveal(isVisible: hasAppeared, offset: 16)

                        VStack(spacing: 12) {
                            Button {
                                showVehicleSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus")
                                        .font(.footnote.weight(.bold))
                                    Text(presentation.primaryActionTitle)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 15)
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.ink, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            Button(presentation.secondaryActionTitle) {
                                hasDismissedOnboarding = true
                                isPresented = false
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.mutedInk)
                        }
                        .onboardingReveal(isVisible: hasAppeared, offset: 18)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Willkommen")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                guard !hasAppeared else { return }
                if reduceMotion {
                    hasAppeared = true
                } else {
                    withAnimation(.easeOut(duration: 0.75)) {
                        hasAppeared = true
                    }
                }
            }
        }
        .sheet(isPresented: $showVehicleSheet) {
            VehicleProfileView(vehicle: nil) { savedVehicle in
                activeVehicleStore.select(savedVehicle)
                hasDismissedOnboarding = true
                isPresented = false
            }
        }
    }

    private func sectionHeading(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.title3, design: .default, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func onboardingLine(title: String, text: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(AppTheme.surfaceLow, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }

    private func onboardingStep(number: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.footnote.weight(.bold))
                .foregroundStyle(AppTheme.petrol)
                .frame(width: 28, height: 28)
                .background(AppTheme.surfaceLow, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    FirstRunOnboardingView(
        isPresented: .constant(true),
        hasDismissedOnboarding: .constant(false)
    )
    .environmentObject(ActiveVehicleStore())
    .modelContainer(PreviewStore.container)
}
