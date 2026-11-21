import SwiftUI

/// Health Impact (plan 0046, D0046-10): a two-column grid, one column at accessibility sizes.
/// Values are the view model's
/// unchanged numbers; the heavy-day definition is fixed in grams (owner; logic unchanged).
struct HealthMetricsCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let vm: InsightsViewModel

    /// Two columns, one at accessibility sizes. A Dynamic Type branch with a non-lazy `Grid`:
    /// the audit flagged every text of the lazy adaptive grid as `dynamicType` (plan 0046 Task 7,
    /// same finding as the old card).
    @ViewBuilder
    private var cells: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 16) {
                heavyDaysCell; caloriesCell; drinkFreeCell; streakCell; heaviestDayCell; spendCell
            }
        } else {
            Grid(alignment: .topLeading, horizontalSpacing: 16, verticalSpacing: 16) {
                GridRow { heavyDaysCell; caloriesCell }
                GridRow { drinkFreeCell; streakCell }
                GridRow { heaviestDayCell; spendCell }
            }
        }
    }

    private var heavyDaysCell: some View {
        MetricCell(title: String(localized: "insights.metric.bingeEpisodes"),
                   systemImage: "exclamationmark.triangle.fill", tint: .red,
                   value: "\(vm.bingeEpisodes)",
                   detail: String(localized: "insights.metric.heavyDays.detail"))
    }

    private var caloriesCell: some View {
        MetricCell(title: String(localized: "insights.metric.calories"),
                   systemImage: "flame.fill", tint: .orange,
                   value: "\(vm.periodCaloriesKcal) kcal")
    }

    private var drinkFreeCell: some View {
        MetricCell(title: String(localized: "insights.metric.drinkFreeDays"),
                   systemImage: "moon.fill", tint: .teal,
                   value: "\(vm.drinkFreeDays.count)/\(vm.drinkFreeDays.total)",
                   detail: drinkFreePercent)
    }

    private var streakCell: some View {
        MetricCell(title: String(localized: "insights.metric.soberStreak"),
                   systemImage: "trophy.fill", tint: .purple,
                   value: streakText)
    }

    var body: some View {
        GroupBox {
            cells
                .padding(.top, 8)
        } label: {
            CardTitle("insights.section.healthImpact")
        }
    }

    /// "1 day" / "5 days": automatic grammar agreement is applied by `AttributedString(localized:)`.
    private var streakText: String {
        String(AttributedString(localized: "^[\(vm.longestSoberStreak) day](inflect: true)").characters)
    }

    /// Unchanged rule of the old card: truncated percent, nothing when the period has no days.
    private var drinkFreePercent: String? {
        let total = vm.drinkFreeDays.total
        guard total > 0 else { return nil }
        return "\(Int(Double(vm.drinkFreeDays.count) / Double(total) * 100))%"
    }

    private var heaviestDayCell: some View {
        let day = vm.heaviestDay
        return MetricCell(title: String(localized: "insights.metric.heaviestDay"),
                          systemImage: "chart.line.uptrend.xyaxis", tint: .orange,
                          value: day.map { vm.formattedValue($0.grams) } ?? "–",
                          detail: day.map { $0.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) })
    }

    private var spendCell: some View {
        let spend = vm.periodSpend
        let perDay = vm.periodSpendPerDay.map { vm.formattedSpend($0) + "/" + String(localized: "unit.day") }
        return MetricCell(title: String(localized: "insights.metric.spend"),
                          systemImage: "eurosign.circle", tint: .green,
                          value: spend.map { vm.formattedSpend($0) } ?? "–",
                          detail: spend == nil ? nil : perDay)
    }
}

/// One Health Impact figure: label with a natural-colour icon, value, optional detail.
/// Accessibility: label "title: value" (the UI tests parse it), detail as the value.
private struct MetricCell: View {
    @Environment(\.numbersCountDown) private var countsDown
    let title: String
    let systemImage: String
    let tint: Color
    let value: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label {
                Text(title).foregroundStyle(Color.dpSecondaryText)
            } icon: {
                Image(systemName: systemImage).foregroundStyle(tint)
            }
            .font(.footnote)
            Text(value)
                .contentTransition(.numericText(countsDown: countsDown))
                .font(.title3.bold())
                .fontDesign(.rounded)
                .monospacedDigit()
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.dpSecondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(title): \(value)"))
        .accessibilityValue(Text(verbatim: detail ?? ""))
    }
}

#Preview("Health Impact") {
    ScrollView { HealthMetricsCard(vm: InsightsViewModel.preview).padding() }
        .brandBackground()
}

#Preview("Health Impact · Dark") {
    ScrollView { HealthMetricsCard(vm: InsightsViewModel.preview).padding() }
        .brandBackground()
        .preferredColorScheme(.dark)
}

#Preview("Health Impact · AX5") {
    ScrollView { HealthMetricsCard(vm: InsightsViewModel.preview).padding() }
        .brandBackground()
        .dynamicTypeSize(.accessibility5)
}
