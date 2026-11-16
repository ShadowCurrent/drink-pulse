import SwiftUI
import Charts

struct ThisWeekCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var scaledChartHeight: Double = 96

    let vm: DashboardViewModel

    /// Grows with the labels, capped so the card stays a chart rather than a page.
    private var chartHeight: CGFloat { CGFloat(min(scaledChartHeight, 220)) }

    private var chartYMax: Double {
        let peak = vm.weekBarData.map(\.grams).max() ?? 0
        let ref = vm.effectiveDailyLimitGrams > 0 ? vm.effectiveDailyLimitGrams : 20
        return max(peak, ref)
    }

    private var chartFloor: Double { chartYMax * 0.06 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "dashboard.section.thisWeek"))
                .font(.headline)
            Chart(vm.weekBarData) { entry in
                BarMark(
                    x: .value("Day", entry.label),
                    y: .value("g", max(entry.grams, chartFloor))
                )
                .foregroundStyle(barColor(for: entry))
                .annotation(position: .top, alignment: .center, spacing: 2) {
                    // Seven bars are too narrow for percentage labels at accessibility sizes.
                    if !dynamicTypeSize.isAccessibilitySize, let label = pctLabel(for: entry) {
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(barColor(for: entry))
                    }
                }
            }
            .chartXScale(domain: vm.weekBarData.map(\.label))
            .chartYScale(domain: 0...chartYMax)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel(collisionResolution: dynamicTypeSize.isAccessibilitySize ? .greedy : .automatic)
                        .font(.caption2)
                }
            }
            .frame(height: chartHeight)
            .accessibilityHidden(true)
        }
        .padding()
        .dpGlassCard()
    }

    private func barColor(for entry: WeekBarEntry) -> Color {
        if entry.isFuture { return Color(.quaternarySystemFill) }
        if entry.grams == 0 { return Color(.tertiarySystemFill) }
        guard vm.effectiveDailyLimitGrams > 0 else { return .dpGreen }
        return vm.riskLevel(consumedGrams: entry.grams, limitGrams: vm.effectiveDailyLimitGrams).color
    }

    private func pctLabel(for entry: WeekBarEntry) -> String? {
        guard entry.grams > 0, !entry.isFuture, vm.effectiveDailyLimitGrams > 0 else { return nil }
        let pct = Int(vm.fraction(consumedGrams: entry.grams, limitGrams: vm.effectiveDailyLimitGrams) * 100)
        return "\(pct)%"
    }
}

#Preview("With data") {
    let vm = DashboardViewModel()
    let cal = Calendar.current
    let now = Date.now
    let event1 = ConsumptionEvent(consumptionDate: now, volumeMl: 568, abv: 0.05,
                                  category: .beer, icon: "🍺")
    let minus2 = cal.date(byAdding: .day, value: -2, to: now)!
    let event2 = ConsumptionEvent(consumptionDate: minus2, volumeMl: 330, abv: 0.05,
                                  category: .beer, icon: "🍺")
    let minus4 = cal.date(byAdding: .day, value: -4, to: now)!
    let event3 = ConsumptionEvent(consumptionDate: minus4, volumeMl: 175, abv: 0.135,
                                  category: .wine, icon: "🍷")
    vm.events = [event1, event2, event3]
    vm.profile = UserProfile.preview
    return ThisWeekCard(vm: vm)
        .padding()
}

#Preview("Empty") {
    ThisWeekCard(vm: DashboardViewModel())
        .padding()
}

#Preview("Accessibility 5") {
    ThisWeekCard(vm: DashboardViewModel())
        .padding()
        .dynamicTypeSize(.accessibility5)
}
