---
phase: 10-data-platform-integration-modernization
reviewed: 2026-11-10T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - docs/architecture.md
  - drinkpulse/Domain/Persistence/StoreBootstrap.swift
  - drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
  necessity: 0
status: issues_found
---

# Phase 10: Code Review Report (incremental re-review, round 5)

**Reviewed:** 2026-11-10
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Incremental re-review of `git diff 9d39732..HEAD` (commit 2d19503) for the three listed files. No structural findings (fallow) and no external reviewer evidence were supplied. I did not run the tests or the build. `necessity-review.md` was not loaded, so no necessity findings are reported.

Prior WR-01 (rollback claim "live path holds none of the store" false for the `-shm`): fixed for the scenario it described. The diff changes only comments, docs, a test name and one test assertion. No executable logic changed, so there is no behavior regression.

- Code comment, docs paragraph and test comments now say "no main file or WAL stays at the live path" and admit an unmoved `-shm` may remain.
- Test `recoverStore_leavesNoMainFileOrWalAtLivePath_whenMainFileRestoreFailsAfterWalRestore` now pins the `-shm` behavior with `#expect(fm.fileExists(atPath: shm.path))`. Trace: `moved = [main, wal]`, the `-shm` move throws, WAL restore succeeds, main restore throws, the compensating move returns the WAL to the snapshot. The `-shm` is never touched, so the new assertion holds.
- The old test name `leavesLivePathEmpty` and the phrase "holds none of it" no longer appear anywhere in `drinkpulse`, `drinkpulseTests` or `docs`.
- The other test (`keepsMainFileAndWalTogetherInSnapshot...`) still matches its comments. Its `-shm` was also unmoved, but it does not assert on it, which is fine.

The fix is incomplete in one way, reported as WR-01 below. The new wording is true only when the failed move is the `-shm`.

IN-01 and IN-02 still apply to the current code and are carried forward unchanged in substance, with updated line numbers.

## Warnings

### WR-01: New "no main file or WAL stays at the live path" claim is false when the failed move is the WAL

**File:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift:87-92`, `docs/architecture.md:184-189`
**Issue:** The reworded claim holds only when the move that failed is the `-shm`. The move loop runs `["", "-wal", "-shm"]` in order and stops at the first throw. If the WAL move fails, then `moved = [main]`. If restoring the main file then also fails, the rollback stops with `restored` empty. The main file is in the snapshot, and the unmoved WAL stays at the live path with no main file. That is exactly the "WAL left behind next to a fresh store" state the same comment calls worse than no move. The code comment hedges with "a file whose move failed (for example the -shm)", but the sentence before it asserts "no main file or WAL stays at the live path" without a condition. The docs go further and say "an unmoved `-shm` file (the one whose move failed)", which names the `-shm` as the only possible leftover. The new tests cover only the `-shm` failure, so this case is unpinned. Consequence is low, because SQLite deletes a WAL next to a zero-size or missing main database on open, but the stated invariant is still wrong and the repo's own rationale treats an orphan WAL as the dangerous case.
**Fix:** Pick one.

- Weaken the wording to match all cases. Comment and docs: "files whose own move failed were never moved and may remain at the live path (the `-shm`, or the WAL if its move failed); a leftover `-shm` or a WAL without its main file is rebuilt or discarded by SQLite".
- Or make the claim true. When the rollback fails, also move any store file still at the live path into the snapshot, so the snapshot holds everything that could be moved.

If the claim stays, add a test where the move of the WAL throws and the restore of the main file throws, and assert what actually remains at the live path.

## Info

### IN-01: Compensating-move failure branch is untested

**File:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift:114-118`, `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift`
**Issue:** Unchanged from the prior round. The tests cover the compensating move succeeding (line 168 onward) but not the inner `catch` where the compensating move also fails. That path is documented as "best effort", logs, and leaves a partial store at the live path. The injected `moveItem` seam makes it cheap to test. The two test scenarios in the file both let the compensating move pass, because its `to` is a snapshot path and its `from` is not `-shm`.
**Fix:** Add a test where the mover throws for the `-shm` move, the main file restore, and the compensating WAL move (`from.path == wal.path`). Assert that the original error is still thrown, the snapshot folder still exists, and the WAL is still at the live path.

### IN-02: `recoverStore` rollback nests six levels deep and mixes two responsibilities

**File:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift:93-130`
**Issue:** Unchanged. `recoverStore` is still about 68 lines (67-134). The rollback sits in a `catch`, then a `for`, then a `catch`, then another `for`, then another `do/catch`. The doc comment above it has grown to six lines to explain the paths, and the last two rounds have both been about its exact wording.
**Fix:** Extract the rollback into a private `nonisolated static func rollBack(moved:destination:moveItem:) -> Bool` that restores each entry, undoes completed restores on the first failure, and returns whether the rollback was complete. The `catch` block then reduces to the folder cleanup, the log call and the rethrow. Put the per-case guarantees in that helper's doc comment, which also gives WR-01 one place to be stated correctly.

---

_Reviewed: 2026-11-10_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
