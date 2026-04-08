import Foundation

struct ReadinessDimensionMetadata: Equatable {
    let title: String
    let systemImage: String
    let action: ReadinessActionKind?
    let sortOrder: Int

    static func resolve(title: String) -> Self {
        switch title {
        case "Gewicht":
            .init(title: title, systemImage: "scalemass", action: .weight, sortOrder: 0)
        case "Dokumente & Fristen":
            .init(title: title, systemImage: "doc.text", action: .documents, sortOrder: 1)
        case "Wartung":
            .init(title: title, systemImage: "wrench.and.screwdriver", action: .maintenance, sortOrder: 2)
        case "Wasser & Saison":
            .init(title: title, systemImage: "drop", action: .departureChecklist, sortOrder: 3)
        case "Kosten":
            .init(title: title, systemImage: "eurosign.circle", action: .costs, sortOrder: 4)
        default:
            .init(title: title, systemImage: "checklist", action: nil, sortOrder: 99)
        }
    }
}

extension ReadinessDimensionResult {
    var metadata: ReadinessDimensionMetadata {
        ReadinessDimensionMetadata.resolve(title: title)
    }
}
