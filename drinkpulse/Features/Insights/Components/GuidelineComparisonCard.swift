import SwiftUI

struct GuidelineComparisonCard: View {
    let comparisons: [GuidelineComparison]
    /// Formats the "consumed / limit" figure in the user's chosen unit.
    let label: (GuidelineComparison) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "insights.section.guidelineComparison"))
                .font(.headline)
            ForEach(comparisons) { comparison in
                comparisonRow(comparison)
                if comparison.id != comparisons.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .dpGlassCard()
        .accessibilityElement(children: .contain)
    }

    private func comparisonRow(_ item: GuidelineComparison) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(label(item))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(for: item.fraction))
                        .frame(width: geo.size.width * min(item.fraction, 1))
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(item))
    }

    private func barColor(for fraction: Double) -> Color {
        RiskLevel.from(pct: fraction).chartColor
    }

    private func accessibilityLabel(_ item: GuidelineComparison) -> String {
        let pct = Int(item.fraction * 100)
        return "\(item.name): \(pct)% \(String(localized: "insights.guideline.ofLimit"))"
    }
}

#Preview {
    let comparisons = [
        GuidelineComparison(guideline: .who, name: "WHO", consumedGrams: 60, limitGrams: 700),
        GuidelineComparison(guideline: .uk, name: "NHS (UK)", consumedGrams: 60, limitGrams: 784),
        GuidelineComparison(guideline: .de, name: "DHS (DE)", consumedGrams: 60, limitGrams: 1176),
    ]
    return GuidelineComparisonCard(comparisons: comparisons) {
        String(format: "%.0f / %.0f g", $0.consumedGrams, $0.limitGrams)
    }
    .padding()
}
