# Retrospective — 0016 log-reminder local notifications

**Completed**: 2026-06-26
**Status**: completed

## What shipped

An opt-in daily local notification reminding the user to log their drinks,
and the **first member of a new `Services/` layer** (ADR-0008). Settings →
Reminders has a toggle and a time picker; enabling requests notification
authorization, schedules one repeating request, and tapping the notification
opens Add Drink. The reminder copy is deliberately neutral ("How did today
go?") — a prompt to log, never a consumption judgement.

## Outcome vs plan

All in-scope items delivered. Open questions Q1–Q4 implemented as resolved
(21:00 default, neutral copy, persisted tap-action across cold launch, inline
denied message + Open Settings deep link).

### Deviations (full detail in execution.md)
- **ADR number**: plan said `0005-services-layer.md`; 0005–0007 were taken, so
  created **`0008`**. ADR-0004 already referenced "the services-layer ADR", so
  this filled an existing forward reference rather than inventing a layer.
- **Settings is a glass-card `ScrollView`** (plan-0027), not the `List` the
  2026-05 plan assumed → `ReminderSection` built as a `SettingsSection`.
- **Tap-action** wired to the current shell's single `showAddDrink` sheet via a
  persisted flag (cold launch) + a `NotificationCenter` async-sequence task
  (running) — no Combine / ObservableObject.
- **UI-test enablement**: rather than driving the real, locale-dependent,
  one-shot system permission alert (flaky), added a launch-arg-gated
  non-prompting stub centre (`UITestNotificationCenter`), selected only under
  `-dp_uitest`. The UI test drives the real toggle/time wiring without a system
  prompt and without scheduling a real notification.
- **Test location**: `ReminderServiceTests` placed under `drinkpulseTests/
  Services/` per the CLAUDE.md mirror rule, not the plan's target-root path.

## What went well
- `NotificationScheduling` protocol made `ReminderService` 100% unit-testable
  with a `FakeNotificationCenter` — no real prompt, no real scheduling.
- The Services-layer ADR was anticipated by ADR-0004, so the architecture
  change slotted in cleanly.

## What was tricky
- `ReminderService.defaultCenter()` had to be `nonisolated` because it is used
  as a default argument (evaluated in a nonisolated context) while the class is
  `@MainActor`.
- Conforming `UNUserNotificationCenter` to a `Sendable` protocol under Swift 6
  needed `@retroactive @unchecked Sendable` to avoid a strict-concurrency
  warning on the framework type.
- Adding a section above App Lock broke a sibling UI test's single-swipe scroll
  assumption — fixed by scrolling until hittable.

## Follow-ups / not done
- `NotificationActionHandler` (the tap delegate) is not unit-tested:
  `UNNotificationResponse` / `UNNotification` have no public initializers, so it
  is framework glue, excluded like the protocol adapter. Its real behaviour is
  only exercisable with an actual notification tap.
- Weekly summary notification remains a separate roadmap idea.
- `HistoryUnitDisplayUITests` shows pre-existing full-suite timing flakiness
  (passes in isolation) — candidate for a separate robustness pass.
</content>
