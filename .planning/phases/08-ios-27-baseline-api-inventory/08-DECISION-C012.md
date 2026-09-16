# C012 — Swift 6.4 async cleanup and cancellation shields

**Status:** owner outcome pending — not authorized  
**Proposed destination:** Phase 10

## Current behavior

Potential task-lifetime locations are `drinkpulse/Services/HealthWriteHooks.swift:11-35`, `HealthService.swift:44-71,142-154`, `ReminderService.swift:51-68`, and `WeeklySummaryService.swift:55-90`. The current implementation has no reproduced interruption loss and does not need asynchronous cleanup to outlive cancellation.

## Source-backed decision table

**Availability:** The selected iOS 27 minimum satisfies the current API/toolchain availability described by the official source below; no replacement is inferred from age alone.

| Topic | Evidence |
| --- | --- |
| Official source | [Swift 6.4 release notes](https://www.swift.org/blog/swift-6.4-released/) (checked 2026-09-16) describe async `defer` and `withTaskCancellationShield` as cleanup tools, not required migrations. |
| Proposed behavior | Retain current task lifetimes unless an interruption/parallel-operation failure proves a narrowly bounded cleanup need. |
| Benefit | Could protect demonstrated cleanup from cancellation; no such loss is observed. |
| Cost | Failure reproduction, cancellation semantics design, notification/HealthKit lifecycle tests, and user-intent regression proof. |
| Alternatives | **Retain** current completion/cancellation behavior and synchronous cleanup. |
| Compatibility | Swift 6.4 compiler supports the features while the project correctly remains in Swift 6.0 language mode. |
| Data / accessibility / lifecycle risk | Shielding can prolong notification/Health work after user intent and alter lifecycle behavior; no direct data or accessibility benefit is established. |

## Recommendation and proposed scope

Recommend retain pending proof. If a later defect is approved, constrain scope to the one reproduced cleanup path and prove that cancellation still honors user intent.

## Owner decision record

**Outcome:** pending  
**Decision date:**  
**Exact scope:**  
**Owner reason:**
