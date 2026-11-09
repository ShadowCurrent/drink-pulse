# F3 — Cancel while a notification schedule is in flight leaves a stale pending request

**Status:** decided by the owner; applied or retained by plan 10-09
**Proposed destination:** Phase 10, plan 10-09 (applied only after the owner records an Outcome below)

## Current behavior

Both notification services follow the same shape: remove the pending request, then await the notification center's `add`.

- `drinkpulse/Services/ReminderService.swift` — `schedule(hour:minute:)` calls `removePendingRequests`, then `try await center.add(...)`. `cancel()` only calls `removePendingRequests`. Because the service is `@MainActor`, `cancel()` can run while `schedule` is suspended inside `add`; the request then lands after the cancel and stays pending. `scheduleIfEnabled()` checks the opt-in default once, before it schedules, and never again.
- `drinkpulse/Services/WeeklySummaryService.swift` — `scheduleIfEnabled(context:)` checks the opt-in default, builds the content, then removes the pending request and awaits `center.add`. `cancel()` only removes the pending request. There is no re-check of the opt-in flag after `add` returns.

Evidence (both pinned by deterministic tests that use a lock-guarded `SlowNotificationCenter` whose first `add` suspends until released):

- `ReminderServiceCancellationTests.cancel_whileScheduleSuspendedInAdd_leavesNoPendingRequest` — records a known issue: after `cancel()` and the released `add`, `dp.daily.log.reminder` is still pending. With the known-issue wrapper removed locally, the test fails on `Expectation failed: pending.isEmpty`.
- `WeeklySummaryServiceCancellationTests.optOut_whileSceneActiveRescheduleSuspendedInAdd_leavesNoPendingRequest` — records a known issue: a scene-active reschedule suspended in `add` while the user opts out leaves `dp.weekly.summary` pending. This resolves research assumption A4 (the weekly service shares the race): A4 is confirmed, not falsified.
- Controls that pass unwrapped: cancel after a completed schedule leaves nothing pending and removes only the service's own identifier (both services); schedule, cancel, schedule leaves exactly one pending request (reminder); an opted-out `scheduleIfEnabled` never enters `add` (weekly).

Where the guards already exist and where they do not:

- `WeeklySummarySection` already protects the Settings enable path with a `toggleGeneration` check after `scheduleIfEnabled` returns; when the generation changed it calls `cancel()`. The Settings weekly path is therefore already covered.
- `ReminderSection.enable()` has no such guard. A toggle-off during the authorization await can be overwritten by `enabled = true` and a schedule. The system permission alert is modal, so the practical likelihood is low.
- The scene-active calls in `RootShellView` (`reminderService.scheduleIfEnabled()` and `weeklySummaryService.scheduleIfEnabled(context:)`) have no guard.

Practical window: `add` is a call to the system notification daemon, so the real race window is milliseconds. The pins use a deliberately suspended `add` to make the window deterministic. The owner should weigh the fix cost against a milliseconds-wide window; the user-visible harm is one notification the user opted out of, once, until the next cancel or reschedule.

## Source-backed decision table

**Availability:** The selected iOS 27 minimum satisfies the current API/toolchain availability described by the official sources below; no replacement or deprecation is claimed or inferred from age.

| Topic | Evidence |
| --- | --- |
| Official source | UserNotifications `UNUserNotificationCenter` add and remove pending requests: the iPhoneOS 27.2 SDK header `UserNotifications.framework/Headers/UNUserNotificationCenter.h` states that `addNotificationRequest:` replaces an existing request with the same identifier and that `removePendingNotificationRequestsWithIdentifiers:` removes requests waiting for their trigger. Swift concurrency actor reentrancy: the Swift migration guide on data-race safety and the language guide on actors (a `@MainActor` function resumed after an `await` may observe state changed by other work in between). Reached through the local SDK header read on 2026-11-08 because Xcode MCP `DocumentationSearch` was not connected in this execution environment; the Swift guides are cited from the Phase 08 C011 and C012 records. |
| Proposed behavior | Service-level lifecycle epoch (see Options). No actor, task-cancellation, or isolation rewrite. |
| Benefit | A cancel issued after a schedule began can no longer be overtaken by that schedule's `add`; user opt-out intent wins (C010, C012). |
| Cost | Low: two private counters per service, plus regression tests in plan 10-09 (stale schedule after cancel; the superseding-schedule timeline). |
| Alternatives | See Options and the rejected alternatives below. |
| Compatibility | No public API change; `schedule(hour:minute:)`, `scheduleIfEnabled`, and `cancel()` keep their signatures and call-site semantics. |
| Data / accessibility / lifecycle risk | No data risk and no accessibility effect. Lifecycle risk is low but real: it changes notification scheduling and cancellation ordering, which Phase 08 D-09 gates behind an owner decision. |

## Recommendation and proposed scope

Recommend `fix-service-epoch`: approve S1 and S2, defer S3, and retain O1.

Scope items (each separately approvable):

- **S1 — reminder service fix.** `ReminderService` gets the lifecycle epoch described below.
- **S2 — weekly service fix.** `WeeklySummaryService` gets the same epoch.
- **S3 — `ReminderSection` generation guard** mirroring `WeeklySummarySection`'s `toggleGeneration`. Not reproducible in a UI test: the permission prompt is modal and the fake center answers instantly. The existing `ReminderSettingsUITests` are the regression suite.
- **O1 (optional) — `NotificationActionHandler` as plain `Sendable`** instead of the `@unchecked Sendable` conformance. A compile probe shows plain `Sendable` builds warning-free. It is retained by the literal D-12 rule (the removal condition is an SDK change) unless the owner opts in.

### Options

- **`fix-service-epoch`** — S1 and S2. Each service keeps two private counters: a lifecycle epoch that every `schedule` or `scheduleIfEnabled` call and every `cancel` advances, and a cancel epoch that records the lifecycle value at the latest cancel. A schedule call keeps the value its own increment produced. After `add` returns, it removes its own identifier only when the cancel epoch equals the current lifecycle epoch and is greater than the kept value, meaning the latest lifecycle event is a cancel issued after the call began. A superseded schedule therefore never removes a request created by a later schedule. Preserves schedule semantics for callers that do not set the opt-in flag. No actor or task-cancellation rewrite.
- **`fix-service-epoch-plus-view-guard`** — S1, S2 and S3.
- **`retain`** — accept the milliseconds-wide window; keep both pins as known issues.
- **`defer`** — decide later; the race stays open and pinned.

Timeline showing why the epoch is compared with the current value and not only advanced by cancel (reminder service; the epoch values are the lifecycle counter):

1. Schedule A starts. Lifecycle epoch becomes 1; A keeps 1. A suspends in `add`.
2. `cancel()` runs. Lifecycle epoch becomes 2; cancel epoch becomes 2.
3. Schedule B starts. Lifecycle epoch becomes 3; B keeps 3. B's `add` completes; its request is pending.
4. A's `add` returns. Cancel epoch (2) is not equal to the current lifecycle epoch (3), so A does not remove anything, and B's request stays in place.

Without step 4's comparison, A would remove the identifier that B just created and silently lose the reminder. Plan 10-09 pins this timeline with a regression test that reads `SlowNotificationCenter.operationLog`.

### Alternatives considered and rejected

- **(a) Re-read the opt-in flag after `add`.** Rejected: `schedule(hour:minute:)` is called directly by tests and Settings code without the opt-in flag semantics, so the flag does not describe user intent for every caller.
- **(b) An epoch that only `cancel` advances.** Rejected: a stale schedule waking after a cancel and a newer schedule would remove the newer request that reuses the same identifier, silently losing the reminder.

## Owner decision record

**Outcome:** fix-service-epoch+handler-sendable
**Decision date:** 2026-11-09
**Exact scope:**
- S1 (ReminderService lifecycle epoch): applied
- S2 (WeeklySummaryService lifecycle epoch): applied
- S3 (ReminderSection generation guard): not applied
- O1 (NotificationActionHandler as plain Sendable): approved
**Owner reason:** Close the race at the service layer with the smallest change (owner chose the recommended option and opted in to O1 via the orchestrator's direct owner prompt on 2026-11-09).

No notification change has started. Plan 10-09 reads this record in its preconditions and changes no notification behavior until an Outcome is recorded here.
