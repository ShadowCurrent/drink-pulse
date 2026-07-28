---
created: 2026-07-26T17:20:00.000Z
title: Animate History list row insert and delete
area: ui
severity: cosmetic
cluster: B
files:
  - drinkpulse/Features/History/HistoryListQueryView.swift:36-66 (List/ForEach, swipe-to-delete, no animation)
  - drinkpulse/Features/History/Components/EventContextMenu.swift:36 (context-menu delete path)
  - drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift:92 (modelContext.insert — the "new entry" side)
---

## Problem

In History → **List** segment (`HistorySegment.list`, the "table mode"), rows
snap in and out with no transition:

- **Delete** — `HistoryListQueryView.swift` deletes via
  `modelContext.delete(event)` inside `.swipeActions` with **no**
  `withAnimation` wrapper and no `.animation(...)` modifier on the `List`. The
  `@Query` result changes and the row disappears instantly. Same for the
  second delete path in `EventContextMenu.swift:36`.
- **Insert** — a drink logged from Add Drink
  (`DrinkDetailInputView+Logic.swift:92`, `modelContext.insert(event)`) pops
  into the History list with no entrance transition when the user navigates
  back.

Deleting the last row of a day section also removes the whole `Section`
(rows are grouped by `vm.groupedByDay(events)`), so the section header
disappears in the same abrupt frame — that's the most jarring case and the
one most likely to look broken.

## Solution

TBD — sketch:

- Wrap both delete call sites in `withAnimation` (or attach
  `.animation(_:value:)` keyed on the events array / a derived count to the
  `List`), so `@Query`-driven diffs animate. Two call sites, keep them
  consistent — a shared helper is preferable to duplicating the animation
  choice.
- Verify the section-collapse case (deleting a day's last event) animates
  acceptably, not just the single-row case.
- Insert side: confirm whether the row should animate on return-to-History.
  The insert happens on a different screen, so the transition may need to be
  driven from the List's appearance rather than the insert call.
- **`reduceMotion` is mandatory** per CLAUDE.md accessibility rules. Follow
  the pattern already used in
  `Features/Onboarding/OnboardingView.swift:80` —
  `.animation(reduceMotion ? nil : .someCurve, value:)` — rather than
  inventing a new one.
- Check whether the **Calendar** segment
  (`Components/HistoryCalendarView.swift`, which already uses animation)
  needs a matching treatment for consistency, or is explicitly out of scope.

Gate: this is a user-facing change to an existing screen's behaviour, so per
CLAUDE.md it needs at least one `drinkpulseUITests` test. Existing History UI
tests to extend rather than duplicate:
`drinkpulseUITests/Features/History/EditDeleteConfirmationUITests.swift`,
`HistoryInteractionUITests+Helpers.swift`. Note that asserting on an
*animation* in XCUITest is unreliable — pin the post-animation end state
(row gone / row present) and keep the test about correctness, not timing.

Size: small, likely a `/gsd-quick` task rather than a full plan.

## Resolution (2026-07-28)

Fixed the **delete** side: both call sites (`HistoryListQueryView.swift`
swipe action, `EventContextMenu.swift` context-menu delete) now route through
a shared `animatedHistoryDelete(reduceMotion:_:)` helper (`withAnimation`
unless `accessibilityReduceMotion`), so the `@Query`-driven row/section
removal — including the section-collapse case when a day's last event is
removed — animates consistently and respects reduced motion. Existing
`HistoryInteractionUITests.test_contextMenuDelete_removesEvent` and
`test_swipeDelete_removesEvent` already pin the correct post-delete end state
(seeded event is the day's only one, so both exercise the section-collapse
path too) and pass unchanged with the new animation wrapper.

**Insert side scoped out**: the insert happens on Add Drink, a different
screen than History. By the time the sheet dismisses and History reappears,
the row already exists in a fresh mount — there is no moment where History
is on screen watching the row appear, so there is nothing to animate on
return. No fix needed there.

Calendar segment (`HistoryCalendarDayDetail.swift`) has no swipe-delete, only
the shared context-menu delete — now consistent with List for free via the
same helper.
