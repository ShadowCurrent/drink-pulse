import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var earliestEvents: [ConsumptionEvent]

    @State private var segment: HistorySegment = .list
    @State private var listPageLimit = HistoryViewModel.listPageSize
    @State private var visibleMonth: Date
    @State private var selectedDay: Date
    @State private var editingEvent: ConsumptionEvent?

    @State private var vm = HistoryViewModel()
    private var profile: UserProfile? { profiles.first }

    init(initialSegment: HistorySegment = .list) {
        _segment = State(initialValue: initialSegment)
        let now = Date.now
        let calendar = Calendar.current
        _visibleMonth = State(initialValue: now)
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
                    pageLimit: listPageLimit,
                    vm: vm,
                    profile: profile,
                    onLoadMore: loadNextListPage,
                    onEditEvent: { editingEvent = $0 }
                )
            }
        }
    }

    private var calendarContent: some View {
        HistoryCalendarQueryView(
            vm: vm,
            profile: profile,
            selectedDay: $selectedDay,
            visibleMonth: $visibleMonth,
            availableRange: vm.calendarRange(earliest: earliestEvent?.consumptionDate),
            onEditEvent: { editingEvent = $0 }
        )
    }

    private func loadNextListPage() {
        listPageLimit = vm.nextPageLimit(after: listPageLimit)
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
