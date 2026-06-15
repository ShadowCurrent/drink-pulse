import SwiftUI
import SwiftData

struct HistoryListQueryView: View {
    @Query private var events: [ConsumptionEvent]
    @Environment(\.modelContext) private var modelContext

    private let vm: HistoryViewModel
    private let profile: UserProfile?
    private let onLoadMore: () -> Void
    private let onEditEvent: (ConsumptionEvent) -> Void

    init(
        windowStart: Date,
        vm: HistoryViewModel,
        profile: UserProfile?,
        onLoadMore: @escaping () -> Void,
        onEditEvent: @escaping (ConsumptionEvent) -> Void
    ) {
        _events = Query(
            filter: #Predicate<ConsumptionEvent> { $0.timestamp >= windowStart },
            sort: \ConsumptionEvent.timestamp,
            order: .reverse
        )
        self.vm = vm
        self.profile = profile
        self.onLoadMore = onLoadMore
        self.onEditEvent = onEditEvent
    }

    var body: some View {
        List {
            ForEach(vm.groupedByDay(events), id: \.day) { section in
                Section(sectionTitle(for: section.day)) {
                    ForEach(section.events) { event in
                        Button { onEditEvent(event) } label: {
                            EventRow(event: event, profile: profile)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                modelContext.delete(event)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                        .eventContextMenu(for: event, in: modelContext)
                    }
                }
            }
            LoadMoreSentinel(onAppear: onLoadMore)
        }
        .listStyle(.insetGrouped)
    }

    private func sectionTitle(for day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return String(localized: "history.today") }
        if cal.isDateInYesterday(day) { return String(localized: "history.yesterday") }
        return day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year())
    }
}

private struct LoadMoreSentinel: View {
    let onAppear: () -> Void

    var body: some View {
        Color.clear
            .frame(height: 1)
            .onAppear(perform: onAppear)
    }
}
