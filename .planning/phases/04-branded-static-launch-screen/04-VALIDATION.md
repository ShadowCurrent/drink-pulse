---
phase: 04
slug: branded-static-launch-screen
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-28
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest / XCUITest (existing project convention — see `drinkpulseUITests/Features/Shell/StartupErrorUITests.swift` for the established pattern of asserting app-rendered English strings, never system-process UI) |
| **Config file** | none — driven by the `drinkpulse` scheme |
| **Quick run command** | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseUITests` |
| **Full suite command** | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** N/A for the pre-process launch screen itself (no automatable assertion exists); run `-only-testing:drinkpulseUITests` to confirm no regression to normal app launch.
- **After every plan wave:** Full suite green, plus a manual real-device force-quit cold-launch check.
- **Before `/gsd-verify-work`:** Full suite must be green; Success Criteria #1–#3 verified manually on a real device (structurally unautomatable — see below).
- **Max feedback latency:** 120 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | LAUNCH-01 (SC#2: static image only, no animation/wordmark) | — | N/A | config-review | Reviewable directly from the `project.pbxproj` diff / Info.plist content — no runtime test possible | ✅ | ⬜ pending |
| 04-01-02 | 01 | 1 | LAUNCH-01 (SC#3: no visible flash at handoff) | — | N/A | UI (proxy) | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseUITests` — asserts first live frame appears within timeout; cannot assert pixel-level color continuity across the pre-process boundary | ✅ | ⬜ pending |
| 04-01-03 | 01 | 1 | LAUNCH-01 (SC#1: real branded launch screen on cold launch) | — | N/A | manual-only | N/A — XCUITest attaches only after the process starts, structurally after the launch screen has already rendered and handed off | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*None: existing `drinkpulseUITests` infrastructure covers all phase requirements for indirect/proxy regression coverage. No new test framework or fixture is required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cold launch shows branded icon + matching background, no blank/spinner/text | LAUNCH-01 (SC#1, SC#2) | The real launch screen is pre-process UIKit/Info.plist rendering; XCUITest only attaches after the app process starts — after the launch screen has already rendered and handed off. No in-process test can observe it. | Force-quit the app on a real device (not simulator), then cold-launch it. Visually confirm: app icon centered at Home Screen icon size, background matches `Color(.systemBackground)` (white in light mode / black in dark mode), no text, no spinner, no animation. |
| No visible color/flash mismatch at handoff into first live frame | LAUNCH-01 (SC#3) | Pixel-level color continuity across the pre-process → in-process boundary cannot be asserted by any in-process test. | On the same real-device cold launch, watch the transition from launch screen into onboarding/Dashboard — confirm no flash or color jump. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies (config-review + UI-proxy tasks are automated; SC#1/#3 are explicitly manual-only per above)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none — N/A)
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
