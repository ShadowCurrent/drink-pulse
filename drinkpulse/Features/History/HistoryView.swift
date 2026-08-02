import SwiftUI
import SwiftData
#if DEBUG
import OSLog
#endif

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var profiles: [UserProfile]
    @Query private var earliestEvents: [ConsumptionEvent]

    @State private var segment: HistorySegment = .list
    @State private var insertionEdge: Edge = .trailing
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
        VStack(spacing: 0) {
            segmentPickerRow
            Group {
                switch segment {
                case .list:
                    listContent
                case .calendar:
                    calendarContent
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: insertionEdge),
                removal: .move(edge: insertionEdge == .trailing ? .leading : .trailing)
            ))
        }
        .navigationTitle(String(localized: "tab.history"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingEvent) { EditEventView(event: $0) }
        .dp_logViewLoad("History")
    }

    /// Pure, stateless direction mapping: reads only the destination segment,
    /// never the previous one. This is what makes it immune to the
    /// diff-based alternating-switch direction-lag bug (RESEARCH.md Pitfall 1,
    /// Apple Developer Forums thread 749606).
    static func edge(forEntering segment: HistorySegment) -> Edge {
        segment == .calendar ? .trailing : .leading
    }

    /// Pure, testable gate for the Reduce Motion branch below: when Reduce
    /// Motion is on, segment changes must apply without animation.
    /// Extracted from `selectSegment(_:)` so the branch condition itself is
    /// unit-testable (mirrors how `edge(forEntering:)` was extracted).
    static func shouldAnimate(reduceMotion: Bool) -> Bool {
        !reduceMotion
    }

    /// Single entry point for every segment change (Picker tap or any other
    /// selection source, e.g. VoiceOver). Computes the transition direction
    /// and mutates `segment` in the same synchronous scope, gated by
    /// Reduce Motion — matching `OnboardingView.animatedStep(_:)`'s shape.
    private func selectSegment(_ new: HistorySegment) {
        insertionEdge = Self.edge(forEntering: new)
        if Self.shouldAnimate(reduceMotion: reduceMotion) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                segment = new
            }
        } else {
            segment = new
        }
    }

    private var segmentPickerRow: some View {
        Picker(
            String(localized: "history.segment.picker"),
            selection: Binding(get: { segment }, set: { selectSegment($0) })
        ) {
            ForEach(HistorySegment.allCases, id: \.self) { s in
                Text(s.label).tag(s)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var listContent: some View {
        Group {
            if earliestEvent == nil {
                emptyState
            } else {
                HistoryListQueryView(
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
        selectedDay = defaultSelectedDay(for: newMonth)
    }

    /// A day is always selected. For the current month that is today; for any
    /// other month it falls back to the first day of that month.
    private func defaultSelectedDay(for month: Date) -> Date {
        let cal = Calendar.current
        if cal.isDate(month, equalTo: .now, toGranularity: .month) {
            return cal.startOfDay(for: .now)
        }
        let comps = cal.dateComponents([.year, .month], from: month)
        return cal.date(from: comps) ?? cal.startOfDay(for: month)
    }

    private func extendListWindow() {
        let old = listWindowStart
        listWindowStart = vm.extendedWindowStart(from: listWindowStart)
        #if DEBUG
        Logger(subsystem: "com.drinkpulse.app", category: "performance").notice(
            "History extendListWindow: \(old, privacy: .public) -> \(self.listWindowStart, privacy: .public)"
        )
        #endif
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
