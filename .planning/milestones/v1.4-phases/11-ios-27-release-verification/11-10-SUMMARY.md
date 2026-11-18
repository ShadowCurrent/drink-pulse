---
phase: 11-ios-27-release-verification
plan: 10
subsystem: testing
tags: [ver-01, ver-02, ver-03, secondary-destination, smoke-cross-check, xcode-mcp]
status: complete

requires:
  - phase: 11-ios-27-release-verification
    provides: plan 11-03 gated audit class and D11-22 audit record, plan 11-04 scoped runs, plan 11-05 full suite
provides:
  - "11-EVIDENCE.md rows S1 and S2: smoke cross-check on iPhone 18 Pro Max, iOS 27.2 (runtime build 24B8117), runner and SHA-256 of every result and console file"
  - "11-EVIDENCE.md secondary destination line, Accessibility (VER-03) note, active destination restored statement"
  - "11-DEBT-LEDGER.md observation DL-O03"
affects: [11-06, 11-07, 11-08, 11-09]

actuals:
  tokens: 6000
  tasks: 2
  commits: 2
plan_head_before: ae245ba
plan_head_after: 07918c1

key-files:
  created: []
  modified:
    - .planning/phases/11-ios-27-release-verification/11-EVIDENCE.md
    - .planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md

key-decisions:
  - "D11-22 wins over the plan: the audit class is skipped-by-gate on the secondary destination and counts as a pass; no allow-list, no A11Y-AUDIT rows, no re-run S1R, no CLI recheck"

requirements-completed: []  # evidence recorded; the orchestrator and plan 11-08 own requirement status

duration: about 15 minutes
completed: 2026-11-15
---

# Phase 11 Plan 10: Secondary destination smoke cross-check Summary

On the iPhone 18 Pro Max, iOS 27.2 (runtime build 24B8117) through Xcode MCP: the audit class skipped by gate (16 skipped, 0 failed) and the five core-flow classes passed 23 of 23; the primary iPhone 18 Pro destination is active again.

## Results

| Row | Classes | Runner | total | passed | failed | skipped |
|-----|---------|--------|-------|--------|--------|---------|
| S1 | AccessibilityAuditUITests (gated, `DP_RUN_A11Y_AUDIT` not set) | Xcode MCP RunSomeTests | 16 | 0 | 0 | 16 |
| S2 | OnboardingFlowUITests, ShellNavigationUITests, AddDrinkFlowUITests, DashboardUITests, SettingsUITests | Xcode MCP RunSomeTests | 23 | 23 | 0 | 0 |

- Both result bundles report device iPhone 18 Pro Max, osVersion 27.2, osBuildNumber 24B8117 (read with `xcresulttool`). Only one "iPhone 18 Pro Max (27.2)" entry existed in `XcodeListRunDestinations`; it sits under the same runtime as the primary. iPhone Duo and the 24B91016s runtime were not used.
- S2 had no failure, so no isolated re-run, no flake, no new todo.
- Destination restored: `XcodeSwitchRunDestination` to `iPhone 18 Pro`, confirmed active with `XcodeListRunDestinations`; the evidence states `active destination restored`.
- Flakes: none observed.
- Blockers: none.

## Task commits

1. **Task 1: S1 and S2 rows** - `d8c9584` (docs)
2. **Task 2: secondary destination line, Accessibility note, DL-O03** - `07918c1` (docs)

Out-of-git (stamp directory): `s1-audit-secondary.result.txt`, `s1-audit-secondary.console.txt`, `s2-flows-secondary.result.txt`, `s2-flows-secondary.console.txt`; digests are in the evidence.

## Deviations from Plan

**1. [Owner override D11-22] S1 skipped-by-gate, allow-list part of Task 2 void**
- S1 ran without `DP_RUN_A11Y_AUDIT`; 16 skipped, 0 failed counts as a pass. No `AllowedIssue` entry, no `A11Y-AUDIT-NN` ledger row, no edit to `AccessibilityAuditUITests.swift`, no S1R re-run. The evidence says larger-screen audit findings are not assessed in Phase 11 and routes them to todo `2026-11-14-fix-accessibility-audit-findings`.

**2. [Owner override D11-20/D11-22] CLI recheck dropped**
- The Task 2 step 5 CLI run (`audit-secondary-recheck.cli.log`, "Executed 16 tests, with 0 failures") was not run. D11-20 forbids it; the audit is gated, so it would not have been a meaningful check.

**3. [Verify script adapted] Assertions changed**
- Dropped: allow-list IDs equal ledger IDs, the 30-key stop rule, `Unrecorded accessibility audit issue: ` prefix, the S1R row and digest, the S1-failures-are-audit-methods check (S1 has no failures), the `audit-secondary-recheck.cli.log` grep.
- Kept: row counts add up, destination named, runner named, result and console digests equal files, secondary destination and smoke cross-check wording, `active destination restored`, no UUID-shaped string in the evidence or ledger.
- Added: S1 counts equal 16/0/0/16 and S2 equal 23/23/0/0; DL-O03 present once.

**4. [Source guard] `git diff --quiet 2aa9156 -- drinkpulse drinkpulse.xcodeproj` exits 1**
- Only `drinkpulse/Info.plist` differs (`--name-only` lists it alone, `--numstat` 1 added, 0 removed): the owner-approved D11-21 change (plan 11-11). No other production or project file changed. Same treatment as plans 11-04 and 11-05.

**5. [Ledger numbering] DL-O03 added**
- The plan asks for one ledger observation row with the next free DL-O number: DL-O03 (observation only, no new debt).

## Auth gates

None.

## Known Stubs

None. No source file was created or changed.

## Threat Flags

None. The evidence holds model, runtime build, counts, identifiers and digests only; no simulator identifier was written to a committed file.

## Verification

- Adapted Task 1 and Task 2 gates pass (counts, digests, wording, restored destination, no UUID in committed docs).
- `AccessibilityAuditUITests.swift` is identical to HEAD (no test-code edit); production diff vs `2aa9156` is `drinkpulse/Info.plist` only.

## Self-Check: PASSED

- Stamp-directory files exist and their digests match the evidence.
- Commits `d8c9584` and `07918c1` are ancestors of HEAD.
