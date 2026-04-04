import Foundation
import SwiftData
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private let requestPrefix = "camperready."

    private init() {}

    func notificationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func rescheduleAllIfAuthorized(context: ModelContext) async {
        let status = await notificationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }
        await rescheduleAll(context: context)
    }

    func rescheduleAll(context: ModelContext) async {
        let documents = (try? context.fetch(FetchDescriptor<DocumentRecord>())) ?? []
        let maintenance = (try? context.fetch(FetchDescriptor<MaintenanceEntry>())) ?? []
        let checklists = (try? context.fetch(FetchDescriptor<ChecklistRun>())) ?? []
        let checklistItems = (try? context.fetch(FetchDescriptor<ChecklistItemRecord>())) ?? []
        let trips = (try? context.fetch(FetchDescriptor<Trip>())) ?? []
        let costs = (try? context.fetch(FetchDescriptor<CostEntry>())) ?? []
        let currentOdometerKm = AppDataLocator.currentOdometerKm(maintenance: maintenance, costs: costs)
        let plans = ReminderPlanner.plans(
            documents: documents,
            maintenance: maintenance,
            checklists: checklists,
            checklistItems: checklistItems,
            trips: trips,
            currentOdometerKm: currentOdometerKm
        )
        await reschedule(plans: plans)
    }

    func rescheduleDocumentRemindersIfAuthorized(documents: [DocumentRecord]) async {
        let status = await notificationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }
        await rescheduleDocumentReminders(documents: documents)
    }

    func rescheduleDocumentReminders(documents: [DocumentRecord]) async {
        let plans = ReminderPlanner.plans(
            documents: documents,
            maintenance: [],
            checklists: [],
            checklistItems: [],
            trips: [],
            currentOdometerKm: nil
        )
        await reschedule(plans: plans)
    }

    private func reschedule(plans: [ReminderPlan]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(requestPrefix) }
            .map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: pending)

        for plan in plans {
            guard plan.fireDate > .now else { continue }
            let content = UNMutableNotificationContent()
            content.title = plan.title
            content.body = plan.body
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: plan.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(requestPrefix)\(plan.identifier)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }
}
