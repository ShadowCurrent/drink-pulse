---
phase: 11-ios-27-release-verification
plan: 13
subsystem: testing
tags: [accessibility, xcuiautomation, audit-baseline, owner-checkpoint, record-only]
requires: [11-12]
provides:
  - valid refreshed accessibility audit baseline on HEAD (385 reports, 311 byte-wise distinct keys)
  - baseline group mapping to A11Y-AUDIT-G01 to G09 with per-group distinct counts in the ledger
  - confirmed closed audit gate (scheme clean, ungated class skips 16 of 16)
affects: [11-14, 11-15, 11-16, 11-19, 11-22, 11-24]
tech-stack:
  added: []
  patterns: ["owner-set scheme environment variable, one Xcode MCP RunSomeTests call, owner removes it (D11-26)"]
key-files:
  created: []
  modified:
    - .planning/phases/11-ios-27-release-verification/11-EVIDENCE.md
    - .planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md
key-decisions:
  - "D11-26 mechanism realized through the Run action environment, inherited by Test (shouldUseLaunchSchemeArgsEnv = YES)"
  - "All distinct-key counts use LC_ALL=C sort -u; plain sort -u under pl_PL collapses emoji names"
  - "Fix plans 11-16 to 11-21 fix every baseline finding on their screen, whichever group ID it carries"
requirements-completed: []
status: complete
commits: 2
plan_head_before: a1ee81872020753272aaacbfc4c9ac954601d33b
plan_head_after: c0bbb5eb749c12323d66eaf5a91cbce90319acf2
actuals:
  tokens: 42000
  tasks: 4
  commits: 2
duration: multi-session, owner checkpoints included
completed: 2026-11-16
---

# Phase 11 Plan 13: Refreshed accessibility audit baseline Summary

Valid audit baseline on HEAD from one gated Xcode MCP run (385 reports, 311 byte-wise distinct keys, all mapped to G01 to G09, no G10), recorded as documents only; the owner set and removed `DP_RUN_A11Y_AUDIT`, and the ungated class skips 16 of 16 again.

## Accomplishments

- **Task 1 (owner checkpoint, no commit):** the owner set `DP_RUN_A11Y_AUDIT=1` in the Run action environment of the drinkpulse scheme; Test inherits it because the scheme sets `shouldUseLaunchSchemeArgsEnv = "YES"` (the Test action had no Arguments tab in the owner's Xcode).
- **Task 2 (commit 7170634):** gate opened (16 total, 0 skipped, 16 failed as designed). 385 reports, 311 byte-wise distinct keys. Types (reports/distinct): contrast 200/144, dynamicType 83/73, textClipped 65/57, sufficientElementDescription 21/21, hitRegion 16/16. No navigation-failure message, no `Failed to set appearance mode`, so every variant label is valid. Every key maps to G01 to G09; per-group counts equal the old ledger (111, 4, 49, 65, 35, 14, 10, 15, 8); no G10. Evidence section "Accessibility audit (refreshed baseline, plan 11-13)" and ledger column "Baseline keys (plan 11-13)" added; no Status cell changed.
- **Task 3 (owner checkpoint, no commit):** the owner removed the variable.
- **Task 4 (commit c0bbb5e):** scheme has 0 `DP_RUN_A11Y_AUDIT` entries, `git diff --quiet -- drinkpulse.xcodeproj` exits 0; ungated class run: 16 skipped, 0 failed; digest of `audit-gated-3.result.txt` recorded in the evidence.

## Owner-visible findings

1. **G09 is not locatable.** All 8 keys are `none#type=nil`: the audit issue carries no element object, so no element type or frame class can be recorded. The owner brief for G09 must find the element another way.
2. **Appearance is unproven by keys.** Light and dark key sets are identical on Home, Insights, History and Settings. The console pin lines prove the appearance was set; the keys cannot show it reached the audited window. Open observation, cause not established.
3. **Insights hitRegion is unstable per variant.** Old run: ax5 7 / standard 0; new run: ax5 0 / standard 7; total 14 unchanged. Fix plans must compare the screen sum, not a single variant.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Locale artifact in distinct-key counts**
- **Found during:** Task 2
- **Issue:** plain `sort -u` under pl_PL collapses emoji names (the "254" artifact in earlier records).
- **Fix:** all distinct-key counts use `LC_ALL=C sort -u`; the superseded record reads "385 reports, 311 byte-wise distinct keys (exploratory record, corrected)".
- **Files modified:** 11-EVIDENCE.md
- **Commit:** 7170634

**2. [Mechanism] Variable set on the Run action, not the Test action**
- **Issue:** the plan names the Test action; the owner's Xcode showed no Arguments tab there.
- **Resolution:** Run-action environment, inherited by Test via `shouldUseLaunchSchemeArgsEnv = "YES"`; arrival observed as 0 skipped, which is the plan's own test of arrival.

**3. [Transient MCP error] First Task 4 call returned no result**
- The first `RunSomeTests` call returned "The result bundle could not be opened as it is incomplete" with no counts. It was repeated once through MCP (no CLI) and returned 16 skipped, 0 failed. Noted in the evidence and in `audit-gated-3.result.txt`.

## Out-of-git helper

`audit-baseline.issues.raw` in the stamp directory (385 raw issue lines, not digested, not in git). The four files of the baseline and `audit-gated-3.result.txt` are digested in the evidence.

## Known Stubs

None.

## Threat Flags

None. No production, test or scheme file was committed; the commits list only `11-EVIDENCE.md` and `11-DEBT-LEDGER.md`.

## Self-Check: PASSED

- 11-EVIDENCE.md section "refreshed baseline, plan 11-13" present; ledger column "Baseline keys (plan 11-13)" present
- commits 7170634 and c0bbb5e are ancestors of HEAD
- scheme has 0 `DP_RUN_A11Y_AUDIT`, no diff in `drinkpulse.xcodeproj`

## Requirements note

VER-03 and VER-01 are not marked complete: this plan records the baseline only, and the evidence keeps VER-03 as not complete (open audit findings, owner checklist fails). `requirements mark-complete` was run by the standard state step and reverted before the commit. `state advance-plan` and `state update-progress` declined because 11 plans of phase 11 have no SUMMARY yet; STATE.md position fields are unchanged, the decision, metric and session records were written.
