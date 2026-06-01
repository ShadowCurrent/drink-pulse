import SwiftUI
import SwiftData

struct HistoryCalendarQueryView: View {
    @Query private var events: [ConsumptionEvent]

    private let vm: HistoryViewModel
    private let monthShown: Date
    private let profile: UserProfile?
    private let selectedDay: Binding<Date?>
    private let onEditEvent: (ConsumptionEvent) -> Void

    init(
        monthStart: Date,
        monthEnd: Date,
        vm: HistoryViewModel,
        monthShown: Date,
        profile: UserProfile?,
        selectedDay: Binding<Date?>,
        onEditEvent: @escaping (ConsumptionEvent) -> Void
    ) {
        _events = Query(
            filter: #Predicate<ConsumptionEvent> {
                $0.timestamp >= monthStart && $0.timestamp < monthEnd
            },
            sort: \ConsumptionEvent.timestamp,
            order: .reverse
        )
        self.vm = vm
        self.monthShown = monthShown
        self.profile = profile
        self.selectedDay = selectedDay
        self.onEditEvent = onEditEvent
    }

    var body: some View {
        HistoryCalendarView(
            events: events,
            vm: vm,
            monthShown: monthShown,
            profile: profile,
            selectedDay: selectedDay,
            onEditEvent: onEditEvent
        )
    }
}
