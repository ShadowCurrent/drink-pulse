import SwiftUI
import SwiftData

struct HistoryListQueryView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query private var events: [ConsumptionEvent]

    /// Flat List rows (one per event, plus day-header pseudo-rows), computed
    /// once per data change instead of once per body pass (B8-1) — `daySections`
    /// grouping/date-formatting AND the flattening in `flattenedForHistoryList()`
    /// both stay off the render path. Kept in the view rather than on the view
    /// model so the view model stays stateless with respect to persistence
    /// (ADR-0004). See `.planning/debug/contextmenu-zoom-glitch.md` for why this
    /// is a flat one-row-per-event `ForEach` rather than one row per day.
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

    /// Resolved once at this list level and passed down as a value, so no row holds
    /// a reference to the observable profile model (A6-1).
    private var unitContext: RowUnitContext { RowUnitContext(profile) }

    var body: some View {
        List {
            // Flat top-level `ForEach` yielding ONE unary row (a single top-level
            // view) per EVENT, plus non-interactive day-header pseudo-rows in the
            // SAME flat `ForEach` — no `List.Section`, no nested per-event `ForEach`
            // at this level, no row that hosts more than one event. This is List's
            // documented cell-reuse-backed lazy shape (SwiftUI templates each row's
            // identity from the ForEach element's id alone); it deliberately avoids
            // the distinct, Apple-acknowledged FB11280425 defect (`List { ForEach(groups)
            // { Section { ForEach(items) {...} } } }` defeats row-level laziness
            // entirely) that the pre-migration implementation used.
            //
            // This replaces the prior one-row-per-DAY shape (`HistoryDaySectionCard`,
            // every event nested as a sibling subview of one shared List row): that
            // shape let multiple `.contextMenu`s share one List row, which SwiftUI/
            // UIKit does not scope correctly — it caused both a transient whole-day
            // highlight flash AND silently routed Duplicate/Delete to the wrong event.
            // See .planning/debug/contextmenu-zoom-glitch.md for the full research
            // trail (re-scope evidence 2026-08-03T16:20:00Z-16:40:00Z; the shared-row
            // root cause confirmed 2026-08-05).
            ForEach(rows) { row in
                switch row {
                case .header(_, let title):
                    // No `List(selection:)` binding is used anywhere in this List,
                    // so a plain (non-Button, non-NavigationLink) row like this one
                    // has no tap-highlight/selection affordance to begin with —
                    // nothing further to disable.
                    //
                    // Top inset carries the FULL 16pt gap between this day and the
                    // previous one (see `eventRowInsets` below for why that gap can
                    // no longer live on the previous day's last event row).
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
                    .historyListRowChrome(insets: Self.headerRowInsets)
            } else {
                // Terminal branch stating the builder's "no third state"
                // assumption explicitly rather than leaving it implied (A2-1).
                EmptyView()
            }
        }
        .listStyle(.plain)
        // Canvas set explicitly to the semantic PAIR of the row fill below
        // (`HistoryEventCardRow`'s `.secondarySystemGroupedBackground`): Apple's
        // own docs define `secondarySystemGroupedBackground` as "content layered
        // on top of" `systemGroupedBackground` specifically — the two are meant
        // to be used together (e.g. Settings/Reminders card-on-canvas look).
        // `.plain` List left unstyled defaults its canvas to `.systemBackground`
        // instead, which in light mode is the same white as the row fill —
        // rows read as flat/washed-out with no visible card edge.
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
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
        .onChange(of: events.map(\.modifiedDate), initial: true) { _, _ in refreshRows() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshRows() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshRows()
        }
        // Native per-event swipe-to-delete (`.swipeActions`) is NOT wired up here
        // even though each row is now genuinely one event (which is what makes it
        // reachable at all, unlike the retired one-row-per-day shape): context-menu
        // Delete stays the sole delete path for this turn, per
        // .planning/debug/contextmenu-zoom-glitch.md's explicit scope (fixing the
        // contextMenu targeting/highlight bugs, not adding a new gesture) — flagged
        // there as now-reachable future work, not implemented speculatively here.
    }

    /// Single definition of the row recompute, shared by all three refresh
    /// triggers above (data change, scene activation, calendar day change).
    ///
    /// **Correctness obligation this cache introduces (finding A4-2).** Section
    /// titles are now *stored data*, not values derived on every render: "Today"
    /// and "Yesterday" are resolved against the clock at the moment this runs and
    /// then held in `rows` until something invalidates them. The previous
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
    private func refreshRows() {
        rows = vm.daySections(events).flattenedForHistoryList()
    }

    /// List row insets for EVERY event row, regardless of its position in the
    /// day (deliberately NOT position-dependent — see below). 16pt
    /// leading/trailing (unchanged — screen-edge-to-card-edge margin,
    /// matching the retired shared day-card's own List row inset); `0`
    /// top/bottom, since a same-day join needs zero gap and the gap to the
    /// PREVIOUS day is now carried entirely by the NEXT header's top inset
    /// (`headerRowInsets`) instead.
    ///
    /// This used to give the last event of each day a `bottom: 8` inset to
    /// produce the 16pt gap before the next day's header. That made the
    /// last-in-day row's own List row frame taller than its visible card —
    /// and the default (no custom `preview:`) `.contextMenu` lift/highlight
    /// scopes to the FULL row frame (content + `listRowInsets`), not just the
    /// visible card, so long-pressing that row showed a visibly larger empty
    /// margin below the card than pressing any other row (reported live,
    /// 2026-08-11 — see `.planning/debug/contextmenu-zoom-glitch.md`). Moving
    /// the day-gap onto the header row (non-interactive, no `.contextMenu`)
    /// removes the size variance between rows entirely, since a header pseudo-
    /// row is never what gets long-pressed.
    private static let eventRowInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

    /// Day-header row insets: `16` top carries the FULL day-to-day gap
    /// (previously split 8/8 across the previous day's last event and this
    /// header — see `eventRowInsets` above for why that split was moved off
    /// the event row). `8` bottom is unchanged: joined with the first
    /// event's own `0` top inset, it reproduces the original 8pt
    /// header-to-first-row gap.
    private static let headerRowInsets = EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
}

/// Non-interactive day-heading pseudo-row ("TODAY", "YESTERDAY", or a
/// formatted date) — a sibling of that day's event rows in the SAME flat
/// `ForEach`, not a `List.Section` header (see the discussion in
/// `.planning/debug/contextmenu-zoom-glitch.md`: a `Section`-generating outer
/// `ForEach` would defeat List's row-level laziness, FB11280425). Kept as its
/// own single top-level `Text` — the "unary row" shape List needs to stay
/// lazily cell-reuse-backed.
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
