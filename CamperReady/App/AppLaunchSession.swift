import Combine
import Foundation

final class AppLaunchSession: ObservableObject {
    typealias Sleep = @Sendable (TimeInterval) async -> Void

    @Published private(set) var isReady = false
    @Published private(set) var isLaunching = false

    private let sleep: Sleep

    init(sleep: @escaping Sleep = {
        let nanoseconds = UInt64($0 * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }) {
        self.sleep = sleep
    }

    @MainActor
    func start(reduceMotion: Bool) async {
        guard !isReady, !isLaunching else { return }

        isLaunching = true
        defer { isLaunching = false }

        await sleep(AppLaunchTiming.holdDuration(reduceMotion: reduceMotion))

        guard !Task.isCancelled else { return }

        isReady = true
    }
}
