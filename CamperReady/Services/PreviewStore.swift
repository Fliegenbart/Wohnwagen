import Foundation
import SwiftData

enum PreviewStore {
    @MainActor
    static var container: ModelContainer = {
        let schema = Schema([
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

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        try! SampleDataSeeder.seedIfNeeded(context: container.mainContext)
        return container
    }()
}
