import MapKit
import SwiftData
import SwiftUI

private enum LogbookSection: String, CaseIterable, Identifiable {
    case maintenance
    case documents
    case places

    var id: String { rawValue }

    var title: String {
        switch self {
        case .maintenance: "Wartung"
        case .documents: "Dokumente"
        case .places: "Orte"
        }
    }
}

struct LogbookView: View {
    @Query(sort: \VehicleProfile.createdAt) private var vehicles: [VehicleProfile]
    @Query(sort: \MaintenanceEntry.date, order: .reverse) private var maintenanceEntries: [MaintenanceEntry]
    @Query(sort: \DocumentRecord.validUntil) private var documents: [DocumentRecord]
    @Query(sort: \PlaceNote.dateLastUsed, order: .reverse) private var placeNotes: [PlaceNote]
    @State private var selectedSection: LogbookSection = .maintenance
    @State private var exportFile: ExportFile?

    var body: some View {
        let vehicle = AppDataLocator.primaryVehicle(in: vehicles)
        let vehicleMaintenance = AppDataLocator.maintenance(for: vehicle, entries: maintenanceEntries)
        let vehicleDocuments = AppDataLocator.documents(for: vehicle, documents: documents)
        let vehiclePlaces = AppDataLocator.places(for: vehicle, places: placeNotes)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero(
                    maintenanceCount: vehicleMaintenance.count,
                    documentCount: vehicleDocuments.count,
                    placeCount: vehiclePlaces.count
                )

                Picker("Bereich", selection: $selectedSection) {
                    ForEach(LogbookSection.allCases) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedSection {
                case .maintenance:
                    SectionCard(title: "Wartungsjournal") {
                        if vehicleMaintenance.isEmpty {
                            Text("Noch keine Wartungseinträge vorhanden.")
                                .foregroundStyle(AppTheme.mutedInk)
                        } else {
                            ForEach(vehicleMaintenance) { entry in
                                MaintenanceRow(entry: entry)
                                if entry.id != vehicleMaintenance.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                case .documents:
                    SectionCard(title: "Dokumente & Fristen") {
                        Text("Hinweis: Die Fristen dienen als persönliche Erinnerung und sind keine Rechtsberatung. Quellen und Regeln bleiben editierbar.")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.mutedInk)

                        Divider()

                        if vehicleDocuments.isEmpty {
                            Text("Noch keine Dokumente erfasst.")
                                .foregroundStyle(AppTheme.mutedInk)
                        } else {
                            ForEach(vehicleDocuments) { document in
                                DocumentRow(document: document)
                                if document.id != vehicleDocuments.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                case .places:
                    if vehiclePlaces.isEmpty {
                        ContentUnavailableView(
                            "Keine privaten Orte",
                            systemImage: "map",
                            description: Text("Hier erscheinen nur deine eigenen Notizen, keine öffentliche Datenbank.")
                        )
                    } else {
                        SectionCard(title: "Eigene Platznotizen") {
                            Map(initialPosition: .region(region(for: vehiclePlaces))) {
                                ForEach(vehiclePlaces) { place in
                                    Marker(place.title, coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude))
                                }
                            }
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                            ForEach(vehiclePlaces) { place in
                                PlaceRow(place: place)
                                if place.id != vehiclePlaces.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("Logbuch")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if selectedSection == .maintenance {
                        Button("Wartung als CSV exportieren") {
                            exportFile = try? ExportService.exportMaintenanceCSV(entries: vehicleMaintenance)
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
    }

    private func hero(maintenanceCount: Int, documentCount: Int, placeCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Eigentümer-Logbuch")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.78))
                    Text("Nachweise & Historie")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Wartung, Fristen und persönliche Plätze an einem Ort.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                Image(systemName: "book.closed.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            HStack(spacing: 10) {
                heroPill(title: "Wartung", value: "\(maintenanceCount)")
                heroPill(title: "Dokumente", value: "\(documentCount)")
                heroPill(title: "Orte", value: "\(placeCount)")
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppTheme.accent.opacity(0.94), Color(red: 0.18, green: 0.62, blue: 0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .shadow(color: AppTheme.accent.opacity(0.24), radius: 28, x: 0, y: 16)
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

    private func region(for places: [PlaceNote]) -> MKCoordinateRegion {
        guard let first = places.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 47.8, longitude: 10.2),
                span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
            )
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.6, longitudeDelta: 0.6)
        )
    }
}

private struct MaintenanceRow: View {
    let entry: MaintenanceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text(entry.date.shortDateString())
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.mutedInk)
            }

            HStack(spacing: 8) {
                Text(entry.category.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.accent.opacity(0.10), in: Capsule())

                if let cost = entry.costEUR {
                    Text(cost.euroString)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.64), in: Capsule())
                }
            }

            if let dueDate = entry.nextDueDate {
                Label("Nächste Fälligkeit: \(dueDate.shortDateString())", systemImage: "calendar.badge.clock")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.mutedInk)
            }

            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.ink)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct DocumentRow: View {
    let document: DocumentRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(document.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                if let validUntil = document.validUntil {
                    Text(validUntil.shortDateString())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(statusColor.opacity(0.12), in: Capsule())
                }
            }

            Text(document.sourceLabel)
                .font(.caption)
                .foregroundStyle(AppTheme.mutedInk)

            if !document.notes.isEmpty {
                Text(document.notes)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.ink)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        guard let validUntil = document.validUntil else { return AppTheme.mutedInk }
        if validUntil < .now {
            return AppTheme.red
        }
        if let thirtyDaysOut = Calendar.current.date(byAdding: .day, value: 30, to: .now), validUntil < thirtyDaysOut {
            return AppTheme.yellow
        }
        return AppTheme.green
    }
}

private struct PlaceRow: View {
    let place: PlaceNote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(place.type.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                Spacer()
                if let rating = place.personalRating {
                    Text("\(rating)/5")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.64), in: Capsule())
                }
            }

            Text(place.notes)
                .font(.footnote)
                .foregroundStyle(AppTheme.ink)

            if let lastUsed = place.dateLastUsed {
                Text("Zuletzt genutzt: \(lastUsed.shortDateString())")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        LogbookView()
    }
    .modelContainer(PreviewStore.container)
}
