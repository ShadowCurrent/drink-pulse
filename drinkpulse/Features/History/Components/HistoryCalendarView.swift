import SwiftData
import SwiftUI

struct HistoryCalendarView: View {
    let events: [ConsumptionEvent]
    let vm: HistoryViewModel
    let monthShown: Date
    let profile: UserProfile?
    @Binding var selectedDay: Date?
    let onEditEvent: (ConsumptionEvent) -> Void

    private var calendar: Calendar { .current }

    /// Resolved once at this list level and passed down as a value, so no row holds
    /// a reference to the observable profile model (A6-1).
    private var unitContext: RowUnitContext { RowUnitContext(profile) }
    private var density: Double { unitContext.density }
    private var dailyLimit: Double {
        guard let p = profile else { return 20 }
        return p.guidelineChoice
            .effectiveLimits(weeklyGoalGrams: p.weeklyGoalGrams, for: p.biologicalSex)
            .effectiveDailyGrams
    }

    private var monthComponents: (year: Int, month: Int) {
        let comps = calendar.dateComponents([.year, .month], from: monthShown)
        return (comps.year ?? 0, comps.month ?? 0)
    }

    private var cells: [DayCell] {
        let c = monthComponents
        return vm.monthCells(year: c.year, month: c.month, events: events,
                             density: density, calendar: calendar, today: .now)
    }

    /// A weekday header symbol plus its column position. The position is the
    /// identity because the symbols themselves repeat in many locales (English
    /// has two "S" and two "T"), so the text cannot identify a column. Finding A1-3
    /// retired the index-pairing / offset-keyed iteration this replaces.
    private struct WeekdayLabel: Identifiable {
        let id: Int
        let text: String
    }

    private var weekdayLabels: [WeekdayLabel] {
        let symbols = calendar.veryShortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        let rotated = Array(symbols[start...]) + Array(symbols[..<start])
        return rotated.indices.map { WeekdayLabel(id: $0, text: rotated[$0]) }
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
                    unitContext: unitContext,
                    onEditEvent: onEditEvent
                )
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedDay)
        .dpGlassCard()
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(weekdayLabels) { label in
                Text(label.text)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            ForEach(cells) { cell in
                HistoryCalendarDayCell(
                    cell: cell,
                    isSelected: isSelected(cell),
                    fillColor: fillColor(for: cell),
                    onTap: { selectDay(cell) }
                )
            }
        }
        .padding(12)
    }

    private func isSelected(_ cell: DayCell) -> Bool {
        guard let date = cell.date, let selected = selectedDay else { return false }
        return calendar.isDate(date, inSameDayAs: selected)
    }

    private func fillColor(for cell: DayCell) -> Color? {
        guard !cell.isFuture else { return nil }
        return vm.riskColor(forGrams: cell.grams, dailyLimit: dailyLimit)
    }

    private func selectDay(_ cell: DayCell) {
        guard let date = cell.date else { return }
        // A day is always selected; tapping never clears the selection.
        selectedDay = date
    }

    private func eventsForDay(_ day: Date) -> [ConsumptionEvent] {
        events.filter { calendar.isDate($0.consumptionDate, inSameDayAs: day) }
    }
}

#Preview {
    @Previewable @State var selectedDay: Date? = .now
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(ConsumptionEvent.previewBeer)
    container.mainContext.insert(ConsumptionEvent.previewWine)
    container.mainContext.insert(UserProfile.preview)
    return HistoryCalendarView(
        events: [.previewBeer, .previewWine],
        vm: HistoryViewModel(),
        monthShown: .now,
        profile: .preview,
        selectedDay: $selectedDay,
        onEditEvent: { _ in }
    )
    .padding()
    .modelContainer(container)
}
