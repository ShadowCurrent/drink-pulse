# Phase 10 Concurrency Record

## Purpose

This record documents the concurrency decisions made in Phase 10 for MOD-03 under decisions D-11 to D-13. It holds the D-12 disposition of every unchecked Sendable site, the one concurrency annotation change applied in plan 10-07 (the HealthKitAdapter qualifier), and the compile probe that justifies it. The per-candidate records for C010, C011 and C012 are completed in plan 10-11.

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

Per-candidate record completed in plan 10-11.

## C011

Per-candidate record completed in plan 10-11.

## C012

Per-candidate record completed in plan 10-11.
