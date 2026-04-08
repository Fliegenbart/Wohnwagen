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

    private var activeVehicle: VehicleProfile? {
        activeVehicleStore.activeVehicle(in: vehicles)
    }

    private var orderedVehicles: [VehicleProfile] {
        let presentation = GaragePresentation.make(
            vehicles: vehicles,
            activeVehicleID: activeVehicleStore.selectedVehicleID
        )
        let lookup = Dictionary(uniqueKeysWithValues: vehicles.map { ($0.id, $0) })
        return presentation.orderedVehicleIDs.compactMap { lookup[$0] }
    }

    var body: some View {
        NavigationStack {
            AppCanvas {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        FeatureHeader(
                            eyebrow: "Dein Camper, dein Startpunkt",
                            title: "Garage",
                            subtitle: "Wähl deinen Camper und halt die Basisdaten aktuell."
                        )
                        .padding(.top, 8)

                        if vehicles.isEmpty {
                            GarageEmptyState {
                                editorContext = VehicleEditorContext(vehicle: nil)
                            }
                        } else {
                            if let activeVehicle {
                                GarageCurrentVehicleCard(
                                    vehicle: activeVehicle,
                                    onEdit: {
                                        editorContext = VehicleEditorContext(vehicle: activeVehicle)
                                    },
                                    onAddVehicle: {
                                        editorContext = VehicleEditorContext(vehicle: nil)
                                    }
                                )
                            }

                            GarageFleetSection(
                                vehicles: orderedVehicles,
                                activeVehicleID: activeVehicle?.id,
                                onSelect: { vehicle in
                                    activeVehicleStore.select(vehicle)
                                },
                                onEdit: { vehicle in
                                    editorContext = VehicleEditorContext(vehicle: vehicle)
                                },
                                onAddVehicle: {
                                    editorContext = VehicleEditorContext(vehicle: nil)
                                }
                            )

                            if let activeVehicle {
                                GarageDetailSection(
                                    title: "Basisdaten",
                                    subtitle: "Damit kennt die App deinen Camper."
                                ) {
                                    GarageInfoRow(label: "Name", value: activeVehicle.name)
                                    GarageInfoRow(label: "Marke", value: joinedValue(activeVehicle.brand, activeVehicle.model))
                                    GarageInfoRow(label: "Kennzeichen", value: activeVehicle.licensePlate.fallback("Noch offen"))
                                    GarageInfoRow(label: "Zulassungsland", value: activeVehicle.country.title)
                                    GarageInfoRow(label: "Fahrzeugtyp", value: activeVehicle.vehicleKind.title)
                                }

                                GarageDetailSection(
                                    title: "Gewicht & Tanks",
                                    subtitle: "Mit diesen Werten rechnet die App bei Gewicht, Wasser und Gas."
                                ) {
                                    GarageInfoRow(label: "Zulässiges Gesamtgewicht", value: numberValue(activeVehicle.gvwrKg, suffix: "kg"))
                                    GarageInfoRow(label: "Leergewicht (gemessen)", value: numberValue(activeVehicle.preferredBaseWeightKg, suffix: "kg"))
                                    GarageInfoRow(label: "Frischwasser", value: numberValue(activeVehicle.freshWaterCapacityL, suffix: "l"))
                                    GarageInfoRow(label: "Grauwasser", value: numberValue(activeVehicle.greyWaterCapacityL, suffix: "l"))
                                    GarageInfoRow(label: "Gas", value: gasSummary(for: activeVehicle))
                                }

                                GarageDetailSection(
                                    title: "Service-Intervalle",
                                    subtitle: "Damit Wartung und Fristen immer zum richtigen Camper gehören."
                                ) {
                                    GarageInfoRow(label: "Service alle … Monate", value: activeVehicle.serviceIntervalMonths.map { "\($0) Monate" } ?? "Noch offen")
                                    GarageInfoRow(label: "Service alle … km", value: activeVehicle.serviceIntervalKm.map { "\($0.formatted()) km" } ?? "Noch offen")

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
                                        .padding(.top, 4)
                                    }
                                }
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
        guard let value else { return "Noch offen" }
        return "\(Int(value.rounded())) \(suffix)"
    }

    private func joinedValue(_ first: String, _ second: String) -> String {
        let values = [first, second].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return values.isEmpty ? "Noch offen" : values.joined(separator: " ")
    }

    private func gasSummary(for vehicle: VehicleProfile) -> String {
        guard let count = vehicle.gasBottleCount, count > 0 else {
            return "Noch offen"
        }

        let size = vehicle.gasBottleSizeKg.map { " à \(Int($0.rounded())) kg" } ?? ""
        return "\(count) Flaschen\(size)"
    }
}

struct VehicleSelectionView: View {
    @EnvironmentObject private var activeVehicleStore: ActiveVehicleStore
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]

    @State private var editorContext: VehicleEditorContext?

    private var orderedVehicles: [VehicleProfile] {
        let presentation = GaragePresentation.make(
            vehicles: vehicles,
            activeVehicleID: activeVehicleStore.selectedVehicleID
        )
        let lookup = Dictionary(uniqueKeysWithValues: vehicles.map { ($0.id, $0) })
        return presentation.orderedVehicleIDs.compactMap { lookup[$0] }
    }

    var body: some View {
        NavigationStack {
            AppCanvas {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        FeatureHeader(
                            eyebrow: "Dein Camper, dein Startpunkt",
                            title: "Deine Camper.",
                            subtitle: "Wähl den Camper, mit dem du gerade unterwegs bist."
                        )
                        .padding(.top, 20)

                        if vehicles.isEmpty {
                            GarageEmptyState {
                                editorContext = VehicleEditorContext(vehicle: nil)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(orderedVehicles) { vehicle in
                                    Button {
                                        activeVehicleStore.select(vehicle)
                                    } label: {
                                        GarageSelectionCard(
                                            vehicle: vehicle,
                                            isActive: vehicle.id == activeVehicleStore.selectedVehicleID
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Button("Neuen Camper anlegen") {
                                editorContext = VehicleEditorContext(vehicle: nil)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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

private struct GarageEmptyState: View {
    let onCreateVehicle: () -> Void

    var body: some View {
        AlpineSurface(role: .section) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Noch kein Camper angelegt")
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .tracking(-0.3)
                    .foregroundStyle(AppTheme.ink)

                Text("Leg deinen ersten Camper an — danach läuft alles automatisch.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Camper anlegen", action: onCreateVehicle)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

private struct GarageCurrentVehicleCard: View {
    let vehicle: VehicleProfile
    let onEdit: () -> Void
    let onAddVehicle: () -> Void

    var body: some View {
        AlpineSurface(role: .focus) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Aktiver Camper")
                            .font(.caption.weight(.bold))
                            .textCase(.uppercase)
                            .tracking(1.1)
                            .foregroundStyle(AppTheme.sand.opacity(0.86))

                        Text(vehicle.name)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)

                        Text(vehicleHeadline(vehicle))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.82))
                    }

                    Spacer()

                    GarageTag(title: "Aktiv", isHighlighted: false)
                }

                HStack(spacing: 10) {
                    GarageTag(title: vehicle.vehicleKind.title, isHighlighted: false)
                    GarageTag(title: vehicle.country.title, isHighlighted: false)
                    GarageTag(title: vehicle.licensePlate.fallback("Kennzeichen noch offen"), isHighlighted: false)
                }

                HStack(spacing: 12) {
                    Button("Basisdaten bearbeiten", action: onEdit)
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.sand)
                        .foregroundStyle(AppTheme.ink)

                    Button("Neuer Camper", action: onAddVehicle)
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.82))
                }
            }
        }
    }
}

private struct GarageFleetSection: View {
    let vehicles: [VehicleProfile]
    let activeVehicleID: UUID?
    let onSelect: (VehicleProfile) -> Void
    let onEdit: (VehicleProfile) -> Void
    let onAddVehicle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Deine Camper")
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .tracking(-0.3)
                        .foregroundStyle(AppTheme.ink)
                    Text("Der aktive Camper steht immer oben.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedInk)
                }

                Spacer()

                Button("Neu", action: onAddVehicle)
                    .buttonStyle(.bordered)
            }

            ForEach(vehicles) { vehicle in
                GarageSelectionRow(
                    vehicle: vehicle,
                    isActive: vehicle.id == activeVehicleID,
                    onSelect: { onSelect(vehicle) },
                    onEdit: { onEdit(vehicle) }
                )
            }
        }
    }
}

private struct GarageSelectionRow: View {
    let vehicle: VehicleProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void

    var body: some View {
        AlpineSurface(role: .section) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isActive ? AppTheme.accent : AppTheme.mutedInk)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(vehicle.name)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppTheme.ink)

                            if isActive {
                                GarageTag(title: "Aktiv", isHighlighted: true)
                            }
                        }

                        Text(vehicleHeadline(vehicle))
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            GarageTag(title: vehicle.vehicleKind.title, isHighlighted: false)
                            GarageTag(title: vehicle.licensePlate.fallback("Kennzeichen offen"), isHighlighted: false)
                        }
                    }

                    Spacer()
                }

                HStack(spacing: 12) {
                    if isActive {
                        Text("Ausgewählt")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppTheme.petrol)
                    } else {
                        Button("Auswählen", action: onSelect)
                            .buttonStyle(.borderedProminent)
                    }

                    Button("Bearbeiten", action: onEdit)
                        .buttonStyle(.bordered)
                }
            }
        }
    }
}

private struct GarageSelectionCard: View {
    let vehicle: VehicleProfile
    let isActive: Bool

    var body: some View {
        AlpineSurface(role: .section) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isActive ? AppTheme.accent : AppTheme.mutedInk)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(vehicle.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)

                        if isActive {
                            GarageTag(title: "Aktiv", isHighlighted: true)
                        }
                    }

                    Text(vehicleHeadline(vehicle))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        GarageTag(title: vehicle.vehicleKind.title, isHighlighted: false)
                        GarageTag(title: vehicle.licensePlate.fallback("Kennzeichen offen"), isHighlighted: false)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
    }
}

private struct GarageDetailSection<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        AlpineSurface(role: .section) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .tracking(-0.3)
                        .foregroundStyle(AppTheme.ink)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                content
            }
        }
    }
}

private struct GarageTag: View {
    let title: String
    let isHighlighted: Bool

    var body: some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(isHighlighted ? AppTheme.petrol : AppTheme.mutedInk)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isHighlighted ? AppTheme.sand : AppTheme.surfaceRaised,
                in: Capsule()
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

private func vehicleHeadline(_ vehicle: VehicleProfile) -> String {
    [vehicle.brand, vehicle.model]
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .joined(separator: " ")
        .fallback("Camperdaten ergänzen")
}

private extension String {
    func fallback(_ replacement: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? replacement : self
    }
}
