# 0050 — Port step 10: Shared alcohol-free day rule

**Status**: in-progress
**Frozen**: 2026-11-26
**Size**: small
**Created**: 2026-11-26
**Programme**: [0040 — Native UI port](../0040-native-ui-port/plan.md), step 10
**Branch**: `port/0050-alcohol-free-day-rule` (from `ui-revamp` at `678eee7`; `main` has no new commits)

> Execution: superpowers `executing-plans`, inline, one session (owner workflow, plan 0040
> "Workflow"). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One pure Domain rule decides, for every calendar day, whether it counts, whether it
is alcohol-free and whether it is heavy; Insights and Today use it and no screen keeps its own
copy.

**Architecture:** A new `nonisolated struct AlcoholFreeDayRule` in `Domain/` (Foundation only,
`Sendable`, calendar injected) takes the first event date, `now` and a calendar, and answers
per-day status plus the four aggregates the screens need. Callers pass a `(Date) -> Double`
grams-per-day lookup in display-unit grams, so density stays with the callers (unchanged).
`InsightsViewModel+HealthMetrics` and `DashboardViewModel` delegate to it; `HealthMetricsCard`
shows "–" when the period has no counted day.

**Tech stack:** Foundation `Calendar` (`startOfDay(for:)`, `date(byAdding:value:to:)`,
`dateInterval(of:for:)`); Swift Testing; XCUITest. No new Apple API: every `Calendar` call is
already used in the same files today.

**Spec:** `docs/superpowers/specs/2026-11-26-alcohol-free-day-rule-design.md` (approved by the
owner 2026-11-26).

## Summary

Three pieces of code compute alcohol-free numbers with three rules: Insights counts every
elapsed day of the period (also days before the first log and today without alcohol), Today's
streak walks back up to 366 days with no start bound, and Today's month count starts at the
first log but counts today while it has no alcohol. The spec fixes one rule (start day, finished
days, today only with alcohol, no future days, heavy ≥ 60 g).

## Context

- `InsightsViewModel+HealthMetrics.swift`: `bingeEpisodes` (`>= 60` over `activeDays`),
  `drinkFreeDays` and `longestSoberStreak` (over `elapsedDays`, no start bound).
- `InsightsViewModel.swift`: `elapsedDays` (only used by the two metrics above and by tests),
  `oldestEventDate` (any event, 0 % included), `gramsForNormalizedDay(_:)` (display-unit grams,
  keyed by `cal.startOfDay`), `cal` = `Calendar.current`.
- `DashboardViewModel.swift:126-167`: `currentStreakDays` (365-day cap, no start bound),
  `soberDaysThisMonthDates` (start-bound, counts today without alcohol). `calendar` is injectable.
- `HealthMetricsCard.swift`: renders `count/total` and percent; `heaviestDayCell` already uses
  "–" (en dash, U+2013) as its placeholder.
- UI tests pinning old values: `InsightsDrinkFreeDaysUITests`, `InsightsStreakUITests` (expected
  helpers start at the month start; the `multiday` fixture's first log is 13 days ago).
- Unit tests pinning old values: `InsightsViewModelTests+Aggregates` (`drinkFreeDays_*`,
  `longestSoberStreak_*`), `DashboardViewModelTests.soberDaysThisMonth_countsFromFirstEntryWhenInCurrentMonth`.
- `docs/plans/INDEX.md` says "Next number: **0049**" although 0049 exists — stale, fixed in
  Task 5.

## Decisions (this plan)

- **D0050-1 Domain type.** `drinkpulse/Domain/AlcoholFreeDayRule.swift` and
  `drinkpulse/Domain/AlcoholFreeDayStatus.swift`:

  ```swift
  nonisolated enum AlcoholFreeDayStatus: Equatable, Sendable { case notCounted, alcoholFree, drinking }

  nonisolated struct AlcoholFreeDayRule: Sendable {
      static let heavyDayThresholdGrams: Double = 60
      static func isHeavy(grams: Double) -> Bool                                  // grams >= 60
      static func heavyDayCount(in days: [Date], grams: (Date) -> Double) -> Int
      init(firstEventDate: Date?, now: Date, calendar: Calendar)
      func status(of day: Date, grams: Double) -> AlcoholFreeDayStatus
      func alcoholFreeDays(in days: [Date], grams: (Date) -> Double) -> (count: Int, total: Int)
      func longestAlcoholFreeStreak(in days: [Date], grams: (Date) -> Double) -> Int
      func alcoholFreeDates(in days: [Date], grams: (Date) -> Double) -> [Date]
      func currentAlcoholFreeStreak(grams: (Date) -> Double) -> Int
  }
  ```

  `status`: normalise `day` with `calendar.startOfDay`; no start → `.notCounted`; before the
  start day or after today → `.notCounted`; today → `.drinking` if grams > 0, else
  `.notCounted`; earlier → `.drinking` if grams > 0, else `.alcoholFree`. `grams` closures are
  called with start-of-day dates. A `.notCounted` day resets the longest run.
  `currentAlcoholFreeStreak`: 0 when today is `.drinking`; otherwise count `.alcoholFree` days
  walking back from yesterday, stopping at the first other status (the start day bounds it; no
  365 cap — spec "Decided by the builder").
- **D0050-2 Insights.** `alcoholFreeDayRule` built from `oldestEventDate`, `now`, `cal`;
  `drinkFreeDays`, `longestSoberStreak` run over `activeDays`, `bingeEpisodes` uses
  `heavyDayCount`. `elapsedDays` is deleted (no production caller left).
- **D0050-3 Today.** One private `[Date: Double]` day→display-grams map per access;
  `currentStreakDays` → `currentAlcoholFreeStreak`; `soberDaysThisMonthDates` →
  `alcoholFreeDates(in: calendar.days(in: monthStart...today))`. Property names stay (views and
  performance tests use them).
- **D0050-4 Placeholder.** When `vm.drinkFreeDays.total == 0`, "Alcohol-Free Days" and "Longest
  Alcohol-Free Streak" show "–" and the percent detail is nil.
- **D0050-5 UI test fixture.** New dataset `alcoholfreetoday`: profile + one 0 % beer
  (500 ml, ABV 0) logged now. Old code shows Insights week 1/1 and Today streak 366, month 1;
  new code shows "–", "–", 0 days, 0 days.
- **D0050-6 Test scope.** During tasks, `RunSomeTests` limited to:
  T1 `drinkpulseTests/AlcoholFreeDayRuleTests`; T2 `drinkpulseTests/InsightsViewModelTests`;
  T3 `drinkpulseTests/DashboardViewModelTests`; T4 `InsightsDrinkFreeDaysUITests`,
  `InsightsStreakUITests`, `InsightsUITests`, `DashboardUITests`,
  `InsightsAlcoholFreePlaceholderUITests`, `DashboardAlcoholFreeUITests`. Before merge: full
  `RunAllTests` (Domain change, AGENTS.md escalation) and line coverage of
  `AlcoholFreeDayRule.swift` and `AlcoholFreeDayStatus.swift` = 100 %.

## Scope

### In
The rule, its two call sites, the "–" placeholder, updated and new tests, docs.

### Out
Grams, density, limits, averages, totals, charts, calories, spend, "Highest Day", weekly
summary notification (spec Non-goals). No string-catalog change.

## Global constraints

- Heavy day: **≥ 60 g** of display-unit grams, one threshold for everyone.
- Start: calendar day of the first event of any kind, 0 % ABV included. No events → nothing counts.
- Today counts only with alcohol (grams > 0); future days never count.
- Domain type: Foundation only, `Sendable`, calendar injected, day boundaries via `Calendar.startOfDay`.
- Placeholder: "–" (U+2013), no percent.
- Swift Testing for new tests; files < 300 lines; zero warnings; no `print`, no logging of grams.

## Review focus

1. **Event at 23:59 / 00:00 boundary** — belongs to its calendar day; test
   `status_normalisesTimeOfDay` passes a 23:59 date and expects the same status as midnight (T1).
2. **First event in the future** (logged with a future date) — start after today → every
   past day `.notCounted`, streak 0; test `futureFirstEvent_nothingCounts` (T1).
3. **0 % drink today, nothing else** — today stays `.notCounted` (0 g), not drinking; covered by
   D0050-5 UI tests and `example2` (T1, T4).
4. **Period entirely before the first log** (All Time is bounded by it, week navigation stops
   at it) — `total == 0` → "–"; covered by `example5` (T1) and the placeholder UI test (T4).
5. **Mode density near the threshold** — 1500 ml × 5 % is 59.175 g (grams) vs 60.0 g (UK
   units); `example7` uses `AlcoholUnit.density(for:)`, not a literal (T1).

---

### Task 1: Domain rule + spec examples

**Files:**
- Create: `drinkpulse/Domain/AlcoholFreeDayStatus.swift`, `drinkpulse/Domain/AlcoholFreeDayRule.swift`
- Test: `drinkpulseTests/Domain/AlcoholFreeDayRuleTests.swift`

**Interfaces:** Produces D0050-1.

- [ ] **Step 1: Write the failing tests.** Fixture: `Calendar(identifier: .gregorian)`,
  `timeZone = TimeZone(identifier: "UTC")!`, `firstWeekday = 2`; helper
  `d(_ m: Int, _ day: Int, _ h: Int = 12) -> Date` for 2026; `now = d(11, 26, 10)` unless stated;
  week = Mon 23 … Sun 29 Nov; month = Nov 1 … 30; beer = 19.725 g. Grams supplied as a
  `[Date: Double]` keyed by start of day. One `@Test` per spec row, asserting the **New** column
  only:

  | Test | First event | Grams | Asserts |
  |---|---|---|---|
  | `example1_firstLogBeerWednesday` | Nov 25 | Nov 25: beer | week `alcoholFreeDays` == (0, 1); week longest == 0; month `alcoholFreeDates.count` == 0; `currentAlcoholFreeStreak` == 0 |
  | `example2_firstLogZeroPercentWednesday` | Nov 25 | none | week == (1, 1); streak == 1; month count == 1 |
  | `example3_loggingSinceOctober_alcoholOnlySaturday21` | Oct 1 | Nov 21: beer | week == (3, 3); week longest == 3; streak == 4; month count == 24 |
  | `example4_asThreePlus70gToday` | Oct 1 | Nov 21: beer, Nov 26 (20:00): 70 | week == (3, 4); `heavyDayCount(week)` == 1; streak == 0; month count == 24 |
  | `example5_mondayMorningNothingLogged` | Oct 1, `now = d(11, 23, 8)` | Nov 21: beer | week == (0, 0); week longest == 0 |
  | `example6_previousWeek_firstLogThursday19` | Nov 19 | Nov 19: beer | days Nov 16 … 22: == (3, 4); longest == 3 |
  | `example7_heavyThreshold_dependsOnModeDensity` | — | 1500 × 1 × 0.05 × density | `isHeavy` false with `AlcoholUnit.grams.density(for: .who)`; true with `AlcoholUnit.standardDrinks.density(for: .uk)` |

  Plus edge tests: `noEvents_nothingCounts` (nil start: week == (0, 0), streak 0, dates
  empty), `futureDay_isNotCounted`, `dayBeforeStart_isNotCounted`,
  `status_normalisesTimeOfDay`, `futureFirstEvent_nothingCounts`,
  `isHeavy_atExactly60_isTrue` / `isHeavy_below60_isFalse`.
- [ ] **Step 2: Run** `RunSomeTests` `drinkpulseTests/AlcoholFreeDayRuleTests`. Expected: build
  fails (type missing).
- [ ] **Step 3: Implement** D0050-1. Any example that does not match the spec table after a
  correct implementation → **stop and ask the owner** (do not change the table).
- [ ] **Step 4: Run** the same scope. Expected: all pass.
- [ ] **Step 5: Commit** `[plan-0050] shared alcohol-free day rule in Domain`.

### Task 2: Insights uses the rule; "–" placeholder

**Files:**
- Modify: `drinkpulse/Features/Insights/InsightsViewModel+HealthMetrics.swift:7-28`,
  `drinkpulse/Features/Insights/InsightsViewModel.swift:174-177` (delete `elapsedDays`),
  `drinkpulse/Features/Insights/Components/HealthMetricsCard.swift:41-73`
- Test: `drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift:148-226`,
  `drinkpulseTests/Features/Insights/InsightsViewModelTests.swift` (binge tests stay green)

**Interfaces:** Consumes D0050-1. Produces `var alcoholFreeDayRule: AlcoholFreeDayRule` on
`InsightsViewModel`.

- [ ] **Step 1: Update the pinning tests** (pinned `now` = 2026-07-18 12:00, `Calendar.current`,
  as today):
  - `drinkFreeDays_allFreeWhenNoEvents` → `drinkFreeDays_nothingCountedWhenNoEvents`: (0, 0).
  - `drinkFreeDays_oneDrinkingDay` → pinned now, single 30 g event today: (0, 1).
  - `drinkFreeDays_monthExcludesFutureDays` → `drinkFreeDays_monthNoEvents_nothingCounted`: (0, 0).
  - `drinkFreeDays_monthWithDrinkingDay_countsElapsedOnly` → `…_countsFromFirstLogToYesterday`:
    event 13 days ago → (12, 13).
  - New `drinkFreeDays_zeroPercentToday_nothingCounted`: one 0 g event today → (0, 0).
  - `longestSoberStreak_noEvents_spansAllElapsedDaysOfWeek` → `…_noEvents_isZero`: 0.
  - `longestSoberStreak_monthExcludesFutureDays` → `…_monthNoEvents_isZero`: 0.
  - `longestSoberStreak_monthStreakEndsAtToday_notEndOfMonth` → `…_endsYesterdayWithoutAlcoholToday`: 12.
  - `longestSoberStreak_reducedWhenHasDrinkingDay` unchanged.
- [ ] **Step 2: Run** D0050-6 T2 scope. Expected: the updated tests fail.
- [ ] **Step 3: Implement** D0050-2 and D0050-4 (`"–"` for both values when `total == 0`;
  `drinkFreePercent` nil). Update the card's doc comment (heavy-day threshold now lives in
  `AlcoholFreeDayRule`).
- [ ] **Step 4: Run** T2 scope. Expected: all pass (binge tests unchanged).
- [ ] **Step 5: Commit** `[plan-0050] Insights uses the shared alcohol-free day rule`.

### Task 3: Today uses the rule

**Files:**
- Modify: `drinkpulse/Features/Dashboard/DashboardViewModel.swift:126-167`
- Test: `drinkpulseTests/Features/Dashboard/DashboardViewModelTests.swift:159-264`

**Interfaces:** Consumes D0050-1; keeps `currentStreakDays: Int`,
`soberDaysThisMonthDates: [Date]`, `soberDaysThisMonth: Int`.

- [ ] **Step 1: Tests.** Existing streak tests stay. Update
  `soberDaysThisMonth_countsFromFirstEntryWhenInCurrentMonth` to pinned `now` = 2026-11-26 10:00
  (`vm.now`, `vm.calendar = .current`), drink 1 day ago → 0 (today no longer counted). New:
  `currentStreak_zeroPercentOnlyYesterday_isOne` (0 g event 1 day ago, pinned now → 1; old
  code 366); `currentStreak_stopsAtFirstLogDay` (0 g event 5 days ago → 5);
  `soberDaysThisMonth_excludesTodayWithoutAlcohol` (0 g events 3 days ago and today → 3).
- [ ] **Step 2: Run** T3 scope. Expected: new/updated tests fail.
- [ ] **Step 3: Implement** D0050-3.
- [ ] **Step 4: Run** T3 scope. Expected: pass.
- [ ] **Step 5: Commit** `[plan-0050] Today uses the shared alcohol-free day rule`.

### Task 4: UI tests

**Files:**
- Modify: `drinkpulse/UITestSeed.swift` (dispatch `datasetArgument == "alcoholfreetoday"`),
  `drinkpulse/UITestSeed+Fixtures.swift` (`seedAlcoholFreeTodayEvents(into:)`)
- Modify: `drinkpulseUITests/Features/Insights/InsightsDrinkFreeDaysUITests.swift:79-102`,
  `drinkpulseUITests/Features/Insights/InsightsStreakUITests.swift:69-90`
- Create: `drinkpulseUITests/Features/Insights/InsightsAlcoholFreePlaceholderUITests.swift`,
  `drinkpulseUITests/Features/Dashboard/DashboardAlcoholFreeUITests.swift`

- [ ] **Step 1: Write the tests.**
  - Expected helpers of the two `multiday` tests start at `max(monthStart, today − 13 days)`
    (the fixture's first log); today has alcohol (offset 0) so it counts.
  - `InsightsAlcoholFreePlaceholderUITests.test_week_noCountedDay_showsDash`: dataset
    `alcoholfreetoday`, Insights, Week; labels `"Alcohol-Free Days: –"` and
    `"Longest Alcohol-Free Streak: –"` exist.
  - `DashboardAlcoholFreeUITests.test_zeroPercentToday_streakAndMonthAreZero`: same dataset,
    Today; the "Alcohol-Free Streak" and "Alcohol-Free This Month" tiles read "0 days".
- [ ] **Step 2: Run** the two new classes before the fixture exists. Expected:
  `InsightsAlcoholFreePlaceholderUITests` fails (unknown dataset falls back to one beer now →
  "1/1"). `DashboardAlcoholFreeUITests` may pass on that fallback; its regression value is
  against the pre-plan code (366 / 1), recorded in `execution.md`, not re-proved here.
- [ ] **Step 3: Implement** D0050-5.
- [ ] **Step 4: Run** T4 scope. Expected: pass; both new test names appear in the log.
- [ ] **Step 5: Commit** `[plan-0050] UI tests for the alcohol-free day rule`.

### Task 5: Gates, docs, close

- [ ] **Step 1: Build** with zero warnings (`BuildProject`).
- [ ] **Step 2: Full suite** `RunAllTests`; coverage of `AlcoholFreeDayRule.swift` and
  `AlcoholFreeDayStatus.swift` = 100 % (from the run's `.xcresult` via `xcrun xccov`; if the
  MCP run has no coverage, the AGENTS.md `xcodebuild test -enableCodeCoverage YES` command is
  the named fallback). Record in `execution.md`.
- [ ] **Step 3: File size and privacy** (AGENTS.md `find`; no network, no logging, no `print`).
- [ ] **Step 4: Docs:** `docs/domain.md` (rule + WHO heavy threshold), README and
  `.planning/PROJECT.md` if they describe these metrics, `docs/architecture.md` if it lists
  Domain types, `DEVLOG.md`, `current-focus.md`, `open-questions.md`, `INDEX.md` (status, next
  number 0051), memory `native-swiftui-prototype.md` (step 10 done, next step 11),
  `execution.md`, `retrospective.md`. Commit `[plan-0050] docs: close plan`.
- [ ] **Step 5: Final review:** one fresh superpowers reviewer over the branch. Fix Critical /
  Important with tests; minors to `execution.md`.
- [ ] **Step 6:** `git switch ui-revamp && git merge --no-ff port/0050-alcohol-free-day-rule`;
  report rulings, deferred minors, owner decisions; ask about push.

## Open questions

- [ ] Owner hand-verification of the seven spec examples against the Task 1 tests.

## Tests required

New: `AlcoholFreeDayRuleTests` (7 examples + 7 edge tests), Insights/Dashboard VM tests listed
in Tasks 2–3, `InsightsAlcoholFreePlaceholderUITests`, `DashboardAlcoholFreeUITests`. Updated:
8 Insights aggregate tests, 1 Dashboard test, 2 Insights UI tests. Coverage: new Domain files
100 %; full suite before merge.
