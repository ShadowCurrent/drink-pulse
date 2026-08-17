import SwiftUI
import Charts

struct WeekdayBarChart: View {
    let bars: [WeekdayBar]
    var unitDivisor: Double = 1.0
    var unitLabel: String = "g"

    @State private var selectedLabel: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

                if selectedLabel == bar.label {
                    PointMark(
                        x: .value(String(localized: "insights.chart.axis.weekday"), bar.label),
                        y: .value(String(localized: "insights.chart.axis.grams"), displayValue(bar))
                    )
                    .foregroundStyle(color(for: bar.riskLevel))
                    .symbolSize(70)
                    .annotation(
                        position: .top,
                        spacing: 6,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        calloutView(bar: bar)
                    }
                }
            }
            .chartXSelection(value: $selectedLabel)
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
            .chartYScale(domain: 0...yDomainUpperBound)
            .frame(height: 160)
            .accessibilityChartDescriptor(
                WeekdayBarChartAXDescriptor(bars: bars, unitDivisor: unitDivisor, unitLabel: unitLabel)
            )
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

    private var yDomainUpperBound: Double {
        let peakValue = bars.map(displayValue).max() ?? 0
        return max(peakValue * 1.6, 1)
    }

    // MARK: - Scrub callout

    private func calloutView(bar: WeekdayBar) -> some View {
        Text("\(bar.label) — \(String(format: "%.1f", displayValue(bar))) \(unitLabel)")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .fixedSize()
            .dpChartCalloutBackground()
            .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)))
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: selectedLabel)
    }
}

#Preview {
    let bars = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].enumerated().map { i, label in
        WeekdayBar(weekdayIndex: i, label: label, averageGrams: Double.random(in: 0...40),
                   riskLevel: [.safe, .caution, .exceeded].randomElement()!)
    }
    return WeekdayBarChart(bars: bars).padding()
}
