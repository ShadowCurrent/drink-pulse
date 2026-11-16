---
phase: 11-ios-27-release-verification
verified: 2026-11-16T13:38:45Z
status: gaps_found
score: 17/28 truths verified (4 failed, 6 uncertain, 1 present but behavior unverified)
covered_files: [".planning/phases/11-ios-27-release-verification/11-01-PLAN.md", ".planning/phases/11-ios-27-release-verification/11-01-SUMMARY.md", ".planning/phases/11-ios-27-release-verification/11-02-PLAN.md", ".planning/phases/11-ios-27-release-verification/11-02-SUMMARY.md", ".planning/phases/11-ios-27-release-verification/11-03-PLAN.md", ".planning/phases/11-ios-27-release-verification/11-03-SUMMARY.md", ".planning/phases/11-ios-27-release-verification/11-04-PLAN.md", ".planning/phases/11-ios-27-release-verification/11-04-SUMMARY.md", ".planning/phases/11-ios-27-release-verification/11-05-PLAN.md", ".planning/phases/11-ios-27-release-verification/11-05-SUMMARY.md", ".planning/phases/11-ios-27-release-verification/11-06-PLAN.md", ".planning/phases/11-ios-27-release-verification/11-06-SUMMARY.md", ".planning/phases/11-ios-27-release-verification/11-07-PLAN.md", ".planning/phases/11-ios-27-release-verification/11-07-SUMMARY.md", ".planning/phases/11-ios-27-release-verification/11-08-PLAN.md", ".planning/phases/11-ios-27-release-verification/11-08-SUMMARY.md", ".planning/phases/11-ios-27-release-verification/11-09-PLAN.md", ".planning/phases/11-ios-27-release-verification/11-09-SUMMARY.md", ".planning/phases/11-ios-27-release-verification/11-10-PLAN.md", ".planning/phases/11-ios-27-release-verification/11-10-SUMMARY.md", ".planning/phases/11-ios-27-release-verification/11-11-PLAN.md", ".planning/phases/11-ios-27-release-verification/11-11-SUMMARY.md", ".planning/phases/11-ios-27-release-verification/11-A11Y-CHECKLIST.md", ".planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md", ".planning/phases/11-ios-27-release-verification/11-DISCOVERIES.md", ".planning/phases/11-ios-27-release-verification/11-EVIDENCE.md", ".planning/phases/11-ios-27-release-verification/11-REVIEW.md", "drinkpulse/Info.plist", "drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift"]
covered_digest: "v4:sha256:7b368a808ce3e30cc6d72f578a25e438dab429a5c5a72d8615e57e6e7f3c13a8"
behavior_unverified: 1
overrides_applied: 0
gaps:
  - truth: "Reduce Motion is honored by every animation the owner flagged on Home and in History (VER-03, CHK-05 and CHK-06; CHK-04 open)"
    status: failed
    reason: "Owner observed the Home overview card progress bar and the History calendar detail area animate with Reduce Motion on. Source confirms neither animation reads accessibilityReduceMotion. DPArcProgress is also ungated (CHK-04 open because the sheet covered it)."
    artifacts:
      - path: "drinkpulse/Features/Dashboard/Components/ConsumptionOverviewCard.swift"
        issue: "Line 110: .animation(hasSettledOnce ? .easeOut(duration: 0.5) : nil, value: pctClamped) with no Reduce Motion check"
      - path: "drinkpulse/Features/History/Components/HistoryCalendarView.swift"
        issue: "Line 61: .animation(.easeInOut(duration: 0.25), value: selectedDay) with no Reduce Motion check"
      - path: "drinkpulse/DesignSystem/DPArcProgress.swift"
        issue: "Line 18: .animation(hasSettledOnce ? .easeOut(duration: 0.4) : nil, value: pct) with no Reduce Motion check (CHK-04 still open)"
    missing:
      - "Owner decision on briefs 11-DECISION-C014.md and 11-DECISION-C015.md (decision pending)"
      - "Gate the three animations on accessibilityReduceMotion as the owner decides, following the existing pattern in WeekdayBarChart and AlcoholAreaChart"
      - "A UI test for each user-facing change (AGENTS.md mandatory UI-test rule)"
      - "Re-run CHK-04, CHK-05 and CHK-06 on the simulator with the owner, with Reduce Motion on and off"
  - truth: "Dynamic Type through AX5 shows no truncated, clipped or overlapping text on the affected flows (VER-03, CHK-07)"
    status: failed
    reason: "Owner observed truncation, clipping or overlap at AX5 on Home, Insights, Add Drink (steps 1 and 2), Settings Preferences and Onboarding. Guideline picker and History were fine. The automated AX5 coverage is part of the red audit and does not clear this."
    artifacts:
      - path: "drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift"
        issue: "Owner watch point: fixed-height area chart with small axis labels at AX5 (CHK-07 source note)"
      - path: "drinkpulse/Features/Dashboard"
        issue: "Home card text clipped or truncated at AX5 (brief 11-DECISION-C016.md)"
      - path: "drinkpulse/Features/AddDrink"
        issue: "Drink-type tiles and Cancel button at AX5 (brief 11-DECISION-C016.md)"
    missing:
      - "Owner decision on brief 11-DECISION-C016.md (decision pending)"
      - "Layout fixes on Home, Insights, Add Drink, Settings Preferences and Onboarding at AX5, each with a UI test at AX5 (AGENTS.md UI-test rule)"
      - "Re-observe CHK-07 on the simulator with the owner"
  - truth: "The automated accessibility audit passes for the affected flows (VER-03 automated column)"
    status: failed
    reason: "The gated audit class has never passed on any run. The recorded exploratory run failed all 16 methods with 385 reports (D11-22 accepted these as open). The owner's decision keeps the findings open, so VER-03 cannot pass until they are fixed or the owner changes the requirement."
    artifacts:
      - path: "drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift"
        issue: "Gated by DP_RUN_A11Y_AUDIT (lines 37 to 55); with the gate set every reported issue fails the test (line 134)"
      - path: ".planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md"
        issue: "Rows A11Y-AUDIT-G01 to G09 hold the open groups"
      - path: ".planning/todos/pending/2026-11-14-fix-accessibility-audit-findings.md"
        issue: "Fix tracker; no owner brief yet for the groups"
    missing:
      - "Fix the audit groups G01 to G09 under owner D-09 briefs (each group needs its own decision, per D11-22)"
      - "Re-run the gated class on HEAD until it passes, or record an owner decision that changes the VER-03 contract"
      - "Remove the gate only after the findings are fixed (the gate may stay as documented opt-in)"
  - truth: "The automated audit evidence is recorded accurately: variant labels and issue counts match the saved result files"
    status: failed
    reason: "Two record errors. (1) The exploratory run in commit 9aaf759 failed to restore the simulator appearance after each of the four dark variants (console: 'Setting appearance mode to Unspecified' rejected, four times). The device stayed dark for every test that ran after history_dark, so the standard and ax5 labels for those screens are not reliable. Standard and dark key sets are identical for Home (23 of 23), History (4 of 4) and Settings (8 of 8), and the Insights standard set is contained in the dark set (37 of 37). Commit 7bea6da's message states 'the dark run left the simulator dark'. The evidence does not record this consequence. (2) 'Recomputed from the saved files: 311 distinct keys, 385 reports' is false. audit-exploratory.txt has 311 lines and 254 distinct lines (57 repeats). The 385 result-file reports collapse to 254 distinct screen, variant, type and element strings. The 311 figure is therefore not distinct, and it is repeated in D11-22, the ledger, the todo, the skip message, DEVLOG, current-focus and open-questions."
    artifacts:
      - path: ".planning/phases/11-ios-27-release-verification/11-EVIDENCE.md"
        issue: "Section 'Accessibility audit (exploratory run, D11-22)': '311 distinct keys' and the per-screen and per-variant table; 'no mismatch' claim; Accessibility table automated cells"
      - path: ".planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md"
        issue: "DL-O01 and grouped rows A11Y-AUDIT-G01 to G09 total 311"
      - path: "drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift"
        issue: "HEAD teardown (lines 60 to 70) restores light, which fixes the leak, but WR-02 (standard and ax5 not pinned) and WR-01 (navigation failure still audits) remain"
    missing:
      - "Correct the count in 11-EVIDENCE.md, the ledger, the todo, DEVLOG and open-questions to 385 reports and 254 distinct keys, and state the 311 figure as a line count with repeats"
      - "State in the evidence that the exploratory standard and ax5 labels after history_dark ran in dark appearance, and mark those rows unreliable"
      - "Apply the WR-01 and WR-02 fixes (pin appearance for every variant; stop the audit when navigation fails)"
      - "Re-run the audit class once on HEAD with the gate set, recording the new counts and digests. Decide with the owner how to set DP_RUN_A11Y_AUDIT for an Xcode MCP run, because the CLI is not an approved runner for this run"
behavior_unverified_items:
  - truth: "Reduce Motion gates the callout transition and selection animation on both Insights charts (05-UAT test 4, CHK-03)"
    test: "Insights tab: scrub each chart with Reduce Motion on, then with it off, and compare the callout transition"
    expected: "Callout appears without scale or fade with Reduce Motion on, and visibly animates with it off"
    why_human: "The gate is present in AlcoholAreaChart.swift (lines 104 and 105) and WeekdayBarChart.swift (lines 85 and 86). No test exercises the transition, and the owner's CHK-03 pass saw no difference between the two settings, so the gate is not demonstrated."
coincidental_reliance_items: []
---

# Phase 11: iOS 27 Release Verification - Verification Report

**Phase Goal:** Demonstrate a warning-clean, data-safe and accessible migration with recorded build and test evidence.
**Requirements:** MOD-04, VER-01, VER-02, VER-03
**Verified:** 2026-11-16T13:38:45Z
**Status:** gaps_found
**Re-verification:** No (initial verification; no prior VERIFICATION file existed)

## Verdict

The phase goal is not achieved. Build and test evidence is largely real and reproducible: every recorded log and result digest I checked matches its file, the full suite result and the coverage figures recompute from the saved bundle, and the one production change (the iPad orientation line) is the approved one. Two things block the goal.

1. **Accessibility is not demonstrated.** The owner checklist fails Reduce Motion at two sites (CHK-05, CHK-06) and Dynamic Type at AX5 on five screens (CHK-07). The automated audit has never passed. Four items remain open because they need a device (the VoiceOver rotor and both chart Audio Graphs).
2. **The automated audit record is wrong.** The exploratory run left the simulator in dark appearance for most of its later variants, and the "311 distinct keys" figure is not distinct (the saved files give 254 distinct keys across 385 reports). The record claims a recomputation that does not reproduce.

Closing VER-03 needs fixes in the app (not only owner decisions), so the status is `gaps_found`, not `human_needed`. Owner decisions on the five briefs (C014, C015, C016, OBS-A, OBS-C) are required as well.

REQUIREMENTS.md and ROADMAP.md agree that VER-03 is Pending: the checkbox at REQUIREMENTS.md line 33 is unchecked, and the traceability row reads Pending. The phase is correctly In progress, not passed.

## Requirement Cross-Reference

Requirement IDs are declared in PLAN frontmatter as follows: 11-01 (MOD-04, VER-01), 11-02 (VER-01, VER-03), 11-03 (VER-03), 11-04 (VER-02, VER-01), 11-05 (VER-01), 11-06 (VER-03), 11-07 (VER-03), 11-08 (all four), 11-09 (all four), 11-10 (VER-01, VER-02, VER-03), 11-11 (MOD-04, VER-01). All four IDs appear in at least one plan. REQUIREMENTS.md maps exactly these four to Phase 11 and no others, so no ID is orphaned or unaccounted.

| Requirement | REQUIREMENTS.md checkbox and traceability | Verifier verdict | Basis |
|-------------|-------------------------------------------|------------------|-------|
| MOD-04 | [x], Complete | SATISFIED | Truths T01 to T03. Deprecation count 0 in all four logs; the one app-owned warning is fixed. Four external tool-note lines remain (see W5). |
| VER-01 | [x], Complete | SATISFIED WITH NAMED EXCEPTIONS; owner confirmation requested on the Domain shortfall | Truths T02 to T07. Full run passes with 0 failures. Domain coverage 90.06 percent against 100 percent (T06, W1). |
| VER-02 | [x], Complete | SATISFIED UNDER OWNER-ACCEPTED LIMITATIONS; two residual risks | Truths T07 to T09. Edit persistence is undetermined (T08). Backup import has no UI test and the data-preservation device proof is historical (T09). |
| VER-03 | [ ], Pending | NOT SATISFIED | Truths T11 to T19. Three FAILED truths on Reduce Motion, AX5 and the audit; two FAILED record-integrity truths; open device items. |

## Roadmap Success Criteria

| SC | Criterion (ROADMAP.md) | Verdict | Notes |
|----|------------------------|---------|-------|
| SC1 | App-owned deprecation warnings resolved; external warnings documented | MET | Deprecations 0. External notes classified in 11-EVIDENCE.md, without an official Apple source (W5). |
| SC2 | Debug and Release builds and suites pass; evidence records toolchain, SDK, destination, limitations | MET WITH NAMED EXCEPTIONS | Release simulator-SDK build not run (owner D11-20, limitation L-07). Known-list failures in scoped run G3 only. |
| SC3 | Core flows complete with existing data preserved | MET WITH LIMITATIONS | Backup import UI untested (L-01), edit coverage partial and undetermined (L-02), device proof historical (L-03). |
| SC4 | VoiceOver, Reduce Motion, Dynamic Type through AX5, light/dark, Increase Contrast recorded as passed or explicitly open; automated and human results distinguished | NOT MET | Automated and human columns are separated. Three human items are fail, not passed or open. Their briefs keep them open as defects, which the literal wording may allow, but the requirement itself says checks pass (VER-03). |
| SC5 | Phase 05 skipped checks reconciled; no silent closure; discoveries have recorded outcomes | MET | Verified in truths T20 to T22. |

## Observable Truths

Status vocabulary: VERIFIED, FAILED (BLOCKER), UNCERTAIN (WARNING, human decision requested), PRESENT_BEHAVIOR_UNVERIFIED (WARNING, routes to human).

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| T01 | App-owned deprecation warnings resolved without suppression (MOD-04) | VERIFIED | `grep -E 'warning:.*deprecat\|deprecat.*warning'` returns 0 in mcp-debug-build.log, mcp-debug-build-2.log, release-device-build.log and release-device-build-2.log (the only "deprecated" hits are build-setting exports). `dismissSheet` appears in 0 lines of each. No `SUPPRESS_WARNINGS`, `WARN_INHIBIT` or `TREAT_WARNINGS_AS_ERRORS = YES` in project.pbxproj; no `pragma clang diagnostic` or `@available(*, deprecated` in drinkpulse sources. |
| T02 | Debug build succeeds with 0 Swift, linker or clang warnings (MCP BuildProject, buildForTesting) | VERIFIED | mcp-debug-build.log sha256 6d019bd4... matches the evidence; `** BUILD SUCCEEDED **` present once; gate pattern matches 0. Three plain tool-note lines (see T28). |
| T03 | Release device-SDK build succeeds, and the iPad orientation warning is gone (D11-21) | VERIFIED | release-device-build-2.log sha256 bd6c2055... matches; `** BUILD SUCCEEDED **`; 0 lines of "All interface orientations"; release-device-build-2.exit reads 0. The first build (7076a947...) had the line, as recorded. The Release simulator-SDK build was not run (owner runner policy). |
| T04 | Full suite passes: 834 tests, 0 failed, 18 skipped by gate, exit 0 | VERIFIED | full.log ends with `** TEST SUCCEEDED **`; full.exit reads 0; full.log sha256 79ae2971... matches. `xcresulttool get test-results summary` (read-only) gives result Passed, failedTests 0, passedTests 816, skippedTests 18, testFailures empty. The bundle's device-level passedTests reads 824; the evidence quotes the top-level 816 (see I2). |
| T05 | Coverage: overall at least 90, Services at least 85, view models at least 90 | VERIFIED | Recomputed from coverage.json (sha256 63efa071... matches): overall 10554/11151 = 94.65 percent; Services excluding HealthKitAdapter and NotificationScheduling 443/456 = 97.15 percent; view models 676/689 = 98.11 percent. |
| T06 | Domain layer at 100 percent per AGENTS.md | UNCERTAIN | Recomputed: non-Persistence Domain 743/825 = 90.06 percent, 8 of 23 files below 100 percent (DrinkTemplate 23/50, TemplateRecord 25/39, BackupDocument 6/9, BackupExport 26/36, ConsumptionEvent 72/87, Currency 12/13, DataImporter 147/155, DrinkControlImporter 89/93). AGENTS.md says below threshold "blocks completion". The owner listed the gap as debt (D11-10), but D11-02 does not name it as a VER-01 exception, despite REQUIREMENTS.md citing D11-02 for it (W1). |
| T07 | Scoped VER-02 flows pass except known-list tests | VERIFIED | Groups G1 to G4 and U1 reconcile with the source (G1 21 = 20 tests plus the ungated control test in SheetDismissTabSwitchUITests; G2 26; G3 22 = 15 in the HistoryInteraction family plus 1 plus 1 plus 5; G4 28). The only failures are HistoryInteractionUITests edit tests DL-T02 and DL-T03, which are on the owner's list. |
| T08 | Edit flow persists user edits without data loss | UNCERTAIN | The two edit-persistence tests failed in G3 and passed in the full run with the same code. Three other edit tests pass. The evidence states the data-integrity risk is undetermined (L-02). Owner accepted the exception under D11-02; the risk itself is not closed. |
| T09 | Existing data survives the upgrade and import (data-safe) | UNCERTAIN | MigrationChain, StoreBootstrap, RecordDeduplicator and importer unit suites pass on HEAD (U1). The only on-device upgrade proof is 10-DEVICE-SESSION.md (2026-11-09), which predates ten changed production files. The diff from a38a75f includes 117 changed lines in StoreBootstrap.swift and 42 in WeeklySummaryService.swift. Backup import has no UI test (L-01), and UI tests run on an in-memory store (L-04). Owner accepted these under D11-04 and D11-13. |
| T10 | The audit class is gated, so the default full run cannot go red from it | VERIFIED | AccessibilityAuditUITests.swift (180 lines) calls XCTSkipUnless on DP_RUN_A11Y_AUDIT in setUpWithError (lines 37 to 55). The full run and S1 each show 16 skipped. |
| T11 | Reduce Motion is honored at the Home overview card, the History calendar and the Home arc | FAILED | Owner: CHK-05 and CHK-06 fail, animating with Reduce Motion on and off; CHK-04 open. Source check: no `accessibilityReduceMotion` in ConsumptionOverviewCard.swift, HistoryCalendarView.swift or DPArcProgress.swift. Gap G-1. |
| T12 | Reduce Motion gates both Insights charts' callout and selection animation (05-UAT test 4) | PRESENT_BEHAVIOR_UNVERIFIED | Code present and wired: AlcoholAreaChart.swift lines 104 and 105, WeekdayBarChart.swift lines 85 and 86 read `reduceMotion`. The owner's CHK-03 pass saw no callout animation with Reduce Motion on or off, so the gate is not shown by a before and after difference. Routed to human (H5). |
| T13 | No truncated, clipped or overlapping text at AX5 on the affected flows | FAILED | Owner: CHK-07 fail on Home, Insights, Add Drink steps 1 and 2, Settings Preferences and Onboarding; guideline picker and History fine. HistoryDynamicTypeUITests (one test) does not cover these screens. Gap G-2. |
| T14 | Light and dark appearance is correct on all tabs and the Add Drink sheet | VERIFIED | Human CHK-08 pass (owner, iOS 27.2 simulator, not device). The automated dark variants do not support this (see T18); the human result stands on its own. |
| T15 | Increase Contrast is readable in both appearances | VERIFIED | Human CHK-09 pass (owner, iOS 27.2 simulator). No automated route exists. |
| T16 | VoiceOver Audio Graph on both charts (05-UAT tests 5 and 6; CHK-01, CHK-02) | UNCERTAIN | Open per CHK-00: the rotor is not reachable on the simulator. Descriptor unit tests pass but do not test the rotor. Needs a device (H6). |
| T17 | VoiceOver actions on a History row (CHK-10) | UNCERTAIN | Open per CHK-00. Needs a device (H6). |
| T18 | Automated audit evidence is recorded accurately | FAILED | (a) Console of the exploratory run: after history_dark, the teardown failed at line 718 ("Setting appearance mode to Unspecified") and the four dark teardowns failed the same way. Later tests in the recorded order (history_standard, home_ax5, home_dark, home_standard, insights_*, onboarding_*, settings_*) ran with the device left dark. Only addDrink (standard and ax5) and history_ax5 ran before the first failed restore. (b) The standard and dark key sets are identical for Home (23 of 23), History (4 of 4) and Settings (8 of 8), and the Insights standard set is a subset of the dark set. (c) audit-exploratory.txt has 311 lines and 254 distinct lines; the result file has 385 reports and 254 distinct screen, variant, type, element strings. "311 distinct keys" and "no mismatch" are unsupported. Gap G-4. |
| T19 | Automated audit passes for the affected flows (VER-03 automated column) | FAILED | Exploratory run: 16 methods failed, 385 reports. Gated run: 16 skipped. No audit method has passed on any run. Findings open per D11-22. Gap G-3. |
| T20 | Phase 05 skipped checks reconciled (05-UAT tests 4, 5, 6) | VERIFIED | 05-UAT.md tests 4, 5 and 6 read `result: skipped` (3 skipped). 11-DISCOVERIES.md maps them to CHK-03 (pass with caveat), CHK-01 (open) and CHK-02 (open), matching 11-A11Y-CHECKLIST.md. |
| T21 | Each substantial discovery has a recorded analysis and outcome (SC5) | VERIFIED | 26 rows. Nine outcome strings spot-checked by exact match in the cited files (revert-container-only, fix-query-first, as-of-last-visit, "Disposition: applied narrow fix.", "Owner outcome: deferred, flicker not confirmed gone", "Reduce Motion gates both charts' scrub animation", "Completed by Plan 09-02: approved Add Drink dismissal ownership repair.", sync-assign, 214 events). |
| T22 | The debt ledger lists items and closes none | VERIFIED | 79 DL rows plus 9 A11Y-AUDIT rows = 88. The only row marked fixed is DL-W05, which was already fixed before this phase. DL-W12 reads "open" as a dated quotation while WINDOWS.md row 12 reads fixed (acknowledged in the evidence). |
| T23 | Only approved production change; no schema or deployment-target change | VERIFIED | `git diff 2aa9156 HEAD -- drinkpulse drinkpulse.xcodeproj` names only drinkpulse/Info.plist, one added line (`UIInterfaceOrientationPortraitUpsideDown`). The test tree adds only AccessibilityAuditUITests.swift. Eight `IPHONEOS_DEPLOYMENT_TARGET` values, all 27.0. No UIRequiresFullScreen. Owner approved both (D11-21, D11-22). |
| T24 | Shipped-schema and file-size guards | VERIFIED | `git diff --quiet fbd37fa -- drinkpulse/Domain/Persistence/Schemas drinkpulse/Domain/Persistence/MigrationPlan.swift` exits 0. The file-size find (over 300 lines) returns nothing. |
| T25 | No identifiers or personal values in committed documents; no AI attribution in commits | VERIFIED | UUID-shaped scan of the Phase 11 documents and DEVLOG.md: 0 matches. `git log 2aa9156..HEAD` with Co-Authored-By or Claude: 0 matches. |
| T26 | Every requirement ID is declared in a plan and mapped once | VERIFIED | See Requirement Cross-Reference. |
| T27 | REQUIREMENTS.md VER-03 Pending agrees with the evidence | VERIFIED | Checkbox unchecked, traceability Pending, last-updated note consistent. ROADMAP.md text drifts (W7). |
| T28 | "Warning-clean" in the AGENTS.md sense (zero plain `warning:` lines in the build logs) | UNCERTAIN | Plain warning lines remain: Debug 3 and Release device 1, all `appintentsmetadataprocessor: Metadata extraction skipped, no AppIntents.framework dependency found`. The evidence classifies them as external with no impact. No Apple documentation was found for the message (W5). MOD-04 is met because none is a deprecation; the owner must accept that the literal zero-warning gate is not met (H7). |

**Score:** 17/28 truths verified. Failed: T11, T13, T18, T19. Uncertain: T06, T08, T09, T16, T17, T28. Present but behavior unverified: T12.

## Required Artifacts and Wiring

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| drinkpulse/Info.plist | iPad orientations: Portrait, PortraitUpsideDown, LandscapeLeft, LandscapeRight; iPhone key Portrait only | VERIFIED | Diff is one added line; the iPhone key is unchanged; no UIRequiresFullScreen. |
| drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift | Test-only audit class, 16 methods, gated, no allow-list | VERIFIED (as gated) | 180 lines; 16 `test_audit_*` methods (lines 164 to 179); gate at lines 37 to 55; issue handler records each issue as an XCTFail (lines 127 to 139). Known defects: WR-01 (navigation failure still audits, lines 119 to 125) and WR-02 (appearance not pinned for standard and ax5, lines 59 to 70). |
| 11-EVIDENCE.md | Build, test, coverage, VER-02 map, VER-03 tables, limitations, guards | VERIFIED WITH DEFECTS | Digests spot-checked (17 of 17 cited files match). Accessibility audit section contains the record errors in T18. |
| 11-A11Y-CHECKLIST.md | Eleven items, pass, fail or open, human only | VERIFIED | Results: pass CHK-03, CHK-08, CHK-09; fail CHK-05, CHK-06, CHK-07; open CHK-00, CHK-01, CHK-02, CHK-04, CHK-10. No pending items. |
| 11-DECISION-C014/C015/C016/OBS-A/OBS-C.md | Owner briefs, decision pending | VERIFIED | All five exist with `decision: pending`. |
| .planning/todos/pending/2026-11-14-fix-accessibility-audit-findings.md | Fix tracker | VERIFIED | Exists. It does not reference WR-01 or WR-02, although 11-REVIEW-DISPOSITION.md says they "belong with the todo" (W6). |
| 11-DEBT-LEDGER.md | 88 rows, none closed | VERIFIED | Counts reconcile with the evidence. Audit groups quote the 311 figure (T18). |
| 11-DISCOVERIES.md | 26 rows with outcomes | VERIFIED | See T21. |

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| Checklist CHK-03 | 05-UAT tests 4 to 6 | Phase 05 archived results | WIRED | Discoveries rows and checklist agree. |
| Checklist CHK-04 to CHK-06 | Animation sites | file and line references | WIRED | Lines 18, 110 and 61 match the source; none reads Reduce Motion. |
| Evidence VER-02 map | Scoped and full-run results | row names and counts | WIRED | Counts reconcile (T07). |
| Evidence audit section | audit-exploratory.txt and result file | recomputation | NOT_WIRED | The recomputation fails: 254 distinct, not 311 (T18). |
| Audit class | Default full run | DP_RUN_A11Y_AUDIT gate | WIRED | 16 skipped in the full run and in S1. |
| REQUIREMENTS VER-03 | 11-EVIDENCE outcome | Requirement outcome table | WIRED | Pending agrees with the outcome NOT complete. |

## Data-Flow Trace (Level 4)

Not applicable. Phase 11 is verification-only; the one production change is a static plist entry, and no rendered data path was changed.

## Behavioral Spot-Checks

| Behavior | Check | Result | Status |
|----------|-------|--------|--------|
| Full suite result | xcresulttool summary (read-only) of build/p11-full.xcresult | result Passed, failedTests 0, skippedTests 18 | PASS |
| Coverage aggregates | Recomputed from coverage.json | 94.65, 97.15, 98.11, 90.06 as stated | PASS |
| Warning gate | grep on the four recorded build logs | 0 gate-pattern matches, 0 deprecations, 0 orientation lines in the second Release build | PASS |
| Audit distinctness | sort -u on audit-exploratory.txt and result file | 254 distinct, not 311 | FAIL (T18) |
| Reduce Motion gate in source | grep accessibilityReduceMotion in drinkpulse | present in charts, History, Onboarding; absent in the three flagged sites | PASS (confirms T11) |

No build or test was run in this verification (owner runner policy D11-20 and the verifier instruction). The checks above read recorded outputs and source only.

## Probe Execution

Not applicable. No probe scripts are declared for this phase.

## Requirements Coverage

Covered in the Requirement Cross-Reference table above. No orphaned requirement IDs.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| drinkpulse/Features/Dashboard/Components/ConsumptionOverviewCard.swift | 110 | Animation not gated by Reduce Motion | BLOCKER (G-1) | Motion for users who asked for less |
| drinkpulse/Features/History/Components/HistoryCalendarView.swift | 61 | Animation not gated by Reduce Motion | BLOCKER (G-1) | Same |
| drinkpulse/DesignSystem/DPArcProgress.swift | 18 | Animation not gated by Reduce Motion (CHK-04 open) | WARNING | Same; not confirmed by the owner |
| drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift | 59 to 70 | Appearance not pinned for standard and ax5; restore falls back to the value read first | WARNING (WR-02) | Labels may be wrong (T18) |
| drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift | 94 to 125 | XCTAssert failure does not stop the audit (WR-01) | WARNING | Not triggered in the recorded run (no navigation failure lines), but a latent record risk |
| docs/DEVLOG.md (Phase 11 entry, checklist item 1) | n/a | "Debug and Release build with 0 warnings" | WARNING | Plain warning lines remain (T28) |

No TODO, FIXME or XXX markers were introduced in the Phase 11 code change. No production placeholder, stub or console logging was found in the one changed production file.

## Code Review Warnings (11-REVIEW.md)

- **WR-01** (navigation failures do not stop the audit): not triggered in the recorded run, because the exploratory log contains no navigation assertion failures (all 385 failures are audit reports). It remains a latent risk for any rerun and must be fixed before the audit record is refreshed (G-4).
- **WR-02** (standard and ax5 variants not pinned): this risk materialized in the recorded run. The dark-restore failure left the simulator dark for the later variants (T18). It directly weakens the exploratory record that D11-22 relies on.

The review's other findings (IN-01 to IN-03) do not affect the verdict. The disposition file records all five as open, and the review's statement that WR-01 and WR-02 "belong with the todo" is not reflected in the todo (W6).

## Deviations Classification

Per the owner rule (an owner-adapted deviation is not a gap; an unsupported claim is a gap):

| Deviation | Source | Classification |
|-----------|--------|----------------|
| Release simulator-SDK build not run; CLI limited to two approved steps plus one approved extra device build | D11-20, D11-21 | ACCEPTED (owner decision, limitation L-07) |
| Audit allow-list, green audit, negative control and ledger-per-key contract replaced by open findings and gating | D11-22 | ACCEPTED (owner decision) |
| Plan 11-10 "audit class passes on both destinations" read as skipped-by-gate | D11-22 (owner states this reading) | ACCEPTED |
| CLI recheck of secondary audit dropped | D11-20, D11-22 | ACCEPTED |
| Source guard `git diff --quiet 2aa9156` exits 1 | D11-21 | ACCEPTED (proved by `--name-only` and `--numstat`) |
| Plan 11-03 truth "appearance restored after every dark-variant test" | Plan 11-03 must_haves | NOT MET in the recorded run. The later fix (7bea6da) is in HEAD, but the consequence on variant labels is not recorded. Gap G-4 |
| Evidence "311 distinct keys ... no mismatch" | 11-EVIDENCE.md | UNSUPPORTED CLAIM. Gap G-4 |
| VER-01 Domain exception attributed to D11-02 | REQUIREMENTS.md, ROADMAP.md | MISATTRIBUTED. D11-02 does not name the Domain gap. Warning W1 |
| "Debug and Release build with 0 warnings" | DEVLOG.md | OVERCLAIMED. Warning W5 |
| "app built ... with zero warnings from GetBuildLog" | 11-11-SUMMARY.md | QUALIFIED (the statement is limited to GetBuildLog). INFO |

## Owner Decisions Honored

- D11-01 (no re-verification of 08 to 10): honored. The stale 09-VERIFICATION.md is listed in the ledger, not edited.
- D11-02 (named exceptions for VER-01): honored for the six named tests. The Domain gap is not in this list (W1).
- D11-03 (owner runs the checklist on the simulator): honored; results are recorded as owner results.
- D11-04 (no new device session): honored. The consequence is recorded as T09 and W3.
- D11-05 (toolchain 27.2, deployment target 27.0): honored; evidence uses 27.2 and the Phase 08 strings are historical.
- D11-09 (Phase 05 checks folded into the checklist): honored.
- D11-17 (animation sites on the checklist): honored; the sites are CHK-04 to CHK-06 and are failing in source.
- D11-20 (Xcode MCP only; two approved CLI steps): honored. Three CLI xcodebuild invocations were recorded (Release device twice, full run once). Pre-override CLI artifacts (debug-build.exit, release-sim-build.exit, run-*.sh) are present in the out-of-git stamp directory but are not cited as evidence (INFO I3).
- D11-21 (one Info.plist line): honored, verified by diff.
- D11-22 (audit gated, 311 open findings, no allow-list): honored for the gate and the no-allow-list rule. The count itself is not reproducible (T18).

## Human Verification Required

These items need an owner decision or a device. None is a substitute for the fixes in the gaps.

1. **Decide the five briefs** (`11-DECISION-C014.md`, `11-DECISION-C015.md`, `11-DECISION-C016.md`, `11-DECISION-OBS-A.md`, `11-DECISION-OBS-C.md`). The brief files are the input to every fix.
2. **Domain coverage shortfall (T06).** Decide whether 90.06 percent against 100 percent is accepted for VER-01. AGENTS.md says it blocks completion. Correct the D11-02 attribution in REQUIREMENTS.md and ROADMAP.md either way.
3. **Edit flow (T08).** Accept the risk recorded in L-02, or order an investigation of DL-T02 and DL-T03 to decide whether the app or the test is wrong.
4. **Data preservation and import (T09).** Accept L-01, L-03 and L-04, or schedule an on-device upgrade and import run against HEAD (the StoreBootstrap changes postdate the device session).
5. **CHK-03 re-observation (T12).** Repeat the Reduce Motion on and off comparison on both charts with a discriminating difference.
6. **Device run.** VoiceOver rotor and both Audio Graphs (CHK-00, CHK-01, CHK-02, CHK-10), and the Home arc under the sheet (CHK-04). The simulator cannot reach these.
7. **Plain warning lines (T28).** Accept the four `appintentsmetadataprocessor` notes under MOD-04, or find a source-side cause. No Apple documentation was found for the note.

## Gaps Summary

**G-1 Reduce Motion (T11, BLOCKER).** Three animations ignore Reduce Motion. Two are confirmed by the owner (CHK-05, CHK-06), one is open (CHK-04). Missing: owner decision on C014 and C015, gating in code, UI tests, and re-observation.

**G-2 AX5 layout (T13, BLOCKER).** Text clipping, truncation and overlap on five screens. Missing: owner decision on C016, layout fixes, AX5 UI tests and re-observation.

**G-3 Automated audit red (T19, BLOCKER).** Sixteen methods fail on the recorded run with 385 reports (groups A11Y-AUDIT-G01 to G09). Missing: fixes under owner briefs per group, and a passing gated re-run on HEAD.

**G-4 Audit record integrity (T18, BLOCKER).** The dark-appearance leak invalidates many standard and ax5 labels in the exploratory record, and the count of "distinct" keys is wrong (254 distinct, 385 reports). Missing: corrected figures in the evidence, ledger, todo, DEVLOG, current-focus, open-questions and the D11-22 record; WR-01 and WR-02 fixes; a refreshed audit run on HEAD with recorded counts and digests. The owner must decide how an Xcode MCP run can set DP_RUN_A11Y_AUDIT.

**Why gaps_found and not human_needed.** G-1, G-2 and G-3 need code changes, and G-4 needs a corrected record. Owner decisions and device checks alone would have produced human_needed.

**Recommended path.** (1) Correct G-4 first, in documents and with a refreshed audit run, so that the fix briefs are written from a valid record. (2) Owner decides the five briefs and T06. (3) Fix G-1, G-2 and the audit groups under their briefs, each with a UI test. (4) Device pass for the open VoiceOver items. (5) Re-run this verification.

## Warnings (non-blocking)

- **W1 Domain coverage attribution and gate (T06).** REQUIREMENTS.md and ROADMAP.md cite D11-02 for the 90.06 percent Domain shortfall. D11-02 names four items (six tests) and no coverage item. The owner did list the gap as debt (D11-10), but AGENTS.md says below-threshold coverage blocks completion. Owner must confirm.
- **W2 Edit persistence (T08).** Two edit-persistence tests fail in one run and pass in another with the same code. Owner accepted the exception, not the risk.
- **W3 Data-safety evidence age (T09).** The device upgrade proof predates 117 changed lines in StoreBootstrap.swift and 42 in WeeklySummaryService.swift. Unit suites pass on HEAD, but no on-device upgrade on HEAD exists.
- **W4 CHK-03 pass is non-discriminating (T12).** The owner saw no callout animation with Reduce Motion on or off. The pass proves only that nothing animated with the setting on.
- **W5 Warning-clean wording.** Four plain `warning:` lines remain (Debug 3, Release device 1). DEVLOG item 1 says "0 warnings". The phase goal says "warning-clean". MOD-04 is still met, because none of the lines is a deprecation.
- **W6 Review follow-through.** WR-01 and WR-02 are "open" in 11-REVIEW-DISPOSITION.md with a statement that they belong with the todo, but the todo does not mention them.
- **W7 Planning-document drift.** ROADMAP.md line 148 says "plan 11-09 pending" although 11-09 is ticked. ROADMAP.md line 169 (plan 11-03) still says "prove a repeatable green run and the negative control", which D11-22 superseded. STATE.md body line 198 still says "Discuss Phase 11". STATE.md frontmatter contradicts ROADMAP (DL-C01, acknowledged).
- **W8 Ledger staleness.** DL-W12 reads "open" while WINDOWS.md row 12 reads fixed. The evidence notes this as a dated quotation.

## Info

- **I1** Owner checklist session: part of CHK-07 ran without seeded launch arguments (on-disk store of unknown origin, not read). The owner states the layout observations do not depend on data (recorded in the checklist header and DL-O16).
- **I2** The xcresult device-level passedTests reads 824 while the top-level reads 816. The evidence quotes 816 (top level), which matches the total of 834 with 18 skipped.
- **I3** The out-of-git stamp directory holds pre-override CLI artifacts (debug-build.*, release-sim-build.*, run-debug.sh, run-release.sh, mcp-build.result.txt). None is cited as evidence.
- **I4** Release simulator-SDK build was never run; VER-01 wording "Debug and Release builds succeed" is met only for the device SDK (L-07).
- **I5** The G1 scoped group omits the ungated control test in SheetDismissTabSwitchUITests from its prose; the count reconciles.
- **I6** The simulator clone (dp-phase11-a11y) is absent, as the evidence states.

## Method and Limits

- No build or test was run. The CLI xcodebuild was not used, per the verifier instruction. Read-only checks: git diff, grep, file reads, recomputation of coverage from coverage.json, read-only xcresulttool summary, and sha256 of the out-of-git files.
- Not re-verified: Xcode MCP results recorded as tool output (GetBuildLog, DocumentationSearch, RunSomeTests), the owner's checklist answers, the simulator state, and the active run destination restoration (plan 11-10).
- The out-of-git log directory (`~/Library/Logs/DrinkPulse/phase-11-ios27/20261114T121519Z/`) was read in place; no file was copied into the repository.

---

_Verified: 2026-11-16T13:38:45Z_
_Verifier: Claude (gsd-verifier)_
