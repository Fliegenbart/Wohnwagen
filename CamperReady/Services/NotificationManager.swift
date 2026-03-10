import Foundation
import SwiftData
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func notificationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func rescheduleDocumentRemindersIfAuthorized(documents: [DocumentRecord]) async {
        let status = await notificationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }
        await rescheduleDocumentReminders(documents: documents)
    }

    func rescheduleDocumentReminders(documents: [DocumentRecord]) async {
        let center = UNUserNotificationCenter.current()
        let prefix = "camperready.document."
        let pending = await center.pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(prefix) }
            .map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: pending)

        for document in documents {
            guard let validUntil = document.validUntil else { continue }
            let offsets: [(Int, Bool)] = [(90, document.remind90Days), (30, document.remind30Days), (7, document.remind7Days)]
            for (days, isEnabled) in offsets where isEnabled {
                guard let fireDate = Calendar.current.date(byAdding: .day, value: -days, to: validUntil), fireDate > .now else { continue }
                let content = UNMutableNotificationContent()
                content.title = "CamperReady Erinnerung"
                content.body = "\(document.title) lauft bald ab (\(validUntil.shortDateString()))."
                content.sound = .default

                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: "\(prefix)\(document.id.uuidString).\(days)", content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }
}
