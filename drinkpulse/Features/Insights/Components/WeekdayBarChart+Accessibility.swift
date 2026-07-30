import Accessibility
import SwiftUI

// VoiceOver audio-graph support for WeekdayBarChart, independent of the
// chartXSelection drag gesture (CHART-03, D-09) — for consistency with
// AlcoholAreaChart's audio graph, even though this chart's per-bar
// accessibilityLabel already technically satisfies VoiceOver swipe-through
// access. Attached via `.accessibilityChartDescriptor(_:)` on the chart's
// `Chart(...)` view.
//
// `unitDivisor`/`unitLabel` mirror the exact formatting already used by
// this file's per-bar `accessibilityLabel` (`String(format: "%.1f", ...)`
// + unitLabel) rather than `vm.formattedValue` — `WeekdayBarChart` stays a
// "dumb" view with no view-model reference, per D-09/PATTERNS.md.
struct WeekdayBarChartAXDescriptor: AXChartDescriptorRepresentable {
    let bars: [WeekdayBar]
    let unitDivisor: Double
    let unitLabel: String

    private var safeDivisor: Double { unitDivisor > 0 ? unitDivisor : 1.0 }

    func makeChartDescriptor() -> AXChartDescriptor {
        let xAxis = AXCategoricalDataAxisDescriptor(
            title: String(localized: "insights.chart.axis.weekday"),
            categoryOrder: bars.map(\.label)
        )

        let maxValue = bars.map { $0.averageGrams / safeDivisor }.max() ?? 0
        let yAxis = AXNumericDataAxisDescriptor(
            title: String(localized: "insights.chart.axis.grams"),
            range: 0...maxValue,
            gridlinePositions: []
        ) { String(format: "%.1f", $0) + " " + unitLabel }

        let series = AXDataSeriesDescriptor(
            name: String(localized: "insights.section.weekdayPatterns"),
            isContinuous: false,
            dataPoints: bars.map {
                .init(x: $0.label, y: $0.averageGrams / safeDivisor)
            }
        )

        return AXChartDescriptor(
            title: String(localized: "insights.section.weekdayPatterns"),
            summary: nil,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}
