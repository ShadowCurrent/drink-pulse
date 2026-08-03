import SwiftUI
import SwiftData

struct HistoryListQueryView: View {
    @Query private var events: [ConsumptionEvent]

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

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(vm.groupedByDay(events), id: \.day) { section in
                    HistoryDaySectionCard(
                        title: sectionTitle(for: section.day),
                        events: section.events,
                        profile: profile,
                        onEditEvent: onEditEvent
                    )
                    .id(section.day)
                }
                if hasMore {
                    LoadMoreSentinel(onBecomeVisible: onLoadMore)
                } else if !events.isEmpty {
                    EndOfListFooter()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        // TODO(iOS 27): native swipe-to-delete needs a `List` row context (or
        // `swipeActionsContainer()`, iOS-27-only, per Apple's SwiftUI docs).
        // Dropped in plan-0038; re-add once min deployment reaches iOS 27.
        // Context-menu Delete (`.eventContextMenu`, inside HistoryDaySectionCard)
        // is the sole delete path until then.
    }

    private func sectionTitle(for day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return String(localized: "history.today") }
        if cal.isDateInYesterday(day) { return String(localized: "history.yesterday") }
        return day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year())
    }
}

private struct LoadMoreSentinel: View {
    let onBecomeVisible: () -> Void

    // Latches a single `onBecomeVisible()` call per visible->visible spell;
    // resets when the sentinel goes offscreen again. Guards against firing
    // more than once per genuine "became visible" transition — belt-and-
    // braces alongside `extendListWindow`'s own one-shot gap collapsing
    // (`HistoryViewModel.extendedWindowStart(from:earliest:)`), since a fast
    // continuous scroll gesture can otherwise re-report crossings for the
    // same transition before the resulting state change has a chance to move
    // (or remove) the sentinel.
    @State private var hasTriggeredForCurrentVisibility = false

    // `.onAppear` is documented as unreliable for a trailing sentinel inside
    // ScrollView+LazyVStack (unlike List): LazyVStack computes content geometry
    // from an ESTIMATE for not-yet-measured trailing subviews (WWDC26 session
    // 321, "Dive into lazy stacks and scrolling with SwiftUI"), so a genuine
    // scroll-to-bottom gesture can stop at a wrong estimated offset without the
    // sentinel ever registering as appeared — only a later scroll delta forces
    // the corrective layout pass. `onScrollVisibilityChange` reports real
    // threshold-crossing visibility instead of relying on LazyVStack's internal
    // appear bookkeeping, which is Apple's documented API for this exact
    // pagination/lazy-loading pattern (iOS 18+, well under this app's iOS 26 min).
    var body: some View {
        Color.clear
            .frame(height: 1)
            .onScrollVisibilityChange(threshold: 0) { isVisible in
                if isVisible {
                    guard !hasTriggeredForCurrentVisibility else { return }
                    hasTriggeredForCurrentVisibility = true
                    onBecomeVisible()
                } else {
                    hasTriggeredForCurrentVisibility = false
                }
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
