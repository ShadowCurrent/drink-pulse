# C007 — Additive Xcode 27 VoiceOver UI-test capability

**Status:** owner outcome pending — not authorized  
**Proposed destination:** Phase 11

## Current behavior

Current XCTest UI tests use `XCUIApplication`, semantic element queries, seeded launch arguments, and waits. Representative exact locations are `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift:13-26,88-132`, `WrongRowContextMenuTargetUITests.swift:26-83`, `Features/Insights/InsightsUITests.swift:74-89`, and `Features/Onboarding/OnboardingFlowUITests.swift:8-105`. No `XCUIVoiceOverService` use exists.

## Source-backed decision table

**Availability:** The selected iOS 27 minimum satisfies the current API/toolchain availability described by the official source below; no replacement is inferred from age alone.

| Topic | Evidence |
| --- | --- |
| Official source | [Xcode 27 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes) (checked 2026-09-16) is the capability-discovery source for `XCUIVoiceOverService`; Xcode 27 is selected. |
| Proposed behavior | Evaluate additive deterministic VoiceOver regression coverage without replacing semantic UI tests. |
| Benefit | Could make focused accessibility regressions more deterministic. |
| Cost | New test design, simulator capability validation, and no-green-claim baseline rerun after compilation succeeds. |
| Alternatives | **Retain** current semantic UI tests and Phase 11 human VoiceOver checks. |
| Compatibility | Toolchain capability depends on the selected Xcode 27; current XCTest APIs are not deprecated. |
| Data / accessibility / lifecycle risk | No data/lifecycle change; an incomplete test can create false accessibility confidence or displace existing behavior coverage. |

## Recommendation and proposed scope

Recommend a narrowly additive evaluation only after the build works: prove one representative VoiceOver regression without removing current assertions. The newer tool capability alone is not authorization.

## Owner decision record

**Outcome:** pending  
**Decision date:**  
**Exact scope:**  
**Owner reason:**
