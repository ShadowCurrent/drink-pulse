---
created: 2026-07-26T17:40:00.000Z
title: Slide transition between History list and calendar segments
area: ui
severity: cosmetic
cluster: B
resolves_phase: 6
files:
  - drinkpulse/Features/History/HistoryView.swift:64-79 (body — bare Group/switch, no transition)
  - drinkpulse/Features/History/HistoryView.swift:81-91 (segmentPickerRow — the Picker driving `segment`)
  - drinkpulse/Features/History/HistoryView.swift:93-129 (listContent / calendarContent — the two branches)
  - drinkpulse/Features/History/HistorySegment.swift (the enum being switched on)
---

## Problem

Switching the History segmented control between **List** and **Calendar**
swaps the content with no transition — the old view vanishes and the new one
appears in the same frame.

`HistoryView.swift:67-74` is a bare `Group { switch segment { ... } }` with
**no** `.transition(...)`, no `.animation(_:value: segment)`, and no `.id`
driving an identity change. The `Picker` at :82 mutates `segment` directly
with no `withAnimation`, so nothing animates by construction.

## Solution

TBD — sketch:

- Attach a slide transition to the switched content and drive it from
  `segment`, either via `.animation(_:value: segment)` on the `Group` plus
  `.transition(.slide)` (or an asymmetric move) on each branch, or by
  animating the binding at the `Picker`.
- **Directionality needs the previous value.** A slide that always goes the
  same way looks wrong going back; list→calendar should travel opposite to
  calendar→list. That means tracking the prior segment (or deriving direction
  from `HistorySegment.allCases` ordering) — it is not free with a plain
  `.slide`.
- **The two branches are structurally different containers**: `listContent`
  resolves to a `List` (`HistoryListQueryView`, `.insetGrouped`) while
  `calendarContent` is a `ScrollView`. Cross-fading/sliding two different
  scroll containers can produce layout jumps or a flash of unstyled
  background mid-transition — verify on device, not just in a Preview.
- The list branch also has an **empty state** fork
  (`ContentUnavailableView` at :95) so there are effectively three states to
  transition between, not two.
- `HistoryListQueryView` is `@Query`-backed and re-runs its fetch on
  appearance; confirm the transition does not visibly race the query (row
  content popping in mid-slide).
- **`reduceMotion` is mandatory** per CLAUDE.md accessibility rules. Reuse the
  existing pattern at `Features/Onboarding/OnboardingView.swift:80`
  (`.animation(reduceMotion ? nil : .someCurve, value:)`) rather than
  inventing a new one.

Related but deliberately separate: `2026-07-26-animate-history-list-row-insert-delete.md`
covers row-level diffs *inside* the List. Different code path; if both are
picked up together, keep the animation curves consistent between them.

Gate: user-facing change to an existing screen's behaviour, so per CLAUDE.md
at least one `drinkpulseUITests` test is required and must actually run.
Existing candidate to extend:
`drinkpulseUITests/Features/History/HistoryInteractionUITests+Helpers.swift`.
Asserting on animation in XCUITest is unreliable — pin the post-transition end
state (correct segment's content visible), not timing.

Size: small — likely a `/gsd-quick`, though the directionality and
List-vs-ScrollView caveats above could expand it.
