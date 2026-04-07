import Foundation

enum AppReleaseConfiguration {
    static let providerName = "David Wegener Marketing Consulting GmbH"
    static let providerAddress = "Stockmeyerstraße 43, 20457 Hamburg"
    static let supportEmail = "mail@wegener-gmbh.com"

    static let privacyPolicyURL: URL? = URL(string: "https://www.wegener-gmbh.com/datenschutz-camperready")
    static let supportURL: URL? = URL(string: "https://www.wegener-gmbh.com")
    static let marketingURL: URL? = URL(string: "https://www.wegener-gmbh.com")

    static let legalDisclaimer = """
    CamperReady ist eine persönliche Organisations- und Erinnerungshilfe für private Camper-Besitzer:innen. Die App ersetzt keine technische Prüfung, keine Wiegung und keine Rechtsberatung. Vorschriften, Prüffristen und regionale Anforderungen können sich ändern.
    """

    static let shouldSeedSampleDataOnFirstLaunch = false

    static var appVersionDescription: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}
