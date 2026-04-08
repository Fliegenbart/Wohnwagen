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
                            eyebrow: "Fahrzeugwahl",
                            title: "Garage",
                            subtitle: "Wähle dein aktives Fahrzeug und pflege die wichtigsten Basisdaten ohne Umwege."
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
                                    subtitle: "Diese Angaben nutzt die App für Auswahl, Dokumente und Einordnung."
                                ) {
                                    GarageInfoRow(label: "Fahrzeug", value: activeVehicle.name)
                                    GarageInfoRow(label: "Marke", value: joinedValue(activeVehicle.brand, activeVehicle.model))
                                    GarageInfoRow(label: "Kennzeichen", value: activeVehicle.licensePlate.fallback("Noch offen"))
                                    GarageInfoRow(label: "Land", value: activeVehicle.country.title)
                                    GarageInfoRow(label: "Typ", value: activeVehicle.vehicleKind.title)
                                }

                                GarageDetailSection(
                                    title: "Kapazitäten & Gewicht",
                                    subtitle: "So rechnet die App bei Gewicht, Wasser und Gas mit den Werten deines Campers."
                                ) {
                                    GarageInfoRow(label: "zGG", value: numberValue(activeVehicle.gvwrKg, suffix: "kg"))
                                    GarageInfoRow(label: "Leergewicht", value: numberValue(activeVehicle.preferredBaseWeightKg, suffix: "kg"))
                                    GarageInfoRow(label: "Frischwasser", value: numberValue(activeVehicle.freshWaterCapacityL, suffix: "l"))
                                    GarageInfoRow(label: "Grauwasser", value: numberValue(activeVehicle.greyWaterCapacityL, suffix: "l"))
                                    GarageInfoRow(label: "Gas", value: gasSummary(for: activeVehicle))
                                }

                                GarageDetailSection(
                                    title: "Service",
                                    subtitle: "Damit Wartung, Fristen und Notizen beim richtigen Fahrzeug bleiben."
                                ) {
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
                            eyebrow: "Fahrzeugwahl",
                            title: "Deine Camper.",
                            subtitle: "Wähle das Fahrzeug, das du gerade fährst. Die Daten bleiben getrennt."
                        )
                        .padding(.top, 20)

                        CamperSceneCard(
                            mood: .garage,
                            eyebrow: "Garage",
                            title: "Ein Camper, viele Erinnerungen.",
                            subtitle: "Die App merkt sich den zuletzt aktiven Camper und hält die Daten sauber getrennt.",
                            badge: "Wechseln"
                        )

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

                            Button("Neues Fahrzeug anlegen") {
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
                Text("Noch kein Fahrzeug angelegt")
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .tracking(-0.3)
                    .foregroundStyle(AppTheme.ink)

                Text("Lege zuerst deinen Camper an. Danach merkt sich die App automatisch, welches Fahrzeug zuletzt aktiv war.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Fahrzeug anlegen", action: onCreateVehicle)
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
                        Text("Aktives Fahrzeug")
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
                    GarageTag(title: vehicle.licensePlate.fallback("Kennzeichen offen"), isHighlighted: false)
                }

                HStack(spacing: 12) {
                    Button("Basisdaten bearbeiten", action: onEdit)
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.sand)
                        .foregroundStyle(AppTheme.ink)

                    Button("Neues Fahrzeug", action: onAddVehicle)
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
                    Text("Deine Fahrzeuge")
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .tracking(-0.3)
                        .foregroundStyle(AppTheme.ink)
                    Text("Das aktive Fahrzeug steht immer zuerst, damit du schnell weiterkommst.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedInk)
                }

                Spacer()

                Button("Neu", action: onAddVehicle)
                    .buttonStyle(.bordered)
            }

            ForEach(vehicles) { vehicle in
                GarageFleetCard(
                    vehicle: vehicle,
                    isActive: vehicle.id == activeVehicleID,
                    onSelect: { onSelect(vehicle) },
                    onEdit: { onEdit(vehicle) }
                )
            }
        }
    }
}

private struct GarageFleetCard: View {
    let vehicle: VehicleProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void

    var body: some View {
        AlpineSurface(role: isActive ? .raised : .section) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(vehicle.name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)

                        Text(vehicleHeadline(vehicle))
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    if isActive {
                        GarageTag(title: "Aktiv", isHighlighted: true)
                    }
                }

                HStack(spacing: 10) {
                    GarageTag(title: vehicle.vehicleKind.title, isHighlighted: isActive)
                    GarageTag(title: vehicle.country.title, isHighlighted: false)
                    GarageTag(title: vehicle.licensePlate.fallback("Kennzeichen offen"), isHighlighted: false)
                }

                HStack(spacing: 12) {
                    if isActive {
                        Text("Ausgewählt")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(AppTheme.petrol)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(AppTheme.sand, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        let compactLayout = ScenicCardLayout.metrics(forScreenWidth: UIScreen.main.bounds.width, emphasis: .support).sizeClass != .regular

        AlpineSurface(role: isActive ? .raised : .section) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.lavenderSoft, AppTheme.skySoft, AppTheme.canvasWarm],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: compactLayout ? 160 : 180)

                    CamperSceneArtwork(mood: .garage)
                        .frame(height: compactLayout ? 160 : 180)
                        .opacity(0.92)

                    if isActive {
                        GarageTag(title: "Aktiv", isHighlighted: true)
                            .padding(14)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(vehicle.name)
                        .font(.system(size: compactLayout ? 22 : 24, weight: .medium, design: .default))
                        .foregroundStyle(AppTheme.petrol)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text(vehicleHeadline(vehicle))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if compactLayout {
                    VStack(spacing: 10) {
                        statTile(title: "Leergewicht", value: vehicle.preferredBaseWeightKg.map { "\($0.kgString)" } ?? "Offen")
                        statTile(title: "Nutzlast", value: payloadValue(for: vehicle))
                    }
                } else {
                    HStack(spacing: 10) {
                        statTile(title: "Leergewicht", value: vehicle.preferredBaseWeightKg.map { "\($0.kgString)" } ?? "Offen")
                        statTile(title: "Nutzlast", value: payloadValue(for: vehicle))
                    }
                }

                if compactLayout {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            GarageTag(title: vehicle.vehicleKind.title, isHighlighted: isActive)
                            GarageTag(title: vehicle.country.shortLabel, isHighlighted: false)
                        }
                        GarageTag(title: vehicle.licensePlate.fallback("Kennzeichen offen"), isHighlighted: false)
                    }
                } else {
                    HStack(spacing: 10) {
                        GarageTag(title: vehicle.vehicleKind.title, isHighlighted: isActive)
                        GarageTag(title: vehicle.country.shortLabel, isHighlighted: false)
                        GarageTag(title: vehicle.licensePlate.fallback("Kennzeichen offen"), isHighlighted: false)
                    }
                }

                HStack {
                    Text(isActive ? "Ausgewählt" : "Fahrzeug wählen")
                        .font(.footnote.weight(.bold))
                    Spacer()
                    Image(systemName: isActive ? "checkmark" : "arrow.right")
                        .font(.footnote.weight(.bold))
                }
                .foregroundStyle(isActive ? AppTheme.petrol : AppTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(isActive ? AppTheme.sand : AppTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .tracking(0.7)
                .foregroundStyle(AppTheme.mutedInk)
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .default))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceLow, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func payloadValue(for vehicle: VehicleProfile) -> String {
        guard let gvwr = vehicle.gvwrKg, let baseWeight = vehicle.preferredBaseWeightKg else {
            return "Offen"
        }
        return "\(Int(max(gvwr - baseWeight, 0).rounded())) kg"
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
        .fallback("Fahrzeugdaten ergänzen")
}

private extension String {
    func fallback(_ replacement: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? replacement : self
    }
}
