import Testing
import Accessibility
import Foundation
@testable import drinkpulse

@MainActor
struct AlcoholAreaChartAXDescriptorTests {

    private func makeData(count: Int = 7) -> [ChartPoint] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<count).compactMap { i -> ChartPoint? in
            guard let d = cal.date(byAdding: .day, value: -count + 1 + i, to: today) else { return nil }
            return ChartPoint(date: d, grams: Double(i) * 5)
        }
    }

    // AXDataPoint's y-value readback has no public Swift accessor in this SDK
    // (AXDataPointValue.number is NS_REFINED_FOR_SWIFT with no Swift overlay
    // shipped) — Key-Value Coding against the underlying Objective-C property
    // is the only supported way to read it back for test assertions.
    private func rawY(_ point: AXDataPoint) -> Double? {
        (point.yValue as AnyObject?)?.value(forKey: "number") as? Double
    }

    // NaN/infinite-safe like the real `vm.formattedValue`, which never force-
    // converts to Int — a bare `Int($0)` crashes when the framework probes the
    // closure with a computed default-gridline value on a zero-width range
    // (see the empty-data test below).
    private func safeFormattedValue(_ grams: Double) -> String {
        String(format: "%.0f g", grams)
    }

    @Test func makeChartDescriptor_dataPointCountMatchesInput() {
        let data = makeData(count: 7)
        let descriptor = AlcoholAreaChartAXDescriptor(data: data, formattedValue: safeFormattedValue)

        let chartDescriptor = descriptor.makeChartDescriptor()

        #expect(chartDescriptor.series.first?.dataPoints.count == data.count)
    }

    @Test func makeChartDescriptor_yValuesMatchRawGrams_neverRounded() {
        let data = makeData(count: 7)
        let descriptor = AlcoholAreaChartAXDescriptor(data: data, formattedValue: safeFormattedValue)

        let chartDescriptor = descriptor.makeChartDescriptor()
        let dataPoints = chartDescriptor.series.first?.dataPoints ?? []

        #expect(dataPoints.count == data.count)
        for (i, point) in dataPoints.enumerated() {
            #expect(rawY(point) == data[i].grams)
        }
    }

    @Test func makeChartDescriptor_usesInjectedFormattedValueClosure_notInlineFormatting() {
        let data = makeData(count: 1)
        let marker = "MARKER-VALUE"
        let descriptor = AlcoholAreaChartAXDescriptor(data: data, formattedValue: { _ in marker })

        let chartDescriptor = descriptor.makeChartDescriptor()

        #expect(chartDescriptor.yAxis?.valueDescriptionProvider(data[0].grams) == marker)
    }

    @Test func makeChartDescriptor_emptyData_zeroDataPoints_noCrash() {
        let descriptor = AlcoholAreaChartAXDescriptor(data: [], formattedValue: safeFormattedValue)

        let chartDescriptor = descriptor.makeChartDescriptor()

        #expect(chartDescriptor.series.first?.dataPoints.count == 0)
    }
}
