---
phase: quick-260718-vgy
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - drinkpulse/Features/Insights/InsightsViewModel+HealthMetrics.swift
  - drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift
  - drinkpulseUITests/Features/Insights/InsightsDrinkFreeDaysUITests.swift
  - docs/DEVLOG.md
autonomous: true
requirements:
  - BUGFIX-insights-drinkfreedays-future-days
user_setup: []

must_haves:
  truths:
    - "On the Insights Month and Week views, the Drink-Free Days card 'X/Y' counts only days up to and including today — future (not-yet-elapsed) days are never counted in either the numerator (free) or the denominator (total)."
    - "Past months/weeks (offset < 0) and Year / All-Time scopes are unaffected: their drink-free-days values are identical before and after the fix."
    - "The fix is isolated to the drinkFreeDays metric; longestSoberStreak, totals, calories, binge days, and heaviest day behaviour are unchanged; effectiveDateRange and activeDays are untouched."
  artifacts:
    - "drinkpulse/Features/Insights/InsightsViewModel+HealthMetrics.swift (drinkFreeDays reads elapsedDays for both count and total)"
    - "drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift (drinkFreeDays month regression tests + updated week tests)"
    - "drinkpulseUITests/Features/Insights/InsightsDrinkFreeDaysUITests.swift (Month-view drink-free-days UI test)"
    - "docs/DEVLOG.md (fix entry, follow-up to quick-260718-kgp)"
  key_links:
    - "InsightsViewModel+HealthMetrics.drinkFreeDays iterates elapsedDays (not activeDays) for both `free` and `total`"
    - "elapsedDays already filters activeDays to days <= startOfDay(now) (added by quick-260718-kgp); this plan reuses it, adds no new property"
---

<objective>
Fix the Insights "Drink-Free Days" card so its "X/Y" value stops counting future days in the
current month/week.

Bug: In the Insights tab, Month (and Week) period, the "Drink-Free Days" metric computes both
the count (drink-free days) and the total (denominator) over the whole calendar grid — including
days after today that haven't happened yet. Because future days carry zero grams, they read as
"drink-free" and inflate both the numerator and the denominator (e.g. on July 18 the current
month shows "X/31" instead of "X/18", counting the empty rest-of-month tail).

Root cause (identical to the already-fixed Longest Streak bug, quick-260718-kgp):
`InsightsViewModel.effectiveDateRange` deliberately keeps the full calendar grid for
`.week`/`.month` (so the area chart isn't a stub mid-period). Every per-day metric reads
`activeDays`, built from that full range. `drinkFreeDays` (in
`InsightsViewModel+HealthMetrics.swift`) therefore iterates future days for both `total` and
`free`. This latent bug was explicitly flagged as out-of-scope in the quick-260718-kgp DEVLOG
entry — this plan is that follow-up.

Fix: point `drinkFreeDays` at the existing `elapsedDays` window (`activeDays` clamped to
`<= today`, added in quick-260718-kgp) instead of `activeDays`. This is a no-op for past periods
and for Year/All-Time (already clamped to `now` via `effectiveDateRange`), and correctly excludes
future days for the current week and month. No new property is added; `longestSoberStreak`,
`effectiveDateRange`, and `activeDays` are not touched.

Purpose: A drink-free count/total that includes not-yet-elapsed days misleads the user about
their current progress and shows a wrong denominator on the card.
Output: Corrected metric, deterministic unit regression tests, one UI test on the Month view, a
DEVLOG entry, and the CLAUDE.md end-of-task gates.
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
@drinkpulseUITests/Features/Insights/InsightsStreakUITests.swift
@drinkpulse/UITestSeed+Fixtures.swift

# Key facts already verified during planning:
# - `elapsedDays` ALREADY EXISTS on InsightsViewModel (InsightsViewModel.swift, added by
#   quick-260718-kgp): `activeDays.filter { $0 <= cal.startOfDay(for: now) }`. Reuse it as-is;
#   do NOT add a second clamped-days property.
# - Current drinkFreeDays (InsightsViewModel+HealthMetrics.swift): `total = activeDays.count`,
#   `free = activeDays.filter { gramsForNormalizedDay($0) == 0 }.count`. Both must become
#   `elapsedDays`.
# - effectiveDateRange clamps .year/.allTime to `now` but returns the full grid for .week/.month;
#   this is intentional for the chart and MUST NOT change.
# - `now` is an injectable stored property on InsightsViewModel (tests set vm.now).
# - The card renders via MetricCell with combined a11y label "Drink-Free Days: X/Y" (explicit
#   .accessibilityLabel("\(title): \(value)") where value is "\(count)/\(total)"). English title
#   from Localizable key insights.metric.drinkFreeDays = "Drink-Free Days". The percentage
#   subtitle is NOT part of the a11y label (accessibilityLabel is set explicitly), so the label
#   is exactly "Drink-Free Days: X/Y".
# - Existing test helpers (InsightsViewModelTests.swift): makeVM(), makeContainer(),
#   event(daysAgo:hoursOffset:grams:price:relativeTo:in:). makeVM() uses .grams (density 0.789).
# - The multiday UI seed (-dp_uitest_dataset multiday) logs drinks at days-ago offsets
#   {0,1,2,4,6,7,9,11,13} relative to launch day, all in the past/today, anchored to noon.
# - InsightsUITests.swift is ~263 lines and InsightsStreakUITests.swift (~108 lines) already
#   exists (kgp split the streak UI test out). The UITests folder is a
#   PBXFileSystemSynchronizedRootGroup — a new .swift file is auto-included, no project.pbxproj
#   edit needed.
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Point drinkFreeDays at the elapsedDays window + unit regression tests</name>
  <files>drinkpulse/Features/Insights/InsightsViewModel+HealthMetrics.swift, drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift</files>
  <behavior>
    Write/adjust these tests FIRST (the two new ones must fail against current code), in
    InsightsViewModelTests+Aggregates.swift under the existing "// MARK: - drinkFreeDays" section:

    - NEW `drinkFreeDays_monthExcludesFutureDays`: makeVM(), vm.events = [], vm.now pinned to
      DateComponents(year: 2026, month: 7, day: 18) via Calendar.current, vm.period = .month.
      Expect total == 18 (July has 31 days but only 18 have elapsed) and free == 18 (every elapsed
      day is drink-free). Pre-fix this returns total == 31, free == 31.
    - NEW `drinkFreeDays_monthWithDrinkingDay_countsElapsedOnly`: makeContainer() + makeVM(),
      vm.period = .month, vm.now pinned to 2026-07-18. Seed one drinking day on July 5 via
      event(daysAgo: 13, grams: 30, relativeTo: pinnedNow, in: context). Expect total == 18 and
      free == 17 (Jul 1–18 elapsed, one drinking day). Pre-fix returns total == 31, free == 30.
    - UPDATE the existing `drinkFreeDays_allFreeWhenNoEvents` test: it currently asserts
      `total == 7`, which encodes the buggy full-grid assumption and becomes flaky once future days
      are excluded (total only equals 7 on the last day of the week). Change the total assertion to
      `#expect(total == vm.elapsedDays.count)`; keep `#expect(free == total)`. Update its
      comment to describe the elapsed-day invariant (no events → every elapsed day of the current
      week is drink-free). Keep vm.now = .now, vm.period = .week.
    - UPDATE the existing `drinkFreeDays_oneDrinkingDay` test: change `#expect(total == 7)` to
      `#expect(total == vm.elapsedDays.count)` and `#expect(free == 6)` to
      `#expect(free == total - 1)` (today carries the one drinking day; every other elapsed day is
      free). Keep vm.now = .now, vm.period = .week, event(daysAgo: 0, grams: 30, ...).
  </behavior>
  <action>
    Then make the tests pass with a minimal, isolated change.

    In InsightsViewModel+HealthMetrics.swift, change `drinkFreeDays` to iterate `elapsedDays`
    instead of `activeDays` for BOTH the `total` (denominator) and the `free` (numerator) — i.e.
    `total = elapsedDays.count` and `free = elapsedDays.filter { gramsForNormalizedDay($0) == 0 }.count`.
    Update its head comment to note WHY (same reason as longestSoberStreak): activeDays keeps the
    full week/month grid for the chart, but the drink-free X/Y must not count days that have not
    happened yet — a future empty day is not a drink-free day, and it must not inflate the
    denominator either. No-op for past periods and for Year/All-Time (effectiveDateRange already
    clamps those to now).

    Reuse the existing `elapsedDays` computed property on InsightsViewModel as-is — do NOT add a
    new clamped-days property, and do NOT modify InsightsViewModel.swift, effectiveDateRange, or
    activeDays. Do NOT touch `longestSoberStreak` (already fixed), `bingeEpisodes`, `heaviestDay`,
    `periodTotalGrams`, or `periodCaloriesKcal`. Keep the diff to the drinkFreeDays path only.
  </action>
  <verify>
    <automated>xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests/InsightsViewModelTests 2>&1 | tail -30</automated>
  </verify>
  <done>
    The two new month tests and the two updated week tests pass; all pre-existing
    InsightsViewModelTests stay green. `drinkFreeDays` reads `elapsedDays` for both count and
    total. InsightsViewModel.swift, effectiveDateRange, activeDays, and longestSoberStreak are
    unchanged.
  </done>
</task>

<task type="auto">
  <name>Task 2: UI test — Month-view Drink-Free Days card excludes future days</name>
  <files>drinkpulseUITests/Features/Insights/InsightsDrinkFreeDaysUITests.swift</files>
  <action>
    Create a new XCUITest file `InsightsDrinkFreeDaysUITests.swift` (one concept per file, per
    CLAUDE.md — do NOT add this to InsightsUITests.swift, which is ~263 lines and would cross the
    300-line ceiling, nor to InsightsStreakUITests.swift). Mirror the structure of the sibling
    InsightsStreakUITests.swift: a @MainActor final class, continueAfterFailure = false, and copy
    the small private helpers it needs (launchApp() with the -dp_uitest_dataset multiday launch
    args, openInsights(), and firstElement(beginningWith:)). Locators key off the app's English
    a11y text only (the simulator system locale is Polish; the app's own strings are English-only,
    so asserting app-rendered text is locale-safe). Do NOT add a new seed dataset or a
    date-injection hook.

    Test `test_monthView_drinkFreeDays_excludesFutureDays`:
    1. launchApp() (passes -dp_uitest_dataset multiday), then openInsights().
    2. Tap the "Month" segment on the period segmented control (app.segmentedControls.firstMatch,
       buttons["Month"]), following the same pattern as InsightsStreakUITests.
    3. Locate the drink-free cell with firstElement(beginningWith: "Drink-Free Days"), wait for it,
       and read its .label. The label is exactly "Drink-Free Days: X/Y".
    4. Parse X (free) and Y (total) out of the label deterministically: split the label on "/" into
       two parts, then extract the run of digits from each part (the title "Drink-Free Days"
       contains no numerals, so the first part's digits are X and the second part's digits are Y).
       Assert both parse to non-nil Ints; fail with the raw label if not.
    5. In the test process, compute the expected elapsed-only (free, total) deterministically from
       the seed and today's date using Calendar.current, in a private static helper mirroring
       production `elapsedDays` + `drinkFreeDays`: today = startOfDay(now); monthStart = start of
       the current month's dateInterval; drinkingDays = the set of startOfDay(today - offset) for
       offset in {0,1,2,4,6,7,9,11,13}, keeping only those >= monthStart; then walk day-by-day from
       monthStart through today inclusive — increment total each day, and increment free when the
       day is NOT in drinkingDays.
    6. Assert parsed X == expected.free AND parsed Y == expected.total. Add a message explaining
       that a larger Y (denominator) means the (now-fixed) future-day counting has regressed, since
       pre-fix the card would include the empty rest-of-month tail in both numerator and
       denominator.

    FILE-SIZE GUARD: keep the new file well under 300 lines (it will be ~90–110 lines, like
    InsightsStreakUITests.swift). Run the file-size check in verify.
  </action>
  <verify>
    <automated>xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseUITests/InsightsDrinkFreeDaysUITests/test_monthView_drinkFreeDays_excludesFutureDays 2>&1 | tail -30 || xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseUITests 2>&1 | tail -30</automated>
  </verify>
  <done>
    The new UI test appears in the test log (it actually ran) and passes, asserting the Month-view
    "Drink-Free Days" X/Y matches the elapsed-only computation. No file exceeds 300 lines.
  </done>
</task>

<task type="auto">
  <name>Task 3: End-of-task gates + DEVLOG entry</name>
  <files>docs/DEVLOG.md</files>
  <action>
    Run the CLAUDE.md end-of-task checklist for this bug fix and record it:

    1. Build clean with zero warnings and the full test suite green (see verify). Fix any Swift 6
       strict-concurrency warnings at the source — never suppress.
    2. Coverage: confirm the changed view-model path stays at/above the ≥90% view-model target (the
       drinkFreeDays path is exercised by the Task 1 tests).
    3. File-size check: run the find command from CLAUDE.md and confirm no Swift file (excluding
       Preview Content) exceeds 300 lines.
    4. Privacy/logging: confirm no new network calls, no new logging of health data, no print in
       production (this change adds none).
    5. Living-docs audit: this is an isolated metric bugfix — grams-of-alcohol math is untouched,
       so architecture.md and domain.md calculation rules are unchanged; confirm nothing in the
       living docs now contradicts reality. No ADR needed (no architectural decision).
    6. Append a dated DEVLOG.md entry (English, append-only — never edit existing entries):
       date + time, the bug (Insights Month/Week "Drink-Free Days" X/Y counted future days in both
       numerator and denominator), the root cause (activeDays uses the full week/month grid;
       effectiveDateRange only clamps year/all-time), the fix (drinkFreeDays now iterates the
       existing elapsedDays window — reused from quick-260718-kgp, no new property), the tests
       added/updated, and an explicit note that this closes the follow-up flagged in the
       quick-260718-kgp DEVLOG entry (drinkFreeDays had the same latent full-grid behaviour).
  </action>
  <verify>
    <automated>xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20; find drinkpulse -name "*.swift" -not -path "*/Preview Content/*" | xargs wc -l | awk '$1 > 300 {print}'</automated>
  </verify>
  <done>
    xcodebuild build is warning-free, xcodebuild test is green (unit + UI), the find command
    reports no file over 300 lines, and DEVLOG.md has the new entry documenting the fix as the
    quick-260718-kgp follow-up.
  </done>
</task>

</tasks>

<non_goals>
- Do NOT add a new clamped-days property. Reuse the existing `elapsedDays` on InsightsViewModel
  (added by quick-260718-kgp). A second parallel property is explicitly forbidden by the task
  constraint.
- Do NOT modify InsightsViewModel.swift, `effectiveDateRange`, or `activeDays`. The full
  week/month grid is intentional for the area chart (avoids a stub chart mid-period); clamping it
  would change the chart and other metrics.
- Do NOT touch `longestSoberStreak` (already fixed in quick-260718-kgp), `bingeEpisodes`,
  `heaviestDay`, `periodTotalGrams`, or `periodCaloriesKcal`.
- Do NOT touch BAC, guideline-limit, or sync logic (none involved; those require explicit owner
  approval per CLAUDE.md).
- No new SwiftData schema change, no migration (no model shape change).
</non_goals>

<verification>
- Month view, current month, no events: Drink-Free Days total == elapsed days of the month
  (today's day-of-month), not the full month length; free == total.
- Month view with an early-month drinking day: total counts only elapsed days; free == total minus
  the elapsed drinking days; neither runs into future days.
- Week view: total == elapsedDays.count for the current week (not a hard 7 mid-week).
- Past month / Year / All-Time: values identical before and after the fix (regression-safe).
- `xcodebuild build` clean (zero warnings); `xcodebuild test` green (unit + UI); no file > 300 lines.
</verification>

<success_criteria>
- The Insights Month/Week "Drink-Free Days" card counts only days up to and including today in
  both the numerator (free) and the denominator (total).
- Deterministic unit regression tests pin the month behaviour (18-of-31 empty case; early
  drinking-day case) and the elapsed-day invariant for the two week cases.
- A UI test drives the real Month view and asserts the displayed X/Y equals the elapsed-only
  computation.
- All CLAUDE.md end-of-task gates pass and DEVLOG.md records the fix as the quick-260718-kgp
  follow-up.
</success_criteria>

<output>
Create `.planning/quick/260718-vgy-fix-bug-insights-month-week-view-drinkfr/260718-vgy-SUMMARY.md` when done.
</output>
</content>
</invoke>
