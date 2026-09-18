---
gsd_state_version: "1.0"
milestone: v1.4
current_phase: 09
current_phase_name: SwiftUI & Design System Modernization
status: planning
stopped_at: Phase 08 complete, ready to plan Phase 09
last_updated: "2026-09-18T08:00:28.735Z"
last_activity: 2026-09-18
last_activity_desc: Phase 08 complete, transitioned to Phase 09
state_head: d789b2a87d6fbc84a1ba6fd245d68d5b655bcd09
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 2
  completed_plans: 0
milestone_name: iOS 27 Migration & Modernization
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-18)

**Core value:** Every logged drink and every guideline comparison stays accurate and private — on-device by default, with no account ever required.
**Current focus:** Phase 09 — SwiftUI & Design System Modernization

## Current Position

Phase: 09 — SwiftUI & Design System Modernization
Plan: Not started
Status: Ready to plan
Last activity: 2026-09-18 — Phase 08 complete, transitioned to Phase 09

## Performance Metrics

**Velocity:**

- Total plans completed: 26 (GSD-tracked; 36 pre-GSD plans exist under docs/plans/)
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
- [Phase 08]: C001–C012 zatwierdzone wyłącznie w ograniczonym zakresie z 08-DECISION-REGISTER.md; modernizacja nie rozpoczęła się w Phase 08.
- [Phase 08]: C008/C009 zachowują model danych i format backupu bez celu biznesowego; C010–C012 wymagają diagnostyki przed punktową poprawką współbieżności.

### Pending Todos

- [2026-07-31] [tooling] Add branch-per-milestone workflow to GSD config — [todo file](.planning/todos/pending/2026-07-31-add-branch-per-milestone-workflow-to-gsd-config.md) — Needs TBD. Likely touches:.
- [2026-08-01] [general] Defer UNUserNotificationCenter.current() out of RootShellView cold-launch path — [todo file](.planning/todos/pending/2026-08-01-defer-unusernotificationcenter-current-out-of-rootshellview-cold-launch.md)
- [2026-08-27] [general] Add practical History list filtering — [todo file](.planning/todos/pending/2026-08-27-add-practical-history-list-filtering.md) — Needs Prefer native SwiftUI controls: `.searchable` for case- and.
- [2026-08-27] [general] Scope name autocomplete by drink category and ABV — [todo file](.planning/todos/pending/2026-08-27-scope-name-autocomplete-by-drink-category-and-abv.md)
- [2026-09-15] [general] Clarify weekly alcohol summary comparison — [todo file](.planning/todos/pending/2026-09-15-clarify-weekly-alcohol-summary-comparison.md)
- [2026-09-15] [general] Migrate project to iOS 27 and modernize codebase — [todo file](.planning/todos/pending/2026-09-15-migrate-project-to-ios-27-and-modernize-codebase.md) — Needs Plan and implement a full migration:.

### Blockers/Concerns

- CloudKit sync Phase B is blocked externally: needs a provisioned iCloud container (paid Apple Developer account) plus an explicit one-way approval before enabling
- BAC estimate implementation is gated on explicit owner design approval (formula documented in docs/domain.md, not yet built)
- Open product decisions not yet resolved: multi-currency spend aggregation on the Dashboard; guideline-alert-card tap action (see `.claude/context/open-questions.md`)
- Accessibility audit (VoiceOver, Dynamic Type up to AX5) is still outstanding — not yet started
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

Last session: 2026-09-18T08:00:28.735Z
Stopped at: Phase 08 complete, ready to plan Phase 09
Resume file: None

## Operator Next Steps

- A3-1 (`#Index` on `consumptionDate`) needs its own future phase — `SchemaV5` + `MigrationStage`, deferred by D-04
- Discuss Phase 08 with /gsd-discuss-phase 08
