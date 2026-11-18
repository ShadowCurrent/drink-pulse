# ADR-0013 — Accessibility: one Reduce Motion seam and an accessibility-size layout rule

**Status**: Accepted
**Date**: 2026-11-18
**Builds on**: Phase 11 verification, owner decisions D11-23 and D11-24 (`.planning/phases/11-ios-27-release-verification/11-CONTEXT.md`)

## Context

The Phase 11 accessibility verification on the iOS 27.2 simulator found two classes of defect that were not one-off bugs.

1. Three animations ignored the Reduce Motion setting: the Home overview bars, the History calendar detail area and the Home arc (owner decision D11-23). Each site had, or lacked, its own inline environment check.
2. Text was truncated, clipped or overlapping at the largest accessibility text size (AX5) on five screens: Home, Insights, Add Drink, Settings Preferences and Onboarding (owner decision D11-24).

Two constraints shaped the fix. `EnvironmentValues.accessibilityReduceMotion` is get-only, so a UI test cannot override it through the environment, and XCUITest has no API to switch Reduce Motion on. And XCUITest cannot observe an animation frame, so the behavior needs a test-visible signal that is not part of the production UI.

Official sources consulted through Xcode MCP `DocumentationSearch` (recorded in the "Apple API record" of the plan 11-14 and 11-16 summaries): SwiftUI `EnvironmentValues.accessibilityReduceMotion`, `View.animation(_:value:)`, `DynamicTypeSize.isAccessibilitySize`, `ScaledMetric`, `AnyLayout` with `HStackLayout` and `VStackLayout`, and `View.lineLimit(_:)`. All are used at the iOS 27.0 deployment target; the extracts carry no older-availability line, so no older-version claim is made.

## Decision

1. **One Reduce Motion decision seam.** Every app animation that must respect Reduce Motion is decided through `DPMotion.animation(_:reduceMotion:)`, fed by the `accessibilityReduceMotion` environment value. `DPMotion.isReduced(system:forced:)` is the single place that combines the system preference with the test override. The seam is unit tested (`DPMotionTests`).
2. **Test-only override and probe.** The override `-dp_uitest_reduce_motion` and the one point non-text `DPMotionProbe` elements (identifier `dp_motion.<site>`, label `reduced` or `animated`) exist only for UI tests. They are active only under `-dp_uitest` (`UITestSeed.isActive`) and never reach a production path; in production the override is always `false` and no probe element is rendered.
3. **Layouts adapt at accessibility sizes through one rule.** Layouts switch on `DynamicTypeSize.isAccessibilitySize`. Side by side at regular sizes and stacked at accessibility sizes is done with `DPAdaptiveStack` (an `AnyLayout` switching between `HStackLayout` and `VStackLayout`, the pattern `EventRow` already used), so subview state survives the switch. Fixed sizes use `ScaledMetric`. Text wraps instead of being limited to one line. A `dynamicTypeSize` range cap is never used to avoid a layout problem.
4. **Audit coverage.** Accessibility audit coverage is the ungated per-screen audit classes plus the gated full class `AccessibilityAuditUITests` (opt-in through `DP_RUN_A11Y_AUDIT`, run through the Xcode MCP). Every deviation from "the audit must find nothing" is an explicit, per-call, decision-scoped opt-in of the shared audit helper (D11-28, D11-29, D11-30, D11-31), logged as warnings; there is no allow-list.

## Consequences

### Positive
- A new animation has one obvious way to respect Reduce Motion, and the decision is unit tested once instead of at every site.
- Reduce Motion behavior is observable by UI tests without a device setting, so each gated site has a UI test.
- Accessibility-size layouts follow one reusable rule; the audit and the AX5 UI classes guard it.

### Negative / trade-offs
- Each gated animation site carries a probe element, which is test-only code in the view tree behind a launch-argument gate.
- XCUITest cannot observe an animation frame, so the visual behavior (and the Home arc, CHK-03 and OBS-D) stays an owner check on a simulator or device.
- Every new view must remember to use the seam and the layout rule; the audit classes catch layout regressions but not a forgotten animation gate.

### Alternatives considered
- **Repeat an inline environment check at each site** — rejected: it is how three sites went ungated, and it cannot be unit tested once.
- **Read `UIAccessibility.isReduceMotionEnabled` directly** — rejected: UIKit in a SwiftUI-only app, and it bypasses the SwiftUI environment the views already read.
- **Cap the Dynamic Type range** — rejected: it hides the problem from the users who need the largest sizes.
- **Allow-list audit findings** — rejected: a muted finding is an unverified defect (owner decision D11-22); narrow, documented, logged opt-ins replace it.
- **Hide the chart or content from accessibility to pass the audit** — rejected: it makes the audit green by removing the content from the people the audit protects.
