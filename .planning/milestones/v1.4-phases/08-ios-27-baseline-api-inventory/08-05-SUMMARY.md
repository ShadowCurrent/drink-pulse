---
phase: 08-ios-27-baseline-api-inventory
plan: "05"
subsystem: modernization-inventory
tags: [ios-27, swift-6.4, traceability, api-inventory, decision-gate]
requires:
  - phase: 08-02
    provides: active iOS 27 toolchain documentation and audit
  - phase: 08-03
    provides: UI/resource/UI-test inventory
  - phase: 08-04
    provides: domain/service/test/tooling inventory
provides:
  - Master reconciliation for all 254 tracked app, test, UI-test, and Xcode paths.
  - Twelve independent, source-backed substantial-candidate briefs with pending-only owner outcomes.
affects: [09-swiftui-design-system-modernization, 10-data-platform-integration-modernization, 11-ios-27-release-verification, 08-06-owner-decision-handoff]
actuals:
  tokens: 13287
  tasks: 2
  commits: 2
plan_head_before: 25b51cd8d1a2628785e47e29c7c77516f00b3290
tech-stack:
  added: []
  patterns: [master source inventory, no-candidate coverage, independent owner-decision gate]
key-files:
  created:
    - .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY.md
    - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-REGISTER.md
    - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C001.md through 08-DECISION-C012.md
  modified:
    - .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md
key-decisions:
  - "Treat the two previously omitted UI-test seed files as a coverage defect and add a no-candidate record before closing the inventory."
  - "Keep every substantial candidate outcome, scope, reason, and downstream authorization pending for Wave 4."
patterns-established:
  - "A substantial candidate has one master ID, one brief, and one pending register row; recommendations never confer scope approval."
requirements-completed: [MOD-01, MOD-05, PLAT-02]
coverage:
  - id: D1
    description: Complete master index reconciles all tracked inventory surfaces, no-candidate rows, baseline diagnostics, Swift 6.4 coverage, and flagged assumptions.
    requirement: MOD-01
    verification:
      - kind: other
        ref: "08-05 tracked-path Python coverage assertion"
        status: pass
    human_judgment: false
  - id: D2
    description: Every substantial modernization candidate has a source-backed brief and a pending-only owner decision row.
    requirement: MOD-05
    verification:
      - kind: other
        ref: "08-05 decision-brief Python completeness assertion"
        status: pass
    human_judgment: true
    rationale: Owner outcomes, scope, and reason must be supplied at the Wave 4 checkpoint.
duration: 8min
completed: 2026-09-16
status: complete
---

# Phase 08 Plan 05: Inventory Reconciliation and Decision Briefs Summary

**A complete iOS 27 source inventory now crosswalks all tracked surfaces and baseline evidence, while twelve behavior/data/lifecycle-sensitive candidates await independent owner outcomes.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-09-16T18:15:32Z
- **Completed:** 2026-09-16T18:23:24Z
- **Tasks:** 2/2
- **Files modified:** 15

## Accomplishments

- Reconciled 254 tracked production, unit-test, UI-test, and Xcode-project paths against detailed inventories; fixed the missing UI-test seed coverage and preserved 30 explicit no-candidate records.
- Added one master candidate ID per detailed row, disposition/destination counts, a diagnostic/test-result crosswalk, Swift 6.4 coverage, nine assumption dispositions, and the stale API-intel boundary.
- Prepared twelve standalone decision briefs and a pending-only register without pre-authorizing Phase 09 or Phase 10 scope.

## Verification

- The tracked-file coverage assertion passed: all 254 paths appear in a detailed inventory and the master includes all required disposition/baseline/Swift coverage terms.
- The decision-brief assertion passed: every C001–C012 file includes all required decision content and the register has pending-only empty scope/reason cells.
- `git diff --check` passed.

## Task Commits

1. **Task 1: Reconcile all source files, candidate rows, no-candidate rows and baseline diagnostics into one inventory index** — `8e0590d` (docs)
2. **Task 2: Write one decision brief per substantial candidate and create an owner-outcome register** — `02d8549` (docs)

## Files Created/Modified

- `08-INVENTORY.md` — master coverage, source-ID crosswalk, diagnostic disposition, Swift 6.4 review, and decision-gate rule.
- `08-INVENTORY-UI.md` — records both UI-test seed files in NC-UI-01 and its literal manifest.
- `08-DECISION-REGISTER.md` — twelve independent pending outcome rows for Wave 4.
- `08-DECISION-C001.md` through `08-DECISION-C012.md` — self-contained source-backed tradeoff briefs.

## Decisions Made

- Restored file-level traceability for `UITestSeed.swift` and `UITestSeed+Fixtures.swift`; their launch-only in-memory fixture behavior has no evidence-backed modernization candidate.
- Applied the substantial threshold to navigation, accessibility, persisted-data, lifecycle, and system-integration candidates, leaving all owner choices pending.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Documentation traceability] Added omitted UI-test seed files to the detailed inventory.**

- **Found during:** Task 1
- **Issue:** The required tracked-path assertion found `UITestSeed.swift` and `UITestSeed+Fixtures.swift` absent from the detailed inventory manifests.
- **Fix:** Reviewed their launch argument, in-memory container, fixture insertion, and actor-isolation patterns; added both to NC-UI-01 and the literal UI manifest.
- **Files modified:** `08-INVENTORY-UI.md`
- **Verification:** The tracked-file coverage assertion passed for all 254 paths.
- **Committed in:** `8e0590d`

**Total deviations:** 1 auto-fixed (1 Rule 1 traceability correction).

## Issues Encountered

The baseline remains non-passing: the Debug, Release, and unfiltered full-test invocations stop at the app-owned `DPArcProgress.swift:33` compiler error, so test counts are unavailable. The master inventory preserves this classification and does not report unavailable tests as passing.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Wave 4 can present twelve complete briefs and collect a separate approve/retain/defer outcome, exact scope, and reason for each. Until then, no substantial replacement is eligible for Phase 09 or Phase 10 planning.

## Self-Check: PASSED

- Found the master inventory, register, all twelve decision briefs, and this summary.
- Found task commits `8e0590d` and `02d8549`; measured plan ledger count is two commits from `25b51cd8d1a2628785e47e29c7c77516f00b3290`.

---
*Phase: 08-ios-27-baseline-api-inventory*
*Completed: 2026-09-16*
