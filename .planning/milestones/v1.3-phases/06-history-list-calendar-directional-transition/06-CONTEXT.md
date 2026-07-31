# Phase 6: History List↔Calendar Directional Transition - Context

**Gathered:** 2026-07-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Switching History's segmented control between List and Calendar animates as
directional navigation — content slides in one direction going List→Calendar,
the opposite direction going Calendar→List — instead of the current abrupt
`switch segment { }` swap in `HistoryView.body`. Scope is `HIST-01` through
`HIST-03` only: the transition/animation layer around the existing `listContent`
and `calendarContent` views. No changes to `HistoryListQueryView`,
`HistoryCalendarQueryView`, `HistoryViewModel`, or the underlying `@Query`
fetch logic — this phase wraps presentation, not data.

</domain>

<decisions>
## Implementation Decisions

### Transition mechanism
- **D-01:** Primary approach is a common container around the existing
  `switch segment { case .list: listContent; case .calendar: calendarContent }`
  in `HistoryView.body`, using `.transition(.asymmetric(insertion: .move(edge:),
  removal: .move(edge:)))` keyed by `segment`, driven by `withAnimation` on
  segment change. `List` and `ScrollView` are treated as opaque subviews under
  a single transition — no snapshot/rendering hack as the first attempt.
- **D-02:** Fallback if native `.transition(.move)` shows visual bugs (layout
  pop, flash, `@Query` re-fetch flicker) during verification: switch to a
  snapshot-based crossfade (per ROADMAP.md's stated fallback). Plan the native
  approach first; only add crossfade as a gap-closure step if verification
  surfaces a real bug on-device — do not pre-emptively build both.
  **Reversibility:** costly — if crossfade becomes necessary, most of the
  `.transition`/`withAnimation` wiring in `HistoryView` gets replaced, not
  reused.

### Direction semantics
- **D-03:** Direction follows segmented-control spatial order: List is the
  left segment, Calendar is the right segment (`HistorySegment.allCases` =
  `[.list, .calendar]`). List→Calendar slides leftward (new content enters
  from the trailing/right edge); Calendar→List slides rightward (new content
  enters from the leading/left edge). Matches standard iOS segmented-control
  spatial convention — no fixed "forward/back" semantic independent of
  picker position.

### Reduce Motion
- **D-04:** With `accessibilityReduceMotion` enabled, segment switching is an
  instant cut — no slide animation at all. Reuse the existing `reduceMotion`
  ternary pattern established in `OnboardingView.swift` (`reduceMotion ? nil :
  .spring(...)` style) rather than introducing a new pattern.

### Empty state
- **D-05:** The empty state (`earliestEvent == nil`, shown inside
  `listContent`) participates in the same transition container as populated
  List/Calendar content — switching into or out of empty state slides
  directionally like any other segment content, no special-cased instant swap
  or bypass. Keeps the interaction consistent regardless of dataset state,
  per HIST-03's "no layout pop, flash ... across List, Calendar, and the empty
  state" success criterion.

### Claude's Discretion
- Exact `@State` shape for tracking transition direction (e.g. a computed
  `Edge` derived from old/new `HistorySegment` comparison, or an explicit
  `@State private var transitionEdge: Edge`) — implementation wiring, resolve
  during planning.
- Whether the outer transition container needs an explicit `.id(segment)` on
  the `Group`/switch to force SwiftUI to treat list/calendar as distinct
  identities for the transition to fire correctly — technical detail for
  research/planning to confirm against SwiftUI's transition-identity rules.
- Whether `calendarNavHeader` (month prev/next chevrons) sits inside or
  outside the sliding container — reasonable to keep it inside
  `calendarContent` as today unless research finds a reason to hoist it.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` §"History List↔Calendar Directional Transition"
  (if present) — HIST-01..03 requirement text and scope boundaries
- `.planning/ROADMAP.md` §"Phase 6: History List↔Calendar Directional
  Transition" — goal, 3-point success criteria, UI hint, and the documented
  crossfade fallback for the List/ScrollView container-mismatch risk

### Relevant code
- `drinkpulse/Features/History/HistoryView.swift` — owns `segment: HistorySegment`
  `@State`, the `switch segment { }` in `body` (lines 64-79) that this phase
  wraps with a transition container; `listContent` (line 93) and
  `calendarContent` (line 110) are the two branches; `emptyState` (line 159)
  lives inside `listContent`
- `drinkpulse/Features/History/HistorySegment.swift` — `enum HistorySegment:
  String, CaseIterable { case list, calendar }`, `allCases` order is
  `[.list, .calendar]` — defines the spatial/direction mapping (D-03)
- `drinkpulse/Features/History/HistoryListQueryView.swift` — uses `List` (UIKit-
  backed), not `ScrollView` — the container-mismatch source of risk
- `drinkpulse/Features/History/HistoryCalendarQueryView.swift` — rendered inside
  `calendarContent`'s `ScrollView` in `HistoryView.swift:110-129`
- `drinkpulse/Features/Onboarding/OnboardingView.swift:9,80,87` — established
  `@Environment(\.accessibilityReduceMotion)` ternary pattern to reuse (D-04)

[No ADRs directly govern list/calendar transitions — this is new ground.]

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `OnboardingView.swift`'s `reduceMotion` ternary pattern — direct reuse for
  gating the slide animation (D-04)

### Established Patterns
- `HistoryView.segment` is already a single `@State` source of truth driving
  a `switch` — the transition wraps this existing switch rather than
  restructuring segment state
- Both `listContent` and `calendarContent` are already extracted as computed
  properties — the transition container change is localized to `body`
  (lines 64-79) plus whatever new `@State`/animation trigger is added

### Integration Points
- `HistoryView.body`'s `switch segment { }` block (lines 68-73) is the sole
  integration point — no other view in the codebase reads or reacts to
  `segment`
- `segmentPickerRow`'s `Picker(selection: $segment)` (line 81) is what
  triggers the state change the transition responds to

</code_context>

<specifics>
## Specific Ideas

No mockup or reference image was provided. Guiding principle: try the
simplest native SwiftUI mechanism (`.transition` + `withAnimation` on an
existing `switch`) before reaching for snapshot/crossfade complexity, given
List/ScrollView are opaque containers to SwiftUI's transition system and may
just work.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 6-History List↔Calendar Directional Transition*
*Context gathered: 2026-07-31*
