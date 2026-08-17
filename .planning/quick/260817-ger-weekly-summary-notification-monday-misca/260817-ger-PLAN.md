---
phase: quick-260817-ger
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - drinkpulse/Services/WeeklySummaryService.swift
  - drinkpulse/Domain/WeeklySummaryCalculator.swift
  - drinkpulseTests/Services/WeeklySummaryServiceTests.swift
  - docs/DEVLOG.md
autonomous: true
requirements:
  - ENGG-03
  - ENGG-04
user_setup: []

must_haves:
  truths:
    - "WeeklySummaryService.scheduleIfEnabled(context:) compares last week's pureAlcoholGrams total (InsightsPeriod.week offset -1) against the week-before-last's total (offset -2) — never the still-in-progress current week (offset 0), which the Monday-morning notification cannot meaningfully report on."
    - "A ConsumptionEvent logged in the in-progress current week (offset 0) has zero influence on the scheduled notification's body text — proven by a regression test that seeds a large offset-0 event alongside real offset -1/-2 events and asserts the resulting body matches the content computed from offset -1/-2 alone."
    - "Every pre-existing WeeklySummaryServiceTests scheduleIfEnabled test still passes, re-anchored to the corrected offsets (-1/-2 instead of 0/-1) so they assert genuine last-week-vs-week-before behavior rather than mirroring the old bug."
  artifacts:
    - "drinkpulse/Services/WeeklySummaryService.swift — scheduleIfEnabled(context:) fetches lastWeekRange = InsightsPeriod.week.dateRange(offset: -1, ...) and weekBeforeLastRange = InsightsPeriod.week.dateRange(offset: -2, ...); hasAnyPriorWeekData checks hasEvents(before: lastWeekRange.lowerBound)."
    - "drinkpulse/Domain/WeeklySummaryCalculator.swift — currentWeekGrams doc-comment corrected to state the production caller always passes a fully-elapsed week (last week), never the in-progress current week."
    - "drinkpulseTests/Services/WeeklySummaryServiceTests.swift — new regression test proving in-progress current-week data is excluded, plus the four existing scheduleIfEnabled tests re-anchored to offset -1/-2."
  key_links:
    - "WeeklySummaryService.scheduleIfEnabled(context:) is the sole production caller of WeeklySummaryCalculator.content(currentWeekGrams:priorWeekGrams:hasAnyPriorWeekData:) — fixing the two InsightsPeriod.week.dateRange(offset:) arguments passed into it is the entire fix; WeeklySummaryCalculator's own comparison logic (percentage/direction/skip rules) is correct and untouched."
    - "The corrected lastWeekRange.lowerBound value is reused unchanged as the hasEvents(before:) boundary for ENGG-06's first-ever-week skip check — its semantics ('was there any history before the week being summarized') stay correct automatically once lastWeekRange itself points at the right week."
---

<objective>
Fix the Monday weekly-summary notification's week-over-week alcohol comparison, which currently
compares the wrong pair of weeks.

**Root cause (found during planning):** `WeeklySummaryService.scheduleIfEnabled(context:)`
(`drinkpulse/Services/WeeklySummaryService.swift:95-98`) calls
`InsightsPeriod.week.dateRange(offset: 0, now: now, calendar: calendar)` for what it labels
`currentRange`, and `offset: -1` for `priorRange`. `offset: 0` is the **still-in-progress calendar
week containing `now`** (per `InsightsPeriod.dateRange`'s own doc: "how many periods `date` is
behind `now`", `Features/Insights/InsightsPeriod.swift:40-51`) — it deliberately mirrors
`InsightsViewModel.trendFraction`'s live "This Week" semantics (see the doc-comment on
`WeeklySummaryCalculator.content`'s `currentWeekGrams` parameter, `Domain/WeeklySummaryCalculator.swift:37-42`,
which explicitly documents this as the current behavior). That live "This Week" semantics is correct
for the Insights screen's real-time indicator, but wrong for this notification: ENGG-03 requires the
notification to fire "on the first day of the new week" and ENGG-04 requires its body to state "%
higher/lower than **last week**" — a fully-elapsed week, not whatever is logged so far in the week
that just started (which, at 9am Monday, is close to empty). The result: the notification actually
computes and reports "week-in-progress vs. last week" instead of "last week vs. the week before" — an
off-by-one-week anchoring bug that is worst right around the Monday-morning fire time itself (when the
in-progress week has almost no data), producing a spuriously large "down" swing, and remains wrong at
any other reschedule time too (whichever calendar week happened to contain `now` at the last app
foreground gets misreported as "last week").

**Fix:** Change the two `InsightsPeriod.week.dateRange(offset:...)` calls in `scheduleIfEnabled` from
`offset: 0` / `offset: -1` to `offset: -1` / `offset: -2`, so the comparison is always between the two
most recently fully-elapsed weeks — never the in-progress one. `WeeklySummaryCalculator`'s own
percentage/direction/skip logic (`Domain/WeeklySummaryCalculator.swift`) is correct today and needs no
behavioral change, only a doc-comment correction describing what its caller actually passes.

Purpose: The Monday weekly-summary notification currently misreports how the user's drinking changed
week-over-week — this is the feature's entire value proposition, so the miscalculation defeats the
feature.
Output: Corrected `WeeklySummaryService.scheduleIfEnabled(context:)`, a corrected doc-comment in
`WeeklySummaryCalculator.swift`, a new regression test pinning the fix, four existing tests re-anchored
to the correct offsets, and a DEVLOG entry.
</objective>

<execution_context>
@/Users/fempter/.claude/gsd-core/workflows/execute-plan.md
</execution_context>

<context>
@./CLAUDE.md
@drinkpulse/Services/WeeklySummaryService.swift
@drinkpulse/Domain/WeeklySummaryCalculator.swift
@drinkpulse/Features/Insights/InsightsPeriod.swift
@drinkpulseTests/Services/WeeklySummaryServiceTests.swift

# Key facts already verified during planning:
# - `InsightsPeriod.week.dateRange(offset:now:calendar:)` (Features/Insights/InsightsPeriod.swift:40-51)
#   is correct and untouched by this fix: offset 0 = the calendar week containing `now`, offset -1 =
#   the week before that, offset -2 = two weeks before that. The bug is purely in WHICH offsets
#   `WeeklySummaryService.scheduleIfEnabled` passes, not in `InsightsPeriod` itself.
# - `WeeklySummaryCalculator.content(currentWeekGrams:priorWeekGrams:hasAnyPriorWeekData:)`
#   (Domain/WeeklySummaryCalculator.swift:48-66) is correct and untouched: it just compares two grams
#   totals by generic name, with no calendar awareness of its own. `WeeklySummaryCalculatorTests.swift`
#   needs NO changes — it only tests this pure-number comparison logic, never date ranges.
# - `hasEvents(in:before:)` (WeeklySummaryService.swift:143-149) is correct and untouched: it is a
#   generic "any ConsumptionEvent before this Date" check. Only the Date passed to it changes (from
#   the old currentRange.lowerBound to the new lastWeekRange.lowerBound), which happens automatically
#   once the range variable itself is corrected.
# - `WeeklySummaryService.makeRequest(calendar:content:)` (lines 61-80) and `bodyText(for:)` (lines
#   155-184) are correct and untouched — they only format an already-classified `WeeklySummaryContent`,
#   with no date-range logic of their own.
# - The 4 existing `scheduleIfEnabled` tests in `WeeklySummaryServiceTests.swift` that build
#   `currentRange`/`priorRange` local variables using `offset: 0`/`offset: -1` to seed fixture events
#   are currently PASSING only because they mirror the production bug's own offsets, not because they
#   validate real last-week-vs-week-before semantics. They must be re-anchored to `offset: -1`/`offset:
#   -2` as part of the fix, or they will fail against the corrected production code.
</context>

<tasks>

<task type="tdd" tdd="true">
  <name>Task 1: Add failing regression test proving in-progress current-week data leaks into the notification</name>
  <files>drinkpulseTests/Services/WeeklySummaryServiceTests.swift</files>
  <behavior>
    - Seed three `ConsumptionEvent`s: one in the week-before-last (`InsightsPeriod.week.dateRange(offset:
      -2, now: now, calendar: calendar)`), one in last week (`offset: -1`), and one in the
      still-in-progress current week (`offset: 0`) with a much larger `quantity` than the other two (so
      it would dominate the computed percentage if it were incorrectly included).
    - Compute `expectedContent` via `WeeklySummaryCalculator.content(currentWeekGrams:priorWeekGrams:hasAnyPriorWeekData:)`
      using ONLY the offset -1 event's `pureAlcoholGrams` as `currentWeekGrams` and ONLY the offset -2
      event's `pureAlcoholGrams` as `priorWeekGrams` (mirrors the assertion style already used by
      `scheduleIfEnabled_schedulesPercentageContent_usingPhysicalDensity_notModeDensity`).
    - Call `service.scheduleIfEnabled(context:)`, then assert `fake.addedRequests.first?.content.body`
      equals `service.makeRequest(calendar: calendar, content: expectedContent)!.content.body`.
    - This test MUST fail against the current, unmodified production code — because the current code
      computes `currentWeekGrams` from the offset-0 event (the dominant one) instead of the offset-1
      event, so the actual body will not match `expectedContent`'s body.
  </behavior>
  <action>
    In `drinkpulseTests/Services/WeeklySummaryServiceTests.swift`, inside the `// MARK: - scheduleIfEnabled`
    section (after `scheduleIfEnabled_swallowsSchedulingError_withoutThrowing`, before `// MARK: -
    laziness contract`), add a new `@Test func scheduleIfEnabled_comparesLastWeekVsWeekBefore_ignoringInProgressCurrentWeek()
    async throws`. Follow the exact setup shape of
    `scheduleIfEnabled_schedulesPercentageContent_usingPhysicalDensity_notModeDensity` (fake center,
    isolated `UserDefaults`, in-memory `ModelContainer`, `defaults.set(true, forKey:
    AppStorageKeys.weeklySummaryEnabled)`). Build three date ranges from `Calendar.current` / `Date.now`:
    `weekBeforeLastRange` (`offset: -2`), `lastWeekRange` (`offset: -1`), and `inProgressRange` (`offset:
    0`). Declare `let weekBeforeLastEvent = ConsumptionEvent(consumptionDate: weekBeforeLastRange.lowerBound,
    volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")` (quantity defaults to 1), `let lastWeekEvent =
    ConsumptionEvent(consumptionDate: lastWeekRange.lowerBound, volumeMl: 500, abv: 0.05, quantity: 2,
    category: .beer, icon: "🍺")` (double the grams, giving a clean ~100% "up" comparison against
    `weekBeforeLastEvent`), and `let inProgressEvent = ConsumptionEvent(consumptionDate:
    inProgressRange.lowerBound, volumeMl: 500, abv: 0.05, quantity: 50, category: .beer, icon: "🍺")` (a
    deliberately huge outlier that must NOT influence the result) — `context.insert(...)` all three.
    Compute `expectedContent` from `WeeklySummaryCalculator.content(currentWeekGrams:
    lastWeekEvent.pureAlcoholGrams, priorWeekGrams: weekBeforeLastEvent.pureAlcoholGrams,
    hasAnyPriorWeekData: true)` and `expectedRequest = service.makeRequest(calendar: calendar, content:
    expectedContent)!`. Call `await service.scheduleIfEnabled(context: context)`, then `#expect(fake.addedRequests.first?.content.body
    == expectedRequest.content.body)`.
  </action>
  <verify>
    <automated>xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests/WeeklySummaryServiceTests/scheduleIfEnabled_comparesLastWeekVsWeekBefore_ignoringInProgressCurrentWeek 2>&1 | tail -40</automated>
  </verify>
  <done>
    The new `scheduleIfEnabled_comparesLastWeekVsWeekBefore_ignoringInProgressCurrentWeek` test compiles
    and runs, and FAILS against the current unmodified production code — the assertion
    `fake.addedRequests.first?.content.body == expectedRequest.content.body` does not hold, because
    production `scheduleIfEnabled` currently derives `currentWeekGrams` from the huge offset-0 outlier
    event instead of the offset-1 ("last week") event. This failure is the proof the bug is real and
    reproducible; do not proceed to Task 2 until this failure is observed.
  </done>
</task>

<task type="auto">
  <name>Task 2: Fix the offset bug, re-anchor existing tests, and record the fix</name>
  <files>drinkpulse/Services/WeeklySummaryService.swift, drinkpulse/Domain/WeeklySummaryCalculator.swift, drinkpulseTests/Services/WeeklySummaryServiceTests.swift, docs/DEVLOG.md</files>
  <action>
    In `drinkpulse/Services/WeeklySummaryService.swift`'s `scheduleIfEnabled(context:)` (lines 92-118),
    rename the `currentRange`/`priorRange` locals to `lastWeekRange`/`weekBeforeLastRange` and change
    their `InsightsPeriod.week.dateRange(offset:...)` arguments from `0`/`-1` to `-1`/`-2` respectively;
    rename the derived `currentGrams`/`priorGrams` locals to `lastWeekGrams`/`weekBeforeLastGrams` and
    update their `fetchEvents(in:from:to:)` calls to read from `lastWeekRange`/`weekBeforeLastRange`;
    change `hasAnyPriorWeekData`'s `hasEvents(in:before:)` call to pass `lastWeekRange.lowerBound` (was
    `currentRange.lowerBound`); update the `WeeklySummaryCalculator.content(currentWeekGrams:priorWeekGrams:hasAnyPriorWeekData:)`
    call to pass `lastWeekGrams`/`weekBeforeLastGrams` for the first two arguments (the calculator's
    parameter labels stay `currentWeekGrams`/`priorWeekGrams` — only the local variable names and the
    values they hold change). Add a one-line comment above the two range declarations citing ENGG-03/04:
    the two windows being compared are always the two most recently fully-elapsed weeks, never the
    in-progress current week — a partial week would make the reported percentage meaningless at exactly
    the moment (Monday morning) the notification fires. Also correct the doc-comment on
    `scheduleIfEnabled` itself (lines 87-91) if its "current/prior-week" wording implies the in-progress
    week is used.

    In `drinkpulse/Domain/WeeklySummaryCalculator.swift`, correct the `currentWeekGrams` parameter
    doc-comment (lines 37-42): remove the claim that the production caller "passes the in-progress
    calendar week, mirroring InsightsViewModel.trendFraction's live 'This Week' semantics" — replace with
    a note that, despite the generic parameter name, the production caller
    (`WeeklySummaryService.scheduleIfEnabled`) always passes a fully-elapsed week (last week, relative to
    the Monday-morning fire time per ENGG-03/04), never the in-progress current week, since a partial
    week would make the reported comparison meaningless. Leave the rest of the doc-comment (the
    `priorWeekGrams`/`hasAnyPriorWeekData` descriptions, and the "Strict, no epsilon" inline comment at
    lines 55-56) unchanged — they remain accurate.

    In `drinkpulseTests/Services/WeeklySummaryServiceTests.swift`, re-anchor the four existing
    `scheduleIfEnabled` tests that build `currentRange`/`priorRange` local variables from
    `InsightsPeriod.week.dateRange(offset: 0, ...)` / `offset: -1, ...`:
    `scheduleIfEnabled_schedulesPercentageContent_usingPhysicalDensity_notModeDensity` (lines ~168-169),
    `scheduleIfEnabled_directionOnly_whenPriorWeekHasOnlyZeroAbvEvent` (lines ~205-207, which also has a
    `beforePriorRange` at `offset: -2` that must become `offset: -3`),
    `scheduleIfEnabled_isIdempotent_leavesOnePendingRequest` (lines ~238-239), and
    `scheduleIfEnabled_swallowsSchedulingError_withoutThrowing` (lines ~266-267). In each, shift every
    offset down by exactly one: `offset: 0` becomes `offset: -1`, `offset: -1` becomes `offset: -2`, and
    (in the zero-ABV test only) `offset: -2` becomes `offset: -3`. Do not change the variable names,
    quantities, ABVs, or assertions in these four tests — only the `offset:` arguments, so each test
    keeps validating the exact same relative-week relationship, now correctly anchored to
    last-week/week-before-last instead of current-week/last-week. Do not modify
    `WeeklySummaryCalculatorTests.swift` — it tests pure number comparisons with no date-range
    involvement and needs no change.

    Append one new dated entry to `docs/DEVLOG.md` (English, append-only — never edit existing entries,
    matching the file's established `## YYYY-MM-DD HH:MM — Title` format) describing: the bug (Monday
    weekly-summary notification compared the in-progress current week against last week instead of last
    week against the week before, due to `scheduleIfEnabled` passing `InsightsPeriod.week.dateRange`
    offsets `0`/`-1` instead of `-1`/`-2`), how it was found (quick-task investigation triggered by a
    live user report), the fix (offsets corrected to `-1`/`-2`, doc-comments corrected in both files),
    and the regression coverage (the new
    `scheduleIfEnabled_comparesLastWeekVsWeekBefore_ignoringInProgressCurrentWeek` test plus the four
    existing `scheduleIfEnabled` tests re-anchored to the corrected offsets).
  </action>
  <verify>
    <automated>xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests/WeeklySummaryServiceTests -only-testing:drinkpulseTests/WeeklySummaryCalculatorTests 2>&1 | tail -60</automated>
  </verify>
  <done>
    All `WeeklySummaryServiceTests` tests pass, including the new
    `scheduleIfEnabled_comparesLastWeekVsWeekBefore_ignoringInProgressCurrentWeek` regression test from
    Task 1 (now GREEN) and the four re-anchored `scheduleIfEnabled` tests; all `WeeklySummaryCalculatorTests`
    tests still pass unmodified; `WeeklySummaryService.swift` and `WeeklySummaryCalculator.swift` compile
    with zero warnings; neither file exceeds 300 lines; `docs/DEVLOG.md` has one new dated entry
    describing the bug and fix.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| None new | This fix only changes which local, already-trusted `ConsumptionEvent` rows (device-local SwiftData, no new input surface) get summed into an existing notification body; no new external input, dependency, or trust boundary is introduced. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|------------------|
| T-quick260817ger-01 | Information Disclosure | WeeklySummaryService.scheduleIfEnabled | low | accept | Notification body still only ever interpolates a rounded whole-percent magnitude (never raw grams, dates, or event content) per the existing `bodyText(for:)` contract — unchanged by this fix; no new logging or PII surface introduced. |

</threat_model>

<verification>
- New regression test `scheduleIfEnabled_comparesLastWeekVsWeekBefore_ignoringInProgressCurrentWeek`
  fails against the pre-fix code (Task 1) and passes against the post-fix code (Task 2).
- All four pre-existing `scheduleIfEnabled` tests pass, re-anchored to `offset: -1`/`-2`.
- `WeeklySummaryCalculatorTests.swift` unchanged and still green (pure-number logic untouched).
- `xcodebuild build` clean (zero warnings); no Swift file over 300 lines.
- `docs/DEVLOG.md` records the bug and fix.
</verification>

<success_criteria>
- The Monday weekly-summary notification's week-over-week comparison always uses the two most recently
  fully-elapsed weeks (last week vs. the week before), never the in-progress current week.
- `WeeklySummaryCalculator`'s comparison logic is unchanged — the fix is entirely in which date ranges
  `WeeklySummaryService.scheduleIfEnabled` feeds it.
- The regression is pinned by an automated test that would fail if the offset bug reappeared.
- Build clean, no file > 300 lines, DEVLOG updated.
</success_criteria>

<output>
Create `.planning/quick/260817-ger-weekly-summary-notification-monday-misca/260817-ger-SUMMARY.md` when done.
</output>
