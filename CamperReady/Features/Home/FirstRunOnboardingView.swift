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
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureHeader(
                            eyebrow: "Dein Camper, dein Startpunkt",
                            title: "Sag uns kurz, mit wem du unterwegs bist",
                            subtitle: "Ein paar Angaben zu deinem Camper reichen. Den Rest kannst du später in der Garage ergänzen."
                        )
                        .padding(.top, 16)
                        .opacity(hasAppeared ? 1 : 0.01)
                        .offset(y: hasAppeared ? 0 : 12)

                        AlpineSurface(role: .section) {
                            VStack(alignment: .leading, spacing: 14) {
                                sectionHeading(
                                    title: "Was wir am Anfang brauchen",
                                    subtitle: "Nur die Basis, damit CamperReady direkt mit dem richtigen Fahrzeug arbeitet."
                                )

                                onboardingLine(
                                    title: "Name und Fahrzeugtyp",
                                    text: "Damit du deinen Camper sofort wiedererkennst.",
                                    systemImage: "car.side",
                                    tint: AppTheme.petrol
                                )

                                onboardingLine(
                                    title: "Wichtige Eckdaten",
                                    text: "Gewicht, Wasser oder Gas kannst du später ergänzen, wenn du sie gerade nicht parat hast.",
                                    systemImage: "square.and.pencil",
                                    tint: AppTheme.yellow
                                )

                                onboardingLine(
                                    title: "Ein aktiver Camper",
                                    text: "Danach bleiben Checklisten, Fristen und Berechnungen sauber dem richtigen Fahrzeug zugeordnet.",
                                    systemImage: "checkmark.circle",
                                    tint: AppTheme.green
                                )
                            }
                        }
                        .opacity(hasAppeared ? 1 : 0.01)
                        .offset(y: hasAppeared ? 0 : 14)

                        AlpineSurface(role: .section) {
                            VStack(alignment: .leading, spacing: 14) {
                                sectionHeading(
                                    title: "So fühlt sich die App danach an",
                                    subtitle: "CamperReady merkt sich, welcher Camper aktiv ist, und nutzt diese Auswahl im ganzen Alltag weiter."
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
                        .offset(y: hasAppeared ? 0 : 16)

                        AlpineSurface(role: .raised) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("So startest du")
                                    .font(.system(.title3, design: .default, weight: .semibold))
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

                                Text("Mehr musst du für den ersten Start nicht vorbereiten.")
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(AppTheme.mutedInk)
                            }
                        }
                        .opacity(hasAppeared ? 1 : 0.01)
                        .offset(y: hasAppeared ? 0 : 18)

                        VStack(spacing: 12) {
                            Button {
                                showVehicleSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus")
                                        .font(.footnote.weight(.bold))
                                    Text("Camper anlegen")
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

                            Button("Erstmal nur schauen") {
                                hasDismissedOnboarding = true
                                isPresented = false
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.mutedInk)
                        }
                        .opacity(hasAppeared ? 1 : 0.01)
                        .offset(y: hasAppeared ? 0 : 20)
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
