---
phase: 01-weekly-summary-notification
reviewed: 2026-07-20T20:51:55Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - drinkpulse/DesignSystem/AppStorageKeys.swift
  - drinkpulse/Domain/WeeklySummaryCalculator.swift
  - drinkpulse/Features/Onboarding/Components/HealthStep.swift
  - drinkpulse/Features/Settings/Components/WeeklySummarySection.swift
  - drinkpulse/Features/Settings/SettingsView.swift
  - drinkpulse/Features/Shell/RootShellView.swift
  - drinkpulse/Localizable.xcstrings
  - drinkpulse/Services/NotificationActionHandler.swift
  - drinkpulse/Services/WeeklySummaryService.swift
  - drinkpulse/UITestSeed.swift
  - drinkpulse/drinkpulseApp.swift
  - drinkpulseTests/Domain/WeeklySummaryCalculatorTests.swift
  - drinkpulseTests/Services/WeeklySummaryServiceTests.swift
  - drinkpulseUITests/Features/Onboarding/OnboardingWeeklySummaryUITests.swift
  - drinkpulseUITests/Features/Settings/WeeklySummarySettingsUITests.swift
  - drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift
findings:
  critical: 1
  warning: 5
  info: 4
  total: 10
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-07-20T20:51:55Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

Reviewed the weekly-summary local-notification feature end to end: the pure
`WeeklySummaryCalculator` domain classifier, `WeeklySummaryService`'s
SwiftData-backed scheduling, the Settings/Onboarding toggle UI, tap-routing
through `NotificationActionHandler`/`RootShellView`, the localization strings,
and the accompanying unit/UI tests.

`WeeklySummaryCalculator.content` itself is correct and thoroughly tested — all
boundary conditions (ENGG-04/05/06, the ±5% inclusive band, the large-delta
case) are exercised. Density handling (physical 0.789 g/ml via
`pureAlcoholGrams`, never a display-mode density) is verified by a dedicated
test, and the opt-in/authorization/cancel plumbing correctly mirrors the
existing `ReminderService`/`ReminderSection` pattern (privacy-safe logging, no
PII in logs, idempotent scheduling, no force-unwraps in production code).

The main problem is architectural rather than local: `WeeklySummaryService`
bakes a percentage into the notification's **static** content at the moment the
app happens to be foregrounded, but the notification only fires at a fixed
future weekly boundary, and nothing in this codebase (no `BGTaskScheduler`, no
Notification Service Extension) recomputes it closer to delivery — so the
number a user sees can misrepresent the week it claims to summarize, most for
exactly the lapsed users this re-engagement nudge targets. A handful of smaller
correctness/robustness/consistency issues round out the report: a race between
a fast toggle-off and an in-flight enable, a non-exhaustive switch, a
notification-copy claim that doesn't match what the calculator can actually
prove, and a test-isolation gap for the newly added `pendingOpenInsights` flag.

## Critical Issues

### CR-01: Weekly-summary notification content can be stale/incomplete by delivery time

**File:** `drinkpulse/Services/WeeklySummaryService.swift:82-119`
**Also relevant:** `drinkpulse/Features/Shell/RootShellView.swift:104-109`

**Issue:**
`scheduleIfEnabled(context:)` computes `currentGrams`/`priorGrams` from SwiftData
and bakes the resulting percentage into a **static** `UNNotificationContent.body`
(via `makeRequest` → `bodyText(for:)`), then schedules a repeating
`UNCalendarNotificationTrigger` that fires once a week at a fixed time (9am on
the locale's first weekday). `scheduleIfEnabled` is only ever invoked from
`RootShellView`'s `.onChange(of: scenePhase)` when the app becomes `.active`
(launch/foreground). There is no `BGTaskScheduler`/`BGAppRefreshTask`
registration anywhere in the codebase (verified: no matches for
`BGTaskScheduler|BGAppRefreshTask|BGProcessingTask` under `drinkpulse/`) and no
Notification Service Extension target that could recompute content at delivery
time.

Consequently, the number shown in the delivered notification reflects whatever
`currentGrams`/`priorGrams` were **at the last time the app happened to be
foregrounded**, not at the moment the notification actually fires:

- A user who logs drinks Friday/Saturday night and does not reopen the app
  again before the following Monday will receive a notification whose
  percentage does not include that weekend's drinking, because the last
  `scheduleIfEnabled` call (say, on Wednesday) baked in an incomplete week's
  total.
- A genuinely lapsed user — the exact audience a "here's your week" nudge is
  meant to win back — can receive a notification quoting numbers computed from
  whatever "current week" existed several weeks ago, with no indication to the
  user that the figure is outdated.

This is worsened by `currentGrams` itself being computed from the **in-progress**
calendar week (`offset: 0` via `InsightsPeriod.dateRange`, mirroring
`InsightsViewModel.trendFraction`'s intentionally *live* "This Week" semantics —
see WR-01 below), not a completed one, so even a same-day recompute can
under-represent that week's eventual total; the gap between "computed" and
"delivered" only widens it further.

This is a user-facing correctness defect in a health-adjacent feature: the copy
presents an exact "you drank N% more/less than last week" claim, but the
mechanism cannot guarantee the number reflects the week it claims to describe.

**Fix:** Pick one of:
- Register a `BGAppRefreshTask` that runs close to the weekly fire time to
  recompute and reschedule with fresh data, so content reflects the
  actually-completed week even for users who haven't opened the app recently.
- Explicitly document this as an accepted v1 limitation and soften the copy
  (e.g. avoid a precise `%d%%` figure that implies more accuracy than the
  mechanism can provide) until a refresh mechanism exists.
- At minimum, track the recompute timestamp and skip/soften delivery when it is
  "too old" relative to the upcoming fire date, rather than silently presenting
  a stale figure as current.

## Warnings

### WR-01: `WeeklySummaryCalculator`'s doc comment contradicts how its only caller uses it

**File:** `drinkpulse/Domain/WeeklySummaryCalculator.swift:38-39`

**Issue:** The doc comment states:
```
///   - currentWeekGrams: Total pure-alcohol grams logged in the just-completed week.
```
but the only production caller, `WeeklySummaryService.scheduleIfEnabled`, passes
`offset: 0` (`InsightsPeriod.dateRange(offset: 0, ...)`), which per
`InsightsPeriod.dateRange` is the calendar week **containing `now`** — the
in-progress week, not a completed one (this matches `InsightsViewModel
.trendFraction`'s live "This Week" semantics, which the calculator's own inline
comment says it deliberately mirrors — `WeeklySummaryCalculator.swift:51-52`).
The doc comment will mislead future maintainers about what value the parameter
is expected to hold, and directly obscures the mechanism behind CR-01.

**Fix:** Update the doc comment to describe the parameter as "the current
period's total (which may be in progress)," or — if "just-completed week" is
actually the intended UX — change `scheduleIfEnabled` to pass `offset: -1` /
`offset: -2` instead of `offset: 0` / `offset: -1`, so behavior and
documentation agree.

### WR-02: Toggle-off during pending async authorization can re-enable Weekly Summary against the user's last action

**Files:** `drinkpulse/Features/Settings/Components/WeeklySummarySection.swift:56-92`

**Issue:** The toggle binding fires an unawaited `Task` on enable, while the
off path is fully synchronous:
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
`enable()` resumes past its `await` (a real window: both `requestAuthorization()`
and `scheduleIfEnabled(context:)` suspend, and re-authorization typically
resolves quickly once already granted from a prior run), the sequence becomes:
(1) the off-tap sets `enabled = false` synchronously and kicks off `cancel()`,
(2) the stale `enable()` task then resumes and unconditionally sets
`enabled = true` again, then calls `scheduleIfEnabled`, which reads
`AppStorageKeys.weeklySummaryEnabled` (now back to `true`) and reschedules the
notification. The end state contradicts the user's final, explicit opt-out —
silently re-arming a notification the user just turned off. The identical
shape exists in `HealthStep.enableWeeklySummary()`
(`drinkpulse/Features/Onboarding/Components/HealthStep.swift:150-164`).

**Fix:** Guard the completion against a stale/superseded toggle action — e.g.
re-check `UserDefaults.standard.bool(forKey: AppStorageKeys.weeklySummaryEnabled)`
(or a captured generation token) immediately before applying the "authorized"
side effects, and bail out if the user has since turned it back off.

### WR-03: Non-exhaustive `default:` case silently reinterprets a hypothetical `.down` as `.same`

**File:** `drinkpulse/Services/WeeklySummaryService.swift:150-156`

**Issue:**
```swift
case .directionOnly(let direction):
    switch direction {
    case .up:
        return String(localized: "weeklySummary.notification.body.directionOnlyUp")
    default:
        return String(localized: "weeklySummary.notification.body.directionOnlySame")
    }
```
`SignDirection` has three cases (`up`, `down`, `same`). Today
`WeeklySummaryCalculator.content` never constructs `.directionOnly(.down)` (only
`.up`/`.same` are reachable), so this is latent rather than user-visible today.
But `WeeklySummaryContent` is a general-purpose, `Sendable`, `Equatable` enum
with no invariant enforced by the type system preventing `.directionOnly(.down)`
from being constructed elsewhere (a future refactor, a test helper, or a new
call site). If that ever happens, the notification would silently show "No
drinks logged again this week." for what is actually a real increase — the
opposite of what "down" should communicate — with no compiler warning and no
existing test covering the branch.

**Fix:** Make the switch exhaustive and fail loudly on the case the domain
layer currently guarantees is impossible, instead of quietly aliasing it to
`.same`:
```swift
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

### WR-04: New `pendingOpenInsights` flag is not reset by `UITestSeed.resetTransientDefaults()`

**File:** `drinkpulse/UITestSeed.swift:64-74`

**Issue:** `resetTransientDefaults()` explicitly resets `reminderEnabled`,
`healthWriteEnabled`, `weeklySummaryEnabled`, and the health sample-count probe
to guard against simulator `UserDefaults` bleeding across UI-test runs (per the
function's own doc comment: prior runs "leave... true and break the next run's
'starts off' assumption"). The newly added `AppStorageKeys.pendingOpenInsights`
flag — written directly to `UserDefaults.standard` by both
`NotificationActionHandler.userNotificationCenter(_:didReceive:)` and, for
UI-test purposes, `drinkpulseApp.init()` via `UITestSeed.seedPendingOpenInsights`
(`drinkpulse/drinkpulseApp.swift:24-30`) — is not included in the reset list.

`WeeklySummaryTapUITests` deliberately sets this flag true via
`-dp_uitest_pending_open_insights YES` and relies on
`RootShellView.openInsightsIfPending()` to consume (clear) it on appear. If
that test — or any future test exercising the same path — fails or is
interrupted before the shell appears and consumes the flag, the `true` value
persists in the simulator's app-domain defaults (the exact cross-run
persistence problem `resetTransientDefaults()` exists to solve for the other
three keys), and can cause an unrelated, later UI-test run to unexpectedly land
on the Insights tab at cold launch — a flaky, hard-to-diagnose failure.

**Fix:**
```swift
UserDefaults.standard.removeObject(forKey: AppStorageKeys.pendingOpenInsights)
```
added alongside the other `removeObject` calls in `resetTransientDefaults()`.

### WR-05: `.directionOnly(.same)` notification copy can misrepresent a week where a drink actually was logged

**File:** `drinkpulse/Services/WeeklySummaryService.swift:154-155`, `drinkpulse/Domain/WeeklySummaryCalculator.swift:53-55`, `Localizable.xcstrings` key `weeklySummary.notification.body.directionOnlySame`

**Issue:** `WeeklySummaryCalculator.content` returns `.directionOnly(.same)`
whenever both `priorWeekGrams` and `currentWeekGrams` are `<= 0`. Per the
calculator's own comment ("A logged 0.0%-ABV event does not make
priorWeekGrams non-zero"), this condition can be true even when the user *did*
log drinks in both weeks — as long as those drinks were 0% ABV (e.g. a
mocktail or non-alcoholic beer), since only grams of pure alcohol are tracked,
not "was anything logged." The delivered notification text for this case is
literally:
> "No drinks logged again this week."

which is factually incorrect for a user who has been consistently logging
non-alcoholic drinks — a use case the app's own data model explicitly supports
(ABV can be `0.0`).

**Fix:** Reword the copy to be agnostic of drink-logging vs. alcohol content,
e.g. "No alcohol logged again this week." (matches what the calculator can
actually assert), or thread an "any event logged" signal through
`WeeklySummaryService` if the more literal "no drinks" claim is required.

## Info

### IN-01: `fetchLimit` combined with `fetchCount` has unclear/redundant intent

**File:** `drinkpulse/Services/WeeklySummaryService.swift:133-139`

**Issue:**
```swift
private func hasEvents(in context: ModelContext, before date: Date) -> Bool {
    var descriptor = FetchDescriptor<ConsumptionEvent>(
        predicate: #Predicate { $0.consumptionDate < date }
    )
    descriptor.fetchLimit = 1
    return ((try? context.fetchCount(descriptor)) ?? 0) > 0
}
```
Setting `fetchLimit = 1` on a descriptor that is then passed to `fetchCount`
(not `fetch`) is unusual — `fetchCount`'s job is to report how many records
match, and `fetchLimit`'s effect on that count is not part of SwiftData's
documented contract. The `> 0` check still produces the correct boolean result
regardless of whether `fetchLimit` has any effect, so this is not a functional
bug, just a combination that could mislead a future reader into thinking it's
a proven scan-capping optimization.

**Fix:** Either drop `fetchLimit` (it adds no proven value with `fetchCount`)
or switch to `!context.fetch(descriptor).isEmpty` with `fetchLimit` retained,
whichever more clearly documents the intended optimization.

### IN-02: Unused `import Foundation` in a pure domain type

**File:** `drinkpulse/Domain/WeeklySummaryCalculator.swift:1`

**Issue:** `WeeklySummaryCalculator.swift` imports `Foundation` but only uses
`Double`, `abs`, and standard-library enum/struct features, none of which
require Foundation. The file's own doc comment emphasizes it has "No SwiftUI,
SwiftData, or UserNotifications dependency" for testability/purity — an
unnecessary Foundation import is a minor inconsistency with that stated goal.

**Fix:** Remove the import if a build check confirms it is unused, or leave a
comment noting which symbol requires it if one is found.

### IN-03: `HealthStep.enableWeeklySummary()` swallows its error without logging, unlike its Settings sibling

**File:** `drinkpulse/Features/Onboarding/Components/HealthStep.swift:150-164`

**Issue:** The `catch` block sets UI state (`weeklySummaryEnabled = false`,
`weeklySummaryPermissionDenied = true`) but never logs the error, whereas the
equivalent `WeeklySummarySection.enable()` (Settings) logs via
`logger.error("Weekly summary enable failed: ...")`. Both call sites were added
in this same phase for the same underlying failure (authorization request
throwing), so the missing log in the onboarding path is an inconsistency
within the phase's own code, not a pre-existing convention being followed —
it makes onboarding-time authorization failures invisible in diagnostics.

**Fix:** Add a `Logger` call mirroring `WeeklySummarySection`'s, e.g.
`logger.error("Weekly summary onboarding enable failed: \(error.localizedDescription)")`.

### IN-04: Weekly Summary's "Open Settings" deep link reuses a reminder-specific localization key

**File:** `drinkpulse/Features/Settings/Components/WeeklySummarySection.swift:41-49`

**Issue:** The denied-permission action row reuses
`String(localized: "settings.reminder.openSettings")` (value: "Open
Settings") verbatim from `ReminderSection`. This diverges from the more recent
`HealthSection`, which defines its own feature-scoped key
(`settings.health.openSettings`) for the identical UI element. The shared
generic value is correct today, but the key name ties it semantically to the
reminder feature and is inconsistent with the pattern the codebase had already
moved to (per-feature key) by the time this phase was written.

**Fix:** Low priority — either accept the shared key as intentional and add a
one-line comment noting it's deliberately shared, or introduce a
feature-scoped key (e.g. `settings.weeklySummary.openSettings`) matching
`HealthSection`'s convention.

---

_Reviewed: 2026-07-20T20:51:55Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
