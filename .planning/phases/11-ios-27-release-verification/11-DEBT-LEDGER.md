# Phase 11 Debt Ledger

Date: 2026-11-14. Plan: 11-02. Requirements: VER-01 (limitations clause), VER-03 (outstanding debt clause). CONTEXT decisions: D11-01, D11-02, D11-10.

This ledger records every open verification, test and product item that Phase 11 touches or could be mistaken for closing. Phase 11 lists these items and closes none. A status changes only when the owner acts and evidence exists. WINDOWS.md rows change only through the owner running the `windows fixed` or `windows waive` commands. Todo files, open-questions entries and the Phase 08, 09 and 10 verification records are not edited here.

Column rules: "Status as read" quotes the source file's own wording and date and is not reinterpreted. "Owner" is `owner` for owner-held decisions and `executor` only for Phase 11 evidence rows. "Phase 11 action" says only listed, linked to a checklist item, or watched.

## Known non-green tests (VER-01 exceptions)

D11-02: no test or app fixes in Phase 11 for these items. A failure not on this list is a blocker, not a silent exception. A listed test that unexpectedly passes is recorded without removing it from its todo or open-questions entry.

| ID | Item | Source | Status as read | Owner | Phase 11 action |
|----|------|--------|----------------|-------|-----------------|
| DL-T01 | `InsightsUITests.test_heroCard_holdsHeight_whenSwitchingToAllTimeScope` fails. Cause as recorded: Week chart y=323.0, All chart y=320.0, tolerance 1.0; whether the hero card moves or the tolerance is too tight is not established. | open-questions entry "Insights hero card height test fails (pre-existing)" | "Found 2026-11-09 ... fails reproducibly" and fails the same way on commits `2cb2649` and `fbd37fa` (checked 2026-11-10), so it predates Phase 10. Owner chose to log it and continue. | owner | listed; expected to fail in the full run |
| DL-T02 | `HistoryInteractionUITests.test_editCustomNameAndNotes_persist` fails (failure line 165 in the todo). Whether the app or the test is wrong is undetermined, so the data-integrity risk in the edit flow is undetermined. | todo `2026-11-13-history-edit-uitests-failing.md`; open-questions entry "History edit UI tests fail on their own" | "fail deterministically ... including on the single retry" (2026-11-13). Waived by name for the plan 09-08 scoped gate only; the todo says the waiver does not extend to later plans or phase verification and that diagnosis is due before a full-suite gate at milestone close. | owner | listed; D11-02 records it as a Phase 11 limitation |
| DL-T03 | `HistoryInteractionUITests.test_editCategoryChange_persists` fails (failure line 220 in the todo). Whether the app or the test is wrong is undetermined, so the data-integrity risk is undetermined. | same todo and open-questions entry as DL-T02 | same wording as DL-T02; earlier recorded as flaky in a prior debug session, now deterministic | owner | listed; D11-02 records it as a Phase 11 limitation |
| DL-T04 | `ExportUITests.test_export_dismissWithoutSaving_showsNoFailureAlert` fails intermittently ("Save panel should present before dismissal"). | todo `2026-11-13-export-dismiss-uitest-flaky.md` | Failed in the Phase 09 closing full run (821 of 826 passed, 2026-11-13); earlier Phase 10 runs recorded it as a single-run flake that passed on re-run. Owner decision 2026-11-13: record as known flake without a re-run. | owner | listed; expected intermittent |
| DL-T05 | `SheetDismissTabSwitchUITests.test_sheetCancelThenTabSwitch_cycle_staysNavigable_recordsFrameDeltas` is a D1 harness test gated behind the environment variable `DP_RUN_FLASH_HARNESS`. | todo `2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md` | Deferred 2026-11-13 with D1. Expected to report Skipped, not Failed. A full-suite run has never confirmed end to end that it stays skipped; Phase 11 is the first run that can. | owner | listed; watched for Skipped |
| DL-T06 | `SheetDismissTabSwitchUITests.test_sheetCancelThenTabSwitch_emptyStore_recordsFrameDeltas`, same gate and same expectation as DL-T05. | same todo as DL-T05 | same wording as DL-T05 | owner | listed; watched for Skipped |
| DL-T07 | `HistoryInteractionUITests.test_segmentSwitch_alternatingDirection_endsInCorrectState`, a single-run flake observed in the Phase 10 plan 10-13 full run that passed on re-run. Not on the CONTEXT list. | open-questions entry "Insights hero card height test fails (pre-existing)" (last sentence of Current state) | "failed once and passed on re-run (flake)". Unknown-failure protocol if it fails: re-run once alone; a pass means a newly observed flake plus a todo; a second failure is a blocker for the owner. | owner | watched |

## D1: Dashboard flash and simulator crash

| ID | Item | Source | Status as read | Owner | Phase 11 action |
|----|------|--------|----------------|-------|-----------------|
| DL-D01 | Device flicker after Add Drink dismissal and tab change (iPhone 15 Pro Max, iOS 27). | todo `2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md`; `09-FLASH-DIAGNOSIS.md` | "Owner outcome: deferred, flicker not confirmed gone". Deferred 2026-11-13, not fixed, not device-confirmed; the flicker was never measured. Todo not moved to completed. | owner | listed |
| DL-D02 | Intermittent iOS 27 simulator crash in private Liquid Glass code (`MaterialProviderBox.resolveLayers`), after a sheet cycle then a tab switch onto a tab with a live `glassEffect` card. | same todo and `09-FLASH-DIAGNOSIS.md`; open-questions entry "Dashboard flash after Add Drink dismissal and tab change" | Classification C-INCONCLUSIVE, no cure proposed. Owner decision C013 (`revert-container-only`, 2026-11-13) fixes neither symptom. | owner | listed |
| DL-D03 | Open hypotheses H1 to H6. | open-questions entry "Dashboard flash after Add Drink dismissal and tab change" | "Still open: H1 to H6" | owner | listed |
| DL-D04 | Crash candidates G1 to G6. | same entry | "crash candidates G1 to G6 (never measured)" | owner | listed |
| DL-D05 | Video flicker metric (frame-delta evidence). | same entry; `09-FLASH-DIAGNOSIS.md` | "the video flicker metric" still open; frame-delta evidence untouched and unmeasured | owner | listed |
| DL-D06 | Unsubmitted Apple Feedback draft. | same entry | "the unsubmitted Apple Feedback draft" | owner | listed |
| DL-D07 | Owner-device confirmation, empty-data behavior on the device, adjacency and ordering assumptions. | same entry (Phase 09 closure paragraph) | "empty-data behavior on the device (never measured), the adjacency and ordering assumptions (unchecked)" and device confirmation not requested in Phase 09 | owner | listed |
| DL-D08 | Full `RunAllTests` confirmation that the two harness tests stay skipped. | same entry (Phase 09 closure paragraph) | Only `GetTestList` and a `RunSomeTests` run confirmed it; see DL-T05 and DL-T06 | executor | watched in the Phase 11 full run |

## WINDOWS.md rows

Frontmatter as read at plan start: `open_count: 11`, `fixed_count: 1`, `total_count: 12`, `last_updated: 2026-11-14T12:22:54.934Z`. Row 12 was added by plan 11-01 (see DL-W12); rows 1 to 11 carry the recorded dates of 2026-07-27 to 2026-08-04. Status of rows 1 to 11 as read: 10 open, row 5 fixed.

| ID | Item | Source | Status as read | Owner | Phase 11 action |
|----|------|--------|----------------|-------|-----------------|
| DL-W01 | Pre-existing Domain coverage gap predating Phase 2 (DrinkTemplate 46%, TemplateRecord 64%, SchemaV1 to V3 68 to 77%, BackupExport and BackupDocument 66 to 69%, ConsumptionEvent 83%) against the literal Domain 100% target. Same Domain-coverage gap as DL-W07 (recorded earlier, in phase 02). | `.planning/WINDOWS.md` id 1 (phase 02, unmet-truth, recorded 2026-07-27) | open | owner | listed |
| DL-W02 | `HistoryInteractionUITests.swift` exceeded the 300-line ceiling when recorded (319 lines, 324 after an additive parameter). Observation only: `wc -l` on 2026-11-14 reads 225 lines for this file. The status stays open. | id 2 (phase 06, deviation, recorded 2026-07-31) | open | owner | listed with the current line count as an observation |
| DL-W03 | C14-2 VoiceOver rotor check unrun: Duplicate and Delete appear as VoiceOver Actions on a History row and Delete presents the confirmation. | id 3 (phase 07, unrun-verify, recorded 2026-08-03) | open | owner | linked to CHK-10 (optional); not closed by running the checklist |
| DL-W04 | C14-7 contrast audit unrun over the History list in light, dark and Increase Contrast. | id 4 (phase 07, unrun-verify, recorded 2026-08-03) | open | owner | linked to CHK-09; not closed by running the checklist |
| DL-W05 | HealthWriteHooksUITests delete test updated after the Delete confirmation gate. | id 5 (phase 07, deviation, recorded 2026-08-03) | fixed (resolved 2026-08-03T22:52:45.872Z; the only fixed row, as the file reads it) | owner | listed |
| DL-W06 | B9-3 human check: glass card appearance in light, dark and at AX5 not visually verified. | id 6 (phase 07, unrun-verify, recorded 2026-08-03) | open | owner | linked to CHK-07; not closed by running the checklist |
| DL-W07 | Domain layer coverage 89.39% against the 100% per-layer target (15 of 32 files below 100%). The row CONTEXT D11-10 names. Same Domain-coverage gap as DL-W01. | id 7 (phase 07, unmet-truth, recorded 2026-08-03) | open | owner | listed |
| DL-W08 | B10-1 human check not performed: first frame of an all-outside-window History shows a centered progress indicator. | id 8 (phase 07, unrun-verify, recorded 2026-08-03) | open | owner | listed |
| DL-W09 | WR-01 section-cache fix has no dedicated UI-test regression proof. | id 9 (phase 07, deviation, recorded 2026-08-04) | open | owner | listed |
| DL-W10 | WR-02 accessibility label embeds literal English outside `String(localized:)`. | id 10 (phase 07, deviation, recorded 2026-08-04) | open | owner | listed |
| DL-W11 | WR-03 `dailyLimit` 20-gram no-profile fallback is an unnamed magic number. | id 11 (phase 07, deviation, recorded 2026-08-04) | open | owner | listed |
| DL-W12 | MOD-04: Release device build holds 1 app-owned warning (iPad interface orientations validation notice from Info.plist). Added by plan 11-01 on 2026-11-14. | id 12 (phase 11, unmet-truth, recorded 2026-11-14, milestone v1.4); `11-01-SUMMARY.md` | open; owner decision pending (fix in a source-touching plan or accept with rationale) | owner | listed |

`/gsd-ship` blocks while `open_count > 0`. This ledger does not change the counter.

## Open questions

One row per second-level heading of `.claude/context/open-questions.md`, heading text verbatim.

| ID | Item | Source | Status as read | Owner | Phase 11 action |
|----|------|--------|----------------|-------|-----------------|
| DL-Q01 | Production build date and privacy manifest | `.claude/context/open-questions.md` | Open. "Relevant to Phase 11 release verification." No `PrivacyInfo.xcprivacy` found by the entry's own check. See DL-M01. | owner | listed |
| DL-Q02 | Store recovery fires on any ModelContainer open error | `.claude/context/open-questions.md` | Open. Phase 10 code review WR-01, "left open by the WR-04 fix"; product decision on the user-facing notice and an allowlist of recovery triggers pending. See DL-R04. | owner | listed |
| DL-Q03 | Insights hero card height test fails (pre-existing) | `.claude/context/open-questions.md` | Open. Found 2026-11-09; owner chose to log and continue. See DL-T01. | owner | listed |
| DL-Q04 | Weekly summary natural delivery not yet observed on device | `.claude/context/open-questions.md` | Open. "only a natural weekly delivery remains unobserved" after the 2026-11-09 and 2026-11-10 device sessions. | owner | listed |
| DL-Q05 | Debugger attach to the iPhone hangs | `.claude/context/open-questions.md` | Open. Seen in the 2026-11-09 device session; "Treated as a tooling observation, not an app result." | owner | listed |
| DL-Q06 | Dashboard flash after Add Drink dismissal and tab change | `.claude/context/open-questions.md` | Open. "Deferred by the owner on 2026-11-13 out of Phase 09 to the pending todo". See DL-D01 to DL-D08. | owner | listed |
| DL-Q07 | History edit UI tests fail on their own | `.claude/context/open-questions.md` | Open. "Waived by name for Phase 09 by the owner"; tracked in the pending todo. See DL-T02 and DL-T03. | owner | listed |
| DL-Q08 | Deferred Phase 09 code-review findings | `.claude/context/open-questions.md` | Open. "Deferred by owner decision O3 (2026-11-13)", captured one item each in the pending triage todo. | owner | listed |
| DL-Q09 | BAC implementation | `.claude/context/open-questions.md` | Open. "Formula documented in `docs/domain.md`. Not implemented." Propose before implementing; owner hand-verifies. | owner | listed |
| DL-Q10 | Multi-currency spend aggregation | `.claude/context/open-questions.md` | Open. "Spend is not yet displayed anywhere"; aggregation option undecided. | owner | listed |
| DL-Q11 | Guideline alert card tap action | `.claude/context/open-questions.md` | Open. "Card is rendered non-tappable (option C by default per plan-0001 execution)"; owner picks an option. | owner | listed |
| DL-Q12 | History native swipe-to-delete | `.claude/context/open-questions.md` | Open. Row-shape blocker gone; context-menu Delete remains the sole delete path "purely by choice". | owner | listed |
| DL-Q13 | Apple Watch: data transport | `.claude/context/open-questions.md` | Open. "Not started. Depends on iCloud sync being in place first." | owner | listed |
| DL-Q14 | Domain-layer test coverage is below its stated target | `.claude/context/open-questions.md` | Open. 89.39%, 15 of 32 files below 100% at the Phase 07 close (2026-08-04). Same gap as DL-W01 and DL-W07. | owner | listed |

## Pending todos

One row per file in `.planning/todos/pending`, file name verbatim.

| ID | Item | Source | Status as read | Owner | Phase 11 action |
|----|------|--------|----------------|-------|-----------------|
| DL-P01 | `2026-07-31-add-branch-per-milestone-workflow-to-gsd-config.md` (tooling, minor) | `.planning/todos/pending` | Pending. Created 2026-07-31; solution "TBD". | owner | listed |
| DL-P02 | `2026-08-27-add-practical-history-list-filtering.md` (minor) | `.planning/todos/pending` | Pending. Created 2026-08-27. | owner | listed |
| DL-P03 | `2026-08-27-scope-name-autocomplete-by-drink-category-and-abv.md` (minor) | `.planning/todos/pending` | Pending. Created 2026-08-27. | owner | listed |
| DL-P04 | `2026-09-15-migrate-project-to-ios-27-and-modernize-codebase.md` (major) | `.planning/todos/pending` | Pending. Frontmatter reads `resolves_phase: 08`, yet the file still sits in pending, so the record is stale. Plan 10-12 states the umbrella todo spans the whole milestone and was left in pending on purpose. Recorded, not changed here. See DL-C04. | owner | listed |
| DL-P05 | `2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md` (major) | `.planning/todos/pending` | Pending. "Status 2026-11-13 (plan 09-10): still pending"; D1 deferred. See DL-D01 to DL-D08. | owner | listed |
| DL-P06 | `2026-11-13-export-dismiss-uitest-flaky.md` (testing, minor) | `.planning/todos/pending` | Pending. Created 2026-11-13; known flake recorded without a re-run. See DL-T04. | owner | listed |
| DL-P07 | `2026-11-13-history-edit-uitests-failing.md` (testing, major) | `.planning/todos/pending` | Pending. Created 2026-11-13; two tests fail deterministically; waiver limited to the plan 09-08 gate. See DL-T02 and DL-T03. | owner | listed |
| DL-P08 | `2026-11-13-triage-deferred-phase-09-review-findings.md` (minor) | `.planning/todos/pending` | Pending. Created 2026-11-13; WR-01 to WR-04 and IN-01 to IN-04 deferred by owner decision O3 (WR-05 was fixed by plan 09-05). | owner | listed |

## Verification record states

CONTEXT D11-01 calls the 08 and 10 records stale. This ledger records them as read. Phase 11 does not re-run the phase verifier for 08, 09 or 10 (a deferred idea) and does not edit these files. Staleness is relative to a covered-files digest that Phase 11 does not re-evaluate.

| ID | Item | Source | Status as read | Owner | Phase 11 action |
|----|------|--------|----------------|-------|-----------------|
| DL-V01 | Phase 08 verification record | `08-VERIFICATION.md` frontmatter | status passed; verified 2026-11-12T20:36:28Z; score 23/23 must-haves (1 via owner override) | owner | listed |
| DL-V02 | Phase 09 verification record | `09-VERIFICATION.md` frontmatter | status gaps_found; score 12/14; verified 2026-11-12T21:55:00+01:00, written before plan 09-10 (the closure that deferred D1). Verifier-generated, not hand-edited. | owner | listed |
| DL-V03 | Phase 10 verification record | `10-VERIFICATION.md` frontmatter | status passed; verified 2026-11-10T19:18:16Z; score 10/10 (9 verified, 1 passed via owner-accepted override) | owner | listed |

## Phase 10 residuals

| ID | Item | Source | Status as read | Owner | Phase 11 action |
|----|------|--------|----------------|-------|-----------------|
| DL-R01 | R-01 interrupted migration: a process kill during a real store migration cannot be reproduced on demand. Not re-tested in Phase 11; store recovery on failure is covered by named suites that plan 11-04 runs. | `10-DEVICE-SESSION.md` residual table | acknowledged | owner | listed |
| DL-R02 | R-02 interrupted Health write: a kill between the HealthKit save and the local cache write cannot be reproduced on demand. Not re-tested in Phase 11; covered by named suites that plan 11-04 runs. | `10-DEVICE-SESSION.md` residual table | acknowledged | owner | listed |
| DL-R03 | R-03 cold-tap finite sample: three killed-app taps are a finite sample of system delivery timing. | `10-14-SUMMARY.md`; `10-DEVICE-RETEST.md` | "Owner accepted residual risk R-03" (killed-app taps 3 of 3 correct; weekly cold tap N/A) | owner | listed |
| DL-R04 | WR-04 store recovery fires on any open error. | open-questions entry; STATE.md Phase 10 decision line | Deferred; "decide allowlist fix vs. accept". See DL-Q02. | owner | listed |

## Project-level debt

| ID | Item | Source | Status as read | Owner | Phase 11 action |
|----|------|--------|----------------|-------|-----------------|
| DL-H01 | Launch-icon real-hardware size quirk: two opposite-direction size edits produced no visible on-device difference. | `.planning/PROJECT.md` Current State tech debt; STATE.md blockers | "owner accepted current 60pt (D-03 spec) state rather than continue chasing it" | owner | listed |
| DL-H02 | STATE.md blocker line "Accessibility audit (VoiceOver, Dynamic Type up to AX5) is still outstanding — not yet started". This is exactly VER-03; plan 11-08 updates the line from evidence. | `.planning/STATE.md` Blockers/Concerns | open as read | owner | linked to the VER-03 checklist; the line is not edited here |

## Record-state contradictions

Plans 11-08 and 11-09 reconcile the living documents. The frozen records are not rewritten.

| ID | Item | Source | Status as read | Owner | Phase 11 action |
|----|------|--------|----------------|-------|-----------------|
| DL-C01 | STATE.md frontmatter against ROADMAP.md and REQUIREMENTS.md. At research time STATE.md read current_phase 09, status verifying, completed_phases 1. At plan start it reads current_phase 11, status executing, completed_phases 1 of 4, while ROADMAP.md marks every Phase 08, 09 and 10 plan checked and REQUIREMENTS.md marks Phase 09 complete. | `.planning/STATE.md`; `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md` | contradiction as read | owner | listed; reconciled by plan 11-08 |
| DL-C02 | `.claude/context/current-focus.md` says the next step is the Phase 09 re-verification run, then Phase 11. CONTEXT D11-01 overrides it: proceed without re-verifying Phases 08 to 10. | `.claude/context/current-focus.md`; `11-CONTEXT.md` | contradiction as read | owner | listed; reconciled by plan 11-08 |
| DL-C03 | ID namespace collision: the Phase 08 inventory candidates use C001-C021 while the decision register uses C001 to C013, and they differ. See `11-DISCOVERIES.md`. | `08-INVENTORY.md`; `08-DECISION-REGISTER.md` | recorded, not fixed | owner | listed |
| DL-C04 | Stale pending-todo record: DL-P04 carries `resolves_phase: 08` in frontmatter yet sits in pending. | `.planning/todos/pending/2026-09-15-migrate-project-to-ios-27-and-modernize-codebase.md` | stale record as read, not changed here | owner | listed |

## Privacy manifest and production build date

| ID | Item | Source | Status as read | Owner | Phase 11 action |
|----|------|--------|----------------|-------|-----------------|
| DL-M01 | Does the app need a privacy manifest before App Store submission, and should production users see a build date. No `PrivacyInfo.xcprivacy` found by the entry's own `find` check; the app uses UserDefaults and `@AppStorage`. Ledger entry only; not resolved in Phase 11 (CONTEXT research follow-up). | open-questions entry "Production build date and privacy manifest" | open; "Relevant to Phase 11 release verification." | owner | listed |

## Accessibility audit allow-list (filled by plan 11-03)

There is no allow-list. Owner decision D11-22 (2026-11-14) superseded D11-12's "allow-list, green run" contract: the first audit run found 385 reports, 311 byte-wise distinct keys (exploratory record, corrected), which are recorded here as open findings, not allow-listed and not fixed in Phase 11. The heading keeps its original text so references to it still resolve. Per-key detail (311 byte-wise distinct keys, a key per line) is in the out-of-git file `audit-exploratory.txt`, digest in `11-EVIDENCE.md` section "Accessibility audit (exploratory run, D11-22)"; this ledger holds one row per probable root-cause group (screen plus audit type), not one row per key. Group IDs are `A11Y-AUDIT-Gnn`. The group assignment is a hypothesis from element names, not a diagnosis, and it is provisional for the keys of the nine unreliable rows (they ran in dark appearance; `11-EVIDENCE.md` Record integrity) until plan 11-13 refreshes the baseline. The earlier figure "254 distinct" from `11-VERIFICATION.md` is a locale artifact of `sort -u`; the byte-wise distinct count is 311, so the group figures below are unchanged. `AccessibilityAuditUITests` stays in the repo gated behind `DP_RUN_A11Y_AUDIT=1` and skips by default.

| ID | Group (screen, audit types) | Distinct keys (corrected) | Probable root cause | Status | Owner | Next step |
|----|-----------------------------|-----:|---------------------|--------|-------|-----------|
| A11Y-AUDIT-G01 | Add Drink: contrast 49, dynamicType 21, textClipped 41 | 111 | Drink-type tiles (emoji plus type name): clipping and contrast of the emoji and label at default size and AX5 | open: recorded, not fixed | owner | owner D-09 brief required before any fix (accessibility is a D-09 trigger); Phase 11 makes no fix |
| A11Y-AUDIT-G02 | Add Drink: contrast 2, dynamicType 2 | 4 | Toolbar Cancel button | open: recorded, not fixed | owner | same as G01 |
| A11Y-AUDIT-G03 | Home: contrast 35, dynamicType 12, textClipped 2 | 49 | Dashboard card text (secondary styles on glass cards, fixed-size values, "140 kcal" clipped) | open: recorded, not fixed | owner | same as G01 |
| A11Y-AUDIT-G04 | Insights: contrast 31, dynamicType 24, textClipped 10 | 65 | Summary cards and range/comparison labels; "505 kcal" and card titles clipped | open: recorded, not fixed | owner | same as G01 |
| A11Y-AUDIT-G05 | Insights: sufficientElementDescription 21, hitRegion 14 | 35 | Chart day marks exposed as raw timestamps without a description; small hit regions at AX5 and dark | open: recorded, not fixed | owner | same as G01 |
| A11Y-AUDIT-G06 | Settings: contrast 14 | 14 | Section headers and the reminder caption | open: recorded, not fixed | owner | same as G01 |
| A11Y-AUDIT-G07 | Onboarding: contrast 4, dynamicType 2, hitRegion 2, textClipped 2 | 10 | Welcome step: Get Started, subtitle, heart emoji, "Step 1 of 4" element | open: recorded, not fixed | owner | same as G01 |
| A11Y-AUDIT-G08 | History, Home, Insights, Settings: contrast 3, dynamicType 12 | 15 | `dp_health_sample_count`: 1 pt clear test-only overlay (`UITestSeed.isActive`), probably an audit artifact of the test hook | open: recorded, not fixed | owner | confirm it is not user-visible when the fix brief is written; owner D-09 brief decides whether it needs any change |
| A11Y-AUDIT-G09 | History, Settings: contrast 6, textClipped 2 | 8 | Element with neither identifier nor label (`element=none`), not identified from the record | open: recorded, not fixed | owner | locate the element first; then same as G01 |

Total: 111 + 4 + 49 + 65 + 35 + 14 + 10 + 15 + 8 = 311 byte-wise distinct keys. Fix tracking: `.planning/todos/pending/2026-11-14-fix-accessibility-audit-findings.md`.

## Phase 11 observations (filled by plans 11-04, 11-05, 11-07)

| ID | Observation | Source | Status | Owner | Next step |
|----|-------------|--------|--------|-------|-----------|
| DL-O01 | Exploratory accessibility audit run found 385 reports, 311 byte-wise distinct keys (exploratory record, corrected) across 6 screens (nine of the 16 rows are unreliable; refreshed in plan 11-13) in 16 methods; recorded as open, not allow-listed and not fixed (D11-22). | plan 11-03; `11-EVIDENCE.md` section "Accessibility audit (exploratory run, D11-22)" | recorded | owner | grouped rows A11Y-AUDIT-G01 to G09; owner D-09 brief per fix |
| DL-O02 | The full run of plan 11-05 (2026-11-15, 834 tests, 0 failed, 18 skipped by gate) passed all four known-list tests (DL-T01 to DL-T04) and the watched DL-T07; the two History edit tests failed in scoped row G3 of plan 11-04 with the same code, so the outcome depends on how they are run. Observation only: nothing is closed, the cause is not established. | plan 11-05; `11-EVIDENCE.md` section "Full suite (VER-01)", Failure mapping | observed; rows DL-T01 to DL-T04 stay open | owner | owner decides whether to re-test the known list in isolation; todos and open-questions entries untouched |
| DL-O03 | Secondary destination smoke (plan 11-10, 2026-11-15, iPhone 18 Pro Max, iOS 27.2, runtime build 24B8117): `AccessibilityAuditUITests` 16 skipped by gate (D11-22), 0 failed; core-flow classes (onboarding, shell navigation, add drink, dashboard, settings) 23 of 23 passed. Larger-screen audit findings are not assessed in Phase 11. | plan 11-10; `11-EVIDENCE.md` rows S1 and S2, section Accessibility (VER-03) | observed; no new debt | owner | audit rerun on the secondary destination belongs to todo `2026-11-14-fix-accessibility-audit-findings` |
| DL-O04 | CHK-00 open: VoiceOver switches on but the rotor cannot be opened on the simulator, so Audio Graph is not reachable; not verifiable on simulator, requires device. | plan 11-07; owner session 2026-11-16, iOS 27.2 simulator; `11-A11Y-CHECKLIST.md` | open | owner | device check deferred per 11-CONTEXT |
| DL-O05 | CHK-01 open (AlcoholAreaChart Audio Graph, 05-UAT test 5): reason CHK-00. | plan 11-07; owner session 2026-11-16, iOS 27.2 simulator | open | owner | device check deferred per 11-CONTEXT |
| DL-O06 | CHK-02 open (WeekdayBarChart Audio Graph, 05-UAT test 6): reason CHK-00. | plan 11-07; owner session 2026-11-16, iOS 27.2 simulator | open | owner | device check deferred per 11-CONTEXT |
| DL-O07 | CHK-04 open: the arc refreshes while the Add Drink sheet still covers it, so the owner could not judge whether it animates, with Reduce Motion on or off. | plan 11-07; owner session 2026-11-16, iOS 27.2 simulator | open | owner | rerun on a device, or find a flow where the arc is visible when it changes; owner decides |
| DL-O08 | CHK-05 fail: the Home overview card progress bar always animates, with Reduce Motion on and off. | plan 11-07; owner session 2026-11-16, iOS 27.2 simulator | failed | owner | owner D-09 brief `11-DECISION-C014.md`, decision pending; no fix in Phase 11 |
| DL-O09 | CHK-06 fail: the History calendar detail area always animates when a day changes, with Reduce Motion on and off. | plan 11-07; owner session 2026-11-16, iOS 27.2 simulator | failed | owner | owner D-09 brief `11-DECISION-C015.md`, decision pending; no fix in Phase 11 |
| DL-O10 | CHK-07 fail: truncated, clipped or overlapping text at AX5 on Home, Insights, Add Drink, Settings Preferences and Onboarding; the guideline picker and History are fine. Similar in location to audit groups A11Y-AUDIT-G01, G03, G04 and G07; the audit groups are not confirmed by this human observation. | plan 11-07; owner session 2026-11-16, iOS 27.2 simulator | failed | owner | owner D-09 brief `11-DECISION-C016.md`, decision pending; related todo `2026-11-14-fix-accessibility-audit-findings`; no fix in Phase 11 |
| DL-O11 | CHK-10 open: VoiceOver actions on a History row not checked, reason CHK-00. | plan 11-07; owner session 2026-11-16, iOS 27.2 simulator | open | owner | device check deferred per 11-CONTEXT |
| DL-O12 | OBS-A: with VoiceOver on, focusing an Insights chart point reads a very large number instead of date and value. Cause is an unverified hypothesis (a raw date spoken as the value); related to audit group A11Y-AUDIT-G05 in kind and location only. CHK-01 stays open and is not marked fail. | plan 11-07; owner session 2026-11-16, iOS 27.2 simulator | open | owner | owner D-09 brief `11-DECISION-OBS-A.md`, decision pending; device check first; no fix in Phase 11 |
| DL-O13 | OBS-B: VoiceOver speaks some elements in English and some in Polish. Probable cause: the app is English-only and the simulator system language is Polish. | plan 11-07; owner session 2026-11-16, iOS 27.2 simulator | observed | owner | observation, not a defect; no brief unless the owner decides otherwise |
| DL-O14 | OBS-C: the Settings tab shows an endless progress indicator when the store has no profile (an on-disk store of unknown origin, launched without arguments). Whether a real user can reach this state is not established. | plan 11-07; owner session 2026-11-16, iOS 27.2 simulator | open | owner | owner D-09 brief `11-DECISION-OBS-C.md`, decision pending; related open question WR-04 on store recovery; no fix in Phase 11 |
| DL-O15 | CHK-03 passed with a caveat: no callout animation was visible with Reduce Motion on or off, so the gate is not shown by a before and after difference. Recorded as an observation, the pass stands as the owner's word. | plan 11-07; owner session 2026-11-16, iOS 27.2 simulator | observed | owner | owner decides whether a device recheck is wanted |
| DL-O16 | Session evidence integrity: accessibility settings were switched with the Xcode 27 Device Hub app and not the simulator Settings app; Simulator.app is not present in Xcode 27.2; part of the early CHK-07 walk ran from an icon launch without the seeded arguments; the owner shut the clone down once and it was rebooted and reset. Layout and Reduce Motion observations do not depend on the dataset. | plan 11-07; owner session 2026-11-16, iOS 27.2 simulator | observed | owner | none; recorded so the VER-03 results are read with these conditions |
