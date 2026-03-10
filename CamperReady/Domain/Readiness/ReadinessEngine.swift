import Foundation

struct ReadinessDimensionResult: Identifiable {
    let id = UUID()
    let title: String
    let status: ReadinessStatus
    let summary: String
    let reasons: [String]
    let nextAction: String?
}

struct DashboardSnapshot {
    let vehicleName: String
    let nextTripTitle: String
    let overallStatus: ReadinessStatus
    let overallHeadline: String
    let openItemsCount: Int
    let dimensions: [ReadinessDimensionResult]
    let blockingItems: [String]
}

enum ReadinessStatus: Int, Comparable, Codable {
    case green = 0
    case yellow = 1
    case red = 2

    static func < (lhs: ReadinessStatus, rhs: ReadinessStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .green: "Bereit"
        case .yellow: "Achtung"
        case .red: "Nicht bereit"
        }
    }

    var compactTitle: String {
        switch self {
        case .green: "Bereit"
        case .yellow: "Prüfen"
        case .red: "Blockiert"
        }
    }
}

struct WeightContributor: Identifiable {
    let id = UUID()
    let label: String
    let weightKg: Double
}

struct WeightAssessmentInput {
    let vehicleName: String
    let gvwrKg: Double?
    let baseWeightKg: Double?
    let freshWaterCapacityL: Double?
    let gasBottleCount: Int
    let gasBottleSizeKg: Double?
    let gasBottleFillPercent: Double
    let packingItems: [WeightContributor]
    let passengers: [WeightContributor]
    let freshWaterLiters: Double
    let rearCarrierLoadKg: Double
    let roofLoadKg: Double
    let extraLoadKg: Double
    let bikesOnRearCarrier: Bool
    let hasMeasuredAxleValues: Bool
    let frontAxleMeasuredKg: Double?
    let rearAxleMeasuredKg: Double?
}

struct WeightAssessmentOutput {
    let status: ReadinessStatus
    let estimatedGrossWeightKg: Double?
    let remainingMarginKg: Double?
    let summary: String
    let warnings: [String]
    let nextAction: String?
    let contributors: [WeightContributor]
    let axleRisk: LoadRiskLevel
    let waterComparisonDeltaKg: Double
}

enum ReadinessEngine {
    static func buildDashboard(
        vehicle: VehicleProfile?,
        nextTrip: Trip?,
        weight: WeightAssessmentOutput,
        documents: [DocumentRecord],
        maintenance: [MaintenanceEntry],
        checklists: [ChecklistRun],
        checklistItems: [ChecklistItemRecord],
        costs: [CostEntry],
        now: Date = .now,
        currentOdometerKm: Double? = nil
    ) -> DashboardSnapshot {
        let legal = evaluateLegal(documents: documents, now: now)
        let maintenanceDimension = evaluateMaintenance(entries: maintenance, now: now, currentOdometerKm: currentOdometerKm)
        let waterWinter = evaluateWaterWinter(checklists: checklists, items: checklistItems, now: now)
        let costsDimension = evaluateCosts(costs: costs, tripID: nextTrip?.id)
        let weightDimension = ReadinessDimensionResult(
            title: "Gewicht",
            status: weight.status,
            summary: weight.summary,
            reasons: weight.warnings,
            nextAction: weight.nextAction
        )

        let dimensions = [weightDimension, legal, maintenanceDimension, waterWinter, costsDimension]
        let overallStatus = dimensions.map(\.status).max() ?? .yellow
        let blockingItems = dimensions
            .filter { $0.status == .red }
            .flatMap { result in
                result.reasons.isEmpty ? [result.summary] : result.reasons
            }

        let openItemsCount = dimensions.filter { $0.status != .green }.count
        let overallHeadline: String
        if overallStatus == .green {
            overallHeadline = "Abfahrbereit"
        } else if overallStatus == .red {
            overallHeadline = "Nicht bereit"
        } else {
            overallHeadline = "\(openItemsCount) Punkte offen"
        }

        return DashboardSnapshot(
            vehicleName: vehicle?.name ?? "Kein Fahrzeug",
            nextTripTitle: nextTrip?.title ?? "Keine Reise geplant",
            overallStatus: overallStatus,
            overallHeadline: overallHeadline,
            openItemsCount: openItemsCount,
            dimensions: dimensions,
            blockingItems: blockingItems
        )
    }

    static func assessWeight(_ input: WeightAssessmentInput) -> WeightAssessmentOutput {
        guard let gvwrKg = input.gvwrKg, let baseWeightKg = input.baseWeightKg else {
            return WeightAssessmentOutput(
                status: .yellow,
                estimatedGrossWeightKg: nil,
                remainingMarginKg: nil,
                summary: "Gewicht unvollständig",
                warnings: ["zGG oder Leergewicht fehlt. Die Anzeige bleibt bewusst vorsichtig."],
                nextAction: "zGG und gemessenes Leergewicht nachtragen",
                contributors: (input.packingItems + input.passengers).sorted(by: { $0.weightKg > $1.weightKg }),
                axleRisk: .elevated,
                waterComparisonDeltaKg: max((input.freshWaterCapacityL ?? 0) - input.freshWaterLiters, 0)
            )
        }

        let gasKg = Double(input.gasBottleCount) * (input.gasBottleSizeKg ?? 0) * (input.gasBottleFillPercent / 100)
        let contributorPool = input.packingItems + input.passengers + [
            WeightContributor(label: "Frischwasser", weightKg: input.freshWaterLiters),
            WeightContributor(label: "Gas", weightKg: gasKg),
            WeightContributor(label: "Heckträger", weightKg: input.rearCarrierLoadKg),
            WeightContributor(label: "Dachlast", weightKg: input.roofLoadKg),
            WeightContributor(label: "Zusatzlast", weightKg: input.extraLoadKg)
        ]

        let variableLoadKg = contributorPool.map(\.weightKg).reduce(0, +)
        let estimatedGrossWeightKg = baseWeightKg + variableLoadKg
        let remainingMarginKg = gvwrKg - estimatedGrossWeightKg
        let riskPatterns = [
            input.bikesOnRearCarrier,
            input.rearCarrierLoadKg >= 40,
            input.roofLoadKg >= 30,
            input.passengers.count >= 4,
            input.freshWaterLiters >= 80
        ]
        let elevatedAxleRisk = !input.hasMeasuredAxleValues && riskPatterns.contains(true)

        let status: ReadinessStatus
        if remainingMarginKg < 0 {
            status = .red
        } else if remainingMarginKg <= 100 || remainingMarginKg / gvwrKg <= 0.05 || elevatedAxleRisk {
            status = .yellow
        } else {
            status = .green
        }

        let summary: String
        if remainingMarginKg < 0 {
            summary = "Überladen um \(Int(abs(remainingMarginKg).rounded())) kg"
        } else {
            summary = "+\(Int(remainingMarginKg.rounded())) kg Reserve"
        }

        var warnings: [String] = []
        if remainingMarginKg < 0 {
            warnings.append("Das geschätzte Gesamtgewicht liegt über der zGG.")
        } else if remainingMarginKg <= 100 {
            warnings.append("Die Reserve ist knapp. Vor der Abfahrt besser nachwiegen.")
        }

        if elevatedAxleRisk {
            warnings.append("Achslast unbekannt bei riskanter Beladung. Wiegen empfohlen.")
        } else if input.hasMeasuredAxleValues {
            warnings.append("Achslaststatus basiert auf echten Messwerten.")
        }

        let nextAction: String?
        if remainingMarginKg < 0 {
            nextAction = "Beladung reduzieren oder Wasserstand senken"
        } else if elevatedAxleRisk {
            nextAction = "Achslast an einer Waage prüfen"
        } else {
            nextAction = "Aktuelle Beladung speichern"
        }

        return WeightAssessmentOutput(
            status: status,
            estimatedGrossWeightKg: estimatedGrossWeightKg,
            remainingMarginKg: remainingMarginKg,
            summary: summary,
            warnings: warnings,
            nextAction: nextAction,
            contributors: contributorPool.filter { $0.weightKg > 0 }.sorted(by: { $0.weightKg > $1.weightKg }),
            axleRisk: input.hasMeasuredAxleValues ? .measured : (elevatedAxleRisk ? .elevated : .low),
            waterComparisonDeltaKg: max((input.freshWaterCapacityL ?? input.freshWaterLiters) - input.freshWaterLiters, 0)
        )
    }

    static func evaluateLegal(documents: [DocumentRecord], now: Date = .now) -> ReadinessDimensionResult {
        let relevantDocs = documents.filter(\.isStatusRelevant)
        guard !relevantDocs.isEmpty else {
            return ReadinessDimensionResult(
                title: "Gas & Dokumente",
                status: .yellow,
                summary: "Noch keine Fristen hinterlegt",
                reasons: ["Dokumente und Prüfungen sind editierbar und bewusst keine Rechtsberatung."],
                nextAction: "Mindestens HU, Versicherung und Gasprüfung anlegen"
            )
        }

        let expiredBlocking = relevantDocs.filter {
            guard let validUntil = $0.validUntil else { return false }
            return $0.isBlockingWhenExpired && validUntil < now
        }
        let upcoming = relevantDocs.compactMap { record -> (DocumentRecord, Int)? in
            guard let validUntil = record.validUntil else { return nil }
            let days = Calendar.current.dateComponents([.day], from: now, to: validUntil).day ?? .max
            return (record, days)
        }.sorted { $0.1 < $1.1 }

        if let expired = expiredBlocking.first {
            return ReadinessDimensionResult(
                title: "Gas & Dokumente",
                status: .red,
                summary: "\(expired.title) abgelaufen",
                reasons: ["\(expired.title) ist seit \(expired.validUntil?.shortDateString() ?? "") abgelaufen."],
                nextAction: "Nachweis erneuern oder Termin planen"
            )
        }

        if let nextDue = upcoming.first, nextDue.1 <= 30 {
            return ReadinessDimensionResult(
                title: "Gas & Dokumente",
                status: .yellow,
                summary: "\(nextDue.0.title) fällig bis \(nextDue.0.validUntil?.monthYearString() ?? "")",
                reasons: ["Frist endet in \(max(nextDue.1, 0)) Tagen."],
                nextAction: "Dokument prüfen und Erinnerung bestätigen"
            )
        }

        if let farthest = upcoming.first {
            return ReadinessDimensionResult(
                title: "Gas & Dokumente",
                status: .green,
                summary: "\(farthest.0.title) gültig bis \(farthest.0.validUntil?.monthYearString() ?? "")",
                reasons: ["Regeln können sich ändern. Quellenhinweise bleiben editierbar."],
                nextAction: "Nachweise aktuell halten"
            )
        }

        return ReadinessDimensionResult(
            title: "Gas & Dokumente",
            status: .yellow,
            summary: "Laufzeit unklar",
            reasons: ["Mindestens ein Nachweis hat kein Gültig-bis-Datum."],
            nextAction: "Laufzeiten ergänzen"
        )
    }

    static func evaluateMaintenance(
        entries: [MaintenanceEntry],
        now: Date = .now,
        currentOdometerKm: Double? = nil
    ) -> ReadinessDimensionResult {
        guard !entries.isEmpty else {
            return ReadinessDimensionResult(
                title: "Wartung",
                status: .yellow,
                summary: "Kein Wartungsverlauf vorhanden",
                reasons: ["Ohne Einträge können Fälligkeiten nicht bewertet werden."],
                nextAction: "Letzte Services eintragen"
            )
        }

        let overdue = entries.first { entry in
            if let nextDueDate = entry.nextDueDate, nextDueDate < now { return true }
            if let currentOdometerKm, let dueKm = entry.nextDueOdometerKm, currentOdometerKm > dueKm { return true }
            return false
        }

        if let overdue {
            return ReadinessDimensionResult(
                title: "Wartung",
                status: .red,
                summary: "\(overdue.title) überfällig",
                reasons: ["Nächster Service wurde überschritten."],
                nextAction: "Werkstatttermin oder Eigeneintrag planen"
            )
        }

        let soon = entries.compactMap { entry -> (MaintenanceEntry, Int)? in
            guard let nextDueDate = entry.nextDueDate else { return nil }
            let days = Calendar.current.dateComponents([.day], from: now, to: nextDueDate).day ?? .max
            return (entry, days)
        }.sorted { $0.1 < $1.1 }.first

        if let soon, soon.1 <= 45 {
            return ReadinessDimensionResult(
                title: "Wartung",
                status: .yellow,
                summary: "\(soon.0.title) in \(max(soon.1, 0)) Tagen fällig",
                reasons: ["Wartung naht. Reiseplanung und Werkstattfenster abstimmen."],
                nextAction: "Termin vormerken"
            )
        }

        let recent = entries.sorted(by: { $0.date > $1.date }).first
        return ReadinessDimensionResult(
            title: "Wartung",
            status: .green,
            summary: recent.map { "Letzter Eintrag: \($0.title)" } ?? "Wartung im Plan",
            reasons: ["Keine überfälligen Services erkannt."],
            nextAction: "Nächste Fristen im Blick behalten"
        )
    }

    static func evaluateWaterWinter(
        checklists: [ChecklistRun],
        items: [ChecklistItemRecord],
        now: Date = .now
    ) -> ReadinessDimensionResult {
        let relevantModes: Set<ChecklistMode> = [.departure, .winterize, .deWinterize]
        let relevantChecklists = checklists
            .filter { relevantModes.contains($0.mode) }
            .sorted(by: { $0.updatedAt > $1.updatedAt })

        guard let latest = relevantChecklists.first else {
            return ReadinessDimensionResult(
                title: "Wasser / Winter",
                status: .yellow,
                summary: "Kein Modus aktiv",
                reasons: ["Abfahrts- oder Wintermodus wurde noch nicht gestartet."],
                nextAction: "Passenden Modus starten"
            )
        }

        let checklistItems = items.filter { $0.checklistID == latest.id }
        let required = checklistItems.filter(\.isRequired)
        let openRequired = required.filter { !$0.isCompleted }
        let isColdSeason = Calendar.current.component(.month, from: now).isIn([11, 12, 1, 2, 3])

        if latest.mode == .departure && !openRequired.isEmpty {
            return ReadinessDimensionResult(
                title: "Wasser / Winter",
                status: .yellow,
                summary: "Abfahrtscheck unvollständig",
                reasons: openRequired.prefix(2).map { "\($0.title) noch offen." },
                nextAction: "Vor Abfahrt prüfen"
            )
        }

        if latest.mode == .winterize && isColdSeason && !openRequired.isEmpty {
            return ReadinessDimensionResult(
                title: "Wasser / Winter",
                status: .yellow,
                summary: "Wintermodus unvollständig",
                reasons: openRequired.prefix(2).map { "\($0.title) noch offen." },
                nextAction: "Wasser- und Gasanlage sichern"
            )
        }

        return ReadinessDimensionResult(
            title: "Wasser / Winter",
            status: .green,
            summary: "\(latest.mode.title) komplett",
            reasons: ["Letzter operativer Modus wurde abgeschlossen."],
            nextAction: "Status bei Wetterumschwung neu prüfen"
        )
    }

    static func evaluateCosts(costs: [CostEntry], tripID: UUID?) -> ReadinessDimensionResult {
        let tripCosts = costs.filter { $0.tripID == tripID && !$0.isRecurringFixedCost }
        let fixedCosts = costs.filter(\.isRecurringFixedCost)
        let tripTotal = tripCosts.map(\.amountEUR).reduce(0, +)
        let annualFixedTotal = fixedCosts.reduce(0) { partial, entry in
            partial + annualizedAmount(for: entry)
        }

        if tripID == nil {
            return ReadinessDimensionResult(
                title: "Kosten",
                status: .yellow,
                summary: "Keine aktive Reise",
                reasons: ["Fixkosten \(annualFixedTotal.euroString) pro Jahr erfasst."],
                nextAction: "Reise anlegen, um variable Kosten zu tracken"
            )
        }

        if tripCosts.isEmpty {
            return ReadinessDimensionResult(
                title: "Kosten",
                status: .yellow,
                summary: "Noch keine Reisekosten",
                reasons: ["Fixkosten \(annualFixedTotal.euroString) pro Jahr hinterlegt."],
                nextAction: "Tankung, Maut oder Stellplatz erfassen"
            )
        }

        return ReadinessDimensionResult(
            title: "Kosten",
            status: .green,
            summary: "Diese Reise: \(tripTotal.euroString)",
            reasons: ["Fixkosten hochgerechnet: \(annualFixedTotal.euroString) pro Jahr."],
            nextAction: "Kosten pro 100 km beobachten"
        )
    }

    static func annualizedAmount(for entry: CostEntry) -> Double {
        guard entry.isRecurringFixedCost else { return 0 }
        return switch entry.recurrence {
        case .monthly: entry.amountEUR * 12
        case .quarterly: entry.amountEUR * 4
        case .yearly: entry.amountEUR
        case nil: entry.amountEUR
        }
    }
}

private extension Int {
    func isIn(_ values: [Int]) -> Bool {
        values.contains(self)
    }
}
