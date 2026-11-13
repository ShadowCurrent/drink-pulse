---
phase: 09-swiftui-design-system-modernization
plan: "06"
subsystem: testing
tags: [xcuitest, liquid-glass, glasseffect, crash-isolation, tabview, sheet, xcode-mcp, diagnosis]

requires:
  - phase: 09-swiftui-design-system-modernization
    provides: "09-05 VoiceOver regression and the shared build/ sequencing; 09-02 Add Drink return-to-originating-tab behavior that the harness navigability asserts cover"
provides:
  - "Sheet-then-tab-switch cycle harness (SheetDismissTabSwitchUITests) with a no-sheet control and a held-back empty-store test; frame-delta metric lines were never collected because HEAD crashes in the cycle"
  - "Pre-registered Route S / Route D decision rule, threshold basis, and data-dependence criteria, committed before any measurement and left unapplied"
  - "Reproducible simulator crash on HEAD narrowed to one live glassEffect card per tab (EXC_BREAKPOINT in MaterialProviderBox.resolveLayers / GlassEffectResolvedMaterial.value.getter), with a standalone minimal repro and an unsubmitted Apple Feedback draft"
  - "Owner close-out decision C (no device session) and the C006 acceptance statement, recorded in 09-FLASH-DIAGNOSIS.md for plan 09-07 to consume"
affects: [09-07, 09-08, 09-09, 09-10]

actuals:
  tokens: 16000
  tasks: 0
  commits: 7
plan_head_before: c763fa53853a835f2ebb9e7b24cc26ef16a43116
plan_head_after: 813c33b7a397e2f42fb9f41cdb0c3879279c88a8

tech-stack:
  added: []
  patterns:
    - "Pre-register hypotheses and decision rules in a committed section before any run; results land in a later commit"
    - "Diagnostic variants live as single commits on local diag/ branches in worktrees outside the repository, never merged"

key-files:
  created:
    - drinkpulseUITests/Features/Shell/SheetDismissTabSwitchUITests.swift
    - .planning/phases/09-swiftui-design-system-modernization/09-FLASH-DIAGNOSIS.md
  modified:
    - docs/DEVLOG.md

key-decisions:
  - "Owner decision B (2026-11-13), crash first: frame-delta measurement paused, crash on HEAD isolated before anything else"
  - "Owner decision C round 2 (2026-11-13): one more simulator bisect round plus a standalone minimal repro, then stop for a decision"
  - "Owner decision C no-device (2026-11-13, C: bez urzadzenia): skip the device session; re-plan 09-07 on simulator evidence; the reproducible simulator crash counts as the measured defect decision C006 requires"
  - "No production source changed in this plan; diagnostic variants stay on local diag/ branches"

patterns-established:
  - "Crash-first diagnosis: when a harness shake-down crashes the app, isolate the crash with pre-registered variants before measuring a softer symptom"
  - "Two-clean-runs rule before accepting a no-crash result for an intermittent crash"

requirements-completed: []  # MOD-02 gap D1 stays open until plans 09-07 to 09-10; this plan only supplies diagnosis evidence

# Metrics
duration: 90min
completed: 2026-11-13
status: complete
---

# Phase 09 Plan 06: Flash diagnosis harness and crash isolation Summary

**Cross-tab glass flicker diagnosis became a reproducible simulator crash investigation: one live `glassEffect` card per tab, after an Add Drink then Cancel sheet cycle, crashes the app with `EXC_BREAKPOINT` in `GlassEffectResolvedMaterial.value.getter`, reproduced in a standalone minimal project; the owner skipped the device session and accepted the crash as the C006 measured defect.**

## Performance

- **Duration:** about 90 min (approximate, from the 09-05 completion commit to this close-out)
- **Completed:** 2026-11-13
- **Tasks:** 0 of 3 completed as written; Task 1 steps 1 to 4 done, everything else replaced or skipped by owner decision (see Deviations)
- **Files modified:** 3 (1 UI-test file created, 1 evidence file created, `docs/DEVLOG.md` appended); no production source

## Accomplishments

- Built and committed the cycle harness `SheetDismissTabSwitchUITests` (218 lines, three tests: sheet cycle, no-sheet control, held-back empty-store) together with the pre-registered decision rule, threshold basis, and data-dependence criteria (`010a843`), before any measurement existed. The rule was never applied to data and is unchanged.
- The shake-down found that HEAD crashes in the sheet cycle at cycle 2 or 3, which made the planned 20-landing baseline impossible (`83fe65a`).
- Crash isolation round 1 (three simulator variants): glass in tab content plus a sheet cycle is sufficient; the Dashboard `GlassEffectContainer` and the Add Drink sheet content are not required; replacing glass with a regular material, or removing the sheet, completes 20 of 20 (`df74b25`, `dfb45e3`).
- Crash isolation round 2: one live `glassEffect` card suffices on either tab (`DashboardHeroCard` on Home, `InsightsScopeNavigator` on Insights), and the crash occurs at the first update after a tab switch onto the tab with live glass. A standalone minimal repro outside the repository reproduced the same signature in 1 of 2 completed glass runs while its material control completed 20 of 20 in 2 of 2 runs. An Apple Feedback draft exists and was not submitted (`0cdb397`, `6b0b063`).
- Recorded the owner close-out decision, the C006 acceptance statement, the unexecuted steps, the open items (CH6, flicker-to-crash link), and the evidence inventory for plan 09-07 (`813c33b`).

## Task Commits

1. **Task 1: harness and pre-registered rule (steps 1 to 4)** - `010a843` (test)
2. **Task 1: harness shake-down crash finding** - `83fe65a` (docs)
3. **Crash isolation round 1: pre-registration and results** - `df74b25`, `dfb45e3` (docs)
4. **Crash isolation round 2: pre-registration, then results and minimal repro** - `0cdb397`, `6b0b063` (docs)
5. **Close-out: owner decision C record and DEVLOG entry** - `813c33b` (docs)

Task 1 step 5 (HEAD baseline), commit H, Task 2 as written, and Task 3 were not executed; no commit exists for them.

**Plan metadata:** the final docs commit of this plan (summary, state, roadmap).

## Files Created/Modified

- `drinkpulseUITests/Features/Shell/SheetDismissTabSwitchUITests.swift` - cycle harness: Add Drink, Cancel, tab switch, frame-delta sampling, metric lines to file, stdout, and attachment; navigability assertions only. On HEAD the sheet-mode test does not complete because the app crashes (below).
- `.planning/phases/09-swiftui-design-system-modernization/09-FLASH-DIAGNOSIS.md` - defect record, corrections, provenance, pre-registered rule, shake-down finding, two crash-isolation rounds with results, minimal repro, Feedback draft, owner close-out. The "Baseline results" heading is intentionally empty.
- `docs/DEVLOG.md` - entry "2026-11-13 16:35" for this plan.

## Decisions Made

- Owner decisions B, C round 2, and C no-device are recorded verbatim with dates in the evidence file; the last one carries the C006 acceptance statement. CH6 stays open.
- No production code was changed; the centralized Liquid Glass layer (`DPGlass.swift`) was not replaced or redesigned (plan prohibition honored). Variants V1, V3, V4 and the `diag/09-crash-r2-*` variants exist only on local `diag/` branches in worktrees outside the repository.
- `requirements-completed` is left empty on purpose: this plan supplies diagnosis evidence for the open MOD-02 gap D1 and does not close it. `requirements mark-complete` was not run.

## Deviations from Plan

### Owner-directed scope change (not an auto-fix)

**1. [Owner decision] Crash-first investigation replaced the frame-delta measurement and the device session**
- **Found during:** Task 1 step 5 (baseline measurement)
- **Issue:** HEAD crashes at cycle 2 or 3 of the sheet cycle (`EXC_BREAKPOINT`, `GlassEffectResolvedMaterial.value.getter`), so the planned 20 sheet landings and the Route S / Route D classification cannot be produced. The harness could not do what the plan assumed.
- **Resolution:** At three decision checkpoints the owner chose B "crash first" (pause measurement), then C "bisect round 2 only", then C "bez urzadzenia" (no device session). Crash-isolation variants and a minimal repro replaced the planned frame-delta variants; the crash became the evidence for decision C006.
- **Not executed:** Task 1 step 5 (HEAD and control baseline, "Baseline results", Route line); commit H (hypotheses H1 to H5, the classification table); Task 2 as written (frame-delta measurement of V1, V3, V4 and the "Variant simulator results" with excursion counts); Task 3 (owner device session, six configurations). The crash-isolation hypotheses CH1 to CH6 and RH1 to RH6 were pre-registered in their own commits before their runs, which preserves the ancestry rule the plan wanted.
- **Files modified:** none beyond the evidence file, `docs/DEVLOG.md`, and the harness
- **Committed in:** `83fe65a`, `df74b25`, `dfb45e3`, `0cdb397`, `6b0b063`, `813c33b`

### Tooling deviations

Tooling deviations (variant worktrees, Xcode MCP use, any CLI step with its named missing capability) are recorded in the "Xcode tooling record" subsection and the shake-down and round sections of `09-FLASH-DIAGNOSIS.md`; they are not repeated here.

---

**Total deviations:** 1 owner-directed scope change; no auto-fixes (Rules 1 to 3 not triggered)
**Impact on plan:** The plan's measurement-and-device-session goal was not achieved; its purpose (an evidenced, owner-accepted defect for C006 before any Liquid Glass change) was met by a different route. Plan 09-07 must be re-planned on the simulator evidence.

## Issues Encountered

- HEAD crash blocks the pre-registered baseline (above).
- One minimal-repro run failed with "The result bundle could not be opened as it is incomplete"; it was recorded as an infrastructure error, not a result, and repeated.
- The crash is intermittent (2 to 8 cycles survived in the app variants; 1 of 2 glass runs in the minimal repro), so a clean glass run does not clear a build.

## Known Stubs

None. The empty "Baseline results" heading in `09-FLASH-DIAGNOSIS.md` is intentional and explained in place; no stub code was written.

## Threat Flags

None. No network, auth, file-access, or schema surface was added. No device screenshots, recordings, or logs entered the repository; crash reports are kept outside it.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 09-07 should be re-planned around the crash: evidence is in 09-FLASH-DIAGNOSIS.md (round 1 and round 2 tables, minimal repro at `/Users/fempter/Developer/drinkpulse-diag/minimal-repro`, the Feedback draft).
- Open and not settled: CH6 (simulator-only?), the flicker-to-crash link, per-variant crash rate, and which property of one glass card triggers the crash. Submitting the Apple Feedback draft is the owner's call.
- All `diag/` branches and `../drinkpulse-diag/` worktrees remain in place for plan 09-09 cleanup.

## Self-Check: PASSED

- FOUND: `drinkpulseUITests/Features/Shell/SheetDismissTabSwitchUITests.swift`
- FOUND: `.planning/phases/09-swiftui-design-system-modernization/09-FLASH-DIAGNOSIS.md`
- FOUND: `docs/DEVLOG.md`
- FOUND commits (ancestors of HEAD): `010a843`, `83fe65a`, `df74b25`, `dfb45e3`, `0cdb397`, `6b0b063`, `813c33b`
- Measured: 7 commits since `plan_head_before` (`c763fa5`); `git diff c763fa5..HEAD -- drinkpulse` is empty (no production source changed); working tree clean before this summary; 9 `diag/` branches and 5 worktrees untouched.

---
*Phase: 09-swiftui-design-system-modernization*
*Completed: 2026-11-13*
