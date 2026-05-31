# 0016 — Log-reminder local notifications

**Status**: draft
**Size**: medium
**Created**: 2026-05-19

## Summary

Add an opt-in daily local notification that reminds the user to log
drinks before bed. Toggle and time-picker live in Settings → Reminders.

- Off by default. Toggling on triggers an `UNUserNotificationCenter`
  authorisation request (alert + sound, no badge).
- One repeating local notification per day at the chosen time. The
  notification body localised; tapping it opens AddDrink.
- Notification is *only* about logging — not about consumption
  recommendations (avoid medical-advice posture).

## Context

Surfaced in the Claude Design chat: "Reminders to log configurable in
settings". The user picked a list of times (18:00–22:00) in the design;
we'll use a `DatePicker(.hourAndMinute)` for flexibility.

CLAUDE.md "out of scope" excludes third-party analytics and login systems
but says nothing about notifications; this is in-scope.

### Architectural note: new `Services/` layer

`ReminderService` is the **first member of a new `drinkpulse/Services/`
layer** — it is neither a domain value type, a view model, nor a SwiftUI
view. It wraps a platform capability (`UNUserNotificationCenter`) behind a
testable protocol. The current `architecture.md` folder layout lists only
`Domain/`, `Features/`, and `DesignSystem/`, so introducing `Services/` is a
deliberate architectural change that must be recorded:

- Step 0 below creates an ADR for the layer.
- The same task updates the `architecture.md` folder layout and the layer
  rules so the living doc matches reality (per CLAUDE.md living-docs rule).

A "service" is defined as: a stateless or app-lifecycle-scoped type that
mediates a platform/system capability (notifications, Health, file IO),
exposed through a protocol so view models and views depend on the
abstraction, not the framework.

## Scope

### In
- `Services/NotificationScheduling.swift` — protocol abstracting the parts
  of `UNUserNotificationCenter` we use, so `ReminderService` is unit-testable
  without touching the real notification centre:

  ```swift
  protocol NotificationScheduling: Sendable {
      func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
      func add(_ request: UNNotificationRequest) async throws
      func pendingRequestIdentifiers() async -> [String]
      func removePendingRequests(withIdentifiers ids: [String])
  }
  ```

  `UNUserNotificationCenter` is extended to conform (thin adapter wrapping
  its completion-handler / async APIs). Tests inject a `FakeNotificationCenter`
  that records `add`/`remove` calls and returns canned pending identifiers.
- `Services/ReminderService.swift` — `@MainActor final class` depending on
  `NotificationScheduling` (injected; defaults to the real centre):
  - `requestAuthorization() async throws -> Bool`
  - `schedule(hour: Int, minute: Int) async throws` — builds the
    `DateComponents`, cancels any existing request first (idempotency),
    then adds one repeating request.
  - `cancel() async`
  - `scheduleIfEnabled() async` — reads `@AppStorage`-backed values and
    re-applies; safe to call at launch and on `scenePhase == .active`.
  - Static identifier `"dp.daily.log.reminder"`.
  - `makeRequest(hour:minute:) -> UNNotificationRequest` — pure factory,
    extracted so tests assert on the trigger without scheduling.
- `Features/Settings/ReminderSection.swift` — toggle row, time picker
  row (visible only when toggle on), inline hint copy.
- `@AppStorage("dp_reminder_enabled") Bool` + a stored
  `dp_reminder_hour:Int` + `dp_reminder_minute:Int`.
- Open-Settings deep link if authorisation was denied: `UIApplication.openSettingsURLString`.
- Localised strings (title + body).
- Tap action: when the notification is tapped, open the Add Drink sheet on
  next launch. Implement via `UNUserNotificationCenterDelegate` and a
  shared `@AppStorage("dp_pending_add_drink")` flag the root reads on
  appear.

### Out
- Multiple reminders per day.
- Smart reminders ("haven't logged after 9pm — open Add Drink").
- Weekly summary notifications — separate idea, kept on roadmap.
- Server push.

## Implementation steps

0. **ADR + architecture.md** — create `docs/decisions/0005-services-layer.md`
   (0004 is the data-access ADR; re-check `docs/decisions/` in case the
   number was taken) describing the `Services/` layer and the
   protocol-wrapping rule for platform capabilities. Update the
   `architecture.md` folder layout to add
   `Services/` and a one-line layer rule. Do this first so the new layer is
   documented before any code lands.
1. **`NotificationScheduling` protocol + adapter** — define the protocol and
   the `UNUserNotificationCenter` conformance (the thin adapter).
2. **`ReminderService`** — `@MainActor final class` taking a
   `NotificationScheduling` (default = real centre). Implement
   `makeRequest`, `schedule`, `cancel`, `requestAuthorization`,
   `scheduleIfEnabled`.
3. **Settings UI** — toggle + time row; on toggle-on call
   `requestAuthorization` and surface failures inline (e.g. "Notifications
   denied — open Settings", Q4 → option A includes the "Open Settings"
   button).
4. **Schedule** — `makeRequest` builds a `UNCalendarNotificationTrigger(
   dateMatching: components, repeats: true)` with `.hour` and `.minute`
   only, wrapped in a `UNNotificationRequest` using the static identifier.
5. **Cancel / re-schedule** — `schedule` always removes the existing
   request id first, guaranteeing idempotency (toggle off, or time change,
   never leaves two pending requests).
6. **Tap-action handling** — `UNUserNotificationCenterDelegate` set in
   `drinkpulseApp`. On `didReceive response`, set the
   `@AppStorage("dp_pending_add_drink")` flag and post a `NotificationCenter`
   event the shell observes to flip its `showAddDrink` state. The root reads
   and clears the flag `.onAppear` so the action survives an app kill
   (Q3 → option A).
7. **Tests** — pure logic via the injected fake centre (see "Tests
   required").

## Files

| File | Action |
|------|--------|
| `docs/decisions/0005-services-layer.md` | Create (ADR) |
| `docs/architecture.md` | Modify (add `Services/` to folder layout + layer rule) |
| `drinkpulse/Services/NotificationScheduling.swift` | Create (protocol + `UNUserNotificationCenter` adapter) |
| `drinkpulse/Services/ReminderService.swift` | Create |
| `drinkpulse/Features/Settings/Components/ReminderSection.swift` | Create |
| `drinkpulse/Features/Settings/SettingsView.swift` | Modify |
| `drinkpulse/drinkpulseApp.swift` | Modify (delegate + `scheduleIfEnabled` on launch) |
| `drinkpulse/Localizable.xcstrings` | Append keys |
| `drinkpulseTests/ReminderServiceTests.swift` | Create (with `FakeNotificationCenter`) |
| `drinkpulse/Info.plist` | No change — local notifications need no usage-description key |

## Open questions

- [x] **Q1 — Default time** when first enabled: **21:00** (option A —
  matches design). Stored as `dp_reminder_hour = 21`, `dp_reminder_minute = 0`.

- [x] **Q2 — Notification body copy**: **option A — neutral phrasing**
  ("How did today go?"). Chosen for consistency with the project's
  risk-language stance (see [[plan-0015]] and the risk-language guidance):
  notifications must not nudge toward or moralise about consumption, only
  prompt logging. Title: "DrinkPulse"; body: localised "How did today go?".

- [x] **Q3 — Persist tap-action** across an app kill: **option A** —
  the `@AppStorage("dp_pending_add_drink")` flag survives the kill; the
  shell opens AddDrink on next launch and clears the flag after reading.

- [x] **Q4 — Settings copy when permission denied**: **option A** —
  inline message **plus** an "Open Settings" button using
  `UIApplication.openSettingsURLString`.

## Tests required

All tests inject a `FakeNotificationCenter` conforming to
`NotificationScheduling`; no real authorization prompt is ever triggered.

- `test_makeRequest_buildsRepeatingTrigger_atGivenHourMinute` — assert the
  `UNCalendarNotificationTrigger` has `repeats == true` and `dateComponents`
  `.hour == 21`, `.minute == 0`, and uses the static identifier.
- `test_schedule_addsExactlyOneRequest` — after `schedule(hour:minute:)`,
  the fake records exactly one `add` with the reminder identifier.
- `test_schedule_isIdempotent` — calling `schedule` twice results in one
  pending request, not two (remove-then-add ordering verified).
- `test_cancel_removesPendingRequest` — `cancel()` removes the reminder id.
- `test_scheduleIfEnabled_doesNothing_whenDisabled` — with the enabled flag
  false, no `add` is recorded.

> Coverage: `ReminderService` is a Services-layer type → ≥85% per the
> repository/service coverage target in CLAUDE.md. The protocol adapter
> (thin `UNUserNotificationCenter` conformance) is excluded as framework
> glue, consistent with the "what does NOT require unit tests" list.

## Future links

- Weekly summary notification — future idea on roadmap.
- AI chat may schedule its own ad-hoc reminders later; we don't reserve
  that infra here.
