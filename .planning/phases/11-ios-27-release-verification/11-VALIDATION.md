---
phase: "11"
slug: "ios-27-release-verification"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| MOD-04 | 0 app-owned warnings, Debug and Release | build log scan | clean builds + `grep -cE '(\.swift:[0-9]+:[0-9]+: \|ld: \|clang: )warning:'` == 0 | n/a | ✅ green: Debug MCP 0 warnings on 3f70ff6; Release device-SDK CLI build of the final tree 0 gate warnings (D11-32, plan 11-23) |
| VER-01 | suites pass except named exceptions | unit + UI | full suite (plan 11-23: MCP `RunAllTests`, 888 tests on 3f70ff6) | ✅ | ✅ green with named exceptions: 866 passed, 4 failed (DL-T01..DL-T04, all known), 18 skipped by gate; coverage carried historically (D11-33) |
| VER-02 | core flows complete | UI | `-only-testing:` the VER-02 classes from 11-RESEARCH.md | ✅ | ✅ green with named limitations (L-01..L-09); every failure maps to the known list |
| VER-02 | import round trip (limitation: no UI test) | unit | `DataImporterRoundTripTests`, `ComprehensiveRoundTripTests`, `SanitizedBackupFixtureTests` | ✅ | ✅ green in the plan 11-23 full run (limitation L-01) |
| VER-02 | stored data survives migration | unit | `MigrationChainV1Tests`, `MigrationChainV2V3Tests`, `MigrationSweepTests`, `StoreBootstrapTests` | ✅ | ✅ green in the plan 11-23 full run |
| VER-03 | no unrecorded audit issue | UI | `-only-testing:drinkpulseUITests/AccessibilityAuditUITests` (gated, `DP_RUN_A11Y_AUDIT=1`) | ✅ | ✅ green: 16/16 with D11-29/30/31 opt-ins (plan 11-22); exemption breadth carried as debt DL-O25 |
| VER-03 | per-screen audit, all types (ungated) | UI | `{AddDrink,Dashboard,History,Insights,Onboarding,Settings}AccessibilityAuditUITests` | ✅ | ✅ green: cumulative 40/40 (plan 11-21) |
| VER-03 | AX5, VoiceOver, chart descriptors | UI + unit | `HistoryDynamicTypeUITests`, `ShellNavigationUITests`, `AlcoholAreaChartAXDescriptorTests`, `WeekdayBarChartAXDescriptorTests` | ✅ | ✅ green in the plan 11-23 full run |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift`: the audit test class
- [x] `11-A11Y-CHECKLIST.md`: the owner simulator checklist, starting with the VoiceOver/Audio Graph probe
- [x] `11-EVIDENCE.md`: the evidence skeleton (toolchain change row, destination, counts, log hashes)
- [x] the out-of-git log directory `~/Library/Logs/DrinkPulse/phase-11-ios27/<UTC stamp>`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Audio Graph rotor action on AlcoholAreaChart and WeekdayBarChart (05-UAT tests 5, 6) | VER-03 | `XCUIVoiceOverService` has no rotor API | 11-A11Y-CHECKLIST.md, iOS 27.2 simulator; "explicitly open" is allowed if the probe fails |
| Reduce Motion gating on both charts (05-UAT test 4) and on DPArcProgress, ConsumptionOverviewCard and HistoryCalendarView | VER-03 | Motion is judged visually | 11-A11Y-CHECKLIST.md |
| Increase Contrast, light/dark visual | VER-03 | Visual judgement | 11-A11Y-CHECKLIST.md |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 600s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-11-18 (validate-phase after gap closure 11-12..11-24). Manual-only items stay manual; their results live in 11-A11Y-CHECKLIST.md (open device items CHK-00/01/02/10 listed under VER-03).

## Validation Audit 2026-11-18

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
