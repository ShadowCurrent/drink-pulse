import SwiftUI
import Charts

struct ThisWeekCard: View {
    let vm: DashboardViewModel

    // Reference scale for the Y axis — daily limit or the tallest actual bar, whichever is greater.
    // Computed in body scope so SwiftUI tracks vm.events and vm.effectiveDailyLimitGrams as
    // dependencies and invalidates the view when either changes.
    private var chartYMax: Double {
        let peak = vm.weekBarData.map(\.grams).max() ?? 0
        let ref = vm.effectiveDailyLimitGrams > 0 ? vm.effectiveDailyLimitGrams : 20
        return max(peak, ref)
    }

    // Stub height for zero-data bars: 6% of the Y scale so they're visible but clearly empty.
    private var chartFloor: Double { chartYMax * 0.06 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "dashboard.section.thisWeek"))
                .font(.headline)
            Chart(vm.weekBarData) { entry in
                BarMark(
                    x: .value("Day", entry.label),
                    y: .value("g", max(entry.grams, chartFloor))
                )
                .foregroundStyle(barColor(for: entry))
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
            .frame(height: 72)
            .accessibilityHidden(true)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func barColor(for entry: WeekBarEntry) -> Color {
        if entry.isFuture { return Color(.quaternarySystemFill) }
        if entry.grams == 0 { return Color(.tertiarySystemFill) }
        if entry.isToday { return .dpTeal }
        if entry.grams > vm.effectiveDailyLimitGrams && vm.effectiveDailyLimitGrams > 0 { return .dpAmber }
        return Color(.tertiarySystemFill)
    }
}
