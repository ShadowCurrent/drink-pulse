---
phase: 09-swiftui-design-system-modernization
plan: "07"
subsystem: ui
tags: [liquid-glass, glasseffect, diagnosis, decision-brief, owner-decision, c013, tabview, sheet]

requires:
  - phase: 09-swiftui-design-system-modernization
    provides: "09-06 crash-isolation evidence (HEAD crash, per-tab and per-card bisect, minimal repro), the pre-registered Route S / Route D rule and data-dependence criteria, and the owner's C006 acceptance statement"
provides:
  - "Conclusion section in 09-FLASH-DIAGNOSIS.md: H1 to H5 all untested, classification C-INCONCLUSIVE, Data dependence: not shown, Cure proposed: no, with the simulator crash recorded as a layer observation at glassEffect material resolution"
  - "H1 to H5 predictions transcribed unchanged from 09-06-PLAN.md (commit H was never written)"
  - "08-DECISION-C013.md source-backed brief, Outcome pending, apply-proposed-fix not offered"
  - "Verbatim owner decision (Polish original and English translation): revert-container-only, with the Route D no-automated-regression line acknowledged"
affects: [09-08, 09-09, 09-10]

actuals:
  tokens: 7100
  tasks: 2
  commits: 4
plan_head_before: a6a5b30eed6eb39aa2fd559f18989e70480cce10
plan_head_after: 915b4a6ade3191a4e881634ec85a48defb3a2c45

tech-stack:
  added: []
  patterns:
    - "Apply only pre-registered rules in a Conclusion; an input that was never measured is recorded as missing, never invented"
    - "Owner reply transcribed verbatim with the original language and the chosen option id on exactly one line; a recommendation is never an approval"

key-files:
  created:
    - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C013.md
  modified:
    - .planning/phases/09-swiftui-design-system-modernization/09-FLASH-DIAGNOSIS.md
    - docs/DEVLOG.md

key-decisions:
  - "Classification is C-INCONCLUSIVE: no H1 to H5 prediction could be checked (no frame-delta or device data) and the owner skipped the device session"
  - "No cure is proposed: the evidence does not narrow the trigger property, Apple documentation states no cause, and replacing glass with a material is a diagnostic result that the project prohibition forbids as a workaround"
  - "Owner decision C013 (2026-11-13): revert-container-only, acknowledging Automated flash regression: none (Route D) - owner device confirmation is the only proof; device session and Feedback decision stay open; MOD-02 stays open"
  - "The decision authorizes only restoring DashboardView.swift to its pre-553ea58 form in plan 09-08; no DPGlass.swift or glassEffect consumer change"

patterns-established:
  - "Route D semantics when no baseline exists: no automated flash regression, owner device confirmation is the only proof"

requirements-completed: []  # MOD-02 stays open: the owner's decision does not fix the crash or the flicker; requirements mark-complete was not run

coverage:
  - id: D1
    description: "Flicker root cause classified from recorded evidence and the C013 brief drafted with the owner's decision on its scope recorded verbatim"
    requirement: "MOD-02"
    verification:
      - kind: other
        ref: "python3 verifiers of 09-07-PLAN.md Task 1 (conclusion, brief, data-dependence ordering, no production source change) and Task 2 (owner decision section)"
        status: pass
    human_judgment: true
    rationale: "Whether the flicker is the crash path failing softly, and whether it is gone, can only be judged on the owner's device (plan 09-10)"

duration: 20min
completed: 2026-11-13
status: complete
---

# Phase 09 Plan 07: Flicker diagnosis conclusion and C013 decision Summary

**The cross-tab Liquid Glass flicker is classified C-INCONCLUSIVE with no cure proposed, the C013 brief is drafted, and the owner chose revert-container-only (restore the pre-553ea58 Dashboard, acknowledging no automated flash regression exists), which fixes neither the simulator crash nor the device flicker.**

## Performance

- **Duration:** about 20 min across both executor sessions (approximate); the owner decision wait is not counted
- **Completed:** 2026-11-13
- **Tasks:** 2 of 2 (Task 1 auto, Task 2 blocking-human decision checkpoint, resolved by the owner reply)
- **Files modified:** 3 (1 brief created, the evidence file extended, `docs/DEVLOG.md` appended); no production source

## Accomplishments

- Transcribed the H1 to H5 hypotheses and predictions from `09-06-PLAN.md` without change, because commit H was never written (`0d8a6f4`).
- Wrote the Conclusion (`ec7d74c`): verdict table (all five hypotheses untested, no frame-delta or device observation exists), classification C-INCONCLUSIVE (no hypothesis supported, device session skipped), `Data dependence: not shown`, and `Cure proposed: no (C-INCONCLUSIVE)`. The simulator crash is recorded separately as a layer observation at `glassEffect` material resolution, reached through any single call site; what it rules out as required (Dashboard container, Add Drink sheet content, sheet presentation alone, app data, card variety) and what stays unestablished are listed.
- Drafted `08-DECISION-C013.md` in the C006 format (`3d3fa3d`): Outcome pending, `Dashboard container retained: no`, `Size review trigger: not tripped (0 changed lines, 0 files)` labelled as the planner-set convention, `Automated flash regression: none (Route D) - owner device confirmation is the only proof`, apply-proposed-fix marked not offered.
- Recorded the owner's decision in a new "Owner decision on the fix" section (`915b4a6`): reply transcribed in English translation and Polish original, `Chosen option: revert-container-only`, date 2026-11-13, the Route D acknowledgement line, and a scope amendment of none beyond the option text. The brief and the decision register were left unchanged; plan 09-08 records the outcome there.

## Task Commits

1. **Task 1: H1 to H5 transcription** - `0d8a6f4` (docs)
2. **Task 1: Conclusion** - `ec7d74c` (docs)
3. **Task 1: C013 brief, outcome pending** - `3d3fa3d` (docs)
4. **Task 2: owner decision revert-container-only recorded** - `915b4a6` (docs)

**Plan metadata:** the final docs commit of this plan (summary, DEVLOG, state, roadmap).

## Files Created/Modified

- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C013.md` - source-backed brief, Outcome pending until plan 09-08.
- `.planning/phases/09-swiftui-design-system-modernization/09-FLASH-DIAGNOSIS.md` - H1 to H5 transcription, Conclusion, and "Owner decision on the fix" sections appended; no earlier section edited.
- `docs/DEVLOG.md` - entry "2026-11-13 16:50" for this plan.

## Decisions Made

- The owner chose revert-container-only on 2026-11-13. The chosen scope is restoring `drinkpulse/Features/Dashboard/DashboardView.swift` to its form before commit `553ea58` (removes the unauthorized `GlassEffectContainer(spacing: 0)`), executed in plan 09-08. The decision does not authorize any `DPGlass.swift` or `glassEffect` consumer change, any cure, or any claim that the flicker or crash is fixed.
- The owner acknowledged that no automated flash regression exists (Route D); only owner device confirmation can prove a flicker fix.
- The device session and the decision on submitting the draft Apple Feedback text stay open. MOD-02 stays open and the pending todo stays pending.
- The pre-registered thresholds, the Route S / Route D rule, and the data-dependence criteria were not changed and no value was invented for an input that was never measured.

## Deviations from Plan

None - plan executed as written, within the owner-directed re-plan recorded in the continuation notes. The plan's Route S / Route D lines assume a baseline that 09-06 could not produce (HEAD crashes in the sheet cycle); the Conclusion records Route D semantics by the owner's close-out direction and states that the route rule was never applied to data. This was the re-planned scope, not an auto-fix.

Tooling: no build, test, or CLI step was run in this plan (Apple documentation only, through Xcode MCP `DocumentationSearch`); recorded in the Xcode tooling record row for plan 09-07 Task 1.

## Issues Encountered

None. The plan's Task 2 verifier tests for `Route: S` in the evidence file; the file contains no such line, so the verifier correctly selects the Route D acknowledgement text, which matches the brief.

## Known Stubs

None. No source code was written.

## Threat Flags

None. No network, auth, file-access, or schema surface was added.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 09-08 applies exactly the chosen scope: restore `DashboardView.swift` to its pre-`553ea58` form, record the outcome in `08-DECISION-C013.md` and the register, copying the Route D acknowledgement line into the owner decision record.
- Open and not settled: whether the flicker is the same glass-resolution path failing softly on device (CH6), every H1 to H5 prediction (needs the device session to be requested again, plus a Release run for H1 and H4), the empty-data assumption for the flicker, adjacency and ordering (carry to the plan 09-10 owner checklist), the Feedback submission, and the `SheetDismissTabSwitchUITests` sheet-mode test crashing on HEAD (a full UI suite run can fail on it; for the plans after 09-07 to decide).
- Diagnostic worktrees and `diag/` branches remain for plan 09-09 cleanup.

## Self-Check: PASSED

- FOUND: `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C013.md`
- FOUND: `.planning/phases/09-swiftui-design-system-modernization/09-FLASH-DIAGNOSIS.md`
- FOUND: `docs/DEVLOG.md` (entry added in the final docs commit)
- FOUND commits (ancestors of HEAD): `0d8a6f4`, `ec7d74c`, `3d3fa3d`, `915b4a6`
- Measured: 4 commits since `plan_head_before` (`a6a5b30`) at SUMMARY write; `git diff a6a5b30..HEAD -- drinkpulse` is empty (no production source changed); the Task 2 verifiers pass (`Chosen option: revert-container-only`, acknowledgement line present and matching the brief).

---
*Phase: 09-swiftui-design-system-modernization*
*Completed: 2026-11-13*
