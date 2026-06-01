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

    private let vm = HistoryViewModel()
    private var profile: UserProfile? { profiles.first }

    init() {
        let now = Date.now
        let calendar = Calendar.current
        _listWindowStart = State(initialValue: calendar.date(byAdding: .day, value: -90, to: now) ?? now)
        let comps = calendar.dateComponents([.year, .month], from: now)
        _monthShown = State(initialValue: calendar.date(from: comps) ?? now)

        var descriptor = FetchDescriptor<ConsumptionEvent>(
            sortBy: [SortDescriptor(\ConsumptionEvent.timestamp, order: .forward)]
        )
        descriptor.fetchLimit = 1
        _earliestEvents = Query(descriptor)
    }

    private var earliestEvent: ConsumptionEvent? { earliestEvents.first }

    private var currentMonthStart: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: .now)
        return cal.date(from: comps) ?? .now
    }

    private var canGoPrev: Bool {
        guard let earliest = earliestEvent else { return false }
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: earliest.timestamp)
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
        .navigationTitle(String(localized: "tab.history"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { segmentPicker }
        .sheet(item: $editingEvent) { EditEventView(event: $0) }
    }

    @ToolbarContentBuilder
    private var segmentPicker: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker(String(localized: "history.segment.picker"), selection: $segment) {
                ForEach(HistorySegment.allCases, id: \.self) { s in
                    Text(s.label).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
    }

    private var listContent: some View {
        Group {
            if earliestEvent == nil {
                emptyState
            } else {
                HistoryListQueryView(
                    windowStart: listWindowStart,
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
            .padding(.bottom, 16)
        }
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

    private var emptyState: some View {
        ContentUnavailableView(
            String(localized: "history.emptyTitle"),
            systemImage: "wineglass",
            description: Text(String(localized: "history.emptyDescription"))
        )
    }

    private func navigateMonth(by value: Int) {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: value, to: monthShown) else { return }
        monthShown = newMonth
        selectedDay = nil
    }

    private func extendListWindow() {
        guard let extended = Calendar.current.date(byAdding: .day, value: -90, to: listWindowStart) else { return }
        listWindowStart = extended
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

#Preview("Empty state") {
    NavigationStack { HistoryView() }
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}
