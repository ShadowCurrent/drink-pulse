import Testing
import Accessibility
import Foundation
@testable import drinkpulse

@MainActor
struct WeekdayBarChartAXDescriptorTests {

    private func makeBars() -> [WeekdayBar] {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].enumerated().map { i, label in
            WeekdayBar(weekdayIndex: i, label: label, averageGrams: Double(i) * 5, riskLevel: .safe)
        }
    }

    // AXDataPoint's y-value readback has no public Swift accessor in this
    // SDK (AXDataPointValue.number is NS_REFINED_FOR_SWIFT with no Swift
    // overlay shipped) — Key-Value Coding against the underlying
    // Objective-C property is the only supported way to read it back for
    // test assertions (mirrors AlcoholAreaChartAXDescriptorTests.rawY).
    private func rawY(_ point: AXDataPoint) -> Double? {
        (point.yValue as AnyObject?)?.value(forKey: "number") as? Double
    }

    @Test func makeChartDescriptor_dataPointCountMatchesSevenBars() {
        let bars = makeBars()
        let descriptor = WeekdayBarChartAXDescriptor(bars: bars, unitDivisor: 1.0, unitLabel: "g")

        let chartDescriptor = descriptor.makeChartDescriptor()

        #expect(chartDescriptor.series.first?.dataPoints.count == 7)
    }

    @Test func makeChartDescriptor_yValuesAreDivisorAdjusted_neverRawAverageGrams() {
        let bars = makeBars()
        let unitDivisor = 8.0
        let descriptor = WeekdayBarChartAXDescriptor(bars: bars, unitDivisor: unitDivisor, unitLabel: "units")

        let chartDescriptor = descriptor.makeChartDescriptor()
        let dataPoints = chartDescriptor.series.first?.dataPoints ?? []

        #expect(dataPoints.count == bars.count)
        for (i, point) in dataPoints.enumerated() {
            #expect(rawY(point) == bars[i].averageGrams / unitDivisor)
        }
    }

    @Test func makeChartDescriptor_categoryOrderMatchesBarLabelsInOrder() {
        let bars = makeBars()
        let descriptor = WeekdayBarChartAXDescriptor(bars: bars, unitDivisor: 1.0, unitLabel: "g")

        let chartDescriptor = descriptor.makeChartDescriptor()
        let xAxis = chartDescriptor.xAxis as? AXCategoricalDataAxisDescriptor

        #expect(xAxis?.categoryOrder == bars.map(\.label))
    }

    @Test func makeChartDescriptor_emptyBars_zeroDataPoints_noCrash() {
        let descriptor = WeekdayBarChartAXDescriptor(bars: [], unitDivisor: 1.0, unitLabel: "g")

        let chartDescriptor = descriptor.makeChartDescriptor()

        #expect(chartDescriptor.series.first?.dataPoints.count == 0)
    }
}
