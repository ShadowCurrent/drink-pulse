---
phase: 09-swiftui-design-system-modernization
plan: "08"
subsystem: ui
tags: [liquid-glass, dashboard, glasseffectcontainer, c013, governance, revert, ui-tests]

requires:
  - phase: 09-swiftui-design-system-modernization
    provides: "09-07 owner decision revert-container-only, C013 brief draft, Route D acknowledgement"
provides:
  - "C013 outcome approve (revert-container-only) in 08-DECISION-C013.md, an independent C013 row in 08-DECISION-REGISTER.md, and a C013 row in the 08-INVENTORY.md eligible-scope table, committed before the source change"
  - "DashboardView.swift restored to its form before commit 553ea58 (GlassEffectContainer removed); no other production change"
  - "Evidence logs build/d1-debug-base.log, d1-debug-after.log, d1-release-base.log, d1-release-after.log, d1-scoped-ui.log, flash-metrics-FIX.txt, flash-metrics-V0.txt (git-ignored)"
affects: [09-09, 09-10]

actuals:
  tokens: 9000
  tasks: 1
  commits: 2
plan_head_before: d35681be44602630482a0bbd536071076f963610
plan_head_after: 5b95ab7

key-files:
  created: []
  modified:
    - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C013.md
    - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-REGISTER.md
    - .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY.md
    - drinkpulse/Features/Dashboard/DashboardView.swift
    - docs/DEVLOG.md

key-decisions:
  - "Route D semantics (owner-acknowledged): no flash assertion added to the harness; owner device confirmation (plan 09-10) is the only flash proof"
  - "Release builds go through CLI xcodebuild with missing-mcp-capability=Release-configuration-selection (BuildProject has only workspaceIdentifier and buildForTesting)"
  - "Full UI suite not run: neither DPGlass.swift nor RootShellView.swift changed"
  - "Plan stopped at a checkpoint: the scoped-suite gate cannot pass because of two failures that are not caused by the revert"

requirements-completed: []  # MOD-02 stays open: the revert fixes neither the simulator crash nor the device flicker; requirements mark-complete was not run

coverage:
  - id: D1
    description: "Owner C013 decision recorded in governance artifacts before the source change; unauthorized 553ea58 container removed"
    requirement: "MOD-02"
    verification:
      - kind: other
        ref: "python verifier of Task 1 (brief outcome, register row, acknowledgement line, no source change before the record) and the container-state gate (GlassEffectContainer absent, brief says retained: no, glassEffect intact in DPGlass.swift)"
        status: pass
    human_judgment: true
    rationale: "Whether the device flicker is gone can only be judged on the owner's iPhone (plan 09-10)"
  - id: D2
    description: "Scoped UI suites green after the correction"
    requirement: "MOD-02"
    verification:
      - kind: ui_test
        ref: "build/d1-scoped-ui.log (DP_RESULT status=failed passed=47 failed=4)"
        status: fail
    human_judgment: false
    rationale: "2 History edit tests fail identically at the governance commit; 2 SheetDismissTabSwitchUITests tests crash the app (known simulator glass crash). Both need an owner decision."

duration: 45min
completed: 2026-11-13
status: paused
paused_reason: "Owner decision 2026-11-13: fix the simulator glass crash first (workaround must keep live glassEffect). History edit-test failures waived by name for this gate only."
---

# Phase 09 Plan 08: Record C013 and restore the Dashboard layout Summary

**The owner's revert-container-only decision is on record (brief, register, inventory) and `DashboardView.swift` is back to its pre-553ea58 form, but the plan stops at a checkpoint: the scoped UI suites are not green because of two History edit-test failures that already fail at the governance commit and two crashing harness tests.**

## Performance

- **Duration:** about 45 min (approximate; build and test waits dominate)
- **Completed:** 2026-11-13
- **Tasks:** Task 1 complete; Task 2 applied and built but its preserve-behavior gate fails (status gaps_found)
- **Files modified:** 5 tracked (3 governance files, `DashboardView.swift`, `docs/DEVLOG.md`)

## Accomplishments

- Governance commit `ae37187` (before any source change): `08-DECISION-C013.md` records Outcome approve, date 2026-11-13, exact scope "restore `DashboardView.swift` to its form before commit `553ea58` and make no other source change", the verbatim owner response (English translation, Polish original referenced), and `Automated flash regression acknowledged: none (Route D) — owner device confirmation is the only proof`. `Dashboard container retained: no` and `Size review trigger: not tripped` stand. Independent C013 row and "Later discoveries" note in the register; C013 row in the inventory eligible-scope table. C001 to C012 untouched.
- Production commit `5b95ab7`: `git checkout 553ea58^ -- drinkpulse/Features/Dashboard/DashboardView.swift` (24 lines, one file; `git diff 553ea58^` on the file is empty). `553ea58` was the only commit that touched the file after `d863b17`. `DPGlass.swift` still holds `.glassEffect(`; `RootShellView.swift` and the harness are unchanged.
- Builds: Debug (Xcode MCP `BuildProject` with `buildForTesting`, `GetBuildLog` severity warning: 0) and Release (CLI) report no warning apart from the owner-ratified appintentsmetadataprocessor packaging note, baseline and after. File-size check clean.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Release null build after the restore**
- **Found during:** Task 2 step 3
- **Issue:** Two Release builds right after `git checkout` ran no compile task at all (nothing printed between planning and `BUILD SUCCEEDED`), so they would have proved nothing about the restored file.
- **Fix:** `touch` on `DashboardView.swift` (content unchanged) forced the real recompile; that output is the one kept in `build/d1-release-after.log`. The Debug MCP build was repeated after the touch and its log shows `DashboardView.swift` compiled.
- **Files modified:** none (mtime only)

**2. [Rule 3 - Blocking] Route D gate reads files that never existed**
- **Found during:** Task 2 step 4
- **Issue:** The excursion gate reads `build/flash-metrics-V0.txt` and `-FIX.txt` even under Route D, but no baseline was ever measured.
- **Fix:** `flash-metrics-V0.txt` holds one comment line stating that no baseline exists; `flash-metrics-FIX.txt` holds the completed control landings and the one sheet landing, labelled as not used for any excursion count. No value was invented.
- **Files modified:** none tracked (git-ignored `build/`)

### Plan steps not met

- Task 2 scoped-suite gate (`build/d1-scoped-ui.log` must show `status=succeeded failed=0`): fails, see Issues Encountered. The full-suite run was not required (no shared file changed) and was not run.
- Route D: no flash assertion added, by plan. The simulator gave no flash signal.

## Issues Encountered

Scoped UI result: 51 tests run (48 non-harness, 3 harness), 47 passed, 4 failed. `InsightsUITests.test_heroCard_holdsHeight_whenSwitchingToAllTimeScope` was excluded by name as documented.

| Test | Result | Classification |
|---|---|---|
| `HistoryInteractionUITests/test_editCustomNameAndNotes_persist` (line 165, row should show custom name 'Tyskie IPA') | failed, failed on the one retry | Pre-existing at the governance commit: failed identically with the `GlassEffectContainer` temporarily put back (HEAD state), then restored. Not caused by the revert; unrelated to the Dashboard. Not in the documented known-failure list. |
| `HistoryInteractionUITests/test_editCategoryChange_persists` (line 220, row should show 150 ml wine default) | failed, failed on the one retry | Same as above. Note `.planning/debug/resolved/contextmenu-zoom-glitch.md` records this test as flaky in an earlier session; it now fails deterministically. |
| `SheetDismissTabSwitchUITests/test_sheetCancelThenTabSwitch_cycle_staysNavigable_recordsFrameDeltas` | failed: `com.haniewicz.drinkpulse crashed` (43.8 s) | Known simulator Liquid Glass crash on HEAD (09-FLASH-DIAGNOSIS.md). The revert does not remove it (owner option text). Not skipped, not deleted. |
| `SheetDismissTabSwitchUITests/test_sheetCancelThenTabSwitch_emptyStore_recordsFrameDeltas` | failed: `com.haniewicz.drinkpulse crashed` (160.1 s) | Same crash, empty-sheet phase. |
| `SheetDismissTabSwitchUITests/test_tabSwitchWithoutSheet_control_recordsFrameDeltas` | passed | n/a |

Navigation suites ShellNavigationUITests (4 of 4), AddDrinkFlowUITests (6 of 6), DashboardUITests (5 of 5), InsightsUITests (6 of 6), InsightsScrubUITests, SettingsUITests, WrongRowContextMenuTargetUITests, and ContextMenuDeleteConfirmationUITests passed with no retry. The plan's retry rule counts a `SheetDismissTabSwitchUITests` failure as a regression, but this one is the known crash that the owner brief says the revert does not fix, so classifying it as a regression of the revert would be wrong. The gate decision is the owner's.

Retry semantics: the MCP path used one explicit second `RunSomeTests` of only the failed tests, so the CLI `-retry-tests-on-failure -test-iterations 2` semantics are moot; no CLI test step was taken.

Xcode tooling record for plan 09-09 (from the `build/d1-*.log` source headers):

| Step | Log | Source header |
|---|---|---|
| Debug baseline and after | `d1-debug-base.log`, `d1-debug-after.log` | `xcode-mcp XcodeListWorkspaces XcodeListRunDestinations BuildProject(buildForTesting=true) GetBuildLog(severity=warning)` |
| Release baseline and after | `d1-release-base.log`, `d1-release-after.log` | `cli-xcodebuild missing-mcp-capability=Release-configuration-selection` (live `BuildProject` schema: only `workspaceIdentifier` and `buildForTesting`) |
| Scoped UI, retry, governance-state classification, harness | `d1-scoped-ui.log` | `xcode-mcp XcodeListWorkspaces XcodeListRunDestinations GetTestList RunSomeTests` |

## Known Stubs

None.

## Threat Flags

None. No new network, auth, file, or schema surface.

## Owner decisions after the checkpoint (2026-11-13)

Status: paused, not complete. Recorded verbatim in `09-FLASH-DIAGNOSIS.md` ("Owner decisions after 09-08 scoped UI gate").

- Open crash gate: "Najpierw napraw crash" (fix the crash first). The two `SheetDismissTabSwitchUITests` failures stay as the open gate until a crash workaround that keeps live `glassEffect` (no material substitution) is accepted by the owner. No skip, quarantine, or `XCTExpectFailure` was added.
- Waiver: "Osobny defekt, waiver (Rekomendowane)". `HistoryInteractionUITests/test_editCustomNameAndNotes_persist` and `HistoryInteractionUITests/test_editCategoryChange_persists` are waived by name for this plan's gate only; tracked in `.planning/todos/pending/2026-11-13-history-edit-uitests-failing.md`.
- The plan is not complete: `requirements-completed` stays empty and `requirements mark-complete` was not run.

## Next Phase Readiness (superseded by the section above; kept as written at the checkpoint)

Blocked for the owner. Decisions needed before 09-09 and 09-10:

1. How to treat the two crashing `SheetDismissTabSwitchUITests` tests (skip entry in the scheme, quarantine behind a launch argument, `XCTExpectFailure`, or fix the crash first). They have no skip entry and fail any full UI run.
2. Whether the two `HistoryInteractionUITests` edit-test failures are accepted as pre-existing (separate defect) or must be fixed before this plan's gate passes.

MOD-02 is not marked complete.

## Self-Check: PASSED

- `ae37187` and `5b95ab7` exist in history; `DashboardView.swift` has no `GlassEffectContainer`; `DPGlass.swift` still has `.glassEffect(`.
- `build/d1-debug-base.log`, `d1-debug-after.log`, `d1-release-base.log`, `d1-release-after.log`, `d1-scoped-ui.log`, `flash-metrics-FIX.txt`, `flash-metrics-V0.txt` exist.
