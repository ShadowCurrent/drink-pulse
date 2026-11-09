# DEVICE-FINDING — Cold-launch notification tap does not route (INT-01, F6)

**Status:** decided by the owner; fix applied by a Phase 10 gap-closure plan
**Proposed destination:** a gap-closure plan in Phase 10, or Phase 11 if the owner prefers (owner picks in the decision record)

## Current behavior

Recorded by the owner on the real iPhone on 2026-11-09 (10-DEVICE-SESSION.md, Step 6), category and numbers only:

| Check | Result | Numbers |
| --- | --- | --- |
| Killed-app daily reminder tap | FAIL | taps 1, correct 0. The app opened on Dashboard instead of the Add Drink sheet. |
| Backgrounded-app daily reminder tap | PASS | taps 1, correct 1. |
| Weekly summary tap | N/A | No natural delivery observed. Routing is covered by automated tests only. |

The session stopped at the first failed cold tap (stop rule), so only one cold tap was recorded, not the three that F6 asked for. All data, migration and HealthKit checks (Steps 1 to 5) passed, and the detached cold-launch timing (Step 7) was near container-load time, so the launch-duration question (D-17) is closed separately and is unrelated to this finding.

Code path (read from the source, not traced on the device):

- `drinkpulse/drinkpulseApp.swift` `init()` calls `assignNotificationDelegate(_:)`, which creates a `Task.detached(priority: .userInitiated)`, resolves `UNUserNotificationCenter.current()` there and then hops to `MainActor.run { center.delegate = handler }`. The assignment therefore happens after `init()` returns, at an undefined later time.
- The SDK header `UNUserNotificationCenter.h:99` states for `didReceiveNotificationResponse`: "The delegate must be set before the application returns from application:didFinishLaunchingWithOptions:." (verified in the installed iOS SDK in this run).
- `NotificationActionHandler.route(identifier:)` sets `pendingAddDrink` or `pendingOpenInsights` and posts a tap notification. `RootShellView.onAppear` reads the pending flag, and a `.task` listens for the tap notification. If the delegate callback never runs on a cold launch, neither path fires and the app lands on Dashboard, which matches the observation.
- A warm or backgrounded app already has the delegate, which matches the passing backgrounded tap.

Hypothesis (unconfirmed by a device trace): the delegate is assigned too late on a cold launch from a notification, so the system drops or never delivers the response. A weaker second candidate is a narrow race where the tap notification is posted before the `.task` listener subscribes, but the pending flag set before `RootShellView.onAppear` would still cover that, so it does not explain a miss on its own.

Provenance:

- The detached-delegate hop was introduced in commit `ba4b326` on 2026-08-01 (todo "Defer UNUserNotificationCenter.current()", second candidate fix). That date is after the v1.1 tag (2026-07-21) in which cold-tap routing was device-verified, and after the v1.3 tag (2026-07-31). So this behavior is most likely pre-existing, introduced by that hop, not by Phase 10.
- Phase 10 did not change `drinkpulseApp.swift`. It did change two files on the path, behavior-preserving: `NotificationActionHandler.swift` (the delegate body extracted into `route(identifier:defaults:)`, plus `@unchecked Sendable` narrowed to `Sendable`) and `RootShellView.swift` (UI-test-only warm-tap arming). Without a pre-Phase-10 device run this cannot be excluded by measurement, only by the code diff.
- The cold-tap UI test passes because it drives the `UITestNotificationCenter` seam and does not exercise the system delivery timing, so automated coverage does not see this defect.
- The cold weekly-summary tap very likely shares the same cause (same delegate, same `route(identifier:)`), but it was not observed on the device.

Why the hop existed: it was added to remove a suspected launch stall from the first `UNUserNotificationCenter.current()` call. The D-17 measurement on the real device (detached, Home Screen launch) now shows container load 6 ms and Dashboard appeared 104 to 118 ms, which supports the earlier finding that the multi-second figure came from debugger-attached overhead and not from this call. The stall the hop was written to avoid was therefore not reproduced detached.

## Source-backed decision table

**Availability:** The iOS 27 minimum covers `UNUserNotificationCenter`, its `delegate` property and `didReceiveNotificationResponse`; no replacement or deprecation is claimed, and none is inferred from age. Official source: [UNUserNotificationCenterDelegate](https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate) and [UNUserNotificationCenter.delegate](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/delegate). Those pages were not re-fetched here (no Xcode MCP DocumentationSearch or web access in this agent). The statement of the timing requirement rests on the SDK header comment quoted above, read from the installed iOS SDK in this run, and on research note F6 in 10-RESEARCH.md.

| Topic | sync-assign (recommended) | confirm-first | retain-and-document | delegate-adaptor |
| --- | --- | --- | --- | --- |
| Proposed behavior | In `drinkpulseApp.init()`, assign `UNUserNotificationCenter.current().delegate` synchronously, so it is set before launch finishes. Keep the lazy-center fixes in the two services. Add a log-only, no-PII category line for the delegate callback so the next device run proves delivery. | Make no behavior change. Add the callback log line and a device log run to prove whether `didReceive` fires on a cold tap, then decide. | Change nothing. Record that a cold tap opens Dashboard, and keep the device result as a known limitation. | Move delegate assignment into an `@UIApplicationDelegateAdaptor` `didFinishLaunching`. |
| Benefit | Meets the documented requirement (delegate set before the app finishes launching). Smallest change that targets the observed failure. Restores the behavior that was device-verified in v1.1. | Turns the hypothesis into evidence before touching a launch path. | No risk to launch behavior. | Same documented timing, with a standard hook. |
| Cost | One synchronous `current()` call on the launch path, which the hop was written to avoid. The D-17 detached figure must be re-measured. A device re-test (at least three killed-app taps, plus a cold weekly tap) is needed because no automated test can prove system delivery timing. | A second owner device session before any fix lands, and one extra round trip. | INT-01 cold-tap routing stays broken on hardware, contradicting its stated behavior and Apple's documented requirement. Lost notification taps are user-visible. | Introduces UIKit (`UIApplicationDelegate`), which AGENTS.md allows only when unavoidable. A plain synchronous assignment avoids it, so it is not unavoidable. Larger change. |
| Alternatives | The three other options. | sync-assign afterwards. | None. | sync-assign. |
| Compatibility | `NotificationActionHandler`, `route(identifier:)`, pending flags and tap notifications unchanged. No schema, data, export or format change. CloudKit and HealthKit untouched. | None needed. | None needed. | Adds an app-delegate type. |
| Data / accessibility / lifecycle risk | No data risk. Lifecycle risk is on the launch path (a D-09 trigger, hence this brief). Directly restores a lost accessibility-relevant action, because the user cannot reach Add Drink from the reminder. | None. | The reminder's tap action stays unreliable. | Same as sync-assign plus a new lifecycle type. |

## Recommendation and proposed scope

Recommend **sync-assign**, with the confirmation folded into the same plan: the callback log line gives the evidence on the device run that verifies the fix, so a separate confirm-first round trip is not needed unless the owner wants proof before touching the launch path.

Proposed scope if approved (a new gap-closure plan, not executed under plan 10-12):

- one synchronous delegate assignment in `drinkpulseApp.init()`, with no other startup or lifecycle change;
- keep `ReminderService` and `WeeklySummaryService` lazy-center behavior as shipped;
- one log-only line for the delegate callback (category and identifier kind only, never user data);
- a device re-test: at least three killed-app daily-reminder taps and one backgrounded tap, then three detached cold-launch timings to confirm D-17 stays near;
- if a cold weekly-summary notification can be delivered, one cold weekly tap routed to Insights.

Not authorized by this brief: any change to `RootShellView`, the pending-flag or tap-notification design, `NotificationActionHandler`, schema, export format or CloudKit. The cold-launch todo is closed as not an app-code bug (launch duration); that closure does not cover this finding.

## Owner decision record

Allowed outcomes: sync-assign, confirm-first, retain-and-document, delegate-adaptor, or custom wording of the scope.

**Outcome:** sync-assign
**Decision date:** 2026-11-09
**Exact scope:** Assign `UNUserNotificationCenter.current().delegate` synchronously in `drinkpulseApp.init()` (remove the `Task.detached` hop), add a log-only line in the delegate `didReceive` callback, then re-test on the device: at least 3 killed-app reminder taps (expected: Add Drink sheet) plus 3 detached launch timings confirming D-17 stays near.
**Owner reason:** chose the recommended option (owner answered the orchestrator's direct owner prompt on 2026-11-09).
**Where the follow-up lands:** Phase 10 gap-closure plan
