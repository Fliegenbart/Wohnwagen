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
                        FeatureHeader(
                            eyebrow: "Dein Camper, dein Startpunkt",
                            title: "Sag uns kurz, mit wem du unterwegs bist",
                            subtitle: "Ein paar Angaben zu deinem Camper reichen — danach weiß die App, worüber wir reden."
                        )
                        .padding(.top, 12)
                        .opacity(hasAppeared ? 1 : 0.01)
                        .offset(y: hasAppeared ? 0 : 16)

                        AlpineSurface(role: .focus) {
                            VStack(alignment: .leading, spacing: 18) {
                                Text("Einmal kurz einrichten — dann kann’s losgehen")
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundStyle(.white)

                                Text("Ein Name und ein paar Eckdaten reichen völlig. Den Rest kannst du jederzeit in der Garage nachtragen.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.84))
                                    .fixedSize(horizontal: false, vertical: true)

                                HStack(spacing: 10) {
                                    onboardingBadge(title: "Garage")
                                    onboardingBadge(title: "Gewicht")
                                    onboardingBadge(title: "Fristen")
                                }
                            }
                        }
                        .opacity(hasAppeared ? 1 : 0.01)
                        .offset(y: hasAppeared ? 0 : 18)

                        AlpineSurface(role: .section) {
                            VStack(alignment: .leading, spacing: 14) {
                                sectionHeading(
                                    title: "Das läuft danach von allein",
                                    subtitle: "CamperReady merkt sich, welcher Camper gerade aktiv ist — und hält alles sauber getrennt."
                                )

                                onboardingLine(
                                    title: "Immer der richtige Camper im Blick",
                                    text: "Beim Wechsel in der Garage nutzt das Cockpit sofort den richtigen Camper weiter.",
                                    systemImage: "car.side.fill",
                                    tint: AppTheme.accent
                                )

                                onboardingLine(
                                    title: "Gewicht und Wasser — ehrlich gerechnet",
                                    text: "Kapazitäten und Basiswerte kommen immer vom aktuell ausgewählten Fahrzeug.",
                                    systemImage: "scalemass.fill",
                                    tint: AppTheme.yellow
                                )

                                onboardingLine(
                                    title: "Checklisten und Fristen gehören zum richtigen Fahrzeug",
                                    text: "So verwechselst du Wartung, Dokumente und Notizen nicht zwischen mehreren Fahrzeugen.",
                                    systemImage: "checklist.checked",
                                    tint: AppTheme.green
                                )
                            }
                        }
                        .opacity(hasAppeared ? 1 : 0.01)
                        .offset(y: hasAppeared ? 0 : 20)

                        AlpineSurface(role: .raised) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Los geht’s — in zwei Schritten")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                    .foregroundStyle(AppTheme.ink)

                                onboardingStep(
                                    number: "1",
                                    title: "Camper anlegen",
                                    text: "Name, Fahrzeugtyp und die wichtigsten Daten eintragen."
                                )

                                onboardingStep(
                                    number: "2",
                                    title: "Den Rest später in der Garage ergänzen",
                                    text: "Gewicht, Frischwasser, Gas und Service-Intervalle kannst du danach jederzeit ergänzen."
                                )
                            }
                        }
                        .opacity(hasAppeared ? 1 : 0.01)
                        .offset(y: hasAppeared ? 0 : 22)

                        VStack(spacing: 12) {
                            Button {
                                showVehicleSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Camper jetzt einrichten")
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

                            Button("Erstmal nur schauen") {
                                hasDismissedOnboarding = true
                                isPresented = false
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.mutedInk)
                        }
                        .opacity(hasAppeared ? 1 : 0.01)
                        .offset(y: hasAppeared ? 0 : 24)
                    }
                    .padding(.horizontal, 16)
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

    private func onboardingBadge(title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white.opacity(0.92))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.12), in: Capsule())
    }

    private func sectionHeading(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
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
        .padding(.vertical, 4)
    }

    private func onboardingStep(number: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.footnote.weight(.bold))
                .foregroundStyle(AppTheme.petrol)
                .frame(width: 28, height: 28)
                .background(AppTheme.sand, in: Circle())

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
