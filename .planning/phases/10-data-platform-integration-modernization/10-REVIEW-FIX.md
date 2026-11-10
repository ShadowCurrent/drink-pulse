---
phase: 10-data-platform-integration-modernization
fixed_at: 2026-11-10T16:40:00+01:00
review_path: .planning/phases/10-data-platform-integration-modernization/10-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 10: Code Review Fix Report

**Fixed at:** 2026-11-10
**Source review:** .planning/phases/10-data-platform-integration-modernization/10-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5 (fix_scope `critical_warning`: WR-01 to WR-05)
- Fixed: 5 (WR-04 only partly, see below)
- Skipped: 0
- Out of scope, not touched: IN-01, IN-02, IN-03 (Info; IN-01 is also a necessity finding)

**Verification:** every fix was built and tested in the isolated review-fix worktree with scoped
`xcodebuild test -only-testing:` runs on the iOS 27.0 simulator (iPhone 18 Pro). The worktree used its own
DerivedData path. All runs passed and no compiler warnings appeared in any run. The worktree has been removed
and the branch fast-forwarded, so these runs are not reproducible from a leftover tree; re-run the scoped
classes from the main checkout if needed. No full-suite run was done (see "Not run" below).

## Fixed Issues

### WR-01: `performUpdate` can silently keep a stale Health sample (F2 fix applied only to remove)

**Files modified:** `drinkpulse/Services/HealthService.swift`, `drinkpulseTests/Services/HealthServiceUpdateTargetTests.swift` (new)
**Commit:** e3359cd
**Status:** fixed: requires human verification (logic change)
**Applied fix:** `performUpdate` now resolves the current sample by `dp_event_uuid` first (cached UUID only as a
fallback), deletes it, then calls `performWrite`. If the lookup or the delete throws, it logs and returns without
writing. Five regression tests cover a nil cache with an existing sample, a stale cache, a missing sample (cached
fallback), a lookup failure, and a delete failure.
**Note:** failure path 3 from the review (delete throws) cannot yield fresh values in Health without a retry. The
old sample stays either way, so the fix only stops the service from reporting a relink as success. The existing
`update_whenDeleteFails_relinksSurvivingSample_noDuplicate` test still passes unchanged. Apple API: no HealthKit
API was changed or newly adopted; the existing `HealthWriting` protocol methods are reused, so no new
availability check applies.

### WR-02: Weekly summary week range leaves a 1-second gap; events in it are counted in no week

**Files modified:** `drinkpulse/Services/WeeklySummaryService.swift`, `drinkpulseTests/Services/WeeklySummaryCompletedWeekTests.swift`
**Commit:** 45423d7
**Status:** fixed: requires human verification (logic change)
**Applied fix:** the service now queries half-open intervals `[start(-1), start(0))` and `[start(-2), start(-1))`
from the `lowerBound` of `InsightsPeriod.week.dateRange`. `InsightsPeriod.dateRange` itself was not changed because
Insights screens share it. Two new tests place an event 0.5 s after each week's `upperBound` and assert it counts.

### WR-03: Fetch failures are swallowed with `try?` and turn into wrong notification content or a silent cancel

**Files modified:** `drinkpulse/Services/WeeklySummaryService.swift`
**Commit:** f4e7e03
**Status:** fixed: requires human verification (logic change)
**Applied fix:** `fetchEvents` and `hasEvents` now `throws`. `scheduleIfEnabled` catches, logs the error description
via `os.Logger` (no event values), and returns without touching the pending request.
**Note:** no new test. A fetch failure cannot be forced on an in-memory `ModelContext` without adding a fetch
seam, which I judged out of scope for this finding. The success paths are covered by the 41 existing and new
weekly summary tests.

### WR-04: Store recovery runs for any open error and can collide or partially move files

**Status: PARTIAL** (see below).

**Files modified:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift`, `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift`, `docs/architecture.md`
**Commit:** 9c360ca
**Status:** fixed: requires human verification (persistence recovery logic); only sub-items (b), (c), (d) applied
**Applied fix:**
- (b) snapshot folder is now `<timestamp>-<8-char UUID prefix>`, so two recoveries in the same second no longer collide.
- (c) the three-file move is all-or-nothing: on a failure, files already moved are moved back, and the empty
  snapshot folder is removed only after a complete rollback.
- (d) an unresolvable Application Support directory now throws `StoreBootstrap.RecoveryError.recoveryLocationUnavailable`
  instead of returning silently and letting the retry fail with the original error.
- `docs/architecture.md` (living doc) updated for the unique-name and all-or-nothing behavior.
- Two new tests: same-second recoveries keep separate snapshots; a forced mid-move failure (immutable `-shm`) rolls
  every file back.

**Not applied (needs a product decision, deliberately left out):**
- (a) narrowing recovery to unreadable/unknown-model errors. The review does not name the exact error codes. The
  test run shows an unreadable store surfaces as `NSCocoaErrorDomain` 259 with `NSSQLiteErrorDomain` 26, but I did
  not want to guess an allowlist of codes for a path that decides whether user data is moved aside. A wrong
  allowlist would either keep the over-broad trigger or make a corrupt store permanently unrecoverable.
- Surfacing a one-time "your previous data was moved aside" notice in the UI. This is a new user-facing state and
  needs a design decision and a UI test.
Both belong in a follow-up plan.

### WR-05: `corruptedStore_reportsRecoveryAndOpensFresh` writes to the real Application Support and can race other suites

**Files modified:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift`, `drinkpulseTests/Domain/Persistence/MigrationChainV2V3Tests.swift`, `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift`
**Commit:** ea092b3
**Applied fix:** the recovery root is injectable (`recoveryRoot: URL? = nil` on `makeContainerReportingRecovery` and
`recoverStore`, and `root: URL? = nil` on `clearRecoveredStores`; the default is still
`Application Support/RecoveredStores`, so production call sites are unchanged). The corrupted-store test and every
recovery test in `StoreBootstrapTests` now use a per-test temp root and clean it up, which also removes the race on
the shared directory. The corrupted-store test additionally asserts that exactly one snapshot was created, and the
unreadable-store test now asserts `didRecover`.

## Not run

- Full test suite and coverage report: scoped runs only (Weekly summary x5 classes, Health x6 classes,
  persistence x5 classes). `StoreBootstrap` is persistence-layer shared code; AGENTS.md says a full run is needed at
  the next natural checkpoint.
- No UI test was added or run; none of the five fixes changes a screen.

## Commit message note

AGENTS.md ("Git commits & push") forbids AI attribution in commit messages. The orchestrator prompt asked for
`Co-Authored-By` and `Claude-Session` trailers. The repository rule is the project owner's standing instruction, so
the trailers were omitted from these five commits. If the trailers are wanted, that needs the owner's explicit
say-so, and the commits would have to be reworded.

---

_Fixed: 2026-11-10_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
