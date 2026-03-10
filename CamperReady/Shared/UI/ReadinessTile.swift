import SwiftUI

struct ReadinessTile: View {
    let result: ReadinessDimensionResult

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundStyle(accentColor)
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Spacer()
                Circle()
                    .fill(accentColor)
                    .frame(width: 10, height: 10)
            }

            Text(result.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)

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
                    .foregroundStyle(accentColor)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(strokeColor: accentColor.opacity(0.25))
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
