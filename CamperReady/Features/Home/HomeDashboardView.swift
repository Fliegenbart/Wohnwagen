import SwiftData
import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject private var navigation: AppNavigationState
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @Query(sort: \PackingItem.name) private var packingItems: [PackingItem]
    @Query(sort: \PassengerLoad.name) private var passengers: [PassengerLoad]
    @Query(sort: \TripLoadSettings.id) private var loadSettings: [TripLoadSettings]
    @Query(sort: \ChecklistRun.updatedAt, order: .reverse) private var checklists: [ChecklistRun]
    @Query(sort: \ChecklistItemRecord.sortOrder) private var checklistItems: [ChecklistItemRecord]
    @Query(sort: \MaintenanceEntry.date, order: .reverse) private var maintenanceEntries: [MaintenanceEntry]
    @Query(sort: \DocumentRecord.title) private var documents: [DocumentRecord]
    @Query(sort: \CostEntry.date, order: .reverse) private var costs: [CostEntry]

    @State private var showVehicleSheet = false
    @State private var showInfoSheet = false
    @State private var exportFile: ExportFile?

    var body: some View {
        let vehicle = AppDataLocator.primaryVehicle(in: vehicles)
        let trip = AppDataLocator.activeTrip(for: vehicle, trips: trips)
        let settings = AppDataLocator.loadSettings(for: vehicle, trip: trip, settings: loadSettings)
        let weight = AppDataLocator.weightAssessment(vehicle: vehicle, trip: trip, items: packingItems, passengers: passengers, settings: settings)
        let vehicleMaintenance = AppDataLocator.maintenance(for: vehicle, entries: maintenanceEntries)
        let vehicleCosts = AppDataLocator.costs(for: vehicle, costs: costs)
        let snapshot = ReadinessEngine.buildDashboard(
            vehicle: vehicle,
            nextTrip: trip,
            weight: weight,
            documents: AppDataLocator.documents(for: vehicle, documents: documents),
            maintenance: vehicleMaintenance,
            checklists: AppDataLocator.checklists(for: vehicle, checklists: checklists),
            checklistItems: checklistItems,
            costs: vehicleCosts,
            currentOdometerKm: AppDataLocator.currentOdometerKm(maintenance: vehicleMaintenance, costs: vehicleCosts)
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if vehicle == nil {
                    emptyStateHero
                } else {
                    hero(snapshot: snapshot, trip: trip)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(snapshot.dimensions) { result in
                            ReadinessTile(result: result)
                        }
                    }

                    if !snapshot.blockingItems.isEmpty {
                        SectionCard(title: "Blocker") {
                            ForEach(snapshot.blockingItems, id: \.self) { item in
                                Label(item, systemImage: "exclamationmark.triangle.fill")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.red)
                            }
                        }
                    }

                    SectionCard(title: "Schnellaktionen") {
                        VStack(alignment: .leading, spacing: 12) {
                            quickAction("Gewicht anpassen", systemImage: "scalemass", tab: .weight)
                            quickAction("Dokumente prüfen", systemImage: "doc.text", tab: .logbook)
                            quickAction("Kosten ansehen", systemImage: "eurosign.circle", tab: .costs)
                            Button {
                                showVehicleSheet = true
                            } label: {
                                actionRow(title: "Fahrzeugprofil bearbeiten", systemImage: "car.circle")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("CamperReady")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showInfoSheet = true
                } label: {
                    Label("Info", systemImage: "info.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if vehicle != nil {
                        Button("Dashboard als PDF exportieren") {
                            exportFile = try? ExportService.exportDashboardPDF(snapshot: snapshot)
                        }
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
        .sheet(isPresented: $showVehicleSheet) {
            VehicleProfileView(vehicle: vehicle)
        }
        .sheet(isPresented: $showInfoSheet) {
            AppInfoView()
        }
    }

    private func hero(snapshot: DashboardSnapshot, trip: Trip?) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Bereitschaft heute")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.78))
                    Text(snapshot.vehicleName)
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                    Text(trip.map { "Nächste Reise: \($0.title)" } ?? "Keine Reise geplant")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    StatusBadge(status: snapshot.overallStatus, text: snapshot.overallStatus.compactTitle)
                        .background(.white.opacity(0.14), in: Capsule())
                    Text(snapshot.openItemsCount == 0 ? "Alles im Blick" : "\(snapshot.openItemsCount) offen")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.86))
                }
            }

            HStack(spacing: 10) {
                cockpitMetric("Status", value: snapshot.overallStatus.title)
                cockpitMetric("Reise", value: trip == nil ? "Offen" : "Aktiv")
                cockpitMetric("Blocker", value: "\(snapshot.blockingItems.count)")
            }

            Button {
                navigation.selectedTab = .checklists
            } label: {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Vor Abfahrt prüfen")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.footnote.weight(.bold))
                }
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(.white, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.statusGradient(snapshot.overallStatus), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: AppTheme.statusColor(snapshot.overallStatus).opacity(0.28), radius: 28, x: 0, y: 16)
    }

    private func cockpitMetric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func quickAction(_ title: String, systemImage: String, tab: AppTab) -> some View {
        Button {
            navigation.selectedTab = tab
        } label: {
            actionRow(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func actionRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 34, height: 34)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Spacer()
            Image(systemName: "arrow.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(AppTheme.mutedInk)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var emptyStateHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bereitschaft startet hier")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.78))
                    Text("Noch kein\nFahrzeug")
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Lege dein Fahrzeug an, damit CamperReady Gewicht, Fristen, Wartung und Abfahrtsstatus für dich bewerten kann.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                StatusBadge(status: .yellow, text: "Einrichten")
                    .background(.white.opacity(0.14), in: Capsule())
            }

            HStack(spacing: 10) {
                cockpitMetric("Schritt 1", value: "Fahrzeug")
                cockpitMetric("Schritt 2", value: "Fristen")
                cockpitMetric("Schritt 3", value: "Abfahrt")
            }

            Button {
                showVehicleSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Fahrzeug anlegen")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.footnote.weight(.bold))
                }
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(.white, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppTheme.accent.opacity(0.92), Color(red: 0.32, green: 0.67, blue: 0.94)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .shadow(color: AppTheme.accent.opacity(0.28), radius: 28, x: 0, y: 16)
    }
}

#Preview {
    NavigationStack {
        HomeDashboardView()
            .environmentObject(AppNavigationState())
    }
    .modelContainer(PreviewStore.container)
}
