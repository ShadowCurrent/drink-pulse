import SwiftUI

/// Period total, neutral trend versus the previous period and the area chart (plan 0046,
/// D0046-9; prototype `InsightsHeroCard`). While a point is scrubbed the total shows that point
/// and its date replaces the trend line. The trend is neutral: arrow and number state the
/// direction; red / green would judge it (VOICE.md) and rely on a red–green pair (HIG
/// Inclusive color).
struct InsightsHeroCard: View {
    @Environment(\.numbersCountDown) private var countsDown

    let vm: InsightsViewModel

    @State private var selectedDate: Date?

    private var unit: Calendar.Component { AlcoholAreaChart.unit(for: vm.period) }

    private var selectedPoint: ChartPoint? {
        guard let selectedDate else { return nil }
        return vm.seriesData.first {
            Calendar.current.isDate($0.date, equalTo: selectedDate, toGranularity: unit)
        }
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.formattedValue(selectedPoint?.grams ?? vm.periodTotalGrams))
                        .font(.largeTitle.bold())
                        .fontDesign(.rounded)
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: countsDown))
                    if let selectedPoint {
                        Text(AlcoholAreaChart.dateText(selectedPoint.date, period: vm.period))
                            .font(.subheadline)
                            .foregroundStyle(Color.dpSecondaryText)
                            .accessibilityIdentifier("insights.hero.selectedDate")
                    } else if !vm.isAllTime {
                        trend
                    }
                }
                AlcoholAreaChart(
                    data: vm.seriesData,
                    period: vm.period,
                    selectedDate: $selectedDate,
                    unitDivisor: vm.displayUnitDivisor,
                    dailyLimitGrams: vm.effectiveDailyLimitGrams,
                    limitCaption: vm.limitRuleCaption,
                    formattedValue: vm.formattedValue
                )
            }
        } label: {
            CardTitle("insights.hero.total")
        }
        // Review focus 4: a new period or offset clears the selection, so the hero shows the
        // new total.
        .onChange(of: vm.period) { selectedDate = nil }
        .onChange(of: vm.activeOffset) { selectedDate = nil }
    }

    private var trend: some View {
        let change = vm.trendFraction
        let symbol = abs(change) <= 0.01 ? "equal" : (change > 0 ? "arrow.up.right" : "arrow.down.right")
        let percent = "\(Int((change * 100).rounded()))%"
        let text = String(format: String(localized: "insights.hero.vsPrev"),
                          percent,
                          vm.period.localizedLabel.lowercased(),
                          vm.formattedValue(vm.prevPeriodTotalGrams))
        return Label(text, systemImage: symbol)
            .font(.subheadline)
            .foregroundStyle(Color.dpSecondaryText)
    }
}

#Preview("Hero card") {
    ScrollView {
        InsightsHeroCard(vm: InsightsViewModel.preview).padding()
    }
    .brandBackground()
}

#Preview("Hero card · Dark") {
    ScrollView {
        InsightsHeroCard(vm: InsightsViewModel.preview).padding()
    }
    .brandBackground()
    .preferredColorScheme(.dark)
}

#Preview("Hero card · AX5") {
    ScrollView {
        InsightsHeroCard(vm: InsightsViewModel.preview).padding()
    }
    .brandBackground()
    .dynamicTypeSize(.accessibility5)
}
