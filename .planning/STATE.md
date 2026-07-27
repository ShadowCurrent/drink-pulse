---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Swift 6 + App-Target Hardening
current_phase: 3
current_phase_name: App Startup Hardening
status: planning
stopped_at: Phase 3 context gathered
last_updated: "2026-07-27T10:49:47.684Z"
last_activity: 2026-07-27
last_activity_desc: Phase 02 complete, transitioned to Phase 3
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 2
  completed_plans: 2
  percent: 50
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-27)

**Core value:** Every logged drink and every guideline comparison stays accurate and private — on-device by default, with no account ever required.
**Current focus:** Phase 02 — swift-6-language-mode-migration

## Current Position

Phase: 3 — App Startup Hardening
Plan: Not started
Status: Ready to plan
Last activity: 2026-07-27 — Phase 02 complete, transitioned to Phase 3

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**

- Total plans completed: 8 (GSD-tracked; 36 pre-GSD plans exist under docs/plans/)
- Average duration: N/A
- Total execution time: N/A

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 5 | - | - |
| 01.1 | 1 | - | - |
| 02 | 2 | - | - |
| 3 | TBD | - | - |

**Recent Trend:**

- Last 5 plans: N/A (no GSD-tracked plans yet this milestone)
- Trend: N/A

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table (11 ADRs; 9
locked, 2 superseded/historical — ADR-0003, ADR-0005).

Recent decisions affecting future work:

- v1.2 roadmap: Phase 2 (Swift 6 language-mode flip) must complete and be committed before Phase 3 (app startup hardening) starts — async model-container work and onboarding-gate rewiring are concurrency changes that should be reasoned about once, under real Swift 6 rules, not redone after the flip (`.planning/todos/CLUSTERS.md`)
- Two design decisions inside Phase 3 are deliberately deferred to discuss-phase/plan-phase, not resolved by the roadmap: (a) what replaces the two `fatalError` calls at `drinkpulseApp.swift:59,68`; (b) which source of truth wins for onboarding (persisted `onboardingDone` vs live `@Query profiles`)
- Phase 1 (Weekly Summary Notification) follows the existing `Services/` layer notification pattern (ADR-0008, `ReminderService`/`NotificationScheduling`/`NotificationActionHandler`) rather than inventing a new one
- CloudKit sync: Phase A (CloudKit-ready schema, ADR-0010) shipped; Phase B (enabling CloudKit) stays OFF, blocked on a provisioned iCloud container + explicit one-way owner approval
- BAC estimate explicitly requires owner design approval before any implementation (never build without it)

### Pending Todos

Cluster A todos are now covered by the v1.2 roadmap (Phase 2 / Phase 3) —
no longer "pending" in the general sense, but their source files remain
until each phase executes and closes them out.

- Migrate app target to Swift 6 language mode and purge deprecated patterns (major) → Phase 2 — `.planning/todos/pending/2026-07-26-migrate-app-target-to-swift-6-language-mode.md`
- Harden onboarding dual source of truth in RootShellView (major) → Phase 3 — `.planning/todos/pending/2026-07-27-harden-onboarding-dual-source-of-truth.md`
- Move model container creation off the synchronous init path and add a real error state (minor) → Phase 3 — `.planning/todos/pending/2026-07-27-async-model-container-startup-and-error-state.md`

**Cluster B — Native feel: motion, layout, chart interaction** (own future milestone; must not run during v1.2)

- Scrub Insights charts to reveal per-point values (minor) — `.planning/todos/pending/2026-07-26-scrub-insights-charts-for-per-point-values.md`
- Animate History list row insert and delete (cosmetic) — `.planning/todos/pending/2026-07-26-animate-history-list-row-insert-delete.md`
- Slide transition between History list and calendar segments (cosmetic) — `.planning/todos/pending/2026-07-26-slide-transition-between-history-list-and-calendar.md`
- Reserve vs-prev row height in Insights all-time hero card (cosmetic) — `.planning/todos/pending/2026-07-26-reserve-vsprev-row-height-in-insights-all-time.md`
- Suppress entrance animation on first render of progress indicators (cosmetic) — `.planning/todos/pending/2026-07-27-no-entrance-animation-on-first-render.md`
- Replace generated launch screen with branded static launch screen (minor) — `.planning/todos/pending/2026-07-27-branded-static-launch-screen.md`

**Unclustered**

- Audit every context.insert call site for the missing-save identity race (minor) — `.planning/todos/pending/2026-07-27-audit-context-insert-call-sites-for-missing-save.md`
- Rename app display name to DrinkPulse (cosmetic) — `.planning/todos/pending/2026-07-26-rename-app-display-name-to-drinkpulse.md`

### Blockers/Concerns

- Phase 3 has two open design decisions to resolve during discuss-phase/plan-phase, not before: the `fatalError` replacement UX, and which onboarding source of truth is authoritative (see PROJECT.md and ROADMAP.md Phase 3 "Open decisions")
- CloudKit sync Phase B is blocked externally: needs a provisioned iCloud container (paid Apple Developer account) plus an explicit one-way approval before enabling
- BAC estimate implementation is gated on explicit owner design approval (formula documented in docs/domain.md, not yet built)
- Open product decisions not yet resolved: multi-currency spend aggregation on the Dashboard; guideline-alert-card tap action (see `.claude/context/open-questions.md`)
- Accessibility audit (VoiceOver, Dynamic Type up to AX5) is still outstanding — not yet started

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260718-kgp | Fix bug: Insights month view "Longest Streak" card counts future days (after today) in current month. Should only count elapsed days (up to and including today). | 2026-07-18 | 62394d5 | [260718-kgp-fix-bug-insights-month-view-longest-stre](./quick/260718-kgp-fix-bug-insights-month-view-longest-stre/) |
| 260718-vgy | Fix bug: Insights month/week view "drinkFreeDays" metric counts future days in its X/Y numerator/denominator — follow-up to 260718-kgp. Should only count elapsed days. | 2026-07-18 | 56587bd | [260718-vgy-fix-bug-insights-month-week-view-drinkfr](./quick/260718-vgy-fix-bug-insights-month-week-view-drinkfr/) |
| 260719-nm6 | Add autocomplete/suggestions to the "custom name" text field on the drink add/edit screen — tap-to-autocomplete from prior ConsumptionEvent.customName history. | 2026-07-19 | 034d916 | [260719-nm6-add-autocomplete-suggestions-to-the-cust](./quick/260719-nm6-add-autocomplete-suggestions-to-the-cust/) |

### Roadmap Evolution

- Phase 01.1 inserted after Phase 1: Address tech debt: weekly summary notification (URGENT) — v1.1
- 2026-07-27 — v1.2 roadmap created: Phase 2 (Swift 6 Language Mode Migration) and Phase 3 (App Startup Hardening), continuing phase numbering from v1.1's 1/01.1. 6/6 v1.2 requirements mapped (SWIFT6-01/02/03 → Phase 2; STARTUP-01/02/03 → Phase 3).

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-07-21:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| debug | sheet-closes-reopens-loses-state | closed 2026-07-27 — human-verified, session archived to `.planning/debug/resolved/` | v1.1 close, 2026-07-21 |

## Session Continuity

Last session: 2026-07-27T10:49:47.671Z
Stopped at: Phase 3 context gathered
Resume file: .planning/phases/03-app-startup-hardening/03-CONTEXT.md

## Operator Next Steps

- Review and approve the v1.2 roadmap (`.planning/ROADMAP.md`)
- Then start planning: `/gsd-plan-phase 2`
