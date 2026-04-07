import SwiftUI

struct ReadinessTile: View {
    let result: ReadinessDimensionResult

    var body: some View {
        AlpineSurface(role: .section) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: iconName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(accentColor)
                        .frame(width: 28, height: 28)
                        .background(accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title.uppercased())
                            .font(.caption.weight(.bold))
                            .tracking(0.8)
                            .foregroundStyle(AppTheme.mutedInk)
                            .lineLimit(1)

                        Text(result.summary)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(3)
                    }

                    Spacer()

                    StatusBadge(status: result.status, text: result.status.compactTitle)
                }

                if let reason = result.reasons.first {
                    Text(reason)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppTheme.mutedInk)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let nextAction = result.nextAction {
                    Label(nextAction, systemImage: "arrow.up.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.petrolBright)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(result.title)
        .accessibilityValue([result.summary, result.reasons.first, result.nextAction]
            .compactMap { $0 }
            .joined(separator: ". "))
    }

    private var accentColor: Color {
        AppTheme.statusColor(result.status)
    }

    private var iconName: String {
        switch result.title {
        case "Gewicht": "scalemass"
        case "Gas & Dokumente": "doc.text"
        case "Wartung": "wrench.and.screwdriver"
        case "Wasser / Winter": "drop"
        case "Kosten": "eurosign.circle"
        default: "circle.grid.2x2"
        }
    }
}
