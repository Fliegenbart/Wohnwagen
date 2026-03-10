import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct AppInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Query(sort: \DocumentRecord.validUntil) private var documents: [DocumentRecord]

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isUpdatingNotifications = false

    var body: some View {
        NavigationStack {
            AppCanvas {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        hero

                        SectionCard(title: "App") {
                            VStack(alignment: .leading, spacing: 10) {
                                infoRow(title: "Version", value: AppReleaseConfiguration.appVersionDescription)
                                infoRow(title: "Betrieb", value: "Offline-first, lokal auf diesem iPhone")
                                infoRow(title: "Region", value: "Deutsch als Primärsprache, DACH-ready")
                            }
                        }

                        SectionCard(title: "Erinnerungen") {
                            VStack(alignment: .leading, spacing: 12) {
                                infoRow(title: "Status", value: notificationStatusLabel)

                                if notificationStatus == .denied {
                                    Button("Mitteilungen in den Einstellungen öffnen") {
                                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                            openURL(settingsURL)
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                } else {
                                    Button(isUpdatingNotifications ? "Aktualisiere…" : reminderActionTitle) {
                                        Task { await updateNotifications() }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(isUpdatingNotifications)
                                }

                                Text("Dokumenten-Erinnerungen bleiben optional und funktionieren auch dann nicht blockierend, wenn Mitteilungen abgelehnt wurden.")
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.mutedInk)
                            }
                        }

                        SectionCard(title: "Rechtliches") {
                            Text(AppReleaseConfiguration.legalDisclaimer)
                                .font(.footnote)
                                .foregroundStyle(AppTheme.ink)
                        }

                        SectionCard(title: "Links") {
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

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Release-Info")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.78))
                    Text("CamperReady")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Persönliches Bereitschafts-Cockpit statt Camping-Marktplatz.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                Image(systemName: "info.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            HStack(spacing: 10) {
                heroPill(title: "Version", value: AppReleaseConfiguration.appVersionDescription)
                heroPill(title: "Support", value: "Vorbereitet")
                heroPill(title: "Privatsphäre", value: "Lokal")
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppTheme.accent.opacity(0.95), Color(red: 0.20, green: 0.58, blue: 0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .shadow(color: AppTheme.accent.opacity(0.24), radius: 28, x: 0, y: 16)
    }

    private func heroPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.72))
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                Text("Vor Release ergänzen")
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
        @unknown default: "Unbekannt"
        }
    }

    private var reminderActionTitle: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            "Erinnerungen aktualisieren"
        case .notDetermined:
            "Erinnerungen aktivieren"
        case .denied:
            "Mitteilungen aktivieren"
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
        await NotificationManager.shared.rescheduleDocumentRemindersIfAuthorized(documents: documents)
    }
}

#Preview {
    AppInfoView()
        .modelContainer(PreviewStore.container)
}
