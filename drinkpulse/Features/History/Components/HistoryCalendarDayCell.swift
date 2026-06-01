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
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(.primary.opacity(0.6), lineWidth: 1.5)
                    }
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
    private var background: some View {
        if cell.isToday {
            RoundedRectangle(cornerRadius: 8)
                .fill((fillColor ?? Color.accentColor).opacity(0.35))
        } else if let color = fillColor, !cell.isFuture {
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
