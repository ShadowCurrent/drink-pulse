---
phase: 08-ios-27-baseline-api-inventory
plan: "07"
subsystem: developer-documentation
tags: [xcode, ios-27, simulator, documentation, portability]
requires:
  - phase: 08-01
    provides: Immutable iOS 27 baseline evidence
provides:
  - Portable local iOS 27 simulator selection for living build and test instructions
  - Durable links from living instructions to immutable baseline evidence
affects: [PLAT-02, developer-workflow, phase-08-verification]
actuals:
  tokens: 1200
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns: [LOCAL_IOS_27_UDID local simulator destination contract]
key-files:
  created: []
  modified: [README.md, CLAUDE.md]
key-decisions:
  - "Keep the evidence-capture simulator identity exclusively in 08-BASELINE.md; living instructions select a local device."
patterns-established:
  - "Build, full-test, scoped-test, and coverage commands consume LOCAL_IOS_27_UDID after local discovery and boot readiness."
requirements-completed: [PLAT-02]
coverage:
  - id: D1
    description: README documents a portable local iOS 27 simulator build and full-test path linked to baseline evidence.
    requirement: PLAT-02
    verification:
      - kind: other
        ref: "Plan 08-07 README Python assertion"
        status: pass
    human_judgment: false
  - id: D2
    description: CLAUDE documents the same portable destination for coverage, build, full-suite, and scoped-test commands.
    requirement: PLAT-02
    verification:
      - kind: other
        ref: "Plan 08-07 CLAUDE Python assertion"
        status: pass
    human_judgment: false
duration: 6 min
completed: 2026-09-17
status: complete
---

# Phase 08 Plan 07: Portable Simulator Documentation Summary

**Portable iOS 27 simulator selection in README and CLAUDE, with immutable Phase 08 evidence retained separately**

## Performance

- **Duration:** 6 min
- **Started:** 2026-09-17T14:23:00Z
- **Completed:** 2026-09-17T14:29:01Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added local iOS 27 simulator discovery, selection, and boot-readiness steps to README before its Debug build and full-test commands.
- Replaced capture-machine destinations in README and CLAUDE with `LOCAL_IOS_27_UDID`.
- Linked both living entry points to `08-BASELINE.md` for immutable capture evidence while keeping its machine-specific UDID out of general guidance.

## Task Commits

1. **Task 1: Make the README build and full-test path portable from local simulator discovery to immutable evidence** — `bca12f1` (docs)
2. **Task 2: Apply the same portable destination contract to CLAUDE coverage and verification commands** — `16ff6e8` (docs)

## Files Created/Modified

- `README.md` — Local simulator selection and portable Debug build/full-test destinations.
- `CLAUDE.md` — Shared local simulator contract for coverage, build, full-suite, and scoped-test commands.

## Decisions Made

- Kept the capture-specific simulator identity as immutable evidence only, not reusable local configuration.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Plan 08-08 remains as the final Phase 08 gap closure, correcting the persistence-topology documentation contradiction.

---
*Phase: 08-ios-27-baseline-api-inventory*
*Completed: 2026-09-17*
