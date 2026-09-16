---
phase: 08-ios-27-baseline-api-inventory
plan: "01"
subsystem: ios-build-baseline
tags: [xcode-27, ios-27, swift-6, xcresult, baseline]
requires: []
provides:
  - Complete, hashed primary evidence inventory for dependency resolution, Debug, Release, and full test invocations.
  - Truthful app-owned compiler-failure classification for Phase 09 remediation.
affects: [09, 10, 11]
actuals:
  tokens: 0
  tasks: 2
  commits: 0
tech-stack:
  added: []
  patterns: [External raw Xcode evidence is referenced by relative path and SHA-256 from the committed manifest.]
key-files:
  created: [.planning/phases/08-ios-27-baseline-api-inventory/08-01-SUMMARY.md]
  modified:
    - .planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.json
    - .planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md
key-decisions:
  - "Use the 20260916T200000Z capture as the primary baseline; retain the earlier sandbox attempt as history only."
  - "Classify the Swift concurrency compiler error as app-owned and send remediation to Phase 09."
requirements-completed: [PLAT-01, PLAT-02]
coverage:
  - id: D1
    description: iOS 27 build and test baseline evidence inventory
    requirement: PLAT-01
    verification:
      - kind: other
        ref: 08-BASELINE.json automated manifest verification
        status: pass
    human_judgment: false
  - id: D2
    description: Complete unit and UI test invocation baseline
    requirement: PLAT-02
    verification:
      - kind: integration
        ref: xcodebuild full test invocation recorded in 08-BASELINE.json
        status: fail
    human_judgment: true
    rationale: Compilation failed before either test target began; Phase 09 must remedy the app-owned compiler error before test behavior can be judged.
status: complete
---

# Phase 08 Plan 01 Summary

**Primary Xcode 27/iOS 27 baseline evidence now distinguishes one successful dependency resolution from three app-owned compiler failures.**

## Accomplishments

- Recorded the primary external capture at `20260916T200000Z` with all four required run entries, exact command lines, stdout/stderr paths, SHA-256s, exit codes, and available result-bundle paths.
- Recorded dependency resolution as passed (exit 0); Debug, Release, and full test commands as failed (exit 65), without converting any failure into a pass.
- Classified `DPArcProgress.swift:33` main-actor `Shape` conformance as app-owned and assigned remediation to Phase 09; retained the `AddDrinkView.swift:5` `@Entry` closure warning.
- Recorded all test counts as unavailable because compilation stopped before tests began, despite the shared scheme enabling both test targets.

## Verification

Ran the plan's Python manifest verification. It confirmed all required run entries, raw stream hashes, integer exit codes, full-test target count keys, and failure classification.

## Files

- `.planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.json` — primary capture manifest.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md` — human-readable baseline evidence.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-01-SUMMARY.md` — plan handoff.

## Next phase readiness

Phase 09 should fix the `ArcShape` actor-isolation compiler error, assess the `@Entry` closure warning, then recapture Debug, Release, and full-test evidence. No source files were changed in this continuation.
