---
phase: 10-data-platform-integration-modernization
reviewed: 2026-11-10T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - docs/architecture.md
  - drinkpulse/Domain/Persistence/StoreBootstrap.swift
  - drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift
  - drinkpulseTests/Services/WeeklySummaryCompletedWeekTests.swift
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
  necessity: 0
status: issues_found
---

# Phase 10: Code Review Report (incremental re-review, round 4)

**Reviewed:** 2026-11-10
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Incremental re-review of `git diff 9b1933d..HEAD` for the four listed files. The changes are the fix for the prior WR-01 (compensating move-back in the rollback loop), a new test for it, a docs update, and a parameterized fetch-failure test. No structural findings (fallow) and no external reviewer evidence were supplied. I did not run the tests or the build. `necessity-review.md` was not loaded, so no necessity findings are reported.

Verified correct:

- The compensating move works. `restored` records `(from: live, to: snapshot)` pairs, and the undo calls `moveItem(done.from, done.to)`, which moves the file live to snapshot. Direction is right.
- Trace of the new test scenario. `moved = [main, wal]` because the `-shm` move fails. Rollback restores the WAL, then the main restore fails. The WAL goes back to the snapshot, so the snapshot holds main and WAL, and `rolledBack == false` keeps the snapshot folder. The test closure does not fail the compensating move (`to` is a snapshot path and `from` is not `-shm`), so the test discriminates: without the fix, the WAL would stay live and the `!fileExists(wal)` assertion would fail.
- The original error is still rethrown, not a rollback error.
- If a compensating move fails, the loop continues with the remaining restored files (best effort). A failure never deletes files, because the snapshot is kept when `rolledBack == false`.
- `fetchFailure_leavesThePendingRequestUntouched(failingCallIndex:)` matches the service. `scheduleIfEnabled` makes exactly three sequential fetches (lines 83, 85, 87 via `hasEvents`) in one `do` block, and the first throw returns. `callCount == failingCallIndex + 1` therefore holds for 0, 1 and 2. The `defer` runs after the `callCount == failingCallIndex` check, so the indexing is right. The captured `var` is only touched on the main actor, since both the test struct and `WeeklySummaryService` are `@MainActor`.
- The docs paragraph matches the code, including the best-effort caveat.

## Warnings

### WR-01: Rollback claim "live path holds none of the store" is false for the `-shm` file; the test never checks it

**File:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift:87-91`, `docs/architecture.md:184-189`, `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift:168-202`
**Issue:** The new test's own scenario is "the `-shm` move fails". In that scenario `-shm` was never moved, so it remains at the live path. After the fixed rollback, the live path holds `store.sqlite-shm` with no main file and no WAL. The code comment ("the snapshot holds the whole store and the live path holds none of it"), the docs ("the snapshot keeps the whole store and the store location holds none of it") and the test name (`leavesLivePathEmpty`) all overclaim. The test asserts only that main and WAL are absent from the live path and says nothing about the `-shm`.

Consequence: low. An orphan `-shm` is a shared-memory index that SQLite rebuilds, so it is much less dangerous than an orphan WAL. The wording still states an invariant the code does not provide, and the snapshot never contains the `-shm` in this branch ("the whole store" is also inaccurate).

**Fix:** Pick one.

- Make the claim true: when rollback fails, also move any file still at the live path that belongs to the store (the unmoved `-shm`) into the snapshot, or delete a stale `-shm`.
- Or weaken the claim. Docs and comment: "no main file or WAL remains at the store location; an unmoved `-shm` may remain, and SQLite recreates it". Rename the test (for example `...leavesNoMainOrWalAtLivePath...`) and add `#expect(fm.fileExists(atPath: shm.path))` so the actual behavior is pinned.

## Info

### IN-01: Compensating-move failure branch is untested

**File:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift:112-118`, `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift`
**Issue:** The new test covers only the compensating move succeeding. The inner `catch` (compensating move fails, so a partial store stays live and is logged) has no test, and the injected `moveItem` seam makes one cheap to write. This is the documented "best effort" path.
**Fix:** Add a test where the mover also throws for the WAL move-back. Assert that the original error is still thrown, the snapshot folder still exists, and the WAL is still at the live path.

### IN-02: `recoverStore` rollback nests six levels deep and mixes two responsibilities

**File:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift:93-129`
**Issue:** The function body is about 65 lines. The rollback sits in a `catch`, then a `for`, then a `catch`, then another `for`, then another `catch`. That is hard to reason about, and this block has needed three review rounds to get right.
**Fix:** Extract the rollback into a private `nonisolated static func rollBack(moved:, destination:, moveItem:) -> Bool`. It restores each entry, undoes completed restores on the first failure, and returns whether the rollback was complete. The `catch` block then reduces to the folder cleanup, the log call and the rethrow.

---

_Reviewed: 2026-11-10_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
