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
        List {
            // Flat top-level `ForEach` yielding one unary row (`HistoryDaySectionCard`,
            // a single top-level view) per day — no `List.Section`, no nested per-event
            // `ForEach` at this level. This is List's documented cell-reuse-backed lazy
            // shape (SwiftUI templates each row's identity from the ForEach element's id
            // alone); it deliberately avoids the distinct, Apple-acknowledged FB11280425
            // defect (`List { ForEach(groups) { Section { ForEach(items) {...} } } }`
            // defeats row-level laziness entirely) that the pre-migration implementation
            // used. See .planning/debug/contextmenu-zoom-glitch.md re-scope evidence
            // (2026-08-03T16:20:00Z-16:40:00Z) for the research trail.
            ForEach(vm.daySections(events)) { section in
                HistoryDaySectionCard(
                    title: section.title,
                    events: section.events,
                    profile: profile,
                    onEditEvent: onEditEvent
                )
                // Matches the previous ScrollView+LazyVStack's `spacing: 16` between
                // cards (8pt bottom of one row + 8pt top of the next) and 16pt
                // horizontal margin; List rows have no built-in "spacing" parameter,
                // so row insets are the equivalent lever.
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            if hasMore {
                LoadMoreSentinel(onBecomeVisible: onLoadMore)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else if !events.isEmpty {
                EndOfListFooter()
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        // TODO(iOS 27): native per-event swipe-to-delete is still not restorable —
        // `.swipeActions` is a row-level affordance tied to what List's own ForEach
        // treats as a discrete row, and each row here is a whole day (`HistoryDaySectionCard`,
        // multiple events), not a single event. Context-menu Delete (`.eventContextMenu`,
        // inside HistoryDaySectionCard) stays the sole delete path — this is unchanged
        // from what shipped in 2e0fd4f, not a new regression from this re-scope. See
        // .planning/debug/contextmenu-zoom-glitch.md Evidence 2026-08-03T16:40:00Z.
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

    // Reversed rationale from the ScrollView+LazyVStack version this replaces:
    // there, `.onAppear` was documented as unreliable for a trailing sentinel
    // because LazyVStack computes content geometry from an ESTIMATE for
    // not-yet-measured trailing subviews (WWDC26 session 321), so a genuine
    // scroll-to-bottom gesture could stop at a wrong estimated offset without
    // the sentinel ever registering as appeared. `List` (iOS 15+) has no such
    // estimate: it is cell-reuse-backed by UICollectionView, which tracks
    // EXACT row frames, not estimates — a dedicated "loading row" whose
    // `.onAppear` fires the next page is List's own long-standing idiomatic
    // pagination pattern (e.g. tanaschita.com "How to implement pagination
    // with SwiftUI's List view"; fatbobman.com "List or LazyVStack"). See
    // .planning/debug/contextmenu-zoom-glitch.md Evidence for the research
    // trail behind this swap back to `.onAppear`/`.onDisappear`.
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
