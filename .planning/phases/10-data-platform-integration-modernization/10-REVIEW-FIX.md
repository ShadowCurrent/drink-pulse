---
phase: 10-data-platform-integration-modernization
fixed_at: 2026-11-10T00:00:00Z
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
- Findings in scope: 5
- Fixed: 5 (WR-01 and WR-02 partly; the remainder of each is recorded below)
- Skipped: 0

Verification ran in the isolated review-fix worktree, on the iOS 27 simulator, with scoped
`xcodebuild test -only-testing:` runs. The worktree was removed after fast-forwarding the branch, so
the runs are not reproducible from the worktree; rerun the same scoped classes from the main checkout.
Classes run: `StoreBootstrapTests`, `WeeklySummaryCompletedWeekTests`, `WeeklySummaryServiceTests`,
`HealthServiceTests`, `HealthServiceUpdateTargetTests`, `MigrationChainV2V3Tests`. All passed, and the
new tests were confirmed in the test log. No full-suite run (not required by the escalation rules). No
file in `drinkpulse/` is over 300 lines.

## Fixed Issues

### WR-01: Store recovery still fires on any `ModelContainer` open error (prior WR-04a, deliberately left open)

**Files modified:** `docs/architecture.md`, `.claude/context/open-questions.md`
**Commit:** d800651
**Status:** fixed: requires human verification (documentation correction; the recovery semantics are unchanged)
**Applied fix:** Took the doc-correction route. Changing which errors trigger recovery needs a product
decision (the user-facing notice) and an Apple-documentation check of the error allowlist, both still
open. `docs/architecture.md` no longer says recovery fires only on "genuine store corruption". It now
states that any open failure moves the store aside, lists the transient faults that can trigger it, and
points to the follow-up. The follow-up is logged in `open-questions.md` ("Store recovery fires on any
ModelContainer open error") with the proposed allowlist (`NSCocoaErrorDomain` 259 with underlying
`NSSQLiteErrorDomain` 26, plus unknown model version, checked through Xcode MCP before use) and the
rethrow-to-`.failed` plan. The live defect remains in code and is now documented and tracked. No Apple
API changed, so no API availability record applies.

### WR-02: New error branches ship without tests, against the AGENTS.md "error paths" rule

**Files modified:** `drinkpulse/Services/WeeklySummaryService.swift`, `drinkpulse/Domain/Persistence/StoreBootstrap.swift`, `drinkpulseTests/Services/WeeklySummaryCompletedWeekTests.swift`, `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift`
**Commit:** 130589d
**Applied fix:**
1. `WeeklySummaryService.init` takes an injectable `fetch` closure, defaulting to `context.fetch`. `hasEvents` now goes through the same seam with `fetchLimit = 1` and `!isEmpty`, replacing `fetchCount`, so one seam covers all three reads. New test `fetchFailure_leavesThePendingRequestUntouched` asserts a throwing fetch produces no `add` and no `remove`.
2. `StoreBootstrap.recoverStore` takes an injectable `moveItem` closure, defaulting to `FileManager.moveItem`. New test `recoverStore_keepsSnapshotFolder_whenARollbackMoveAlsoFails` fails the `-shm` move and the WAL restore, then asserts the snapshot folder and the unrestored WAL survive and the main file is back.
3. Not done: `RecoveryError.recoveryLocationUnavailable` stays untested. The reviewer allowed accepting an untestable guard, and a provider parameter would add API surface for a guard that cannot fire on iOS.

Not mutation-tested: the fetch-failure test relies on `cancel()` calling `removePendingRequests`, so
turning the `return` back into `cancel()` makes it fail.

### IN-03: Recovery failure masks the original open error

**Files modified:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift`
**Commit:** 9de23ea
**Applied fix:** The open-failure log line now carries the original error's `domain` and `code` (both
`privacy: .public`), logged before `recoverStore` runs. Used domain and code instead of
`localizedDescription` because they are strictly error categories, while a description can embed file
paths.

### IN-01: Stale test name and duplicated coverage after the `performUpdate` change

**Files modified:** `drinkpulseTests/Services/HealthServiceTests.swift`, `drinkpulseTests/Services/HealthServiceUpdateTargetTests.swift`
**Commit:** 5a4a1d4
**Applied fix:** Renamed the old test to `update_whenDeleteFails_keepsCachedUUID_noDuplicate`. The two tests are not exact duplicates: the old one sets a cached UUID, the new one does not. So both are kept, and the new one was renamed to `update_whenDeleteFails_leavesStoredSampleAlone_andWritesNothing`, because its previous name claimed a cached-UUID assertion it never made.

### IN-02: Trim test cannot prove the new snapshot survives

**Files modified:** `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift`
**Commit:** d40514d
**Applied fix:** `recoverStore_keepsAtMostMaxSnapshots` now asserts exactly `maxRecoveredStores` entries remain, that exactly one non-seeded entry (the new snapshot, found by elimination because its name is random) survives, and that the kept seeded entries are the newest ones.

---

_Fixed: 2026-11-10_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
