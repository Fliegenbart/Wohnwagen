import SwiftData
import SwiftUI

private struct VehicleEditorContext: Identifiable {
    let id = UUID()
    let vehicle: VehicleProfile?
}

struct GarageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var activeVehicleStore: ActiveVehicleStore
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]

    @State private var editorContext: VehicleEditorContext?

    var body: some View {
        NavigationStack {
            AppCanvas {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Garage")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(AppTheme.ink)
                            Text("Hier wechselst du dein aktives Fahrzeug und pflegst die wichtigsten Basisdaten.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.mutedInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 8)

                        if let activeVehicle = activeVehicleStore.activeVehicle(in: vehicles) {
                            SectionCard(title: "Aktives Fahrzeug", subtitle: "Mit diesem Fahrzeug arbeiten Home, Gewicht, Checklisten, Logbuch und Kosten.") {
                                VStack(alignment: .leading, spacing: 14) {
                                    GarageActiveVehicleRow(vehicle: activeVehicle)

                                    HStack(spacing: 12) {
                                        Button("Basisdaten bearbeiten") {
                                            editorContext = VehicleEditorContext(vehicle: activeVehicle)
                                        }
                                        .buttonStyle(.borderedProminent)

                                        Button("Neues Fahrzeug") {
                                            editorContext = VehicleEditorContext(vehicle: nil)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }

                            SectionCard(title: "Garage", subtitle: "Wähle hier aus, mit welchem Fahrzeug du gerade unterwegs bist.") {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(vehicles) { vehicle in
                                        GarageVehicleRow(
                                            vehicle: vehicle,
                                            isActive: vehicle.id == activeVehicle.id,
                                            onSelect: {
                                                activeVehicleStore.select(vehicle)
                                            },
                                            onEdit: {
                                                editorContext = VehicleEditorContext(vehicle: vehicle)
                                            }
                                        )
                                    }
                                }
                            }

                            SectionCard(title: "Basisdaten", subtitle: "Die wichtigsten Stammdaten deines aktiven Fahrzeugs.") {
                                VStack(alignment: .leading, spacing: 12) {
                                    GarageInfoRow(label: "Fahrzeug", value: activeVehicle.name)
                                    GarageInfoRow(label: "Marke", value: joinedValue(activeVehicle.brand, activeVehicle.model))
                                    GarageInfoRow(label: "Kennzeichen", value: activeVehicle.licensePlate.fallback("Noch offen"))
                                    GarageInfoRow(label: "Land", value: activeVehicle.country.title)
                                }
                            }

                            SectionCard(title: "Kapazitäten & Gewicht", subtitle: "Diese Werte nutzt die App für Gewicht, Wasser, Gas und Bereitschaft.") {
                                VStack(alignment: .leading, spacing: 12) {
                                    GarageInfoRow(label: "zGG", value: numberValue(activeVehicle.gvwrKg, suffix: "kg"))
                                    GarageInfoRow(label: "Leergewicht", value: numberValue(activeVehicle.preferredBaseWeightKg, suffix: "kg"))
                                    GarageInfoRow(label: "Frischwasser", value: numberValue(activeVehicle.freshWaterCapacityL, suffix: "l"))
                                    GarageInfoRow(label: "Grauwasser", value: numberValue(activeVehicle.greyWaterCapacityL, suffix: "l"))
                                    GarageInfoRow(label: "Gas", value: gasSummary(for: activeVehicle))
                                }
                            }

                            SectionCard(title: "Service", subtitle: "Damit du Wartung und Fristen realistisch planen kannst.") {
                                VStack(alignment: .leading, spacing: 12) {
                                    GarageInfoRow(label: "Intervall Zeit", value: activeVehicle.serviceIntervalMonths.map { "\($0) Monate" } ?? "Nicht hinterlegt")
                                    GarageInfoRow(label: "Intervall Kilometer", value: activeVehicle.serviceIntervalKm.map { "\($0.formatted()) km" } ?? "Nicht hinterlegt")
                                    if !activeVehicle.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Notizen")
                                                .font(.footnote.weight(.bold))
                                                .foregroundStyle(AppTheme.mutedInk)
                                            Text(activeVehicle.notes)
                                                .font(.subheadline)
                                                .foregroundStyle(AppTheme.ink)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                        } else {
                            SectionCard(title: "Noch kein Fahrzeug", subtitle: "Lege zuerst einen Camper an. Danach merkt sich die App dein zuletzt genutztes Fahrzeug automatisch.") {
                                Button("Fahrzeug anlegen") {
                                    editorContext = VehicleEditorContext(vehicle: nil)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Garage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
        .sheet(item: $editorContext) { context in
            VehicleProfileView(vehicle: context.vehicle) { savedVehicle in
                activeVehicleStore.select(savedVehicle)
            }
        }
        .onAppear {
            activeVehicleStore.reconcile(with: vehicles)
        }
    }

    private func numberValue(_ value: Double?, suffix: String) -> String {
        guard let value else { return "Nicht hinterlegt" }
        return "\(Int(value.rounded())) \(suffix)"
    }

    private func joinedValue(_ first: String, _ second: String) -> String {
        let values = [first, second].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return values.isEmpty ? "Noch offen" : values.joined(separator: " ")
    }

    private func gasSummary(for vehicle: VehicleProfile) -> String {
        guard let count = vehicle.gasBottleCount, count > 0 else {
            return "Nicht hinterlegt"
        }

        let size = vehicle.gasBottleSizeKg.map { " à \(Int($0.rounded())) kg" } ?? ""
        return "\(count) Flaschen\(size)"
    }
}

struct VehicleSelectionView: View {
    @EnvironmentObject private var activeVehicleStore: ActiveVehicleStore
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]

    @State private var editorContext: VehicleEditorContext?

    var body: some View {
        NavigationStack {
            AppCanvas {
                VStack(alignment: .leading, spacing: 20) {
                    Spacer(minLength: 20)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Welches Fahrzeug nutzt du jetzt?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                        Text("Deine Daten bleiben pro Fahrzeug erhalten. Wähle einfach deinen Camper aus und arbeite direkt weiter.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(vehicles) { vehicle in
                            Button {
                                activeVehicleStore.select(vehicle)
                            } label: {
                                GarageSelectionRow(vehicle: vehicle)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button("Neues Fahrzeug anlegen") {
                        editorContext = VehicleEditorContext(vehicle: nil)
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .navigationTitle("Fahrzeug wählen")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
        .sheet(item: $editorContext) { context in
            VehicleProfileView(vehicle: context.vehicle) { savedVehicle in
                activeVehicleStore.select(savedVehicle)
            }
        }
        .onAppear {
            activeVehicleStore.reconcile(with: vehicles)
        }
    }
}

private struct GarageActiveVehicleRow: View {
    let vehicle: VehicleProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(vehicle.name)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text([vehicle.brand, vehicle.model].filter { !$0.isEmpty }.joined(separator: " "))
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)
            Text(vehicle.licensePlate.fallback("Kennzeichen noch offen"))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct GarageVehicleRow: View {
    let vehicle: VehicleProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(isActive ? AppTheme.accent : AppTheme.asphalt.opacity(0.10))
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(vehicle.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text([vehicle.brand, vehicle.model].filter { !$0.isEmpty }.joined(separator: " ").fallback("Fahrzeugdaten ergänzen"))
                            .font(.footnote)
                            .foregroundStyle(AppTheme.mutedInk)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onEdit) {
                Image(systemName: "square.and.pencil")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isActive ? AppTheme.accent.opacity(0.08) : Color.white.opacity(0.54))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isActive ? AppTheme.accent.opacity(0.22) : AppTheme.asphalt.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct GarageSelectionRow: View {
    let vehicle: VehicleProfile

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppTheme.accent.opacity(0.16))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text([vehicle.brand, vehicle.model].filter { !$0.isEmpty }.joined(separator: " ").fallback("Fahrzeugdaten ergänzen"))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedInk)
                Text(vehicle.licensePlate.fallback("Kennzeichen noch offen"))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            Spacer()

            Image(systemName: "arrow.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.74))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.asphalt.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct GarageInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.footnote.weight(.bold))
                .foregroundStyle(AppTheme.mutedInk)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.trailing)
        }
    }
}

private extension String {
    func fallback(_ replacement: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? replacement : self
    }
}
