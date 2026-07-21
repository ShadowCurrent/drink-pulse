# Roadmap: DrinkPulse

## Overview

DrinkPulse's v1.0 scope — quick drink logging, insight/history views,
guideline-aware settings, first-launch onboarding, Apple Health
write-back, risk-language, a history calendar, in-place entry editing,
and opt-in log reminders — already shipped prior to GSD adoption,
delivered across 36 completed plans (`docs/plans/0001`–`0036`; see
`docs/plans/INDEX.md` for the full delivery history).

This is the **first GSD-managed milestone: v1.1 — Weekly Summary
Notification**. It is a single, cohesive feature: an opt-in local
notification that tells the user, once a week, whether their
pure-alcohol consumption went up, down, or stayed about the same
compared to the prior week — following the existing `Services/` layer
notification pattern established for the daily log reminder
(ADR-0008, `ReminderService`).

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [x] **Phase 1: Weekly Summary Notification** - Opt-in weekly notification comparing this week's alcohol consumption to last week, with Settings/onboarding controls, correct edge-case messaging, and tap-to-open. (completed 2026-07-20)

## Phase Details

### Phase 1: Weekly Summary Notification

**Goal**: Users who opt in (via Settings or onboarding) receive an accurate, correctly-timed weekly notification comparing their pure-alcohol consumption to the prior week, and tapping it opens the app.
**Depends on**: Nothing (first phase)
**Requirements**: ENGG-01, ENGG-02, ENGG-03, ENGG-04, ENGG-05, ENGG-06, ENGG-07
**Success Criteria** (what must be TRUE):

  1. User can enable/disable the weekly summary notification from Settings; it is off by default until the user explicitly opts in.
  2. During onboarding, the user is offered the option to enable the weekly summary notification, and their choice takes effect immediately (reflected in Settings, no separate action needed).
  3. When enabled, the user receives a notification on the first day of the new week (per system locale) at 9am local time, stating the percentage higher/lower than the previous week's total pure-alcohol grams, or "about the same" when the change is within ±5%.
  4. When last week had zero grams logged, the notification states direction only (no exact numbers/percentages, avoiding a meaningless divide-by-zero); when there is no prior week of data at all (the user's first week), no notification fires.
  5. Tapping the notification opens the app.

**Plans**: 5/5 plans executed
Plans:
**Wave 1**

- [x] 01-01-PLAN.md — Domain calculator (WeeklySummaryCalculator) + AppStorageKeys + all-phase Localizable.xcstrings entries

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-02-PLAN.md — WeeklySummaryService (scheduling, fetch, density-correct sums)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01-03-PLAN.md — NotificationActionHandler + RootShellView tap-routing and foreground reschedule
- [x] 01-04-PLAN.md — Settings WeeklySummarySection + Onboarding HealthStep toggle

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 01-05-PLAN.md — UI tests (Settings, Onboarding, tap-routing) + test-only seeding hooks

**UI hint**: yes

## Progress

**Execution Order:** Phase 1

| Phase | Plans Complete | Status | Completed |
|-------|-----------------|--------|-----------|
| 1. Weekly Summary Notification | 5/5 | Complete    | 2026-07-20 |

---
*Last updated: 2026-07-20 after planning Phase 1 (5 plans across 4 waves: 01-01 domain calculator, 01-02 service, 01-03 tap-routing/shell wiring, 01-04 Settings/Onboarding UI, 01-05 UI tests)*

### Phase 01.1: Address tech debt: weekly summary notification (INSERTED)

**Goal:** Dispose of the 3 tech-debt items flagged by the v1.1 milestone audit for the weekly summary notification feature — fix the one real inconsistency (onboarding toggle-off doesn't call `WeeklySummaryService.cancel()`), and explicitly close the other two as accepted no-action items.
**Requirements**: None — no new REQ-IDs this phase; ENGG-01 through ENGG-07 stay mapped to Phase 1
**Depends on:** Phase 1
**Plans:** 1 plan

Plans:
**Wave 1**

- [ ] 01.1-01-PLAN.md — Constructor-inject WeeklySummaryService into HealthStep, extract disableWeeklySummary(), add service-call assertion test (D-02/D-03)
