import SwiftUI

struct ReadinessTile: View {
    let result: ReadinessDimensionResult

    var body: some View {
        AlpineSurface(role: .raised) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: result.metadata.systemImage)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(accentColor)
                        .frame(width: 24, height: 24)
                        .background(AppTheme.surfaceLow, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(result.title)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppTheme.mutedInk)
                            .lineLimit(1)

                        Text(result.summary)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(3)
                    }

                    Spacer(minLength: 8)

                    StatusBadge(status: result.status, text: result.status.compactTitle)
                }

                if let reason = result.reasons.first {
                    Text(reason)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.mutedInk)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let nextAction = result.nextAction {
                    Label(nextAction, systemImage: "arrow.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.petrol)
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
}
