import SwiftUI

struct ActivityHeatmap: View {
    let cells: [HeatmapCell]
    @Environment(\.dpTheme) private var theme

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var maxGrams: Double {
        cells.filter { !$0.isFuture }.map(\.grams).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "insights.section.activityHeatmap"))
                .font(.headline)
            weekdayHeader
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(cells) { cell in
                    cellView(cell)
                }
            }
            legend
        }
        .padding()
        .dpGlassCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "insights.section.activityHeatmap"))
    }

    private var weekdayHeader: some View {
        let cal = Calendar.current
        let firstDay = cal.firstWeekday
        let fmt = DateFormatter()
        fmt.locale = Locale.current
        return HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { col in
                let weekday = ((firstDay - 1 + col) % 7) + 1
                Text(fmt.veryShortStandaloneWeekdaySymbols[weekday - 1])
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func cellView(_ cell: HeatmapCell) -> some View {
        if cell.isFuture {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                    Color.secondary.opacity(0.25),
                    style: StrokeStyle(lineWidth: 0.75, dash: [2.5, 2])
                )
                .aspectRatio(1, contentMode: .fit)
                .accessibilityHidden(true)
        } else {
            let opacity: Double = maxGrams > 0 ? min(cell.grams / maxGrams, 1) : 0
            RoundedRectangle(cornerRadius: 4)
                .fill(cellColor(for: cell, opacity: opacity))
                .overlay {
                    if cell.isCurrentWeek {
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.primary.opacity(0.25), lineWidth: 1)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .accessibilityLabel(cellAccessibilityLabel(cell))
        }
    }

    private func cellColor(for cell: HeatmapCell, opacity: Double) -> Color {
        if cell.grams == 0 { return Color.secondary.opacity(0.15) }
        let base: Color = cell.isCurrentWeek ? theme.primary : .dpRiskModerate
        return base.opacity(0.2 + opacity * 0.75)
    }

    private func cellAccessibilityLabel(_ cell: HeatmapCell) -> String {
        let date = cell.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        return "\(date): \(String(format: "%.1f", cell.grams)) g"
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Text(String(localized: "insights.heatmap.legend.less"))
                .font(.caption2)
                .foregroundStyle(.secondary)
            ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { v in
                RoundedRectangle(cornerRadius: 2)
                    .fill(v == 0
                          ? Color.secondary.opacity(0.15)
                          : Color.dpRiskModerate.opacity(0.2 + v * 0.75))
                    .frame(width: 12, height: 12)
            }
            Text(String(localized: "insights.heatmap.legend.more"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let cal = Calendar.current
    let today = cal.startOfDay(for: .now)
    guard let weekStart = cal.dateInterval(of: .weekOfYear, for: today)?.start else {
        fatalError("Preview: weekStart failed")
    }
    var cells: [HeatmapCell] = []
    let gramsPattern: [Double] = [0, 32, 0, 18, 45, 60, 20]
    for week in 0..<12 {
        for day in 0..<7 {
            if let date = cal.date(byAdding: .day, value: -(11 - week) * 7 + day, to: weekStart) {
                let isFuture = date > today
                cells.append(HeatmapCell(
                    date: date,
                    grams: isFuture ? 0 : gramsPattern[day],
                    weekIndex: week,
                    dayIndex: day,
                    isCurrentWeek: week == 11,
                    isFuture: isFuture
                ))
            }
        }
    }
    return ActivityHeatmap(cells: cells.sorted { $0.date < $1.date })
        .padding()
}
