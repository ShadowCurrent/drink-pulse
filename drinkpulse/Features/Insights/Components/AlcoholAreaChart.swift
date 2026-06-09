import SwiftUI
import Charts

// Pure chart view — no card wrapper. Embed inside InsightsHeroCard or any
// container that already provides padding and background.
struct AlcoholAreaChart: View {
    let data: [ChartPoint]
    let period: InsightsPeriod

    var body: some View {
        if data.allSatisfy({ $0.grams == 0 }) {
            emptyState
        } else {
            chart
        }
    }

    private var chart: some View {
        Chart(data) { point in
            AreaMark(
                x: .value(String(localized: "insights.chart.axis.date"), point.date),
                y: .value(String(localized: "insights.chart.axis.grams"), point.grams)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.dpRiskModerate.opacity(0.65), Color.dpRiskModerate.opacity(0.05)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            LineMark(
                x: .value(String(localized: "insights.chart.axis.date"), point.date),
                y: .value(String(localized: "insights.chart.axis.grams"), point.grams)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(Color.dpRiskModerate)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: xAxisCount)) {
                AxisValueLabel(format: xAxisFormat, centered: true)
                    .font(.caption2)
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: .automatic(includesZero: true))
        .frame(height: 100)
        .accessibilityLabel(String(localized: "insights.section.areaChart"))
    }

    private var emptyState: some View {
        Text(String(localized: "insights.areaChart.empty"))
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
            .multilineTextAlignment(.center)
    }

    private var xAxisCount: Int {
        switch period {
        case .week:    return 7
        case .month:   return 5
        case .year:    return 6
        case .allTime: return 6
        }
    }

    private var xAxisFormat: Date.FormatStyle {
        switch period {
        case .week:    return .dateTime.weekday(.abbreviated)
        case .month:   return .dateTime.day().month(.abbreviated)
        case .year:    return .dateTime.month(.abbreviated)
        case .allTime: return .dateTime.month(.abbreviated).year(.twoDigits)
        }
    }
}

#Preview {
    let cal = Calendar.current
    let today = cal.startOfDay(for: .now)
    let data = (0..<7).compactMap { i -> ChartPoint? in
        guard let d = cal.date(byAdding: .day, value: -6 + i, to: today) else { return nil }
        return ChartPoint(date: d, grams: Double([0, 32, 0, 18, 45, 60, 20][i]))
    }
    AlcoholAreaChart(data: data, period: .week)
        .padding()
        .dpGlassCard()
        .padding()
}
