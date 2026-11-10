---
phase: 10-data-platform-integration-modernization
reviewed: 2026-11-10T00:00:00Z
depth: standard
files_reviewed: 33
files_reviewed_list:
  - drinkpulse/Domain/Persistence/StoreBootstrap.swift
  - drinkpulse/drinkpulseApp.swift
  - drinkpulse/Features/Shell/RootShellView.swift
  - drinkpulse/Localizable.xcstrings
  - drinkpulse/Services/HealthKitAdapter.swift
  - drinkpulse/Services/HealthService.swift
  - drinkpulse/Services/NotificationActionHandler.swift
  - drinkpulse/Services/ReminderService.swift
  - drinkpulse/Services/UITestNotificationCenter.swift
  - drinkpulse/Services/WeeklySummaryService.swift
  - drinkpulse/UITestSeed.swift
  - drinkpulseTests/Domain/DataTransfer/BackupFixtureLoader.swift
  - drinkpulseTests/Domain/DataTransfer/SanitizedBackupFixtureTests.swift
  - drinkpulseTests/Domain/Persistence/MigrationChainV1Tests.swift
  - drinkpulseTests/Domain/Persistence/MigrationChainV2V3Tests.swift
  - drinkpulseTests/Domain/Persistence/MigrationFixtures.swift
  - drinkpulseTests/Domain/Persistence/MigrationFixtures+LegacyV2V3.swift
  - drinkpulseTests/Domain/Persistence/MigrationFixtureValues.swift
  - drinkpulseTests/Domain/Persistence/MigrationSweepTests.swift
  - drinkpulseTests/Services/HealthServiceConcurrencyTests.swift
  - drinkpulseTests/Services/HealthServiceOrderingTests.swift
  - drinkpulseTests/Services/HealthServiceRemoveSampleTests.swift
  - drinkpulseTests/Services/HealthWriteHooksTests.swift
  - drinkpulseTests/Services/NotificationActionHandlerTests.swift
  - drinkpulseTests/Services/NotificationDelegateAssignmentTests.swift
  - drinkpulseTests/Services/NotificationOptOutTests.swift
  - drinkpulseTests/Services/ReminderServiceCancellationTests.swift
  - drinkpulseTests/Services/SlowNotificationCenter.swift
  - drinkpulseTests/Services/WeeklySummaryCompletedWeekTests.swift
  - drinkpulseTests/Services/WeeklySummaryCopyTests.swift
  - drinkpulseTests/Services/WeeklySummaryServiceCancellationTests.swift
  - drinkpulseUITests/Features/AddDrink/HealthWriteHooksUITests.swift
  - drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift
findings:
  critical: 0
  warning: 5
  info: 3
  total: 8
  necessity: 1
status: issues_found
---

# Phase 10: Code Review Report

**Reviewed:** 2026-11-10
**Depth:** standard
**Files Reviewed:** 33
**Status:** issues_found

## Summary

Phase 10 changes reviewed against `fbd37fa..HEAD`, plus real bugs found elsewhere in the listed files. No structural findings (fallow) were supplied; no external reviewer evidence was supplied. `necessity-review.md` was not loaded separately; the single necessity finding rests on repo-provable arithmetic.

The F3 epoch logic (Reminder and Weekly services), the F2 remove-by-query fix, the synchronous notification delegate assignment, and the notification tap routing are sound. I traced these interleavings: schedule held then cancel, schedule held then cancel then later schedule, two held schedules then cancel, cancel before schedule. All are correct. No critical issues.

The real defects are an asymmetry left by the F2 fix (update still trusts the cached sample UUID), a one-second gap in the week range the weekly summary relies on, silent fetch failure in the weekly summary, an over-broad store recovery trigger, and a test that touches shared on-disk state.

## Warnings

### WR-01: `performUpdate` can silently keep a stale Health sample (F2 fix applied only to remove)

**File:** `drinkpulse/Services/HealthService.swift:107-118`
**Issue:** `performRemoveSample` was fixed to resolve the current sample by `dp_event_uuid` because the cached `healthKitUUID` can be stale. `performUpdate` has the same flaw and was not fixed. It deletes only `event.healthKitUUID`, then calls `performWrite`, which does `sampleUUID(forEventUUID:)` and, if a sample exists, re-links it and returns without saving. Three paths leave the edited grams or date unwritten:
1. The cache is nil but a sample exists (an interrupted write that was later re-linked, a restored backup, or a CloudKit-synced event whose `healthKitUUID` is device-local). The delete is skipped, the existing sample is found, and the old grams and date stay in Health.
2. The cache is stale (it points at a replaced sample). The delete is a no-op on a non-existent object, the current sample is found and re-linked, and the old values stay.
3. `store.delete` throws. The error is logged, `healthKitUUID` is set to nil anyway, and `performWrite` re-links the undeleted old sample.

In all three cases the Health sample no longer matches the edited event, and nothing is surfaced.
**Fix:** Resolve the current sample by event UUID first, as `performRemoveSample` does. Only fall through to `performWrite` once the old sample is confirmed gone:
```swift
private func performUpdate(_ event: ConsumptionEvent) async {
    guard await isAuthorizedForWrite() else { return }
    do {
        var target = event.healthKitUUID
        if let current = try await store.sampleUUID(forEventUUID: event.uuid) { target = current }
        if let target { try await store.delete(uuid: target) }
        event.healthKitUUID = nil
    } catch {
        logger.error("Health update delete failed: \(error.localizedDescription)")
        return   // do not relink a sample that still holds the old values
    }
    await performWrite(event)
}
```
Add a regression test for the nil-cache and delete-throws cases.

### WR-02: Weekly summary week range leaves a 1-second gap; events in it are counted in no week

**File:** `drinkpulse/Services/WeeklySummaryService.swift:70-77, 106-111` (range from `drinkpulse/Features/Insights/InsightsPeriod.swift:37-47`)
**Issue:** `InsightsPeriod.week.dateRange` returns `start...(23:59:59 of day 7)`. The next week starts at 00:00:00. `fetchEvents` uses `>= start && <= end`, so an event logged in `(23:59:59.000, 24:00:00)`, which is sub-second and reachable because dates carry fractional seconds, matches neither week. `hasEvents(before: lastWeekRange.lowerBound)` has the same hole for the week before that. The summary then reports a wrong percentage or a wrong "none the week before it" claim. This is the phase's central "completed-week" feature, and the tests place events at `lowerBound` or noon, so none exercise the edge.
**Fix:** Query half-open intervals (`>= start && < nextWeekStart`). Derive the end from `calendar.dateInterval(of: .weekOfYear, ...)` / `weekInterval.end`, or make `dateRange` return `interval.end - 1ns`. Add a test with an event at `lastWeek.upperBound + 0.5s`.

### WR-03: Fetch failures are swallowed with `try?` and turn into wrong notification content or a silent cancel

**File:** `drinkpulse/Services/WeeklySummaryService.swift:110, 118`
**Issue:** A failed fetch returns `[]` / `0`. A transient SwiftData error therefore makes the calculator see "no alcohol in either week", which yields `.skip` and calls `cancel()`. This removes a valid pending summary. Or, if only some fetches fail, it produces a misleading health claim ("you logged no alcohol..."). `AGENTS.md` forbids `try?` swallowing without a comment explaining why the failure is ignorable, and a missing comment is the least of it here, because the failure is not ignorable.
**Fix:** Make `fetchEvents` / `hasEvents` `throws`. In `scheduleIfEnabled`, catch the error, log the error category (not values), and return without touching the pending request.

### WR-04: Store recovery runs for any open error and can collide or partially move files

**File:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift:37-43, 56-69`
**Issue:**
- (a) The recovery branch runs on any `ModelContainer` error: disk full, a transient I/O error, file protection, or a failed migration. A transient fault therefore moves the user's whole store aside and boots an empty app. After 3 such events `trimRecoveredStores` permanently deletes the oldest snapshot. Phase 10 adds `didRecover` reporting for tests but not for the user, who sees an empty store with no indication.
- (b) The snapshot directory name has one-second resolution. Two recoveries in the same second reuse the directory and may collide on `moveItem`.
- (c) If moving `-wal` or `-shm` throws after the main file has moved, the store is split across locations and the error propagates, leaving a main file without its WAL in the recovery snapshot.
- (d) If the `applicationSupportDirectory` lookup returns nil, `recoverStore` returns silently and the retry fails with the original error, which hides why.

This is partly pre-existing, but the phase touched this flow.
**Fix:** Only recover on errors that indicate an unreadable or unknown-model store (check the `SwiftDataError` / `NSCocoaErrorDomain` code), and rethrow otherwise. Add a UUID or sub-second suffix to the snapshot directory. Move all three files with rollback on failure. Surface a one-time "your previous data was moved aside" state to the UI.

### WR-05: `corruptedStore_reportsRecoveryAndOpensFresh` writes to the real Application Support and can race other suites

**File:** `drinkpulseTests/Domain/Persistence/MigrationChainV2V3Tests.swift:107-129`
**Issue:** The test drives `StoreBootstrap.recoverStore`, which uses `FileManager.default`'s real `applicationSupportDirectory/RecoveredStores`. It never cleans up. It also runs concurrently (Swift Testing parallelizes suites by default) with `StoreBootstrapTests`, which asserts counts in the same directory and calls `clearRecoveredStores()`, so it can flake. Each run also leaves a snapshot and can trigger `trimRecoveredStores`, which deletes real snapshots from the developer's simulator.
**Fix:** Make the recovery root injectable (for example `recoverStore(at:recoveryRoot:)` defaulting to Application Support) and point it at a temp directory in the test. Or put both suites in one `@Suite(.serialized)` and clean up the snapshot in a `defer`.

## Info

### IN-01: Redundant `cancelEpoch > myEpoch` guard and duplicated epoch logic

**File:** `drinkpulse/Services/ReminderService.swift:65`, `drinkpulse/Services/WeeklySummaryService.swift:98`
**Category:** necessity
**Issue:** `lifecycleEpoch` is incremented at the top of every schedule, so `lifecycleEpoch >= myEpoch` at the post-add check. `cancelEpoch` is only ever assigned from `lifecycleEpoch` at a cancel. So `cancelEpoch == lifecycleEpoch` means the latest lifecycle event was a cancel, and it must have come after this call's increment (a cancel before it would leave `lifecycleEpoch > cancelEpoch`). `cancelEpoch > myEpoch` is therefore always true when the first clause is true. Evidence is in `ReminderService.swift:57-65` and `WeeklySummaryService.swift:90-98`. The epoch pair and its comment block are also copy-pasted across the two services.
**Fix:** Drop the second clause, or keep it with a comment saying it is defensive. Consider a small shared `LifecycleEpoch` helper to avoid drift between the two copies.

### IN-02: Stale test name "knownIssueF2" asserts the fixed behavior

**File:** `drinkpulseTests/Services/HealthServiceConcurrencyTests.swift:52`
**Issue:** `removeQueuedBehindInFlightUpdate_leavesNoSample_knownIssueF2` is named like a known-failure pin, but the body and comment assert the fixed outcome. The suite doc comment also still says "plan 10-08 applies or retains it". Both mislead whoever reads a future failure.
**Fix:** Rename to `..._leavesNoSample_afterF2Fix` and update the doc comment.

### IN-03: `seedPendingOpenInsights` is not gated on `isActive`, unlike its sibling hook

**File:** `drinkpulse/UITestSeed.swift:24-30`, `drinkpulse/drinkpulseApp.swift:29-31`
**Issue:** `armWarmWeeklySummaryTap` correctly guards on `isActive`. `seedPendingOpenInsights` does not, and `drinkpulseApp.init` writes `pendingOpenInsights` to production `UserDefaults` whenever the launch argument is present. `AGENTS.md` requires test hooks to be gated, and `forceStoreFailure` / `deleteProfileMidSession` are only reached from `isActive` call sites, so this one is the odd one out. It is low risk (local launch arguments only) but inconsistent.
**Fix:** Add `guard isActive else { return false }` to `seedPendingOpenInsights`.

---

_Reviewed: 2026-11-10_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
