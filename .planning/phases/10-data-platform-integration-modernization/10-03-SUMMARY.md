---
phase: 10-data-platform-integration-modernization
plan: "03"
subsystem: testing
tags: [swift-testing, swiftdata, backup-export, fixtures, privacy]

requires:
  - phase: 08-ios-27-baseline-api-inventory
    provides: C009 backup compatibility requirement and the D-07 to D-09 fixture decisions
provides:
  - BackupFixtureLoader that reads fixture JSON from the test bundle
  - Synthetic probe-export-v2.json proving bundling and the importer path
  - Owner-approved, placeholder-only sanitized-export-v2.json (real shape, 14 events, no templates, profile)
  - SanitizedBackupFixtureTests including a permanent placeholder lint mirroring the scrub guide
  - 10-FIXTURE-SCRUB.md owner guide with Allowed values, scrub script and review checklist
affects: [10-12 device import round trip, any plan touching DataTransfer]

plan_head_before: 4fc01253466793723cb617539e8503c1c03abc4d
plan_head_after: 642c868e413df2b82b4bb089e15ef65506d4e3ee

actuals:
  tokens: 8500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Fixture JSON in the synchronized test folder is copied to the test bundle root; loader tries Fixtures subdirectory then root"
    - "Raw-JSON placeholder lint (JSONSerialization) whose failure messages name only rule and position, never values"

key-files:
  created:
    - drinkpulseTests/Domain/DataTransfer/BackupFixtureLoader.swift
    - drinkpulseTests/Domain/DataTransfer/SanitizedBackupFixtureTests.swift
    - drinkpulseTests/Domain/DataTransfer/Fixtures/probe-export-v2.json
    - drinkpulseTests/Domain/DataTransfer/Fixtures/sanitized-export-v2.json
    - .planning/phases/10-data-platform-integration-modernization/10-FIXTURE-SCRUB.md
  modified: []

key-decisions:
  - "Bundling probe passed: JSON files in the file-system-synchronized test folder land at the test bundle root, so no BackupFixtureLiterals.swift fallback was created"
  - "Lint stays in the suite and is never weakened; a failure means re-scrub"

requirements-completed: [DATA-01]

coverage:
  - id: D1
    description: "Synthetic export loads from the test bundle, imports without failures, re-imports as a no-op and exports without healthKitUUID"
    requirement: "DATA-01"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Domain/DataTransfer/SanitizedBackupFixtureTests.swift#probe_importsWithoutFailures_andReimportIsNoOp"
        status: pass
    human_judgment: false
  - id: D2
    description: "Owner-scrubbed real-shape export decodes at v2, imports with zero failures, re-imports as a no-op and exports without healthKitUUID"
    requirement: "DATA-01"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Domain/DataTransfer/SanitizedBackupFixtureTests.swift#sanitized_decodesAtVersion2_andImportsWithoutFailures"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Domain/DataTransfer/SanitizedBackupFixtureTests.swift#sanitized_reimportIsNoOp"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Domain/DataTransfer/SanitizedBackupFixtureTests.swift#sanitized_exportHasNoHealthKitUUID_andOnlyAllowedKeys"
        status: pass
    human_judgment: false
  - id: D3
    description: "Placeholder lint enforces every Allowed values item against the committed fixture and rejects a leaked synthetic sample"
    requirement: "DATA-01"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Domain/DataTransfer/SanitizedBackupFixtureTests.swift#sanitized_lint_containsOnlyAllowedPlaceholderValues"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Domain/DataTransfer/SanitizedBackupFixtureTests.swift#lint_rejectsPersonalValues"
        status: pass
    human_judgment: false
  - id: D4
    description: "The fixture contains no personal data: the owner scrubbed it with the guide script outside the repo and reviewed it by eye before commit"
    requirement: "DATA-01"
    verification: []
    human_judgment: true
    rationale: "Absence of personal values rests on the owner's review (D-07); the lint only checks the rules it encodes"

duration: 95min
completed: 2026-11-09
status: complete
---

# Phase 10 Plan 03: Sanitized Backup Fixture Summary

**Real-shape backup export, scrubbed by the owner outside the repo, committed as a placeholder-only fixture with a permanent raw-JSON lint; decode, import, no-op re-import and no-healthKitUUID proven on iOS 27 with the export format and importer untouched.**

## Performance

- **Duration:** about 95 min wall clock, including an interruption (rate limit, then a Mac reboot) and the owner checkpoint
- **Tasks:** 3 of 3 (Task 2 was the owner checkpoint)
- **Files created:** 5

## Accomplishments

- Tracer: synthetic probe fixture, loader and importer path proven end to end first (3 `probe_` tests).
- Owner scrub guide with the authoritative Allowed values section, a Python 3 scrub script that aborts on unknown keys, and a review checklist. The script was smoke-tested on a synthetic input kept outside the repo.
- Sanitized fixture committed after the owner's approval, with decode/import, re-import no-op, no-healthKitUUID plus allowed-key-set, and the placeholder lint (plus a negative test proving the lint catches leaked values).
- Existing DataTransfer suites pass unchanged (D-09): `git diff fbd37fa -- drinkpulse/Domain/DataTransfer` is empty.

## Owner checkpoint (Task 2, D-07)

- Resume signal received: the owner replied `approved` in the main session on 2026-11-09, relayed to this agent by the coordinator. The owner reviewed `scrubbed.json` first.
- Provenance: the owner placed the raw export in the fixture folder under the gitignored name `drinkpulse-backup-2026-11-09.json` (never staged). At the owner's direction the orchestrator moved it to `~/Documents/dp-scrub/original.json`, outside the repo, extracted `scrub.py` verbatim from the guide, and ran it with both paths outside the repo (`wrote 14 events, 0 templates`). The owner reviewed the output, then the orchestrator copied it to `drinkpulseTests/Domain/DataTransfer/Fixtures/sanitized-export-v2.json`. No raw export remains in the repo. This agent never read the raw export and never printed fixture values.

## Bundling probe result (Pitfall 2)

The fixture JSON in the synchronized test folder is copied to the root of `drinkpulseTests.xctest` (build log: `CpResource ... drinkpulseTests.xctest/probe-export-v2.json`). `BackupFixtureLoader` finds it through its root fallback. The literal-string fallback was not needed.

## TDD / commits

- RED `c2f2afe` `test(10-03)`: 3 `probe_` tests failed with `Fixture resource 'probe-export-v2.json' not found in the test bundle`. The target tests executed and failed on the planned condition (fixture absent). Semantic assessment: valid RED. Evidence kept in `build/p10-03-red.log` (not committed); the `gsd_run check tdd-red-evidence` classifier was not run because this plan is `type: execute`, not `type: tdd`.
- GREEN `3882cc3` `feat(10-03)`: probe fixture, scrub guide, container lifetime fix. 3 tests in 1 suite passed.
- Task 3 `642c868` `test(10-03)`: sanitized fixture and 5 tests. 53 tests in 7 suites passed (SanitizedBackupFixtureTests, DataBackupExportTests, DataImporterRoundTripTests, DataImporterUpsertTests, DataImporterEdgeCaseTests, ComprehensiveRoundTripTests, DrinkControlImporterTests).

## Deviations from Plan

**1. [Rule 1 - Bug] Test container deallocated mid-test**
- **Found during:** Task 1 GREEN run
- **Issue:** `try makeContainer().mainContext` let the `ModelContainer` deallocate while the context was in use, trapping (EXC_BREAKPOINT) inside `DataImporter.importData`.
- **Fix:** hold the container in a local, as the existing importer tests do. Test-only change, no production code touched.
- **Commit:** 3882cc3

**2. [Rule 3 - Blocking] Simulator assignment and invocation form**
- The orchestrator assigned simulator `03EFCD44-67A6-4AA6-9A7B-92411F25D3CE`, so no dedicated clone was created and `LOCAL_IOS_27_UDID_P10_03` was not exported; the UDID was passed literally because the sandbox rejects runtime-computed values in `xcodebuild` calls. The scoped `-only-testing` flags are the plan's own verify flags. The `| tee ... | tail` and `grep` pipeline was split into redirect-to-log plus separate greps, with the same "Test run with N tests ... passed" evidence.
- **Apple tooling route:** CLI fallback (`xcodebuild`, `simctl`) for every step; Xcode MCP was not used. Reason: build logs and the xcresult-adjacent log were needed as files, and the MCP acts on the main workspace rather than this worktree.

**3. [Plan note] Task 3 extra test**
- Added `lint_rejectsPersonalValues` (synthetic leaked sample) so the lint is proven to fail on violations. Not in the plan's four behaviors; kept the suite at 268 lines.

**4. [Convention] Commit attribution omitted**
- AGENTS.md forbids AI attribution in commit messages; the commits carry none.

**Total deviations:** 1 auto-fixed bug, 1 blocking-environment adaptation, 2 notes. **Impact:** none on scope or correctness.

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None. No new network, auth, file-access or schema surface; the loader reads only the test bundle.

## Verification results

- Scoped run: 53 tests in 7 suites passed on iPhone 18 Pro Max, iOS 27.2; no compiler warnings from the new files.
- `git add --dry-run` lists both fixtures; `git check-ignore` exits 1 for the probe fixture; no tracked or untracked file matches `drinkpulse-backup-*` or `drinkcontrol*`.
- Fixture structural check: version 2, 14 events (limit 14), no templates key content, profile present, no `healthKitUUID`.
- Mirror check: all four lint constants appear in both the guide and the test, and the test refers to timestamp, creationDate, modifiedDate, biologicalSex, currency, uuid, male and USD.
- File size: `SanitizedBackupFixtureTests.swift` 268 lines, `BackupFixtureLoader.swift` 27 lines (limit 300).
- Not run: full test suite and coverage report (scoped run only, as directed by the coordinator under high machine load; the change adds test files and fixtures only).
- Living docs audit: no living document contradicted; this plan changes no production behavior.
- The device import round trip belongs to plan 10-12.

## Next

Ready for the remaining wave plans; orchestrator owns STATE.md and ROADMAP.md.

## Self-Check: PASSED

- FOUND: BackupFixtureLoader.swift, SanitizedBackupFixtureTests.swift, probe-export-v2.json, sanitized-export-v2.json, 10-FIXTURE-SCRUB.md
- FOUND commits: c2f2afe, 3882cc3, 642c868
