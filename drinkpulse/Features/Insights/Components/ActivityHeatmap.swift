import SwiftUI

struct ActivityHeatmap: View {
    let cells: [HeatmapCell]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

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

    private func cellView(_ cell: HeatmapCell) -> some View {
        let maxGrams: Double = cells.map(\.grams).max() ?? 1
        let opacity: Double = maxGrams > 0 ? min(cell.grams / maxGrams, 1) : 0
        return RoundedRectangle(cornerRadius: 4)
            .fill(cellColor(for: cell.grams, opacity: opacity))
            .overlay {
                if cell.isCurrentWeek {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.primary.opacity(0.3), lineWidth: 1)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .accessibilityLabel(cellAccessibilityLabel(cell))
    }

    private func cellColor(for grams: Double, opacity: Double) -> Color {
        if grams == 0 { return Color.secondary.opacity(0.15) }
        return Color.dpRiskModerate.opacity(0.2 + opacity * 0.75)
    }

    private func cellAccessibilityLabel(_ cell: HeatmapCell) -> String {
        let date = cell.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        let g = String(format: "%.1f", cell.grams)
        return "\(date): \(g) g"
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Text(String(localized: "insights.heatmap.legend.less"))
                .font(.caption2)
                .foregroundStyle(.secondary)
            ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { v in
                RoundedRectangle(cornerRadius: 2)
                    .fill(v == 0 ? Color.secondary.opacity(0.15) : Color.dpRiskModerate.opacity(0.2 + v * 0.75))
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
    let now = Date.now
    guard let weekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start else {
        return AnyView(Text("Preview error"))
    }
    var cells: [HeatmapCell] = []
    for weekOffset in (0..<4).reversed() {
        let row = 3 - weekOffset
        for dayOffset in 0..<7 {
            if let day = cal.date(byAdding: .day, value: -weekOffset * 7 + dayOffset, to: weekStart) {
                cells.append(HeatmapCell(date: day, grams: Double.random(in: 0...60),
                                         weekIndex: row, dayIndex: dayOffset, isCurrentWeek: weekOffset == 0))
            }
        }
    }
    return AnyView(ActivityHeatmap(cells: cells.sorted { $0.date < $1.date }).padding())
}
