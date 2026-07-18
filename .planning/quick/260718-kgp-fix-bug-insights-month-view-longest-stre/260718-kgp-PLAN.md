---
phase: quick-260718-kgp
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - drinkpulse/Features/Insights/InsightsViewModel.swift
  - drinkpulse/Features/Insights/InsightsViewModel+HealthMetrics.swift
  - drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift
  - drinkpulseUITests/Features/Insights/InsightsUITests.swift
  - docs/DEVLOG.md
autonomous: true
requirements:
  - BUGFIX-insights-longest-streak-future-days
user_setup: []

must_haves:
  truths:
    - "On the Insights Month view, the Longest Streak card counts only days up to and including today — future (not-yet-elapsed) days in the current month are never counted as sober days."
    - "Past months (offset < 0) and Year / All-Time scopes are unaffected: their longest-streak values are identical before and after the fix."
    - "The fix is isolated to the sober-streak metric; totals, calories, binge days, heaviest day, and drink-free-days behaviour are unchanged."
  artifacts:
    - "drinkpulse/Features/Insights/InsightsViewModel.swift (new elapsedDays window property)"
    - "drinkpulse/Features/Insights/InsightsViewModel+HealthMetrics.swift (longestSoberStreak reads elapsedDays)"
    - "drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift (deterministic regression tests)"
    - "drinkpulseUITests/Features/Insights/InsightsUITests.swift (month-view streak UI test)"
  key_links:
    - "InsightsViewModel.elapsedDays filters InsightsViewModel.activeDays to days <= startOfDay(now)"
    - "InsightsViewModel+HealthMetrics.longestSoberStreak iterates elapsedDays (not activeDays)"
---

<objective>
Fix the Insights "Longest Streak" card so it stops counting future days in the current month.

Bug: In the Insights tab, Month period, the "Longest Streak" card computes the longest
sober (drink-free) streak over the whole calendar month — including days after today that
haven't happened yet. Because future days carry zero grams, they read as "sober" and inflate
the streak (e.g. on July 18 an empty rest-of-month adds 13 phantom sober days).

Root cause (already located): `InsightsViewModel.effectiveDateRange` deliberately keeps the
full calendar grid for `.week`/`.month` (so the area chart isn't a stub mid-month). Every
per-day metric reads `activeDays`, which is built from that full range. `longestSoberStreak`
(in `InsightsViewModel+HealthMetrics.swift`) therefore iterates future days too. The same code
path also affects the current Week view for the same reason.

Fix: introduce an `elapsedDays` window (activeDays clamped to `<= today`) and have
`longestSoberStreak` iterate it. This is a no-op for past periods and for Year/All-Time
(already clamped to `now` via `effectiveDateRange`), and correctly excludes future days for the
current week and month.

Purpose: A streak of not-yet-elapsed days is meaningless and misleads the user about their
current progress.
Output: Corrected metric, deterministic unit regression tests, one UI test on the Month view,
and the CLAUDE.md end-of-task gates.
</objective>

<execution_context>
@/Users/fempter/Developer/drinkpulse/.claude/gsd-core/workflows/execute-plan.md
</execution_context>

<context>
@./CLAUDE.md
@drinkpulse/Features/Insights/InsightsViewModel.swift
@drinkpulse/Features/Insights/InsightsViewModel+HealthMetrics.swift
@drinkpulse/Features/Insights/Components/HealthMetricsCard.swift
@drinkpulseTests/Features/Insights/InsightsViewModelTests.swift
@drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift
@drinkpulseUITests/Features/Insights/InsightsUITests.swift
@drinkpulse/UITestSeed+Fixtures.swift

# Key facts already verified during planning:
# - activeDays comes from cal.days(in: effectiveDateRange) and every element is normalized to start-of-day.
# - effectiveDateRange clamps .year/.allTime to `now` but returns the full grid for .week/.month.
# - `now` is an injectable stored property on InsightsViewModel (tests set vm.now).
# - The streak card renders via MetricCell with combined a11y label "Longest Streak: N d"
#   (English title from Localizable.xcstrings key insights.metric.soberStreak = "Longest Streak").
# - Existing test helpers: makeVM(), makeContainer(), event(daysAgo:hoursOffset:grams:relativeTo:in:).
# - The multiday UI seed (-dp_uitest_dataset multiday) logs drinks at days-ago offsets
#   {0,1,2,4,6,7,9,11,13} relative to launch day, all in the past/today.
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Exclude future days from longestSoberStreak (elapsedDays window) + unit regression tests</name>
  <files>drinkpulse/Features/Insights/InsightsViewModel.swift, drinkpulse/Features/Insights/InsightsViewModel+HealthMetrics.swift, drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift</files>
  <behavior>
    Write these tests FIRST (they must fail against current code), in
    InsightsViewModelTests+Aggregates.swift under the "// MARK: - longestSoberStreak" section:

    - Test `longestSoberStreak_monthExcludesFutureDays`: makeVM(), vm.events = [],
      vm.now pinned to DateComponents(year: 2026, month: 7, day: 18) via Calendar.current,
      vm.period = .month. Expect vm.longestSoberStreak == 18 (July has 31 days but only 18 have
      elapsed). Pre-fix this returns 31.
    - Test `longestSoberStreak_monthStreakEndsAtToday_notEndOfMonth`: makeContainer() + makeVM(),
      vm.period = .month, vm.now pinned to 2026-07-18. Seed one drinking day on July 5 via
      event(daysAgo: 13, grams: 30, relativeTo: pinnedNow, in: context). Expect
      vm.longestSoberStreak == 13 (the July 6–18 sober run; July 1–4 is only 4). Pre-fix returns
      26 because it counts July 6–31.
    - UPDATE the existing `longestSoberStreak_fullWeekWhenNoEvents` test: it currently asserts
      `== 7`, which encodes the buggy full-grid assumption and becomes flaky once future days are
      excluded (it only equals 7 on the last day of the week). Change its assertion to
      `#expect(vm.longestSoberStreak == vm.elapsedDays.count)` and update its name/comment to
      describe the elapsed-day invariant (no events → the streak spans every elapsed day of the
      current week). Keep vm.now = .now, vm.period = .week.
    - Confirm the existing `longestSoberStreak_reducedWhenHasDrinkingDay` (asserts `< 7`) still
      passes unchanged.
  </behavior>
  <action>
    Then make the tests pass with a minimal, isolated change.

    In InsightsViewModel.swift, add a computed property `elapsedDays` (place it directly after the
    `activeDays` property so the caching/observation notes stay adjacent). It returns `activeDays`
    filtered to elements `<= cal.startOfDay(for: now)`. Add a short comment explaining WHY:
    activeDays keeps the full week/month grid for the chart, but streak/elapsed metrics must not
    count days that have not happened yet — a future empty day is not a sober day. Note it is a
    no-op for past periods and for Year/All-Time (effectiveDateRange already clamps those to now).
    Do NOT cache it (it is a cheap filter over the already-cached activeDays and reads the tracked
    `now`); do NOT change effectiveDateRange or activeDays — the chart and other metrics must keep
    the full grid.

    In InsightsViewModel+HealthMetrics.swift, change `longestSoberStreak` to iterate `elapsedDays`
    instead of `activeDays`. No other change to its logic.

    Do NOT touch `drinkFreeDays`, `bingeEpisodes`, `heaviestDay`, `periodTotalGrams`,
    `periodCaloriesKcal`, or any other metric — those are explicitly out of scope for this bug
    (see Non-goals). Keep the diff to the streak path only.
  </action>
  <verify>
    <automated>xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests/InsightsViewModelTests 2>&1 | tail -30</automated>
  </verify>
  <done>
    The two new tests and the updated week test pass; all pre-existing InsightsViewModelTests stay
    green. `elapsedDays` exists on InsightsViewModel and `longestSoberStreak` reads it.
    effectiveDateRange and activeDays are unchanged.
  </done>
</task>

<task type="auto">
  <name>Task 2: UI test — Month-view Longest Streak card excludes future days</name>
  <files>drinkpulseUITests/Features/Insights/InsightsUITests.swift</files>
  <action>
    Add one XCUITest that drives the real Insights Month view end to end and asserts the displayed
    "Longest Streak" value equals the elapsed-only expected value computed from the known
    multiday seed. Reuse the existing helpers in InsightsUITests (launchApp, openInsights,
    firstElement(beginningWith:)) — do NOT add a new seed dataset or a date-injection hook.

    Test `test_monthView_longestStreak_excludesFutureDays`:
    1. launchApp() (this already passes -dp_uitest_dataset multiday), then openInsights().
    2. Tap the "Month" segment on the period segmented control (app.segmentedControls.firstMatch,
       buttons["Month"]), following the same pattern as test_periodPicker_switchesRange_changesHeroTotal.
    3. Locate the streak cell with firstElement(beginningWith: "Longest Streak"), wait for it,
       read its .label, and parse the integer N out of the "Longest Streak: N d" string
       (extract the run of digits — do not assume a fixed position).
    4. In the test process, compute the expected elapsed-only streak deterministically from the
       seed and today's date using Calendar.current: today = startOfDay(now); monthStart = start
       of the current month's dateInterval; drinking days = the set of startOfDay(today - offset)
       for offset in {0,1,2,4,6,7,9,11,13}; then walk day-by-day from monthStart through today
       inclusive, resetting the run to 0 on a drinking day and otherwise incrementing it, tracking
       the max. This mirrors production `elapsedDays` + `longestSoberStreak`.
    5. Assert the parsed N equals the computed expected value. Add a message explaining that a
       larger value means the (now-fixed) future-day counting has regressed, since pre-fix the
       card would include the empty rest-of-month tail.

    Keep locators keyed on the app's English a11y label only (the app is English-only; the
    simulator system locale is Polish, so never match system UI by localized text) — consistent
    with the file's existing convention.

    FILE-SIZE GUARD: InsightsUITests.swift is ~263 lines. After adding the test, run the
    file-size check (see verify). If the file crosses the 300-line ceiling, extract the new test
    into drinkpulseUITests/Features/Insights/InsightsStreakUITests.swift as a new
    @MainActor final class (copying only the 2–3 private helpers it needs) rather than exceeding
    the limit — the folder is a PBXFileSystemSynchronizedRootGroup, so no project.pbxproj edit is
    needed.
  </action>
  <verify>
    <automated>xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseUITests/InsightsUITests/test_monthView_longestStreak_excludesFutureDays 2>&1 | tail -30 || xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseUITests 2>&1 | tail -30</automated>
  </verify>
  <done>
    The new UI test appears in the test log (it actually ran) and passes, asserting the Month-view
    "Longest Streak" value matches the elapsed-only computation. No file exceeds 300 lines.
  </done>
</task>

<task type="auto">
  <name>Task 3: End-of-task gates + DEVLOG entry</name>
  <files>docs/DEVLOG.md</files>
  <action>
    Run the CLAUDE.md end-of-task checklist for this bug fix and record it:

    1. Build clean with zero warnings and the full test suite green (see verify). Swift 6
       strict-concurrency warnings, if any surface, are fixed at the source — never suppressed.
    2. Coverage: confirm the changed view-model path stays at/above the ≥90% view-model target
       (the new elapsedDays property and longestSoberStreak are exercised by the Task 1 tests).
    3. File-size check: run the find command from CLAUDE.md and confirm no Swift file (excluding
       Preview Content) exceeds 300 lines.
    4. Privacy/logging: confirm no new network calls, no new logging of health data, no print in
       production (this change adds none).
    5. Living-docs audit: this is an isolated metric bugfix — architecture.md and domain.md
       calculation rules are unchanged (grams-of-alcohol math untouched); confirm nothing in the
       living docs now contradicts reality. No ADR needed (no architectural decision).
    6. Append a dated DEVLOG.md entry (English, append-only — never edit existing entries):
       date + time, the bug (Insights Month "Longest Streak" counted future days), the root cause
       (activeDays uses the full week/month grid; effectiveDateRange only clamps year/all-time),
       the fix (new elapsedDays window; longestSoberStreak iterates it), the tests added, and the
       explicit non-goal that drinkFreeDays has the same latent full-grid behaviour but was left
       unchanged per the minimal-fix scope (flag for owner follow-up).
  </action>
  <verify>
    <automated>xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20; find drinkpulse -name "*.swift" -not -path "*/Preview Content/*" | xargs wc -l | awk '$1 > 300 {print}'</automated>
  </verify>
  <done>
    xcodebuild build is warning-free, xcodebuild test is green (unit + UI), the find command
    reports no file over 300 lines, and DEVLOG.md has the new entry.
  </done>
</task>

</tasks>

<non_goals>
- Do NOT change `drinkFreeDays`, `bingeEpisodes`, `heaviestDay`, `periodTotalGrams`, or
  `periodCaloriesKcal`. `drinkFreeDays` has the same latent full-grid behaviour (it counts
  future days toward the "X/Y" denominator), but the user reported only the Longest Streak card
  and the constraint is a minimal fix. Flag drinkFreeDays as an owner follow-up in DEVLOG, do not
  implement it here.
- Do NOT modify `effectiveDateRange` or `activeDays`. The full week/month grid is intentional for
  the area chart (avoids a stub chart mid-month); clamping it would change the chart and other
  metrics.
- Do NOT touch BAC, guideline-limit, or sync logic (none involved; those require explicit owner
  approval per CLAUDE.md).
- No new SwiftData schema change, no migration (no model shape change).
</non_goals>

<verification>
- Month view, current month, no events: Longest Streak == elapsed days of the month (today's
  day-of-month), not the full month length.
- Month view with an early-month drinking day: streak ends at today, never runs into future days.
- Past month / Year / All-Time: values identical before and after the fix (regression-safe).
- `xcodebuild build` clean (zero warnings); `xcodebuild test` green (unit + UI); no file > 300 lines.
</verification>

<success_criteria>
- The Insights Month view "Longest Streak" card counts only days up to and including today.
- Deterministic unit regression tests pin the month behaviour (18-of-31 empty case; early
  drinking-day case) and the elapsed-day invariant for the week case.
- A UI test drives the real Month view and asserts the displayed streak equals the elapsed-only
  expected value.
- All CLAUDE.md end-of-task gates pass and DEVLOG.md records the fix.
</success_criteria>

<output>
Create `.planning/quick/260718-kgp-fix-bug-insights-month-view-longest-stre/260718-kgp-SUMMARY.md` when done.
</output>
