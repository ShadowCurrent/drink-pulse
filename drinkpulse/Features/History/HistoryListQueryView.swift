import SwiftUI
import SwiftData

struct HistoryListQueryView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query private var events: [ConsumptionEvent]

    @State private var rows: [HistoryFlatRow] = []

    private let hasMore: Bool
    private let vm: HistoryViewModel
    private let profile: UserProfile?
    private let onLoadMore: () -> Void
    private let onEditEvent: (ConsumptionEvent) -> Void

    init(
        windowStart: Date,
        hasMore: Bool,
        vm: HistoryViewModel,
        profile: UserProfile?,
        onLoadMore: @escaping () -> Void,
        onEditEvent: @escaping (ConsumptionEvent) -> Void
    ) {
        _events = Query(
            filter: #Predicate<ConsumptionEvent> { $0.consumptionDate >= windowStart },
            sort: \ConsumptionEvent.consumptionDate,
            order: .reverse
        )
        self.hasMore = hasMore
        self.vm = vm
        self.profile = profile
        self.onLoadMore = onLoadMore
        self.onEditEvent = onEditEvent
    }

    private var unitContext: RowUnitContext { RowUnitContext(profile) }

    var body: some View {
        List {
            ForEach(rows) { row in
                switch row {
                case .header(_, let title):
                    HistoryDayHeaderRow(title: title)
                        .historyListRowChrome(insets: Self.headerRowInsets)
                case .event(let event, let position):
                    HistoryEventCardRow(
                        event: event,
                        position: position,
                        unitContext: unitContext,
                        onEdit: onEditEvent
                    )
                    .historyListRowChrome(insets: Self.eventRowInsets)
                }
            }
            if events.isEmpty && hasMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .historyListRowChrome(insets: EdgeInsets())
                    .accessibilityLabel(String(localized: "history.list.loadingOlder"))
            }
            if hasMore {
                LoadMoreSentinel(onBecomeVisible: onLoadMore)
                    .historyListRowChrome(insets: EdgeInsets())
            } else if !events.isEmpty {
                EndOfListFooter()
                    .historyListRowChrome(insets: Self.headerRowInsets)
            } else {
                EmptyView()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .onChange(of: events.map(\.modifiedDate), initial: true) { _, _ in refreshRows() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshRows() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshRows()
        }
    }

    private func refreshRows() {
        rows = vm.daySections(events).flattenedForHistoryList()
    }

    private static let eventRowInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

    private static let headerRowInsets = EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
}

private struct HistoryDayHeaderRow: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isStaticText)
    }
}

private struct LoadMoreSentinel: View {
    let onBecomeVisible: () -> Void

    @State private var hasTriggeredForCurrentVisibility = false

    var body: some View {
        Color.clear
            .frame(height: 1)
            .onAppear {
                guard !hasTriggeredForCurrentVisibility else { return }
                hasTriggeredForCurrentVisibility = true
                onBecomeVisible()
            }
            .onDisappear {
                hasTriggeredForCurrentVisibility = false
            }
    }
}

private struct EndOfListFooter: View {
    var body: some View {
        Text(String(localized: "history.list.endOfList"))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 4)
            .accessibilityAddTraits(.isStaticText)
    }
}

fileprivate extension View {
    func historyListRowChrome(
        insets: EdgeInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    ) -> some View {
        listRowInsets(insets)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
