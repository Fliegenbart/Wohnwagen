import SwiftUI

struct ReadinessTile: View {
    let result: ReadinessDimensionResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(accentColor)
                Spacer()
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(accentColor)
                    .frame(width: 28, height: 6)
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
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.54))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(accentColor.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: AppTheme.ink.opacity(0.05), radius: 12, x: 0, y: 6)
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
