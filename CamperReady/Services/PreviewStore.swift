import Foundation
import SwiftData

enum PreviewStore {
    @MainActor
    static var container: ModelContainer = {
        let container = PersistenceController.makePreviewContainer()
        do {
            try SampleDataSeeder.seedIfNeeded(context: container.mainContext)
        } catch {
            print("Preview seeding failed: \(error)")
        }
        return container
    }()
}
