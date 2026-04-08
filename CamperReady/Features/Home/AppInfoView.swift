import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct AppInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isUpdatingNotifications = false

    var body: some View {
        NavigationStack {
            AppCanvas {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureHeader(
                            eyebrow: "Info",
                            title: "App & Hinweise",
                            subtitle: "Version, Erinnerungen, Rechtliches und Kontakt — alles hier."
                        )

                        SectionCard(title: "App", subtitle: "Version, Sprache und wer dahintersteckt.") {
                            VStack(alignment: .leading, spacing: 10) {
                                infoRow(title: "Version", value: AppReleaseConfiguration.appVersionDescription)
                                infoRow(title: "Speicherort", value: "Lokal auf deinem iPhone")
                                infoRow(title: "Sprache", value: "Deutsch")
                                infoRow(title: "Anbieter", value: AppReleaseConfiguration.providerName)
                            }
                        }

                        SectionCard(title: "Erinnerungen", subtitle: "Status und Zugriff auf Mitteilungen.") {
                            VStack(alignment: .leading, spacing: 12) {
                                infoRow(title: "Status", value: notificationStatusLabel)

                                if notificationStatus == .denied {
                                    Button("Einstellungen öffnen") {
                                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                            openURL(settingsURL)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                } else {
                                    Button(isUpdatingNotifications ? "Wird geprüft …" : reminderActionTitle) {
                                        Task { await updateNotifications() }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(isUpdatingNotifications)
                                }

                                Text("Erinnerungen sind optional — die App funktioniert auch ohne.")
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.mutedInk)
                            }
                        }

                        SectionCard(title: "Rechtliches", subtitle: "Anbieter und Rechtliches.") {
                            VStack(alignment: .leading, spacing: 10) {
                                infoRow(title: "Anbieter", value: AppReleaseConfiguration.providerName)
                                infoRow(title: "Adresse", value: AppReleaseConfiguration.providerAddress)

                                Text(AppReleaseConfiguration.legalDisclaimer)
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.ink)
                            }
                        }

                        SectionCard(title: "Links", subtitle: "Support, Datenschutz und mehr.") {
                            VStack(alignment: .leading, spacing: 12) {
                                configuredLinkRow(title: "Support", url: AppReleaseConfiguration.supportURL)
                                configuredLinkRow(title: "Datenschutz", url: AppReleaseConfiguration.privacyPolicyURL)
                                configuredLinkRow(title: "Website", url: AppReleaseConfiguration.marketingURL)
                                infoRow(title: "Kontakt", value: AppReleaseConfiguration.supportEmail)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Info & Rechtliches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
            .task {
                notificationStatus = await NotificationManager.shared.notificationStatus()
            }
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)
                .multilineTextAlignment(.trailing)
        }
    }

    private func configuredLinkRow(title: String, url: URL?) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Spacer()
            if let url {
                Link(url.absoluteString, destination: url)
                    .font(.subheadline)
                    .multilineTextAlignment(.trailing)
            } else {
                Text("Noch nicht hinterlegt")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
    }

    private var notificationStatusLabel: String {
        switch notificationStatus {
        case .notDetermined: "Noch nicht entschieden"
        case .denied: "Deaktiviert"
        case .authorized: "Aktiv"
        case .provisional: "Vorläufig aktiv"
        case .ephemeral: "Temporär aktiv"
        @unknown default: "Noch nicht erfasst"
        }
    }

    private var reminderActionTitle: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            "Erinnerungen aktualisieren"
        case .notDetermined:
            "Erinnerungen aktivieren"
        case .denied:
            "Einstellungen öffnen"
        @unknown default:
            "Erinnerungen prüfen"
        }
    }

    private func updateNotifications() async {
        isUpdatingNotifications = true
        defer { isUpdatingNotifications = false }

        if notificationStatus == .notDetermined {
            _ = await NotificationManager.shared.requestAuthorization()
        }

        notificationStatus = await NotificationManager.shared.notificationStatus()
        await NotificationManager.shared.rescheduleAllIfAuthorized(context: modelContext)
    }
}

#Preview {
    AppInfoView()
        .modelContainer(PreviewStore.container)
}
