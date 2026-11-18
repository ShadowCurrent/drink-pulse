---
phase: 10-data-platform-integration-modernization
plan: "10"
subsystem: notifications
tags: [weekly-summary, copy, localization, d-16, int-01, swift-testing]
requires:
  - phase: 10-data-platform-integration-modernization
    provides: "10-04 F4 decision record (10-DECISION-F4.md, outcome as-of-last-visit)"
provides:
  - "Owner-approved as-of-last-visit English wording for all five weeklySummary.notification.body.* keys"
  - "WeeklySummaryCopyTests literal-string wording guard"
  - "Closed copy todo with recorded UI test exemption"
affects: [10-12-device-session]
tech-stack:
  added: []
  patterns: ["Literal approved-string assertions on makeRequest body, independent of String(localized:)"]
key-files:
  created:
    - drinkpulseTests/Services/WeeklySummaryCopyTests.swift
  modified:
    - drinkpulse/Localizable.xcstrings
    - .planning/todos/completed/2026-09-15-clarify-weekly-alcohol-summary-comparison.md
key-decisions:
  - "Applied F4 outcome as-of-last-visit verbatim; no follow-up refresh todo (only created under d16-then-refresh)"
requirements-completed: [INT-01]
status: complete
actuals:
  tokens: 9000
  tasks: 2
  commits: 5
plan_head_before: 67514a19250f8db9e8c9359a88c8f9aabd8e272a
plan_head_after: 0475698e26e34298affdb53824e4389a3ef4adfc
metrics:
  completed: 2026-11-09
---

# Phase 10 Plan 10: Weekly Summary Copy Summary

The five weekly-summary notification bodies now carry the owner-approved as-of-last-visit wording from 10-DECISION-F4.md, pinned by literal-string Swift Testing assertions, and the folded copy todo is closed.

## Outcome applied

F4 Owner decision record: Outcome `as-of-last-visit`, decided 2026-11-09. Precondition met (not pending, not outside the D-16-compliant set). All five strings applied verbatim; `%d%%` kept in `down` and `up`, no specifier in the other three. Calculator, plus or minus 5 percent band, title and non-English localizations untouched (`git diff --stat fbd37fa -- drinkpulse/Domain/WeeklySummaryCalculator.swift` empty).

## Tasks and commits

| Step | Commit | Description |
| ---- | ------ | ----------- |
| T1 RED | c42ee58 | `test(10-10)`: literal `down` wording test (50 percent; 1, 50, 100 formatting) |
| T1 GREEN | 66e1cc5 | `feat(10-10)`: catalog `down` value |
| T2 RED | 78a4a70 | `test(10-10)`: up, same, directionOnlyUp, directionOnlySame, rounding boundaries, cross-variant invariants |
| T2 GREEN | acc6166 | `feat(10-10)`: catalog up, same, directionOnlyUp, directionOnlySame values |
| T2 docs | 0475698 | `docs(10-10)`: todo moved to completed with closing note and UI test exemption |

## TDD

- RED (T1): `down_body_equalsApprovedWording_with50Percent` and `down_body_formatsWholePercentWithoutStraySpecifier` (1, 50, 100) failed on the literal-equality `#expect` against the old copy ("You drank %d%% less than last week."). 2 tests, 4 issues. Semantic assessment: target tests executed and failed on the planned assertion; no build or load failure. The machine classifier `gsd_run check tdd-red-evidence` was not run: the evidence is `xcodebuild` console output, not one of its supported report formats (swift-testing `swift test` adapter); judged by manual inspection of `build/p10-10-red.log`.
- RED (T2): up, same, directionOnlyUp, directionOnlySame, the 0.995 boundary and the cross-variant invariant tests failed on assertion against old copy (10 tests, 12 issues); the `down` tests and the -0.051 boundary already passed from T1/existing logic. Semantic assessment: same as above, `build/p10-10-red2.log`.
- GREEN: catalog edits only; T1 run 25 tests in 4 suites passed, T2 run 42 tests in 5 suites passed (WeeklySummaryCopyTests, WeeklySummaryServiceTests, WeeklySummaryServiceScheduleTests, WeeklySummaryCompletedWeekTests, WeeklySummaryCalculatorTests, all unchanged and passing).
- REFACTOR: none.
- Tracer gate: T1 verify (tests plus catalog-vs-record consistency check plus calculator guard) re-run end to end and passed before expansion.

## Rounding boundaries (Pitfall 7)

-0.051 renders 5; 0.995 renders 100 (99.5 rounded); -0.5 renders 50; 1, 5, 50, 100 format correctly for up and down with no stray `%d`, `%%` or `%@`.

## UI test exemption

AGENTS.md UI tests rule, owner-accepted 2026-11-08. The five changed bodies have no `drinkpulseUITests` test because XCUITest cannot read system notification bodies: they exist only inside scheduled system notifications. Substitute evidence: the `WeeklySummaryCopyTests` literal-string assertions on the exact `UNNotificationRequest` body handed to the notification center, plus the plan 10-12 device session, which records natural weekly delivery if observed (best effort). Wording authority: `10-DECISION-F4.md`. Recorded also in the closing note of `.planning/todos/completed/2026-09-15-clarify-weekly-alcohol-summary-comparison.md`. No `drinkpulseUITests` file was added or changed.

## Apple documentation / API changes

No Apple API changed. The plan's `<read_first>` asked for String Catalogs and `String(localized:)` documentation via Xcode MCP DocumentationSearch. Xcode MCP was not used in this worktree session (MCP acts on the main workspace, not the worktree) and no web access was used, so that documentation was not consulted. The change is a value-only edit to existing catalog entries following the existing key, `extractionState`, `state` and `%d%%` convention, verified by compiler and tests, which is not a substitute for the documentation; the lookup remains unrecorded.

## Apple tooling route

CLI fallback (`xcodebuild test`, scoped `-only-testing`) for every step, because the Xcode MCP server targets the main workspace and not this worktree (task instruction). Simulator: the assigned iPhone 17e iOS 27.2 (`2CC6581D-8C11-4481-87E4-6CC08109554F`) booted with `xcrun simctl bootstatus -b`, used with worktree-local `-derivedDataPath build/` (not the plan's per-plan `build/p10-10` and `LOCAL_IOS_27_UDID_P10_10`, replaced by the orchestrator's parallel-wave assignment), shut down at the end. Logs: `build/p10-10-{red,red2,t1,t2}.log`.

## Deviations from Plan

- **Environment substitution (not a rule deviation):** used the orchestrator-assigned simulator and `build/` derived data path in place of the plan's `LOCAL_IOS_27_UDID_P10_10` and `build/p10-10`, per the parallel-wave instruction. The tool sandbox rejected compound shell commands, so the plan's chained `<automated>` commands were run as separate equivalent steps (xcodebuild test, log greps, the same python consistency checks, the calculator `git diff --stat`).
- **Test additions beyond the plan's listed cases:** added percent 5 to the formatting arguments (threat T-10-21 names 1, 5, 50, 100) and an `up` formatting test.
- **Commit attribution:** the dispatch attribution reminder asks for Co-Authored-By lines; AGENTS.md "Git commits & push" forbids any AI attribution in commit messages and takes precedence, so none were added.
- Otherwise: none. Plan executed as written.

## Living docs / checklist notes

No living doc references the old strings (`grep` over docs, README.md, `.claude`, source and test trees found none). `docs/DEVLOG.md`, STATE.md and ROADMAP.md were not touched here: the orchestrator owns shared tracking after the wave merge. File size: test file 105 lines. No logging added, no network, no new SDK.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- FOUND: drinkpulseTests/Services/WeeklySummaryCopyTests.swift
- FOUND: .planning/todos/completed/2026-09-15-clarify-weekly-alcohol-summary-comparison.md
- Pending todo absent; refresh follow-up todo correctly absent (outcome is as-of-last-visit)
- Commits c42ee58, 66e1cc5, 78a4a70, acc6166, 0475698 present on branch
