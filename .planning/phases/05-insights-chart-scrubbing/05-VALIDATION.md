---
phase: 05
slug: insights-chart-scrubbing
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-30
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (`drinkpulseTests`) + XCUITest (`drinkpulseUITests`) — both already configured, `PBXFileSystemSynchronizedRootGroup`s |
| **Config file** | none — scheme-driven via `xcodebuild test -scheme drinkpulse` |
| **Quick run command** | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests/Features/Insights -only-testing:drinkpulseUITests/InsightsUITests` |
| **Full suite command** | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` |
| **Estimated runtime** | ~120 seconds (full suite; project baseline per Phase 04 VALIDATION.md) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (Insights unit + UI subset).
- **After every plan wave:** Full suite must be green.
- **Before `/gsd-verify-work`:** Full suite green; coverage ≥90% overall; CHART-04 manually verified with Reduce Motion on.
- **Max feedback latency:** ~60 seconds (quick run subset).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD (assigned at planning) | TBD | TBD | CHART-01 — drag shows touched-point callout | — | N/A | UI (XCUITest, `press(forDuration:thenDragTo:)`) | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseUITests/InsightsUITests` | ❌ Wave 0 | ⬜ pending |
| TBD (assigned at planning) | TBD | TBD | CHART-02 — hero headline follows touch, reverts on release | — | N/A | UI (XCUITest) + unit if selection logic is extracted | same as above | ❌ Wave 0 | ⬜ pending |
| TBD (assigned at planning) | TBD | TBD | CHART-03 — `accessibilityChartDescriptor` exposes every point without the drag gesture | — | N/A | unit (`AXChartDescriptorRepresentable.makeChartDescriptor()` output — dataPoints count/values match input) | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests/Features/Insights` | ❌ Wave 0 | ⬜ pending |
| TBD (assigned at planning) | TBD | TBD | CHART-04 — Reduce Motion suppresses callout appear/disappear transition | — | N/A | manual-only | N/A — not practically assertable via XCUITest (no visual-diff harness); see Manual-Only Verifications | N/A | ⬜ pending |

*Task IDs are TBD until `/gsd-planner` creates PLAN.md for this phase; the planner must map each row above onto a concrete task ID. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] New test methods in `drinkpulseUITests/Features/Insights/InsightsUITests.swift` covering CHART-01/CHART-02 (drag-to-scrub, hero total follows/reverts)
- [ ] New unit test files `drinkpulseTests/Features/Insights/AlcoholAreaChartAXDescriptorTests.swift` and `WeekdayBarChartAXDescriptorTests.swift` covering CHART-03
- [ ] No new shared fixtures needed — existing `InsightsDataGenerator.previewEvents(days:)` and the `-dp_uitest_dataset multiday` seed already provide multi-point data for both chart types

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Reduce Motion suppresses the scrub callout's appear/disappear transition | CHART-04 | SwiftUI `.transition`/`.animation` visual behavior under `reduceMotion` is not practically assertable via XCUITest (no visual-diff harness in this project; matches existing precedent — `OnboardingView`'s reduceMotion path also has no dedicated UI test) | Simulator/device: Settings → Accessibility → Motion → Reduce Motion ON. Scrub `AlcoholAreaChart` and `WeekdayBarChart`; confirm the callout appears/disappears with no slide/scale animation. Toggle OFF and confirm animated appearance returns. |
| VoiceOver announces per-point date + value for both charts without requiring a drag gesture | CHART-03 (supplements the automated descriptor-output unit test) | Actual audio-graph narration requires an interactive Accessibility Inspector / on-device VoiceOver session, not just descriptor-output assertions | Enable VoiceOver (Simulator Accessibility Inspector or real device). Navigate to Insights, activate each chart's Audio Graph rotor action, swipe through data points, confirm date+value narration matches the visible values in the user's display unit. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
