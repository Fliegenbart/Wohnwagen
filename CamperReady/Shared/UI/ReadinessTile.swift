import SwiftUI

struct ReadinessTile: View {
    let result: ReadinessDimensionResult

    var body: some View {
        AlpineSurface(role: .raised) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: iconName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)
                        .frame(width: 28, height: 28)
                        .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text(result.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(2)

                    Spacer()

                    StatusBadge(status: result.status, text: result.status.compactTitle)
                }

                Text(result.summary)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(3)

                if let reason = result.reasons.first {
                    Text(reason)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppTheme.mutedInk)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let nextAction = result.nextAction {
                    Label(nextAction, systemImage: "arrow.right.circle.fill")
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
        case "Gewicht": "scalemass.fill"
        case "Gas & Dokumente": "doc.text.fill"
        case "Wartung": "wrench.and.screwdriver.fill"
        case "Wasser / Winter": "drop.fill"
        case "Kosten": "eurosign.circle.fill"
        default: "circle.grid.2x2.fill"
        }
    }
}
