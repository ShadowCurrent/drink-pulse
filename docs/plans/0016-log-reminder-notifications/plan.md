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

## Scope

### In
- `Services/ReminderService.swift` — wraps `UNUserNotificationCenter`:
  - `requestAuthorization() async throws -> Bool`
  - `schedule(at components: DateComponents) async throws`
  - `cancel() async`
  - Static identifier `"dp.daily.log.reminder"`.
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

1. **`ReminderService`** — `@MainActor final class`. Static method
   `scheduleIfEnabled()` reads AppStorage and re-applies — useful at
   app launch and on scenePhase=active.
2. **Settings UI** — toggle + time row; on toggle-on call
   `requestAuthorization` and surface failures inline (e.g. "Notifications
   denied — open Settings").
3. **Schedule** — `var trigger = UNCalendarNotificationTrigger(dateMatching:
   components, repeats: true)` with `.hour` and `.minute` only.
4. **Cancel** — removes pending requests by id when toggle goes off OR
   when time is changed (schedule fresh).
5. **Tap-action handling** — `UNUserNotificationCenterDelegate` set in
   `drinkpulseApp`. On `didReceive response`, set the AppStorage flag and
   post a `NotificationCenter` event the shell observes to flip its
   `showAddDrink` state.
6. **Tests** — pure logic only:
   - `ReminderService.scheduleAt(hour: 21, minute: 0)` produces a
     `UNCalendarNotificationTrigger` with matching components and
     `repeats == true`. Use the protocol so we can inject a fake centre.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Services/ReminderService.swift` | Create |
| `drinkpulse/Features/Settings/Components/ReminderSection.swift` | Create |
| `drinkpulse/Features/Settings/SettingsView.swift` | Modify |
| `drinkpulse/drinkpulseApp.swift` | Modify (delegate) |
| `drinkpulse/Localizable.xcstrings` | Append keys |
| `drinkpulseTests/ReminderServiceTests.swift` | Create |
| `drinkpulse/Info.plist` | Modify (UNUserNotificationCenter privacy if needed — none for local notifications) |

## Open questions

- [ ] **Q1 — Default time** when first enabled: 21:00 (matches design)
  vs. user-locale-evening?
  - A) 21:00 (default — matches design)

- [ ] **Q2 — Notification body copy**: should it allude to consumption
  ("Time to log tonight's drinks") or be neutral ("Open DrinkPulse")?
  - A) Neutral wellness phrasing: "How did today go?" (default)
  - B) Specific: "Log today's drinks"

- [ ] **Q3 — Persist tap-action** when user kills app before opening:
  - A) AppStorage flag survives kill — open AddDrink on next launch
       (default; cleared after read)
  - B) Drop the action if app was killed

- [ ] **Q4 — Settings copy when permission denied**: just inline message or
  also offer a button to open system settings?
  - A) Inline message + "Open Settings" button (default)
  - B) Inline message only

## Tests required

- `ReminderServiceTests`: scheduling, cancellation, idempotency
  (schedule twice → only one pending request).

## Future links

- Weekly summary notification — future idea on roadmap.
- AI chat may schedule its own ad-hoc reminders later; we don't reserve
  that infra here.
