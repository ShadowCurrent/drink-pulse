# Phase 11 Discovery Reconciliation

Date: 2026-11-14. Plan: 11-02. Roadmap success criterion 5 ("all substantial modernization discoveries received a recorded analysis and discussion outcome"). CONTEXT decisions: D11-09, D11-11, D11-18.

Method: every row cites one file and one short verbatim string from it. The string was machine-checked against the file with an exact-match lookup when this record was written. The outcome is quoted from the cited record; none is invented. A row whose analysis or outcome record does not exist is flagged GAP. A row whose outcome is recorded but whose later verification or deferral is still open is flagged OPEN and names the item; OPEN is not a missing record.

## ID namespace note

The Phase 08 inventory uses candidate IDs C001-C021 and the Phase 08 decision register uses C001 to C013. The two ranges differ: for example inventory C004 is decision brief C002. CONTEXT's "C001 to C013" means the register IDs, and the rows below use register IDs. The collision is recorded here and is not fixed (ledger row DL-C03). The brief files carry a frozen header that reads owner-approved eligibility recorded with modernization not started; that is a Phase 08 record state. The outcomes live in the Phase 09 and Phase 10 records cited below.

## Register decisions and Phase 10 decisions

| ID | Subject | Recorded analysis | Recorded outcome | Gap flag | Evidence file | Evidence string |
|----|---------|-------------------|------------------|----------|---------------|-----------------|
| C001 | Add Drink dismissal warning | Brief 08-DECISION-C001.md; Phase 09 evidence 09-ADD-DRINK-EVIDENCE.md | Change, done by plan 09-02 | none | `.planning/phases/09-swiftui-design-system-modernization/09-RETAIN-EVIDENCE.md` | `Completed by Plan 09-02: approved Add Drink dismissal ownership repair.` |
| C002 | History list and calendar audit | Brief 08-DECISION-C002.md; 09-RETAIN-EVIDENCE.md section UI-C-04 / UI-C-05 | Retain | none | `.planning/phases/09-swiftui-design-system-modernization/09-RETAIN-EVIDENCE.md` | `Native History List and separate calendar branch remain covered by focused iOS 27 interactions` |
| C003 | History context menu | Brief 08-DECISION-C003.md; 09-RETAIN-EVIDENCE.md section UI-C-04 / UI-C-05 | Retain | none | `.planning/phases/09-swiftui-design-system-modernization/09-RETAIN-EVIDENCE.md` | `Context-menu target, duplicate, destructive confirmation, and accessibility actions remain protected by focused tests` |
| C004 | Charts interaction and accessibility | Brief 08-DECISION-C004.md; 09-RETAIN-EVIDENCE.md section UI-C-06 / UI-C-08, "pass for automated scope" | Retain | OPEN: human Audio Graph check open until VER-03 (CHK-01, CHK-02) | `.planning/phases/09-swiftui-design-system-modernization/09-RETAIN-EVIDENCE.md` | `Swift Charts selection, selected-value callout, labels, and descriptor attachments remain source-audited and covered by focused tests` |
| C005 | Reduce Motion | Brief 08-DECISION-C005.md; 09-RETAIN-EVIDENCE.md index row UI-C-08 | Retain, with runtime verification required before any change | OPEN: open until VER-03 (CHK-03 to CHK-06) | `.planning/phases/09-swiftui-design-system-modernization/09-RETAIN-EVIDENCE.md` | `requires human runtime verification before any change` |
| C006 | Liquid Glass | Brief 08-DECISION-C006.md; 09-FLASH-DIAGNOSIS.md owner acceptance statement | Retain (UI-C-09) plus the C013 follow-up | OPEN: D1 deferred, not fixed (DL-D01, DL-D02) | `.planning/phases/09-swiftui-design-system-modernization/09-FLASH-DIAGNOSIS.md` | `Decision C006 acceptance statement` |
| C007 | VoiceOver dismissal UI test | Brief 08-DECISION-C007.md; completed by plan 09-02 and rewritten by plan 09-05 (ShellNavigationUITests) | Change, done | none | `.planning/phases/09-swiftui-design-system-modernization/09-RETAIN-EVIDENCE.md` | `Completed by Plan 09-02: approved focused VoiceOver UI regression coverage.` |
| C008 | Schema and migration boundary | Brief 08-DECISION-C008.md; 10-EVIDENCE.md section C008 disposition | Retain | none | `.planning/phases/10-data-platform-integration-modernization/10-EVIDENCE.md` | `Disposition: retain.` |
| C009 | Backup export and import | Brief 08-DECISION-C009.md; 10-EVIDENCE.md section C009 disposition | Retain (importer and format unchanged) | none | `.planning/phases/10-data-platform-integration-modernization/10-EVIDENCE.md` | `Disposition: retain (importer and format unchanged).` |
| C010 | Notification concurrency | Brief 08-DECISION-C010.md; 10-CONCURRENCY-RECORD.md section C010; owner decision F3 | Applied narrow fix | none | `.planning/phases/10-data-platform-integration-modernization/10-CONCURRENCY-RECORD.md` | `Disposition: applied narrow fix.` |
| C011 | HealthKit concurrency | Brief 08-DECISION-C011.md; 10-CONCURRENCY-RECORD.md section C011; owner decision F2 | Applied narrow fix | none | `.planning/phases/10-data-platform-integration-modernization/10-CONCURRENCY-RECORD.md` | `Disposition: applied narrow fix.` |
| C012 | Async cleanup and cancellation | Brief 08-DECISION-C012.md; 10-CONCURRENCY-RECORD.md section C012 | Retain | none | `.planning/phases/10-data-platform-integration-modernization/10-CONCURRENCY-RECORD.md` | `Disposition: retain.` |
| C013 | Dashboard GlassEffectContainer | Brief 08-DECISION-C013.md (surfaced after C001 to C012); 09-RETAIN-EVIDENCE.md follow-up; 09-FLASH-DIAGNOSIS.md | Owner approved revert-container-only on 2026-11-13 | OPEN: fixes neither D1 symptom | `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-REGISTER.md` | `revert-container-only` |
| F2 | Health edit-then-delete orphan sample | 10-DECISION-F2.md | Owner outcome fix-query-first, applied by plan 10-08 | none | `.planning/phases/10-data-platform-integration-modernization/10-DECISION-F2.md` | `fix-query-first` |
| F3 | Cancel-in-flight stale notification request | 10-DECISION-F3.md | Owner outcome fix-service-epoch+handler-sendable, applied by plan 10-09 | none | `.planning/phases/10-data-platform-integration-modernization/10-DECISION-F3.md` | `fix-service-epoch+handler-sendable` |
| F4 | Weekly summary copy | 10-DECISION-F4.md | Owner outcome as-of-last-visit, applied by plan 10-10 | none | `.planning/phases/10-data-platform-integration-modernization/10-DECISION-F4.md` | `as-of-last-visit` |
| Device finding | Cold-launch notification tap | 10-DECISION-DEVICE-FINDING.md; re-test in 10-DEVICE-RETEST.md | Owner outcome sync-assign (re-test passed 3 of 3 killed-app taps) | OPEN: the weekly cold tap was not observed (DL-Q04) | `.planning/phases/10-data-platform-integration-modernization/10-DECISION-DEVICE-FINDING.md` | `sync-assign` |

## Discoveries without a register brief

| ID | Subject | Recorded analysis | Recorded outcome | Gap flag | Evidence file | Evidence string |
|----|---------|-------------------|------------------|----------|---------------|-----------------|
| D1 | Dashboard flicker and simulator crash | 09-FLASH-DIAGNOSIS.md (classification C-INCONCLUSIVE); todo `2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md` | Owner deferral 2026-11-13; flicker not fixed and not confirmed gone | OPEN: deferred, not fixed (DL-D01 to DL-D08) | `.planning/phases/09-swiftui-design-system-modernization/09-FLASH-DIAGNOSIS.md` | `Owner outcome: deferred, flicker not confirmed gone` |
| UI-C-02 | DPArcProgress compile error | Inventory candidate in 09-RETAIN-EVIDENCE.md index; no decision brief by design | Change, done by plan 09-01 | none | `.planning/phases/09-swiftui-design-system-modernization/09-RETAIN-EVIDENCE.md` | `Completed by Plan 09-01: targeted` |
| UI-C-03 and UI-C-07 | Stable ForEach identity and Observation owners | 09-RETAIN-EVIDENCE.md index rows and sections UI-C-03 and UI-C-07; no decision brief by design | Retain | none | `.planning/phases/09-swiftui-design-system-modernization/09-RETAIN-EVIDENCE.md` | `identities pass the focused source audit and selected iOS 27 UI suite` |
| WR-04 | Store recovery fires on any ModelContainer open error | open-questions entry; Phase 10 code review WR-01 | Deferred; owner accepted the deferral in 10-UAT.md test 4; product decision still pending (DL-Q02, DL-R04) | OPEN: product decision pending | `.claude/context/open-questions.md` | `Store recovery fires on any ModelContainer open error` |
| R1-WR-01, WR-02, WR-03 | Health update path and weekly summary scheduling behavior changes | 10-REVIEW-DISPOSITION.md rows; 10-UAT.md tests 1 and 2 (both pass) | Owner accepted in UAT round 2 | none | `.planning/STATE.md` | `behavior changes owner-accepted in UAT round 2` |
| Privacy manifest and build date | Production build date and privacy manifest | open-questions entry (no PrivacyInfo.xcprivacy found; UserDefaults and AppStorage in use) | Listed in the debt ledger as DL-M01, not resolved in Phase 11; no owner decision recorded | OPEN: owner decision pending (DL-M01) | `.claude/context/open-questions.md` | `Production build date and privacy manifest` |

## Phase 05 skipped checks

Three checks were skipped in the archived Phase 05 UAT (the user stopped the checklist to fix a callout bug). D11-09 folds them into the VER-03 human checklist.

| 05-UAT test | Expectation | Checklist item | Outcome | Evidence file | Evidence string |
|-------------|-------------|----------------|---------|---------------|-----------------|
| 05-UAT test 4 | Reduce Motion suppresses both charts' callout transition and selection animation together (CHART-04) | CHK-03 | CHK-03 pass (owner, iOS 27.2 simulator, 2026-11-16): with Reduce Motion on the callout jumps without animation; caveat: no callout animation was visible with Reduce Motion off either | `.planning/milestones/v1.3-phases/05-insights-chart-scrubbing/05-UAT.md` | `Reduce Motion gates both charts' scrub animation` |
| 05-UAT test 5 | AlcoholAreaChart Audio Graph surfaces every data point's date and value (CHART-03) | CHK-01 | CHK-01 open (owner, 2026-11-16): reason CHK-00, the rotor Audio Graph action is not reachable on the simulator; requires device | `.planning/milestones/v1.3-phases/05-insights-chart-scrubbing/05-UAT.md` | `AlcoholAreaChart VoiceOver Audio Graph` |
| 05-UAT test 6 | WeekdayBarChart Audio Graph surfaces every data point's weekday and value (CHART-03) | CHK-02 | CHK-02 open (owner, 2026-11-16): reason CHK-00, the rotor Audio Graph action is not reachable on the simulator; requires device | `.planning/milestones/v1.3-phases/05-insights-chart-scrubbing/05-UAT.md` | `WeekdayBarChart VoiceOver Audio Graph` |

Note: 05-UAT test 9 (callout date format is period-aware) passed on automated evidence only and was never human-confirmed on a device. The test file says so itself. Recorded, not changed.

## Phase 11 new findings

| ID | Finding | Source | Disposition | Owner |
|----|---------|--------|-------------|-------|
| C014 | The Home overview card progress bar always animates, with Reduce Motion on and off (CHK-05 fail) | owner checklist, plan 11-07; `11-DECISION-C014.md` | open: owner D-09 brief written, decision pending, no fix in Phase 11; ledger DL-O08 | owner |
| C015 | The History calendar detail area always animates when a day changes, with Reduce Motion on and off (CHK-06 fail) | owner checklist, plan 11-07; `11-DECISION-C015.md` | open: owner D-09 brief written, decision pending, no fix in Phase 11; ledger DL-O09 | owner |
| C016 | Text is truncated, clipped or overlapping at AX5 on Home, Insights, Add Drink, Settings Preferences and Onboarding (CHK-07 fail); similar in location to audit groups G01, G03, G04 and G07, not a confirmation of them | owner checklist, plan 11-07; `11-DECISION-C016.md` | open: owner D-09 brief written, decision pending, no fix in Phase 11; ledger DL-O10 | owner |
| OBS-A | With VoiceOver on, focusing an Insights chart point reads a very large number instead of date and value; cause is an unverified hypothesis (raw date spoken); not a CHK-01 fail, which stays open per CHK-00 | owner observation, plan 11-07; `11-DECISION-OBS-A.md` | open: owner D-09 brief written, decision pending, no fix in Phase 11; ledger DL-O12 | owner |
| OBS-B | VoiceOver speaks some elements in English and some in Polish; probable cause is an English-only app on a Polish simulator | owner observation, plan 11-07 | observation, not a defect; no brief; ledger DL-O13 | owner |
| OBS-C | Settings tab shows an endless progress indicator when the store has no profile (edge case from an on-disk store of unknown origin) | owner observation, plan 11-07; `11-DECISION-OBS-C.md` | open: owner D-09 brief written, decision pending, no fix in Phase 11; ledger DL-O14 | owner |

Each confirmed defect has an owner D-09 brief and stays open. Phase 11 makes no fix. The brief files for OBS-A and OBS-C carry OBS names and not C numbers because the plan's gate counts `11-DECISION-C0*.md` files against the number of `fail` results. Filled by plan 11-07.

## Summary

Rows verified against their cited file: 26; rows flagged GAP: 0.

Rows flagged OPEN (outcome recorded, later verification or decision still pending): 8 (C004, C005, C006, C013, Device finding, D1, WR-04, Privacy manifest and build date). The three Phase 05 rows carry the plan 11-07 outcomes (CHK-03 pass, CHK-01 open, CHK-02 open) and are counted in the 26. CHK-01 and CHK-02 are open, not passed, so the C004 row stays OPEN; CHK-03 passed and C005 stays OPEN because CHK-04 is open and CHK-05 and CHK-06 failed. Phase 11 new findings: 6 rows (C014, C015, C016, OBS-A, OBS-B, OBS-C), 5 with owner briefs and decision pending.
