---
phase: 10-data-platform-integration-modernization
reviewed: 2026-11-10T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - docs/architecture.md
  - drinkpulse/Domain/Persistence/StoreBootstrap.swift
  - drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift
  - drinkpulseTests/Services/WeeklySummaryCompletedWeekTests.swift
  - .planning/phases/10-data-platform-integration-modernization/10-REVIEW-DISPOSITION.md
  - .claude/context/open-questions.md
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
  necessity: 0
status: issues_found
---

# Phase 10: Code Review Report (re-review of fixes, round 3)

**Reviewed:** 2026-11-10
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Incremental re-review of `git diff e516837..HEAD`, which is fix commit 088cebd for the prior WR-01. The fix added `break` to the rollback loop so a failed restore stops the loop. It does not fully deliver the stated guarantee. The opposite-order case that the prior WR-01 called equally unsafe is real and still reachable. The tests and the docs now claim the guarantee holds. No structural findings (fallow) and no external reviewer evidence were supplied. I did not run the tests. `necessity-review.md` was not loaded, so no necessity findings are reported.

Verified as correct:

- The `break` fixes the case the test covers. Moves run main, wal, shm. If the `-shm` move fails, the rollback runs shm (never moved), then wal, then main. A WAL restore failure now stops before the main file, so main and WAL stay together in the snapshot. The updated test asserts exactly this and discriminates.
- `rolledBack == false` still keeps the snapshot folder, so nothing is deleted.
- The original error is rethrown, not the rollback error.

Carried forward from the prior round (both re-verified against current source): IN-01 and IN-02 below.

## Warnings

### WR-01: Rollback still leaves an orphan WAL at the live path when the WAL restore succeeds and the main-file restore fails

**File:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift:87-115`, `docs/architecture.md:184-186`, `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift:133-166`
**Issue:** Confirmed real. `moved` is `[main, wal]` when the `-shm` move fails. The rollback reverses it, so it restores the WAL first and the main file second. If the WAL restore succeeds and the main-file restore then fails (for example, the live path is occupied or the file system fails again), the `break` fires after the WAL is already back. The result:

- the live path holds `store.sqlite-wal` with no `store.sqlite`
- the main `.sqlite` file stays in the snapshot
- `rolledBack` is false, so the code keeps the snapshot and rethrows

The next launch then creates a fresh main file beside a stale WAL that belongs to a different database. SQLite will try to recover from that WAL, which can corrupt the new store or replay unrelated frames. This is the "opposite order" that prior WR-01 called equally unsafe. The `break` only closes the one order where the WAL fails first.

The comment at lines 87-91 and the new docs sentence ("the store location never holds a partial store") state a guarantee that does not hold on this branch. The test only covers the WAL-fails-first order, so nothing catches it. A single-direction `break` cannot give the invariant, because the files restore one at a time. Any stop point other than "all restored" or "none restored" leaves a partial store at the live path.

I rate this WARNING and not BLOCKER because it needs a double fault (the move fails, then the restore fails). The consequence is a possible corrupt store, so fix it before relying on the all-or-nothing claim.

**Fix:** When a restore fails, put back into the snapshot every file that this rollback already restored, so the live path ends up empty and the snapshot holds the whole store. Do this best-effort and keep the snapshot folder.
```swift
var restored: [(from: URL, to: URL)] = []
var rolledBack = true
for entry in moved.reversed() {
    do {
        try moveItem(entry.to, entry.from)
        restored.append(entry)
    } catch {
        rolledBack = false
        // Undo the restores already done so the live path holds no partial store.
        for done in restored.reversed() {
            try? moveItem(done.from, done.to)
        }
        break
    }
}
```
Add a test that fails only the main-file restore (`to.path == url.path` after the `-shm` failure) and asserts that `wal.path` and `url.path` are both absent from the live path and both present in the snapshot. Reword the comment and the docs sentence to say "best effort". If the compensating move also fails, log it, because that case cannot be fully avoided.

## Info

### IN-01: Fetch-failure test exercises only the first fetch (carried forward)

**File:** `drinkpulseTests/Services/WeeklySummaryCompletedWeekTests.swift:160-173`
**Issue:** Still valid. The injected `fetch` throws on every call, so the test only proves that a failure in the first `fetchEvents` returns early. `WeeklySummaryService.swift:83` (last week), `:85` (week before last) and `:134` (`hasEvents`) all use `try fetch(...)`. A regression that put `try?` back on the second or third read would still pass, because the first call already throws.
**Fix:** Parameterize the test on the call index that throws (0, 1 and 2). Use a counter in the closure and keep the same two assertions (`addedRequests.isEmpty`, `removedBatches.isEmpty`).

### IN-02: Disposition ledger records the "recovery fires on any open error" defect as `fixed` while it is still live (carried forward)

**File:** `.planning/phases/10-data-platform-integration-modernization/10-REVIEW-DISPOSITION.md` (WR-04 row, "Store recovery runs for any open error and can collide or partially move files"), `.claude/context/open-questions.md:7-24`
**Issue:** Still valid after the ledger was regenerated in d86e0fa. The ledger now has a `WR-04` row titled "Store recovery runs for any open error and can collide or partially move files", marked `fixed` with source "10-REVIEW-FIX.md (not in the current review)". The collision and partial-move parts were fixed. The "any open error" part was only documented, not fixed. `open-questions.md` still lists it as an unresolved product decision: a transient fault such as disk full or a locked device still moves the user's store aside. The ledger row reads as fully resolved. The new WR-01 row (rollback) will also need to stay `open` until WR-01 above is fixed, not `fixed`. Also, IN-02 itself is still `open` in the ledger.
**Fix:** Set the `WR-04` row to `deferred` by hand, with the Source cell citing the `open-questions.md` entry "Store recovery fires on any ModelContainer open error". Reset the `WR-01` row to `open` until the rollback gap above is closed.

---

_Reviewed: 2026-11-10_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
