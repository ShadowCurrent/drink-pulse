---
phase: "09"
slug: "swiftui-design-system-modernization"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-18"
---

# Phase 09 — Validation Strategy

> Per-phase validation contract for behavior-preserving SwiftUI modernization on iOS 27.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest/XCUITest in the checked-in unit and UI targets |
| **Config file** | `drinkpulse.xcodeproj/project.pbxproj`; file-system-synchronized targets need no build-phase registration for correctly placed Swift test files |
| **Quick run command** | `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" -only-testing:drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests -only-testing:drinkpulseUITests/Features/Shell/ShellNavigationUITests -only-testing:drinkpulseUITests/Features/Dashboard/DashboardUITests` |
| **Full suite command** | `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID"` |
| **Estimated runtime** | Environment-dependent; run scoped suites per task and the full suite only at the phase gate |

## Sampling Rate

- **After every task commit:** Run the scoped build and UI tests for the edited surface.
- **After every plan wave:** Run Debug and Release builds after the `DPArcProgress` repair, then the scoped Add Drink, Shell, and Dashboard suite.
- **Before `$gsd-verify-work`:** Run the full suite and record any remaining limitation truthfully.
- **Max feedback latency:** One scoped Xcode test invocation.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | MOD-02 | T-09-01 | `DPArcProgress` retains rendering/accessibility behavior while clearing the isolation diagnostic | Debug + Release build and Dashboard UI | Scoped Dashboard build/test command defined by PLAN.md | ✅ Dashboard UI suite | ⬜ pending |
| 09-02-01 | 02 | 2 | MOD-02 | T-09-02 | Add Drink cancel/save dismisses the sheet to the originating tab without unintended mutation | XCUITest + VoiceOver | Scoped Add Drink and Shell UI command | ✅ Existing suites; cases extended in Wave 0 | ⬜ pending |
| 09-03-01 | 03 | 3 | MOD-02 | T-09-03 | Protected History, chart, motion, and Liquid Glass behavior is retained unless fresh iOS 27 evidence justifies a local replacement | Existing UI tests + documented human checks | Targeted existing History/Insights tests selected by PLAN.md | ✅ Existing suites | ⬜ pending |

## Wave 0 Requirements

- [ ] Extend an existing Add Drink or Shell UI suite with separately named cancel and save return-to-originating-tab cases.
- [ ] Add one Xcode 27 `XCUIVoiceOverService` regression for the meaningful Add Drink dismissal flow while retaining semantic assertions.
- [ ] Confirm a Dashboard UI assertion exercises the arc's visible/accessibility outcome after the build repair; add one only if absent.
- [ ] Create retain-evidence notes from post-repair simulator and human observations for History, charts, motion, and Liquid Glass; no production change is a prerequisite.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Affected visual and accessibility behavior | MOD-02 | Simulator automation cannot fully establish visual quality, Dynamic Type through AX5, context-menu rendering, or Audio Graph output | After focused automated evidence passes, inspect the changed flow on iOS 27; record path, observation, protected behavior, and outcome. Verify VoiceOver labels/actions, AX5, and Reduce Motion whenever the changed view animates. |
| Retained History, Insights, motion, and Liquid Glass workarounds | MOD-02 | They must not be called obsolete without post-repair iOS 27 evidence | Record the exact path checked, iOS 27 observation, protected behavior, and why no replacement is justified. |

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] `nyquist_compliant: true` set after validation.

**Approval:** pending
