import Foundation
import os.log
import SwiftData

struct PersistenceBootstrap {
    let container: ModelContainer
    let warningMessage: String?
}

@MainActor
final class PersistenceStatus: ObservableObject {
    @Published var warningMessage: String?

    init(warningMessage: String? = nil) {
        self.warningMessage = warningMessage
    }
}

enum PersistenceController {
    static let schema = Schema([
        VehicleProfile.self,
        Trip.self,
        PackingItem.self,
        PassengerLoad.self,
        TripLoadSettings.self,
        ChecklistRun.self,
        ChecklistItemRecord.self,
        MaintenanceEntry.self,
        DocumentRecord.self,
        PlaceNote.self,
        CostEntry.self
    ])

    static func makeProductionBootstrap() -> PersistenceBootstrap {
        if let container = try? makeContainer(isStoredInMemoryOnly: false) {
            return PersistenceBootstrap(container: container, warningMessage: nil)
        }

        Logger.persistence.warning("Persistent SwiftData store unavailable. Falling back to an in-memory container.")

        if let fallback = try? makeContainer(isStoredInMemoryOnly: true) {
            return PersistenceBootstrap(
                container: fallback,
                warningMessage: "Deine Datenbank konnte gerade nicht normal geöffnet werden. CamperReady läuft deshalb vorübergehend ohne dauerhafte Speicherung. Starte die App neu und exportiere wichtige Daten, bevor du weiterarbeitest."
            )
        }

        preconditionFailure("CamperReady could not create a SwiftData container.")
    }

    static func makePreviewContainer() -> ModelContainer {
        if let container = try? makeContainer(isStoredInMemoryOnly: true) {
            return container
        }

        preconditionFailure("CamperReady preview container could not be created.")
    }

    private static func makeContainer(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

private extension Logger {
    static let persistence = Logger(subsystem: "CamperReady", category: "Persistence")
}
