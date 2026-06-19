import SwiftUI
import Charts

// Pure chart view — no card wrapper. Embed inside InsightsHeroCard or any
// container that already provides padding and background.
//
// X is a categorical (band) scale keyed per point — same layout as
// WeekdayBarChart: every point sits at the center of its own band and its axis
// label (centered: true) sits directly under it. This trades a little width
// (the line/area are inset half a band on each side) for clean point↔label
// alignment, which was the chosen trade-off over a full-width continuous scale.
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
                x: .value(String(localized: "insights.chart.axis.date"), key(for: point.date)),
                y: .value(String(localized: "insights.chart.axis.grams"), point.grams)
            )
            .interpolationMethod(.linear)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.dpRiskModerate.opacity(0.65), Color.dpRiskModerate.opacity(0.05)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            LineMark(
                x: .value(String(localized: "insights.chart.axis.date"), key(for: point.date)),
                y: .value(String(localized: "insights.chart.axis.grams"), point.grams)
            )
            .interpolationMethod(.linear)
            .foregroundStyle(Color.dpRiskModerate)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
        .chartXAxis {
            AxisMarks(values: labelKeys) { value in
                if let k = value.as(String.self), let date = dateByKey[k] {
                    AxisValueLabel(centered: true) {
                        Text(date, format: xAxisFormat)
                            .font(.caption2)
                    }
                }
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

    // MARK: - Category keys & labels

    // Stable, unique, sort-stable key per point. The data is already in
    // ascending date order, so first-appearance order == chronological order.
    private func key(for date: Date) -> String {
        String(date.timeIntervalSinceReferenceDate)
    }

    private var dateByKey: [String: Date] {
        Dictionary(uniqueKeysWithValues: data.map { (key(for: $0.date), $0.date) })
    }

    // Thin the labels down to ~xAxisCount, always keeping the last point.
    private var labelKeys: [String] {
        let keys = data.map { key(for: $0.date) }
        guard keys.count > xAxisCount else { return keys }
        let step = max(1, Int((Double(keys.count - 1) / Double(max(1, xAxisCount - 1))).rounded()))
        var picked = stride(from: 0, to: keys.count, by: step).map { keys[$0] }
        if let last = keys.last, picked.last != last { picked.append(last) }
        return picked
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
