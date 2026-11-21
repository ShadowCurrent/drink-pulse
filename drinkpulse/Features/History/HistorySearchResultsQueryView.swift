import SwiftUI
import SwiftData

/// Unpaginated History results for an active search. The predicate comes
/// from `HistorySearchFilter` and covers the whole history (no 90-day window).
struct HistorySearchResultsQueryView: View {
    @Query private var events: [ConsumptionEvent]

    @State private var sections: [DaySection] = []

    private let filter: HistorySearchFilter
    private let vm: HistoryViewModel
    private let profile: UserProfile?
    private let onEditEvent: (ConsumptionEvent) -> Void

    init(
        filter: HistorySearchFilter,
        vm: HistoryViewModel,
        profile: UserProfile?,
        onEditEvent: @escaping (ConsumptionEvent) -> Void
    ) {
        _events = Query(
            filter: filter.predicate,
            sort: \ConsumptionEvent.consumptionDate,
            order: .reverse
        )
        self.filter = filter
        self.vm = vm
        self.profile = profile
        self.onEditEvent = onEditEvent
    }

    private var unitContext: RowUnitContext { RowUnitContext(profile) }

    var body: some View {
        Group {
            if events.isEmpty {
                // A ScrollView, not a List overlay, so the empty state can
                // grow with Dynamic Type instead of clipping (audit).
                ScrollView {
                    emptyState
                        .frame(maxWidth: .infinity)
                        .padding(.top, 48)
                }
                .brandBackground()
            } else {
                resultsList
            }
        }
        .accessibilityIdentifier("history.search.results")
        .onChange(of: events.map(\.uuid), initial: true) { _, _ in refreshSections() }
        .onChange(of: events.map(\.modifiedDate)) { _, _ in refreshSections() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshSections()
        }
    }

    private var resultsList: some View {
        List {
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
            .brandRowBackground()
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .brandListBackground()
    }

    @ViewBuilder
    private var emptyState: some View {
        switch filter.emptyState {
        case .noMatches:
            // App-owned copy of `ContentUnavailableView.search(text:)`: the
            // system view's text fails the dynamicType/textClipped audit here.
            ContentUnavailableView(
                String(localized: "history.search.noResults.title \(filter.query)"),
                systemImage: "magnifyingglass",
                description: Text(String(localized: "history.search.noResults.description"))
            )
        case .unnamedHasNoName:
            ContentUnavailableView(
                String(localized: "history.search.unnamed.title"),
                systemImage: "magnifyingglass",
                description: Text(String(localized: "history.search.unnamed.description"))
            )
        }
    }

    private func refreshSections() {
        sections = vm.daySections(events)
    }
}

#if DEBUG
#Preview("Results for \"guin\"") {
    let container = HistorySearchPreviewData.container()
    return NavigationStack {
        HistorySearchResultsQueryView(
            filter: HistorySearchFilter(text: "guin", scope: .all),
            vm: HistoryViewModel(), profile: nil, onEditEvent: { _ in }
        )
    }
    .modelContainer(container)
}

#Preview("Unnamed with text") {
    NavigationStack {
        HistorySearchResultsQueryView(
            filter: HistorySearchFilter(text: "a", scope: .unnamed),
            vm: HistoryViewModel(), profile: nil, onEditEvent: { _ in }
        )
    }
    .modelContainer(HistorySearchPreviewData.container())
}
#endif
