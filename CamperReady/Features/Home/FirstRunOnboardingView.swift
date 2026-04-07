import SwiftUI

struct FirstRunOnboardingView: View {
    @EnvironmentObject private var activeVehicleStore: ActiveVehicleStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isPresented: Bool
    @Binding var hasDismissedOnboarding: Bool

    @State private var showVehicleSheet = false
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            AppCanvas {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        hero

                        VStack(alignment: .leading, spacing: 14) {
                            sectionHeading(
                                title: "Was du hier erledigen kannst",
                                subtitle: "Die App hilft dir dabei, vor jeder Fahrt schnell den Überblick zu bekommen."
                            )

                            onboardingLine(
                                title: "Bereitschaft statt Bauchgefühl",
                                text: "Vor jeder Reise siehst du sofort, ob Gewicht, Dokumente, Wartung und Wasserzustand passen.",
                                systemImage: "checkmark.shield.fill",
                                tint: AppTheme.green
                            )

                            onboardingLine(
                                title: "Ehrliche Gewichtsbewertung",
                                text: "Du siehst Reserve, Risiken und wann Wiegen sinnvoll ist, ohne falsche Genauigkeit.",
                                systemImage: "scalemass.fill",
                                tint: AppTheme.yellow
                            )

                            onboardingLine(
                                title: "Alles an einem Ort",
                                text: "Checklisten, Wartung, Fristen, Kosten und eigene Platznotizen bleiben lokal auf deinem iPhone.",
                                systemImage: "square.grid.2x2.fill",
                                tint: AppTheme.accent
                            )
                        }
                        .opacity(hasAppeared ? 1 : 0.01)
                        .offset(y: hasAppeared ? 0 : 18)

                        VStack(spacing: 12) {
                            Button {
                                showVehicleSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Fahrzeug jetzt einrichten")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .font(.footnote.weight(.bold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.ink, in: Capsule())
                            }
                            .buttonStyle(.plain)

                            Button("Später im Cockpit") {
                                hasDismissedOnboarding = true
                                isPresented = false
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.mutedInk)
                        }
                        .opacity(hasAppeared ? 1 : 0.01)
                        .offset(y: hasAppeared ? 0 : 22)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
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

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            onboardingBackground

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CamperReady")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        Text("Schnell wissen, ob alles passt")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.78))
                }

                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("In 60 Sekunden wissen,\nob du losfahren kannst.")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.74)

                    Text("Richte dein Fahrzeug einmal ein. Danach prüfst du vor jeder Fahrt in weniger als einer Minute, ob noch etwas fehlt.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.84))
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 14) {
                    onboardingMeta(label: "Gewicht", systemImage: "scalemass")
                    onboardingMeta(label: "Fristen", systemImage: "doc.text")
                    onboardingMeta(label: "Abfahrt", systemImage: "checklist")
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, minHeight: 470, maxHeight: 540, alignment: .bottomLeading)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: AppTheme.asphalt.opacity(0.24), radius: 34, x: 0, y: 20)
        .opacity(hasAppeared ? 1 : 0.01)
        .offset(y: hasAppeared ? 0 : 20)
    }

    private var onboardingBackground: some View {
        LinearGradient(
            colors: [AppTheme.surface, AppTheme.surface.opacity(0.96)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func onboardingMeta(label: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
            Text(label)
                .lineLimit(1)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.white.opacity(0.88))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.58), in: Capsule())
    }

    private func sectionHeading(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)
        }
    }

    private func onboardingLine(title: String, text: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)

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
        .padding(.vertical, 10)
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
