---
phase: 01-weekly-summary-notification
plan: 01
subsystem: domain
tags: [swift-testing, appstorage, localization, xcstrings, weekly-summary]

# Dependency graph
requires: []
provides:
  - "WeeklySummaryCalculator (pure, Sendable enum) classifying week-over-week content: .skip / .directionOnly / .percentage"
  - "AppStorageKeys.weeklySummaryEnabled and .pendingOpenInsights constants"
  - "All 13 localized strings this phase needs (Settings section, Onboarding toggle, notification body/title) in Localizable.xcstrings"
affects: [01-02, 01-03, 01-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "nonisolated enum for pure Domain types under the project's default-MainActor-isolation build setting (mirrors RiskLevel.swift)"
    - "Swift Testing struct with @Test/#expect, one file per Domain type"

key-files:
  created:
    - drinkpulse/Domain/WeeklySummaryCalculator.swift
    - drinkpulseTests/Domain/WeeklySummaryCalculatorTests.swift
  modified:
    - drinkpulse/DesignSystem/AppStorageKeys.swift
    - drinkpulse/Localizable.xcstrings

key-decisions:
  - "SignDirection/WeeklySummaryContent/WeeklySummaryCalculator declared `nonisolated` (not just Sendable) because the project's default-isolation=MainActor build setting otherwise makes their synthesized Equatable conformance MainActor-isolated, breaking non-isolated test call sites (matches existing RiskLevel.swift precedent)"
  - "Reused settings.reminder.openSettings key verbatim for the Settings denied-state action row instead of adding a duplicate string, per plan instruction"

patterns-established:
  - "Pure Domain classifier enums that will be called from a Service layer stay nonisolated + Sendable, with zero SwiftUI/SwiftData/UserNotifications imports"

requirements-completed: [ENGG-03, ENGG-04, ENGG-05, ENGG-06]

coverage:
  - id: D1
    description: "WeeklySummaryCalculator.content classifies skip (no prior week data, ENGG-06), directionOnly (prior week zero but real data exists, ENGG-05), and percentage (ENGG-04, including the +/-5% inclusive boundary and current-week-zero edge case) exactly as specified"
    requirement: "ENGG-03"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Domain/WeeklySummaryCalculatorTests.swift#9 @Test functions (content_skips_whenNoPriorWeekDataAtAll, content_directionOnlyUp_whenPriorWeekZero_currentWeekPositive, content_directionOnlySame_whenBothWeeksZero, content_percentageUp_wellAboveBand, content_percentageDown_wellBelowBand, content_percentageSame_atExactlyPositiveFivePercentBoundary, content_percentageSame_atExactlyNegativeFivePercentBoundary, content_percentageDown_whenCurrentWeekIsZero_priorWeekPositive, content_percentageUp_handlesLargeDelta_withoutOverflowOrCrash)"
        status: pass
    human_judgment: false
  - id: D2
    description: "AppStorageKeys gains weeklySummaryEnabled + pendingOpenInsights; Localizable.xcstrings gains all 13 new keys with exact copy, valid JSON, no duplicate Open-Settings string"
    requirement: "ENGG-03"
    verification:
      - kind: unit
        ref: "python3 -c \"import json; json.load(open('drinkpulse/Localizable.xcstrings'))\" (valid JSON) + key-presence assertion for all 13 keys"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-07-20
status: complete
---

# Phase 1 Plan 1: WeeklySummaryCalculator + AppStorageKeys + Localizable Strings Summary

**Pure, Foundation-only week-over-week content classifier (skip/directionOnly/percentage) plus the two AppStorage keys and all 13 Localizable.xcstrings entries the rest of the weekly-summary-notification phase needs.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-20T13:14:19Z
- **Completed:** 2026-07-20T13:22:29Z
- **Tasks:** 2
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments
- `WeeklySummaryCalculator.content(currentWeekGrams:priorWeekGrams:hasAnyPriorWeekData:)` implements the exact ENGG-03/04/05/06 branch logic, ported from `InsightsViewModel.trendFraction`'s strict `> 0` guard
- 9 Swift Testing cases cover every branch and both +/-5% boundaries (inclusive), the current-week-zero edge case, and a large-delta (599x) safety case
- `AppStorageKeys.weeklySummaryEnabled` / `.pendingOpenInsights` added, mirroring the existing reminder/health key conventions
- All 13 new `Localizable.xcstrings` keys added in alphabetical order (Settings section/toggle/hint/denied, Onboarding toggle/hint/denied, notification title + 5 body variants) — no other plan in this phase needs to touch the string catalog again

## Task Commits

Each task was committed atomically (TDD RED/GREEN for Task 1):

1. **Task 1a (RED): WeeklySummaryCalculatorTests** - `db61f16` (test)
2. **Task 1b (GREEN): WeeklySummaryCalculator** - `e238a1d` (feat)
3. **Task 2: AppStorageKeys + Localizable.xcstrings** - `985c113` (feat)

_TDD task had two commits (test -> feat); no refactor commit needed._

## Files Created/Modified
- `drinkpulse/Domain/WeeklySummaryCalculator.swift` - `SignDirection`, `WeeklySummaryContent`, `WeeklySummaryCalculator` — pure, `nonisolated`, `Sendable`, Foundation-only
- `drinkpulseTests/Domain/WeeklySummaryCalculatorTests.swift` - 9 `@Test` functions covering every branch/boundary
- `drinkpulse/DesignSystem/AppStorageKeys.swift` - added `weeklySummaryEnabled`, `pendingOpenInsights`
- `drinkpulse/Localizable.xcstrings` - added 13 new string-catalog keys (243 -> 256 total entries)

## Decisions Made
- Declared `SignDirection`, `WeeklySummaryContent`, and `WeeklySummaryCalculator` as `nonisolated` (in addition to `Sendable`, as the plan specified). The project's Swift compiler flags include `-default-isolation=MainActor`, so any type without an explicit `nonisolated` is implicitly MainActor-isolated — this made the auto-synthesized `Equatable` conformance MainActor-isolated too, which broke the non-`@MainActor` test call sites with "Main actor-isolated conformance ... cannot be used in nonisolated context." This mirrors the existing `RiskLevel.swift` precedent exactly (also `nonisolated enum ... Sendable`), so it's consistent with the codebase's established pattern for pure Domain enums, not a new convention.
- Reused `settings.reminder.openSettings` verbatim for the Settings weekly-summary denied-state action row per the plan's explicit instruction — verified only one definition exists in the file.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added explicit `nonisolated` to all three new Domain declarations**
- **Found during:** Task 1 (GREEN phase — first test run against the implementation)
- **Issue:** The plan specified `Equatable, Sendable` conformance only. Given the project's `-default-isolation=MainActor` build setting, `Sendable` alone was insufficient — the type remained MainActor-isolated, and its synthesized `Equatable` conformance could not be used from the non-actor-isolated Swift Testing struct, causing 9 build failures.
- **Fix:** Added `nonisolated` to the `enum` declarations for `SignDirection`, `WeeklySummaryContent`, and `WeeklySummaryCalculator` — matching the existing `RiskLevel.swift` convention for pure Domain types.
- **Files modified:** `drinkpulse/Domain/WeeklySummaryCalculator.swift`
- **Verification:** `xcodebuild test -only-testing:drinkpulseTests/WeeklySummaryCalculatorTests` — all 9 tests pass; full `xcodebuild build` succeeds with zero new warnings.
- **Committed in:** `e238a1d` (Task 1 GREEN commit — the fix was applied before the first commit of the implementation file, so no separate fix-up commit was needed)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary correctness fix for the project's strict-concurrency build configuration; no scope creep, no architectural change — the plan's specified public API (`content(currentWeekGrams:priorWeekGrams:hasAnyPriorWeekData:)` signature and case shapes) is unchanged.

## Issues Encountered
None beyond the auto-fixed deviation above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `WeeklySummaryCalculator` is ready for plan 01-02 (`WeeklySummaryService`) to call directly — pure function, no `ModelContext` or `UNUserNotificationCenter` dependency.
- `AppStorageKeys.weeklySummaryEnabled` / `.pendingOpenInsights` are ready for the Settings toggle (01-03), Onboarding toggle (01-04), and the notification-tap deep-link handler (01-02) to bind against.
- All string keys future plans in this phase reference (`settings.section.weeklySummary`, `settings.weeklySummary.*`, `onboarding.health.weeklySummary.*`, `weeklySummary.notification.*`) already exist in `Localizable.xcstrings` — no later plan in this phase needs to edit that file, eliminating parallel-wave file-conflict risk.
- No blockers.

---
*Phase: 01-weekly-summary-notification*
*Completed: 2026-07-20*

## Self-Check: PASSED

All created/modified files verified present on disk; all 4 commit hashes (db61f16, e238a1d, 985c113, f3e8f02) verified in git log.
