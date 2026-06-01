# 0013 — History calendar view with clickable days

**Status**: in-progress
**Frozen**: 2026-06-01
**Size**: medium
**Created**: 2026-05-19

## Summary

Add a Calendar segment alongside the existing List view in History.
- Month-grid layout with `←` / `→` navigation; the prev arrow disables
  at the earliest tracked month and the next arrow disables when on the
  current month.
- Days are colour-coded against the daily limit (low / moderate / high)
  with future days dimmed.
- Tapping a day expands a "Day detail" panel below the grid showing the
  events for that day. Tapping an event opens the existing
  `EditEventView` sheet. Days with no events show a sober-day placeholder.
- Both the calendar and the list load data lazily via date-windowed
  `@Query` sub-views — only the visible slice of events is ever in memory.

## Context

The Claude Design handoff (2026-05-19) shows the calendar as a primary
History view. The open question in `.claude/context/open-questions.md`
captured the colour-threshold decision; the user confirmed in the
transcript that days are coloured relative to *daily* limit, and any
"safe" wording should switch to "Low Risk" — see [[plan-0015]].

Currently `HistoryView` only has the list view. At the time of writing the
existing `@Query` loads **all** events into memory regardless of how far
back the history goes. This plan replaces that with windowed loading.

### Verified state of the code (2026-05-31)

Before freezing, the following was confirmed against the codebase so the
implementer does not act on stale assumptions:

- `HistoryView` has **no toolbar `+` button** — adding a drink is already
  handled by the FAB from [[plan-0010]]. There is nothing to remove.
- `EventRow` currently exists as a **`private struct` inside
  `HistoryView.swift`** (lines ~66–128). The day-detail panel must reuse
  it, so step 1 below extracts it into its own file as an `internal` type.
  Do not duplicate the row layout.
- `HistoryView` does **not** use a view model today; grouping is an inline
  `groupedEvents` computed property that this plan removes.
- The data-access pattern is `@Query` in the view + direct `modelContext`
  for deletes (see ADR-0004). The stateless `HistoryViewModel` introduced
  here is consistent with that pattern — it performs no persistence.

## Lazy loading strategy

### Why

Across one year of typical use (~2 drinks/day) the event array reaches
~700 items; at three years ~2000+. Loading the full history on every
`HistoryView` appearance is wasteful and scales poorly. The calendar needs
only the visible month; the list only needs recently visible sections.

### Calendar: month-range `@Query`

`HistoryCalendarQueryView` is a thin wrapper that receives `monthStart`
and `monthEnd` as `init` parameters and constructs its `@Query` with a
`#Predicate` covering that date range. When `monthShown` changes in the
parent, SwiftUI re-initialises this sub-view with new bounds, SwiftData
re-fetches only the ~30-day slice.

```
HistoryView (owns monthShown: Date)
  └─ HistoryCalendarQueryView(monthStart:monthEnd:)  ← @Query filtered
       └─ HistoryCalendarView(events:dayDetail:...)  ← pure view
```

### List: windowed `@Query` with load-more

`HistoryListQueryView` receives `windowStart: Date` from the parent and
constructs a `@Query` filtered to `windowStart ... now`. `HistoryView`
starts `windowStart` at `now - 90 days`. A sentinel `EmptyView` row at
the bottom of the `ForEach` triggers `.onAppear { extend window }`,
stepping `windowStart` back by another 90 days. A "Load earlier" label
confirms to the user that more history is available.

Initial load: 90 days. Each load-more step: +90 days.

```
HistoryView (owns listWindowStart: Date)
  └─ HistoryListQueryView(windowStart:)  ← @Query filtered
       └─ List { sections… + LoadMoreSentinel }
```

### SwiftData dynamic-`@Query` pattern (critical)

A `@Query` macro cannot read `init` parameters in its property-wrapper
default. To filter by an injected date range, **construct the query in the
sub-view's `init`** and assign to the underscore-prefixed backing property.
Both `HistoryListQueryView` and `HistoryCalendarQueryView` follow this shape:

```swift
struct HistoryCalendarQueryView: View {
    @Query private var events: [ConsumptionEvent]

    init(monthStart: Date, monthEnd: Date,
         selectedDay: Binding<Date?>,
         onEditEvent: @escaping (ConsumptionEvent) -> Void) {
        _events = Query(
            filter: #Predicate<ConsumptionEvent> {
                $0.timestamp >= monthStart && $0.timestamp < monthEnd
            },
            sort: \ConsumptionEvent.timestamp, order: .reverse
        )
        // assign the remaining bindings/closures to @State/stored props here
    }
}
```

`#Predicate` must compare against **`let` locals captured in `init`**
(`monthStart`, `monthEnd`) — not against computed properties or
`Calendar` calls, which the predicate compiler cannot translate to a
SwiftData fetch. Compute the bounds in the parent (`HistoryView`) and pass
them down as plain `Date` values.

### HistoryViewModel — stateless

`HistoryViewModel` is a pure, stateless `@Observable` class. It exposes
computation methods that accept a `[ConsumptionEvent]` slice (already
filtered by the query sub-view) and return derived values. It never
owns a `ModelContext` or a `@Query`.

| Method | Input | Output |
|--------|-------|--------|
| `groupedByDay(_:)` | `[ConsumptionEvent]` | `[(day: Date, events: [ConsumptionEvent])]` |
| `monthCells(year:month:events:)` | year, month, events | `[DayCell]` |
| `gramsByDay(events:)` | `[ConsumptionEvent]` | `[Date: Double]` |
| `riskColor(forGrams:dailyLimit:)` | grams, limit | `Color` |

## Scope

### In
- `Components/EventRow.swift` — extract the existing `private struct EventRow`
  from `HistoryView.swift` into its own `internal` file so the list and the
  day-detail panel share one implementation.
- `HistoryCalendarQueryView.swift` — month-range `@Query` sub-view wrapper.
- `HistoryListQueryView.swift` — windowed `@Query` sub-view wrapper + load-more sentinel.
- `HistoryViewModel.swift` — stateless computations.
- `HistorySegment.swift` — `enum HistorySegment { case list, calendar }`.
- `Components/HistoryCalendarView.swift` — month grid + navigation + clickable cells + inline day detail.
- `Components/HistoryCalendarDayCell.swift` — rounded square cell.
- `Components/HistoryCalendarDayDetail.swift` — day detail panel.
- `HistoryView.swift` — segment toggle, `listWindowStart` state, `monthShown` state; delegates to query sub-views.
- Bounds: prev/next arrows guarded by earliest-event month and current month.
- Performance tests alongside functional tests in `HistoryViewModelTests`.

### Out
- Heatmap-like opacity scaling — calendar uses discrete low/moderate/high.
- Multi-month "year view" — explicit out.
- Edit-from-day-detail beyond opening `EditEventView` (no inline edit).
- Calendar export.

## Implementation steps

1. **Extract `EventRow`** — move the existing `private struct EventRow`
   (and its `EventRow`-local helpers) out of `HistoryView.swift` into
   `Components/EventRow.swift`, changing visibility from `private` to
   `internal`. Keep its API identical (`init(event:profile:)`). Build to
   confirm the list still renders before adding the calendar. This is a
   pure refactor with no behaviour change.
2. **`HistorySegment`** — trivial enum + `HistoryView` state.
3. **`HistoryViewModel`** — pure helper:
   - `groupedByDay` groups and sorts passed events (used by list).
   - `monthCells(year:month:events:)` fills a 7-column grid with `DayCell`
     values; leading empty cells pad to the locale's first weekday.
   - `gramsByDay(events:)` reduces events to a `[Date: Double]` keyed on
     `startOfDay`. Used by calendar colour logic.
   - `riskColor(forGrams:dailyLimit:)` maps < 50% → theme green,
     50–100% → theme orange, > 100% → theme red (option A from Q1).
4. **`HistoryListQueryView`** — receives `windowStart: Date`; constructs
   the filtered `@Query` in `init` (see dynamic-`@Query` pattern above);
   renders `groupedByDay` sections in a `List`; appends a `LoadMoreSentinel`
   row that calls an `onLoadMore` closure on `.onAppear`.
5. **`HistoryCalendarQueryView`** — receives `monthStart`, `monthEnd`;
   constructs the filtered `@Query` in `init`; passes resulting `events` to
   `HistoryCalendarView`.
6. **`HistoryCalendarView`** — pure view: bindings for `monthShown`,
   `selectedDay`, `onSelect`, `onEditEvent`. Renders `DayCell` grid
   and inline `HistoryCalendarDayDetail` below when a day is selected.
7. **`HistoryCalendarDayCell`** — rounded square `Button`; theme-tinted
   today highlight; risk-coloured fill for non-zero days; future days dimmed
   with a neutral fill and disabled (Q3 → option A).
8. **`HistoryCalendarDayDetail`** — placed below the grid in the same
   `GlassCard`; shows date, total grams, then a list of `EventRow` rows
   (the extracted shared component); empty state: 🌙 "Sober day — no drinks
   recorded". Tapping a row calls `onEditEvent`, which the parent wires to
   present `EditEventView` (see [[plan-0014]]).
9. **`HistoryView`** refactor — removes inline `groupedEvents` computed
   property; introduces `listWindowStart` (default `now - 90 days`) and
   `monthShown` (default `startOfCurrentMonth`) state variables; delegates
   rendering to the appropriate query sub-view.
10. **Bounds**:
    - `canGoPrev = monthShown > startOfMonth(earliestEvent)`. The earliest
      event date is obtained via a dedicated `@Query` whose backing
      `FetchDescriptor` sorts ascending and sets `fetchLimit = 1`, so the
      bound never loads the full history. If there are no events, `canGoPrev`
      is `false`.
    - `canGoNext = monthShown < startOfCurrentMonth`.
11. **Tests** — see "Tests required" section below.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Features/History/Components/EventRow.swift` | Create (extract from `HistoryView.swift`) |
| `drinkpulse/Features/History/HistorySegment.swift` | Create |
| `drinkpulse/Features/History/HistoryViewModel.swift` | Create |
| `drinkpulse/Features/History/HistoryListQueryView.swift` | Create |
| `drinkpulse/Features/History/HistoryCalendarQueryView.swift` | Create |
| `drinkpulse/Features/History/Components/HistoryCalendarView.swift` | Create |
| `drinkpulse/Features/History/Components/HistoryCalendarDayCell.swift` | Create |
| `drinkpulse/Features/History/Components/HistoryCalendarDayDetail.swift` | Create |
| `drinkpulse/Features/History/HistoryView.swift` | Modify (extract `EventRow`, remove `groupedEvents`, add segment + state, delegate to sub-views) |
| `drinkpulseTests/HistoryViewModelTests.swift` | Create |
| `drinkpulse/Localizable.xcstrings` | Append keys |

## Open questions

- [x] **Q1 — Colour thresholds**: option A — green < 50%, orange 50–100%,
  red > 100% of daily limit. Matches `ConsumptionOverviewCard` thresholds.

- [x] **Q2 — Default segment**: List. Calendar accessible via segment toggle.
  Can be changed later without architectural impact.

- [x] **Q3 — Future days**: option A — dim with a neutral fill and render
  the cell disabled (non-tappable). Matches the design handoff.

- [x] **Q4 — First weekday**: `Calendar.current.firstWeekday` — reads the
  user's iOS system setting (Settings → General → Language & Region →
  First Day of Week). `UserProfile` has no separate field for this;
  the system setting is the authoritative source.

- [x] **Q5 — Load-more step size**: 90-day initial window; each load-more
  step adds another 90 days triggered by the sentinel row's `.onAppear`.

## Tests required

### Functional tests (`HistoryViewModelTests`)

- `monthCells(May 2026)` returns 35 cells (5 weeks) with correct
  leading-empty-cell count for locale first-weekday.
- `gramsByDay` sums correctly for multi-event days (two events on same day
  → single entry with sum).
- `groupedByDay` sorts descending and groups correctly.
- `riskColor` at 0 g → no fill (or themed neutral), exactly 50% limit →
  orange, exactly 100% limit → red, > 100% → red.
- Zero-consumption month → all cells have `grams == 0`.
- Earliest month bound: `canGoPrev == false` when on the month of the
  only/oldest event.

### Performance tests (`HistoryViewModelPerformanceTests`)

Rationale: the VM methods must remain fast even with years of logged data.
All tests use in-memory `[ConsumptionEvent]` arrays — no SwiftData needed.

| Test | Dataset | Budget |
|------|---------|--------|
| `test_gramsByDay_performance` | 2 000 events (3 yrs, ~2/day) | < 10 ms per iteration |
| `test_monthCells_performance` | 2 000 events, iterate 36 months | < 10 ms per iteration |
| `test_groupedByDay_performance` | 2 000 events | < 10 ms per iteration |
| `test_gramsByDay_performance_extremeLoad` | 10 000 events | < 50 ms per iteration |

Tests use `XCTestCase.measure {}` (Swift Testing has no perf API yet).
A shared factory `HistoryTestDataFactory.makeEvents(count:spread:)` generates
deterministic events spread across the specified number of days.

## Future links

- [[plan-0007]] — glass card.
- [[plan-0014]] — clicking an event in the detail opens edit sheet.
- [[plan-0015]] — legend reads "Low / Moderate / High Risk".
