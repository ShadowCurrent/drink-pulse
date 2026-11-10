---
phase: 10-data-platform-integration-modernization
reviewed: 2026-11-10T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - .claude/context/open-questions.md
  - docs/architecture.md
  - drinkpulse/Domain/Persistence/StoreBootstrap.swift
  - drinkpulse/Services/HealthService.swift
  - drinkpulse/Services/WeeklySummaryService.swift
  - drinkpulseTests/Domain/Persistence/MigrationChainV2V3Tests.swift
  - drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift
  - drinkpulseTests/Services/HealthServiceUpdateTargetTests.swift
  - drinkpulseTests/Services/WeeklySummaryCompletedWeekTests.swift
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
  necessity: 0
status: issues_found
---

# Phase 10: Code Review Report (re-review of fixes)

**Reviewed:** 2026-11-10
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Incremental re-review of `git diff ff7635f..HEAD` over the nine listed files. The fixes for the prior WR-01, WR-02, WR-03 and WR-05 are correct and introduce no new defects. WR-04 is only partly fixed, and its main part is still open. No structural findings (fallow) and no external reviewer evidence were supplied. `necessity-review.md` was not loaded, and no necessity findings are reported.

Verified as correct:

- **Prior WR-01 (`HealthService.performUpdate`).** The lookup by `dp_event_uuid` takes precedence over the cached UUID. A throwing lookup or delete now returns without relinking, and the cache is kept. `HKHealthStore.deleteObjects` does not throw when nothing matches, so a stale cache with no live sample still proceeds to the fresh write. The old `update_whenDeleteFails_relinksSurvivingSample_noDuplicate` assertions still hold, because `healthKitUUID == old` is now true by retention instead of relink.
- **Prior WR-02 (week gap).** The half-open intervals use `dateRange(...).lowerBound`. `thisWeekStart` equals `lastWeekStart + 7 days` by calendar arithmetic, so DST does not reopen a gap. I checked that both new tests discriminate: under the old code the first test counts last week as 0 and the second flips the direction to "up".
- **Prior WR-03 (`try?` swallowing).** The throwing fetch helpers are caught once in `scheduleIfEnabled` and logged with `error.localizedDescription` only, with no event values. The epoch bookkeeping is untouched because the early return happens before `lifecycleEpoch += 1`.
- **Prior WR-04 sub-items (b), (c), (d).** The random suffix removes the same-second collision. Rollback runs in reverse order. The snapshot folder is removed only after a complete rollback. `recoveryLocationUnavailable` is thrown instead of a silent return. `drinkpulseApp.loadContainerIfNeeded` maps any thrown error to the `.failed` retry screen, so the new error type is handled.
- **Prior WR-05 (test isolation).** The recovery root is injectable (`recoveryRoot: URL? = nil`, `root: URL? = nil`), and every recovery test uses a per-test temp root with cleanup. Production call sites still use the default.
- **`open-questions.md` claim.** `git diff fbd37fa HEAD -- drinkpulse/Features/Insights` is empty, so "Phase 10 changed no Insights files" is true.

## Warnings

### WR-01: Store recovery still fires on any `ModelContainer` open error (prior WR-04a, deliberately left open)

**File:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift:43-52`
**Issue:** `makeContainerReportingRecovery` catches every error from `ModelContainer.init` and moves the user's whole store aside. This includes transient faults (disk full, file protection while the device is locked, an I/O error). The user is then silently shown an empty app, and after three such events `trimRecoveredStores` permanently deletes the oldest snapshot. The fixer left (a) and the user-facing notice out for lack of a product decision. That is a reasonable call, but the defect is still live in a path that moves user health data. `docs/architecture.md:179` still says recovery fires only on "genuine store corruption", which the code does not enforce. Under the living-docs rule the doc and code contradict each other.
**Fix:** Track as an explicit follow-up with an owner. Until it ships, either reword the architecture doc to say "any open failure" or make the recovery condition match the doc. The condition can rest on the observed unreadable-store signature (`NSCocoaErrorDomain` 259 with an underlying `NSSQLiteErrorDomain` 26) plus the unknown-model-version error. Check Apple's `SwiftDataError` and `CocoaError` documentation through Xcode MCP before fixing the allowlist, and rethrow everything else to the existing `.failed` retry screen.

### WR-02: New error branches ship without tests, against the AGENTS.md "error paths" rule

**File:** `drinkpulse/Services/WeeklySummaryService.swift:85-90`, `drinkpulse/Domain/Persistence/StoreBootstrap.swift:91-105`
**Issue:** The fixes add three failure branches with no test:
1. The `scheduleIfEnabled` fetch-failure branch. The fix report calls out the missing fetch seam. AGENTS.md requires regression tests for every fixed bug, and the branch has none: a change that turned the `return` back into `cancel()` would pass the suite.
2. The rollback-failure branch (`rolledBack == false`). In that case the destination folder is kept and the store ends up split across locations. This is the riskiest data path in the change.
3. `RecoveryError.recoveryLocationUnavailable`.
Only the successful rollback is tested.
**Fix:**
1. Add a small injectable fetch closure on `WeeklySummaryService` (for example `fetch: (FetchDescriptor<ConsumptionEvent>, ModelContext) throws -> [ConsumptionEvent]`, defaulting to `context.fetch`). Assert that a throwing fetch leaves `FakeNotificationCenter` with no `add` and no `remove` call.
2. Test the rollback failure by making a rollback target unwritable. Alternatively, extract the file-mover behind a closure so a test can fail the rollback and assert that the snapshot folder survives.
3. Accept an untestable guard for `recoveryLocationUnavailable`, or take the `defaultRecoveryRoot` provider as a parameter so that the case can be tested.

## Info

### IN-01: Stale test name and duplicated coverage after the `performUpdate` change

**File:** `drinkpulseTests/Services/HealthServiceTests.swift:133`, `drinkpulseTests/Services/HealthServiceUpdateTargetTests.swift:75-87`
**Issue:** `update_whenDeleteFails_relinksSurvivingSample_noDuplicate` no longer relinks anything. It now asserts that the update stops and keeps the cached UUID. The new `update_whenDeleteFails_keepsCachedUUID_andWritesNothing` covers the same scenario, so the two overlap and the old name misleads whoever reads a future failure.
**Fix:** Rename the old test to `..._keepsCachedUUID_noDuplicate`, or delete it in favor of the new one.

### IN-02: Trim test cannot prove the new snapshot survives

**File:** `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift:138-157`
**Issue:** The test asserts only `afterContents.count <= maxRecoveredStores`. It passes even if `trimRecoveredStores` deleted the snapshot that was just created and kept the stale ones, because trimming orders by directory modification time and the new snapshot's name is now random. A regression there would silently drop the freshest recovery data.
**Fix:** Capture the new snapshot directory (the one entry not in the seeded set) and assert that it still exists, and that the oldest seeded entries are the ones removed.

### IN-03: Recovery failure masks the original open error

**File:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift:46-49`
**Issue:** When `recoverStore` throws (now more often, with the new `recoveryLocationUnavailable` and move-failure paths), the thrown error is the recovery error. The original `ModelContainer.init` error is only logged as a fixed string with no category. The startup-failure screen and any later diagnosis lose the root cause.
**Fix:** Log `error.localizedDescription` of the original open error, which is a non-PII error category, before `recoverStore`, or wrap both errors in one typed error that carries the underlying open error.

---

_Reviewed: 2026-11-10_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
