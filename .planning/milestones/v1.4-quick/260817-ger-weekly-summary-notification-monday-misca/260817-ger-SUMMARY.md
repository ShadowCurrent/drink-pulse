---
phase: quick-260817-ger
plan: 01
subsystem: notifications
tags: [swiftdata, usernotifications, swift-testing, weekly-summary]

# Dependency graph
requires: []
provides:
  - "WeeklySummaryService.scheduleIfEnabled(context:) compares last week (offset -1) vs. the week before last (offset -2), never the in-progress current week (offset 0)"
  - "Regression test pinning the corrected comparison, plus four pre-existing scheduleIfEnabled tests re-anchored to the corrected offsets"
affects: [weekly-summary, notifications, insights]

# Actuals (#2632)
actuals:
  tokens: 6899
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Split an over-300-line Swift-Testing test file by MARK section into two sibling files, each declaring its own private helpers (matches the codebase's existing per-struct helper convention, no shared-extension indirection needed)."

key-files:
  created:
    - drinkpulseTests/Services/WeeklySummaryServiceScheduleTests.swift
  modified:
    - drinkpulse/Services/WeeklySummaryService.swift
    - drinkpulse/Domain/WeeklySummaryCalculator.swift
    - drinkpulseTests/Services/WeeklySummaryServiceTests.swift
    - docs/DEVLOG.md

key-decisions:
  - "Fix is scoped entirely to which InsightsPeriod.week offsets scheduleIfEnabled passes into WeeklySummaryCalculator.content — the calculator's own percentage/direction/skip logic needed no behavioral change."
  - "Split WeeklySummaryServiceTests.swift into two files after the new regression test pushed it to 337 lines (over CLAUDE.md's 300-line ceiling) — scheduleIfEnabled tests moved to a new WeeklySummaryServiceScheduleTests.swift sibling file."

patterns-established: []

requirements-completed:
  - ENGG-03
  - ENGG-04

coverage:
  - id: D1
    description: "scheduleIfEnabled(context:) compares last week's pureAlcoholGrams total (offset -1) against the week-before-last's total (offset -2), never the in-progress current week (offset 0)."
    requirement: "ENGG-03"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceScheduleTests.swift#scheduleIfEnabled_comparesLastWeekVsWeekBefore_ignoringInProgressCurrentWeek"
        status: pass
    human_judgment: false
  - id: D2
    description: "A ConsumptionEvent logged in the in-progress current week has zero influence on the scheduled notification's body text."
    requirement: "ENGG-04"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceScheduleTests.swift#scheduleIfEnabled_comparesLastWeekVsWeekBefore_ignoringInProgressCurrentWeek"
        status: pass
    human_judgment: false
  - id: D3
    description: "All four pre-existing scheduleIfEnabled tests re-anchored to offset -1/-2 (and -3 for the zero-ABV test's older event) still pass, validating genuine last-week-vs-week-before-last behavior."
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceScheduleTests.swift (scheduleIfEnabled_doesNothing_whenDisabled, scheduleIfEnabled_cancelsPending_whenNoPriorWeekDataAtAll, scheduleIfEnabled_schedulesPercentageContent_usingPhysicalDensity_notModeDensity, scheduleIfEnabled_directionOnly_whenPriorWeekHasOnlyZeroAbvEvent, scheduleIfEnabled_isIdempotent_leavesOnePendingRequest, scheduleIfEnabled_swallowsSchedulingError_withoutThrowing)"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-08-17
status: complete
---

# Quick Task 260817-ger: Fix Monday weekly-summary notification week-comparison bug Summary

**Corrected `WeeklySummaryService.scheduleIfEnabled` to compare last week vs. the week before last (offset -1/-2) instead of the still-in-progress current week vs. last week (offset 0/-1), pinned by a new regression test.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-08-17T09:56:21Z
- **Completed:** 2026-08-17T10:03:46Z
- **Tasks:** 2
- **Files modified:** 5 (4 planned + 1 new test file from the file-size split)

## Accomplishments
- Fixed the off-by-one-week anchoring bug: `scheduleIfEnabled(context:)` now fetches `InsightsPeriod.week.dateRange(offset: -1, ...)` (last week) and `offset: -2` (week before last) instead of `offset: 0` (in-progress current week) and `offset: -1`.
- Corrected the `hasAnyPriorWeekData` boundary to `lastWeekRange.lowerBound` so the ENGG-06 first-ever-week skip check stays semantically correct automatically.
- Corrected the stale `currentWeekGrams` doc-comment on `WeeklySummaryCalculator.content` that previously (and now incorrectly) documented the production caller as passing the in-progress week.
- Added a regression test (`scheduleIfEnabled_comparesLastWeekVsWeekBefore_ignoringInProgressCurrentWeek`) that seeds a deliberately huge offset-0 outlier event and proves it has zero influence on the notification body — RED against the pre-fix code (asserted "2400% more" instead of the correct "100% more"), GREEN after the fix.
- Re-anchored all four pre-existing `scheduleIfEnabled` tests from `offset: 0`/`-1` (and one `-2`) to `offset: -1`/`-2` (and `-3`), so they now validate genuine last-week-vs-week-before-last behavior instead of mirroring the old bug.
- Appended a dated `docs/DEVLOG.md` entry describing the bug, root cause, fix, and regression coverage.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add failing regression test proving in-progress current-week data leaks into the notification** - `0e166e9` (test)
2. **Task 2: Fix the offset bug, re-anchor existing tests, and record the fix** - `953c39f` (fix)

_TDD task: RED (`0e166e9`) → GREEN (`953c39f`), both gate commits present in git log._

## Files Created/Modified
- `drinkpulse/Services/WeeklySummaryService.swift` - `scheduleIfEnabled(context:)` offsets corrected -1/-2 (were 0/-1); locals renamed `lastWeekRange`/`weekBeforeLastRange`/`lastWeekGrams`/`weekBeforeLastGrams`; `hasAnyPriorWeekData` boundary corrected; doc-comments updated.
- `drinkpulse/Domain/WeeklySummaryCalculator.swift` - `currentWeekGrams` doc-comment corrected to state the production caller always passes a fully-elapsed week, never the in-progress current week.
- `drinkpulseTests/Services/WeeklySummaryServiceTests.swift` - trimmed to `makeRequest`/`cancel`/`requestAuthorization`/laziness-contract tests only (138 lines); `scheduleIfEnabled` coverage moved out.
- `drinkpulseTests/Services/WeeklySummaryServiceScheduleTests.swift` - new file: all seven `scheduleIfEnabled` tests (six re-anchored + one new regression test), 223 lines.
- `docs/DEVLOG.md` - appended dated entry describing the bug and fix.

## Decisions Made
- Kept the fix strictly to the two `offset:` arguments `scheduleIfEnabled` passes into `WeeklySummaryCalculator.content` — the calculator's own percentage/direction/skip comparison logic was already correct and needed no change, matching the plan's stated key-link.
- Split the test file along its existing `// MARK:` boundaries (`scheduleIfEnabled` vs. everything else) rather than introducing a shared test-helper extension, matching the codebase's existing per-struct-declares-its-own-helpers convention (no precedent for cross-file shared test helpers was found in `drinkpulseTests`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 / CLAUDE.md file-size enforcement] Split `WeeklySummaryServiceTests.swift` after it exceeded the 300-line ceiling**
- **Found during:** Task 2, after adding the Task 1 regression test and re-anchoring the four existing `scheduleIfEnabled` tests, the file reached 337 lines — over CLAUDE.md's hard 300-line ceiling ("Files over 300 lines must be split before declaring a task done").
- **Issue:** The plan's `files_modified` list only named the single existing test file; it did not anticipate the new regression test pushing it over the limit.
- **Fix:** Moved all seven `scheduleIfEnabled` tests (including the new regression test) into a new sibling file `WeeklySummaryServiceScheduleTests.swift` (223 lines), leaving `WeeklySummaryServiceTests.swift` at 138 lines with `makeRequest`/`cancel`/`requestAuthorization`/laziness-contract coverage. Each file declares its own private `makeDefaults()`/`makeContainer()` helpers, matching the existing `ReminderServiceTests.swift` per-struct-helper convention (no shared cross-file test-helper pattern exists in the codebase to reuse).
- **Files modified:** `drinkpulseTests/Services/WeeklySummaryServiceTests.swift`, `drinkpulseTests/Services/WeeklySummaryServiceScheduleTests.swift` (new)
- **Verification:** `find drinkpulseTests -name "*.swift" | xargs wc -l | awk '$1 > 300'` shows neither new/modified file over the ceiling; scoped `xcodebuild test` run (`WeeklySummaryServiceTests`, `WeeklySummaryServiceScheduleTests`, `WeeklySummaryCalculatorTests`) passes 27/27.
- **Committed in:** `953c39f` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 CLAUDE.md file-size enforcement)
**Impact on plan:** Purely a file-organization split required by an existing project constraint; no behavioral change, no scope creep. All planned test content is preserved, just relocated.

## Issues Encountered
- `xcodebuild test` intermittently failed on the first scoped run after the split with `Simulator device failed to launch ... Busy ("Application failed preflight checks")` — a transient simulator/XPC issue, not a code problem. Resolved by `xcrun simctl shutdown all` and retrying; the retry succeeded cleanly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The Monday weekly-summary notification now correctly reports last-week-vs-week-before-last, matching ENGG-03/04's intent — the feature's core value proposition is no longer defeated by an off-by-one-week bug.
- `WeeklySummaryCalculatorTests.swift` was left unchanged (as the plan anticipated) since it only exercises pure-number comparison logic with no date-range involvement.
- No blockers for future work in this area.

---
*Phase: quick-260817-ger*
*Completed: 2026-08-17*
