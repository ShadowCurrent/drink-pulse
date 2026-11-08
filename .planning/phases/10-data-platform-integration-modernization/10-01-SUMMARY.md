---
phase: 10-data-platform-integration-modernization
plan: "01"
subsystem: persistence
tags: [swiftdata, migration, versioned-schema, store-bootstrap, swift-testing]

requires:
  - phase: 08-ios-27-baseline-api-inventory
    provides: C008 migration-chain concern and the fbd37fa baseline commit
provides:
  - StoreBootstrap.makeContainerReportingRecovery seam returning (container, didRecover)
  - Every-field V1, V2, V3 to V4 migration proofs under the shipped MigrationPlan on iOS 27
  - Launch dedup sweep proof over migrated legacy stores
  - Corrupted-store control proving didRecover can report true
affects: [10-12 device sign-off (R-01 acknowledgement), future SchemaV5 work]

actuals:
  tokens: 10122
  tasks: 3
  commits: 4
plan_head_before: 4fc01253466793723cb617539e8503c1c03abc4d
plan_head_after: 87989dcfd4066964c23bd3ee4c14dd30f9d79718

tech-stack:
  added: []
  patterns:
    - "Recovery-reporting seam: tests open legacy stores through makeContainerReportingRecovery and assert !didRecover first"
    - "Plain-value StoreSnapshot (every stored property, uuids and clocks) for before/after and reopen comparisons"

key-files:
  created:
    - drinkpulseTests/Domain/Persistence/MigrationFixtures.swift
    - drinkpulseTests/Domain/Persistence/MigrationFixtureValues.swift
    - drinkpulseTests/Domain/Persistence/MigrationFixtures+LegacyV2V3.swift
    - drinkpulseTests/Domain/Persistence/MigrationChainV1Tests.swift
    - drinkpulseTests/Domain/Persistence/MigrationChainV2V3Tests.swift
    - drinkpulseTests/Domain/Persistence/MigrationSweepTests.swift
  modified:
    - drinkpulse/Domain/Persistence/StoreBootstrap.swift

key-decisions:
  - "makeContainer delegates to the reporting variant, so production and test paths share one open/recover body"
  - "No migration defect found; Schemas, MigrationPlan and RecordDeduplicator are byte-identical to fbd37fa (D-06)"

requirements-completed: [DATA-01]

coverage:
  - id: D1
    description: "StoreBootstrap exposes makeContainerReportingRecovery; makeContainer behavior unchanged"
    requirement: DATA-01
    verification:
      - kind: unit
        ref: "drinkpulseTests/Domain/Persistence/MigrationChainV1Tests.swift; StoreBootstrapTests (all pass)"
        status: pass
    human_judgment: false
  - id: D2
    description: "V1 store opens in one pass as live V4 with every stored property accounted for, no recovery, second open idempotent"
    requirement: DATA-01
    verification:
      - kind: unit
        ref: "drinkpulseTests/Domain/Persistence/MigrationChainV1Tests.swift"
        status: pass
    human_judgment: false
  - id: D3
    description: "V2 and V3 stores migrate to V4 with uuid and modifiedDate exact, creationDate derived only for V2, healthKitUUID nil, no recovery"
    requirement: DATA-01
    verification:
      - kind: unit
        ref: "drinkpulseTests/Domain/Persistence/MigrationChainV2V3Tests.swift"
        status: pass
    human_judgment: false
  - id: D4
    description: "Launch dedup sweep merges and drops no record in migrated legacy stores, including three identical-field V1 events; sweep is idempotent"
    requirement: DATA-01
    verification:
      - kind: unit
        ref: "drinkpulseTests/Domain/Persistence/MigrationSweepTests.swift"
        status: pass
    human_judgment: false
  - id: D5
    description: "Interrupted-migration edge: a store left unreadable is moved aside non-destructively and replaced by a usable fresh store (seam-level evidence for R-01)"
    requirement: DATA-01
    verification:
      - kind: unit
        ref: "drinkpulseTests/Domain/Persistence/MigrationChainV2V3Tests.swift#corruptedStore_reportsRecoveryAndOpensFresh"
        status: pass
    human_judgment: true
    rationale: "No automated test kills the process mid-migration; the residual risk R-01 needs the owner acknowledgement in the plan 10-12 Sign-off."

duration: 75min
completed: 2026-11-08
status: complete
---

# Phase 10 Plan 01: Legacy Store Migration Proof Summary

**V1, V2 and V3 SwiftData stores seeded from the frozen snapshots all reach the live V4 model under the shipped MigrationPlan on iOS 27 with every stored property asserted, through a new `makeContainerReportingRecovery` seam that proves no silent move-aside happened.**

## Performance

- **Duration:** ~75 min (dominated by xcodebuild cold builds)
- **Tasks:** 3 of 3
- **Files:** 1 production file modified, 6 test files created
- **Final run:** 34 tests in 7 suites passed (MigrationChainV1Tests, MigrationChainV2V3Tests, MigrationSweepTests, MigrationTests, StoreBootstrapTests, RecordDeduplicatorTests, UserProfileStoreTests)

## Accomplishments

- `StoreBootstrap.makeContainerReportingRecovery(schema:configuration:)` returns `(container, didRecover)`. `makeContainer` keeps its signature and `@MainActor` and returns the reporting variant's container. Open, catch, `recoverStore`, reopen body and both log lines are unchanged.
- V1 (4 tests): every event, template and profile field exact; consumptionDate equals the seed timestamp, creationDate and modifiedDate equal consumptionDate within 1s; uuids non-nil and pairwise distinct; template link only on the linked event; template and profile modifiedDate fall in the test's own time window; second open reports `didRecover == false` and an identical full snapshot.
- V2 and V3 (3 tests): uuid and modifiedDate preserved exactly; creationDate equals consumptionDate for V2 and the seeded value (3600 s earlier) for V3; healthKitUUID nil; profile id "singleton".
- Corrupted-store control `corruptedStore_reportsRecoveryAndOpensFresh`: first 100 bytes of a seeded V3 store overwritten, seam returns `didRecover == true`, live path holds a store that fetches 0 events and saves and fetches 1 inserted event. This makes every `!didRecover` assertion non-vacuous. The log shows `NSSQLiteErrorDomain : 26` (not a database), so the header-corruption trigger worked and the permission fallback was not needed.
- Sweep (5 tests): `RecordDeduplicator.sweep` over migrated V1, V2, V3 stores and a V1 seed with three identical-field events changes no count, uuid set or stored value; second sweep is a no-op; one profile remains.

## Task Commits

1. Task 1 RED: `7c30768` test(10-01) failing V1 proof (compile error: no member `makeContainerReportingRecovery`)
2. Task 1 GREEN: `6232e3d` feat(10-01) recovery-reporting seam (tracer verified end-to-end, expanding)
3. Task 2: `3e14078` test(10-01) V2/V3 proofs and corrupted-store control
4. Task 3: `87989dc` test(10-01) dedup sweep over migrated legacy stores

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixtures split into three files for the 300-line ceiling**
- **Found during:** Task 1 and 2
- **Issue:** Seeds, plain-value mirrors and V2/V3 seeds together would approach 300 lines in one file (AGENTS.md hard ceiling; the plan allows a second fixtures file).
- **Fix:** `MigrationFixtures.swift` (helpers, V1 seeds, 130 lines), `MigrationFixtureValues.swift` (value types and StoreSnapshot, 194 lines), `MigrationFixtures+LegacyV2V3.swift` (V2/V3 seeds and expectations, 202 lines). Type name `MigrationFixtures` and all planned function names are unchanged.

**2. [Rule 1 - Judgment] V1 profile `alcoholUnit` seeded as `.grams` instead of `.standardDrinks`**
- **Issue:** The behavior list requires every profile field non-default, but `.standardDrinks` is the default, so a migration that reset the field would go undetected. The action text lists `.standardDrinks`.
- **Fix:** Seeded `.grams` (non-default). The plan's stronger requirement (non-default) wins; the weaker value is not asserted anywhere.

**3. Commit attribution**
- The execution wrapper asks for Co-Authored-By and Claude-Session trailers. AGENTS.md says never include AI attribution in commit messages and takes precedence, so none were added.

**Total deviations:** 3 (1 blocking-structure, 1 test-strength, 1 instruction-precedence). **Impact:** none on scope or behavior.

## Tooling Route and Sources (AGENTS.md Apple policy)

- **Xcode MCP:** not exposed to this worktree executor, so every build and test ran by the CLI fallback: `xcodebuild test ... -derivedDataPath build/p10-01 -only-testing:...` on the assigned simulator `02193FDE-1810-4E16-8E72-73371BBC7F1E` (iPhone 17, iOS 27.2; used instead of cloning a plan-specific simulator per the orchestrator's parallel-wave assignment, shut down afterwards). Logs: `build/p10-01-t1-red.log`, `-t1.log`, `-t2.log`, `-t3.log`, `-final.log` (gitignored).
- **Apple documentation:** Xcode MCP `DocumentationSearch` was unavailable, so no documentation lookup ran in this session. No new Apple API was introduced: `Schema(versionedSchema:)`, `ModelContainer(for:migrationPlan:configurations:)`, `FileHandle` and `FetchDescriptor` were already used by the existing MigrationTests and StoreBootstrap code. Behavior was verified by the test runs, not inferred. The plan's ADR reads (0009, 0010) were covered through the plan's own Migration Determinism summary.

## Named Test Gap (R-01)

No automated test terminates the process in the middle of a real SwiftData migration; migrations finish in milliseconds and a kill cannot be reproduced on demand. The corrupted-store test simulates the resulting unreadable store, not the interruption itself. Preservation of moved-aside files is pinned by the existing `recoverStore_movesFilesNotDeletes`, `recoverStore_filesArePresentInRecoveredFolder` and `makeContainer_unreadableStore_recoversAndReturnsFreshContainer`, which passed in the same run. The residual risk is carried to the owner acknowledgement in the plan 10-12 Sign-off.

## Verification Results

- All new suites plus MigrationTests, StoreBootstrapTests, RecordDeduplicatorTests, UserProfileStoreTests: 34 tests, 7 suites, passed; no failures.
- Zero compiler warnings reported for the changed files in any run log.
- `git diff --quiet fbd37fa -- drinkpulse/Domain/Persistence/Schemas drinkpulse/Domain/Persistence/MigrationPlan.swift drinkpulse/Domain/Persistence/RecordDeduplicator.swift` exits 0 (D-06 untouched).
- No test or fixture file mentions `RecoveredStores`; largest new file is 202 lines, StoreBootstrap.swift is 103 lines.
- Scoped runs only, per AGENTS.md; changed production code is a behavior-preserving refactor of one function, so no full-suite escalation criteria apply.

## Known Stubs

None.

## Threat Flags

None. T-10-01 (recovery masking a failed migration) mitigated by the seam; T-10-02 (shipped schemas) mitigated by the baseline diff guard; T-10-03 (disclosure) mitigated by synthetic values, no logging and unique temp URLs removed in `defer`.

## Living Docs Note

No living document contradicts this change (no architecture, domain or public behavior change). STATE.md, ROADMAP.md, DEVLOG and context files were intentionally not touched: the orchestrator owns shared artifacts after the wave.

## Self-Check: PASSED

All six created test files and the modified StoreBootstrap.swift exist on disk; commits 7c30768, 6232e3d, 3e14078, 87989dc are ancestors of HEAD.
