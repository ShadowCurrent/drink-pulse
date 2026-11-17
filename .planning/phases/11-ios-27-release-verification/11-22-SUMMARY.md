---
phase: 11-ios-27-release-verification
plan: 22
subsystem: accessibility
tags: [accessibility-audit, xcuitest, gated-audit, gap-closure, G-3, scheme-gate]
status: complete
requires: [11-21]
provides:
  - gated AccessibilityAuditUITests passes 16 of 16 (0 failed, 0 skipped) on HEAD through Xcode MCP with the owner-set scheme variable (decision D11-26)
  - gated class routed through the shared audit helper with the same decision-scoped opt-ins as the per-screen classes (D11-29, D11-30, D11-31); Insights readiness wait for the chart
  - class doc comment and skip message state the audit passes and stays a documented opt-in; the gate is unchanged
  - 11-EVIDENCE.md section "Accessibility audit (final gated re-run, plan 11-22)" with counts, validity checks, baseline comparison and digests
  - gate closed again: scheme file has no DP_RUN_A11Y_AUDIT entry and no diff; the ungated class skips 16 of 16
affects: [11-23, 11-24]
tech-stack:
  added: []
  patterns:
    - "A gated full-audit class reuses the shared assertNoAuditIssues helper and the per-screen opt-ins, so no screen is judged by a stricter or looser rule than its ungated class"
    - "An audit that reports an element-less issue together with chartFound=false started before the chart was laid out; a readiness wait is the fix, not an exemption"
key-files:
  created: []
  modified:
    - drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift
    - .planning/phases/11-ios-27-release-verification/11-EVIDENCE.md
key-decisions:
  - "No new decision id: the gated class uses only the existing D11-29, D11-30 and D11-31 opt-ins, scoped per screen and variant as in the per-screen classes (D11-32 stays free for plan 11-23)"
metrics:
  duration: "about 25 min of executor time on 2026-11-17, excluding the owner's two checkpoint replies"
  completed: 2026-11-17
actuals:
  tokens: 4500
  tasks: 4
  commits: 2
plan_head_before: e1ff8ef
plan_head_after: 410a5a6c4f15d58e1b0bc64f97132129219cc8b3
requirements-completed: []
---

# Phase 11 Plan 22: Final gated accessibility audit re-run Summary

The gated `AccessibilityAuditUITests` class passes 16 of 16 on HEAD through Xcode MCP, and the audit gate is closed again (the ungated class skips 16 of 16, the scheme equals HEAD). Gap G-3 is closed for the automated audit; VER-03 stays open for its human checks.

## Outcome

- **Task 1 (owner sets the variable):** done before this executor started. The scheme file carried `DP_RUN_A11Y_AUDIT` = 1, isEnabled YES (set in Run > Arguments, Test inherits; verified by the orchestrator). The checkpoint stopped for the owner and was not auto-approved.
- **Task 2 (gated run):** done. Two gated runs of the full class, one fix round of the two allowed.
  - Run 0: 15 passed, 1 failed, 0 skipped (gate arrival proven by 0 skipped). `test_audit_insights_ax5`: one element-less `contrast` issue, logged with `chartFound=false`.
  - Fix round 1: `open(_:in:)` waits up to 10 s for the `Alcohol Over Time` chart before the Insights audit starts. The same per-screen method had passed in `InsightsAccessibilityAuditUITests` with the same opt-ins (one run). The wait changes only when the audit starts; no issue is hidden.
  - Final run: 16 passed, 0 failed, 0 skipped, 0 failure lines, 0 navigation failures, 0 appearance-restore failures, 0 distinct keys.
  - Before the first run the gated class was routed through the shared `assertNoAuditIssues` helper with the per-screen opt-ins (see Deviations). The final run logged 33 ignored issues as warnings: D11-29 16, D11-30 14, D11-31 3.
  - Class doc comment and skip message updated; `BuildProject buildForTesting` succeeded, `GetBuildLog` warning severity 0 entries, `XcodeRefreshCodeIssuesInFile` 0 diagnostics.
- **Task 3 (owner removes the variable):** the owner replied "removed". The checkpoint stopped for the owner and was not auto-approved.
- **Task 4 (gate closed):** the scheme file has 0 occurrences of `DP_RUN_A11Y_AUDIT` and `git diff --quiet -- drinkpulse.xcodeproj` exits 0. The ungated class, run once with the 16 per-method identifiers, shows 16 skipped, 0 failed (`audit-gated-4.result.txt`, digest in 11-EVIDENCE.md).
- Runner: Xcode MCP only (XcodeListWorkspaces, XcodeListRunDestinations, RunSomeTests, BuildProject, GetBuildLog, XcodeRefreshCodeIssuesInFile). No CLI xcodebuild. The scheme was never edited or committed by this plan.
- Budget: the gated class ran 2 times with the variable set and once without; one per-screen Insights AX5 method ran once.

## Comparison with the refreshed baseline (plan 11-13)

Baseline: 16 methods red, 385 reports, 311 byte-wise distinct keys. Final: 16 passed, 0 failures, 0 distinct keys (Home, Insights, History, Settings, Add Drink, Onboarding all 0 per variant). The per-screen table is in 11-EVIDENCE.md.

## Task Commits

1. **Task 2:** `4a2c845` test(11-22): gated audit passes 16 of 16; route through shared opt-ins and wait for the Insights chart (audit test file and 11-EVIDENCE.md)
2. **Task 4:** `410a5a6` docs(11-22): record closed gate, ungated audit class skips 16 of 16 (11-EVIDENCE.md only)

Tasks 1 and 3 are owner checkpoints with no commit. The scheme file was not committed.

## Regular-size visual changes

None. No production file changed in this plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Gated class routed through the shared helper opt-ins**
- **Found during:** Task 2, before the first run (owner directive for this plan)
- **Issue:** the gated class had its own `record(_:)` and no opt-ins, so it would have reported the Home `This Week` and `100%`, Insights and History element-less findings that D11-29, D11-30 and D11-31 already cover for the per-screen classes.
- **Fix:** it now calls `assertNoAuditIssues` with the same per-screen, per-variant opt-ins as the ungated per-screen classes. No allow-list, no excluded type, no skipped method.
- **Files modified:** `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift`
- **Commit:** 4a2c845

**2. [Rule 1 - Bug] Insights AX5 audit raced the chart layout**
- **Found during:** Task 2, run 0
- **Issue:** one element-less contrast issue with `chartFound=false` in `test_audit_insights_ax5`; the per-screen class passed with identical opt-ins.
- **Fix:** readiness wait for the chart in `open(_:in:)` (fix round 1 of 2).
- **Files modified:** `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift`
- **Commit:** 4a2c845

**3. [Rule 3 - Blocking] Plan verify check on `screen=` lines adapted**
- **Issue:** the plan's `grep -c 'screen='` equals 0 check also matches the 33 intentional ignored-issue warnings and their counts.
- **Fix:** the failure line `failed - Accessibility audit issue` (0 lines) is counted instead. Recorded in 11-EVIDENCE.md. All other Task 2 verify checks pass.

**4. [Process] First commit carried attribution trailers**
- The first commit was amended before anything else to remove the AI attribution trailers (owner directive). `4a2c845` and `410a5a6` have none.

### Orchestrator message mismatch

The coordinator first reported that the first RunSomeTests call ran 880 tests. The tool response had `total` 16, so only the audit class ran; the coordinator later confirmed that the 880 was Xcode's displayed total. There are no full-suite totals and no non-audit failures from this plan.

## Carried items

- **DL-O20** (Onboarding at AX5, owner eye check) is not covered by this plan's checkpoints. It is carried to the 11-23 checkpoint.
- **Ledger:** no Status cell was edited here; plan 11-24 reconciles A11Y-AUDIT-G01 to G09 against the digests in 11-EVIDENCE.md. Open items DL-O18, DL-O19, DL-O20 and DL-T01 are unchanged.
- **Requirements:** VER-01 and VER-03 stay open; no `requirements mark-complete` was run. G-2 stays open.

## Known Stubs

None.

## Threat Flags

None. No network, auth, file-access or schema surface was added. T-11-65 (scheme variable left set or committed) is mitigated: 0 occurrences in the scheme file, no diff, ungated class skips 16 of 16.

## Self-Check: PASSED

- `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift` FOUND (173 lines)
- `11-EVIDENCE.md` section "final gated re-run, plan 11-22" FOUND
- commits `4a2c845` and `410a5a6` are ancestors of HEAD
- scheme file: 0 occurrences of `DP_RUN_A11Y_AUDIT`, no diff
