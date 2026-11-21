import SwiftUI
import Charts

/// This Week (plan 0046, D0046-6; owner: stays the calendar week): bars in the risk tone, a
/// dashed rule at the effective daily limit, one accessibility element per day. At accessibility
/// sizes the per-bar percentages and the rule caption collide, so they are dropped there; each
/// bar keeps its label and value and the rule stays.
struct ThisWeekCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let vm: DashboardViewModel

    private var showsAnnotations: Bool { !dynamicTypeSize.isAccessibilitySize }
    private var limit: Double { vm.effectiveDailyLimitGrams }

    private var chartYMax: Double {
        let peak = vm.weekBarData.map(\.grams).max() ?? 0
        return max(peak, limit > 0 ? limit : 20)
    }

    /// Empty days still draw a sliver so the week reads as seven slots.
    private var chartFloor: Double { chartYMax * 0.06 }

    var body: some View {
        GroupBox {
            Chart {
                ForEach(vm.weekBarData) { entry in
                    BarMark(
                        x: .value(String(localized: "insights.chart.axis.date"), entry.day, unit: .day),
                        y: .value(String(localized: "insights.chart.axis.grams"), max(entry.grams, chartFloor))
                    )
                    .foregroundStyle(barColor(for: entry))
                    .annotation(position: .top, spacing: 2) {
                        if showsAnnotations, let label = pctLabel(for: entry) {
                            Text(verbatim: label)
                                .font(.caption2)
                                .foregroundStyle(Color.dpSecondaryText)
                        }
                    }
                    .accessibilityLabel(entry.day.formatted(.dateTime.weekday(.wide)))
                    .accessibilityValue(entry.isFuture ? "" : vm.formattedAlcohol(entry.grams))
                }
                if limit > 0 {
                    RuleMark(y: .value(vm.limitRuleCaption, limit))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .foregroundStyle(Color.secondary)
                        .annotation(position: .top, alignment: .leading) {
                            if showsAnnotations {
                                Text(vm.limitRuleCaption)
                                    .font(.caption2)
                                    .foregroundStyle(Color.dpSecondaryText)
                            }
                        }
                        .accessibilityLabel(vm.limitRuleCaption)
                        .accessibilityValue(vm.formattedAlcohol(limit))
                }
            }
            .chartYScale(domain: 0...chartYMax)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: dynamicTypeSize.isAccessibilitySize ? 2 : 1)) {
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            }
            .frame(minHeight: 160)
            .padding(.vertical, 8)
        } label: {
            CardTitle("dashboard.section.thisWeek")
        }
    }

    private func barColor(for entry: WeekBarEntry) -> Color {
        if entry.isFuture { return Color(.quaternarySystemFill) }
        if entry.grams == 0 { return Color(.tertiarySystemFill) }
        guard limit > 0 else { return RiskLevel.safe.tone }
        return vm.riskLevel(consumedGrams: entry.grams, limitGrams: limit).tone
    }

    private func pctLabel(for entry: WeekBarEntry) -> String? {
        guard entry.grams > 0, !entry.isFuture, limit > 0 else { return nil }
        return "\(Int(vm.fraction(consumedGrams: entry.grams, limitGrams: limit) * 100))%"
    }
}

#Preview("With data") {
    let vm = DashboardViewModel()
    let cal = Calendar.current
    let now = Date.now
    let minus2 = cal.date(byAdding: .day, value: -2, to: now) ?? now
    vm.events = [
        ConsumptionEvent(consumptionDate: now, volumeMl: 568, abv: 0.05, category: .beer, icon: "🍺"),
        ConsumptionEvent(consumptionDate: minus2, volumeMl: 330, abv: 0.05, category: .beer, icon: "🍺"),
    ]
    vm.profile = UserProfile.preview
    return ThisWeekCard(vm: vm).padding().brandBackground()
}

#Preview("Empty · AX5") {
    ThisWeekCard(vm: DashboardViewModel())
        .padding()
        .brandBackground()
        .dynamicTypeSize(.accessibility5)
}
