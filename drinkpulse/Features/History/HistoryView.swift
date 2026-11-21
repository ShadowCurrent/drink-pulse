import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var earliestEvents: [ConsumptionEvent]

    @State private var segment: HistorySegment = .list
    @State private var listWindowStart: Date
    @State private var monthShown: Date
    @State private var selectedDay: Date?
    @State private var editingEvent: ConsumptionEvent?

    @State private var vm = HistoryViewModel()
    private var profile: UserProfile? { profiles.first }

    init(initialSegment: HistorySegment = .list) {
        _segment = State(initialValue: initialSegment)
        let now = Date.now
        let calendar = Calendar.current
        _listWindowStart = State(initialValue: HistoryViewModel().initialWindowStart(from: now, calendar: calendar))
        let comps = calendar.dateComponents([.year, .month], from: now)
        _monthShown = State(initialValue: calendar.date(from: comps) ?? now)
        _selectedDay = State(initialValue: calendar.startOfDay(for: now))

        var profileDescriptor = FetchDescriptor<UserProfile>()
        profileDescriptor.fetchLimit = 1
        _profiles = Query(profileDescriptor)

        var descriptor = FetchDescriptor<ConsumptionEvent>(
            sortBy: [SortDescriptor(\ConsumptionEvent.consumptionDate, order: .forward)]
        )
        descriptor.fetchLimit = 1
        _earliestEvents = Query(descriptor)
    }

    private var earliestEvent: ConsumptionEvent? { earliestEvents.first }

    private var hasMoreToLoad: Bool {
        vm.hasMoreToLoad(earliest: earliestEvent?.consumptionDate, windowStart: listWindowStart)
    }

    private var currentMonthStart: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: .now)
        return cal.date(from: comps) ?? .now
    }

    private var canGoPrev: Bool {
        guard let earliest = earliestEvent else { return false }
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: earliest.consumptionDate)
        let earliestMonthStart = cal.date(from: comps) ?? .now
        return monthShown > earliestMonthStart
    }

    private var canGoNext: Bool { monthShown < currentMonthStart }

    private var monthBounds: (start: Date, end: Date) {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: monthShown) else {
            return (monthShown, monthShown)
        }
        return (interval.start, interval.end)
    }

    var body: some View {
        Group {
            switch segment {
            case .list:
                listContent
            case .calendar:
                calendarContent
            }
        }
        // `.hard` keeps a band under the bar after scrolling back on iOS 27.2 (prototype
        // round 3b); `.soft` returns to a clean resting state.
        .scrollEdgeEffectStyle(.soft, for: .top)
        .navigationTitle(String(localized: "tab.history"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { segmentPicker }
            AddDrinkToolbarItem()
        }
        .sheet(item: $editingEvent) { EditEventView(event: $0) }
        .dp_logViewLoad("History")
    }

    /// List / Calendar switch in the bar's principal slot (plan 0045, D0045-1): a plain
    /// state change, no slide.
    private var segmentPicker: some View {
        Picker(String(localized: "history.segment.picker"), selection: $segment) {
            ForEach(HistorySegment.allCases, id: \.self) { s in
                Text(s.label).tag(s)
            }
        }
        .pickerStyle(.segmented)
        .fixedSize()
    }

    private var listContent: some View {
        Group {
            if earliestEvent == nil {
                HistoryEmptyView()
            } else {
                HistorySearchableList(
                    windowStart: listWindowStart,
                    hasMore: hasMoreToLoad,
                    vm: vm,
                    profile: profile,
                    onLoadMore: extendListWindow,
                    onEditEvent: { editingEvent = $0 }
                )
            }
        }
    }

    private var calendarContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                calendarNavHeader
                let bounds = monthBounds
                HistoryCalendarQueryView(
                    monthStart: bounds.start,
                    monthEnd: bounds.end,
                    vm: vm,
                    monthShown: monthShown,
                    profile: profile,
                    selectedDay: $selectedDay,
                    onEditEvent: { editingEvent = $0 }
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var calendarNavHeader: some View {
        HStack {
            Button {
                navigateMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
            }
            .disabled(!canGoPrev)

            Spacer()

            Text(monthShown.formatted(.dateTime.month(.wide).year()))
                .font(.headline)

            Spacer()

            Button {
                navigateMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
            }
            .disabled(!canGoNext)
        }
        .padding(.horizontal, 4)
    }

    private func navigateMonth(by value: Int) {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: value, to: monthShown) else { return }
        monthShown = newMonth
        selectedDay = defaultSelectedDay(for: newMonth)
    }

    private func defaultSelectedDay(for month: Date) -> Date {
        let cal = Calendar.current
        if cal.isDate(month, equalTo: .now, toGranularity: .month) {
            return cal.startOfDay(for: .now)
        }
        let comps = cal.dateComponents([.year, .month], from: month)
        return cal.date(from: comps) ?? cal.startOfDay(for: month)
    }

    private func extendListWindow() {
        listWindowStart = vm.extendedWindowStart(from: listWindowStart, earliest: earliestEvent?.consumptionDate)
    }
}

#Preview("With data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(ConsumptionEvent.previewBeer)
    container.mainContext.insert(ConsumptionEvent.previewWine)
    container.mainContext.insert(ConsumptionEvent.previewSpirits)
    container.mainContext.insert(UserProfile.preview)
    return NavigationStack { HistoryView() }
        .modelContainer(container)
}

#Preview("Calendar") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(ConsumptionEvent.previewBeer)
    container.mainContext.insert(ConsumptionEvent.previewWine)
    container.mainContext.insert(ConsumptionEvent.previewSpirits)
    container.mainContext.insert(UserProfile.preview)
    return NavigationStack { HistoryView(initialSegment: .calendar) }
        .modelContainer(container)
}

#Preview("Empty state") {
    NavigationStack { HistoryView() }
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}
