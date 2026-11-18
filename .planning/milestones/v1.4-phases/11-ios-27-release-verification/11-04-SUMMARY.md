---
phase: 11-ios-27-release-verification
plan: 04
subsystem: testing
tags: [ver-02, ver-01, scoped-runs, xcuitest, data-preservation, limitations]
status: complete

requires:
  - phase: 11-ios-27-release-verification
    provides: plan 11-01 toolchain and destination record, plan 11-02 debt ledger rows DL-T01 to DL-T07, plan 11-03 accessibility audit prose
provides:
  - "11-EVIDENCE.md Scoped runs rows G1 to G4 (UI) and U1 (unit) with runner, counts, failures, skips, mapping and SHA-256 of each result file"
  - "11-EVIDENCE.md Core flow proof: twelve-row flow-to-test map, data-preservation row citing the Phase 10 device session as historical, five edge notes"
  - "11-EVIDENCE.md Limitations L-01 to L-09, including the changed-production-files gap after a38a75f and the missing import UI test"
  - "Accessibility (VER-03) table created with automated cells for AX5, appearance, VoiceOver and Audio Graph"
affects: [11-05, 11-07, 11-08, 11-09, 11-10]

actuals:
  tokens: 11000
  tasks: 3
  commits: 3
plan_head_before: 1290bf439b948fceded59f56ab85864f37877ee7
plan_head_after: d7e8a76ff310dc8a6b99a046e1506a5b3dbc4323

tech-stack:
  added: []
  patterns:
    - "Scoped runs by class group through Xcode MCP RunSomeTests; the tool's full summary file is saved as the result file and hashed"

key-files:
  created: []
  modified:
    - .planning/phases/11-ios-27-release-verification/11-EVIDENCE.md

key-decisions:
  - "Option C (owner): stop on the missing iOS 27.2 build 24B8117 runtime and resume only after the owner reinstalled it; no run used iPhone Duo or the 24B91016s runtime"
  - "Known-list tests that unexpectedly passed (DL-T01, DL-T04) are recorded as unexpectedly passed and stay on the ledger and in their todo and open-questions entries"

requirements-completed: []  # VER-02 evidence is recorded; the orchestrator and plan 11-08 own the requirement status

duration: 2026-11-14, one interruption for the runtime outage
completed: 2026-11-14
---

# Phase 11 Plan 04: Scoped VER-02 runs, core flow proof and limitations Summary

All VER-02 flow classes ran scoped on the iPhone 18 Pro, iOS 27.2 (build 24B8117) through Xcode MCP: 21 + 26 + 22 + 28 UI tests and 167 unit tests, with only the two known History edit failures and the two expected D1 harness skips.

## Results per group

| Group | Classes in scope | Runner | total | passed | failed | skipped |
|-------|------------------|--------|-------|--------|--------|---------|
| G1 | onboarding, startup and retry, shell, sheet-dismiss harness | Xcode MCP RunSomeTests | 21 | 19 | 0 | 2 |
| G2 | add, edit, delete | Xcode MCP RunSomeTests | 26 | 26 | 0 | 0 |
| G3 | History list and calendar, Dashboard | Xcode MCP RunSomeTests | 22 | 20 | 2 | 0 |
| G4 | Insights, settings, export | Xcode MCP RunSomeTests | 28 | 28 | 0 | 0 |
| U1 | migration, store bootstrap, importer, chart descriptor, weekly summary, Health suites | Xcode MCP RunSomeTests | 167 | 167 | 0 | 0 |

- **Skipped (G1), as expected:** `SheetDismissTabSwitchUITests/test_sheetCancelThenTabSwitch_cycle_staysNavigable_recordsFrameDeltas()` and `SheetDismissTabSwitchUITests/test_sheetCancelThenTabSwitch_emptyStore_recordsFrameDeltas()` (DL-T05, DL-T06, gated by `DP_RUN_FLASH_HARNESS`, no harness variable set). This is the first run that confirms the gate holds without a simulator crash.
- **Failed (G3), both on the known list:** `HistoryInteractionUITests/test_editCustomNameAndNotes_persist()` (DL-T02, line 165) and `HistoryInteractionUITests/test_editCategoryChange_persists()` (DL-T03, line 220). Not re-run in isolation, because both are on the known list (the isolated re-run applies only to unknown failures). The data-integrity risk in the edit flow stays undetermined (L-02).
- **Unexpectedly passed (G4), stay on the ledger:** `InsightsUITests/test_heroCard_holdsHeight_whenSwitchingToAllTimeScope()` (DL-T01) and `ExportUITests/test_export_dismissWithoutSaving_showsNoFailureAlert()` (DL-T04, intermittent).
- **Exception mismatches:** none. **Newly observed flakes:** none (the watched DL-T07 passed in G3), so no todo and no ledger observation row was added.
- **AccessibilityAuditUITests** was not part of any group; its 16 methods are skipped by the D11-22 gate and that is expected.

Result files, outside git in the stamp directory, with the digests recorded in the evidence: `g1-ui.result.txt`, `g2-ui.result.txt`, `g3-ui.result.txt`, `g4-ui.result.txt`, `u1-unit.result.txt` (plus a console log per run).

## Task commits

1. **Task 1: G1 and G2 plus the dated destination note** - `1fbab49` (docs)
2. **Task 2: G3 and G4 plus accessibility automated cells** - `536e2f2` (docs)
3. **Task 3: U1, core flow proof, edge notes, limitations L-01 to L-09** - `d7e8a76` (docs)

## Deviations from Plan

**1. [Rule 4 - Blocker, resolved by owner] Required destination missing at start**
- **Found during:** Task 1 preflight. The iOS 27.2 runtime build 24B8117 was gone (CoreSimulator volume change at about 17:26), the iPhone 18 Pro was "unavailable" and the MCP destination had fallen back to iPhone Duo (build 24B91016s).
- **Action:** stopped with a decision checkpoint, no run made; the owner chose option C and reinstalled the runtime; the same device UDID came back; I switched the MCP destination to iPhone 18 Pro and confirmed it before the first group.
- **Record:** dated destination note at the top of `## Scoped runs (VER-02)`, committed with Task 1 (`1fbab49`). No Phase 11 run used another runtime.

**2. [Rule 3 - Blocking] The Accessibility (VER-03) table did not exist**
- **Found during:** Task 2. Plan 11-03 recorded the audit as prose under D11-22 and never created the seven-row table that Task 2 asked this plan to update.
- **Fix:** created the table with the three columns and the seven row names from the 11-03 plan, filled the automated cells for AX5 (`HistoryDynamicTypeUITests`), appearance (`SettingsUITests`), VoiceOver and Audio Graph, left every Human cell `pending (plan 11-07)`.
- **Commit:** `536e2f2`, with the last two cells in `d7e8a76`.

**3. [Rule 3 - Blocking] The plan's own gate parsed the wrong "## Limitations"**
- **Issue:** a sentence from plan 11-01 in the Toolchain section contained the literal text "`## Limitations`", so the gate's split picked it up first.
- **Fix:** reworded that one sentence to "recorded again as L-05 in the Limitations section"; meaning unchanged. **Commit:** `d7e8a76`.

**4. [Plan assumption stale] Production diff guard cannot exit 0**
- The plan's last check `git diff --quiet 2aa9156 -- drinkpulse drinkpulse.xcodeproj` assumes no production change since the phase start. Plan 11-11 made the owner-approved D11-21 change to `drinkpulse/Info.plist` (1 line added). I checked the intended property instead: `git diff --name-only 2aa9156 -- drinkpulse drinkpulse.xcodeproj` lists exactly `drinkpulse/Info.plist` and `--numstat` reads 1 added, 0 removed. This plan changed no production or project file.

**5. Live changed-file list is ten, not nine**
- `git diff --stat a38a75f HEAD -- drinkpulse` lists the expected nine plus `drinkpulse/Info.plist` (the D11-21 change). L-03 names all ten one by one with line counts and says so, as the plan instructed for a differing live list.

**6. Result files are the MCP full-summary file**
- The MCP tool result for U1 was truncated to 100 of 167 tests, and the tool result text cannot be written to disk by the executor. Each result file is the tool's `fullSummaryPath` file (all tests, state per test); the counts in the rows come from the tool result and equal the number of entries in the file (167 for U1).

## Auth gates

None.

## Known Stubs

None. No source file was created or changed by this plan.

## Threat Flags

None. The evidence holds counts, test identifiers and PASS or FAIL values only; a scan for identifier-shaped strings in `11-EVIDENCE.md` found none. The Phase 10 device figures are quoted as historical counts.

## Verification

- Task 1, 2 and 3 gates (from the plan, with the source-guard adaptation in deviation 4) pass; every result digest in the evidence equals the SHA-256 of its file.
- Active destination before every group: iPhone 18 Pro, iOS 27.2.

## Self-Check: PASSED

- Result files `g1-ui.result.txt`, `g2-ui.result.txt`, `g3-ui.result.txt`, `g4-ui.result.txt`, `u1-unit.result.txt` exist in the stamp directory and their digests match the evidence.
- Commits `1fbab49`, `536e2f2`, `d7e8a76` are ancestors of HEAD.
