import SwiftUI
import Charts

struct ThisWeekCard: View {
    let vm: DashboardViewModel

    // Minimum display height so bars are visible even with zero data.
    // Computed relative to the tallest bar so it stays subtle when real data is present.
    private var chartFloor: Double {
        let peak = vm.weekBarData.map(\.grams).max() ?? 0
        let ref = max(peak, vm.effectiveDailyLimitGrams > 0 ? vm.effectiveDailyLimitGrams : 20)
        return ref * 0.06
    }

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
        if entry.isToday { return .dpTeal }
        if entry.isFuture { return Color(.quaternarySystemFill) }
        if entry.grams > vm.effectiveDailyLimitGrams && vm.effectiveDailyLimitGrams > 0 { return .dpAmber }
        return Color(.tertiarySystemFill)
    }
}
