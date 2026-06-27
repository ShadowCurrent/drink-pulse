import SwiftUI

struct HistoryCalendarDayCell: View {
    let cell: DayCell
    let isSelected: Bool
    let fillColor: Color?
    let onTap: () -> Void

    var body: some View {
        if cell.date == nil {
            Color.clear.aspectRatio(1, contentMode: .fit)
        } else {
            Button(action: onTap) {
                ZStack {
                    background
                    border
                    dayNumber
                }
                .aspectRatio(1, contentMode: .fit)
            }
            .buttonStyle(.plain)
            .disabled(cell.isFuture)
            .accessibilityLabel(accessibilityDescription)
        }
    }

    @ViewBuilder
    private var border: some View {
        // Selected day: thick border. Today (when not selected): light thin
        // border to mark it without implying consumption.
        if isSelected {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.primary.opacity(0.7), lineWidth: 2.5)
        } else if cell.isToday {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.primary.opacity(0.25), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var background: some View {
        // Today gets no fill just for being today — the selection border marks
        // it. Color comes only from consumption, same as any other day.
        if let color = fillColor, !cell.isFuture {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.25))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemFill).opacity(cell.isFuture ? 0.15 : 0.08))
        }
    }

    private var dayNumber: some View {
        Text("\(dayNumericValue)")
            .font(cell.isToday ? .callout.bold() : .callout)
            .foregroundStyle(cell.isFuture ? .tertiary : .primary)
            .minimumScaleFactor(0.7)
    }

    private var dayNumericValue: Int {
        guard let date = cell.date else { return 0 }
        return Calendar.current.component(.day, from: date)
    }

    private var accessibilityDescription: String {
        guard let date = cell.date else { return "" }
        let formatted = date.formatted(.dateTime.day().month(.wide))
        if cell.isFuture {
            return "\(formatted), \(String(localized: "history.calendar.future"))"
        }
        if cell.grams > 0 {
            return "\(formatted), \(String(format: "%.0f g", cell.grams))"
        }
        return "\(formatted), \(String(localized: "history.calendar.soberSuffix"))"
    }
}

#Preview {
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    HStack(spacing: 4) {
        // Today — unselected, no drinks
        HistoryCalendarDayCell(
            cell: DayCell(position: 0, date: .now, grams: 0, isFuture: false, isToday: true),
            isSelected: false, fillColor: nil, onTap: {}
        )
        // Yesterday — with drinks (yellow fill)
        HistoryCalendarDayCell(
            cell: DayCell(position: 1, date: yesterday, grams: 28, isFuture: false, isToday: false),
            isSelected: false, fillColor: .yellow, onTap: {}
        )
        // Yesterday — selected
        HistoryCalendarDayCell(
            cell: DayCell(position: 2, date: yesterday, grams: 0, isFuture: false, isToday: false),
            isSelected: true, fillColor: nil, onTap: {}
        )
        // Tomorrow — future (disabled)
        HistoryCalendarDayCell(
            cell: DayCell(position: 3, date: tomorrow, grams: 0, isFuture: true, isToday: false),
            isSelected: false, fillColor: nil, onTap: {}
        )
    }
    .frame(width: 200)
    .padding()
}
