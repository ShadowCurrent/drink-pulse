import SwiftUI
import Charts

/// Area chart of the period (plan 0046, D0046-9; prototype `InsightsHeroCard`). Identity is the
/// slot, not the date (`Chart(_:id:content:)`): on period navigation each mark keeps its
/// identity and moves to its new value while both axes rescale in one transaction, so the curve
/// morphs instead of cross-fading. Amounts use the accent; the daily limit is a dashed rule as on
/// Today (HIG Charting data: consistent annotations across charts of the same data). Native
/// scrubbing via `chartXSelection`; the hero shows the selected value and date (no callout).
struct AlcoholAreaChart: View {
    let data: [ChartPoint]
    let period: InsightsPeriod
    @Binding var selectedDate: Date?
    /// Grams per display unit, so the axis reads in the user's unit.
    var unitDivisor: Double = 1
    /// Effective daily limit in grams; no rule when 0 or when the period is bucketed by month.
    var dailyLimitGrams: Double = 0
    /// Rule caption: "Daily limit", or "Daily average" when the guideline has no daily limit.
    var limitCaption: String = String(localized: "dashboard.limit.caption")
    var formattedValue: (Double) -> String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    static func unit(for period: InsightsPeriod) -> Calendar.Component {
        period == .week || period == .month ? .day : .month
    }

    /// Date of one mark: the same text the hero shows under the total while it is selected.
    static func dateText(_ date: Date, period: InsightsPeriod) -> String {
        unit(for: period) == .day
            ? date.formatted(.dateTime.weekday(.wide).day().month())
            : date.formatted(.dateTime.month(.wide).year())
    }

    private var unit: Calendar.Component { Self.unit(for: period) }
    private var divisor: Double { unitDivisor > 0 ? unitDivisor : 1 }
    private var showsLimit: Bool { unit == .day && dailyLimitGrams > 0 }
    private var axisLabel: String { String(localized: "insights.chart.axis.date") }
    private var valueLabel: String { String(localized: "insights.chart.axis.grams") }

    private var selectedPoint: ChartPoint? {
        guard let selectedDate else { return nil }
        return data.first { Calendar.current.isDate($0.date, equalTo: selectedDate, toGranularity: unit) }
    }

    var body: some View {
        Chart {
            ForEach(data, id: \.slot) { point in
                Plot {
                    AreaMark(x: .value(axisLabel, point.date, unit: unit),
                             y: .value(valueLabel, point.grams / divisor))
                        .foregroundStyle(.tint.opacity(0.25))
                        .interpolationMethod(.monotone)
                    LineMark(x: .value(axisLabel, point.date, unit: unit),
                             y: .value(valueLabel, point.grams / divisor))
                        .interpolationMethod(.monotone)
                }
                .accessibilityLabel(Self.dateText(point.date, period: period))
                .accessibilityValue(formattedValue(point.grams))

                if let selectedPoint, selectedPoint.slot == point.slot {
                    RuleMark(x: .value(axisLabel, point.date, unit: unit))
                        .foregroundStyle(Color.secondary)
                        .accessibilityHidden(true)
                }
            }
            if showsLimit {
                limitRule
            }
        }
        .chartXSelection(value: $selectedDate)
        // At accessibility sizes the default tick count makes the labels collide: ask for fewer
        // values; nil keeps the framework default at standard sizes.
        // Axis labels in the contrast-safe secondary ink: the default axis grey is under 4.5:1 on
        // the card (audit, plan 0046 Task 7).
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: dynamicTypeSize.isAccessibilitySize ? 3 : nil)) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel().foregroundStyle(Color.dpSecondaryText)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: dynamicTypeSize.isAccessibilitySize ? 2 : nil)) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel().foregroundStyle(Color.dpSecondaryText)
            }
        }
        .frame(minHeight: 180)
        .accessibilityLabel(String(localized: "insights.section.areaChart"))
        .accessibilityChartDescriptor(AlcoholAreaChartAXDescriptor(data: data, formattedValue: formattedValue))
    }

    @ChartContentBuilder
    private var limitRule: some ChartContent {
        RuleMark(y: .value(limitCaption, dailyLimitGrams / divisor))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            // `Color.secondary`: `.secondary` inside a chart resolves against the tint.
            .foregroundStyle(Color.secondary)
            .annotation(position: .top, alignment: .leading) {
                // Dropped at accessibility sizes, where it covers the plot.
                if !dynamicTypeSize.isAccessibilitySize {
                    Text(limitCaption)
                        .font(.caption2)
                        .foregroundStyle(Color.dpSecondaryText)
                }
            }
            .accessibilityLabel(limitCaption)
            .accessibilityValue(formattedValue(dailyLimitGrams))
    }
}
