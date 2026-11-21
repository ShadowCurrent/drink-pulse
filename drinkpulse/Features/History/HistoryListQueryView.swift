import SwiftUI
import SwiftData

struct HistoryListQueryView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query private var events: [ConsumptionEvent]

    @State private var sections: [DaySection] = []

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
                if events.isEmpty && hasMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(String(localized: "history.list.loadingOlder"))
                }
                if hasMore {
                    LoadMoreSentinel(onBecomeVisible: onLoadMore)
                } else if !events.isEmpty {
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
        sections = vm.daySections(events)
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
            .foregroundStyle(Color.dpSecondaryText)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityAddTraits(.isStaticText)
    }
}
