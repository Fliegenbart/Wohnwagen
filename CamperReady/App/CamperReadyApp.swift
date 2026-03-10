import SwiftData
import SwiftUI

@main
struct CamperReadyApp: App {
    private let container: ModelContainer = {
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

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
    }
}
