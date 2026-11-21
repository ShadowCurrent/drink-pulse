import SwiftUI
import Charts

/// Weekday Patterns (plan 0046, D0046-11; owner: no scrubbing): average per weekday in the
/// accent — these are amounts, not risk (round 16) — one accessibility element per bar, and the
/// Audio Graph descriptor.
struct WeekdayBarChart: View {
    let bars: [WeekdayBar]
    var unitDivisor: Double = 1.0
    var unitLabel: String = "g"

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Seven weekday names collide at accessibility sizes, so those sizes show the initial.
    private func axisLabel(_ label: String) -> String {
        dynamicTypeSize.isAccessibilitySize ? String(label.prefix(1)) : label
    }

    var body: some View {
        GroupBox {
            Chart(bars) { bar in
                BarMark(
                    x: .value(String(localized: "insights.chart.axis.weekday"), bar.label),
                    y: .value(String(localized: "insights.chart.axis.grams"), displayValue(bar))
                )
                .foregroundStyle(.tint)
                .cornerRadius(4)
                .accessibilityLabel(bar.label)
                .accessibilityValue("\(String(format: "%.1f", displayValue(bar))) \(unitLabel)")
            }
            .chartXAxis {
                AxisMarks(preset: .aligned) { value in
                    if let label = value.as(String.self) {
                        AxisValueLabel { Text(axisLabel(label)).foregroundStyle(Color.dpSecondaryText) }
                    }
                }
            }
            // Contrast-safe secondary ink: the default axis grey is under 4.5:1 on the card.
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: dynamicTypeSize.isAccessibilitySize ? 3 : nil)) {
                    AxisGridLine()
                    AxisValueLabel().foregroundStyle(Color.dpSecondaryText)
                }
            }
            .chartYScale(domain: 0...yDomainUpperBound)
            .frame(minHeight: 160)
            .padding(.top, 8)
            .accessibilityChartDescriptor(
                WeekdayBarChartAXDescriptor(bars: bars, unitDivisor: unitDivisor, unitLabel: unitLabel)
            )
        } label: {
            CardTitle("insights.section.weekdayPatterns")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "insights.section.weekdayPatterns"))
    }

    private func displayValue(_ bar: WeekdayBar) -> Double {
        bar.averageGrams / (unitDivisor > 0 ? unitDivisor : 1.0)
    }

    private var yDomainUpperBound: Double {
        let peakValue = bars.map(displayValue).max() ?? 0
        return max(peakValue * 1.2, 1)
    }
}

#Preview("Weekday") {
    let bars = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].enumerated().map { i, label in
        WeekdayBar(weekdayIndex: i, label: label, averageGrams: Double([12, 0, 20, 8, 35, 40, 10][i]),
                   riskLevel: .safe)
    }
    return WeekdayBarChart(bars: bars).padding().brandBackground()
}

#Preview("Weekday · AX5") {
    let bars = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].enumerated().map { i, label in
        WeekdayBar(weekdayIndex: i, label: label, averageGrams: Double([12, 0, 20, 8, 35, 40, 10][i]),
                   riskLevel: .safe)
    }
    return WeekdayBarChart(bars: bars).padding().brandBackground().dynamicTypeSize(.accessibility5)
}
