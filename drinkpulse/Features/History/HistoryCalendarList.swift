import SwiftUI
import SwiftData

/// Calendar mode (plan 0045, D0045-8): the system calendar in one section, the selected day
/// below it with the same header and rows as the list. "Today" appears only off today.
struct HistoryCalendarList: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var selectedDay: Date
    @Binding var visibleMonth: Date
    let marks: [Date: RiskLevel]
    let availableRange: DateInterval
    let dayEvents: [ConsumptionEvent]
    let dayTitle: String
    let unitContext: RowUnitContext
    let onEditEvent: (ConsumptionEvent) -> Void

    private var isAtToday: Bool {
        let cal = Calendar.current
        return cal.isDateInToday(selectedDay) && cal.isDate(visibleMonth, equalTo: .now, toGranularity: .month)
    }

    var body: some View {
        List {
            Group {
                Section {
                    DecoratedCalendar(selection: $selectedDay, visibleMonth: $visibleMonth,
                                      marks: marks, availableRange: availableRange)
                }
                Section {
                    if dayEvents.isEmpty {
                        Label(String(localized: "history.calendar.soberDayPlaceholder"), systemImage: "moon.stars")
                            .foregroundStyle(Color.dpSecondaryText)
                    } else {
                        ForEach(dayEvents, id: \.uuid) { event in
                            HistoryEventRow(event: event, unitContext: unitContext, onEdit: onEditEvent)
                        }
                    }
                } header: {
                    HistoryDayHeader(
                        title: dayTitle,
                        total: HistoryDayTotal(events: dayEvents, density: unitContext.density),
                        unitContext: unitContext
                    )
                }
            }
            .brandRowBackground()
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .brandListBackground()
        .animation(DPMotion.animation(.snappy, reduceMotion: reduceMotion), value: selectedDay)
        .overlay { DPMotionProbe(site: "historyCalendar", reduceMotion: reduceMotion) }
        .toolbar {
            if !isAtToday {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "history.calendar.today")) {
                        selectedDay = Calendar.current.startOfDay(for: .now)
                        visibleMonth = .now
                    }
                    .accessibilityIdentifier("history.calendar.today")
                }
            }
        }
    }
}

#Preview("Calendar") {
    @Previewable @State var day = Calendar.current.startOfDay(for: .now)
    @Previewable @State var month = Date.now
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let beer = ConsumptionEvent.previewBeer
    container.mainContext.insert(beer)
    let cal = Calendar.current
    let today = cal.startOfDay(for: .now)
    let marks: [Date: RiskLevel] = [
        today: .caution,
        cal.date(byAdding: .day, value: -1, to: today) ?? today: .safe,
        cal.date(byAdding: .day, value: -2, to: today) ?? today: .exceeded,
    ]
    let start = cal.date(byAdding: .month, value: -3, to: today) ?? today
    return NavigationStack {
        HistoryCalendarList(
            selectedDay: $day, visibleMonth: $month, marks: marks,
            availableRange: DateInterval(start: start, end: .now),
            dayEvents: [beer], dayTitle: "Today", unitContext: RowUnitContext(nil),
            onEditEvent: { _ in }
        )
        .navigationTitle(Text(verbatim: "History"))
        .navigationBarTitleDisplayMode(.inline)
    }
    .modelContainer(container)
}
