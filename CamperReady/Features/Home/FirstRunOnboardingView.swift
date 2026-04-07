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
                            eyebrow: "Fahrzeugwahl",
                            title: "Starte mit deinem ersten Fahrzeug",
                            subtitle: "Lege deinen Camper einmal an. Danach arbeiten Garage, Gewicht, Checklisten und Fristen immer mit dem richtigen Fahrzeug."
                        )
                        .padding(.top, 12)
                        .opacity(hasAppeared ? 1 : 0.01)
                        .offset(y: hasAppeared ? 0 : 16)

                        AlpineSurface(role: .focus) {
                            VStack(alignment: .leading, spacing: 18) {
                                Text("Einmal einrichten, dann direkt loslegen")
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundStyle(.white)

                                Text("Für den Start reichen ein Name und ein paar Basisdaten. Alles Weitere kannst du später in der Garage ergänzen.")
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
                                    title: "Was danach automatisch passt",
                                    subtitle: "Die App merkt sich dein aktives Fahrzeug und trennt die Daten sauber pro Camper."
                                )

                                onboardingLine(
                                    title: "Der richtige Camper bleibt aktiv",
                                    text: "Beim Wechsel in der Garage nutzt Home sofort das gewählte Fahrzeug weiter.",
                                    systemImage: "car.side.fill",
                                    tint: AppTheme.accent
                                )

                                onboardingLine(
                                    title: "Gewicht und Wasser bleiben ehrlich",
                                    text: "Kapazitäten und Basiswerte kommen immer vom aktuell ausgewählten Fahrzeug.",
                                    systemImage: "scalemass.fill",
                                    tint: AppTheme.yellow
                                )

                                onboardingLine(
                                    title: "Checklisten und Fristen bleiben zugeordnet",
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
                                Text("Dein Start in 2 Schritten")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                    .foregroundStyle(AppTheme.ink)

                                onboardingStep(
                                    number: "1",
                                    title: "Fahrzeug anlegen",
                                    text: "Name, Typ und die wichtigsten Daten eintragen."
                                )

                                onboardingStep(
                                    number: "2",
                                    title: "Später in der Garage ergänzen",
                                    text: "Gewicht, Wasser, Gas und Service kannst du danach jederzeit nachpflegen."
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
