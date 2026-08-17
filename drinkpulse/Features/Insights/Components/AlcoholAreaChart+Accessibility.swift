import Accessibility
import SwiftUI

struct AlcoholAreaChartAXDescriptor: AXChartDescriptorRepresentable {
    let data: [ChartPoint]
    let formattedValue: (Double) -> String

    func makeChartDescriptor() -> AXChartDescriptor {
        let xAxis = AXCategoricalDataAxisDescriptor(
            title: String(localized: "insights.chart.axis.date"),
            categoryOrder: data.map { $0.date.formatted(.dateTime.year().month(.wide).day()) }
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
                .init(x: $0.date.formatted(.dateTime.year().month(.wide).day()), y: $0.grams)
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
