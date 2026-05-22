import SwiftUI
import Charts

struct AlcoholAreaChart: View {
    let data: [ChartPoint]
    let period: InsightsPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "insights.section.areaChart"))
                .font(.headline)
            if data.allSatisfy({ $0.grams == 0 }) {
                emptyState
            } else {
                chart
            }
        }
        .padding()
        .dpGlassCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "insights.section.areaChart"))
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
                    colors: [Color.dpRiskModerate.opacity(0.7), Color.dpRiskModerate.opacity(0.1)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            LineMark(
                x: .value(String(localized: "insights.chart.axis.date"), point.date),
                y: .value(String(localized: "insights.chart.axis.grams"), point.grams)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(Color.dpRiskModerate)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: xAxisCount)) {
                AxisValueLabel(format: xAxisFormat, centered: true)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartYScale(domain: .automatic(includesZero: true))
        .frame(height: 160)
    }

    private var emptyState: some View {
        Text(String(localized: "insights.areaChart.empty"))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
            .multilineTextAlignment(.center)
    }

    private var xAxisCount: Int {
        switch period {
        case .week:  return 7
        case .month: return 5
        case .year:  return 6
        }
    }

    private var xAxisFormat: Date.FormatStyle {
        switch period {
        case .week:  return .dateTime.weekday(.abbreviated)
        case .month: return .dateTime.day().month(.abbreviated)
        case .year:  return .dateTime.month(.abbreviated)
        }
    }
}

#Preview {
    let cal = Calendar.current
    let today = cal.startOfDay(for: .now)
    let data = (0..<7).compactMap { i -> ChartPoint? in
        guard let d = cal.date(byAdding: .day, value: -6 + i, to: today) else { return nil }
        return ChartPoint(date: d, grams: Double.random(in: 0...60))
    }
    return AlcoholAreaChart(data: data, period: .week)
        .padding()
}
