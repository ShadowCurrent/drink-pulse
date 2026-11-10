---
phase: 10-data-platform-integration-modernization
reviewed: 2026-11-10T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - .claude/context/open-questions.md
  - docs/architecture.md
  - drinkpulse/Domain/Persistence/StoreBootstrap.swift
  - drinkpulse/Services/WeeklySummaryService.swift
  - drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift
  - drinkpulseTests/Services/HealthServiceTests.swift
  - drinkpulseTests/Services/HealthServiceUpdateTargetTests.swift
  - drinkpulseTests/Services/WeeklySummaryCompletedWeekTests.swift
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
  necessity: 0
status: issues_found
---

# Phase 10: Code Review Report (re-review of fixes, round 2)

**Reviewed:** 2026-11-10
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Incremental re-review of `git diff b0743f5..HEAD` over the eight listed files. This round covers the fixes for the prior WR-01, WR-02, IN-01, IN-02 and IN-03. All five are correctly implemented and add no regression in the code paths I traced. I did not run the tests; the fix report says the scoped classes passed on the simulator. One new warning concerns the rollback path, which the new test now pins in place. No structural findings (fallow) and no external reviewer evidence were supplied. `necessity-review.md` was not loaded, so no necessity findings are reported.

Verified as correct:

- **Prior WR-01 (doc fix).** `docs/architecture.md` now states that recovery fires on any open error. The new `open-questions.md` entry tracks the allowlist and the user notice. The code and docs agree again. The recovery condition itself is unchanged, which the fixer disclosed.
- **Prior WR-02 (fetch seam).** `WeeklySummaryService.init` takes `fetch:` with a default of `{ try $0.fetch($1) }`. Every other call site uses the default. `hasEvents` now uses `fetch` with `fetchLimit = 1` and `!isEmpty`, which gives the same answer as the old `fetchCount > 0`. `fetchFailure_leavesThePendingRequestUntouched` is not vacuous: its defaults enable the feature, so the test gets past the `guard`.
- **Prior WR-02 (move seam).** `recoverStore(at:recoveryRoot:moveItem:)` has a non-escaping `moveItem` closure that defaults to `FileManager.moveItem`. The new rollback-failure test traces correctly. The `-shm` move fails. The WAL restore fails because `to.path == wal.path` (the path is built the same way as in `recoverStore`). The main file is restored. The snapshot folder survives with the WAL in it. The thrown error is the original `MoveFailure`. If `rolledBack` were ignored, the snapshot would be deleted and the WAL assertion would fail, so the test discriminates.
- **Prior IN-02 (trim test).** Five seeded folders are created 10 ms apart, then one new folder is added, and trim keeps the newest three. The assertions (`count == 3`, exactly one unseeded entry, kept seeded set equals the last two seeded names) hold and would catch a trim that deleted the fresh snapshot.
- **Prior IN-03 (log).** The original open error's domain and code are logged with `privacy: .public` before `recoverStore` runs. Both values are error categories, not user data.
- **Prior IN-01 (renames).** `update_whenDeleteFails_keepsCachedUUID_noDuplicate` asserts the cached UUID is kept. `update_whenDeleteFails_leavesStoredSampleAlone_andWritesNothing` seeds no cached UUID and asserts the stored sample is untouched. The two cover different setups and the names match what each asserts.

## Warnings

### WR-01: Failed rollback leaves the main store file without its WAL, and the new test pins that state

**File:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift:99-115`, `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift:133-164`
**Issue:** The comment at line 87 says a main file without its WAL "is worse than no move". But the rollback loop keeps going after a failed restore. In the tested scenario the WAL restore fails and the main file is then restored anyway. The live store location ends up holding a main `.sqlite` file whose committed-but-uncheckpointed WAL transactions sit in the snapshot folder. The error propagates to the `.failed` retry screen. A later retry can open that main file and silently show stale data, with the missing transactions only in `RecoveredStores/`. The new test asserts exactly this half-restored state as the expected outcome. The opposite order is equally unsafe: a restored WAL next to a missing main file leaves an orphan WAL beside a fresh store. The all-or-nothing guarantee in the doc and comment therefore does not hold on this branch.
**Fix:** Stop at the first failed restore so the files that could not all be put back stay together in the snapshot. Then the live path holds no partial store, and the retry creates a fresh one while the whole snapshot is preserved for manual recovery.
```swift
var rolledBack = true
for entry in moved.reversed() {
    do {
        try moveItem(entry.to, entry.from)
    } catch {
        rolledBack = false
        break
    }
}
```
Because the loop runs in reverse order, a failure on the WAL then leaves the main file in the snapshot with it. Update the test to assert that both the main file and the WAL are in the snapshot. If the live-store state after a failed rollback is meant to be a product decision, record it in `open-questions.md` instead.

## Info

### IN-01: Fetch-failure test exercises only the first fetch

**File:** `drinkpulseTests/Services/WeeklySummaryCompletedWeekTests.swift:164-176`
**Issue:** The injected `fetch` throws on every call, so the test only proves that a failure in `fetchEvents` for last week returns early. A regression that put `try?` back on the second `fetchEvents` or on `hasEvents` would still pass, because the first call already throws. Prior WR-03 fixed all three reads.
**Fix:** Parameterize the test on the call index that throws (0, 1 and 2). Use a counter in the closure and keep the same two assertions (`addedRequests.isEmpty`, `removedBatches.isEmpty`).

### IN-02: Disposition records WR-01 as `fixed` while the defect is still live

**File:** `.planning/phases/10-data-platform-integration-modernization/10-REVIEW-DISPOSITION.md` (WR-01 row), `.claude/context/open-questions.md:7-24`
**Issue:** The prior WR-01 was "recovery fires on any open error". The fix changed the documentation only; the code still moves the user's store aside on a transient fault such as disk full or a locked device. The disposition says `fixed`, which downstream tooling reads as resolved. The honest state is `deferred` with the open question as the reason.
**Fix:** Set the disposition to `deferred` by hand and cite the `open-questions.md` entry as the reason in the Source cell.

---

_Reviewed: 2026-11-10_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
