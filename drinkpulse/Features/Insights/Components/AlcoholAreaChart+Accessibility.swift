import Accessibility
import SwiftUI

// VoiceOver audio-graph support for AlcoholAreaChart, independent of the
// chartXSelection drag gesture (CHART-03, D-08). Attached via
// `.accessibilityChartDescriptor(_:)` on the chart's `Chart(...)` view.
//
// `formattedValue` is injected by the caller (the same closure already
// threaded into `AlcoholAreaChart` for its visual callout) so the audio
// graph and the on-screen callout can never drift apart — see D-08 and
// RESEARCH.md Pitfall 3.
struct AlcoholAreaChartAXDescriptor: AXChartDescriptorRepresentable {
    let data: [ChartPoint]
    let formattedValue: (Double) -> String

    func makeChartDescriptor() -> AXChartDescriptor {
        let xAxis = AXCategoricalDataAxisDescriptor(
            title: String(localized: "insights.chart.axis.date"),
            categoryOrder: data.map { $0.date.formatted(.dateTime.month(.wide).day()) }
        )

        let maxGrams = data.map(\.grams).max() ?? 0
        let yAxis = AXNumericDataAxisDescriptor(
            title: String(localized: "insights.chart.axis.grams"),
            range: 0...maxGrams,
            gridlinePositions: []
        ) { formattedValue($0) }

        let series = AXDataSeriesDescriptor(
            name: String(localized: "insights.section.areaChart"),
            isContinuous: true,
            dataPoints: data.map {
                .init(x: $0.date.formatted(.dateTime.month(.wide).day()), y: $0.grams)
            }
        )

        return AXChartDescriptor(
            title: String(localized: "insights.section.areaChart"),
            summary: nil,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}
