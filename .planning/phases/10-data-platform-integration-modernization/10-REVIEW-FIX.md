---
phase: 10-data-platform-integration-modernization
fixed_at: 2026-11-10T18:45:00Z
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

## Fixed Issues

### WR-01: Rollback still leaves an orphan WAL at the live path when the WAL restore succeeds and the main-file restore fails

**Status:** fixed: requires human verification (rollback ordering logic)
**Files modified:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift`, `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift`, `docs/architecture.md`
**Commit:** 28f3fa5
**Applied fix:** The rollback loop now records each successful restore. When a restore fails, it moves every already-restored file back into the snapshot (best effort), so the snapshot holds the whole store and the live path holds none of it. A failed compensating move is logged with category only (no file names or user data). The code comment and the `docs/architecture.md` sentence now say "best effort" and state that a partial store can remain if the compensating move also fails. New test `recoverStore_leavesLivePathEmpty_whenMainFileRestoreFailsAfterWalRestore` fails the `-shm` move, lets the WAL restore succeed, fails the main-file restore (`to.path == url.path`), and asserts the main file and WAL are both in the snapshot and neither is at the live path.

**Test discrimination:** Run against the unfixed `StoreBootstrap.swift` (new test only added), it failed with 2 issues: `Expectation failed: fm.fileExists(atPath: snapshot.appendingPathComponent(wal.lastPathComponent).path)` and `Expectation failed: !fm.fileExists(atPath: wal.path)` (StoreBootstrapTests.swift:199 and :201). It passes with the fix.

### IN-01: Fetch-failure test exercises only the first fetch

**Files modified:** `drinkpulseTests/Services/WeeklySummaryCompletedWeekTests.swift`
**Commit:** c088a3e
**Applied fix:** `fetchFailure_leavesThePendingRequestUntouched` is now parameterized on the failing call index (0, 1, 2). The injected `fetch` counts calls, throws on the chosen one and delegates to the real fetch otherwise. The test keeps the `addedRequests.isEmpty` and `removedBatches.isEmpty` assertions and adds `callCount == failingCallIndex + 1` to prove the chosen read was reached.

**Test discrimination:** With a temporary mutation (second `fetchEvents` wrapped in `try? ... ?? []`, reverted before commit), case index 1 failed on `callCount == failingCallIndex + 1` and `fake.removedBatches.isEmpty`. Without the mutation all three cases pass.

### IN-02: Disposition ledger records the "recovery fires on any open error" defect as `fixed` while it is still live

**Files modified:** `.planning/phases/10-data-platform-integration-modernization/10-REVIEW-DISPOSITION.md`
**Commit:** f750444
**Applied fix:** Set the `WR-04` row to `deferred` by hand, in both the frontmatter list and the table. The Source cell states that the collision and partial-move parts are fixed and cites the `.claude/context/open-questions.md` entry "Store recovery fires on any ModelContainer open error". Per instruction, the `WR-01` row was NOT hand-marked; the disposition step reconciles it from this report. The review's suggestion to reset the `WR-01` row to `open` was therefore not applied.

## Verification

Run in the isolated worktree (not the main checkout), on iOS Simulator "iPhone 18 Pro" (iOS 27.0, UDID `1D35E1B8-4141-4EFF-A493-52CB37B600A5`), derived data in the session scratchpad:

```
xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=1D35E1B8-4141-4EFF-A493-52CB37B600A5" \
  -only-testing:drinkpulseTests/StoreBootstrapTests \
  -only-testing:drinkpulseTests/WeeklySummaryCompletedWeekTests
```

Result at HEAD (f750444): `Test run with 18 tests in 2 suites passed`, `** TEST SUCCEEDED **`. StoreBootstrapTests 10 tests passed, WeeklySummaryCompletedWeekTests 8 tests passed (the parameterized test counts as one with 3 cases). No Swift compiler warnings in the build log. No Swift file over 300 lines.

The scoped run satisfies the AGENTS.md quality gate: two test classes, and `StoreBootstrap` is persistence bootstrap, not shared calculation code. No full-suite or coverage run was done.

---

_Fixed: 2026-11-10_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
