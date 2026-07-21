# Phase 1: Weekly Summary Notification - Research

**Researched:** 2026-07-20
**Domain:** iOS local notifications (UserNotifications framework), SwiftUI/SwiftData opt-in feature wiring
**Confidence:** HIGH

## Summary

This phase is a close structural clone of the existing daily-reminder feature
(`ReminderService` / `ReminderSection` / `HealthStep`, all shipped in
plan-0016/plan-0027/plan-0036). Every piece of infrastructure this phase
needs — the `Services/` protocol-wrapped notification pattern, the
`SettingsSection` card layout, the onboarding opt-in toggle pattern, the
tap-routing delegate, and even the week-over-week % calculation itself —
already exists in the codebase in a form that can be reused or mirrored
almost line-for-line. No new SwiftData schema version, no new third-party
package, and no new background-execution infrastructure (`BGTaskScheduler`)
is required or should be introduced (confirmed absent from the codebase;
D-01 explicitly rules it out).

The one genuinely new piece of platform knowledge this phase needs is how to
build a **weekly-repeating** `UNCalendarNotificationTrigger` (the shipped
`ReminderService.makeRequest` only builds a **daily**-repeating trigger, via
`hour`/`minute` alone). Weekly repetition requires adding a `weekday`
component to `DateComponents`, and "first day of the new week per system
locale" must derive that weekday from `Calendar.current.firstWeekday`, not a
hardcoded `1` (Sunday) or `2` (Monday) — this is the same locale-aware
primitive `InsightsPeriod` already uses via
`calendar.dateInterval(of: .weekOfYear, for:)`.

**Primary recommendation:** Create a new `WeeklySummaryService` in
`Services/` that follows `ReminderService`'s exact shape (stable identifier
constant, pure `makeRequest` factory, idempotent `schedule()`/`cancel()`,
`scheduleIfEnabled()` read from `@AppStorage`), but (a) computes its
percentage-change content by reusing `InsightsViewModel`'s week-aggregation
math (extracted into a small pure calculator, not the view model itself —
see Architecture Patterns), and (b) builds its trigger with
`dateComponents.weekday = Calendar.current.firstWeekday` +
`hour = 9, minute = 0`. Reuse `NotificationScheduling` /
`UITestNotificationCenter` as-is; add a sibling case to
`NotificationActionHandler` for tap-routing to Insights; add a new
`SettingsSection` after `ReminderSection`; fold the onboarding toggle into
the existing `HealthStep` (step 3/4, unchanged step count).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Local notification scheduling/cancellation | Services layer (`Services/`) | — | ADR-0008: platform capability wrapped behind `NotificationScheduling` protocol, mirrors `ReminderService` |
| Week-over-week % change calculation | Domain / calculation layer (new pure calculator) | Services layer (consumes it) | Domain rule (CLAUDE.md: grams of pure alcohol is unit of truth); must be independently unit-testable without `UNUserNotificationCenter` or SwiftUI |
| Opt-in toggle state | SwiftUI views (`@AppStorage`) | Services layer (reads via `UserDefaults`) | Matches `reminderEnabled` pattern — state lives in `AppStorageKeys`, not a service-owned property |
| Notification tap → open Insights | App shell (`RootShellView` + `drinkpulseApp`) | Services layer (`NotificationActionHandler`) | Delegate lives in `Services/`, but the actual navigation (tab switch) must happen in the shell, which owns `selectedTab` |
| Settings UI (toggle + permission hint) | Feature layer (`Features/Settings/Components/`) | — | One `SettingsSection` card per concern, per D-07 |
| Onboarding opt-in UI | Feature layer (`Features/Onboarding/Components/HealthStep.swift`) | — | D-05: folded into existing step, no new file needed at the step level (edit in place) |
| Content freshness (recompute trigger) | App shell (`scenePhase == .active`) | Services layer (`scheduleIfEnabled()`) | Mirrors `ReminderService` exactly — no separate background tier |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `UserNotifications` (Apple, first-party) | iOS 26 SDK (bundled) | Local notification scheduling, tap delegate | Already the sole notification mechanism in the app (`ReminderService`); zero alternative under CLAUDE.md's on-device-only / no-third-party-SDK constraint |
| `Foundation` `Calendar` / `DateComponents` | iOS 26 SDK (bundled) | Locale-aware week boundary + weekly trigger construction | Already used by `InsightsPeriod` for the exact same "first day of week per locale" semantics (`calendar.dateInterval(of: .weekOfYear, for:)`, `calendar.firstWeekday`) |
| SwiftData `@Query` | iOS 26 SDK (bundled) | Fetching last-week / prior-week `ConsumptionEvent`s for the % calculation | ADR-0004 (no repository layer); matches how `InsightsView`/`InsightsViewModel` are fed |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `OSLog` | iOS 26 SDK (bundled) | Category-only error logging in the new service | Matches `ReminderService`'s `Logger(subsystem: "com.drinkpulse.app", category: ...)` pattern (CLAUDE.md logging rules) |
| Swift Testing (`@Test`, `#expect`) | Bundled with Xcode 26.6 (verified installed: `xcodebuild -version` → Xcode 26.6, Build 17F113) | Unit tests for the new service and calculator | Matches `ReminderServiceTests.swift`'s existing pattern; CLAUDE.md mandates Swift Testing for new tests |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `UNCalendarNotificationTrigger` with `weekday` component (repeats: true) | `BGAppRefreshTask` / `BGTaskScheduler` recompute-and-schedule-next-fire pipeline | Rejected by D-01 — no `BGTaskScheduler` infra exists anywhere in the codebase today; introducing it is explicitly out of scope for this phase. The calendar-trigger approach is self-sufficient (the OS fires it without app wake-up) but content can go stale (D-02 accepts this). |
| Reusing `InsightsViewModel.trendFraction` directly from the service | Extracting the week-total/prev-week-total math into a small `Sendable` pure-function calculator | `InsightsViewModel` is `@Observable @MainActor` and carries UI-only state (`period`, `weekOffset`, chart caching) — pulling a background-schedulable service through it is architecturally wrong. A pure calculator (see Architecture Patterns) is directly unit-testable and has no UI coupling, while still reusing the *exact same date-range math* (`InsightsPeriod.dateRange(offset:)`) so both surfaces agree by construction. |

**Installation:** None — every dependency is a first-party Apple framework already linked in the target (`UserNotifications`, `Foundation`, `SwiftData`, `OSLog`). No `Package.swift` / SPM changes.

**Version verification:** N/A (no external package versions to verify — see Package Legitimacy Audit below).

## Package Legitimacy Audit

**No external packages are introduced by this phase.** All functionality is
built from first-party Apple frameworks (`UserNotifications`, `Foundation`,
`SwiftData`, `OSLog`, `SwiftUI`) already present in the Xcode project. Per
CLAUDE.md ("no network calls except CloudKit sync... never add a third-party
SDK"), no dependency-resolution or `npm view`/`cargo search`-style audit
applies here. This section is intentionally empty of table rows.

**Packages removed due to [SLOP] verdict:** none — no packages proposed.
**Packages flagged as suspicious [SUS]:** none — no packages proposed.

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│  App foreground (scenePhase == .active)                              │
│  RootShellView.onChange(scenePhase)                                  │
└───────────────────────────┬───────────────────────────────────────────┘
                            │ Task { await weeklySummaryService.scheduleIfEnabled() }
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│  WeeklySummaryService (Services/, @MainActor)                        │
│  1. reads @AppStorage(weeklySummaryEnabled) — bail if false          │
│  2. fetches ConsumptionEvents (SwiftData) for current + prior week   │
│  3. calls WeeklySummaryCalculator.content(current:, prior:) -> body  │
│  4. builds UNNotificationRequest (weekday=firstWeekday, 09:00)       │
│  5. center.removePendingRequests → center.add (idempotent)           │
└───────────────────────────┬───────────────────────────────────────────┘
                            │ (pure, no UI/service coupling)
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│  WeeklySummaryCalculator (Domain/ or Features/Insights/, pure)       │
│  input: [ConsumptionEvent] currentWeek, [ConsumptionEvent] priorWeek,│
│         hasAnyPriorData: Bool                                        │
│  → .skip                          (ENGG-06: no prior week ever)      │
│  → .directionOnly(.increase/.decrease/.same)  (ENGG-05: prior=0g)    │
│  → .percentage(fraction, direction)            (ENGG-04: normal case)│
└─────────────────────────────────────────────────────────────────────┘

  ... time passes; OS fires the notification autonomously (no app wake) ...

┌─────────────────────────────────────────────────────────────────────┐
│  User taps notification banner                                       │
│  UNUserNotificationCenter → NotificationActionHandler.didReceive     │
│  identifier == weeklySummaryIdentifier?                              │
│    → sets @AppStorage(pendingOpenInsights) = true                    │
│    → posts Notification.Name("dp.didTapWeeklySummary")               │
└───────────────────────────┬───────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│  RootShellView (cold launch: .onAppear / warm: .task { for await })  │
│  reads pendingOpenInsights → selectedTab = .insights                 │
│  (D-04: no deep-link period pre-selection — Insights opens default)  │
└─────────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure
```
drinkpulse/
├── Services/
│   ├── WeeklySummaryService.swift        # new — mirrors ReminderService.swift shape
│   └── NotificationActionHandler.swift   # edited — add weekly-summary branch
├── Domain/
│   └── WeeklySummaryCalculator.swift     # new — pure, Sendable, no UI/persistence coupling
├── Features/
│   ├── Settings/Components/
│   │   └── WeeklySummarySection.swift    # new — mirrors ReminderSection.swift
│   └── Onboarding/Components/
│       └── HealthStep.swift              # edited — add weekly-summary toggle row
├── Features/Shell/
│   └── RootShellView.swift               # edited — schedule call + tap-routing to .insights tab
├── drinkpulseApp.swift                   # unchanged (delegate already wired; single shared handler)
└── DesignSystem/
    └── AppStorageKeys.swift              # edited — add new keys
```

### Pattern 1: Weekly `UNCalendarNotificationTrigger` (locale-aware)
**What:** A repeating notification trigger keyed to `weekday` instead of a
fixed date, driven by `Calendar.current.firstWeekday` so "first day of the
new week" tracks the device's Region setting (matching ENGG-03's "system
locale" wording) rather than a hardcoded Sunday/Monday.
**When to use:** Building `WeeklySummaryService.makeRequest`.
**Example:**
```swift
// Source: web tutorials (createwithswift.com, livsycode.com) + Apple
// UNCalendarNotificationTrigger docs (title/API surface confirmed;
// full doc body not fetchable — cross-checked against known UN framework
// behavior). [CITED — MEDIUM confidence, see Sources]
func makeRequest(calendar: Calendar = .current) -> UNNotificationRequest {
    var components = DateComponents()
    components.weekday = calendar.firstWeekday   // locale-aware "start of week"
    components.hour = 9
    components.minute = 0
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

    let content = UNMutableNotificationContent()
    content.title = String(localized: "weeklySummary.notification.title")
    content.body = bodyText   // computed by WeeklySummaryCalculator
    content.sound = .default

    return UNNotificationRequest(
        identifier: Self.weeklySummaryIdentifier,
        content: content,
        trigger: trigger
    )
}
```
**Important caveat:** `Calendar.current` is a *snapshot* — it does not track
a live Region-setting change (`Calendar.autoupdatingCurrent` does, but that
distinction matters only for a long-lived cached `Calendar` instance, not
for a value read fresh at schedule time). Because `scheduleIfEnabled()` is
re-invoked on every foreground (D-01), a snapshot read at schedule time is
sufficient — the trigger is rebuilt often enough to pick up a locale change
without needing `autoupdatingCurrent`. Recompute `calendar.firstWeekday`
fresh inside `makeRequest`, do not cache it at service-init time.

### Pattern 2: Pure percentage-change calculator (reuse Insights math, don't reuse the view model)
**What:** Extract the week-total/prev-week-total/trend-fraction arithmetic
that already exists in `InsightsViewModel` (lines 212–228) into a small,
`Sendable`, non-`@MainActor`-bound pure type that both `InsightsViewModel`
(optionally, as a later refactor — out of scope this phase) and the new
service can call. This phase only needs the *service* side to use it, but
building it as a free function/struct means it is trivially unit-testable
without an `@Observable` view model, `ModelContext`, or `UNUserNotificationCenter`.
**When to use:** Computing `WeeklySummaryService`'s notification body content.
**Example:**
```swift
// Domain/WeeklySummaryCalculator.swift — new, pure.
enum WeeklySummaryContent: Equatable {
    case skip                                   // ENGG-06: no prior week at all
    case directionOnly(SignDirection)            // ENGG-05: prior week = 0g
    case percentage(fraction: Double, direction: SignDirection) // ENGG-04
}

enum SignDirection: Equatable { case up, down, same }

enum WeeklySummaryCalculator {
    /// `hasAnyPriorWeekData`: true iff at least one ConsumptionEvent exists
    /// with consumptionDate < start of the current calendar week (see
    /// Open Questions → "first-ever week" detection query shape).
    static func content(
        currentWeekGrams: Double,
        priorWeekGrams: Double,
        hasAnyPriorWeekData: Bool
    ) -> WeeklySummaryContent {
        guard hasAnyPriorWeekData else { return .skip }
        guard priorWeekGrams > 0 else {
            // Directional-only: any current-week grams > 0 is "up" from zero;
            // exactly 0 vs 0 is "same" (both weeks sober).
            if currentWeekGrams > 0 { return .directionOnly(.up) }
            return .directionOnly(.same)
        }
        let fraction = (currentWeekGrams - priorWeekGrams) / priorWeekGrams
        if abs(fraction) <= 0.05 { return .percentage(fraction: fraction, direction: .same) }
        return .percentage(fraction: fraction, direction: fraction < 0 ? .down : .up)
    }
}
```
**Reuse note:** `currentWeekGrams`/`priorWeekGrams` should be computed with
`InsightsPeriod.dateRange(offset: 0, ...)` / `dateRange(offset: -1, ...)` and
`ConsumptionEvent.pureAlcoholGrams` (0.789 physical density) summed over
events in range — the *same* date-range primitive `InsightsViewModel` uses,
fetched directly via a SwiftData `FetchDescriptor` in the service (not
through the view model). This guarantees the notification and the Insights
screen's `TrendBadge` never disagree about which days count as "this week."

### Pattern 3: Settings section placement (D-07)
**What:** A new sibling `SettingsSection` inserted between `ReminderSection()`
(line 96) and `HealthSection()` (line 98) in `SettingsView.swift`.
**Example:**
```swift
// Source: Features/Settings/SettingsView.swift:96-98 (existing code)
ReminderSection()

WeeklySummarySection()   // new — inserted here per D-07

HealthSection()
```

### Pattern 4: Onboarding fold-in (D-05) — edit `HealthStep`, don't add a step
**What:** Add a second toggle row to the existing `HealthStep` view (step
3/4, `OnboardingViewModel.totalSteps` stays `4` — **do not increment it**).
Both toggles must stay behaviorally independent per D-06: flipping one must
never set the other's `@AppStorage` key.
**Example:**
```swift
// Features/Onboarding/Components/HealthStep.swift — add alongside the
// existing Health toggle VStack, as its own independent Toggle + hint block
// (not a shared binding). Each has its own @AppStorage, its own
// permissionDenied @State, and its own enable() function that calls the
// weekly-summary service's requestAuthorization() — NOT healthService's.
```

### Pattern 5: Tap-routing to Insights tab (D-03, D-04)
**What:** `NotificationActionHandler` needs a second identifier branch;
`RootShellView` needs to read a second pending-flag and set
`selectedTab = .insights` (no deep-link state — D-04).
**Example:**
```swift
// Services/NotificationActionHandler.swift — extend, don't replace
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
) async {
    let id = response.notification.request.identifier
    if id == ReminderService.reminderIdentifier {
        UserDefaults.standard.set(true, forKey: AppStorageKeys.pendingAddDrink)
        await MainActor.run { NotificationCenter.default.post(name: Self.didTapReminder, object: nil) }
    } else if id == WeeklySummaryService.weeklySummaryIdentifier {
        UserDefaults.standard.set(true, forKey: AppStorageKeys.pendingOpenInsights)
        await MainActor.run { NotificationCenter.default.post(name: Self.didTapWeeklySummary, object: nil) }
    }
}
```
```swift
// Features/Shell/RootShellView.swift — mirror the existing pendingAddDrink
// cold-launch (.onAppear) + warm-launch (.task { for await ... }) pair,
// but set `selectedTab = .insights` instead of `showAddDrink = true`.
```

### Anti-Patterns to Avoid
- **Computing the % change through `InsightsViewModel` from the service:**
  `InsightsViewModel` is `@MainActor @Observable` UI state (navigation
  offsets, chart caches) — instantiating one from a background-schedulable
  service to borrow `trendFraction` couples an unrelated UI concern into
  the notification pipeline and makes the calculation untestable in
  isolation. Use the pure `WeeklySummaryCalculator` (Pattern 2) instead.
- **Hardcoding `weekday = 1` (Sunday) for "first day of week":** Violates
  ENGG-03's "per system locale" requirement outright. Some regions
  (US) start Sunday, others (most of Europe) start Monday — must read
  `Calendar.current.firstWeekday`.
- **Reusing the ±1% "unchanged" threshold from `TrendBadge`:** That
  component's `isUnchanged = abs(fraction) <= 0.01` is a *display*
  convenience for the Insights hero card, not the same band as this
  phase's spec'd ±5% (ENGG-04). Reuse `TrendBadge`'s *formatting* idioms
  (icon/color-by-sign) if drafting UI copy elsewhere, but the ±5% band is
  new and belongs only in `WeeklySummaryCalculator`.
- **Sharing one `@AppStorage` permission-denied flag between Health,
  Reminder, and Weekly Summary sections:** Each existing section
  (`ReminderSection`, `HealthSection`) keeps its own local `@State
  permissionDenied` — even though all three ultimately hit the same
  OS-level `UNUserNotificationCenter`/`HKHealthStore` authorization
  dialog. Follow the same per-section local state, not a shared flag,
  or a denial in one section will incorrectly show as denied in another.
- **Introducing `BGTaskScheduler` "to keep content fresh":** Explicitly
  rejected by D-01/D-02. The notification firing with best-effort/stale
  content is an accepted tradeoff, not a defect to engineer around.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Locale-aware "start of week" | Custom weekday-offset math against a hardcoded Sunday/Monday convention | `Calendar.current.firstWeekday` (system-provided, respects Region setting) | Already the exact primitive `InsightsPeriod.dateRange(offset:)` relies on via `calendar.dateInterval(of: .weekOfYear, for:)` — reusing it keeps the notification and the Insights screen in agreement about week boundaries by construction |
| Notification permission/scheduling abstraction | A second bespoke `UNUserNotificationCenter` wrapper | The existing `NotificationScheduling` protocol + `UITestNotificationCenter` fake (`Services/NotificationScheduling.swift`, `Services/UITestNotificationCenter.swift`) | Both notification types (daily reminder, weekly summary) use identical `UNUserNotificationCenter` surface area (`requestAuthorization`, `add`, `removePendingRequests`) — a second protocol would be pure duplication |
| "Has the user logged anything before this week" query | An ad-hoc `@Query` sort+first-check scattered in a view | A single `FetchDescriptor<ConsumptionEvent>` with a predicate `consumptionDate < currentWeekStart` and `fetchLimit = 1`, used only inside `WeeklySummaryService`/`WeeklySummaryCalculator`'s call site | Centralizes the ENGG-06 "first-ever week" rule in one place instead of re-deriving it differently in the service vs. any future UI surface |

**Key insight:** This phase's entire job is *composition* of five already-shipped
patterns (services layer, settings card, onboarding toggle, tap-routing
delegate, locale-aware week math) plus one new pure calculator. The risk is
not "what library do I need" — there is none — it's correctly threading the
same `ConsumptionEvent.pureAlcoholGrams` / `Calendar.current.firstWeekday`
primitives through a new call site without silently diverging from how
Insights already defines "this week."

## Common Pitfalls

### Pitfall 1: Two independent `UNAuthorizationOptions` requests silently interact
**What goes wrong:** `ReminderSection.enable()`, `HealthStep`'s Health toggle,
and the new weekly-summary toggle all ultimately call
`center.requestAuthorization(options: [.alert, .sound])` against the *same*
OS-level per-app notification permission. If the user already granted (or
denied) notification permission via the daily reminder, a *second* call to
`requestAuthorization` for the weekly summary does not re-prompt — iOS
returns the existing grant/denial state immediately.
**Why it happens:** `UNUserNotificationCenter` authorization is per-app, not
per-feature; there is only one OS dialog, ever (per install, until reset in
Settings).
**How to avoid:** Design `WeeklySummaryService.requestAuthorization()` to
behave correctly whether or not the reminder already prompted: it should
still call `requestAuthorization(options:)` (idempotent, cheap, returns the
current state on a second call) and branch on the boolean result exactly
like `ReminderSection.enable()` does — never special-case "was already
granted by the other feature." D-06 is about keeping the *toggle state*
independent, not the underlying OS permission (which is inherently shared).
**Warning signs:** A test that asserts the weekly-summary toggle enabling
Health, or vice versa, would indicate the independence requirement was
violated; a manual test that grants reminder permission then finds the
weekly-summary toggle silently fails to prompt is *expected*, not a bug.

### Pitfall 2: `UNCalendarNotificationTrigger.nextTriggerDate()` cannot be unit-tested for "does it fire on the right absolute day" without care
**What goes wrong:** `UNCalendarNotificationTrigger` computes its next fire
date internally using the trigger's *own* `dateComponents.calendar`
(defaulting to the current calendar at construction time) — a naive test
that asserts on `trigger.nextTriggerDate()` can be flaky across CI machine
timezones/locales if the test doesn't pin a calendar.
**Why it happens:** The trigger is a thin wrapper; `nextTriggerDate()`
resolves against `Calendar.current` unless the `DateComponents` passed in
carries an explicit `.calendar`.
**How to avoid:** Test `makeRequest` the same way `ReminderServiceTests`
tests `makeRequest` today — assert on the *components themselves*
(`trigger?.dateComponents.weekday == expectedFirstWeekday`,
`.hour == 9`, `.minute == 0`, `.repeats == true`), not on
`nextTriggerDate()`. Inject a fixed `Calendar` (e.g.
`Calendar(identifier: .gregorian)` with a set `firstWeekday`) into
`makeRequest(calendar:)` so the test doesn't depend on the CI machine's
system locale.
**Warning signs:** A test that passes locally but fails in CI (different
default locale/timezone on the build machine) is the signature of this
pitfall.

### Pitfall 3: Divide-by-zero / near-zero prior-week guard must be exact, not "close to zero"
**What goes wrong:** `InsightsViewModel.trendFraction` already guards
`prevPeriodTotalGrams > 0` before dividing — but a naive port might use
`> 0.001` or similar epsilon "to be safe," which would silently mis-route a
genuinely-zero prior week (multiple decimal-precision events summing to a
tiny nonzero float, e.g. floating point drift) into the percentage branch
instead of ENGG-05's qualitative-only branch, or vice versa.
**Why it happens:** `pureAlcoholGrams` is a `Double` computed as
`volumeMl × quantity × abv × density` — for a logged event this is never
exactly `0.0` unless `abv == 0` or `volumeMl == 0` (both are valid domain
states, e.g. a logged non-alcoholic drink). Summing several such events is
exact IEEE-754 addition, not subject to meaningful drift at these
magnitudes, so `> 0` (strict, no epsilon) is the correct and safe guard —
matching what `InsightsViewModel` already does.
**How to avoid:** Use the exact same `guard priorWeekGrams > 0` structure
`InsightsViewModel.trendFraction` uses (line 226) — do not introduce a
different epsilon in the new calculator.
**Warning signs:** A logged 0.0% ABV drink (e.g. an alcohol-free beer) in
the prior week should NOT make `priorWeekGrams` nonzero and should still
route through the ENGG-05 qualitative path if it's the only prior-week
event — this is intentional per the "grams of pure alcohol" domain model.

### Pitfall 4: Onboarding health-permission and weekly-summary-permission requests both fire from the *same* step's "Done" tap path
**What goes wrong:** If a user toggles both the Health switch and the new
Weekly Summary switch on the same `HealthStep` screen, two separate
`async` authorization flows (`HealthKit` and `UserNotifications`) can be
in flight concurrently before "Done" is tapped. This is fine functionally
(they're independent frameworks) but a naive implementation that shares a
single `@State private var permissionDenied` between both toggles would
show the wrong denial state for whichever one didn't actually fail.
**Why it happens:** Copy-paste from `HealthStep`'s existing single-toggle
`@State` without duplicating it per-toggle.
**How to avoid:** Two independent `@State` vars (e.g. `healthPermissionDenied`,
`weeklySummaryPermissionDenied`), matching Pitfall 1's per-section
independence requirement.
**Warning signs:** Toggling only Weekly Summary and having it fail shows
the Health row's hint text change (or vice versa).

## Code Examples

### Reading `ConsumptionEvent`s for the current + prior week (SwiftData)
```swift
// Source: pattern from Features/Settings/Components/HealthSection.swift:138-143
// (fetchEvents()) — same FetchDescriptor idiom, sorted + optional-try pattern.
private func fetchEvents(in context: ModelContext, from start: Date, to end: Date) -> [ConsumptionEvent] {
    let descriptor = FetchDescriptor<ConsumptionEvent>(
        predicate: #Predicate { $0.consumptionDate >= start && $0.consumptionDate <= end },
        sortBy: [SortDescriptor(\.consumptionDate)]
    )
    return (try? context.fetch(descriptor)) ?? []
}
```

### "First-ever week" detection (ENGG-06) — recommended query shape
```swift
// Source: derived from CONTEXT.md "Claude's Discretion" recommendation +
// existing FetchDescriptor idiom above. [ASSUMED — needs planner/owner
// confirmation per CONTEXT.md, not explicitly locked]
private func hasAnyPriorWeekData(in context: ModelContext, before currentWeekStart: Date) -> Bool {
    var descriptor = FetchDescriptor<ConsumptionEvent>(
        predicate: #Predicate { $0.consumptionDate < currentWeekStart }
    )
    descriptor.fetchLimit = 1
    return ((try? context.fetchCount(descriptor)) ?? 0) > 0
}
```

### Weekly trigger with locale-aware weekday (full request)
```swift
// Source: Services/ReminderService.swift:48-64 (makeRequest shape),
// extended with `weekday` per Pattern 1 above. [CITED: web tutorials —
// see Sources]
func makeRequest(calendar: Calendar = .current) -> UNNotificationRequest {
    var components = DateComponents()
    components.weekday = calendar.firstWeekday
    components.hour = Self.fireHour     // 9
    components.minute = Self.fireMinute // 0
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

    let content = UNMutableNotificationContent()
    content.title = String(localized: "weeklySummary.notification.title")
    content.body = pendingBodyText
    content.sound = .default

    return UNNotificationRequest(
        identifier: Self.weeklySummaryIdentifier,
        content: content,
        trigger: trigger
    )
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| N/A — this is the first notification-content-computed-from-data feature in the codebase (the existing `ReminderService` notification body is static localized text, no dynamic content) | Content computed at schedule time (app-foreground), embedded into the `UNNotificationRequest.content.body` before scheduling | This phase | The notification body is "baked" at schedule time, not computed at fire time — there is no live extension/attachment mechanism in play (Notification Service Extension is out of scope; would be new infra, not mirrored by any existing pattern, and unnecessary given D-01/D-02 accept best-effort staleness) |

**Deprecated/outdated:** None relevant — `UNUserNotificationCenter` /
`UNCalendarNotificationTrigger` remain Apple's current (non-deprecated) API
for local notifications on iOS 26.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `UNCalendarNotificationTrigger` weekly repetition via a `weekday`-only `DateComponents` (with `repeats: true`) correctly recurs every 7 days at the matched weekday/hour/minute, without needing `weekOfYear` or an explicit recurrence interval | Architecture Patterns → Pattern 1, Code Examples | If wrong, the notification could fire on every matching weekday indefinitely without a 7-day floor, or could fail to repeat at all — this is Apple-documented behavior (title confirmed via WebFetch, full body not retrievable this session) and is corroborated by 3 independent web tutorials, so risk is low, but the planner should have the executor write the exact `ReminderServiceTests`-style component assertion test before trusting it (Pitfall 2) |
| A2 | `Calendar.current.firstWeekday` reflects the device's Region (System Settings) setting, not the app's own `Locale`/language setting, and is safe to read fresh per `scheduleIfEnabled()` call without needing `Calendar.autoupdatingCurrent` | Architecture Patterns → Pattern 1 | If the OS attaches `firstWeekday` to `Locale.current`'s *language* instead of Region, a French-language/US-region device could get the wrong "first day of week." Low risk — this is a decades-stable Foundation behavior and `InsightsPeriod` already relies on the same primitive family (`calendar.dateInterval(of: .weekOfYear, for:)`) for the exact same purpose, so any error would already affect the shipped Insights week view too |
| A3 | "First-ever week" detection (ENGG-06) should query for *any* `ConsumptionEvent` with `consumptionDate` before the start of the current calendar week — not "less than 7 days since the weekly-summary toggle was flipped on" | Code Examples → "First-ever week" detection; CONTEXT.md Claude's Discretion | This is explicitly flagged in CONTEXT.md as **not locked by the owner** — if the owner actually wants toggle-flip-relative detection instead, the plan/executor must revisit this query. Getting it wrong either wrongly skips a real week-over-week comparison for existing users (bad UX for the 36-shipped-plans-of-history user base) or wrongly fires a meaningless "first week" comparison for a genuinely new user |
| A4 | Permission-denied UX parity: the new Weekly Summary Settings section should reuse `ReminderSection`'s exact denied-state hint pattern (red footnote text + "Open Settings" `SettingsActionRow`) | Architecture Patterns → Pattern 5 note; CONTEXT.md Claude's Discretion | Also explicitly flagged as not owner-confirmed. Low risk if wrong — worst case is a slightly inconsistent (but still functional) denied-state UI that the owner asks to be redesigned later; does not affect correctness of any locked requirement |

**If this table is empty:** N/A — see above, 4 assumptions logged, two of
which (A3, A4) were already flagged by CONTEXT.md itself as
discussion-stopped/Claude's-discretion items and are surfaced here for the
planner to carry into task-level checkpoints (a `checkpoint:human-verify`
or explicit plan note is recommended for A3 given its correctness impact
on a locked requirement, ENGG-06).

## Open Questions

1. **Should `WeeklySummaryService` share a single `ModelContext`/fetch path
   with `WeeklySummaryCalculator`, or should the calculator remain
   `ModelContext`-agnostic (pure function over already-fetched `[Double]`
   or pre-summed totals)?**
   - What we know: `InsightsViewModel` computes sums itself from an
     injected `[ConsumptionEvent]` array (stateless w.r.t. persistence,
     per ADR-0004); the service, unlike a view, does have direct
     `ModelContext` access (it's not a SwiftUI view).
   - What's unclear: Whether the plan should have the service do its own
     `FetchDescriptor` calls (simplest, most testable if the fetch helper
     is separately injectable) or take a `ModelContext`/pre-fetched array
     as a parameter to `scheduleIfEnabled(context:)` for symmetry with how
     `HealthSection.runBackfill()` receives `modelContext` from the
     environment.
   - Recommendation: Keep `WeeklySummaryCalculator` a pure function over
     already-computed grams totals + a `hasAnyPriorWeekData: Bool` (as
     shown above) — this makes it trivially unit-testable with plain
     `Double` literals, no SwiftData mocking required. Let
     `WeeklySummaryService.scheduleIfEnabled(context:)` take a
     `ModelContext` parameter (called from `RootShellView`, which already
     has `@Environment(\.modelContext)` available via the app-level
     `.modelContainer` modifier — confirm the exact call site during
     planning) and do its own two `FetchDescriptor` calls internally.

2. **Exact copy for the notification title/body strings (D-08).**
   - What we know: Claude drafts them; must follow
     `String(localized:)` + `reminder.notification.title`/`.body` key
     naming convention (→ `weeklySummary.notification.title` /
     `.body...` variants for each of the three content branches:
     percentage-up, percentage-down, "about the same," direction-only-up,
     direction-only-same); neutral/factual tone; never call consumption
     "safe" (CLAUDE.md risk-language rule, same rule that drove D-15-era
     "Low/Moderate/High Risk" language elsewhere in the app per
     `feedback_risk_language` memory).
   - What's unclear: Whether the body should mention grams, or stay purely
     qualitative ("up 12% from last week" vs. "12% more than last week's
     total"); no owner wording was mandated.
   - Recommendation: Draft during planning/execution (not research) per
     D-08's explicit deferral; ensure `Localizable.xcstrings` gets new
     entries following the existing `reminder.*` / `onboarding.health.*`
     key-naming convention already in that file.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / `xcodebuild` | Build & test verification | ✓ | Xcode 26.6, Build 17F113 | — |
| iOS Simulator SDK ≥ 26 | Deployment target match (CLAUDE.md: min iOS 26) | ✓ | iOS 26.5 simulator SDK present (`iphonesimulator26.5`) | — |
| `UserNotifications` framework | Notification scheduling | ✓ | Bundled with iOS 26 SDK | — |
| SwiftData | Fetching `ConsumptionEvent`s for the % calculation | ✓ | Bundled with iOS 26 SDK; already used throughout the app | — |
| Swift Testing (`Testing` module) | New unit tests | ✓ | Bundled with Xcode 26.6; already used by `ReminderServiceTests.swift` | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Test`, `#expect`) — confirmed in use by `drinkpulseTests/Services/ReminderServiceTests.swift` |
| Config file | none — target-based (`drinkpulseTests`, file-system-synchronized group); no separate test config |
| Quick run command | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests/WeeklySummaryServiceTests -only-testing:drinkpulseTests/WeeklySummaryCalculatorTests` |
| Full suite command | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ENGG-01 | Settings toggle enable/disable, off by default | unit + UI | `xcodebuild test -only-testing:drinkpulseUITests/WeeklySummarySettingsUITests` | ❌ Wave 0 |
| ENGG-02 | Onboarding opt-in offered, takes effect immediately (mirrored in Settings) | unit + UI | `xcodebuild test -only-testing:drinkpulseUITests/OnboardingWeeklySummaryUITests` | ❌ Wave 0 |
| ENGG-03 | Fires first day of new week (system locale), 9am local, correct % computed | unit | `xcodebuild test -only-testing:drinkpulseTests/WeeklySummaryServiceTests -only-testing:drinkpulseTests/WeeklySummaryCalculatorTests` | ❌ Wave 0 |
| ENGG-04 | Body states %-change or "about the same" within ±5% | unit | `xcodebuild test -only-testing:drinkpulseTests/WeeklySummaryCalculatorTests` | ❌ Wave 0 |
| ENGG-05 | Zero-last-week → direction-only, no numbers | unit | `xcodebuild test -only-testing:drinkpulseTests/WeeklySummaryCalculatorTests` | ❌ Wave 0 |
| ENGG-06 | No prior week at all → notification skipped | unit | `xcodebuild test -only-testing:drinkpulseTests/WeeklySummaryServiceTests -only-testing:drinkpulseTests/WeeklySummaryCalculatorTests` | ❌ Wave 0 |
| ENGG-07 | Tap opens app (Insights tab, per D-03/D-04) | UI | `xcodebuild test -only-testing:drinkpulseUITests/WeeklySummaryTapUITests` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** targeted `-only-testing:` run for the file(s) touched
- **Per wave merge:** full `drinkpulseTests` + `drinkpulseUITests` suite
- **Phase gate:** Full suite green (build clean, zero warnings) before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `drinkpulseTests/Domain/WeeklySummaryCalculatorTests.swift` — covers ENGG-03/04/05/06 (pure calculator branches: percentage-up, percentage-down, ±5% "same" band boundary, zero-prior direction-only, skip-on-no-prior-data)
- [ ] `drinkpulseTests/Services/WeeklySummaryServiceTests.swift` — covers ENGG-03/06 at the service level (mirrors `ReminderServiceTests.swift`: `FakeNotificationCenter`, `makeRequest` component assertions, `scheduleIfEnabled` gating on `@AppStorage`, idempotent schedule/cancel)
- [ ] `drinkpulseUITests/Features/Settings/WeeklySummarySettingsUITests.swift` — covers ENGG-01 (mirrors `drinkpulseUITests/Features/Settings/ReminderSettingsUITests.swift`)
- [ ] `drinkpulseUITests/Features/Onboarding/OnboardingWeeklySummaryUITests.swift` — covers ENGG-02 (toggle in `HealthStep`, immediate Settings reflection)
- [ ] `drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift` — covers ENGG-07/D-03 (simulated tap → Insights tab selected); note per CLAUDE.md's UI-test locale-independence rule, assert on the app's own English `String(localized:)` content or a stable `accessibilityIdentifier` on the Insights tab, never system-process chrome
- [ ] No new `pytest`/framework install needed — Swift Testing is already the project's standard (`Testing` module ships with Xcode)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | no | App has no accounts (CLAUDE.md: "no account, ever") |
| V3 Session Management | no | N/A — single-device, no session concept |
| V4 Access Control | no | Single-user local app; no multi-tenant access boundary |
| V5 Input Validation | n/a (minimal) | No new user-text input in this phase; the notification body is app-computed, not user-entered. Existing `ConsumptionEvent` inputs already validated upstream (out of phase scope) |
| V6 Cryptography | no | No new secrets, tokens, or crypto operations introduced |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Health data (weekly consumption totals) leaking via notification banner content on the Lock Screen | Information Disclosure | This is an inherent tradeoff of *any* local notification showing derived health data (the existing daily reminder already has this property, though its body is static/non-data-bearing). CLAUDE.md's "no logging PII" rule applies to `OSLog`, not to the notification banner itself — the banner is user-facing UI, not a log. No mitigation is mandated by CLAUDE.md for notification banner content specifically, but the drafted copy (D-08, Open Question 2) should stay qualitative-leaning ("about the same," "up," "down") rather than exposing raw gram totals, both for the ENGG-05 spec and as a reasonable privacy-conscious default — flag this as a planning consideration, not a blocking requirement |
| Logging notification scheduling internals (fire time, content, computed percentage) via `OSLog` | Information Disclosure | Follow the exact same rule `ReminderService.scheduleIfEnabled()` already applies: log only the error *category* (`logger.error("Failed to reschedule weekly summary: \(error.localizedDescription)")`), never the computed percentage, never the fire date/time, never grams values — mirrors CLAUDE.md's "log identifiers, counts, enum cases, and error categories — not values" rule |
| Notification tap deep-link spoofing / unintended navigation from a stale/replayed notification identifier | Tampering (low relevance — local-only, no network) | N/A — all notification identifiers are locally generated and locally consumed; there is no server-issued payload to spoof. `NotificationActionHandler`'s `if id == ... else if id == ...` branch structure (Pattern 5) already inertly ignores unrecognized identifiers, which is the correct existing mitigation pattern to continue |

## Sources

### Primary (HIGH confidence)
- Direct codebase reads (this session): `Services/ReminderService.swift`,
  `Services/NotificationScheduling.swift`, `Services/UITestNotificationCenter.swift`,
  `Services/NotificationActionHandler.swift`, `Features/Insights/InsightsViewModel.swift`,
  `Features/Insights/InsightsPeriod.swift`, `Features/Insights/Components/InsightsHeroCard.swift`,
  `Features/Settings/Components/ReminderSection.swift`, `Features/Settings/Components/HealthSection.swift`,
  `Features/Settings/SettingsView.swift`, `Features/Onboarding/Components/HealthStep.swift`,
  `Features/Onboarding/OnboardingView.swift`, `Features/Onboarding/OnboardingViewModel.swift`,
  `Features/Shell/RootShellView.swift`, `drinkpulseApp.swift`, `Domain/ConsumptionEvent.swift`,
  `DesignSystem/AppStorageKeys.swift`, `drinkpulseTests/Services/ReminderServiceTests.swift` —
  all line numbers cited above are exact re-reads against the current working tree, not carried
  forward unverified from CONTEXT.md.
- `xcodebuild -version` / `xcodebuild -showsdks` (this session) — confirmed
  Xcode 26.6 / iOS 26.5 SDK installed and available.

### Secondary (MEDIUM confidence)
- WebSearch: "UNCalendarNotificationTrigger repeating weekly notification weekday component dateComponents"
  — corroborated by 3 independent tutorials (createwithswift.com, livsycode.com,
  hackingwithswift.com) plus an Apple Developer Forums thread; Apple's own
  documentation page title was confirmed present but its full body could not
  be fetched this session (JS-rendered page) — treated as CITED, not fully
  VERIFIED.
- WebSearch: "Swift Calendar.current firstWeekday determined by locale region setting"
  — corroborated by an Apple Developer Forums thread and a Medium article on
  Swift locale handling.

### Tertiary (LOW confidence)
- None used as load-bearing claims — the two WebSearch results above are the
  only non-codebase sources, and both are flagged MEDIUM/CITED, not treated
  as fully authoritative (see Assumptions Log A1/A2).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new dependencies; every framework already linked and in active use elsewhere in the codebase
- Architecture: HIGH — every pattern is a direct read of shipped, working code in this exact repository (not inferred from generic best practices)
- Pitfalls: MEDIUM — Pitfalls 1, 3, 4 are HIGH confidence (derived directly from reading the existing independent-toggle and divide-by-zero-guard code); Pitfall 2 (`UNCalendarNotificationTrigger` weekly-recurrence semantics) is MEDIUM, resting on corroborated-but-not-primary-source web tutorials (see A1)

**Research date:** 2026-07-20
**Valid until:** 2026-08-19 (30 days — this is Apple-platform-stable API surface + an internal-codebase-pattern-reuse phase, not a fast-moving external-dependency domain; no reason to expect drift sooner)
