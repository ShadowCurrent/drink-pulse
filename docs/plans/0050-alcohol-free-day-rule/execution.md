# 0050 — Execution journal

## 2026-11-26 — Plan frozen

- Owner approved the plan in chat and asked to freeze it; execution runs in a new session
  (inline, superpowers `executing-plans`).
- Branch `port/0050-alcohol-free-day-rule` from `ui-revamp` at `678eee7`; `main` had no new
  commits. Xcode run destination switched back to the iPhone 18 Pro simulator (iOS 27.2).
- `INDEX.md` "Next number" was stale (0049); set to 0051.

## 2026-11-26 — Execution (inline, superpowers `executing-plans`)

Xcode MCP workspace `drinkpulse.xcodeproj` (identifier resolved via `XcodeListWorkspaces`);
active destination iPhone 18 Pro simulator, iOS 27.2. All test runs via MCP `RunSomeTests`
within the D0050-6 scope.

### Task 1 — Domain rule (`40e2a3e`)
- RED: build failed, "Cannot find type 'AlcoholFreeDayRule' in scope".
- GREEN: `AlcoholFreeDayRuleTests` 16/16. All seven spec examples match the "New" column of
  the spec table; no stop was needed.
- Deviation: two edge tests beyond the plan list
  (`today_withoutAlcohol_isNotCounted_withAlcohol_isDrinking`,
  `longestStreak_resetsOnNotCountedAndDrinkingDays`) to cover every branch.

### Task 2 — Insights (`1a5a09f`)
- RED: 8 updated tests failed (old values, e.g. week streak 6, month streak 18 / 13).
- GREEN: `InsightsViewModelTests` 77 passed, 0 failed (6 "No result" rows are the renamed
  old test identifiers still in Xcode's test index).
- `elapsedDays` deleted; `HealthMetricsCard` shows "–" for both values when
  `drinkFreeDays.total == 0`, percent nil.

### Task 3 — Today (`a7eb95a`)
- RED: 4 failed — 0 % beer yesterday streak 366, 0 % 5 days ago streak 366, month 4 instead
  of 3, first-entry test 1 instead of 0.
- GREEN: `DashboardViewModelTests` 74/74.
- Deviation: the three new tests live in `DashboardViewModelTests+AlcoholFree.swift` (the main
  test file would cross 300 lines); the shared `event()` helper gained `relativeTo:` (default
  `.now`, existing callers unchanged).
- Regression value against pre-plan code for D0050-5 (Today): streak 366 and month 1 for a
  0 % drink only (proved by the unit RED above; the UI test passes on the default fallback
  seed too, as the plan predicted).

### Task 4 — UI tests (`a7dc8e2`)
- RED (before fixture): `InsightsAlcoholFreePlaceholderUITests` failed ("Alcohol-Free Days
  should read '–'"); `DashboardAlcoholFreeUITests` passed on the fallback seed (expected).
- GREEN: T4 scope (6 classes) 18/18; both new test names in the results.

### Task 5 — Gates
- `BuildProject` (build for testing): succeeded, 0 warnings, 0 errors.
- **Full suite skipped — owner decision (2026-11-26):** `RunAllTests` was started, then stopped
  on the owner's word ("walić ten pełny test … to trwa za długo") because it includes the UI
  tests. This overrides D0050-6's full-suite gate and the AGENTS.md Domain escalation for this
  plan. Evidence instead: scoped runs of every affected class (Tasks 1–4 above).
- Coverage (from the Task 1 scoped run's `.xcresult`, `xcrun xccov view --report`):
  `AlcoholFreeDayRule.swift` 100.00 % (60/60). `AlcoholFreeDayStatus.swift` has no executable
  lines (a bare enum), so `xccov` does not list it — nothing to cover.
- File size: the AGENTS.md `find` reports nothing over 300 lines. Privacy: no network, no
  logging, no `print` added.
- Docs: `docs/domain.md` gains "Alcohol-free and heavy days". README (metrics listed by name
  only), `.planning/PROJECT.md` and `docs/architecture.md` (neither describes these rules nor
  lists Domain types) need no change.

### Final review (fresh superpowers reviewer, opus, `678eee7..a7dc8e2`)
- 0 Critical, 1 Important, 6 Minor. Ready to merge after the Important fix.
- **Fixed (Important):** `currentAlcoholFreeStreak` looked grams up with dates from
  `date(byAdding: .day, value: -1)` without `startOfDay`. Where DST skips midnight (e.g.
  `America/Santiago`, 2026-09-06 starts at 01:00) every older day lands on 01:00, all lookups
  miss, and the streak runs back to the first log while Insights shows the right answer.
  Test `currentStreak_acrossMidnightDSTJump_stopsAtDrinkingDay` RED (11 instead of 6) → GREEN;
  scoped run `AlcoholFreeDayRuleTests` + `InsightsViewModelTests` + `DashboardViewModelTests`
  168 passed, 0 failed; `AlcoholFreeDayRule.swift` coverage 100.00 % (63/63). Commit `bc74136`.
- **Deferred minors:**
  1. `heavyDayCount` passes raw dates to `grams` (same DST-at-midnight gap as period totals
     and "Highest Day"; pre-existing in Insights' day list).
  2. Today uses `calendar.days(in:)` from `Features/Insights/Calendar+Days.swift`; move it to a
     shared folder.
  3. `DashboardView` reads `currentStreakDays` three times per render, each building the day map
     (still far cheaper than the old per-day filtering).
  4. Pre-existing: Insights' grams cache keeps keys from the calendar at the time `events` was
     set; a time-zone change while running can mismatch. Dashboard copies `Calendar.current`
     once.
  5. `longestSoberStreak_reducedWhenHasDrinkingDay` is weak (`.now`, asserts `< 7`; now always 0).
  6. `DashboardAlcoholFreeUITests` also passes on the fallback seed (plan accepted; regression
     proved by the unit RED).
- Ruling on the reviewer's "declined" item: a stale `now` across midnight while the app stays
  in the foreground is pre-existing and unchanged by this plan.
