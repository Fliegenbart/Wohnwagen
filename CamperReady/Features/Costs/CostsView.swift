import SwiftData
import SwiftUI

struct CostsView: View {
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @Query(sort: \CostEntry.date, order: .reverse) private var costs: [CostEntry]
    @State private var exportFile: ExportFile?

    var body: some View {
        let vehicle = AppDataLocator.primaryVehicle(in: vehicles)
        let trip = AppDataLocator.activeTrip(for: vehicle, trips: trips)
        let vehicleCosts = AppDataLocator.costs(for: vehicle, costs: costs)
        let tripCosts = vehicleCosts.filter { $0.tripID == trip?.id && !$0.isRecurringFixedCost }
        let fixedCosts = vehicleCosts.filter(\.isRecurringFixedCost)
        let tripTotal = tripCosts.reduce(0) { $0 + $1.amountEUR }
        let tripNights = max(tripCosts.compactMap(\.nights).reduce(0, +), 1)
        let distance = trip?.plannedDistanceKm ?? 0
        let annualFixed = fixedCosts.reduce(0) { $0 + ReadinessEngine.annualizedAmount(for: $1) }
        let annualVariable = vehicleCosts
            .filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .year) && !$0.isRecurringFixedCost }
            .reduce(0) { $0 + $1.amountEUR }

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero(tripTitle: trip?.title, tripTotal: tripTotal, annualTotal: annualFixed + annualVariable)

                SectionCard(title: "Kostenblick") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(title: "Diese Reise", value: tripTotal.euroString, systemImage: "car.fill")
                        MetricCard(title: "Pro Nacht", value: (tripTotal / Double(tripNights)).euroString, systemImage: "bed.double.fill")
                        MetricCard(title: "Pro 100 km", value: distance > 0 ? (tripTotal / distance * 100).euroString : "Offen", systemImage: "road.lanes")
                        MetricCard(title: "Jahr gesamt", value: (annualFixed + annualVariable).euroString, systemImage: "calendar")
                    }
                }

                SectionCard(title: "Variable Reisekosten") {
                    if tripCosts.isEmpty {
                        Text("Noch keine variablen Kosten für die aktuelle Reise.")
                            .foregroundStyle(AppTheme.mutedInk)
                    } else {
                        ForEach(tripCosts) { cost in
                            CostRow(cost: cost)
                            if cost.id != tripCosts.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                SectionCard(title: "Wiederkehrende Fixkosten") {
                    if fixedCosts.isEmpty {
                        Text("Noch keine Fixkosten hinterlegt.")
                            .foregroundStyle(AppTheme.mutedInk)
                    } else {
                        ForEach(fixedCosts) { cost in
                            FixedCostRow(cost: cost)
                            if cost.id != fixedCosts.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("Kosten")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Kosten als CSV exportieren") {
                        exportFile = try? ExportService.exportCostsCSV(costs: vehicleCosts)
                    }
                    if let exportFile {
                        ShareLink(item: exportFile.url) {
                            Label("Letzte Datei teilen", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private func hero(tripTitle: String?, tripTotal: Double, annualTotal: Double) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kostenklarheit")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.78))
                    Text(tripTitle ?? "Aktuelle Reise")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Variable und fixe Kosten transparent im Blick.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                Image(systemName: "eurosign.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            HStack(spacing: 10) {
                heroPill(title: "Reise", value: tripTotal.euroString)
                heroPill(title: "Jahr", value: annualTotal.euroString)
                heroPill(title: "Einträge", value: "\(costs.count)")
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.45, blue: 0.32), Color(red: 0.22, green: 0.72, blue: 0.52)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .shadow(color: AppTheme.green.opacity(0.24), radius: 28, x: 0, y: 16)
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

private struct CostRow: View {
    let cost: CostEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.headline)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 36, height: 36)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(cost.category.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(cost.notes.isEmpty ? cost.date.shortDateString() : cost.notes)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
            }

            Spacer()

            Text(cost.amountEUR.euroString)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch cost.category {
        case .fuel: "fuelpump.fill"
        case .toll: "road.lanes"
        case .ferry: "ferry.fill"
        case .campsite: "parkingsign.circle.fill"
        case .gas: "flame.fill"
        case .electricity: "bolt.fill"
        case .waterDisposal: "drop.fill"
        case .workshop: "wrench.and.screwdriver.fill"
        case .other: "ellipsis.circle.fill"
        }
    }
}

private struct FixedCostRow: View {
    let cost: CostEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(cost.notes.isEmpty ? cost.category.title : cost.notes)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(cost.recurrence?.rawValue.capitalized ?? "Einmalig")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
            }

            Spacer()

            Text(ReadinessEngine.annualizedAmount(for: cost).euroString)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        CostsView()
    }
    .modelContainer(PreviewStore.container)
}
