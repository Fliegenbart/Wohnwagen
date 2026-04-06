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
    static let storeDirectoryName = "CamperReady"
    static let storeFileName = "default.store"

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

    static func preparePersistentStoreLocation(baseDirectory: URL? = nil) throws -> URL {
        let rootDirectory = baseDirectory ?? defaultBaseDirectory()
        let storeDirectory = rootDirectory.appendingPathComponent(storeDirectoryName, isDirectory: true)
        try ensureProtectedDirectory(at: storeDirectory)
        return storeDirectory.appendingPathComponent(storeFileName)
    }

    private static func makeContainer(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        let configuration: ModelConfiguration
        let persistentStoreURL: URL?

        if isStoredInMemoryOnly {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            persistentStoreURL = nil
        } else {
            let storeURL = try preparePersistentStoreLocation()
            configuration = ModelConfiguration(schema: schema, url: storeURL)
            persistentStoreURL = storeURL
        }

        let container = try ModelContainer(for: schema, configurations: [configuration])

        if let persistentStoreURL {
            try protectPersistentStoreArtifacts(at: persistentStoreURL)
        }

        return container
    }

    private static func defaultBaseDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
    }

    private static func ensureProtectedDirectory(at directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: directory.path
        )
    }

    static func protectPersistentStoreArtifacts(at storeURL: URL) throws {
        let directory = storeURL.deletingLastPathComponent()
        try ensureProtectedDirectory(at: directory)

        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        for url in contents where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: url.path
            )
        }
    }
}

private extension Logger {
    static let persistence = Logger(subsystem: "CamperReady", category: "Persistence")
}
