import SwiftUI
import SwiftData

/// Calendar mode data: events of the visible month (for the marks) and of the selected day
/// (which may lie in another month after paging), in one query.
struct HistoryCalendarQueryView: View {
    @Query private var events: [ConsumptionEvent]

    private let vm: HistoryViewModel
    private let profile: UserProfile?
    @Binding private var selectedDay: Date
    @Binding private var visibleMonth: Date
    private let availableRange: DateInterval

    init(
        vm: HistoryViewModel,
        profile: UserProfile?,
        selectedDay: Binding<Date>,
        visibleMonth: Binding<Date>,
        availableRange: DateInterval
    ) {
        let cal = Calendar.current
        let month = cal.dateInterval(of: .month, for: visibleMonth.wrappedValue)
            ?? DateInterval(start: visibleMonth.wrappedValue, duration: 0)
        let day = cal.dateInterval(of: .day, for: selectedDay.wrappedValue)
            ?? DateInterval(start: selectedDay.wrappedValue, duration: 0)
        let monthStart = month.start, monthEnd = month.end, dayStart = day.start, dayEnd = day.end
        _events = Query(
            filter: #Predicate<ConsumptionEvent> {
                ($0.consumptionDate >= monthStart && $0.consumptionDate < monthEnd)
                    || ($0.consumptionDate >= dayStart && $0.consumptionDate < dayEnd)
            },
            sort: \ConsumptionEvent.consumptionDate,
            order: .reverse
        )
        self.vm = vm
        self.profile = profile
        _selectedDay = selectedDay
        _visibleMonth = visibleMonth
        self.availableRange = availableRange
    }

    private var unitContext: RowUnitContext { RowUnitContext(profile) }

    /// Physical-gram daily limit; 20 g without a profile (as the old grid).
    private var dailyLimit: Double {
        guard let p = profile else { return 20 }
        return p.guidelineChoice
            .effectiveLimits(weeklyGoalGrams: p.weeklyGoalGrams, for: p.biologicalSex)
            .effectiveDailyGrams
    }

    var body: some View {
        let cal = Calendar.current
        HistoryCalendarList(
            selectedDay: $selectedDay,
            visibleMonth: $visibleMonth,
            marks: HistoryCalendarMarks.levels(events: events, dailyLimitGrams: dailyLimit,
                                               density: unitContext.density, calendar: cal),
            availableRange: availableRange,
            dayEvents: events.filter { cal.isDate($0.consumptionDate, inSameDayAs: selectedDay) },
            dayTitle: vm.sectionTitle(
                for: cal.startOfDay(for: selectedDay),
                todayStart: cal.startOfDay(for: .now),
                yesterdayStart: cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: .now)),
                calendar: cal
            ),
            unitContext: unitContext
        )
    }
}
