import SwiftUI

struct FirstRunOnboardingView: View {
    @Binding var isPresented: Bool
    @Binding var hasDismissedOnboarding: Bool

    @State private var showVehicleSheet = false

    var body: some View {
        NavigationStack {
            AppCanvas {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        hero

                        onboardingCard(
                            title: "Bereitschaft statt Bauchgefühl",
                            text: "Vor jeder Reise siehst du sofort, ob Gewicht, Dokumente, Wartung und Winter-/Wasserstatus wirklich abfahrbereit sind.",
                            systemImage: "checkmark.shield.fill",
                            tint: AppTheme.green
                        )

                        onboardingCard(
                            title: "Ehrliche Gewichtsbewertung",
                            text: "CamperReady zeigt Reserve, Risiken und Wiege-Empfehlungen, ohne dir pseudo-genaue Achslasten vorzugaukeln.",
                            systemImage: "scalemass.fill",
                            tint: AppTheme.yellow
                        )

                        onboardingCard(
                            title: "Alles an einem Ort",
                            text: "Checklisten, Wartung, Fristen, Kosten und private Ortsnotizen bleiben lokal auf deinem iPhone und schnell erreichbar.",
                            systemImage: "square.grid.2x2.fill",
                            tint: AppTheme.accent
                        )

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
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Willkommen")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showVehicleSheet) {
            VehicleProfileView(vehicle: nil)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("CamperReady")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.78))

            Text("In 60 Sekunden wissen,\nob du losfahren kannst.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Richte einmal dein Fahrzeug ein und nutze danach ein persönliches Bereitschafts-Cockpit statt verstreuter Notizen und Checklisten.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.84))

            HStack(spacing: 10) {
                heroPill(title: "Modul 1", value: "Gewicht")
                heroPill(title: "Modul 2", value: "Fristen")
                heroPill(title: "Modul 3", value: "Abfahrt")
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppTheme.accent.opacity(0.96), Color(red: 0.23, green: 0.69, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .shadow(color: AppTheme.accent.opacity(0.28), radius: 28, x: 0, y: 16)
    }

    private func heroPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.72))
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func onboardingCard(title: String, text: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

#Preview {
    FirstRunOnboardingView(
        isPresented: .constant(true),
        hasDismissedOnboarding: .constant(false)
    )
    .modelContainer(PreviewStore.container)
}
