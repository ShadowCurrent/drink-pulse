import SwiftUI
import Charts

struct ThisWeekCard: View {
    let vm: DashboardViewModel

    // Computed in body scope so SwiftUI tracks vm.events and vm.effectiveDailyLimitGrams.
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
                    if let label = pctLabel(for: entry) {
                        Text(label)
                            .font(.system(size: 8))
                            .foregroundStyle(barColor(for: entry))
                    }
                }
            }
            .chartXScale(domain: vm.weekBarData.map(\.label))
            .chartYScale(domain: 0...chartYMax)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10))
                }
            }
            .frame(height: 96)
            .accessibilityHidden(true)
        }
        .padding()
        .dpGlassCard()
    }

    // Mirrors IntakePeriodRow colour thresholds: <50% green, <100% amber, ≥100% red.
    private func barColor(for entry: WeekBarEntry) -> Color {
        if entry.isFuture { return Color(.quaternarySystemFill) }
        if entry.grams == 0 { return Color(.tertiarySystemFill) }
        guard vm.effectiveDailyLimitGrams > 0 else { return .dpGreen }
        let pct = entry.grams / vm.effectiveDailyLimitGrams
        if pct >= 1.0 { return .dpRed }
        if pct >= 0.5 { return .dpAmber }
        return .dpGreen
    }

    // Uses Int() truncation — matches IntakePeriodRow.pctBadge so both cards show the same number.
    private func pctLabel(for entry: WeekBarEntry) -> String? {
        guard entry.grams > 0, !entry.isFuture, vm.effectiveDailyLimitGrams > 0 else { return nil }
        let pct = Int(entry.grams / vm.effectiveDailyLimitGrams * 100)
        return "\(pct)%"
    }
}
