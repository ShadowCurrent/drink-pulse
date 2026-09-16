---
phase: 08-ios-27-baseline-api-inventory
plan: "04"
subsystem: inventory
tags: [swift-6.4, swiftdata, healthkit, usernotifications, xcode, testing]
requires:
  - phase: 08-01
    provides: iOS 27 baseline evidence and classified compiler diagnostics
provides:
  - Exhaustive non-UI domain, service, test, and tooling inventory with literal tracked-path coverage
  - Source-backed retain and substantial-candidate dispositions for data and system-integration boundaries
affects: [09-swiftui-design-system-modernization, 10-data-platform-integration-modernization, 11-ios-27-release-verification]
tech-stack:
  added: []
  patterns: [dated API inventory, explicit no-candidate rows, substantial-change owner-brief gate]
key-files:
  created:
    - .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-DATA.md
  modified: []
key-decisions:
  - "Retain frozen schema, export, calculation, HealthKit, and notification behavior absent a source-backed iOS 27 benefit."
  - "Treat concurrency or system-integration rewrites as substantial until interrupted/parallel-operation proof and an owner brief exist."
requirements-completed: [MOD-01, MOD-05]
actuals:
  tokens: 7786
  tasks: 2
  commits: 6
plan_head_before: 40d16beea4ede1f0e22a5e31033a521cfda2fb6c
coverage:
  - id: D1
    description: Exhaustive source-backed inventory of assigned non-UI code, tests, and tooling
    requirement: MOD-01
    verification:
      - kind: other
        ref: python tracked-path coverage assertion (108 paths)
        status: pass
    human_judgment: false
  - id: D2
    description: Substantial migration, concurrency, HealthKit, and notification risks are separated for owner review
    requirement: MOD-05
    verification:
      - kind: other
        ref: 08-INVENTORY-DATA.md S-01 through S-03
        status: pass
    human_judgment: true
    rationale: Owner review is required before a substantial system-integration or lifecycle rewrite is planned.
duration: 3min
completed: 2026-09-16
status: complete
---

# Phase 08 Plan 04: Data and Platform-Service Inventory Summary

**A dated, source-backed iOS 27 inventory covers all 108 assigned domain, service, non-UI test, and Xcode-tooling paths while preserving frozen data and system-integration contracts.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-09-16T20:08:06+02:00
- **Completed:** 2026-09-16T20:10:47+02:00
- **Tasks:** 2/2
- **Files modified:** 1 inventory artifact

## Accomplishments

- Recorded all assigned domain, data-transfer, persistence, schema, service, test, performance, and tracked Xcode-tooling paths, with explicit no-candidate rows for every area.
- Linked each distinct data/concurrency/service disposition to current official Apple or Swift guidance and its exact source locations.
- Protected shipped schemas, UUID/LWW identity, backup format, calculations, notification routing, HealthKit permissions, and device-local sample identity from speculative modernization.

## Task Commits

1. **Task 1: Inventory domain, data transfer, persistence and corresponding unit tests** — `8e4d60b` (`docs`)
2. **Task 2: Inventory services, remaining unit/performance tests, concurrency and Xcode tooling** — `5b08961` (`docs`)

## Files Created/Modified

- `.planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-DATA.md` — Complete non-UI source coverage, official-source dispositions, no-candidate rows, and substantial-risk flags.

## Decisions Made

- Retain all frozen SwiftData snapshots and export/calculation contracts; a target raise alone does not justify a schema, stored-property, format, or formula change.
- Retain the notification and HealthKit unchecked-Sendable boundaries pending a reproducible data-race/lifecycle problem and a Phase 10 owner brief.
- Retain Swift Testing/XCTest mix and synchronous cleanup because Swift 6.4's async cleanup/interoperability features do not solve a demonstrated problem at these call sites.

## Deviations from Plan

None - plan deliverables were produced exactly as specified.

## Issues Encountered

The shared-main execution branch received four committed 08-02/08-03 task commits after this plan's required ledger base was captured. Per the required measured-ledger contract, `actuals.commits: 6` is the exact `40d16be..HEAD` count at summary creation; only `8e4d60b` and `5b08961` belong to Plan 08-04. This note prevents the concurrent commits from being misattributed as task work.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 10 has a complete data/platform map and must preserve the listed migration, identity, HealthKit, and notification invariants.
- S-01 through S-03 require an owner brief before any notification or HealthKit concurrency/lifecycle rewrite. The unresolved interrupted/parallel-operation guarantee remains a retain decision, not an external block.
- The existing iOS 27 compiler diagnostic remains classified in `08-BASELINE.md` and is assigned to Phase 09; no Phase 08 source edit was made.

## Self-Check: PASSED

- `08-INVENTORY-DATA.md` exists and covers all 108 assigned tracked source/tooling paths.
- Task commits `8e4d60b` and `5b08961` exist.
- Automated Task 1/Task 2 inventory assertions and the plan-level coverage/source-link assertion passed; no production, schema, service, test, or Xcode-tooling file changed.

---
*Phase: 08-ios-27-baseline-api-inventory*
*Completed: 2026-09-16*
