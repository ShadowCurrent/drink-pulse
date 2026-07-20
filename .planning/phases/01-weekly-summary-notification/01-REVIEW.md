---
phase: 01-weekly-summary-notification
reviewed: 2026-07-20T00:00:00Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - drinkpulse/Domain/WeeklySummaryCalculator.swift
  - drinkpulseTests/Domain/WeeklySummaryCalculatorTests.swift
  - drinkpulse/DesignSystem/AppStorageKeys.swift
  - drinkpulse/Localizable.xcstrings
  - drinkpulse/Services/WeeklySummaryService.swift
  - drinkpulseTests/Services/WeeklySummaryServiceTests.swift
  - drinkpulse/Services/NotificationActionHandler.swift
  - drinkpulse/Features/Shell/RootShellView.swift
  - drinkpulse/Features/Settings/Components/WeeklySummarySection.swift
  - drinkpulse/Features/Settings/SettingsView.swift
  - drinkpulse/Features/Onboarding/Components/HealthStep.swift
  - drinkpulseUITests/Features/Settings/WeeklySummarySettingsUITests.swift
  - drinkpulseUITests/Features/Onboarding/OnboardingWeeklySummaryUITests.swift
  - drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift
  - drinkpulse/UITestSeed.swift
  - drinkpulse/drinkpulseApp.swift
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-07-20T00:00:00Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

Reviewed the weekly-summary local-notification feature end to end: the pure
`WeeklySummaryCalculator` domain classifier, `WeeklySummaryService`'s
SwiftData-backed scheduling, the Settings/Onboarding toggle UI, tap-routing
through `NotificationActionHandler`/`RootShellView`, the new localization
strings, and the accompanying unit/UI tests.

The domain logic (`WeeklySummaryCalculator.content`) is correct and
thoroughly tested — all boundary conditions called out in the plan
(ENGG-04/05/06, the ±5% inclusive band, the large-delta case) are exercised
and pass. Density handling (physical 0.789 g/ml via `pureAlcoholGrams`,
never a display-mode density) is verified by a dedicated test. Localization
keys are all present and consistently referenced across production code and
UI tests; no missing or orphaned string keys were found for this feature.

No Critical-severity issues were found (no injection, no secrets, no force
unwraps, no crashes). Two Warning-level issues are worth fixing: a
non-exhaustive body-text mapping that silently mis-labels an otherwise
representable domain state, and a toggle-vs-async-authorization race that
can leave the opt-in re-enabled against the user's last action. A few minor
Info-level items round out the report.

## Warnings

### WR-01: `directionOnly` body-text mapping silently swallows the `.down` case behind `default:`

**File:** `drinkpulse/Services/WeeklySummaryService.swift:150-156`

**Issue:** `WeeklySummaryContent.directionOnly` carries a full `SignDirection`
(`.up`, `.down`, `.same`), but `bodyText(for:)` only special-cases `.up` and
falls through to `default:` for everything else:

```swift
case .directionOnly(let direction):
    switch direction {
    case .up:
        return String(localized: "weeklySummary.notification.body.directionOnlyUp")
    default:
        return String(localized: "weeklySummary.notification.body.directionOnlySame")
    }
```

Today `WeeklySummaryCalculator.content` never actually constructs
`.directionOnly(.down)` (only `.up`/`.same` are reachable), so this is
currently latent rather than user-visible. But the type system does not
enforce that invariant — `WeeklySummaryContent` is a general-purpose,
Sendable, Equatable enum that could be constructed with `.directionOnly(.down)`
from anywhere (a future refactor, a test, or a call site added later), and if
that ever happens the notification would silently show "No drinks logged
again this week." for what is actually a real increase — the opposite of
what "down" should communicate. There is also no test covering this branch,
so a regression here would go unnoticed.

**Fix:** Make the switch exhaustive and fail loudly on the case the domain
layer says is impossible, instead of quietly aliasing it to `.same`:

```swift
case .directionOnly(let direction):
    switch direction {
    case .up:
        return String(localized: "weeklySummary.notification.body.directionOnlyUp")
    case .same:
        return String(localized: "weeklySummary.notification.body.directionOnlySame")
    case .down:
        assertionFailure("WeeklySummaryCalculator never produces .directionOnly(.down)")
        return String(localized: "weeklySummary.notification.body.directionOnlySame")
    }
```

### WR-02: Toggle-off during pending async authorization can re-enable Weekly Summary against the user's last action

**Files:** `drinkpulse/Features/Settings/Components/WeeklySummarySection.swift:56-92`,
`drinkpulse/Features/Onboarding/Components/HealthStep.swift:109-164`

**Issue:** Both toggle bindings fire an unawaited `Task` on enable, and the
`off` path is fully synchronous:

```swift
private var toggleBinding: Binding<Bool> {
    Binding(
        get: { enabled },
        set: { newValue in
            if newValue {
                Task { await enable() }
            } else {
                enabled = false
                permissionDenied = false
                Task { await service.cancel() }
            }
        }
    )
}

private func enable() async {
    do {
        let granted = try await service.requestAuthorization()
        guard granted else { enabled = false; permissionDenied = true; return }
        permissionDenied = false
        enabled = true
        await service.scheduleIfEnabled(context: modelContext)
    } catch { ... }
}
```

If the user taps the toggle on, then taps it off again before the in-flight
`enable()` task resumes from its `await` (already-authorized case — this is
a real, if narrow, window since `requestAuthorization()` and
`scheduleIfEnabled(context:)` both suspend), the sequence becomes: (1) off
tap sets `enabled = false` synchronously, (2) the stale `enable()` task
resumes, unconditionally sets `enabled = true` again, and calls
`scheduleIfEnabled`, which reads `AppStorageKeys.weeklySummaryEnabled` (now
`true`) and reschedules the notification. The end state contradicts the
user's final, explicit opt-out — a correctness bug for a feature whose
entire premise is user consent, and it silently re-arms a notification the
user just turned off. (The identical pattern exists in `ReminderSection`,
outside this phase's scope, but both files reviewed here reproduce it.)

**Fix:** Guard the completion against a stale/superseded toggle action, e.g.
capture the intended target state and bail if it no longer matches current
state before applying side effects, or use a generation token:

```swift
private func enable() async {
    do {
        let granted = try await service.requestAuthorization()
        // Bail if the user has since turned it off again.
        guard granted, enabled != true || /* still wants it on */ true else { return }
        guard granted else { enabled = false; permissionDenied = true; return }
        guard UserDefaults.standard.bool(forKey: AppStorageKeys.weeklySummaryEnabled) != false else { return }
        permissionDenied = false
        enabled = true
        await service.scheduleIfEnabled(context: modelContext)
    } catch { ... }
}
```

(the exact shape is less important than adding *some* check that the user's
intent hasn't changed since the async call was kicked off).

## Info

### IN-01: Unused `import Foundation` in a pure domain type

**File:** `drinkpulse/Domain/WeeklySummaryCalculator.swift:1`

**Issue:** `WeeklySummaryCalculator.swift` imports `Foundation` but only uses
`Double`, `abs`, and Swift-standard-library enum/struct features — none of
which require Foundation. The file's own doc comment emphasizes it has "No
SwiftUI, SwiftData, or UserNotifications dependency" for testability/purity;
an unnecessary Foundation import is a minor inconsistency with that stated
goal.

**Fix:** Remove the import if a build check confirms it is unused, or leave
a comment if some symbol does require it.

### IN-02: `HealthStep.enableWeeklySummary()` swallows its error without logging, unlike its sibling

**File:** `drinkpulse/Features/Onboarding/Components/HealthStep.swift:150-164`

**Issue:** The `catch` block sets UI state (`weeklySummaryEnabled = false`,
`weeklySummaryPermissionDenied = true`) but never logs the error, whereas
the equivalent `WeeklySummarySection.enable()` (Settings) logs via
`logger.error("Weekly summary enable failed: ...")`. This makes onboarding
failures invisible in diagnostics even though the sibling code path treats
the same failure as worth a log line.

**Fix:** Add a `Logger` call mirroring `WeeklySummarySection`'s, e.g.
`logger.error("Weekly summary onboarding enable failed: \(error.localizedDescription)")`.

### IN-03: Weekly Summary's "Open Settings" deep link reuses a reminder-named string key

**File:** `drinkpulse/Features/Settings/Components/WeeklySummarySection.swift:41-49`

**Issue:** The denied-permission action row reuses
`"settings.reminder.openSettings"` (value: "Open Settings"). The generic
value is correct today, but the key name ties it semantically to the
reminder feature, which will be confusing if a future translator/localizer
tries to give it reminder-specific phrasing, or if the reminder feature's
copy changes independently of weekly-summary's.

**Fix:** Low priority; either accept the shared generic key as intentional
(and add a one-line comment noting it's intentionally shared), or introduce
a neutrally-named key (e.g. `settings.openSystemSettings`) shared by both
call sites.

---

_Reviewed: 2026-07-20T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
