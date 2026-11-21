import SwiftUI
import SwiftData

struct HistoryListQueryView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query private var events: [ConsumptionEvent]

    @State private var sections: [DaySection] = []
    @State private var hasMore = false

    private let pageLimit: Int
    private let vm: HistoryViewModel
    private let profile: UserProfile?
    private let onLoadMore: () -> Void
    private let onEditEvent: (ConsumptionEvent) -> Void

    /// Fetches the `pageLimit` newest events plus one, to learn whether older ones exist
    /// (count-based paging, see `HistoryViewModel+Pagination`).
    init(
        pageLimit: Int,
        vm: HistoryViewModel,
        profile: UserProfile?,
        onLoadMore: @escaping () -> Void,
        onEditEvent: @escaping (ConsumptionEvent) -> Void
    ) {
        var descriptor = FetchDescriptor<ConsumptionEvent>(
            sortBy: [SortDescriptor(\.consumptionDate, order: .reverse)]
        )
        descriptor.fetchLimit = vm.listFetchLimit(pageLimit: pageLimit)
        _events = Query(descriptor)
        self.pageLimit = pageLimit
        self.vm = vm
        self.profile = profile
        self.onLoadMore = onLoadMore
        self.onEditEvent = onEditEvent
    }

    private var unitContext: RowUnitContext { RowUnitContext(profile) }

    var body: some View {
        List {
            Group {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.events, id: \.uuid) { event in
                            HistoryEventRow(event: event, unitContext: unitContext, onEdit: onEditEvent)
                        }
                    } header: {
                        HistoryDayHeader(
                            title: section.title,
                            total: HistoryDayTotal(events: section.events, density: unitContext.density),
                            unitContext: unitContext
                        )
                    }
                }
            }
            .brandRowBackground()
            Section {
                if hasMore {
                    // A new identity per page, so `onAppear` fires again when the sentinel is
                    // still on screen after a page loads.
                    LoadMoreSentinel(onBecomeVisible: onLoadMore)
                        .id(pageLimit)
                } else if !sections.isEmpty {
                    EndOfListFooter()
                }
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .brandListBackground()
        .onChange(of: events.map(\.modifiedDate), initial: true) { _, _ in refreshSections() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshSections() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshSections()
        }
    }

    private func refreshSections() {
        let page = vm.listPage(from: events, pageLimit: pageLimit)
        sections = vm.daySections(page.events)
        hasMore = page.hasMore
    }
}

private struct LoadMoreSentinel: View {
    let onBecomeVisible: () -> Void

    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .accessibilityLabel(String(localized: "history.list.loadingOlder"))
            .onAppear(perform: onBecomeVisible)
    }
}

private struct EndOfListFooter: View {
    var body: some View {
        Text(String(localized: "history.list.endOfList"))
            .font(.footnote)
            .foregroundStyle(Color.dpSecondaryText)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityAddTraits(.isStaticText)
    }
}
