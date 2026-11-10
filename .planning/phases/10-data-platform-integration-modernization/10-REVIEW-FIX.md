---
phase: 10-data-platform-integration-modernization
fixed_at: 2026-11-10T18:50:00+01:00
review_path: .planning/phases/10-data-platform-integration-modernization/10-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 10: Code Review Fix Report

**Fixed at:** 2026-11-10
**Source review:** .planning/phases/10-data-platform-integration-modernization/10-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

WR-01, IN-01 and IN-02 overlap in the same function and the same test file, so they were fixed in one commit (`cebe16b`) rather than three that could not be separated.

## Fixed Issues

### WR-01: "No main file or WAL stays at the live path" claim false when the WAL move fails

**Files modified:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift`, `docs/architecture.md`, `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift`, `drinkpulseTests/Domain/Persistence/StoreBootstrapTests+Rollback.swift`
**Commit:** cebe16b
**Status:** fixed: requires human verification (logic change in rollback behavior)
**Applied fix:** Took the reviewer's second option (make the claim true) instead of weakening wording again. When a restore fails, the rollback now moves every store file still at the live path into the snapshot. This replaces the old "undo completed restores" nested loop with one sweep, which also covers files that were never moved. The invariant is stated once, in the doc comment on `rollBack`, and mirrored in `docs/architecture.md`:

- Nothing is deleted. Each store file is either at the live path or in the snapshot.
- Complete rollback: every file is back at the live path and the snapshot folder is removed.
- Incomplete rollback: the live path holds only files whose own move into the snapshot failed. The snapshot folder is kept.

The "SQLite recreates a -shm" claim is dropped. It was not part of the move-level guarantee and was not verified.

Failure cases, each pinned by a test in `StoreBootstrapTests+Rollback.swift`:

| Failing step | Test | Live path afterwards |
|---|---|---|
| `-shm` move (real immutable file) | `rollsBackEveryFile_whenALaterMoveFails` | all three files, no snapshot |
| WAL move, main restore ok | `restoresMainFile_whenTheWalMoveFails` | all three files, no snapshot |
| WAL move fails once, main restore fails (the reviewer's case) | `movesWalAndShmIntoSnapshot_whenTheWalMoveFailsOnceAndMainRestoreFails` | empty |
| WAL move always fails, main restore fails | `leavesOnlyTheImmovableWalAtLivePath_whenTheWalNeverMovesAndMainRestoreFails` | only the WAL |
| `-shm` move, WAL restore fails | `keepsMainFileAndWalInSnapshot_whenWalRestoreFails` | only `-shm` |
| `-shm` move, WAL restore ok, main restore fails | `returnsRestoredWalToSnapshot_whenMainFileRestoreFailsAfterWalRestore` | only `-shm` |
| as above, plus the sweep move of the WAL fails | `rethrowsOriginalErrorAndKeepsSnapshot_whenTheSweepMoveAlsoFails` | WAL and `-shm` |

Mutation check: disabling the sweep made 3 of these tests fail (the three with a movable file left at the live path). Source was restored byte-for-byte afterward.

### IN-01: Compensating-move failure branch is untested

**Files modified:** `drinkpulseTests/Domain/Persistence/StoreBootstrapTests+Rollback.swift`
**Commit:** cebe16b
**Applied fix:** `rethrowsOriginalErrorAndKeepsSnapshot_whenTheSweepMoveAlsoFails` forces the sweep move to fail. It asserts that the original `move` error is rethrown (not the restore or compensate error), the snapshot folder is kept with the main file, and the failing files stay at the live path.

### IN-02: `recoverStore` rollback nests six levels deep and mixes two responsibilities

**Files modified:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift`
**Commit:** cebe16b
**Applied fix:** Extracted `rollBack(moved:storeURL:destination:moveItem:) -> Bool` and a `storeFiles(of:)` helper, which the forward move loop also uses. The `catch` in `recoverStore` now only calls `rollBack`, removes the empty snapshot folder after a complete rollback, logs, and rethrows. `recoverStore` shrank and the nesting is two levels in `rollBack`.

Supporting change: the three rollback tests moved out of `StoreBootstrapTests.swift` into an `extension StoreBootstrapTests` in `StoreBootstrapTests+Rollback.swift` (same suite). This keeps both files under 300 lines (153 and 212). The two temp-path helpers lost `private` so the extension can use them.

## Verification

Run in the isolated worktree (iOS 27.0 iPhone 18 Pro simulator, dedicated derived-data path). The worktree was fast-forwarded into the branch and removed afterward.

```
xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=<iPhone 18 Pro iOS 27.0>" \
  -only-testing:drinkpulseTests/StoreBootstrapTests
```

Result: `** TEST SUCCEEDED **`. "Test run with 14 tests in 1 suite passed". All 7 rollback tests above and the 7 pre-existing tests ran by name in the log. No Swift compiler warnings in the log. A scoped run suffices under AGENTS.md because only one test class is affected and no calculation or guideline code changed. The full suite and coverage report were not run.

Living docs: `docs/architecture.md` updated in the same commit. No commit carries AI attribution, per AGENTS.md.

---

_Fixed: 2026-11-10_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
