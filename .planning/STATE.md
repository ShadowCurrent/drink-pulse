---
gsd_state_version: "1.0"
milestone: v1.4
current_phase: 11
current_phase_name: iOS 27 Release Verification
status: executing
stopped_at: Completed 11-19-PLAN.md
last_updated: "2026-11-17T15:47:14.832Z"
last_activity: 2026-11-14
last_activity_desc: Phase 11 execution started
state_head: def977dd02d41eaa6e636212aa0da2b21340900b
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 24
  completed_plans: 3
milestone_name: iOS 27 Migration & Modernization
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-11-10)

**Core value:** Every logged drink and every guideline comparison stays accurate and private — on-device by default, with no account ever required.
**Current focus:** Phase 11 — iOS 27 Release Verification

## Current Position

Phase: 11 (iOS 27 Release Verification) — READY TO EXECUTE
Plan: 10 of 10
Status: Ready to execute
Last activity: 2026-11-14 — Phase 11 execution started

## Performance Metrics

**Velocity:**

- Total plans completed: 40 (GSD-tracked; 36 pre-GSD plans exist under docs/plans/)
- Average duration: N/A
- Total execution time: N/A

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 5 | - | - |
| 01.1 | 1 | - | - |
| 02 | 2 | - | - |
| 03 | 2 | - | - |
| 04 | TBD | - | - |
| 05 | 2 | - | - |
| 06 | 1 | - | - |
| 07 | 5 | - | - |
| 08 | 8 | - | - |
| 10 | 14 | - | - |

**Recent Trend:**

- Last 5 plans: N/A (no GSD-tracked plans yet this milestone)
- Trend: N/A

*Updated after each plan completion*
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 08-ios-27-baseline-api-inventory P05 | 8min | 2 tasks | 15 files |
| Phase 08-ios-27-baseline-api-inventory P06 | 7min | 2 tasks | 15 files |
| Phase 08 P07 | 6 min | 2 tasks | 2 files |
| Phase 08 P08 | 4 min | 2 tasks | 1 files |
| Phase 09 P04 | 7 min | 2 tasks | 4 files |
| Phase 09 P05 | 12 min | 2 tasks | 4 files |
| Phase 09 P06 | 90min | 0 tasks | 3 files |
| Phase 09 P07 | 20min | 2 tasks | 3 files |
| Phase 09 P08 | 45min | 1 tasks | 5 files |
| Phase 09 P08 | 75min | 2 tasks | 9 files |
| Phase 09 P09 | 40 min | 2 tasks | 10 files |
| Phase 09 P10 | 20min | 2 tasks | 10 files |
| Phase 11 P01 | 90min | 3 tasks | 2 files |
| Phase 11 P02 | 9min | 2 tasks | 2 files |
| Phase 11 P11-11 | 12min | 1 tasks | 2 files |
| Phase 11 P12 | 30 min | 3 tasks | 14 files |
| Phase 11 P13 | multi-session | 4 tasks | 2 files |
| Phase 11 P14 | multi-session | 4 tasks | 12 files |
| Phase 11 P15 | 12 min | 2 tasks | 5 files |
| Phase 11 P16 | 2 sessions (2026-11-16 to 2026-11-17) | 6 tasks | 45 files |
| Phase 11 P17 | 80min | 2 tasks | 15 files |
| Phase 11 P18 | 60 min | 2 tasks | 6 files |
| Phase 11 P19 | about 4h10m (incl. rate-limit pause and owner checkpoint) | 2 tasks | 10 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table (12 ADRs; 10
locked, 2 superseded/historical — ADR-0003, ADR-0005).

Recent decisions affecting future work:

- v1.3 phase order follows research's risk-discovery-cost sequencing:
  Phase 4 (launch screen, smallest/lowest-risk) → Phase 5 (chart
  scrubbing, medium scope, new `accessibilityChartDescriptor` work) →
  Phase 6 (History transition, smallest diff but highest discovery risk
  from the List/ScrollView container mismatch)

- CloudKit sync: Phase A (CloudKit-ready schema, ADR-0010) shipped; Phase B (enabling CloudKit) stays OFF, blocked on a provisioned iCloud container + explicit one-way owner approval
- BAC estimate explicitly requires owner design approval before any implementation (never build without it)
- ADR-0012: onboarding gate has exactly one authoritative source of truth (`onboardingDone`) — no second live query/count may influence it, even as a "safety net" (v1.2, Phase 3)
- Phase 07 D-01/D-02: History `ForEach` identity moved to `ConsumptionEvent.uuid`; context-menu Delete gated by a confirmation dialog (not undo)
- Phase 07 D-04: A3-1 (`#Index` on `consumptionDate`) deferred to its own future phase — needs `SchemaV5` + `MigrationStage`, out of scope for a UI/gesture-audit phase
- [Phase 08]: Plan 08-05 reconciles 254 tracked paths and keeps twelve substantial modernization outcomes pending for Wave 4.
- [Phase 08]: C001–C012 were approved only within the scoped decisions in `08-DECISION-REGISTER.md`; modernization did not start in Phase 08.
- [Phase 08]: C008/C009 preserve the data model and backup format without a business-goal change; C010–C012 require diagnostics before any targeted concurrency correction.
- [Phase 10]: Health update path (R1-WR-01) and weekly-summary scheduling (WR-02/WR-03) behavior changes owner-accepted in UAT round 2; WR-04 store-recovery trigger deferred.
- [Phase 09]: 09-04: GuidelineLimits.effectiveDailyGrams declared in the type-level nonisolated struct body (not a member-level annotation in an extension); owner ratification O1 recorded in 09-RETAIN-EVIDENCE.md, AGENTS.md unedited
- [Phase 09]: 09-05: VoiceOver regression activates Cancel via XCUIElement doubleTap while service stays enabled (XCUIVoiceOverService has no activation method); skip on failedToStart; disable only pre-launch and in teardown
- [Phase 09]: 09-06: Owner decision C (no device session, 2026-11-13) accepts the reproducible simulator glassEffect resolution crash as the C006 measured defect; plan 09-07 re-planned on simulator evidence; CH6 and flicker-crash link stay open
- [Phase 09]: 09-07: C013 owner decision revert-container-only (2026-11-13); acknowledges no automated flash regression (Route D); restores DashboardView.swift pre-553ea58 only; MOD-02, device session, Feedback stay open
- [Phase 09]: 09-07: flicker classified C-INCONCLUSIVE, Data dependence not shown, no cure proposed
- [Phase 09]: 09-08: C013 revert-container-only applied (DashboardView.swift restored to pre-553ea58); scoped UI gate blocked by 2 pre-existing History edit-test failures and 2 crashing SheetDismissTabSwitchUITests tests; owner decision needed; MOD-02 stays open
- [Phase 09]: 09-08: Owner deferred D1 (simulator crash and device flicker) out of Phase 09 to the backlog todo; two crashing SheetDismissTabSwitchUITests tests skipped in the scheme; two History edit tests waived by name; plan closes complete with deferral, MOD-02 left for 09-10
- [Phase 09]: 09-09: followed owner deferral (D1 carried by pending todo, 09-10 closes with D1 deferred); diag cleanup limited to worktrees v1, v3, v4, with work, minimal-repro and all diag/* branches kept
- [Phase 09]: 09-10: Phase 09 closed with D1 deferred (owner deferral replaced on-device confirmation); MOD-02 complete with D1 exception; flicker not claimed gone; UAT test 7 skipped; D1 todo stays pending
- [Phase 11]: 11-01: Release verified on iphoneos 27.2 SDK only (D11-20); iPad interface-orientation validation warning recorded as open app-owned finding, not fixed in verification-only phase
- [Phase 11]: DL-W12 (MOD-04 Release warning) listed in the debt ledger; ledger lists, closes nothing
- [Phase 11]: Discovery gap flags split: GAP (no record) vs OPEN (outcome recorded, verification pending); 0 GAP, 8 OPEN
- [Phase 11]: 11-11: D11-21 applied; PortraitUpsideDown added to iPad orientations; second Release device build has no orientation warning; MOD-04 app-owned warnings 0
- [Phase 11]: 11-12: exploratory audit record superseded (not deleted); 311 stays the byte-wise distinct key count, 254 is a sort -u locale artifact; 9 rows unreliable
- [Phase 11]: 11-13: D11-26 mechanism realized via Run-action environment variable inherited by Test; baseline 385 reports / 311 byte-wise distinct keys (LC_ALL=C sort -u), all keys in G01-G09, no G10; fix plans fix every baseline finding on their screen
- [Phase 11]: 11-14: Reduce Motion gated at three sites through DPMotion seam; CHK-04/05/06 re-run pass, CHK-03 re-run open (no discriminating difference); OBS-D arc shows no visible animation with Reduce Motion off (open, not fixed)
- [Phase 11]: 11-15: audit group G08 fixed on the test hook (dp_health_sample_count is a one point Color.clear element, label = count), never by muting the audit
- [Phase 11]: 11-15: assertNoAuditIssuesOnProbes is the single identifier-scoped audit helper; callers pass .all and the unfiltered per-screen classes stay the gate
- [Phase 11]: D11-28 (plan 11-16, owner 2026-11-16): narrow documented exception for AX5 dynamicType and textClipped audit findings on system-owned Form controls on Add Drink step 2 (keys Volume, Strength, Amount, none#type=nil) via an explicit exemptElementKeys set; every other finding still fails; owner CHK-07 eye check found placeholder truncation inside this scope (DL-O19)
- [Phase 11]: D11-29 (owner, 2026-11-17): amendment of D11-25: accessibility audits do not evaluate app content occluded by the system tab bar (explicit per-call opt-in; only contrast and textClipped issues whose element frame intersects the real tab bar are ignored; each ignored issue logged as a warning and counted); the launch viewport otherwise stays the rule
- [Phase 11]: 11-18: Add Drink drink-type emoji drawn as a decorative image (ImageRenderer + Image(decorative:)) and each tile combined into one accessibility element; toolbar Cancel uses Button(role: .cancel) (system close glyph). Executor decision, flagged for owner review; no D11 id used (next free remains D11-30).
- [Phase 11]: D11-30 (owner, option A at the 11-19 hit-region checkpoint): labelled per-day Insights chart marks stay accessible; the Insights audit class exempts only hitRegion issues on those marks, matched at audit time by label and frame, each logged as a warning and counted per variant; G05 hitRegion stays open with exemption; plan 11-23 uses D11-31 or later

### Pending Todos

- [2026-07-31] [tooling] Add branch-per-milestone workflow to GSD config — [todo file](.planning/todos/pending/2026-07-31-add-branch-per-milestone-workflow-to-gsd-config.md) — Needs TBD. Likely touches:.
- [2026-08-01] [general] Defer UNUserNotificationCenter.current() out of RootShellView cold-launch path — [todo file](.planning/todos/pending/2026-08-01-defer-unusernotificationcenter-current-out-of-rootshellview-cold-launch.md)
- [2026-08-27] [general] Add practical History list filtering — [todo file](.planning/todos/pending/2026-08-27-add-practical-history-list-filtering.md) — Needs Prefer native SwiftUI controls: `.searchable` for case- and.
- [2026-08-27] [general] Scope name autocomplete by drink category and ABV — [todo file](.planning/todos/pending/2026-08-27-scope-name-autocomplete-by-drink-category-and-abv.md)
- [2026-09-15] [general] Clarify weekly alcohol summary comparison — [todo file](.planning/todos/pending/2026-09-15-clarify-weekly-alcohol-summary-comparison.md)
- [2026-09-15] [general] Migrate project to iOS 27 and modernize codebase — [todo file](.planning/todos/pending/2026-09-15-migrate-project-to-ios-27-and-modernize-codebase.md) — Needs Plan and implement a full migration:.
- [2026-09-18] [general] Diagnose Dashboard flash after sheet dismissal — [todo file](.planning/todos/pending/2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md) — DEFERRED 2026-11-13 (Phase 09 closed with this exception; flicker and simulator crash not fixed, not device-confirmed).

### Blockers/Concerns

- CloudKit sync Phase B is blocked externally: needs a provisioned iCloud container (paid Apple Developer account) plus an explicit one-way approval before enabling
- BAC estimate implementation is gated on explicit owner design approval (formula documented in docs/domain.md, not yet built)
- Open product decisions not yet resolved: multi-currency spend aggregation on the Dashboard; guideline-alert-card tap action (see `.claude/context/open-questions.md`)
- [Phase 11] Accessibility verification (VER-03) is not complete: owner checklist on the iOS 27.2 simulator 2026-11-16 has 3 fails (CHK-05, CHK-06 Reduce Motion; CHK-07 Dynamic Type at AX5), 5 open (CHK-00, CHK-01, CHK-02, CHK-04, CHK-10; VoiceOver rotor and both chart Audio Graphs need a device) and 3 passes; the automated audit is red with 385 reports, 311 byte-wise distinct keys (exploratory record, corrected) (not allow-listed, D11-22); five owner briefs pending (11-DECISION-C014, C015, C016, OBS-A, OBS-C); see phases/11-ios-27-release-verification/11-EVIDENCE.md
- [Phase 10] WR-04: store recovery fires on any `ModelContainer` open error — deferred; decide allowlist fix vs. accept (see `.claude/context/open-questions.md`)
- [Phase 10] Full UI suite not green: `InsightsUITests.test_heroCard_holdsHeight_...` fails (pre-existing since 2cb2649); single-run flakes in HistoryInteractionUITests and ExportUITests
- [Phase 11] Full-suite result (2026-11-15, iOS 27.2 simulator): 834 tests, 0 failed, 18 skipped by gate, 94.65 percent overall coverage (Domain 90.06 percent, below its 100 percent target). The two History edit tests failed in the scoped run only; the Insights hero card test and the Export dismiss test passed; the two D1 harness tests were skipped by their gate; no new flake observed.
- Launch icon (Phase 04): real-hardware size-invariance quirk unresolved after two content-verified opposite-direction size edits; owner accepted current 60pt state rather than continue chasing it (see PROJECT.md Current State tech debt)

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260718-kgp | Fix bug: Insights month view "Longest Streak" card counts future days (after today) in current month. Should only count elapsed days (up to and including today). | 2026-07-18 | 62394d5 | [260718-kgp-fix-bug-insights-month-view-longest-stre](./quick/260718-kgp-fix-bug-insights-month-view-longest-stre/) |
| 260718-vgy | Fix bug: Insights month/week view "drinkFreeDays" metric counts future days in its X/Y numerator/denominator — follow-up to 260718-kgp. Should only count elapsed days. | 2026-07-18 | 56587bd | [260718-vgy-fix-bug-insights-month-week-view-drinkfr](./quick/260718-vgy-fix-bug-insights-month-week-view-drinkfr/) |
| 260719-nm6 | Add autocomplete/suggestions to the "custom name" text field on the drink add/edit screen — tap-to-autocomplete from prior ConsumptionEvent.customName history. | 2026-07-19 | 034d916 | [260719-nm6-add-autocomplete-suggestions-to-the-cust](./quick/260719-nm6-add-autocomplete-suggestions-to-the-cust/) |
| 4 | Add mandatory doc-lookup rule to CLAUDE.md | 2026-07-31 | 2a143e2 | — |
| 5 | Scope default test runs to affected classes instead of full suite | 2026-07-31 | e7fccf3 | — |
| 260731-w4f | Add view-load-time logger for cold start and tab switches — `os.Logger`/`OSSignposter` dev-diagnostics, `#if DEBUG`-gated, no Release overhead. | 2026-07-31 | 26d0bf6 | [260731-w4f-add-view-load-time-logger-for-cold-start](./quick/260731-w4f-add-view-load-time-logger-for-cold-start/) |
| 260801-l5j | Defer UNUserNotificationCenter.current() out of RootShellView cold-launch path — `@autoclosure @escaping` init param + `private lazy var center` on ReminderService/WeeklySummaryService, deferring resolution to first actual scheduling use. | 2026-08-01 | 1b54cd9 | [260801-l5j-defer-unusernotificationcenter-current-o](./quick/260801-l5j-defer-unusernotificationcenter-current-o/) |
| 260802-uia | Shrink History list initial fetch window from 90 days to 7 days — `HistoryViewModel.listPageDays` 90 -> 7, complementing plan-0038's List->ScrollView+LazyVStack render-side fix with a fetch-side fix. | 2026-08-02 | 4a62018 | [260802-uia-shrink-history-list-initial-fetch-window](./quick/260802-uia-shrink-history-list-initial-fetch-window/) |
| 260817-ger | Fix bug: Monday weekly-summary notification compared the still-in-progress current week vs. last week instead of last week vs. the week before — `scheduleIfEnabled` offsets corrected -1/-2 (were 0/-1). | 2026-08-17 | 953c39f | [260817-ger-weekly-summary-notification-monday-misca](./quick/260817-ger-weekly-summary-notification-monday-misca/) |
| 261112-kvl | Wersja/build (+ Debug marker i data buildu w Debug) na dole Ustawień | 2026-11-12 | dd469d4 | [261112-kvl-dodaj-do-aplikacji-gdzie-na-dole-w-ustaw](./quick/261112-kvl-dodaj-do-aplikacji-gdzie-na-dole-w-ustaw/) |

### Roadmap Evolution

- Phase 01.1 inserted after Phase 1: Address tech debt: weekly summary notification (URGENT) — v1.1
- 2026-07-27 — v1.2 roadmap created: Phase 2 (Swift 6 Language Mode Migration) and Phase 3 (App Startup Hardening), continuing phase numbering from v1.1's 1/01.1. 6/6 v1.2 requirements mapped (SWIFT6-01/02/03 → Phase 2; STARTUP-01/02/03 → Phase 3).
- 2026-07-28 — v1.2 milestone closed and archived (6/6 requirements satisfied); phase numbering continues at Phase 4 for the next milestone.
- 2026-07-28 — v1.3 roadmap created: Phase 4 (Branded Static Launch Screen), Phase 5 (Insights Chart Scrubbing), Phase 6 (History List↔Calendar Directional Transition), continuing phase numbering from v1.2's Phase 3. 8/8 v1.3 requirements mapped (LAUNCH-01 → Phase 4; CHART-01..04 → Phase 5; HIST-01..03 → Phase 6). All three phases are independent (no shared files/state); order follows research's risk-discovery-cost sequencing rather than a dependency chain.
- 2026-07-31 — Phase 06 (History List↔Calendar Directional Transition) complete: 1/1 plan executed, UAT 3/3 passed (no issues), 06-SECURITY.md verified (0 open threats). v1.3 Native Feel is now 3/3 phases complete (100%) — ready for `/gsd-complete-milestone v1.3`.
- 2026-07-31 — v1.3 milestone close found Phase 04 had shipped (2026-07-30, ROADMAP already marked complete) without formal `04-UAT.md`/`04-SECURITY.md`/`04-VERIFICATION.md` artifacts, despite 19 real-device debug rounds of actual human verification. Reconstructed retroactively: ran `/gsd-verify-work 04` (2 tests, real-device light/dark cold-launch, both pass), `/gsd-secure-phase 04` (2 low-severity accepted threats, threats_open: 0), and a goal-backward `gsd-verifier` pass (7/7 must-haves, PASSED). No code changed — only the paper trail was missing.
- 2026-07-31 — v1.3 Native Feel milestone archived: `.planning/milestones/v1.3-ROADMAP.md`, `v1.3-REQUIREMENTS.md`, `v1.3-phases/`. ROADMAP.md collapsed to one-line summary. REQUIREMENTS.md removed (fresh for next milestone). PROJECT.md evolved (v1.3 moved to shipped `<details>`, codebase size refreshed to ~10,784 LOC, launch-icon doc discrepancy flagged). RETROSPECTIVE.md updated. Phase numbering continues at 7 for the next milestone.
- 2026-08-03 — Phase 7 added: SwiftUI List Performance & Gesture Audit — read-only research + plan cycle (Opus 5) covering every `List`-containing view and its feeding `@Query`/SwiftData models: identity/perf (stable IDs, dynamic subview count, predicate placement, row body cost, onAppear misuse, invalidation, extraction), section building, and gesture inventory/conflicts/accessibility. No code changes in this cycle — plan requires explicit approval before execution. Surfaced during this same session: `docs/plans/0038-history-list-lazy-scrollview/plan.md` (frozen, in-progress) still describes List→ScrollView+LazyVStack as the shipped direction, but two same-day debug sessions (`.planning/debug/resolved/history-scrollview-bugs.md`, `contextmenu-zoom-glitch.md`) reverted History's list back to `List` (commit `3093b02`) after finding the ScrollView+LazyVStack path caused an unfixable Liquid Glass context-menu rendering glitch — plan-0038's frozen plan.md is now stale against the shipped code and needs an execution.md deviation entry / retrospective reconciling the reversal before that plan can be marked complete.
- 2026-08-04 — Phase 7 complete: 5/5 plans executed across 3 waves (2 blockers, 14 worth-fixing, 11 nit findings from 07-RESEARCH.md closed in code). UAT 5/5 passed (VoiceOver Actions rotor, contrast audit, WR-01 section-cache fix confirmation, B9-3 Liquid Glass guideline cards, B10-1 loading-state first frame — B10-1 needed a second UAT pass after an initial "cannot test it now" skip). `07-SECURITY.md` closed 26/26 threats (0 open) — register built from all 5 plans' `<threat_model>` blocks, ASVS L1 grep-depth sufficient, no auditor sub-agent needed. A3-1 (`#Index` on `consumptionDate`) stays deferred per D-04, now tracked as an unplanned Active item in PROJECT.md.
- 2026-11-16 — Phase 11 (iOS 27 Release Verification) evidence closed by plan 11-08: MOD-04 complete, VER-01 complete with named exceptions, VER-02 complete with named limitations, VER-03 still Pending (checklist fails CHK-05, CHK-06, CHK-07; audit red under D11-22 with 385 reports, 311 byte-wise distinct keys (exploratory record, corrected); five owner briefs pending). Phase 11 status stays In progress until plan 11-09 and the owner decisions.

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-07-28:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| debug | sheet-closes-reopens-loses-state | closed 2026-07-27 — human-verified, session archived to `.planning/debug/resolved/` | v1.1 close, 2026-07-21 |
| todo | reserve-vsprev-row-height-in-insights-all-time | pending — Cluster B (native feel), not in v1.3 scope | v1.2 close, 2026-07-28 |
| todo | no-entrance-animation-on-first-render | pending — Cluster B (native feel), not in v1.3 scope | v1.2 close, 2026-07-28 |
| todo | audit-context-insert-call-sites-for-missing-save | pending — unclustered, not in v1.3 scope | v1.2 close, 2026-07-28 |
| todo | rename-app-display-name-to-drinkpulse | pending — unclustered, not in v1.3 scope | v1.2 close, 2026-07-28 |
| todo | slide-transition-between-history-list-and-calendar | pending — already implemented independently of GSD tracking (Phase 06 shipped it); todo file not yet closed | v1.3 close, 2026-07-31 |
| todo | branded-static-launch-screen | pending — already implemented independently of GSD tracking (Phase 04 shipped it); todo file not yet closed | v1.3 close, 2026-07-31 |
| todo | add-mandatory-doc-lookup-rule-to-claude-md-no-guessing | pending — not in v1.3 scope | v1.3 close, 2026-07-31 |
| todo | add-view-load-time-logger-for-cold-start-and-tab-switches | pending — not in v1.3 scope | v1.3 close, 2026-07-31 |
| todo | scope-test-runs-to-affected-classes-instead-of-full-suite | pending — not in v1.3 scope | v1.3 close, 2026-07-31 |

## Session Continuity

Last session: 2026-11-17T15:47:14.693Z
Stopped at: Completed 11-19-PLAN.md
Resume file: None

## Operator Next Steps

- A3-1 (`#Index` on `consumptionDate`) needs its own future phase — `SchemaV5` + `MigrationStage`, deferred by D-04
- Discuss Phase 11 with /gsd-discuss-phase 11
