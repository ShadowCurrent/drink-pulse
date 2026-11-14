---
phase: "11"
slug: "ios-27-release-verification"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-14"
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (unit) and XCTest/XCUITest (UI), on Xcode 27.2 (27B52) with the iOS 27.2 SDK |
| **Config file** | `drinkpulse.xcodeproj/xcshareddata/xcschemes/drinkpulse.xcscheme` |
| **Quick run command** | Xcode MCP `RunSomeTests` (workspace resolved via `XcodeListWorkspaces`, destination iPhone 18 Pro iOS 27.2). CLI equivalent: `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" -only-testing:<Target>/<Class>` |
| **Full suite command** | One detached CLI `xcodebuild test ... -enableCodeCoverage YES -derivedDataPath build/` run (MCP cannot collect coverage) |
| **Estimated runtime** | ~1800 seconds full; ~60–600 seconds scoped |

---

## Sampling Rate

- **After every task commit:** run the touched or new test class with MCP `RunSomeTests`. Docs-only tasks run nothing.
- **After every plan wave:** run the VER-02 classes with MCP `RunSomeTests`.
- **Before `/gsd-verify-work`:** run the full suite once. Every failure must map to the named exception table in 11-CONTEXT.md, or to the unknown-failure protocol.
- **Max feedback latency:** 600 seconds (scoped).

---

## Per-Task Verification Map

To be filled by the planner/executor per plan task; requirement-to-test mapping below.

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| MOD-04 | 0 app-owned warnings, Debug and Release | build log scan | clean builds + `grep -cE '(\.swift:[0-9]+:[0-9]+: \|ld: \|clang: )warning:'` == 0 | n/a | ⬜ pending |
| VER-01 | suites pass except named exceptions | unit + UI | full CLI run + `xcrun xcresulttool get test-results summary` | ✅ | ⬜ pending |
| VER-02 | core flows complete | UI | `-only-testing:` the VER-02 classes from 11-RESEARCH.md | ✅ | ⬜ pending |
| VER-02 | import round trip (limitation: no UI test) | unit | `DataImporterRoundTripTests`, `ComprehensiveRoundTripTests`, `SanitizedBackupFixtureTests` | ✅ | ⬜ pending |
| VER-02 | stored data survives migration | unit | `MigrationChainV1Tests`, `MigrationChainV2V3Tests`, `MigrationSweepTests`, `StoreBootstrapTests` | ✅ | ⬜ pending |
| VER-03 | no unrecorded audit issue | UI | `-only-testing:drinkpulseUITests/AccessibilityAuditUITests` | ❌ W0 | ⬜ pending |
| VER-03 | AX5, VoiceOver, chart descriptors | UI + unit | `HistoryDynamicTypeUITests`, `ShellNavigationUITests`, `AlcoholAreaChartAXDescriptorTests`, `WeekdayBarChartAXDescriptorTests` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift`: the audit test class
- [ ] `11-A11Y-CHECKLIST.md`: the owner simulator checklist, starting with the VoiceOver/Audio Graph probe
- [ ] `11-EVIDENCE.md`: the evidence skeleton (toolchain change row, destination, counts, log hashes)
- [ ] the out-of-git log directory `~/Library/Logs/DrinkPulse/phase-11-ios27/<UTC stamp>`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Audio Graph rotor action on AlcoholAreaChart and WeekdayBarChart (05-UAT tests 5, 6) | VER-03 | `XCUIVoiceOverService` has no rotor API | 11-A11Y-CHECKLIST.md, iOS 27.2 simulator; "explicitly open" is allowed if the probe fails |
| Reduce Motion gating on both charts (05-UAT test 4) and on DPArcProgress, ConsumptionOverviewCard and HistoryCalendarView | VER-03 | Motion is judged visually | 11-A11Y-CHECKLIST.md |
| Increase Contrast, light/dark visual | VER-03 | Visual judgement | 11-A11Y-CHECKLIST.md |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 600s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
