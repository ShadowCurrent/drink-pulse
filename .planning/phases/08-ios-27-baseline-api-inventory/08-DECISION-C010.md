# C010 — Notification-center Sendable and delegate isolation

**Status:** owner outcome pending — not authorized  
**Proposed destination:** Phase 10

## Current behavior

`drinkpulse/Services/NotificationScheduling.swift:4-20` uses the unchecked conformance at :11; `NotificationActionHandler.swift:4-32` contains delegate conformance and main-actor hops at :4 and :16-23. Related locations are `ReminderService.swift:5-69`, `WeeklySummaryService.swift:6-132`, and `UITestNotificationCenter.swift:4-21`, with service tests listed in the detailed inventory. These preserve authorization, request cancellation, and cold/warm routing.

## Source-backed decision table

**Availability:** The selected iOS 27 minimum satisfies the current API/toolchain availability described by the official source below; no replacement is inferred from age alone.

| Topic | Evidence |
| --- | --- |
| Official source | [UNUserNotificationCenter](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter) and [Swift data-race safety guidance](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/dataracesafety/) (checked 2026-09-16). No deprecation/replacement is claimed. |
| Proposed behavior | Retain until an iOS 27 data-race diagnostic or reproducible problem identifies an exact safer isolation form. |
| Benefit | A proven rewrite could reduce a concrete concurrency issue; none is observed. |
| Cost | Actor/sendability design, authorization/scheduling/routing regression tests, and cold/warm device checks. |
| Alternatives | **Retain** the reviewed unchecked boundary and actor hops. |
| Compatibility | Current APIs and language mode are supported at iOS 27 / Swift 6.0. |
| Data / accessibility / lifecycle risk | Lifecycle/integration risk is high: changes can alter permission prompts, pending-request cancellation, delegate routing, and task timing. No stored data or direct accessibility change is intended. |

## Recommendation and proposed scope

Recommend retain pending proof. If later approved, scope only the diagnosed boundary and require the named notification regressions; do not introduce a broad concurrency rewrite.

## Owner decision record

**Outcome:** pending  
**Decision date:**  
**Exact scope:**  
**Owner reason:**
