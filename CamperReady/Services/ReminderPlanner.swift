import Foundation

struct ReminderPlan: Identifiable, Equatable {
    let identifier: String
    let title: String
    let body: String
    let fireDate: Date

    var id: String { identifier }
}

enum ReminderPlanner {
    static func plans(
        documents: [DocumentRecord],
        maintenance: [MaintenanceEntry],
        checklists: [ChecklistRun],
        checklistItems: [ChecklistItemRecord],
        trips: [Trip],
        currentOdometerKm: Double?,
        now: Date = .now
    ) -> [ReminderPlan] {
        var output: [ReminderPlan] = []
        output.append(contentsOf: documentPlans(documents: documents, now: now))
        output.append(contentsOf: maintenancePlans(entries: maintenance, currentOdometerKm: currentOdometerKm, now: now))
        output.append(contentsOf: departurePlans(checklists: checklists, items: checklistItems, trips: trips, now: now))
        output.append(contentsOf: seasonalPlans(checklists: checklists, items: checklistItems, now: now))
        return output.sorted { $0.fireDate < $1.fireDate }
    }

    private static func documentPlans(documents: [DocumentRecord], now: Date) -> [ReminderPlan] {
        documents.flatMap { document -> [ReminderPlan] in
            guard let validUntil = document.validUntil else { return [] }

            let offsets: [(Int, Bool)] = [(90, document.remind90Days), (30, document.remind30Days), (7, document.remind7Days)]
            return offsets.compactMap { days, isEnabled in
                guard isEnabled else { return nil }
                guard let fireDate = Calendar.current.date(byAdding: .day, value: -days, to: validUntil), fireDate > now else { return nil }
                return ReminderPlan(
                    identifier: "document.\(document.id.uuidString).\(days)",
                    title: "Frist im Blick behalten",
                    body: "\(document.title) läuft bald ab. Prüfe den Nachweis rechtzeitig.",
                    fireDate: fireDate
                )
            }
        }
    }

    private static func maintenancePlans(entries: [MaintenanceEntry], currentOdometerKm: Double?, now: Date) -> [ReminderPlan] {
        var plans: [ReminderPlan] = []

        for entry in entries {
            if let nextDueDate = entry.nextDueDate, nextDueDate > now {
                let daysUntil = Calendar.current.dateComponents([.day], from: now, to: nextDueDate).day ?? .max
                if daysUntil <= 45 {
                    plans.append(
                        ReminderPlan(
                            identifier: "maintenance.date.\(entry.id.uuidString)",
                            title: "Wartung rückt näher",
                            body: "\(entry.title) ist bald fällig. Plane den nächsten Schritt rechtzeitig.",
                            fireDate: nextDueDate.addingTimeInterval(-7 * 24 * 60 * 60)
                        )
                    )
                }
            }

            if let currentOdometerKm, let dueKm = entry.nextDueOdometerKm, dueKm - currentOdometerKm <= 500 {
                plans.append(
                    ReminderPlan(
                        identifier: "maintenance.km.\(entry.id.uuidString)",
                        title: "Kilometerstand prüfen",
                        body: "\(entry.title) ist bald fällig. Vergleiche den aktuellen Kilometerstand mit deinem Zielwert.",
                        fireDate: now.addingTimeInterval(60)
                    )
                )
            }
        }

        return plans
    }

    private static func departurePlans(
        checklists: [ChecklistRun],
        items: [ChecklistItemRecord],
        trips: [Trip],
        now: Date
    ) -> [ReminderPlan] {
        let activeTrips = trips.filter(\.isActive)
        return activeTrips.compactMap { trip in
            guard let departureChecklist = checklists.first(where: { $0.tripID == trip.id && $0.mode == .departure }) else { return nil }
            let openRequired = items
                .filter { $0.checklistID == departureChecklist.id && $0.isRequired && !$0.isCompleted }
            guard openRequired.isEmpty == false else { return nil }

            let startOfDay = Calendar.current.startOfDay(for: trip.startDate)
            let daysUntilTrip = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: startOfDay).day ?? .max
            guard daysUntilTrip <= 3 else { return nil }

            let reminderDate = max(now.addingTimeInterval(60), Calendar.current.date(byAdding: .hour, value: -18, to: trip.startDate) ?? trip.startDate)
            return ReminderPlan(
                identifier: "departure.\(trip.id.uuidString)",
                title: "Vor der Abfahrt noch offen",
                body: "Deine Abfahrtscheckliste ist noch nicht komplett. Prüfe die offenen Punkte vor dem Losfahren.",
                fireDate: reminderDate
            )
        }
    }

    private static func seasonalPlans(checklists: [ChecklistRun], items: [ChecklistItemRecord], now: Date) -> [ReminderPlan] {
        let month = Calendar.current.component(.month, from: now)

        if [10, 11, 12].contains(month) {
            return seasonalPlan(for: .winterize, title: "Einwintern prüfen", body: "Prüfe Wasser, Gas und Lagerzustand, bevor es richtig kalt wird.", checklists: checklists, items: items, now: now)
        }

        if [3, 4].contains(month) {
            return seasonalPlan(for: .deWinterize, title: "Auswintern prüfen", body: "Prüfe Wasseranlage und Gasversorgung, bevor die Saison startet.", checklists: checklists, items: items, now: now)
        }

        return []
    }

    private static func seasonalPlan(
        for mode: ChecklistMode,
        title: String,
        body: String,
        checklists: [ChecklistRun],
        items: [ChecklistItemRecord],
        now: Date
    ) -> [ReminderPlan] {
        guard let latest = checklists
            .filter({ $0.mode == mode })
            .sorted(by: { $0.updatedAt > $1.updatedAt })
            .first
        else {
            return [
                ReminderPlan(
                    identifier: "seasonal.\(mode.rawValue).missing",
                    title: title,
                    body: body,
                    fireDate: now.addingTimeInterval(60)
                )
            ]
        }

        let openRequired = items.filter { $0.checklistID == latest.id && $0.isRequired && !$0.isCompleted }
        guard openRequired.isEmpty == false else { return [] }

        return [
            ReminderPlan(
                identifier: "seasonal.\(mode.rawValue).\(latest.id.uuidString)",
                title: title,
                body: body,
                fireDate: now.addingTimeInterval(60)
            )
        ]
    }
}
