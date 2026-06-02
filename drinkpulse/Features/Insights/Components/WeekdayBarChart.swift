import SwiftUI
import Charts

struct WeekdayBarChart: View {
    let bars: [WeekdayBar]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "insights.section.weekdayPatterns"))
                .font(.headline)
            Chart(bars) { bar in
                BarMark(
                    x: .value(String(localized: "insights.chart.axis.weekday"), bar.label),
                    y: .value(String(localized: "insights.chart.axis.grams"), bar.averageGrams)
                )
                .foregroundStyle(color(for: bar.riskLevel))
                .cornerRadius(4)
                .accessibilityLabel("\(bar.label): \(String(format: "%.1f", bar.averageGrams)) g")
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
}

#Preview {
    let bars = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].enumerated().map { i, label in
        WeekdayBar(weekdayIndex: i, label: label, averageGrams: Double.random(in: 0...40),
                   riskLevel: [.safe, .caution, .exceeded].randomElement()!)
    }
    return WeekdayBarChart(bars: bars).padding()
}
