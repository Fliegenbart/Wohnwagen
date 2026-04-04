import SwiftData
import SwiftUI

@main
struct CamperReadyApp: App {
    private let bootstrap: PersistenceBootstrap
    @StateObject private var persistenceStatus: PersistenceStatus

    init() {
        let bootstrap = PersistenceController.makeProductionBootstrap()
        self.bootstrap = bootstrap
        _persistenceStatus = StateObject(wrappedValue: PersistenceStatus(warningMessage: bootstrap.warningMessage))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(persistenceStatus)
        }
        .modelContainer(bootstrap.container)
    }
}
