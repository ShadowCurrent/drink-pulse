---
phase: 09-swiftui-design-system-modernization
plan: "08"
subsystem: ui
tags: [liquid-glass, dashboard, glasseffectcontainer, c013, governance, revert, ui-tests, deferral]

requires:
  - phase: 09-swiftui-design-system-modernization
    provides: "09-07 owner decision revert-container-only, C013 brief draft, Route D acknowledgement"
provides:
  - "C013 outcome approve (revert-container-only) in 08-DECISION-C013.md, an independent C013 row in 08-DECISION-REGISTER.md, and a C013 row in the 08-INVENTORY.md eligible-scope table, committed before the source change"
  - "DashboardView.swift restored to its form before commit 553ea58 (GlassEffectContainer removed); no other production change"
  - "Owner deferral of D1 recorded verbatim in 09-FLASH-DIAGNOSIS.md with the full open-items list, and a deferral status plus resume recipe in the D1 todo"
  - "Two crashing SheetDismissTabSwitchUITests methods skipped in the drinkpulse scheme (code kept; no-sheet control stays enabled)"
  - "Evidence logs build/d1-debug-base.log, d1-debug-after.log, d1-release-base.log, d1-release-after.log, d1-scoped-ui.log, d1-scheme-skip.log, flash-metrics-FIX.txt, flash-metrics-V0.txt (git-ignored)"
affects: [09-09, 09-10]

actuals:
  tokens: 14000
  tasks: 2
  commits: 9
plan_head_before: d35681be44602630482a0bbd536071076f963610
plan_head_after: c826450

key-files:
  created: []
  modified:
    - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C013.md
    - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-REGISTER.md
    - .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY.md
    - drinkpulse/Features/Dashboard/DashboardView.swift
    - drinkpulse.xcodeproj/xcshareddata/xcschemes/drinkpulse.xcscheme
    - drinkpulseUITests/Features/Shell/SheetDismissTabSwitchUITests.swift
    - .planning/phases/09-swiftui-design-system-modernization/09-FLASH-DIAGNOSIS.md
    - .planning/todos/pending/2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md
    - docs/DEVLOG.md

key-decisions:
  - "Route D semantics (owner-acknowledged): no flash assertion added to the harness; owner device confirmation was the only flash proof, and the owner has now deferred D1, so there is no flash proof in Phase 09"
  - "Release builds go through CLI xcodebuild with missing-mcp-capability=Release-configuration-selection (BuildProject has only workspaceIdentifier and buildForTesting)"
  - "Full UI suite not run: neither DPGlass.swift nor RootShellView.swift changed"
  - "Owner deferred D1 (simulator crash and device flicker) out of Phase 09 to the backlog todo; crash-workaround round stopped before any candidate was measured"
  - "Two crashing harness tests skipped in the scheme, not deleted, quarantined, or XCTExpectFailure-wrapped"

requirements-completed: []  # MOD-02 is NOT marked here: plan 09-10 marks it complete with the D1 exception recorded

coverage:
  - id: D1
    description: "Owner C013 decision recorded in governance artifacts before the source change; unauthorized 553ea58 container removed"
    requirement: "MOD-02"
    verification:
      - kind: other
        ref: "python verifier of Task 1 (brief outcome, register row, acknowledgement line, no source change before the record) and the container-state gate (GlassEffectContainer absent, brief says retained: no, glassEffect intact in DPGlass.swift)"
        status: pass
    human_judgment: true
    rationale: "Whether the device flicker is gone can only be judged on the owner's iPhone; the owner deferred that judgement together with D1"
  - id: D2
    description: "Scoped UI suites after the correction: 47 of 51 passed at the gate run; the 2 History edit failures are waived by name and the 2 crashing harness tests are skipped in the scheme"
    requirement: "MOD-02"
    verification:
      - kind: automated_ui
        ref: "build/d1-scoped-ui.log (DP_RESULT status=failed passed=47 failed=4) and build/d1-scheme-skip.log (control passes; GetTestList shows the two skipped methods disabled)"
        status: fail
    human_judgment: false
    rationale: "Not green: a clean scoped run was never obtained. The 4 failures are covered by named waivers (see Waivers), not by a passing run."

duration: 75min
completed: 2026-11-13
status: complete
---

# Phase 09 Plan 08: Record C013 and restore the Dashboard layout Summary

**The owner's revert-container-only decision is on record and `DashboardView.swift` is back to its pre-553ea58 form; the plan closes with deferral: the simulator crash and the whole-screen device flicker (D1) are deferred out of Phase 09, two History edit tests are waived by name, and the two crashing harness tests are skipped in the scheme.**

## Performance

- **Duration:** about 75 min over two sessions (approximate; build and test waits dominate)
- **Completed:** 2026-11-13
- **Tasks:** Task 1 complete; Task 2 applied and built; its scoped-suite gate was closed by owner waiver and deferral, not by a green run
- **Files modified:** 9 tracked (3 governance files, `DashboardView.swift`, the scheme, the harness test file, the diagnosis, the D1 todo, `docs/DEVLOG.md`)

## Accomplishments

- Governance commit `ae37187` (before any source change): `08-DECISION-C013.md` records Outcome approve, date 2026-11-13, exact scope "restore `DashboardView.swift` to its form before commit `553ea58` and make no other source change", the verbatim owner response (English translation, Polish original referenced), and `Automated flash regression acknowledged: none (Route D) — owner device confirmation is the only proof`. `Dashboard container retained: no` and `Size review trigger: not tripped` stand. Independent C013 row and "Later discoveries" note in the register; C013 row in the inventory eligible-scope table. C001 to C012 untouched.
- Production commit `5b95ab7`: `git checkout 553ea58^ -- drinkpulse/Features/Dashboard/DashboardView.swift` (24 lines, one file; `git diff 553ea58^` on the file is empty). `553ea58` was the only commit that touched the file after `d863b17`. `DPGlass.swift` still holds `.glassEffect(`; `RootShellView.swift` and the harness logic are unchanged.
- Builds: Debug (Xcode MCP `BuildProject` with `buildForTesting`, `GetBuildLog` severity warning: 0) and Release (CLI) report no warning apart from the owner-ratified appintentsmetadataprocessor packaging note, baseline and after. Debug MCP build repeated after the scheme edit: success, 0 warnings. File-size check clean.
- Deferral commits: `830dcd6` adds `SkippedTests` for the two crashing methods under the `drinkpulseUITests` testable of `drinkpulse.xcscheme` and English comments next to them pointing at the D1 todo; `c826450` appends "Owner deferral of D1 (2026-11-13)" to `09-FLASH-DIAGNOSIS.md` (Polish and English verbatim, the statement that the crash-workaround round stopped before any candidate was measured, and the open-items list) and a "Status 2026-11-13: deferred from Phase 09" section with pointers and a resume recipe to the D1 todo. The todo has no `resolves_phase` frontmatter, so closing the phase cannot auto-close it.
- Scheme skip verification (Xcode MCP, main workspace only, `build/d1-scheme-skip.log`): `xmllint` OK; `GetTestList` reports `TEST_ENABLED: false` for the two skipped methods (counts: 2 disabled, 816 enabled) and `true` for the control; Debug build succeeds with 0 warnings.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Release null build after the restore**
- **Found during:** Task 2 step 3
- **Issue:** Two Release builds right after `git checkout` ran no compile task at all, so they would have proved nothing about the restored file.
- **Fix:** `touch` on `DashboardView.swift` (content unchanged) forced the real recompile; that output is kept in `build/d1-release-after.log`. The Debug MCP build was repeated after the touch and its log shows `DashboardView.swift` compiled.
- **Files modified:** none (mtime only)

**2. [Rule 3 - Blocking] Route D gate reads files that never existed**
- **Found during:** Task 2 step 4
- **Issue:** The excursion gate reads `build/flash-metrics-V0.txt` and `-FIX.txt` even under Route D, but no baseline was ever measured.
- **Fix:** `flash-metrics-V0.txt` holds one comment line stating that no baseline exists; `flash-metrics-FIX.txt` holds the completed control landings and the one sheet landing, labelled as not used for any excursion count. No value was invented.
- **Files modified:** none tracked (git-ignored `build/`)

### Plan-level deviations

**3. Crash-first detour (owner decision "Najpierw napraw crash", 2026-11-13).** After the scoped gate failed, the owner asked for the simulator crash to be fixed first, with live `glassEffect` retained. The work was pre-registered (`09-FLASH-DIAGNOSIS.md`: crash-workaround candidates G1, G2, G3, G5, G6 and acceptance rule, hypothesis H6, video flicker metric), and the symbolication of our `DesignLibrary` frames was done by static analysis. No candidate was measured.

**4. Crash-workaround round stopped before any measurement.** The owner stopped the round ("we probably need to skip this analysis for now and defer this problem"). No result exists for G1, G2, G3, G5, G6, for the session control blocks, or for the video metric; none is claimed anywhere.

**5. D1 deferred out of Phase 09.** Owner decision "Zamknij z odroczeniem": D1 moves to the backlog todo, this plan finishes with waivers, 09-09 does docs and cleanup, 09-10 closes the phase with D1 marked deferred instead of device confirmation, MOD-02 is to be marked complete with the D1 exception recorded (by 09-10, not here).

### Plan steps not met

- Task 2 scoped-suite gate (`build/d1-scoped-ui.log` must show `status=succeeded failed=0`): not met. It is closed by named owner waivers, not by a passing run. The full-suite run was not required (no shared file changed) and was not run.
- Scheme skip not confirmed end to end: an explicit class selection through Xcode MCP `RunSomeTests` for `SheetDismissTabSwitchUITests` ran all three methods (1 passed: the no-sheet control; 2 crashed: the skipped methods), so that tool overrides a scheme skip when the tests are named explicitly. The skip is evidenced by `GetTestList` (the two methods disabled), not by a run that skipped them. A `RunAllTests` or full-suite run, which would show it, was not performed (about 25 min, no shared file changed); phase 09-10 or the next full run is the place to see it.
- Route D: no flash assertion added, by plan. The simulator gave no usable flash signal; the owner later reported seeing the flicker on the simulator during a harness run (see the diagnosis), so "no signal" was a measurement gap, not absence.

## Waivers (by name)

| Item | Reason | Where tracked |
|---|---|---|
| `HistoryInteractionUITests/test_editCustomNameAndNotes_persist` | Pre-existing failure, identical with the `GlassEffectContainer` put back; unrelated to the Dashboard. Owner: "Osobny defekt, waiver" | `.planning/todos/pending/2026-11-13-history-edit-uitests-failing.md` |
| `HistoryInteractionUITests/test_editCategoryChange_persists` | Same as above | same todo |
| `SheetDismissTabSwitchUITests/test_sheetCancelThenTabSwitch_cycle_staysNavigable_recordsFrameDeltas` | Intermittent iOS 27 simulator Liquid Glass crash; skipped in the scheme (owner: "Skip w schemacie"); code kept | `.planning/todos/pending/2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md` (D1) |
| `SheetDismissTabSwitchUITests/test_sheetCancelThenTabSwitch_emptyStore_recordsFrameDeltas` | Same crash in its empty-sheet phase; skipped in the scheme; code kept | same D1 todo |

The no-sheet control `SheetDismissTabSwitchUITests/test_tabSwitchWithoutSheet_control_recordsFrameDeltas` stays enabled and passed twice (gate run and the scheme-skip run).

## Issues Encountered

Scoped UI result at the gate run: 51 tests run (48 non-harness, 3 harness), 47 passed, 4 failed. `InsightsUITests.test_heroCard_holdsHeight_whenSwitchingToAllTimeScope` was excluded by name as documented.

| Test | Result | Classification |
|---|---|---|
| `HistoryInteractionUITests/test_editCustomNameAndNotes_persist` (line 165) | failed, failed on the one retry | Pre-existing at the governance commit. Waived above. |
| `HistoryInteractionUITests/test_editCategoryChange_persists` (line 220) | failed, failed on the one retry | Same. `.planning/debug/resolved/contextmenu-zoom-glitch.md` records it as flaky in an earlier session; it now fails deterministically. |
| `SheetDismissTabSwitchUITests` sheet-mode and empty-store | `com.haniewicz.drinkpulse crashed` (43.8 s and 160.1 s) | Known simulator Liquid Glass crash. Skipped in the scheme; D1 deferred. |
| `SheetDismissTabSwitchUITests` no-sheet control | passed | n/a |

Navigation suites ShellNavigationUITests (4 of 4), AddDrinkFlowUITests (6 of 6), DashboardUITests (5 of 5), InsightsUITests (6 of 6), InsightsScrubUITests, SettingsUITests, WrongRowContextMenuTargetUITests, and ContextMenuDeleteConfirmationUITests passed with no retry.

Retry semantics: the MCP path used one explicit second `RunSomeTests` of only the failed tests, so the CLI `-retry-tests-on-failure -test-iterations 2` semantics are moot; no CLI test step was taken.

Xcode tooling record for plan 09-09 (from the `build/d1-*.log` source headers):

| Step | Log | Source header |
|---|---|---|
| Debug baseline and after | `d1-debug-base.log`, `d1-debug-after.log` | `xcode-mcp XcodeListWorkspaces XcodeListRunDestinations BuildProject(buildForTesting=true) GetBuildLog(severity=warning)` |
| Release baseline and after | `d1-release-base.log`, `d1-release-after.log` | `cli-xcodebuild missing-mcp-capability=Release-configuration-selection` (live `BuildProject` schema: only `workspaceIdentifier` and `buildForTesting`) |
| Scoped UI, retry, governance-state classification, harness | `d1-scoped-ui.log` | `xcode-mcp XcodeListWorkspaces XcodeListRunDestinations GetTestList RunSomeTests` |
| Scheme skip check | `d1-scheme-skip.log` | `xcode-mcp XcodeListWorkspaces XcodeListRunDestinations GetTestList BuildProject(buildForTesting=true) GetBuildLog(severity=warning) RunSomeTests` |

## Known Stubs

None.

## Threat Flags

None. No new network, auth, file, or schema surface.

## Next Phase Readiness

- 09-09 (docs and cleanup): remove worktrees `v1`, `v3`, `v4`; keep `/Users/fempter/Developer/drinkpulse-diag/work`, `/Users/fempter/Developer/drinkpulse-diag/minimal-repro`, and every `diag/*` branch.
- 09-10 (closure): D1 marked deferred instead of device confirmation; MOD-02 marked complete with the D1 exception recorded. MOD-02 is not marked complete by this plan; `requirements mark-complete` was not run.
- Open and carried to the D1 todo: the whole-screen flicker, the simulator crash, H1 to H6, the unused video metric, the unsubmitted Feedback draft, the crash-versus-relaunch discriminator.

## Self-Check: PASSED

- `ae37187`, `5b95ab7`, `830dcd6`, `c826450` exist in history; `DashboardView.swift` has no `GlassEffectContainer`; `DPGlass.swift` still has `.glassEffect(`; the scheme has two `SkippedTests` entries and passes `xmllint`.
- `build/d1-debug-base.log`, `d1-debug-after.log`, `d1-release-base.log`, `d1-release-after.log`, `d1-scoped-ui.log`, `d1-scheme-skip.log`, `flash-metrics-FIX.txt`, `flash-metrics-V0.txt` exist.
- `git rev-list --count d35681b..c826450` is 9 (the `commits:` value); the SUMMARY, DEVLOG, STATE, and ROADMAP commit follows it.
