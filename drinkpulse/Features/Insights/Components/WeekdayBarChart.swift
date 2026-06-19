import SwiftUI
import Charts

struct WeekdayBarChart: View {
    let bars: [WeekdayBar]
    /// Grams per one displayed unit (1.0 for grams mode); divides the raw
    /// averages so the Y axis reads in the user's chosen unit, not grams.
    var unitDivisor: Double = 1.0
    /// Short unit label for accessibility (e.g. "units", "std drinks", "g").
    var unitLabel: String = "g"

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "insights.section.weekdayPatterns"))
                .font(.headline)
            Chart(bars) { bar in
                BarMark(
                    x: .value(String(localized: "insights.chart.axis.weekday"), bar.label),
                    y: .value(String(localized: "insights.chart.axis.grams"), displayValue(bar))
                )
                .foregroundStyle(color(for: bar.riskLevel))
                .cornerRadius(4)
                .accessibilityLabel("\(bar.label): \(String(format: "%.1f", displayValue(bar))) \(unitLabel)")
            }
            .chartXAxis {
                AxisMarks(preset: .aligned) {
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYScale(domain: .automatic(includesZero: true))
            .frame(height: 160)
        }
        .padding()
        .dpGlassCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "insights.section.weekdayPatterns"))
    }

    private func color(for level: RiskLevel) -> Color { level.chartColor }

    private func displayValue(_ bar: WeekdayBar) -> Double {
        bar.averageGrams / (unitDivisor > 0 ? unitDivisor : 1.0)
    }
}

#Preview {
    let bars = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].enumerated().map { i, label in
        WeekdayBar(weekdayIndex: i, label: label, averageGrams: Double.random(in: 0...40),
                   riskLevel: [.safe, .caution, .exceeded].randomElement()!)
    }
    return WeekdayBarChart(bars: bars).padding()
}
