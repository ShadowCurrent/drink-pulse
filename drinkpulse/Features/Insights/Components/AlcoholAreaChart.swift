import SwiftUI
import Charts

struct AlcoholAreaChart: View {
    let data: [ChartPoint]
    let period: InsightsPeriod
    @Binding var selectedKey: String?
    var formattedValue: (Double) -> String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption2) private var scaledChartHeight: Double = 100

    /// Grows with the axis labels, capped so the chart stays a chart rather than a page.
    private var chartHeight: CGFloat { CGFloat(min(scaledChartHeight, 260)) }

    var body: some View {
        if data.allSatisfy({ $0.grams == 0 }) {
            emptyState
        } else {
            chart
        }
    }

    private var chart: some View {
        let shownKeys = labelKeySet
        let dates = dateByKey
        return Chart(data) { point in
            // Area and line draw the same day, so they form one accessibility element per day.
            Plot {
                AreaMark(
                    x: .value(String(localized: "insights.chart.axis.date"), ChartPoint.key(for: point.date)),
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
                    x: .value(String(localized: "insights.chart.axis.date"), ChartPoint.key(for: point.date)),
                    y: .value(String(localized: "insights.chart.axis.grams"), point.grams)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(Color.dpRiskModerate)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
            .accessibilityLabel(point.date.formatted(markDateFormat))
            .accessibilityValue(formattedValue(point.grams))

            if selectedKey == ChartPoint.key(for: point.date) {
                RuleMark(
                    x: .value(String(localized: "insights.chart.axis.date"), ChartPoint.key(for: point.date)),
                    yStart: .value(String(localized: "insights.chart.axis.grams"), 0),
                    yEnd: .value(String(localized: "insights.chart.axis.grams"), point.grams)
                )
                .foregroundStyle(Color.secondary.opacity(0.3))

                PointMark(
                    x: .value(String(localized: "insights.chart.axis.date"), ChartPoint.key(for: point.date)),
                    y: .value(String(localized: "insights.chart.axis.grams"), point.grams)
                )
                .foregroundStyle(Color.dpRiskModerate)
                .symbolSize(70)
                .annotation(
                    position: .top,
                    spacing: 6,
                    overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                ) {
                    calloutView(date: point.date, grams: point.grams)
                }
            }
        }
        .chartXSelection(value: $selectedKey)
        .chartXAxis {
            // A categorical axis calls this closure for every category, so the label subset is
            // applied here; each label sits under its own point, and greedy collision resolution
            // drops a label that would still overlap its neighbour.
            AxisMarks(values: labelKeys) { value in
                if let k = value.as(String.self), shownKeys.contains(k), let date = dates[k] {
                    AxisValueLabel(centered: false, collisionResolution: .greedy) {
                        Text(date, format: xAxisFormat)
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...yDomainUpperBound)
        .frame(height: chartHeight)
        .accessibilityLabel(String(localized: "insights.section.areaChart"))
        .accessibilityChartDescriptor(AlcoholAreaChartAXDescriptor(data: data, formattedValue: formattedValue))
    }

    private var yDomainUpperBound: Double {
        let peakGrams = data.map(\.grams).max() ?? 0
        return max(peakGrams * 1.6, 1)
    }

    private var emptyState: some View {
        Text(String(localized: "insights.areaChart.empty"))
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
            .multilineTextAlignment(.center)
    }

    // MARK: - Scrub callout

    private func calloutView(date: Date, grams: Double) -> some View {
        Text("\(date.formatted(calloutDateFormat)) — \(formattedValue(grams))")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .fixedSize()
            .dpChartCalloutBackground()
            .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)))
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: selectedKey)
    }

    // MARK: - Category keys & labels

    private var dateByKey: [String: Date] {
        Dictionary(data.map { (ChartPoint.key(for: $0.date), $0.date) }, uniquingKeysWith: { _, new in new })
    }

    /// Evenly spaced keys, so two labels are never placed on neighbouring categories. Regular sizes
    /// include the first and the last day; accessibility sizes take the middle of equal segments,
    /// so the wide labels stay clear of the chart edges.
    private var labelKeys: [String] {
        let keys = data.map { ChartPoint.key(for: $0.date) }
        let count = xAxisCount
        guard keys.count > count, count > 1 else { return keys }
        let total = Double(keys.count)
        let indices: [Int] = dynamicTypeSize.isAccessibilitySize
            ? (0..<count).map { Int(((Double($0) + 0.5) * total / Double(count)).rounded(.down)) }
            : (0..<count).map { Int((Double($0) * (total - 1) / Double(count - 1)).rounded()) }
        return indices.map { keys[$0] }
    }

    private var labelKeySet: Set<String> { Set(labelKeys) }

    /// Accessibility sizes leave room for about three labels across the chart.
    private var xAxisCount: Int {
        if dynamicTypeSize.isAccessibilitySize { return 3 }
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

    /// Date of one mark for assistive technologies: the callout date plus the parts the callout
    /// leaves to context (day and month in Week, the year in Year), never the raw category key.
    private var markDateFormat: Date.FormatStyle {
        switch period {
        case .week, .month: return .dateTime.weekday(.abbreviated).day().month(.abbreviated)
        case .year:         return .dateTime.month(.abbreviated).year()
        case .allTime:      return .dateTime.month(.abbreviated).year(.twoDigits)
        }
    }

    private var calloutDateFormat: Date.FormatStyle {
        switch period {
        case .week:    return .dateTime.weekday(.abbreviated)
        case .month:   return .dateTime.weekday(.abbreviated).day().month(.abbreviated)
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
    AlcoholAreaChart(
        data: data, period: .week,
        selectedKey: .constant(nil),
        formattedValue: { "\(Int($0)) g" }
    )
    .padding()
    .dpGlassCard()
    .padding()
}
