import SwiftData
import SwiftUI

struct WeightView: View {
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @Query(sort: \PackingItem.name) private var packingItems: [PackingItem]
    @Query(sort: \PassengerLoad.name) private var passengers: [PassengerLoad]
    @Query(sort: \TripLoadSettings.id) private var loadSettings: [TripLoadSettings]

    var body: some View {
        let vehicle = AppDataLocator.primaryVehicle(in: vehicles)
        let trip = AppDataLocator.activeTrip(for: vehicle, trips: trips)
        let activeSettings = AppDataLocator.loadSettings(for: vehicle, trip: trip, settings: loadSettings)
        let vehicleItems = AppDataLocator.packingItems(for: vehicle, trip: trip, items: packingItems)
        let vehiclePassengers = AppDataLocator.passengers(for: vehicle, trip: trip, passengers: passengers)
        let assessment = AppDataLocator.weightAssessment(
            vehicle: vehicle,
            trip: trip,
            items: packingItems,
            passengers: passengers,
            settings: activeSettings
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let vehicle {
                    hero(vehicle: vehicle, trip: trip, assessment: assessment, settings: activeSettings)

                    if let activeSettings {
                        LoadSettingsEditor(vehicle: vehicle, loadSettings: activeSettings)
                    }

                    SectionCard(title: "Schnellbewertung") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            MetricCard(title: "Gesamt", value: assessment.estimatedGrossWeightKg?.kgString ?? "Unklar", systemImage: "truck.box.fill")
                            MetricCard(title: "Reserve", value: assessment.remainingMarginKg?.kgString ?? "Unklar", systemImage: "checkmark.shield.fill")
                            MetricCard(title: "Achslast", value: axleLabel(for: assessment.axleRisk), systemImage: "warninglight.fill")
                            MetricCard(title: "Volles Wasser", value: "+\(Int(assessment.waterComparisonDeltaKg.rounded())) kg", systemImage: "drop.fill")
                        }
                    }

                    SectionCard(title: "Top-Gewichtstreiber") {
                        let topContributors = Array(assessment.contributors.prefix(6))
                        if topContributors.isEmpty {
                            Text("Noch keine Gewichtstreiber vorhanden.")
                                .foregroundStyle(AppTheme.mutedInk)
                        } else {
                            ForEach(topContributors) { contributor in
                                WeightContributorRow(
                                    contributor: contributor,
                                    maxWeightKg: topContributors.first?.weightKg ?? contributor.weightKg
                                )
                                if contributor.id != topContributors.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    SectionCard(title: "Packliste") {
                        if vehicleItems.isEmpty {
                            Text("Noch keine Packstücke hinterlegt.")
                                .foregroundStyle(AppTheme.mutedInk)
                        } else {
                            ForEach(vehicleItems) { item in
                                PackingItemRow(item: item)
                                if item.id != vehicleItems.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    SectionCard(title: "Mitfahrende") {
                        if vehiclePassengers.isEmpty {
                            Text("Keine Mitfahrenden erfasst.")
                                .foregroundStyle(AppTheme.mutedInk)
                        } else {
                            ForEach(vehiclePassengers) { person in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(person.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.ink)
                                        if person.isDriver {
                                            Text("Fahrer:in")
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(AppTheme.mutedInk)
                                        }
                                    }
                                    Spacer()
                                    Text(person.weightKg.kgString)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(AppTheme.mutedInk)
                                }
                            }
                        }
                    }

                    SectionCard(title: "Hinweise") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Die Berechnung bleibt bewusst konservativ. Achslasten werden nur bewertet, wenn echte Messwerte vorliegen oder ein klares Risikomuster erkennbar ist.")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.mutedInk)

                            if assessment.warnings.isEmpty {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(AppTheme.green)
                                    Text("Keine zusätzlichen Gewichtsrisiken erkannt.")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.ink)
                                }
                            } else {
                                ForEach(assessment.warnings, id: \.self) { warning in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(AppTheme.yellow)
                                        Text(warning)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(AppTheme.ink)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppTheme.yellow.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Kein Fahrzeug",
                        systemImage: "scalemass",
                        description: Text("Lege ein Fahrzeug an, um Gewicht und Reserve ehrlich zu bewerten.")
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("Gewicht")
        .navigationBarTitleDisplayMode(.large)
    }

    private func axleLabel(for risk: LoadRiskLevel) -> String {
        switch risk {
        case .low: "Niedrig"
        case .elevated: "Erhöht"
        case .measured: "Gemessen"
        }
    }

    private func hero(
        vehicle: VehicleProfile,
        trip: Trip?,
        assessment: WeightAssessmentOutput,
        settings: TripLoadSettings?
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Abfahrtsentscheidung")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.78))
                    Text(vehicle.name)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(trip.map { "Reise: \($0.title)" } ?? "Keine aktive Reise")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                StatusBadge(status: assessment.status, text: assessment.status.title)
                    .background(.white.opacity(0.14), in: Capsule())
            }

            Text(assessment.summary)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                heroPill(title: "Reserve", value: assessment.remainingMarginKg?.kgString ?? "Unklar")
                heroPill(title: "Achslast", value: axleLabel(for: assessment.axleRisk))
                heroPill(title: "Wasser", value: "\(Int((settings?.freshWaterLiters ?? 0).rounded())) l")
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.statusGradient(assessment.status), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: AppTheme.statusColor(assessment.status).opacity(0.28), radius: 28, x: 0, y: 16)
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
}

private struct LoadSettingsEditor: View {
    let vehicle: VehicleProfile
    @Bindable var loadSettings: TripLoadSettings

    var body: some View {
        SectionCard(title: "Beladung für diese Reise") {
            VStack(alignment: .leading, spacing: 10) {
                Stepper("Frischwasser: \(Int(loadSettings.freshWaterLiters)) l", value: $loadSettings.freshWaterLiters, in: 0...(vehicle.freshWaterCapacityL ?? 120), step: 5)
                Stepper("Heckträger: \(Int(loadSettings.rearCarrierLoadKg)) kg", value: $loadSettings.rearCarrierLoadKg, in: 0...120, step: 2)
                Stepper("Dachlast: \(Int(loadSettings.roofLoadKg)) kg", value: $loadSettings.roofLoadKg, in: 0...120, step: 2)
                Stepper("Zusatzlast: \(Int(loadSettings.extraLoadKg)) kg", value: $loadSettings.extraLoadKg, in: 0...120, step: 2)
                Stepper("Gasflaschenfüllstand: \(Int(loadSettings.gasBottleFillPercent)) %", value: $loadSettings.gasBottleFillPercent, in: 0...100, step: 10)
                Toggle("Fahrräder am Heckträger", isOn: $loadSettings.bikesOnRearCarrier)
            }
        }
    }
}

private struct WeightContributorRow: View {
    let contributor: WeightContributor
    let maxWeightKg: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(contributor.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text(contributor.weightKg.kgString)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.mutedInk)
            }

            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(AppTheme.accent.opacity(0.12))
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                            .fill(AppTheme.accent)
                            .frame(width: max(proxy.size.width * (contributor.weightKg / max(maxWeightKg, 1)), 16))
                    }
            }
            .frame(height: 8)
        }
    }
}

private struct PackingItemRow: View {
    @Bindable var item: PackingItem

    var body: some View {
        HStack {
            Toggle(isOn: $item.includeInCurrentLoad) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .foregroundStyle(AppTheme.ink)
                    Text(item.category.title)
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedInk)
                }
            }

            Text(item.totalWeightKg.kgString)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.mutedInk)
        }
    }
}

#Preview {
    NavigationStack {
        WeightView()
    }
    .modelContainer(PreviewStore.container)
}
