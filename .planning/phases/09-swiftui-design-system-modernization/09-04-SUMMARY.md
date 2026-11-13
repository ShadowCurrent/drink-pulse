---
phase: 09-swiftui-design-system-modernization
plan: "04"
subsystem: domain
tags: [swift-concurrency, actor-isolation, nonisolated, guideline-limits, xcode-mcp]

requires:
  - phase: 09-swiftui-design-system-modernization
    provides: "09-01 strict-concurrency remediation that introduced the member-level nonisolated (commit 7bf6b2a)"
provides:
  - "GuidelineLimits.effectiveDailyGrams declared in the type-level nonisolated struct body"
  - "Reproduced root cause, alternatives, measured baselines, owner ratification O1, and Xcode tooling record in 09-RETAIN-EVIDENCE.md"
  - "Phase 09 roadmap status set to gap closure in progress"
affects: [09-05, 09-06, 09-07, 09-08, 09-09, 09-10]

actuals:
  tokens: 6500
  tasks: 2
  commits: 2
plan_head_before: 9889ca77abba38a0a43c7c943fecb228a6437d19
plan_head_after: 12cd11be53f69a24ecdec7e6874366b880da878c

tech-stack:
  added: []
  patterns:
    - "Domain value-type members are declared in the type-level nonisolated body, never in a plain extension, so the app target's default MainActor isolation cannot leak onto them"

key-files:
  created: []
  modified:
    - drinkpulse/Domain/GuidelineLimits.swift
    - .planning/phases/09-swiftui-design-system-modernization/09-RETAIN-EVIDENCE.md
    - docs/DEVLOG.md
    - .planning/ROADMAP.md

key-decisions:
  - "Accessor lives in the nonisolated struct body (option c); rejected a member-level nonisolated in an extension, a nonisolated extension block, and main-actor test annotation"
  - "Owner ratification O1 recorded in 09-RETAIN-EVIDENCE.md only; AGENTS.md left unedited"

requirements-completed: [MOD-02]

coverage:
  - id: D1
    description: "effectiveDailyGrams is nonisolated by construction (type body), calculation unchanged, app and test targets compile"
    requirement: MOD-02
    verification:
      - kind: unit
        ref: "drinkpulseTests/GuidelineLimitsTests (full drinkpulseTests suite, 729 passed, 0 failed)"
        status: pass
      - kind: other
        ref: "build/d3-negative-control.log (reproduced compile failure) and build/d3-debug-after.log, build/d3-release-after.log (zero Swift warnings)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Isolation decision, owner ratification O1, Xcode tooling record, and in-progress roadmap status recorded"
    requirement: MOD-02
    verification: []
    human_judgment: true
    rationale: "Documentation content; the plan gate checks presence, adequacy is a reviewer judgment"

duration: 7min
completed: 2026-11-13
status: complete
---

# Phase 09 Plan 04: GuidelineLimits isolation design (gap closure D3) Summary

**`GuidelineLimits.effectiveDailyGrams` now sits inside the nonisolated struct body instead of a one-member extension with a compile-only annotation, with the main-actor inference reproduced from the project build and the decision recorded.**

## Performance

- **Duration:** about 7 min
- **Started:** 2026-11-13T13:51Z
- **Completed:** 2026-11-13T13:58Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Reproduced the root cause through Xcode MCP: with the accessor in a plain extension, `GuidelineLimitsTests` fails to compile with `main actor-isolated property 'effectiveDailyGrams' can not be referenced from a nonisolated context` (`build/d3-negative-control.log`).
- Moved the accessor into the `nonisolated struct GuidelineLimits: Sendable` body, byte-identical expression; the file now has one `nonisolated` keyword (was 2) and no extension block. No call site changed.
- Debug (app + drinkpulseTests) and Release builds: zero Swift warnings before and after; full `drinkpulseTests` suite 729 passed, 0 failed, `GuidelineLimitsTests` observed executing.
- Recorded decision, alternatives, measured baselines, owner ratification O1, and the Xcode tooling record in `09-RETAIN-EVIDENCE.md`; DEVLOG entry appended; ROADMAP Phase 09 status set to gap closure in progress.

## Task Commits

1. **Task 1: reproduce, move accessor, verify builds and tests** - `72b24e3` (fix)
2. **Task 2: record decision, O1, tooling record, roadmap status** - `12cd11b` (docs)

## Files Created/Modified

- `drinkpulse/Domain/GuidelineLimits.swift` - accessor moved into the nonisolated type body.
- `.planning/phases/09-swiftui-design-system-modernization/09-RETAIN-EVIDENCE.md` - new decision section, O1 subsection, tooling record.
- `docs/DEVLOG.md` - appended entry.
- `.planning/ROADMAP.md` - Phase 09 Status line only.

## Decisions Made

- Type-body declaration chosen over three alternatives (see the evidence file's alternatives table).
- The Debug "after" build was incremental (`GuidelineLimits.swift` and dependents recompiled in app and test target); zero-warning attribution for untouched files rests on the full baseline compile.

## Xcode tooling

Xcode MCP responded throughout (`XcodeListWorkspaces` used for the responsiveness check because `XcodeListWindows` is not in this session's tool schema). CLI `xcodebuild` was used only for the two Release builds: `BuildProject` accepts only `workspaceIdentifier` and `buildForTesting`, so Release-configuration selection is missing. The full unit suite ran through `RunSomeTests` with 64 class identifiers (a target-level identifier is rejected; `RunAllTests` would also run the 94 UI tests).

## Deviations from Plan

### Auto-fixed Issues

None in production code.

### Documented wording discrepancy

**1. [Rule 3 - Blocker-adjacent] Packaging note wording on Xcode 27.2 differs from the ratified text**
- **Found during:** Task 1 baseline builds
- **Issue:** The measured line is `appintentsmetadataprocessor[<pid>:<tid>] warning: Metadata extraction skipped, no AppIntents.framework dependency found` (comma, lowercase "no"); the plan and O1 name `... skipped. No AppIntents.framework dependency found.`
- **Fix:** Recorded both texts in 09-RETAIN-EVIDENCE.md O1 subsection as the same tool and note; `GetBuildLog` reports 0 warning-severity entries for every Debug build. Not edited in AGENTS.md. The orchestrator or owner may want to confirm the ratification covers the measured wording; the plan's automated gate passes unchanged because the log lines do not match its warning regex.
- **Files modified:** 09-RETAIN-EVIDENCE.md

**Total deviations:** 1 documentation discrepancy, 0 code changes. **Impact:** none on the gate result.

## Issues Encountered

- An initial commit message carried the harness attribution trailer, contradicting the project's no-AI-attribution rule; it was amended before any further work (local, unpushed). Hash `72b24e3` is the amended commit.

## Known Stubs

None.

## Threat Flags

None. No network, auth, file-access, or schema surface touched (T-09-09 mitigated by identical expression plus full suite; T-09-10 by restore plus file assertion).

## Next Phase Readiness

Ready for 09-05. `build/` evidence logs `d3-*.log` are local and git-ignored; later plans share the single `build/` directory sequentially.

## Self-Check: PASSED

- `drinkpulse/Domain/GuidelineLimits.swift`, `09-RETAIN-EVIDENCE.md`, all six `build/d3-*.log` files exist.
- Commits `72b24e3` and `12cd11b` are ancestors of HEAD; `git rev-list --count` from the recorded base is 2.
- Task 1 and Task 2 automated gates re-run and pass; no file over 300 lines; AGENTS.md unchanged.
