# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.1 — Weekly Summary Notification

**Shipped:** 2026-07-21
**Phases:** 2 | **Plans:** 6 | **Sessions:** 2

### What Was Built
- `WeeklySummaryCalculator` — pure domain classifier for skip/direction-only/percentage week-over-week messaging, including the ±5% "about the same" band and zero-prior-week edge case
- `WeeklySummaryService` — `Services/` layer scheduler mirroring `ReminderService`'s shape, always summing physical `pureAlcoholGrams` (never a display-mode density)
- Settings (`WeeklySummarySection`) and Onboarding (`HealthStep`) opt-in surfaces sharing one `AppStorageKeys.weeklySummaryEnabled` key
- Tap-to-open routing to Insights via `NotificationActionHandler` + `RootShellView`
- Tech-debt closure (Phase 01.1): onboarding toggle-off now calls `WeeklySummaryService.cancel()`, closing the one real Settings/Onboarding parity gap found by the first milestone audit

### What Worked
- Reusing the existing `Services/` protocol-wrapped pattern (ADR-0008) for a second notification type required zero new architecture — `WeeklySummaryService` mirrors `ReminderService` almost 1:1
- Milestone audit (`/gsd-audit-milestone`) caught a real cross-surface inconsistency (Settings toggle-off called `.cancel()`, Onboarding didn't) that per-plan verification alone had missed, because each plan verified its own surface in isolation
- Decimal-phase insertion (01.1) closed that gap cleanly without reopening or amending the frozen Phase 1 plan — the fix, its test, and the two explicitly-accepted no-action items all landed in one small phase
- Constructor injection + convenience-init split (`HealthStep(onDone:weeklySummaryService:)` / `HealthStep(onDone:)`) made the fix unit-testable via the existing `FakeNotificationCenter` mock without touching production call sites

### What Was Inefficient
- The Settings/Onboarding parity gap could have been caught earlier if "toggle-off must mirror toggle-on's counterpart surface" had been an explicit acceptance criterion on Phase 1's plan for the Onboarding toggle, rather than discovered post-hoc by audit
- Swift's actor-isolation rules blocked the planned default-parameter-value init syntax (`weeklySummaryService: WeeklySummaryService = WeeklySummaryService()` inside a `@MainActor` init) — a one-off deviation, but worth flagging as a recurring risk for future `@MainActor`-service-injection plans

### Patterns Established
- Two independent opt-in notification surfaces (Settings + Onboarding) sharing one `AppStorageKeys` key is now the established convention for any future opt-in notification feature
- Constructor-injectable `@MainActor` services need a convenience init that constructs the default *inside the init body*, not as a default parameter value, when the service type itself is `@MainActor`-isolated

### Key Lessons
1. When a feature ships two parallel opt-in entry points (Settings + Onboarding), explicitly verify toggle-off symmetry between them in the same plan/verification pass — don't rely on a separate milestone audit to catch it
2. Decimal-phase insertion is the right mechanism for milestone-audit-flagged tech debt: small, scoped, doesn't reopen frozen plans, and can explicitly close no-action items (not just fix real bugs) so nothing lingers un-triaged

### Cost Observations
- Model mix: balanced profile — planner/executor/debugger on Sonnet, verifier/plan-checker on Haiku, integration-checker on Sonnet
- Sessions: 2 (Phase 1 delivery, Phase 01.1 tech-debt closure + audit + close)
- Notable: first GSD-managed milestone for this project (36 pre-GSD plans predate adoption) — no prior-milestone baseline to compare velocity against

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.1 | 2 | 2 | First GSD-managed milestone; introduced decimal-phase insertion for audit-flagged tech debt |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.1 | +26 (9 calculator, 16 service, 1 HealthStep) + 4 UI tests | ≥90% (Domain 100%) per CLAUDE.md gate | 0 — no new third-party dependencies |

### Top Lessons (Verified Across Milestones)

1. Reusing an established `Services/` layer pattern for a new capability (rather than inventing one) keeps a single-feature milestone architecturally uneventful — confirmed once, watch for continued validation on future notification/service work
