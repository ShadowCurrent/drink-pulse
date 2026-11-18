---
phase: 11-ios-27-release-verification
plan: 05
subsystem: testing
tags: [ver-01, full-suite, coverage, xcodebuild, failure-mapping]
status: complete

requires:
  - phase: 11-ios-27-release-verification
    provides: plan 11-02 debt ledger rows DL-T01 to DL-T07, plan 11-04 scoped runs and limitations
provides:
  - "11-EVIDENCE.md Full suite (VER-01): one complete CLI full run with coverage, exit 0, 834 tests"
  - "11-EVIDENCE.md Failure mapping read from the result bundle: 0 failed, D1 harness tests Skipped"
  - "11-EVIDENCE.md Coverage: overall 94.65 percent, Services 97.15 percent, Domain gap listed not closed"
  - "Extended file size and source guards; ledger observation DL-O02"
affects: [11-08, 11-09, 11-10]

actuals:
  tokens: 9000
  tasks: 3
  commits: 3
plan_head_before: 6c437bc
plan_head_after: 8c5d2bf

key-files:
  created: []
  modified:
    - .planning/phases/11-ios-27-release-verification/11-EVIDENCE.md
    - .planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md

key-decisions:
  - "The four known-list tests all passed in the full run; they stay on the ledger and in their todos (an observation, DL-O02, not a closure)"
  - "The 16 AccessibilityAuditUITests skips are recorded as expected skipped-by-gate (D11-22), not as exceptions"

requirements-completed: []  # VER-01 evidence recorded; the orchestrator and plan 11-08 own the requirement status

duration: about 40 minutes (the full run took 1905 s)
completed: 2026-11-15
---

# Phase 11 Plan 05: Full suite with coverage Summary

One detached `xcodebuild test` run with `-enableCodeCoverage YES` on the iPhone 18 Pro, iOS 27.2 (build 24B8117) finished with exit 0: 834 tests, 816 passed, 0 failed, 18 skipped by gate; overall coverage 94.65 percent, Services 97.15 percent, Domain still below its 100 percent target.

## Results

| Item | Result |
|------|--------|
| Exit status | 0 (`** TEST SUCCEEDED **`) |
| Totals (xcresulttool summary) | total 834, passed 816, failed 0, skipped 18, expected failures 0 |
| Unit result | `Test run with 714 tests in 62 suites passed after 3.688 seconds` plus XCTest `Executed 7 tests, with 0 failures` (721 in the bundle) |
| UI result | `Executed 113 tests, with 18 tests skipped and 0 failures (0 unexpected) in 1855.692 seconds` |
| Skipped (18) | 2 D1 harness tests (`DP_RUN_FLASH_HARNESS` gate) + 16 `AccessibilityAuditUITests` methods (`DP_RUN_A11Y_AUDIT` gate, D11-22); none of the gate variables was set |
| Overall coverage | 94.65 percent (10554/11151), target at least 90: met |
| Services aggregate (adapters excluded) | 97.15 percent (443/456), target at least 85: met; adapters listed apart: `HealthKitAdapter.swift` 20.41, `NotificationScheduling.swift` 0.00 |
| Domain aggregate (non-Persistence) | 90.06 percent (743/825), target 100: not met; 8 of 23 files below 100 percent, listed in the evidence; tracked in WINDOWS rows 1 and 7 (DL-W01, DL-W07), listed, not closed |
| `StoreBootstrap.swift` | 93.02 percent (120/129); historical Phase 10 (2026-11-09) value 96.1 |
| View-model aggregate | 98.11 percent (676/689), target at least 90: met |
| Guards | no Swift file over 300 lines; audit class file 180 lines; shipped-schema guard exit 0; source guard shows only `drinkpulse/Info.plist` (D11-21) changed |

## Failure mapping

- Failed in the bundle: none, so nothing to map, no isolated re-run, no blocker, no newly observed flake, no todo.
- Both D1 harness tests (DL-T05, DL-T06) were Skipped: this closes the open item from plan 09-10 and DL-D08.
- Known-list tests that passed unexpectedly: all four (DL-T01 hero height, DL-T02 and DL-T03 History edit tests, DL-T04 Export dismiss), plus the watched DL-T07. The History edit tests had failed in scoped row G3 (plan 11-04) with the same code; the full-run pass is recorded as an observation only (DL-O02). The cause is not established, the data-integrity risk (L-02) stays undetermined, and every row, todo and open-questions entry stays open and untouched.

Comparison with Phase 10, historical (2026-11-09): 678 unit tests in 59 suites, 93 UI tests in 1714 seconds, 94.61 percent coverage.

## Task commits

1. **Task 1: full run and Full suite section** - `bba33ff` (docs)
2. **Task 2: failure mapping, D1 skipped, ledger DL-O02** - `59ffc45` (docs)
3. **Task 3: coverage section and extended guards** - `8c5d2bf` (docs)

Out-of-git artifacts in the stamp directory: `full.log`, `full.exit`, `coverage.json`, `coverage.txt`, `run-full.sh`; result bundle `build/p11-full.xcresult` and derived data `build/p11-full` (gitignored). Digests of `full.log`, `coverage.json` and `coverage.txt` are in the evidence.

## Deviations from Plan

**1. [Plan assumption stale] Source guard cannot exit 0**
- `git diff --quiet 2aa9156 -- drinkpulse drinkpulse.xcodeproj` exits 1 because of the owner-approved D11-21 change to `drinkpulse/Info.plist` (plan 11-11). Instead I proved that `drinkpulse/Info.plist` is the only changed file (`--name-only`, `--numstat` 1 added, 0 removed) and recorded it in the guards table. Same treatment as plan 11-04.

**2. [Owner override] Expected Skipped is 18, not 2**
- The plan names only the 2 D1 harness tests as Skipped. Under owner decision D11-22 the 16 audit methods are also Skipped by the `DP_RUN_A11Y_AUDIT` gate. Recorded as expected skipped-by-gate rows in the mapping table.

**3. [Extra row] Ledger observation DL-O02**
- The plan creates ledger rows only for newly observed flakes. I added one observation row because the four known-list tests all passed in the full run while the History edit tests failed in scoped run G3. Nothing was closed or waived.

**4. [Wait mechanism]**
- The run itself was one detached background job with no polling of its output. The foreground waits I used were single blocking loops on the existence of `full.exit`; no other build or test ran meanwhile.

## Auth gates

None.

## Known Stubs

None. No source file was created or changed by this plan.

## Threat Flags

None. The evidence holds counts, identifiers and PASS or FAIL values only; no simulator identifier or machine path was recorded.

## Verification

- Task 1, 2 and 3 gates pass against the result bundle (the Task 3 source-guard clause adapted as in deviation 1).
- Recorded overall and Services coverage match the recomputed `xccov` JSON values within 0.01.
- Digest of `full.log` in the evidence equals its SHA-256.

## Self-Check: PASSED

- `full.exit`, `full.log`, `coverage.json`, `coverage.txt` exist in the stamp directory; `build/p11-full.xcresult` exists.
- Commits `bba33ff`, `59ffc45`, `8c5d2bf` are ancestors of HEAD.
