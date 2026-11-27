---
status: complete
quick_task: 260718-vgy
title: Fix bug: Insights month/week view "Drink-Free Days" counts future days
date: 2026-07-18
commits:
  - 30b9d76 "[quick-260718-vgy] fix drinkFreeDays to exclude future days"
  - 2f31fe6 "[quick-260718-vgy] add UI test for Month-view Drink-Free Days card"
  - 56587bd "[quick-260718-vgy] append DEVLOG entry for drinkFreeDays fix"
---

# Summary

Fixed the Insights "Drink-Free Days" card (Month and Week periods) to stop
counting future (not-yet-elapsed) days in either the numerator or the
denominator of its "X/Y" value. This closes the follow-up explicitly flagged
in the quick-260718-kgp DEVLOG entry (which fixed the analogous bug in
"Longest Streak" but left `drinkFreeDays` as an owner-flagged out-of-scope item).

## Root cause

`InsightsViewModel+HealthMetrics.drinkFreeDays` read `activeDays` — which
deliberately keeps the full week/month calendar grid so the area chart isn't a
stub mid-period — for both `total` (denominator) and `free` (numerator).
Future days carry zero grams, so they read as "drink-free" and inflated both
sides (e.g. on July 18, current month showed "31/31" instead of "18/18").

## Fix

`drinkFreeDays` now iterates the existing `elapsedDays` property (added by
quick-260718-kgp for `longestSoberStreak`: `activeDays` filtered to
`<= cal.startOfDay(for: now)`) for both `total` and `free`. No new property
was added. `InsightsViewModel.swift`, `effectiveDateRange`, `activeDays`, and
`longestSoberStreak` were not touched.

File changed: `drinkpulse/Features/Insights/InsightsViewModel+HealthMetrics.swift`

## Tests

- `drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift`:
  - New `drinkFreeDays_monthExcludesFutureDays` (no events, `now` pinned to
    2026-07-18 → expects 18/18, not 31/31).
  - New `drinkFreeDays_monthWithDrinkingDay_countsElapsedOnly` (one drinking
    day on July 5 → expects 17/18, not 30/31).
  - Updated `drinkFreeDays_allFreeWhenNoEvents` and `drinkFreeDays_oneDrinkingDay`
    (week period) to assert against `vm.elapsedDays.count` instead of a
    hard-coded 7 (which would be flaky once future days are excluded).
- `drinkpulseUITests/Features/Insights/InsightsDrinkFreeDaysUITests.swift`
  (new file, 124 lines): `test_monthView_drinkFreeDays_excludesFutureDays`
  drives the real Month view with the `-dp_uitest_dataset multiday` seed,
  parses the rendered "Drink-Free Days: X/Y" label, and asserts it against an
  in-process elapsed-only computation mirroring production logic.

## Gates (CLAUDE.md end-of-task checklist)

- `xcodebuild build`: clean, zero warnings.
- `xcodebuild test` (full suite, unit + UI): `** TEST SUCCEEDED **`, 594
  tests, 0 failures. Confirmed via xcresult that both new unit tests and the
  new UI test (`InsightsDrinkFreeDaysUITests/test_monthView_drinkFreeDays_excludesFutureDays`)
  actually ran and passed.
- Coverage: app overall 93.42% (≥90% target). `InsightsViewModel+HealthMetrics.swift`
  100%. `InsightsViewModel.swift` (untouched) 94.92% (≥90% view-model target).
- File size: `find drinkpulse -name "*.swift" -not -path "*/Preview Content/*" | xargs wc -l | awk '$1 > 300 {print}'`
  reports nothing — no production file exceeds 300 lines. (Note:
  `InsightsViewModelTests+Aggregates.swift` — a test file, outside the scope
  of that find command per project convention — was already over 300 lines
  before this task; not split, consistent with how prior sessions have
  handled it.)
- No force-unwraps introduced in production code.
- No new network calls, no new logging, no PII in logs.
- Living docs: no contradiction introduced (grams-of-alcohol math untouched,
  domain.md/architecture.md unaffected). No ADR needed (no architectural change).
- `docs/DEVLOG.md`: new entry appended (2026-07-18 23:30), explicitly closing
  the quick-260718-kgp follow-up.

## Non-goals honored

- Did not add a new clamped-days property (reused `elapsedDays`).
- Did not touch `InsightsViewModel.swift`, `effectiveDateRange`, `activeDays`.
- Did not touch `longestSoberStreak`, `bingeEpisodes`, `heaviestDay`,
  `periodTotalGrams`, `periodCaloriesKcal`.
- No BAC/guideline/sync logic touched.
- No SwiftData schema change.

## Open questions

None new.
