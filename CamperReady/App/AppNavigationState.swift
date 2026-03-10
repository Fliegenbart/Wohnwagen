import Foundation

@MainActor
final class AppNavigationState: ObservableObject {
    @Published var selectedTab: AppTab = .home
}
