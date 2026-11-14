---
phase: 11-ios-27-release-verification
plan: 02
subsystem: verification
tags: [debt-ledger, discovery-reconciliation, ver-01, ver-03, sc5, records-only]

requires:
  - phase: 08-ios-27-baseline-api-inventory
    provides: decision register C001 to C013 and inventory candidates
  - phase: 09-swiftui-design-system-modernization
    provides: retain evidence, D1 flash diagnosis and closure record
  - phase: 10-data-platform-integration-modernization
    provides: dispositions, owner decisions F2 to F4, device finding, residuals R-01 to R-03
provides:
  - "11-DEBT-LEDGER.md: 63 ledger rows listing every open item with status as read and owner; nothing closed"
  - "VER-01 known non-green tests DL-T01 to DL-T07 with cause, link and owner"
  - "Two reserved empty tables (accessibility allow-list, Phase 11 observations) for later plans"
  - "11-DISCOVERIES.md: 26 machine-verified discovery and Phase 05 rows, 0 GAP flags"
  - "Phase 05 skipped checks (05-UAT tests 4, 5, 6) mapped to CHK-03, CHK-01, CHK-02, pending plan 11-07"
affects: [11-03, 11-04, 11-05, 11-07, 11-08, 11-09, 11-10]

actuals:
  tokens: 8100
  tasks: 2
  commits: 2
plan_head_before: 7e3738b00de7b89b1497b216539a1e5b94b1aa87
plan_head_after: 80f5756ec541ffb497874cec4162fc4c793fb993

tech-stack:
  added: []
  patterns:
    - "Ledger rows quote the source file's own status wording; the Phase 11 action column says only listed, linked or watched"
    - "Discovery rows carry a backticked file and verbatim string that a script looks up in the real file"

key-files:
  created:
    - .planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md
    - .planning/phases/11-ios-27-release-verification/11-DISCOVERIES.md
  modified: []

key-decisions:
  - "WINDOWS row 12 (Phase 11 MOD-04, added by plan 11-01) is listed as DL-W12 in addition to the eleven rows the plan names"
  - "The todo 2026-09-15-migrate-project-to-ios-27... is recorded as a stale-frontmatter record, with the note that plan 10-12 left it in pending on purpose as a milestone umbrella"
  - "Discovery gap flags are split: GAP only where no analysis or outcome record exists (none found), OPEN where an outcome is recorded but later verification or an owner decision is pending (8 rows)"

requirements-completed: []  # VER-01 and VER-03 are only partly served (records); they complete with plans 11-04, 11-07 and 11-08

duration: 9min
completed: 2026-11-14
status: complete
---

# Phase 11 Plan 02: Debt Ledger and Discovery Reconciliation Summary

**Read-only audit records: a 63-row debt ledger that lists and closes nothing, and a discovery reconciliation where all 26 outcome strings were looked up in their cited files.**

## Accomplishments

- `11-DEBT-LEDGER.md` lists D1 (DL-D01 to DL-D08), all WINDOWS rows (DL-W01 to DL-W12), all 14 open-questions headings, all 8 pending todos, the three prior-phase verification record states, Phase 10 residuals, project-level debt, four record-state contradictions and the privacy-manifest question. The header carries the sentence "Phase 11 lists these items and closes none."
- VER-01 exceptions are recorded as DL-T01 to DL-T07 with cause, link and owner. DL-T02 and DL-T03 state that whether the app or the tests are wrong is undetermined. DL-T07 is the Phase 10 single-run flake that is not on the CONTEXT list, handled by the unknown-failure protocol.
- Interrupted migration and interrupted Health write stay acknowledged residuals (DL-R01, DL-R02), not re-tested here.
- `11-DISCOVERIES.md` gives C001 to C013, F2 to F4, the device finding, D1, UI-C-02, UI-C-03 and UI-C-07, WR-04, R1-WR-01 to WR-03 and the privacy-manifest question a recorded analysis and outcome. The three Phase 05 skipped checks map to CHK-03, CHK-01 and CHK-02 with outcome pending (recorded by plan 11-07).
- Both tables reserved for later plans (allow-list for 11-03, observations for 11-04, 11-05, 11-07) and the "Phase 11 new findings" table exist and read "No entries yet."

## Task Commits

| Task | Name | Commit |
|------|------|--------|
| 1 | Debt ledger | cf394a6 |
| 2 | Discovery reconciliation | 80f5756 |

## Verification

- Task 1 script: passed (14 open questions, 8 todos, 11 WINDOWS rows, no closed, fixed or waived status outside DL-W05).
- Task 2 script: passed (26 rows verified against their cited file).
- Diff guard: `.planning/WINDOWS.md`, `.planning/todos`, `.claude/context/open-questions.md` and the three VERIFICATION files are unchanged against the plan-start commit `7e3738b`.
- No build or test was run (docs-only plan; D11-20).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Diff-guard baseline predates the sibling plan's WINDOWS.md edit**
- **Found during:** Task 1 verification
- **Issue:** The plan's guard diffs against `2aa9156`. Plan 11-01 (same wave) legitimately appended WINDOWS row 12 after that commit, so `git diff --quiet 2aa9156 -- .planning/WINDOWS.md` exits 1 even though this plan edited nothing.
- **Fix:** Ran the same guard against the plan-start commit `7e3738b`, where it exits 0. Against `2aa9156` the guard also exits 0 for every path except WINDOWS.md, whose only difference is the 11-01 row.
- **Files modified:** none
- **Commit:** n/a

**2. [Rule 1 - Accuracy] Record states differ from the plan text at execution time**
- **Found during:** Task 1
- **Issue:** The plan describes WINDOWS as 11 rows and STATE.md as current_phase 09. Both changed since research (row 12 from plan 11-01; STATE.md now current_phase 11, executing). HistoryInteractionUITests.swift reads 225 lines.
- **Fix:** DL-W12 added; DL-C01 states both the research-time and the plan-start reading; DL-W02 records 225 lines as an observation only, status stays open.
- **Commit:** cf394a6

**3. [Rule 1 - Accuracy] Requirements not marked complete**
- **Issue:** The state protocol marks the plan's `requirements` complete. VER-01 and VER-03 say builds, suites and accessibility checks pass. This plan only produces the debt and discovery records, so the checks have not run.
- **Fix:** REQUIREMENTS.md was reverted to its prior state after the mark was applied; `requirements-completed` is empty. The requirements complete when plans 11-04, 11-07 and 11-08 record the evidence.
- **Commit:** n/a (reverted before commit)

Otherwise the plan was executed as written.

## Known Stubs

None. The two reserved tables read "No entries yet." by design; plans 11-03, 11-04, 11-05 and 11-07 fill them.

## Threat Flags

None. No network, auth, file-access or schema surface was touched. Records quote identifiers and status words only.

## Self-Check: PASSED

- FOUND: 11-DEBT-LEDGER.md, 11-DISCOVERIES.md
- FOUND commits: cf394a6, 80f5756
