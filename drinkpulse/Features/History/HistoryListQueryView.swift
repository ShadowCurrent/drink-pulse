import SwiftUI
import SwiftData

struct HistoryListQueryView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query private var events: [ConsumptionEvent]

    /// Day sections, computed once per data change instead of once per body pass
    /// (B8-1). Kept in the view rather than on the view model so the view model
    /// stays stateless with respect to persistence (ADR-0004).
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

    /// Resolved once at this list level and passed down as a value, so no row holds
    /// a reference to the observable profile model (A6-1).
    private var unitContext: RowUnitContext { RowUnitContext(profile) }

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
            ForEach(sections) { section in
                HistoryDaySectionCard(
                    title: section.title,
                    events: section.events,
                    unitContext: unitContext,
                    onEditEvent: onEditEvent
                )
                // Default chrome insets match the previous ScrollView+LazyVStack's
                // `spacing: 16` between cards (8pt bottom of one row + 8pt top of
                // the next) and 16pt horizontal margin; List rows have no built-in
                // "spacing" parameter, so row insets are the equivalent lever.
                .historyListRowChrome()
            }
            // The current window is empty but older entries exist (B10-1). Rendered
            // as its own `if`, NOT as a branch of the conditional below: the
            // load-more sentinel must still be present in this same render, because
            // its `.onAppear` is what fires `extendListWindow` and makes the empty
            // window self-heal. Replacing the sentinel here would leave the screen
            // blank forever.
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
                    .historyListRowChrome()
            } else {
                // Terminal branch stating the builder's "no third state"
                // assumption explicitly rather than leaving it implied (A2-1).
                EmptyView()
            }
        }
        .listStyle(.plain)
        // Keyed on `modifiedDate`, not the `events` array itself (WR-01 fix). Every
        // ConsumptionEvent mutator calls `touch()` (CLAUDE.md's LWW identity
        // contract), so this fires on ANY edit — including an in-place
        // `consumptionDate` change that doesn't reorder the `@Query`-sorted array
        // (e.g. editing the currently-oldest event to be even older). `events`
        // holds the same object references before and after such an edit, so
        // Array<ConsumptionEvent>'s default (identity-based) Equatable saw no
        // change and this trigger silently missed it. `[Date]` changes whenever
        // any element's modifiedDate changes, independent of ordering.
        // The initial-fire argument below is load-bearing: without it the first
        // render shows an empty list, because nothing has changed yet at that point.
        .onChange(of: events.map(\.modifiedDate), initial: true) { _, _ in refreshSections() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshSections() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshSections()
        }
        // TODO(iOS 27): native per-event swipe-to-delete is still not restorable —
        // `.swipeActions` is a row-level affordance tied to what List's own ForEach
        // treats as a discrete row, and each row here is a whole day (`HistoryDaySectionCard`,
        // multiple events), not a single event. Context-menu Delete (`.eventContextMenu`,
        // inside HistoryDaySectionCard) stays the sole delete path — this is unchanged
        // from what shipped in 2e0fd4f, not a new regression from this re-scope. See
        // .planning/debug/contextmenu-zoom-glitch.md Evidence 2026-08-03T16:40:00Z.
    }

    /// Single definition of the section recompute, shared by all three refresh
    /// triggers above (data change, scene activation, calendar day change).
    ///
    /// **Correctness obligation this cache introduces (finding A4-2).** Section
    /// titles are now *stored data*, not values derived on every render: "Today"
    /// and "Yesterday" are resolved against the clock at the moment this runs and
    /// then held in `sections` until something invalidates them. The previous
    /// per-render implementation was accidentally immune to that — it re-read the
    /// clock every body pass, so it could not go stale. Caching is the whole point
    /// of B8-1, so the staleness has to be handled here instead:
    ///
    /// - a *backgrounded* app that returns the next day is covered by the
    ///   `scenePhase == .active` trigger;
    /// - an app left *foregrounded* across midnight is covered by the calendar
    ///   day-change notification, which the scene-phase trigger alone would miss.
    ///
    /// The underlying relabelling behaviour is pinned by the injected-clock unit
    /// tests in `HistoryViewModelTests+DayRollover.swift`; this method's job is only
    /// to make sure they are consulted again at the right moments.
    private func refreshSections() {
        sections = vm.daySections(events)
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

/// The row chrome every row in this List shares (B9-1): the same three modifiers
/// were written out on each row kind, and B10-1's loading row would have made it a
/// fourth copy.
///
/// Deliberately a per-row modifier rather than hoisting the separator/background
/// onto the `List` itself: 07-RESEARCH Assumptions Log **A3** records that whether
/// row-scoped modifiers applied to the container propagate to every row under
/// `.plain` style is unverified, and it is the kind of thing that silently
/// half-works. `.listStyle(.plain)` stays the only container-level modifier.
fileprivate extension View {
    func historyListRowChrome(
        insets: EdgeInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    ) -> some View {
        listRowInsets(insets)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
