import SwiftData
import SwiftUI

@main
struct CamperReadyApp: App {
    private let bootstrap: PersistenceBootstrap
    @StateObject private var persistenceStatus: PersistenceStatus
    @StateObject private var activeVehicleStore = ActiveVehicleStore()

    init() {
        let bootstrap = PersistenceController.makeProductionBootstrap()
        self.bootstrap = bootstrap
        _persistenceStatus = StateObject(wrappedValue: PersistenceStatus(warningMessage: bootstrap.warningMessage))
    }

    var body: some Scene {
        WindowGroup {
            AppLaunchContainerView()
                .environmentObject(persistenceStatus)
                .environmentObject(activeVehicleStore)
        }
        .modelContainer(bootstrap.container)
    }
}
