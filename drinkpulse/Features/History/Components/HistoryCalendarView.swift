import SwiftUI

struct HistoryCalendarView: View {
    let events: [ConsumptionEvent]
    let vm: HistoryViewModel
    let monthShown: Date
    let profile: UserProfile?
    @Binding var selectedDay: Date?
    let onEditEvent: (ConsumptionEvent) -> Void

    private var calendar: Calendar { .current }
    private var dailyLimit: Double {
        guard let p = profile else { return 20 }
        let limits = p.guidelineChoice.limits(for: p.biologicalSex)
        return limits.dailyGrams > 0 ? limits.dailyGrams : limits.weeklyGrams / 7
    }

    private var monthComponents: (year: Int, month: Int) {
        let comps = calendar.dateComponents([.year, .month], from: monthShown)
        return (comps.year ?? 0, comps.month ?? 0)
    }

    private var cells: [DayCell] {
        let c = monthComponents
        return vm.monthCells(year: c.year, month: c.month, events: events,
                             calendar: calendar, today: .now)
    }

    private var weekdayLabels: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...]) + Array(symbols[..<start])
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            grid
            if let day = selectedDay {
                Divider()
                HistoryCalendarDayDetail(
                    day: day,
                    events: eventsForDay(day),
                    profile: profile,
                    onEditEvent: onEditEvent
                )
            }
        }
        .dpGlassCard()
    }

    private var grid: some View {
        VStack(spacing: 4) {
            weekdayHeader
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(cells) { cell in
                    HistoryCalendarDayCell(
                        cell: cell,
                        isSelected: isSelected(cell),
                        fillColor: fillColor(for: cell),
                        onTap: { toggleDay(cell) }
                    )
                }
            }
        }
        .padding(12)
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func isSelected(_ cell: DayCell) -> Bool {
        guard let date = cell.date, let selected = selectedDay else { return false }
        return calendar.isDate(date, inSameDayAs: selected)
    }

    private func fillColor(for cell: DayCell) -> Color? {
        guard !cell.isFuture else { return nil }
        return vm.riskColor(forGrams: cell.grams, dailyLimit: dailyLimit)
    }

    private func toggleDay(_ cell: DayCell) {
        guard let date = cell.date else { return }
        if let selected = selectedDay, calendar.isDate(date, inSameDayAs: selected) {
            selectedDay = nil
        } else {
            selectedDay = date
        }
    }

    private func eventsForDay(_ day: Date) -> [ConsumptionEvent] {
        events.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
    }
}
