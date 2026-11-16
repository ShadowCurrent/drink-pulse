import SwiftUI

struct HealthMetricsCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let vm: InsightsViewModel

    /// Two flexible columns, one at accessibility sizes so titles and values can wrap.
    private var gridColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "insights.section.healthImpact"))
                .font(.headline)
            LazyVGrid(columns: gridColumns, spacing: 10) {
                MetricCell(
                    icon: "exclamationmark.triangle.fill",
                    color: .dpRiskHigh,
                    title: String(localized: "insights.metric.bingeEpisodes"),
                    value: "\(vm.bingeEpisodes)"
                )
                MetricCell(
                    icon: "flame.fill",
                    color: .dpAmber,
                    title: String(localized: "insights.metric.calories"),
                    value: "\(vm.periodCaloriesKcal) kcal"
                )
                MetricCell(
                    icon: "moon.fill",
                    color: .dpTeal,
                    title: String(localized: "insights.metric.drinkFreeDays"),
                    value: "\(vm.drinkFreeDays.count)/\(vm.drinkFreeDays.total)",
                    subtitle: drinkFreeSubtitle
                )
                MetricCell(
                    icon: "trophy.fill",
                    color: .dpPurple,
                    title: String(localized: "insights.metric.soberStreak"),
                    value: "\(vm.longestSoberStreak) d"
                )
                heaviestDayCell
                spendCell
            }
        }
        .padding()
        .dpGlassCard()
    }

    private var drinkFreeSubtitle: String {
        let total = vm.drinkFreeDays.total
        guard total > 0 else { return "" }
        let pct = Int(Double(vm.drinkFreeDays.count) / Double(total) * 100)
        return "\(pct)%"
    }

    @ViewBuilder
    private var heaviestDayCell: some View {
        if let (grams, date) = vm.heaviestDay {
            MetricCell(
                icon: "chart.line.uptrend.xyaxis",
                color: .dpRiskModerate,
                title: String(localized: "insights.metric.heaviestDay"),
                value: vm.formattedValue(grams),
                subtitle: date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
            )
        } else {
            MetricCell(
                icon: "chart.line.uptrend.xyaxis",
                color: .dpRiskModerate,
                title: String(localized: "insights.metric.heaviestDay"),
                value: "–"
            )
        }
    }

    @ViewBuilder
    private var spendCell: some View {
        if let spend = vm.periodSpend {
            MetricCell(
                icon: "eurosign.circle",
                color: .dpGreen,
                title: String(localized: "insights.metric.spend"),
                value: vm.formattedSpend(spend),
                subtitle: spendSubtitle
            )
        } else {
            MetricCell(
                icon: "eurosign.circle",
                color: .dpGreen,
                title: String(localized: "insights.metric.spend"),
                value: "–"
            )
        }
    }

    private var spendSubtitle: String {
        guard let perDay = vm.periodSpendPerDay else { return "" }
        return vm.formattedSpend(perDay) + "/" + String(localized: "unit.day")
    }
}

// MARK: - Metric grid cell

private struct MetricCell: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var iconSize: Double = 30

    let icon: String
    let color: Color
    let title: String
    let value: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: iconSize, height: iconSize)
                .background(color.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)

            Text(value)
                .font(.callout.weight(.bold))
                .monospacedDigit()
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.7)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview {
    HealthMetricsCard(vm: InsightsViewModel.preview)
        .padding()
}

#Preview("Accessibility 5") {
    ScrollView {
        HealthMetricsCard(vm: InsightsViewModel.preview)
            .padding()
    }
    .dynamicTypeSize(.accessibility5)
}
