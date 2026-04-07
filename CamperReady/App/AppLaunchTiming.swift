enum AppLaunchTiming {
    static let holdDurationSeconds: Double = 0.85
    static let fadeDurationSeconds: Double = 0.35

    static func holdDuration(reduceMotion: Bool) -> Double {
        reduceMotion ? 0.45 : holdDurationSeconds
    }
}
