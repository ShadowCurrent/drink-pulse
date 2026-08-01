---
phase: quick-260801-l5j
plan: 01
subsystem: infra
tags: [swift, swiftui, usernotifications, autoclosure, lazy-var, performance, cold-launch]

# Dependency graph
requires: []
provides:
  - "ReminderService/WeeklySummaryService no longer call UNUserNotificationCenter.current() synchronously at construction"
  - "Laziness-contract test pattern (CallCounter/countingCenter) reusable for future @autoclosure-provider services"
affects: [RootShellView, ReminderSection, WeeklySummarySection, HealthStep, ViewLoadLogger]

# Actuals (#2632)
actuals:
  tokens: 2664
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "@autoclosure @escaping init parameter + private lazy var to defer a main-thread-blocking framework call off a synchronous construction path"

key-files:
  created: []
  modified:
    - drinkpulse/Services/ReminderService.swift
    - drinkpulse/Services/WeeklySummaryService.swift
    - drinkpulseTests/Services/ReminderServiceTests.swift
    - drinkpulseTests/Services/WeeklySummaryServiceTests.swift
    - docs/DEVLOG.md

key-decisions:
  - "Fixed at the Services layer (centerProvider/lazy center), not at any individual call site — transparently covers RootShellView, ReminderSection, WeeklySummarySection, and HealthStep's identical eager-construction pattern with zero changes to those four files."
  - "Real-device ViewLoadLogger re-measurement deferred as an explicit follow-up — no physical device attached to this environment; the todo's own verification step could not be performed here."

patterns-established:
  - "@autoclosure @escaping provider + private lazy var pattern for deferring expensive/blocking default-arg resolution in @MainActor services, while preserving existing protocol-injection testability."

requirements-completed:
  - TODO-defer-unusernotificationcenter-current

coverage:
  - id: D1
    description: "ReminderService()/WeeklySummaryService() (zero-arg production default) no longer call UNUserNotificationCenter.current() synchronously at construction — resolution is deferred to first actual scheduling use."
    requirement: "TODO-defer-unusernotificationcenter-current"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Services/ReminderServiceTests.swift#center_isNotResolved_atInit_onlyOnFirstActualUse"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Services/WeeklySummaryServiceTests.swift#center_isNotResolved_atInit_onlyOnFirstActualUse"
        status: pass
    human_judgment: false
  - id: D2
    description: "Existing DI/testability pattern (protocol injection via center:) fully preserved — no regressions in pre-existing ReminderServiceTests/WeeklySummaryServiceTests."
    verification:
      - kind: unit
        ref: "xcodebuild test -only-testing:drinkpulseTests/ReminderServiceTests -only-testing:drinkpulseTests/WeeklySummaryServiceTests (29/29 passed)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Real-device re-measurement of Dashboard cold-launch time via ViewLoadLogger, confirming the ~3063ms regression is resolved."
    verification: []
    human_judgment: true
    rationale: "No physical device is attached to this environment; this is the source todo's own stated verification step and is explicitly deferred as a follow-up, not performed in this session."

# Metrics
duration: 39min
completed: 2026-08-01
status: complete
---

# Quick Task 260801-l5j: Defer UNUserNotificationCenter.current() out of cold-launch path Summary

**`ReminderService`/`WeeklySummaryService` init parameter changed to `@autoclosure @escaping` + `private lazy var center`, deferring the documented main-thread-blocking `UNUserNotificationCenter.current()` call off `RootShellView`'s synchronous construction path to first actual scheduling use.**

## Performance

- **Duration:** 39 min
- **Started:** 2026-08-01T15:21:53+02:00
- **Completed:** 2026-08-01T16:01:01+02:00
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- `ReminderService`/`WeeklySummaryService` no longer touch `UNUserNotificationCenter.current()` synchronously at init — the `center:` init parameter is now `@autoclosure @escaping () -> NotificationScheduling`, stored as `centerProvider`, resolved on first read via a new `private lazy var center`.
- Two new TDD-driven laziness-contract tests (`center_isNotResolved_atInit_onlyOnFirstActualUse`, one per service) prove 0 resolutions at init, exactly 1 on first center-touching call, still 1 on a second call — via a shared `CallCounter`/`countingCenter` test helper added to `ReminderServiceTests.swift`.
- Fix transparently covers the same eager-construction pattern at `RootShellView`, `ReminderSection`, `WeeklySummarySection`, and `HealthStep` — none of those four files needed a code change.
- Full suite verified green at full scope (673 tests, 0 failures) per CLAUDE.md's escalation rule (shared Services-layer change, 7+ dependent UI test classes); build clean (zero warnings); no file over 300 lines.
- `docs/DEVLOG.md` records the fix, its generalized effect, and the outstanding real-device re-measurement follow-up.

## Task Commits

Each task was committed atomically:

1. **Task 1: Defer UNUserNotificationCenter.current() resolution to first actual use** - `64a0a29` (fix, TDD: RED test written and confirmed failing before the production `@autoclosure`/`lazy var` change, then GREEN)
2. **Task 2: Full-suite verification + DEVLOG entry** - `1b54cd9` (docs)

_Note: Task 1 is a single commit covering the full RED→GREEN cycle for this quick task (test file + production file changed together), consistent with the plan's `<files>` list for that task; both the failing and passing test runs were executed and inspected before committing._

## Files Created/Modified
- `drinkpulse/Services/ReminderService.swift` - `center:` init param → `@autoclosure @escaping`; `private let centerProvider` + `private lazy var center` replace the old eager `private let center`; doc comment explains why.
- `drinkpulse/Services/WeeklySummaryService.swift` - Identical transformation.
- `drinkpulseTests/Services/ReminderServiceTests.swift` - New `CallCounter` class + `countingCenter(_:_:)` helper (internal, shared target-wide) + `center_isNotResolved_atInit_onlyOnFirstActualUse` test.
- `drinkpulseTests/Services/WeeklySummaryServiceTests.swift` - Mirrored `center_isNotResolved_atInit_onlyOnFirstActualUse` test, reusing the shared helpers.
- `docs/DEVLOG.md` - New dated entry describing the bug, root cause, fix, generalized effect on the other 3 call sites, verification results, and the outstanding real-device follow-up.

## Decisions Made
- Fix lives entirely in the two Services' init/lazy-resolution rather than at any individual call site (`RootShellView`, `ReminderSection`, `WeeklySummarySection`, `HealthStep`), so every current and future eager-construction call site benefits automatically without a code change.
- Used `@autoclosure @escaping` (matching the Swift language guide's documented attribute order) over alternatives like moving service construction into the async `.onChange(of: scenePhase)` path — preserves `RootShellView`'s existing shape exactly (zero changes to that file) per the plan's non-goals.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- First full-suite `xcodebuild test` attempt failed environment-wide ("Application failed preflight checks" / simulator busy — `SBMainWorkspace` denied app launch), producing 0 passed / 76 failed across every UI test class and the unit test host. Diagnosed via `xcrun xcresulttool get test-results summary` as a transient simulator-contention issue unrelated to the code change (confirmed: the failure text was identical "Busy" launch-preflight rejection across every single test, not a per-test assertion failure). Fixed with `xcrun simctl shutdown all` followed by a clean retry, which passed with 673/673 tests green (0 failures). Not a deviation from the plan — an infrastructure hiccup, resolved without touching any plan file.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Fix is complete, tested, and documented. Ready for the next quick task or phase.
- **Outstanding follow-up (explicitly not done here, no physical device attached):** re-measure Dashboard's cold-launch first-appear time via `ViewLoadLogger` on a real device to confirm the ~3063ms regression actually drops to roughly the container-load figure (~10-50ms) plus normal SwiftUI mount time, per the source todo's own stated verification step. The source todo (`.planning/todos/pending/2026-08-01-defer-unusernotificationcenter-current-out-of-rootshellview-cold-launch.md`) should stay in `pending/` (not moved to `completed/`) until that real-device confirmation happens.

---
*Quick task: quick-260801-l5j*
*Completed: 2026-08-01*

## Self-Check: PASSED

All 5 modified/created files confirmed present on disk; both task commits
(`64a0a29`, `1b54cd9`) confirmed present in git history.
