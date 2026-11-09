# Phase 10 Concurrency Record

## Purpose

This record documents the concurrency decisions made in Phase 10 for MOD-03 under decisions D-11 to D-13. It holds the D-12 disposition of every unchecked Sendable site, the one concurrency annotation change applied in plan 10-07 (the HealthKitAdapter qualifier), and the compile probe that justifies it. The per-candidate records for C010, C011 and C012 (plan 10-11) follow the compile probe; the Thread Sanitizer, build and full-suite evidence they cite is in `10-EVIDENCE.md`.

## D-12 unchecked Sendable dispositions

SDK headers were read from `iPhoneOS27.2.sdk` (Xcode 27.2, build 27B52) under `System/Library/Frameworks`.

| Site | SDK or source evidence | Probe or build result | Disposition |
|------|------------------------|-----------------------|-------------|
| Retroactive conformance `extension UNUserNotificationCenter: @retroactive @unchecked Sendable` (`drinkpulse/Services/NotificationScheduling.swift:11`) | `UserNotifications.framework/Headers/UNUserNotificationCenter.h:39` declares `@interface UNUserNotificationCenter : NSObject` with no `NS_SWIFT_SENDABLE` annotation and none appears in the file, so the SDK does not make the center Sendable. | Not probed: the SDK gives no basis to drop the qualifier. | Retain. The conformance is the only way to hand the shared center to the Sendable `NotificationScheduling` protocol. |
| `HealthKitAdapter` (`drinkpulse/Services/HealthKitAdapter.swift`) | `HealthKit.framework/Headers/HKHealthStore.h:36` has `NS_SWIFT_SENDABLE` directly above `@interface HKHealthStore : NSObject` (line 38). `HKObjectType.h:38` has `NS_SWIFT_SENDABLE` directly above `@interface HKObjectType : NSObject` (line 40), and `HKObjectType.h:175` above `@interface HKQuantityType : HKSampleType` (line 177). The remaining stored property `gramsPerStandardDrink` is a constant `Double`. | Applied; build and the Health suites pass with zero new warnings and no errors (see Compile probe). | Applied: qualifier removed, declaration is `final class HealthKitAdapter: HealthWriting`. |
| `NotificationActionHandler` (`drinkpulse/Services/NotificationActionHandler.swift:4`) | Source: an `NSObject` delegate with no stored properties; only static constants and static or async methods. A compile probe in research showed plain `Sendable` builds warning-free. | Applied in plan 10-09 under owner-approved O1 (10-DECISION-F3.md, 2026-11-09): xcodebuild of the app and test targets reported no Swift warning or error for the file; `NotificationActionHandlerTests` and the notification suites pass (43 tests in 7 suites). | Applied: qualifier removed, declaration is `final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate, Sendable`. |
| `UITestNotificationCenter` and `UITestHealthStore` (`drinkpulse/Services/UITestNotificationCenter.swift:4`, `UITestHealthStore.swift:3`) | Source: launch-argument test doubles with mutable state, used only when `UITestSeed.isActive`. | Not probed. | Retain. Test-only mutable state with no production use. |
| `FakeNotificationCenter` and `CallCounter` (`drinkpulseTests/Services/ReminderServiceTests.swift:6` and `:38`) | Source: test doubles with mutable recorded state. | Not probed. | Retain. Test-only mutable state with no production use. |
| `FakeHealthStore` (`drinkpulseTests/Services/FakeHealthStore.swift:4`) | Source: test double with mutable counters and a sample map. | Not probed. | Retain. Test-only mutable state with no production use. |

The plan 10-07 `RecordingHealthStore` (private to `HealthServiceOrderingTests.swift`) is a new test-only double that carries `@unchecked Sendable` with its log guarded by `OSAllocatedUnfairLock`; it follows the same retain rule as `FakeHealthStore`.

## Applied changes (D-13)

### HealthKitAdapter: unchecked Sendable qualifier removed (plan 10-07, MOD-03)

- **Change:** `final class HealthKitAdapter: HealthWriting, @unchecked Sendable` became `final class HealthKitAdapter: HealthWriting`.
- **Isolation and lifecycle reasoning:** `HealthWriting` refines `Sendable`, so the compiler now verifies the conformance instead of trusting it. The class stores `private let store = HKHealthStore()`, `private let alcoholType = HKQuantityType(.numberOfAlcoholicBeverages)` and `private let gramsPerStandardDrink = 14.0`. All three are immutable `let` properties; the first two are SDK types marked `NS_SWIFT_SENDABLE` and the third is a `Double`. No actor isolation, task structure, lifecycle or behavior changes. D-12 explicitly permits this removal when the SDK makes the type Sendable, the build stays warning-free and behavior is unchanged, so no D-10 diagnostic was required. The app target also builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (project build settings), which the compiler applies to declarations in that module; the compile probe below is the evidence, not this setting.
- **Official source and how it was reached:** the Xcode MCP `DocumentationSearch` tool is not exposed to this executor, and the session had no network documentation route, so the primary source consulted was the Apple SDK headers shipped with Xcode 27.2 (`iPhoneOS27.2.sdk`, `HealthKit.framework/Headers/HKHealthStore.h` lines 36 to 38 and `HKObjectType.h` lines 38 to 40 and 175 to 177), found by `grep -n NS_SWIFT_SENDABLE` over those headers. Apple documentation for `Sendable` and `HKHealthStore` was not re-read online; the owner may wish to cross-check it.
- **API availability at iOS 27:** `HKHealthStore` is declared `API_AVAILABLE(ios(8.0), ...)` in the same header; the project minimum is iOS 27.0, so the annotations apply to every supported OS. `NS_SWIFT_SENDABLE` is a compile-time Swift import annotation, not a runtime API.
- **Regression evidence:** scoped run of `HealthServiceTests`, `HealthServiceRemoveSampleTests`, `HealthWriteHooksTests` and `HealthServiceOrderingTests` plus the notification suites on the iOS 27.0 simulator: 72 tests in 8 suites passed, zero Swift warnings or errors in the build log (`build/p10-07-all.log`).

### HealthWriteHooksTests: redundant `try` removed

The leading `try` on `await withWriteEnabled(true)` in `remove_invokesService_whenEnabled` (line 116) was redundant (`withWriteEnabled` rethrows and that closure does not throw) and produced `warning: no calls to throwing functions occur within 'try' expression`. It was removed; no other line of the file changed, and the warning no longer appears in the build log.

## Compile probe

- **Command:** `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID_P10_07" -derivedDataPath build/p10-07 -only-testing:drinkpulseTests/HealthServiceOrderingTests -only-testing:drinkpulseTests/HealthServiceTests -only-testing:drinkpulseTests/HealthServiceRemoveSampleTests -only-testing:drinkpulseTests/HealthWriteHooksTests -only-testing:drinkpulseTests/NotificationOptOutTests -only-testing:drinkpulseTests/ReminderServiceTests -only-testing:drinkpulseTests/WeeklySummaryServiceTests -only-testing:drinkpulseTests/WeeklySummaryServiceScheduleTests`. The test action compiles the app target (including `HealthKitAdapter.swift`, confirmed by a `SwiftCompile ... HealthKitAdapter.swift` entry in the log) before running the suites. A separate `xcodebuild build` invocation was not run, to limit load on a shared machine.
- **Date:** 2026-11-09.
- **Destination:** iPhone 18 Pro simulator, iOS 27.0 runtime, Xcode 27.2 (27B52), Swift 6.4.2.
- **Result:** zero new warnings and no errors in the build log for `HealthKitAdapter.swift` or any other Swift file; `** TEST SUCCEEDED **`, 72 tests in 8 suites passed.

## C010

### Candidate scope

Notification-center Sendable and delegate isolation (`08-DECISION-C010.md`): the `UNUserNotificationCenter` retroactive unchecked conformance, `NotificationActionHandler`, and the cancel and schedule paths in `ReminderService` and `WeeklySummaryService`, with only diagnosed boundaries eligible and no broad actor or cancellation rewrite.

### Evidence checked

- **Compiler diagnostics:** none for the notification files at HEAD. The research build log showed none, and the clean build-for-testing gate in `10-EVIDENCE.md` (section Zero-warning build) reports no Swift, linker or compiler warning.
- **Thread Sanitizer:** after a canary proved activation in the same run, the scoped pass over `ReminderServiceTests`, `ReminderServiceCancellationTests`, `WeeklySummaryServiceTests`, `WeeklySummaryServiceScheduleTests`, `WeeklySummaryServiceCancellationTests`, `WeeklySummaryCompletedWeekTests`, `WeeklySummaryCopyTests`, `NotificationOptOutTests` and `NotificationActionHandlerTests` reported no sanitizer finding (`10-EVIDENCE.md`, section Thread Sanitizer).
- **Interruption and parallel-operation tests:** the F3 pins drive a lock-guarded `SlowNotificationCenter` whose first `add` suspends. `ReminderServiceCancellationTests.cancel_whileScheduleSuspendedInAdd_leavesNoPendingRequest` and `WeeklySummaryServiceCancellationTests.optOut_whileSceneActiveRescheduleSuspendedInAdd_leavesNoPendingRequest` reproduced the stale pending request (research assumption A4 confirmed) and are now plain regression tests. `scheduleHeld_thenCancel_thenLaterSchedule_keepsLaterRequest` (both services) proves a stale schedule does not remove a later schedule's request, and `ReminderServiceCancellationTests.scheduleHeld_thenLaterSchedule_keepsLaterRequest` covers schedule-then-schedule supersession. `NotificationOptOutTests` prove each service removes only its own identifier and that an opted-out `scheduleIfEnabled` adds nothing. `NotificationActionHandlerTests` pin `route(identifier:defaults:)` for the reminder, weekly and unknown identifiers.

### Isolation and lifecycle reasoning

Both services are `@MainActor`, so reentrancy happens only at the `await` inside `center.add`. `cancel()` and the epoch counters run synchronously on the same actor, so the post-add comparison cannot race. The fix (owner outcome `fix-service-epoch+handler-sendable`, `10-DECISION-F3.md`, 2026-11-09; S1 and S2 applied, S3 not applied, O1 approved) adds two private counters per service: a lifecycle epoch advanced by every schedule and cancel, and a cancel epoch holding the lifecycle value at the latest cancel. A schedule removes its own identifier after `add` only when the latest lifecycle event is a cancel issued after it began, so a superseded schedule never removes a later schedule's request. With no cancel during `add` the code is a no-op, so uncontested behavior is unchanged. No actor, task-cancellation or public API change. `NotificationActionHandler` has no stored properties, so plain `Sendable` (O1) is verified by the compiler instead of trusted. The retroactive `UNUserNotificationCenter` conformance is unchanged because the SDK does not mark the type Sendable; its disposition is in the D-12 table.

### Official source consulted

`UserNotifications.framework/Headers/UNUserNotificationCenter.h` in the iPhoneOS 27.2 SDK (Xcode 27.2): `addNotificationRequest:withCompletionHandler:` "will replace an existing notification request with the same identifier" (line 62) and `removePendingNotificationRequestsWithIdentifiers:` (line 69). The class and delegate protocol are `API_AVAILABLE(... ios(10.0) ...)`, so they are available at the iOS 27.0 minimum, and no deprecation or replacement is claimed. The Xcode MCP `DocumentationSearch` tool is not exposed to the executing agents, so the header was the route; the developer.apple.com pages cited in `08-DECISION-C010.md` and `10-DECISION-F3.md` were not re-fetched in this plan.

### Regression evidence

`ReminderServiceCancellationTests`, `WeeklySummaryServiceCancellationTests`, `NotificationOptOutTests`, `NotificationActionHandlerTests`, `ReminderServiceTests`, `WeeklySummaryServiceTests` and `WeeklySummaryServiceScheduleTests`. Plan 10-09 recorded 22 tests in 3 suites (reminder) and 43 tests in 7 suites (weekly, reminder cancellation, opt-out, handler) passing, plus 7 UI tests with 0 failures; plan 10-11 re-ran them under the sanitizer and in the full suite (`10-EVIDENCE.md`).

### Disposition

Disposition: applied narrow fix. Owner decision `fix-service-epoch+handler-sendable` of 2026-11-09 (S1, S2 and O1 applied; S3, the `ReminderSection` generation guard, not applied).

## C011

### Candidate scope

HealthKit concurrency, identity and serial execution (`08-DECISION-C011.md`): `HealthKitAdapter`, `HealthService` with its per-event `runSerial` chain, `HealthWriteHooks`, `HealthWriting` and the UI-test store, with every ADR-0011 invariant preserved and no generic HealthKit modernization.

### Evidence checked

- **Compiler diagnostics:** none for the Health files at HEAD. The qualifier removal in plan 10-07 was probed by a build with zero new warnings (Compile probe above), and the clean build-for-testing gate in `10-EVIDENCE.md` reports no warning.
- **Thread Sanitizer:** after the canary proved activation, the scoped pass over `HealthServiceTests`, `HealthServiceRemoveSampleTests`, `HealthServiceConcurrencyTests`, `HealthServiceOrderingTests` and `HealthWriteHooksTests` reported no sanitizer finding (`10-EVIDENCE.md`).
- **Interruption and parallel-operation tests:** `HealthServiceOrderingTests` pin per-event order (`writeUpdateRemove_executeInEnqueueOrder_forOneEvent`), the idempotent double write (`doubleWrite_savesOneSample_andRelinksSecondCall`), independent chains for different events (`operationsOnDifferentEvents_doNotShareAChain`) and an interrupted write that saved but did not cache (`interruptedWrite_savedButNotCached_relinksOnNextBackfill_noDuplicate`). `HealthServiceConcurrencyTests` reproduced the F2 orphan with `removeQueuedBehindInFlightUpdate_leavesNoSample_knownIssueF2` against the control `updateThenRemove_awaitedSequentially_leavesNoSample`.

### Isolation and lifecycle reasoning

`HealthService` is `@MainActor`, and `performRemoveSample` runs inside the existing `runSerial` per-event chain. The F2 defect was a stale captured `healthKitUUID`: a queued update replaces the sample before the serialized remove runs, so the remove deleted the already-deleted old sample. The fix (owner outcome `fix-query-first`, `10-DECISION-F2.md`, 2026-11-09, applied in plan 10-08) adds one awaited store lookup by `dp_event_uuid` inside the already-serialized remove and uses the captured UUID only when the lookup returns nothing or throws. No actor, Task or cancellation structure changed; `runSerial`, signatures, `performWrite`, `performUpdate`, `backfill` and authorization are untouched; delete stays non-blocking, `dp_event_uuid` stays the source of truth, `healthKitUUID` stays device-local and unexported, and opt-in is unchanged. The `HealthKitAdapter` qualifier removal (plan 10-07) is explained in Applied changes: its stored properties are immutable `let` values of `NS_SWIFT_SENDABLE` SDK types and a `Double`.

### Official source consulted

`HealthKit.framework/Headers/HKHealthStore.h` in the iPhoneOS 27.2 SDK: `NS_SWIFT_SENDABLE` on `HKHealthStore` (line 36), `deleteObjects:withCompletion:` and `deleteObjectsOfType:predicate:withCompletion:` with "An application may only delete objects that it previously saved" (lines 194 to 207), `API_AVAILABLE(ios(9.0) ...)` on both, and the class `API_AVAILABLE(ios(8.0) ...)` (line 37), so all are available at the iOS 27.0 minimum. No deprecation or replacement is claimed. `DocumentationSearch` was not exposed to the executing agents, so the SDK headers were the route; the developer.apple.com pages cited in the decision records were not re-fetched in this plan. The real-device behavior of deleting an already-deleted sample (assumption A5) is a plan 10-12 device check.

### Regression evidence

`HealthServiceConcurrencyTests` (F2 pin flipped to a plain test, plus `removeSample_deletesStoredSample_whenCapturedUUIDIsStale`, `removeSample_fallsBackToCapturedUUID_whenQueryFindsNoSample`, `removeSample_fallsBackToCapturedUUID_whenQueryThrows`), `HealthServiceOrderingTests`, `HealthServiceRemoveSampleTests`, `HealthServiceTests`, `HealthWriteHooksTests` and the UI test `HealthWriteHooksUITests.test_healthEnabled_logEditDelete_leavesNoHealthSample`. Plan 10-08 recorded 43 tests in 5 suites and 6 UI tests with 0 failures; plan 10-11 re-ran the unit suites under the sanitizer and in the full suite (`10-EVIDENCE.md`).

### Disposition

Disposition: applied narrow fix. Owner decision `fix-query-first` of 2026-11-09 for the F2 orphan sample (plan 10-08), plus the plan 10-07 `HealthKitAdapter` unchecked qualifier removal (D-12). Per-event serialization and ordering are unchanged.

## C012

### Candidate scope

Swift 6.4 async cleanup and cancellation shields (`08-DECISION-C012.md`): task lifetimes in `HealthWriteHooks`, `HealthService`, `ReminderService` and `WeeklySummaryService`, with only a single reproduced cleanup or cancellation path eligible and no extension of work beyond user intent.

### Evidence checked

- **Compiler diagnostics:** none; no code path uses async `defer` or `withTaskCancellationShield`, and the clean build gate reports no warning (`10-EVIDENCE.md`).
- **Thread Sanitizer:** the scoped pass over the Health and notification suites listed for C010 and C011 reported no sanitizer finding after a proven-active canary.
- **Interruption and parallel-operation tests:** `HealthServiceOrderingTests.interruptedWrite_savedButNotCached_relinksOnNextBackfill_noDuplicate` shows an interrupted write loses nothing durable (the next backfill relinks by `dp_event_uuid`, no duplicate). The two F3 cancel-in-flight pins and the supersession tests show a cancel issued during an in-flight schedule wins and a superseded schedule never removes a later request.

### Isolation and lifecycle reasoning

No failing test requires Swift 6.4 async `defer` or task-cancellation shielding. The Health work is best-effort and its durable identity is the `dp_event_uuid` metadata, so an interrupted operation is repaired by the next backfill instead of needing cleanup that outlives cancellation. The only reproduced cancel-related defect (F3) was a lost user intent, not lost cleanup. It is handled by the service lifecycle epoch, which compares counters after `add` returns and never cancels or shields a `Task`: the cancel-in-flight and superseded-schedule cases are decided by a synchronous check on the main actor. Shielding would prolong notification or Health work after the user's intent, which the owner scope for C012 forbids, so current task lifetimes are kept.

### Official source consulted

The Swift 6.4 release announcement (`https://www.swift.org/blog/swift-6.4-released/`) cited in `08-DECISION-C012.md` (checked 2026-09-16) describes async `defer` and `withTaskCancellationShield` as cleanup tools, not required migrations. The toolchain here is Swift 6.4.2 (Xcode 27.2) with the project in Swift 6.0 language mode. This is a compiler and language feature with no OS availability gate. The page was not re-fetched in this plan (no documentation tool exposed to the executing agents); no replacement or deprecation is claimed.

### Regression evidence

`HealthServiceOrderingTests`, `HealthServiceConcurrencyTests`, `ReminderServiceCancellationTests` and `WeeklySummaryServiceCancellationTests` (names under C010 and C011), run under the sanitizer and in the full suite (`10-EVIDENCE.md`).

### Disposition

Disposition: retain. Current task lifetimes and synchronous cleanup are kept; no diagnostic or failing test needs async cleanup or shielding. The lifecycle epoch (an applied narrow fix recorded under C010) handles cancel-in-flight and superseded schedules without any `Task` cancellation.
