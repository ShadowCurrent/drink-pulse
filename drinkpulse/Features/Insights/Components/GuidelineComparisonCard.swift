import SwiftUI

struct GuidelineComparisonCard: View {
    let comparisons: [GuidelineComparison]
    let weeklyGrams: Double

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
                Text(limitLabel(item))
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

    private func limitLabel(_ item: GuidelineComparison) -> String {
        String(format: "%.0f / %.0f g", item.weeklyGrams, item.limitGrams)
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
        GuidelineComparison(guideline: .who, name: "WHO", weeklyGrams: 60, limitGrams: 100),
        GuidelineComparison(guideline: .uk, name: "NHS (UK)", weeklyGrams: 60, limitGrams: 112),
        GuidelineComparison(guideline: .de, name: "DHS (DE)", weeklyGrams: 60, limitGrams: 168),
    ]
    return GuidelineComparisonCard(comparisons: comparisons, weeklyGrams: 60)
        .padding()
}
