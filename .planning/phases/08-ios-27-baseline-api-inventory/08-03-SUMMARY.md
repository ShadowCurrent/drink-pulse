---
phase: 08-ios-27-baseline-api-inventory
plan: "03"
subsystem: ui
tags: [swiftui, xctest, accessibility, swift-charts, ios-27, inventory]
requires:
  - phase: 08-01
    provides: iOS 27 baseline diagnostics and evidence limits
provides:
  - Source-backed census of every UI production, resource, and UI-test file
  - Modernization/retain dispositions with official-source links and decision flags
  - Preserved History List/ScrollView and context-menu reproduction gates
affects: [phase-09-swiftui-modernization, phase-11-release-verification, phase-08-plan-05]
actuals:
  tokens: 9022
  tasks: 2
  commits: 5
plan_head_before: b3e892ef3236cefc36e18f323b24ccec660711f3
tech-stack:
  added: []
  patterns: [tracked-file inventory manifest, source-and-official-link candidate register, explicit no-candidate rows]
key-files:
  created:
    - .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md
  modified: []
key-decisions:
  - "Retain History List/ScrollView and context-menu workarounds until focused iOS 27 reproduction and applicable official guidance support a change."
  - "Treat the blocked iOS 27 UI suite as unavailable evidence, never as a passing run."
  - "Flag navigation, chart accessibility, motion, glass, and VoiceOver-test changes for D-09 decision briefs."
patterns-established:
  - "Inventory entries use exact repository-relative source locations, Apple links, disposition, risk, destination, and substantial-brief status."
requirements-completed: [MOD-01, MOD-05]
coverage:
  - id: D1
    description: Complete source-backed census of the assigned UI production, resource, and UI-test surface.
    requirement: MOD-01
    verification:
      - kind: other
        ref: "python3 exact-manifest census verification"
        status: pass
    human_judgment: false
  - id: D2
    description: Behavior-sensitive UI candidates and History workaround evidence are classified for a separate decision before downstream execution.
    requirement: MOD-05
    verification:
      - kind: other
        ref: "08-03-PLAN.md automated inventory verification"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-09-16
status: complete
---

# Phase 08 Plan 03: UI Inventory Summary

**Complete iOS 27 UI inventory covering 90 production Swift files, 39 UI-test Swift files, 16 resources, and ten source-backed modernization or retain records.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-16T18:08:56Z
- **Completed:** 2026-09-16T18:12:45Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Recorded every assigned source and resource file in an exact tracked-path manifest, with an explicit no-candidate row for every production, resource, and UI-test area.
- Classified compiler-diagnostic leads, Observation, list identity, Charts/Audio Graph, motion, Liquid Glass, and an Xcode 27 VoiceOver-test capability with Apple sources, availability wording, priority, risk, and downstream destination.
- Preserved the History List/ScrollView and context-menu workarounds as retain candidates; their focused iOS 27 reproduction gates remain explicit and no unavailable test is reported as green.

## Task Commits

1. **Task 1: Inventory app entry, every SwiftUI feature, design system, diagnostics and UI resources** — `3a23c82` (docs)
2. **Task 2: Inventory every UI test and preserve evidence for platform workaround decisions** — `ace0547` (docs)
3. **Traceability corrections for Tasks 1–2** — `62f86c6`, `5f74cea` (fix)

## Files Created/Modified

- `.planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md` — complete source and UI-test inventory with official links, dispositions, no-candidate rows, and reproduction evidence.

## Decisions Made

- Retain the documented History List/ScrollView and context-menu solutions until targeted iOS 27 evidence demonstrates that a specific replacement preserves their behavior.
- Leave test-result status unavailable because app compilation prevented the full suite from starting; Phase 09 repairs the compiler error before Phase 11 runs focused evidence.
- Mark possible navigation, accessibility, motion, glass, and VoiceOver-test changes substantial so Plan 08-05/08-06 can apply D-09 through D-11.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Documentation traceability] Normalized candidate source paths**
- **Found during:** final verification after Task 2
- **Issue:** several candidate entries used folder-relative shorthand, so their file-and-line locations were not directly repository-resolvable.
- **Fix:** converted them to repository-relative paths.
- **Files modified:** `08-INVENTORY-UI.md`
- **Verification:** candidate-location sampling and `git diff --check`.
- **Committed in:** `62f86c6`

**2. [Rule 1 - Documentation completeness] Expanded the grouped census to an exact manifest**
- **Found during:** final coverage verification after Task 2
- **Issue:** grouped table entries could not mechanically prove every reviewed file, and a tracked asset metadata file was omitted from the explicit resource list.
- **Fix:** added a complete repository-relative manifest for all assigned production, resource, and UI-test paths.
- **Files modified:** `08-INVENTORY-UI.md`
- **Verification:** exact-manifest check passed for 90 production Swift files, 39 UI-test Swift files, and 16 resource files.
- **Committed in:** `5f74cea`

**Total deviations:** 2 auto-fixed (2 Rule 1 documentation-traceability corrections).

## Issues Encountered

- The Phase 08 iOS 27 baseline has an app-owned DPArcProgress compiler error, so the full suite and any focused UI test could not start. The inventory truthfully records counts as unavailable and routes the repair to Phase 09.
- The measured plan commit count is five because another shared-branch commit occurred after the plan ledger was captured; the four commits listed above are the artifacts owned by this plan.

## Known Stubs

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan 08-05 can reconcile this UI inventory with the domain/service inventory and prepare the required D-09 decision briefs.
- Phase 09 must resolve UI-C-02 before focused History interaction evidence or the full iOS 27 UI suite can be captured.

## Self-Check: PASSED

- `08-INVENTORY-UI.md` exists.
- Task commits `3a23c82`, `ace0547`, `62f86c6`, and `5f74cea` exist.

---
*Phase: 08-ios-27-baseline-api-inventory*
*Completed: 2026-09-16*

