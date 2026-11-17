import SwiftUI

/// One preview per period (render with the AX 5 Dynamic Type variant for the largest size), so
/// the x-axis labels of every period can be checked for overlap (ledger row DL-O18).
private enum AlcoholAreaChartPreviewData {
    static let grams: [Double] = [0, 32, 0, 18, 45, 60, 20, 12, 0, 28, 40, 8]

    /// `count` consecutive days ending today, or `count` month starts ending this month.
    static func points(count: Int, component: Calendar.Component) -> [ChartPoint] {
        let cal = Calendar.current
        let now = cal.startOfDay(for: .now)
        let anchor = component == .month ? (cal.dateInterval(of: .month, for: now)?.start ?? now) : now
        return (0..<count).compactMap { i -> ChartPoint? in
            guard let date = cal.date(byAdding: component, value: i - count + 1, to: anchor) else { return nil }
            return ChartPoint(date: date, grams: grams[i % grams.count])
        }
    }

    static func chart(_ period: InsightsPeriod) -> some View {
        let data: [ChartPoint] = switch period {
        case .week: points(count: 7, component: .day)
        case .month: points(count: 30, component: .day)
        case .year: points(count: 12, component: .month)
        case .allTime: points(count: 30, component: .month)
        }
        return AlcoholAreaChart(
            data: data, period: period,
            selectedKey: .constant(nil),
            formattedValue: { "\(Int($0)) g" }
        )
        .padding()
        .dpGlassCard()
        .padding()
    }
}

#Preview("Week") { AlcoholAreaChartPreviewData.chart(.week) }
#Preview("Month") { AlcoholAreaChartPreviewData.chart(.month) }
#Preview("Year") { AlcoholAreaChartPreviewData.chart(.year) }
#Preview("All") { AlcoholAreaChartPreviewData.chart(.allTime) }
