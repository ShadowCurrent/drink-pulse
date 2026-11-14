---
phase: 11-ios-27-release-verification
plan: 03
subsystem: testing
tags: [accessibility, performAccessibilityAudit, xcuitest, ver-03, d11-22, gated-test]

requires:
  - phase: 11-ios-27-release-verification
    provides: plan 11-01 evidence skeleton and plan 11-02 debt ledger with the reserved audit section
provides:
  - "AccessibilityAuditUITests: 16 audit methods (Home, Insights, History, Settings at default, AX5, dark; Add Drink and Onboarding at default, AX5), gated behind DP_RUN_A11Y_AUDIT"
  - "11-EVIDENCE.md section 'Accessibility audit (exploratory run, D11-22)': 311 distinct open findings with counts, per-screen table, root-cause groups, digests"
  - "11-DEBT-LEDGER.md: grouped rows A11Y-AUDIT-G01 to G09 and observation DL-O01 (no allow-list)"
  - "Pending todo 2026-11-14-fix-accessibility-audit-findings.md"
affects: [11-04, 11-05, 11-07, 11-09, 11-10]

actuals:
  tokens: 6300
  tasks: 3
  commits: 6
plan_head_before: bc0e53d53a1d9cebca98e7a78f85fb3ec46e3254
plan_head_after: 11c630efee5f3e3fa4d0de10028f6e6abd5cbd12

tech-stack:
  added: []
  patterns:
    - "Environment-gated XCTest class: XCTSkipUnless on a DP_RUN_* variable in setUpWithError, skip message names the todo (same as DP_RUN_FLASH_HARNESS)"
    - "Ledger rows grouped by root cause instead of one row per key when a run produces hundreds of findings"

key-files:
  created:
    - drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift
    - .planning/todos/pending/2026-11-14-fix-accessibility-audit-findings.md
  modified:
    - .planning/phases/11-ios-27-release-verification/11-EVIDENCE.md
    - .planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md

key-decisions:
  - "D11-22 (owner): the 311 audit findings are recorded as open, not allow-listed and not fixed in Phase 11; the class is gated by default"
  - "Ledger heading 'Accessibility audit allow-list (filled by plan 11-03)' is kept verbatim so references from plans 11-09 and 11-10 still resolve; the section says there is no allow-list"
  - "Group IDs use A11Y-AUDIT-Gnn (not two-digit numbers) to avoid being read as per-key IDs"

requirements-completed: []  # VER-03 is only partly served (automated column recorded, 311 open); it completes with plans 11-07 and 11-08

duration: multi-session (interrupted once, resumed 2026-11-14)
completed: 2026-11-14
status: complete
---

# Phase 11 Plan 03: Automated Accessibility Audit Summary

**One gated test-only audit class (16 methods) ran once and found 311 distinct open accessibility issues (385 reports), which are recorded in evidence, a grouped debt ledger section and a pending fix todo; nothing is fixed or allow-listed.**

## Accomplishments

- `AccessibilityAuditUITests` (180 lines, test-only) calls `performAccessibilityAudit(for: .all)` per screen and variant and records each reported issue as its own failure. Dark variants restore the simulator appearance in a teardown block registered before the change.
- Exploratory run (Xcode MCP `RunSomeTests`, commit `9aaf759`): 16 methods red; 311 distinct keys, 385 reports; by type contrast 144, dynamicType 73, textClipped 57, sufficientElementDescription 21, hitRegion 16. The numbers were recomputed from the saved files and equal the D11-22 numbers.
- After D11-22 the class skips unless `DP_RUN_A11Y_AUDIT=1` (`TEST_RUNNER_DP_RUN_A11Y_AUDIT=1` for xcodebuild). Gated verification (Xcode MCP, commit `509fd4b`): 16 tests, 16 skipped, 0 failed. Build check via MCP `BuildProject` (`buildForTesting`): success, zero warnings (`GetBuildLog` at warning severity returned 0 entries).
- Evidence section holds the per-screen by variant by type table, nine probable-root-cause groups (largest: Add Drink drink-type tiles with 111 keys), SHA-256 digests of the out-of-git result files, and the VER-03 automated wording "audit run: 16 methods red, 311 open findings".
- Ledger: grouped rows `A11Y-AUDIT-G01` to `G09` (311 keys in total) and `DL-O01`. Todo `2026-11-14-fix-accessibility-audit-findings` tracks the fixes; each fix needs an owner D-09 brief.

## Task Commits

1. Task 1, class with empty allow-list: `9aaf759` (test)
2. Task 1 follow-up, appearance teardown restores light instead of the rejected `.unspecified`: `7bea6da` (fix)
3. Owner decision D11-22 recorded in CONTEXT: `0fff990` (docs)
4. Task 3 replacement, gate behind `DP_RUN_A11Y_AUDIT`, allow-list removed: `509fd4b` (test)
5. Tasks 2 and 3, evidence section and grouped ledger rows: `12b7760` (docs)
6. Pending todo for the fixes: `11c630e` (docs)

## Deviations from Plan

### Owner decision

**1. [D11-22 supersedes plan contract] Allow-list, green run, negative control and per-key ledger rows replaced**
- **Found during:** Task 2 (exploratory run found 311 keys, over the plan's 30-key stop rule)
- **Issue:** The plan's contract (ledger row per key, `allowedIssues` bound to ledger IDs, green 16 of 16 run twice, negative control) was set aside by the owner.
- **Fix:** Findings recorded as open; ledger holds nine grouped rows, not 311; no allow-list exists, so the negative control does not apply and the "allow-list IDs equal ledger IDs" gate has nothing to compare; the class is gated and skips by default; the VER-03 automated column reports the red run.
- **Files:** `AccessibilityAuditUITests.swift`, `11-EVIDENCE.md`, `11-DEBT-LEDGER.md`, new todo
- **Commits:** `509fd4b`, `12b7760`, `11c630e`

### Auto-fixed Issues

**2. [Rule 1 - Bug] Dark-variant teardown set an appearance the simulator rejects**
- **Found during:** Task 2 exploratory run (4 failures `Failed to set appearance mode: Requested appearance value (0) is not valid`, one per dark method)
- **Fix:** The teardown restores the appearance read before the change, light if it was unset. These 4 failures are not audit findings and are excluded from the 311 and 385.
- **Commit:** `7bea6da`

### Process deviations

- The session was interrupted mid-plan (token limit) and resumed to close out; finished work was not re-run. The exploratory audit was not repeated.
- MCP `XcodeRefreshCodeIssuesInFile` returned a `SourceEditorCallableDiagnosticError error 5` in the resume session; compiler diagnostics were taken from `BuildProject` and `GetBuildLog` (zero warnings). An earlier session recorded the same tool reporting no issues (`audit-build.result.txt`).
- The plan's CLI `xcodebuild` steps were not used: D11-20 requires Xcode MCP only, and the MCP result carried every per-issue message.
- The plan's Task 3 verify script and the verify scripts of plans 11-09 and 11-10 expect `A11Y-AUDIT-NN` IDs equal in the Swift file and the ledger and an `Unrecorded accessibility audit issue: ` prefix. Both no longer apply (no allow-list; the failure prefix is now `Accessibility audit issue: `). The orchestrator should adjust those plans per D11-22 (they treat the class as skipped-by-gate).

## Known Stubs

None. No placeholder data in the new test file or records.

## Threat Flags

None. No production code, network, auth or schema change. The audit uses existing `dp_uitest` launch-argument hooks only. The record names identifiers and audit types, not user data (seed data is synthetic and in memory).

## Source guard note

`git diff --quiet 2aa9156 -- drinkpulse drinkpulse.xcodeproj` is non-zero only because of the owner-approved D11-21 change from plan 11-11 (`drinkpulse/Info.plist`, 1 insertion). This plan changed no production or project file.

## Self-Check: PASSED

- Files exist: `AccessibilityAuditUITests.swift`, todo, `11-EVIDENCE.md` section, `11-DEBT-LEDGER.md` rows.
- Commits `9aaf759`, `7bea6da`, `0fff990`, `509fd4b`, `12b7760`, `11c630e` are on the branch.
- Evidence digests recomputed with `shasum -a 256` on 2026-11-14.
