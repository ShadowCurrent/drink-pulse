---
phase: 01-weekly-summary-notification
plan: 02
subsystem: notifications
tags: [swiftdata, usernotifications, services-layer, weekly-summary]

# Dependency graph
requires:
  - phase: 01-weekly-summary-notification (plan 01-01)
    provides: WeeklySummaryCalculator (WeeklySummaryContent enum + content(currentWeekGrams:priorWeekGrams:hasAnyPriorWeekData:) classifier), AppStorageKeys.weeklySummaryEnabled, and the weeklySummary.notification.* localization strings
provides:
  - WeeklySummaryService (Services/ layer): stable identifier, pure makeRequest(calendar:content:) trigger factory, requestAuthorization, cancel, and scheduleIfEnabled(context:) that fetches current/prior-week ConsumptionEvents via SwiftData and schedules the notification
affects: [01-weekly-summary-notification (plan 01-03, which wires NotificationActionHandler / UI settings toggle to this service)]

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - drinkpulse/Services/WeeklySummaryService.swift
    - drinkpulseTests/Services/WeeklySummaryServiceTests.swift
  modified: []

key-decisions:
  - "makeRequest(calendar:content:) reads calendar.firstWeekday fresh on every call (default parameter = .current) rather than caching it at service-init, so a Region-setting change is picked up on the next scheduleIfEnabled call (ENGG-03)"
  - "scheduleIfEnabled(context:) sums ConsumptionEvent.pureAlcoholGrams (physical 0.789 density) exclusively; grepped the file post-implementation to confirm zero calls to alcoholGrams(density:) with any other value"
  - "hasAnyPriorWeekData is computed via a separate fetchLimit-1 FetchDescriptor<ConsumptionEvent> predicate (consumptionDate < currentWeekStart), kept distinct from the priorWeekGrams sum so a logged 0.0%-ABV event in the prior week still counts as real history (ENGG-05) rather than triggering the first-week skip (ENGG-06)"

patterns-established: []

requirements-completed: [ENGG-03, ENGG-04, ENGG-05, ENGG-06]

coverage:
  - id: D1
    description: "makeRequest(calendar:content:) returns nil for .skip and builds a weekly-repeating UNCalendarNotificationTrigger (locale-aware weekday, fixed 9:00 fire time) with the correct localized title/body for every WeeklySummaryContent branch"
    requirement: "ENGG-03"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#makeRequest_returnsNil_forSkipContent"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#makeRequest_buildsWeeklyRepeatingTrigger_atFireHourMinute_withInjectedFirstWeekday"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#makeRequest_setsLocalizedTitle_forEveryContentBranch"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#makeRequest_bodyText_percentageUp_interpolatesRoundedWholePercent"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#makeRequest_bodyText_percentageDown_interpolatesRoundedWholePercent"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#makeRequest_bodyText_percentageSame_hasNoInterpolation"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#makeRequest_bodyText_directionOnlyUp"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#makeRequest_bodyText_directionOnlySame"
        status: pass
    human_judgment: false
  - id: D2
    description: "cancel() and requestAuthorization() mirror ReminderService's idempotent-remove and granted/error-propagation behavior"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#cancel_removesPendingWeeklySummaryRequest"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#requestAuthorization_returnsGrantedResult_andPropagatesError"
        status: pass
    human_judgment: false
  - id: D3
    description: "scheduleIfEnabled(context:) is a no-op when disabled, cancels cleanly when there's no prior-week data at all, schedules density-correct percentage content, treats a zero-ABV prior week as real data (directionOnly, not skip), is idempotent, and swallows scheduling errors without throwing"
    requirement: "ENGG-04, ENGG-05, ENGG-06"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#scheduleIfEnabled_doesNothing_whenDisabled"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#scheduleIfEnabled_cancelsPending_whenNoPriorWeekDataAtAll"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#scheduleIfEnabled_schedulesPercentageContent_usingPhysicalDensity_notModeDensity"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#scheduleIfEnabled_directionOnly_whenPriorWeekHasOnlyZeroAbvEvent"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#scheduleIfEnabled_isIdempotent_leavesOnePendingRequest"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#scheduleIfEnabled_swallowsSchedulingError_withoutThrowing"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-20
status: complete
---

# Phase 01 Plan 02: WeeklySummaryService Summary

**`Services/` layer notification scheduler mirroring `ReminderService`'s shape, sourcing content from `WeeklySummaryCalculator` and fetching current/prior-week `ConsumptionEvent`s directly via SwiftData, always summing physical `pureAlcoholGrams` (never a display-mode density).**

## Performance

- **Duration:** 25 min
- **Started:** 2026-07-20T15:55:00Z
- **Completed:** 2026-07-20T16:02:30Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- `WeeklySummaryService` with a stable identifier, UI-test-safe `defaultCenter()` factory, and a pure `makeRequest(calendar:content:)` trigger factory that reads `calendar.firstWeekday` fresh at call time (never cached)
- `scheduleIfEnabled(context:)` fetches current/prior-week `ConsumptionEvent`s via `FetchDescriptor`, sums physical `pureAlcoholGrams` exclusively, and determines `hasAnyPriorWeekData` via a distinct fetchCount predicate — so a logged 0.0%-ABV event still counts as real prior-week history
- Idempotent remove-then-add schedule/cancel, matching `ReminderService`'s exact pattern; scheduling errors are logged by category only, never interpolating grams/percentage/fire date
- 16 unit tests covering makeRequest's nil-for-skip guard, trigger construction, every localized body branch, cancel, requestAuthorization, and all six `scheduleIfEnabled` gating/skip/density-correctness scenarios

## Task Commits

Each task was executed as a RED/GREEN TDD cycle, each half committed atomically:

1. **Task 1: makeRequest + requestAuthorization + cancel** — `692ad12` (test: RED — 10 failing tests), `8cdc4fb` (feat: GREEN — implementation)
2. **Task 2: scheduleIfEnabled(context:) SwiftData wiring** — `703f335` (test: RED — 6 failing tests), `d573bf5` (feat: GREEN — implementation)

## Files Created/Modified
- `drinkpulse/Services/WeeklySummaryService.swift` - New `@MainActor` service: `weeklySummaryIdentifier`/`fireHour`/`fireMinute` constants, `defaultCenter()`, `requestAuthorization()`, `makeRequest(calendar:content:)`, `cancel()`, `scheduleIfEnabled(context:)`, and private `fetchEvents(in:from:to:)` / `hasEvents(in:before:)` helpers
- `drinkpulseTests/Services/WeeklySummaryServiceTests.swift` - New test file, 16 `@Test` functions, reuses `FakeNotificationCenter` from `ReminderServiceTests.swift` directly (no duplicate fake)

## Decisions Made
- `calendar` is a default parameter (`= .current`) on `makeRequest`, not stored at init, so `Region` changes are honored on the very next `scheduleIfEnabled` call without needing to reconstruct the service
- Reused `WeeklySummaryCalculator.content(...)` from plan 01-01 verbatim rather than re-deriving any percentage/direction logic in the Services layer
- Kept `bodyText(for:)` private and static, matching `ReminderService`'s convention of no public formatting API surface

## Deviations from Plan

None — plan executed exactly as written. All 16 named test functions match the plan's `<behavior>` spec, and the acceptance-criteria greps (zero `alcoholGrams(density:` calls, no raw Double/Int/Date interpolation in `logger.error`) both pass.

## Issues Encountered
- The simulator occasionally returned a transient "Busy (Application failed preflight checks)" launch failure on `xcodebuild test` runs, most likely from concurrent parallel-executor contention on the shared simulator; retrying the exact same `-only-testing:drinkpulseTests/WeeklySummaryServiceTests` invocation succeeded both times. This is infrastructure flakiness, not a code defect — the plan's required verification command passed cleanly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `WeeklySummaryService` is fully implemented and unit-tested; plan 01-03 can now wire it into app-launch/foreground scheduling and a Settings toggle without further Services-layer work
- No blockers. The identifier `WeeklySummaryService.weeklySummaryIdentifier` is available for `NotificationActionHandler` (plan 01-03) to match against

---
*Phase: 01-weekly-summary-notification*
*Completed: 2026-07-20*

## Self-Check: PASSED

- FOUND: drinkpulse/Services/WeeklySummaryService.swift
- FOUND: drinkpulseTests/Services/WeeklySummaryServiceTests.swift
- FOUND: .planning/phases/01-weekly-summary-notification/01-02-SUMMARY.md
- FOUND commit: 692ad12 (test RED — Task 1)
- FOUND commit: 8cdc4fb (feat GREEN — Task 1)
- FOUND commit: 703f335 (test RED — Task 2)
- FOUND commit: d573bf5 (feat GREEN — Task 2)
- FOUND commit: 2f9cc24 (docs — summary)
