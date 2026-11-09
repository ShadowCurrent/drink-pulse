---
phase: 10-data-platform-integration-modernization
plan: "11"
subsystem: concurrency-evidence
tags: [thread-sanitizer, swift-concurrency, coverage, swiftdata, healthkit, usernotifications]

requires:
  - phase: 10-data-platform-integration-modernization
    provides: "10-01 to 10-10 code, owner decisions F2, F3, F4, D-12 table and HealthKitAdapter record from 10-07"
provides:
  - "Thread Sanitizer evidence proven active by a deleted canary, then a clean scoped pass over 21 Phase 10 suites"
  - "10-CONCURRENCY-RECORD.md per-candidate records for C010, C011, C012"
  - "10-EVIDENCE.md with toolchain, TSan, zero-warning, guards, file size, full suite, coverage, C008 and C009 dispositions"
  - "docs/architecture.md updated for the recovery-reporting seam, route seam, notification cancel epoch and Health remove resolution"
affects: [10-12 device session, phase verification]

plan_head_before: 5044cfd496ef40b67944da27254656536dfc150e
plan_head_after: fd5c4784c77082e7ff425868da48ad498d69de05 (task commits only; the SUMMARY commit follows)
commits: 3

actuals:
  tokens: 16000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Sanitizer evidence only counts after a same-run canary reports a race under the same flag"
    - "Gate patterns for sanitizer reports must match the Swift wording (Swift access race), not only data race"

key-files:
  created:
    - .planning/phases/10-data-platform-integration-modernization/10-EVIDENCE.md
  modified:
    - .planning/phases/10-data-platform-integration-modernization/10-CONCURRENCY-RECORD.md
    - docs/architecture.md

key-decisions:
  - "C010 applied narrow fix (F3 epoch plus O1), C011 applied narrow fix (F2 query-first plus adapter qualifier), C012 retain, C008 retain, C009 retain"
  - "Broadened the plan's TSan report pattern to the bare word ThreadSanitizer after the canary showed the Swift report reads Swift access race"

requirements-completed: [MOD-03, DATA-01, INT-01, INT-02]

coverage:
  - id: D1
    description: "Thread Sanitizer activation proven by a deleted canary and a clean scoped pass over the final Phase 10 code"
    requirement: MOD-03
    verification:
      - kind: other
        ref: "build/p10-11-canary.log (race reported), build/p10-11-tsan.log (144 tests in 21 suites, no report)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Per-candidate concurrency records for C010, C011, C012 and C008/C009 dispositions"
    requirement: MOD-03
    verification: []
    human_judgment: true
    rationale: "Isolation reasoning and disposition wording need reviewer judgment; the plan's structural check passes."
  - id: D3
    description: "Zero-warning build, shipped-schema and CloudKit-off guards, file-size ceiling"
    requirement: INT-02
    verification:
      - kind: other
        ref: "xcodebuild clean build-for-testing (build/p10-11-gate-build.log); git diff --quiet fbd37fa guard; entitlements and cloudKitDatabase greps; wc gate"
        status: pass
    human_judgment: false
  - id: D4
    description: "Full unit and UI suite green; overall 94.61 percent, Services aggregate 98.33 percent, route 100 percent"
    requirement: MOD-03
    verification:
      - kind: automated_ui
        ref: "build/p10-11-full.log (678 unit tests in 59 suites, 93 UI tests, 0 failures); build/p10-11-coverage.json gate script"
        status: pass
    human_judgment: false

duration: 33min
completed: 2026-11-09
status: complete
---

# Phase 10 Plan 11: Concurrency evidence and phase gates Summary

**Thread Sanitizer shown active by a same-run canary, then clean over 21 Phase 10 suites; C010 to C012 records, C008 and C009 dispositions and the architecture doc completed; zero-warning build, schema and CloudKit-off guards and the full suite (678 unit and 93 UI tests) all green at 94.61 percent overall coverage.**

## Performance

- **Duration:** about 33 min (the full UI suite took about 29 min)
- **Started:** 2026-11-09T08:47:46Z
- **Completed:** 2026-11-09T09:20Z
- **Tasks:** 3 of 3
- **Files modified:** 3 (one created, two modified; no Swift source changed)

## Accomplishments

- Canary: a temporary racy test run under `-enableThreadSanitizer YES` produced `WARNING: ThreadSanitizer: Swift access race` (exit 65, recorded). It was deleted by the same script and never tracked. The scoped pass over the 21 listed suites then ran 144 tests with no sanitizer report.
- `10-CONCURRENCY-RECORD.md`: full six-subsection records for C010 (applied narrow fix: F3 epoch, O1), C011 (applied narrow fix: F2 query-first, adapter qualifier) and C012 (retain). The D-12 table and applied-changes section are intact; the handler row was already updated by 10-09.
- `10-EVIDENCE.md`: all headings filled. C008 disposition retain (10-01 chain, sweep and schema guard evidence), C009 disposition retain (10-03 sanitized fixture, DataTransfer suites, folder unchanged), each pointing to plan 10-12 for device proofs.
- `docs/architecture.md`: recovery-reporting seam, route seam (including the UI-test warm-tap hook), notification cancel epoch and Health remove resolution.
- Gates: clean build-for-testing with zero Swift, linker and compiler warnings; schemas, MigrationPlan, drinkpulseApp, WeeklySummaryCalculator and DataTransfer unchanged against `fbd37fa`; no cloud-container entitlement; no CloudKit-database reference; largest Swift file 263 lines.
- Full suite: 678 unit tests in 59 suites and 93 UI tests, 0 failures. Coverage: overall 94.61 percent; changed non-Persistence Domain set empty so the D-20 100 percent gate is vacuous (Domain aggregate 90.06 percent recorded, pre-existing gap stays in WINDOWS.md rows 7 and 1); Services aggregate 98.33 percent; HealthService 100, ReminderService 100, WeeklySummaryService 95.1, UITestNotificationCenter 93.8, route 100. No remediation test file was needed.

## Task Commits

1. **Task 1: canary and scoped TSan pass** - `663974c` (test)
2. **Task 2: C010 to C012 records, C008 and C009 dispositions, architecture doc** - `fc1d71e` (docs)
3. **Task 3: phase gates recorded** - `fd5c478` (docs)

**Plan metadata:** the SUMMARY commit follows this file.

## Files Created/Modified

- `.planning/phases/10-data-platform-integration-modernization/10-EVIDENCE.md` - evidence file with every gate result and the C008 and C009 dispositions
- `.planning/phases/10-data-platform-integration-modernization/10-CONCURRENCY-RECORD.md` - completed C010, C011, C012 records
- `docs/architecture.md` - living-doc update for the seams and the F2 and F3 behavior

## Decisions Made

- Dispositions as listed above; owner decisions F2 (`fix-query-first`) and F3 (`fix-service-epoch+handler-sendable`) were read from the committed records and applied as recorded, not re-decided.
- The sanitizer report pattern was widened to `ThreadSanitizer` (see Deviations).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] TSan report pattern did not match Swift's report wording**
- **Found during:** Task 1 (canary gate)
- **Issue:** The plan's pattern `ThreadSanitizer: data race|Data race detected` did not match the real report `WARNING: ThreadSanitizer: Swift access race`, so the canary gate failed although the sanitizer was active, and the same pattern would have made the later no-race check vacuous.
- **Fix:** Both checks use `ThreadSanitizer`. The canary log shows the race; the scoped pass log contains the word only in the echoed command line.
- **Files modified:** none (gate command only); documented in `10-EVIDENCE.md`.
- **Committed in:** 663974c

**2. [Rule 3 - Blocking] Simulator and command form**
- The orchestrator supplied one iOS 27.2 simulator and was the only executor, so no dedicated clone was made; `LOCAL_IOS_27_UDID_P10_11` pointed at the supplied simulator. The sandbox rejects runtime-computed values and compound git forms in `xcodebuild` calls, so the plan's automated commands were run as small scripts in the scratchpad (canary, scoped pass, gate build, full suite, coverage gate) with the same flags and the same checks; the coverage script applies the plan's assertions but prints all values before reporting failures. The full-suite run also used `-collect-test-diagnostics never` as the orchestrator directed.
- **Apple tooling route:** CLI fallback (`xcodebuild`, `simctl`, `xccov`) for every step; Xcode MCP acts on the main workspace and `DocumentationSearch` is not exposed to this executor, so the sanitizer flag source is `xcodebuild -help` and the API sources are the iPhoneOS 27.2 SDK headers.

**3. Commit attribution**
- The wrapper asks for Co-Authored-By and Claude-Session trailers. AGENTS.md forbids AI attribution in commit messages and takes precedence, so none were added.

**Total deviations:** 1 auto-fixed gate defect, 2 environment or convention adaptations. **Impact:** none on scope or results.

## Issues Encountered

None beyond the deviations above.

## Known Stubs

None.

## Threat Flags

None. No production Swift code, entitlement, schema or configuration changed (T-10-23 mitigated by the same-run canary, T-10-24 by the guards).

## Open items for the orchestrator

- Plan 10-12 owns the device proofs (D-05, D-08, assumption A5, risk R-01); the C008 and C009 dispositions stay final unless that session records a FAIL.
- Pre-existing Domain coverage gap (non-Persistence aggregate 90.06 percent, several files below 100) is recorded only, per D-20; `WINDOWS.md` was not edited.
- Simulator `02193FDE-...` (supplied) is shut down at the end of this run; `build/` artifacts are gitignored.

## Next Phase Readiness

Ready for plan 10-12. STATE.md and ROADMAP.md are left to the orchestrator.

## Self-Check: PASSED

- FOUND: 10-EVIDENCE.md, 10-CONCURRENCY-RECORD.md, docs/architecture.md; `drinkpulseTests/Services/TSanCanaryTests.swift` absent and untracked.
- FOUND commits: 663974c, fc1d71e, fd5c478 (ancestors of HEAD).
