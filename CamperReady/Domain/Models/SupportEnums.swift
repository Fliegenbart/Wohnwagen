import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case weight
    case checklists
    case logbook
    case costs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Cockpit"
        case .weight: "Gewicht"
        case .checklists: "Checklisten"
        case .logbook: "Logbuch"
        case .costs: "Kosten"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .weight: "scalemass"
        case .checklists: "checklist"
        case .logbook: "wrench.and.screwdriver"
        case .costs: "eurosign.circle"
        }
    }
}

enum CountryPreset: String, CaseIterable, Codable, Identifiable {
    case de
    case at
    case ch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .de: "Deutschland"
        case .at: "Österreich"
        case .ch: "Schweiz"
        }
    }

    var shortLabel: String { rawValue.uppercased() }
}

enum VehicleKind: String, CaseIterable, Codable, Identifiable {
    case campervan
    case motorhome

    var id: String { rawValue }

    var title: String {
        switch self {
        case .campervan: "Campervan"
        case .motorhome: "Wohnmobil"
        }
    }
}

enum GasBottleType: String, CaseIterable, Codable, Identifiable {
    case steel
    case aluminum
    case composite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .steel: "Stahl"
        case .aluminum: "Aluminium"
        case .composite: "Komposit"
        }
    }
}

enum WeightCategory: String, CaseIterable, Codable, Identifiable {
    case kitchen
    case clothing
    case outdoor
    case tech
    case tools
    case kidsPets
    case bikes
    case campingFurniture
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kitchen: "Küche"
        case .clothing: "Kleidung"
        case .outdoor: "Outdoor & Freizeit"
        case .tech: "Technik & Kabel"
        case .tools: "Werkzeug"
        case .kidsPets: "Kinder & Vierbeiner"
        case .bikes: "Fahrräder"
        case .campingFurniture: "Tisch, Stuhl & Co."
        case .other: "Sonstiges"
        }
    }
}

enum ChecklistMode: String, CaseIterable, Codable, Identifiable {
    case departure
    case arrival
    case shortStop
    case storage
    case winterize
    case deWinterize

    var id: String { rawValue }

    var title: String {
        switch self {
        case .departure: "Vor der Abfahrt"
        case .arrival: "Ankunft"
        case .shortStop: "Kurzer Halt"
        case .storage: "Einlagern"
        case .winterize: "Winterschlaf"
        case .deWinterize: "Frühjahrsstart"
        }
    }
}

enum ChecklistState: String, CaseIterable, Codable, Identifiable {
    case notStarted
    case inProgress
    case complete

    var id: String { rawValue }
}

enum MaintenanceCategory: String, CaseIterable, Codable, Identifiable {
    case oilChange
    case inspection
    case tireChange
    case brakes
    case leakTest
    case battery
    case gasInspection
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oilChange: "Ölwechsel"
        case .inspection: "Inspektion"
        case .tireChange: "Reifenwechsel"
        case .brakes: "Bremsen"
        case .leakTest: "Dichtigkeitsprüfung"
        case .battery: "Batterie"
        case .gasInspection: "Gasprüfung"
        case .custom: "Eigener Eintrag"
        }
    }
}

enum DocumentCategory: String, CaseIterable, Codable, Identifiable {
    case registration
    case insurance
    case roadworthiness
    case gasInspection
    case toll
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .registration: "Fahrzeugschein"
        case .insurance: "Versicherung"
        case .roadworthiness: "HU / TÜV"
        case .gasInspection: "Gasprüfung"
        case .toll: "Vignette & Maut"
        case .custom: "Eigenes Dokument"
        }
    }
}

enum PlaceType: String, CaseIterable, Codable, Identifiable {
    case stopover
    case campsite
    case serviceStation
    case dump
    case water

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stopover: "Stellplatz"
        case .campsite: "Campingplatz"
        case .serviceStation: "Ver- & Entsorgung"
        case .dump: "Entsorgung"
        case .water: "Frischwasser"
        }
    }
}

enum CostCategory: String, CaseIterable, Codable, Identifiable {
    case fuel
    case toll
    case ferry
    case campsite
    case gas
    case electricity
    case waterDisposal
    case workshop
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fuel: "Tanken"
        case .toll: "Maut & Vignette"
        case .ferry: "Fähre"
        case .campsite: "Stell- & Campingplatz"
        case .gas: "Gas"
        case .electricity: "Strom"
        case .waterDisposal: "Wasser & Entsorgung"
        case .workshop: "Werkstatt & Teile"
        case .other: "Sonstiges"
        }
    }
}

enum FixedCostInterval: String, CaseIterable, Codable, Identifiable {
    case monthly
    case quarterly
    case yearly

    var id: String { rawValue }
}

enum LoadRiskLevel: String, CaseIterable, Codable, Identifiable {
    case low
    case elevated
    case measured

    var id: String { rawValue }
}

extension Double {
    var kgString: String { "\(Int(self.rounded())) kg" }
    var literString: String { "\(Int(self.rounded())) l" }
    var euroString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: NSNumber(value: self)) ?? "\(self) EUR"
    }
}

extension Date {
    func monthYearString(locale: Locale = Locale(identifier: "de_DE")) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "MM/yyyy"
        return formatter.string(from: self)
    }

    func shortDateString(locale: Locale = Locale(identifier: "de_DE")) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
}
