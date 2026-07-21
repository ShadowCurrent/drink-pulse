# Phase 1: Weekly Summary Notification - Pattern Map

**Mapped:** 2026-07-20
**Files analyzed:** 8 (new) + 5 (modified)
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Services/WeeklySummaryService.swift` (new) | service | request-response (schedule/cancel) | `Services/ReminderService.swift` | exact |
| `Domain/WeeklySummaryCalculator.swift` (new) | utility (pure calculator) | transform | `Features/Insights/InsightsViewModel.swift` (trend math, lines 212-228) | role-match (extraction target, not a service/model) |
| `Services/NotificationActionHandler.swift` (edit) | service (delegate) | event-driven | itself (existing branch structure) | exact |
| `Features/Settings/Components/WeeklySummarySection.swift` (new) | component | request-response (toggle → schedule) | `Features/Settings/Components/ReminderSection.swift` | exact |
| `Features/Onboarding/Components/HealthStep.swift` (edit) | component | request-response (toggle → auth) | itself; sub-pattern from same file's Health toggle block | exact |
| `Features/Shell/RootShellView.swift` (edit) | component (app shell) | event-driven | itself (existing `pendingAddDrink` cold/warm-launch pair) | exact |
| `DesignSystem/AppStorageKeys.swift` (edit) | config | CRUD (key constants) | itself (existing `reminder*` key block) | exact |
| `drinkpulseTests/Domain/WeeklySummaryCalculatorTests.swift` (new) | test | transform | (no direct calculator test exists yet — closest is `InsightsViewModel` logic, untested in isolation) | no analog (new pattern) |
| `drinkpulseTests/Services/WeeklySummaryServiceTests.swift` (new) | test | request-response | `drinkpulseTests/Services/ReminderServiceTests.swift` | exact |
| `drinkpulseUITests/Features/Settings/WeeklySummarySettingsUITests.swift` (new) | test | UI flow | `drinkpulseUITests/Features/Settings/ReminderSettingsUITests.swift` (referenced by RESEARCH.md; not read this pass — same section pattern as `ReminderSection`) | role-match |
| `drinkpulseUITests/Features/Onboarding/OnboardingWeeklySummaryUITests.swift` (new) | test | UI flow | existing onboarding UI test suite (not read; mirror `HealthStep` toggle test shape) | role-match |
| `drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift` (new) | test | UI flow | existing tap-routing UI test for reminder (not read; mirror `pendingAddDrink` assertion shape) | role-match |

## Pattern Assignments

### `Services/WeeklySummaryService.swift` (service, request-response)

**Analog:** `drinkpulse/Services/ReminderService.swift` (full file, 95 lines — read in one pass)

**Imports pattern** (lines 1-3):
```swift
import Foundation
import OSLog
import UserNotifications
```

**Class shape / stable identifier + defaults** (lines 12-24):
```swift
@MainActor
final class ReminderService {
    static let reminderIdentifier = "dp.daily.log.reminder"
    static let defaultHour = 21
    static let defaultMinute = 0

    private let center: NotificationScheduling
    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "ReminderService")
```
→ For `WeeklySummaryService`: `static let weeklySummaryIdentifier = "dp.weekly.summary"`, `static let fireHour = 9`, `static let fireMinute = 0`, same `center`/`defaults`/`logger` triple with category `"WeeklySummaryService"`.

**Injected-fake-friendly init + UI-test-safe center factory** (lines 26-39):
```swift
init(
    center: NotificationScheduling = ReminderService.defaultCenter(),
    defaults: UserDefaults = .standard
) {
    self.center = center
    self.defaults = defaults
}

nonisolated static func defaultCenter() -> NotificationScheduling {
    UITestSeed.isActive ? UITestNotificationCenter() : UNUserNotificationCenter.current()
}
```
Reuse verbatim (same `NotificationScheduling` / `UITestNotificationCenter` types — do not build a second abstraction, per RESEARCH.md Don't-Hand-Roll table).

**Auth pattern** (lines 42-44):
```swift
func requestAuthorization() async throws -> Bool {
    try await center.requestAuthorization(options: [.alert, .sound])
}
```

**Pure trigger factory** (lines 48-64) — extend with `weekday` per RESEARCH.md Pattern 1:
```swift
func makeRequest(hour: Int, minute: Int) -> UNNotificationRequest {
    var components = DateComponents()
    components.hour = hour
    components.minute = minute
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

    let content = UNMutableNotificationContent()
    content.title = String(localized: "reminder.notification.title")
    content.body = String(localized: "reminder.notification.body")
    content.sound = .default

    return UNNotificationRequest(
        identifier: Self.reminderIdentifier,
        content: content,
        trigger: trigger
    )
}
```
For `WeeklySummaryService.makeRequest(calendar:bodyText:)`, add `components.weekday = calendar.firstWeekday` and pass a computed `content.body` from `WeeklySummaryCalculator` output instead of a static string (see RESEARCH.md Code Examples for the exact extended shape).

**Idempotent schedule/cancel** (lines 69-77):
```swift
func schedule(hour: Int, minute: Int) async throws {
    center.removePendingRequests(withIdentifiers: [Self.reminderIdentifier])
    try await center.add(makeRequest(hour: hour, minute: minute))
}

func cancel() async {
    center.removePendingRequests(withIdentifiers: [Self.reminderIdentifier])
}
```
Remove-then-add is the idempotency mechanism — copy exactly (swap the identifier constant).

**Error-handling / best-effort pattern** (lines 82-93):
```swift
func scheduleIfEnabled() async {
    guard defaults.bool(forKey: AppStorageKeys.reminderEnabled) else { return }
    let hour = (defaults.object(forKey: AppStorageKeys.reminderHour) as? Int) ?? Self.defaultHour
    let minute = (defaults.object(forKey: AppStorageKeys.reminderMinute) as? Int) ?? Self.defaultMinute
    do {
        try await schedule(hour: hour, minute: minute)
    } catch {
        logger.error("Failed to reschedule reminder: \(error.localizedDescription)")
    }
}
```
Copy verbatim shape; `WeeklySummaryService.scheduleIfEnabled(context:)` additionally does the two `FetchDescriptor` reads (see next section) before calling `schedule`, and never logs the computed percentage or fire date — only `error.localizedDescription` category text (CLAUDE.md logging rule, explicitly re-flagged in RESEARCH.md Security Domain).

**SwiftData fetch idiom to reuse for current/prior week totals** — analog `Features/Settings/Components/HealthSection.swift:138-143` (per RESEARCH.md; not re-read here since RESEARCH.md already quotes the exact idiom verbatim):
```swift
private func fetchEvents(in context: ModelContext, from start: Date, to end: Date) -> [ConsumptionEvent] {
    let descriptor = FetchDescriptor<ConsumptionEvent>(
        predicate: #Predicate { $0.consumptionDate >= start && $0.consumptionDate <= end },
        sortBy: [SortDescriptor(\.consumptionDate)]
    )
    return (try? context.fetch(descriptor)) ?? []
}
```

**Week-boundary primitive to reuse (not reinvent)** — `Features/Insights/InsightsPeriod.swift` lines 40-51:
```swift
case .week:
    guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
        return now...now
    }
    guard let start = calendar.date(byAdding: .weekOfYear, value: offset, to: weekInterval.start) else {
        return now...now
    }
    let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
    let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
    return start...endOfDay
```
Call `InsightsPeriod.week.dateRange(offset: 0, now:, calendar:)` / `dateRange(offset: -1, ...)` directly from the service rather than re-deriving week boundaries — this is what guarantees the notification and Insights `TrendBadge` never disagree (RESEARCH.md Pattern 2 reuse note).

---

### `Domain/WeeklySummaryCalculator.swift` (utility, transform — new file, no direct analog)

**Analog (math to port, not the type itself):** `Features/Insights/InsightsViewModel.swift` lines 216-228:
```swift
var prevPeriodTotalGrams: Double {
    guard !isAllTime else { return 0 }
    let prevRange = period.dateRange(offset: activeOffset - 1, now: now, calendar: cal)
    return cal.days(in: prevRange).reduce(0) { $0 + gramsForNormalizedDay($1) }
}

var trendFraction: Double {
    guard prevPeriodTotalGrams > 0 else { return 0 }
    return (periodTotalGrams - prevPeriodTotalGrams) / prevPeriodTotalGrams
}
```
**Critical constraint (Pitfall 3, RESEARCH.md):** the `guard prevPeriodTotalGrams > 0` uses a **strict `> 0`, no epsilon** — port that guard exactly, do not introduce `> 0.001` or similar. This is the divide-by-zero guard that routes ENGG-05's zero-prior-week case.

**Do NOT instantiate `InsightsViewModel` from the service** — it is `@MainActor @Observable` UI state (chart caching, navigation offsets); extract only the arithmetic into a plain `enum`/`struct`, per RESEARCH.md's explicit Anti-Pattern. The new calculator is `Sendable`, non-`@MainActor`, and takes plain `Double`s + a `Bool` (see RESEARCH.md Architecture Patterns → Pattern 2 for the exact target shape: `WeeklySummaryCalculator.content(currentWeekGrams:priorWeekGrams:hasAnyPriorWeekData:) -> WeeklySummaryContent`).

---

### `Services/NotificationActionHandler.swift` (edit — add branch)

**Analog:** itself, full file (41 lines, read in one pass).

**Existing identifier + Notification.Name pattern** (lines 14-30):
```swift
final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {
    static let didTapReminder = Notification.Name("dp.didTapReminder")

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.notification.request.identifier == ReminderService.reminderIdentifier else {
            return
        }
        UserDefaults.standard.set(true, forKey: AppStorageKeys.pendingAddDrink)
        await MainActor.run {
            NotificationCenter.default.post(name: Self.didTapReminder, object: nil)
        }
    }
```
**Edit to:** replace the single `guard ... else { return }` with an `if/else if` branch structure (RESEARCH.md Pattern 5 shows the exact target shape — add `static let didTapWeeklySummary = Notification.Name("dp.didTapWeeklySummary")` and a second branch keyed on `WeeklySummaryService.weeklySummaryIdentifier` writing `AppStorageKeys.pendingOpenInsights`). Keep the existing `willPresent` override (lines 34-39) untouched — it already applies `.banner, .sound` to any notification, no per-id branching needed there.

---

### `Features/Settings/Components/WeeklySummarySection.swift` (component, new)

**Analog:** `Features/Settings/Components/ReminderSection.swift` (full file, 135 lines, read in one pass).

**Imports** (lines 1-2):
```swift
import OSLog
import SwiftUI
```

**State shape** (lines 10-17):
```swift
struct ReminderSection: View {
    @AppStorage(AppStorageKeys.reminderEnabled) private var enabled = false
    @AppStorage(AppStorageKeys.reminderHour) private var hour = ReminderService.defaultHour
    @AppStorage(AppStorageKeys.reminderMinute) private var minute = ReminderService.defaultMinute
    @State private var permissionDenied = false

    private let service = ReminderService()
    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "ReminderSection")
```
→ `WeeklySummarySection` drops the hour/minute `@AppStorage` (fixed 9am, no time picker per ENGG-03) and keeps only `@AppStorage(AppStorageKeys.weeklySummaryEnabled)` + its own local `permissionDenied` (Pitfall 1/4: never share this state with `ReminderSection`'s).

**Card body / toggle row + permission-denied hint** (lines 19-60):
```swift
var body: some View {
    SettingsSection("settings.section.reminders") {
        SettingsRow(String(localized: "settings.reminder.toggle")) {
            Toggle(isOn: toggleBinding) {
                Text(String(localized: "settings.reminder.toggle"))
            }
            .labelsHidden()
            .accessibilityLabel(String(localized: "settings.reminder.toggle"))
        }
        ...
        Divider()
        Text(String(localized: permissionDenied ? "settings.reminder.denied" : "settings.reminder.hint"))
            .font(.footnote)
            .foregroundStyle(permissionDenied ? Color.red : .secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)

        if permissionDenied {
            Divider()
            SettingsActionRow(
                title: String(localized: "settings.reminder.openSettings"),
                systemImage: "gearshape",
                trailingSystemImage: "arrow.up.right.square"
            ) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
}
```
Copy this shape with a new `SettingsSection("settings.section.weeklySummary")` title, drop the time-picker `if enabled { ... DatePicker ... }` block entirely (fixed 9am), keep the denied-state footer + `SettingsActionRow` block verbatim (A4 in RESEARCH.md — this parity is Claude's discretion but recommended).

**Toggle binding + enable() action** (lines 65-77, 99-115):
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
        guard granted else {
            enabled = false
            permissionDenied = true
            return
        }
        permissionDenied = false
        enabled = true
        try await service.schedule(hour: hour, minute: minute)
    } catch {
        enabled = false
        permissionDenied = true
        logger.error("Reminder enable failed: \(error.localizedDescription)")
    }
}
```
Same structure; `WeeklySummarySection.enable()` calls `service.schedule()` with no hour/minute params (or fixed constants) since ENGG-03 has no user-facing time picker.

**Settings placement (D-07)** — `Features/Settings/SettingsView.swift` lines 96-98:
```swift
ReminderSection()

HealthSection()
```
Insert `WeeklySummarySection()` between these two lines.

---

### `Features/Onboarding/Components/HealthStep.swift` (edit — add second toggle)

**Analog:** itself, full file (115 lines, read in one pass) — the existing Health toggle block is the template for the new Weekly Summary toggle block within the same view.

**State + toggle + hint block to duplicate (independently)** (lines 15-20, 38-51):
```swift
struct HealthStep: View {
    let onDone: () -> Void

    @AppStorage(AppStorageKeys.healthWriteEnabled) private var enabled = false
    @Environment(\.healthService) private var healthService
    @State private var permissionDenied = false
    ...
    VStack(spacing: 12) {
        Toggle(isOn: toggleBinding) {
            Text(String(localized: "onboarding.health.toggle"))
                .font(.body)
        }
        .accessibilityLabel(String(localized: "onboarding.health.toggle"))

        Text(String(localized: permissionDenied
                              ? "onboarding.health.denied"
                              : "onboarding.health.hint"))
            .font(.footnote)
            .foregroundStyle(permissionDenied ? Color.red : .secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(16)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    .padding(.horizontal, 24)
```
**Edit:** add a second, fully independent block (own `@AppStorage(AppStorageKeys.weeklySummaryEnabled)`, own `@State private var weeklySummaryPermissionDenied`, own `toggleBinding`-equivalent, own `enable()` calling `WeeklySummaryService().requestAuthorization()` — NOT `healthService`) right after this `VStack` (Pitfall 4: two independent `@State` vars, never shared).

**enable() action to mirror (swap the service call)** (lines 93-108):
```swift
private func enable() async {
    guard let healthService else {
        enabled = false
        return
    }
    _ = await healthService.requestAuthorization()
    switch healthService.authorizationStatus() {
    case .authorized:
        permissionDenied = false
        enabled = true
    case .denied, .notDetermined:
        enabled = false
        permissionDenied = true
    }
}
```
For weekly-summary: no `authorizationStatus()` switch exists on `WeeklySummaryService` (it mirrors `ReminderService.requestAuthorization() -> Bool`), so follow `ReminderSection.enable()`'s `guard granted else { ... }` shape instead (see above) rather than this switch-on-enum shape.

---

### `Features/Shell/RootShellView.swift` (edit — schedule call + tap routing)

**Analog:** itself, full file (132 lines, read in one pass).

**Scene-phase reschedule hook** (lines 98-100):
```swift
.onChange(of: scenePhase) { _, phase in
    if phase == .active { Task { await reminderService.scheduleIfEnabled() } }
}
```
Add a second `Task { await weeklySummaryService.scheduleIfEnabled(context: modelContext) }` alongside (needs `@Environment(\.modelContext) private var modelContext` — already implicitly available via the app-level `.modelContainer` per RESEARCH.md Open Question 1; confirm exact injection during planning).

**Warm-launch tap consumption** (lines 101-110):
```swift
.task {
    for await _ in NotificationCenter.default.notifications(
        named: NotificationActionHandler.didTapReminder
    ) {
        pendingAddDrink = false
        showAddDrink = true
    }
}
```
Add a second parallel `.task` (or a second `for await` loop in a `TaskGroup`) observing `NotificationActionHandler.didTapWeeklySummary`, setting `pendingOpenInsights = false; selectedTab = .insights` instead.

**Cold-launch pending-flag consumption** (lines 114-120):
```swift
private func openAddDrinkIfPending() {
    guard pendingAddDrink else { return }
    pendingAddDrink = false
    showAddDrink = true
}
```
Mirror with `openInsightsIfPending()` reading `AppStorageKeys.pendingOpenInsights`, setting `selectedTab = .insights`, called from the same `.onAppear { ... }` (line 97).

---

### `DesignSystem/AppStorageKeys.swift` (edit — add keys)

**Analog:** itself, full file (23 lines, read in one pass).

**Existing key-naming convention to follow** (lines 9-21):
```swift
// Log-reminder local notification (plan-0016).
static let reminderEnabled = "dp_reminder_enabled"
static let reminderHour = "dp_reminder_hour"
static let reminderMinute = "dp_reminder_minute"
static let pendingAddDrink = "dp_pending_add_drink"

static let healthWriteEnabled = "dp_health_write_enabled"
```
Add, with a comment block naming this phase:
```swift
static let weeklySummaryEnabled = "dp_weekly_summary_enabled"
static let pendingOpenInsights = "dp_pending_open_insights"
```
No hour/minute keys needed (fixed 9am, no user-facing time picker per ENGG-03/D-07 scope).

---

### `drinkpulseTests/Services/WeeklySummaryServiceTests.swift` (test, request-response)

**Analog:** `drinkpulseTests/Services/ReminderServiceTests.swift` lines 1-60 (read; file continues beyond but this covers the reusable `FakeNotificationCenter` + first test).

**Fake center to reuse as-is** (lines 10-38):
```swift
final class FakeNotificationCenter: NotificationScheduling, @unchecked Sendable {
    var authorizationResult = true
    var authorizationError: Error?
    var addError: Error?

    private(set) var authCallCount = 0
    private(set) var addedRequests: [UNNotificationRequest] = []
    private(set) var removedBatches: [[String]] = []
    private(set) var pendingIds: [String] = []

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        authCallCount += 1
        if let authorizationError { throw authorizationError }
        return authorizationResult
    }

    func add(_ request: UNNotificationRequest) async throws {
        if let addError { throw addError }
        addedRequests.append(request)
        pendingIds.append(request.identifier)
    }

    func pendingRequestIdentifiers() async -> [String] { pendingIds }

    func removePendingRequests(withIdentifiers ids: [String]) {
        removedBatches.append(ids)
        pendingIds.removeAll { ids.contains($0) }
    }
}
```
Reuse this exact type (it is already `internal` to the test target) — do not duplicate a second fake; both `ReminderServiceTests` and `WeeklySummaryServiceTests` can share it if moved to a common test-support file, or duplicate the class in the new file if project convention keeps fakes file-local (check for a shared `TestSupport/` folder before duplicating).

**Isolated-defaults + component-assertion test pattern** (lines 42-60):
```swift
@MainActor
struct ReminderServiceTests {
    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: "test.reminder.\(UUID().uuidString)")!
        return defaults
    }

    @Test func makeRequest_buildsRepeatingTrigger_atGivenHourMinute() {
        let service = ReminderService(center: FakeNotificationCenter(), defaults: makeDefaults())
        let request = service.makeRequest(hour: 21, minute: 0)

        let trigger = request.trigger as? UNCalendarNotificationTrigger
        #expect(trigger?.repeats == true)
        #expect(trigger?.dateComponents.hour == 21)
        #expect(trigger?.dateComponents.minute == 0)
```
Per Pitfall 2 (RESEARCH.md): assert on `trigger?.dateComponents.weekday`, `.hour`, `.minute`, `.repeats` — never `nextTriggerDate()` — and inject a fixed `Calendar(identifier: .gregorian)` with an explicit `firstWeekday` into `makeRequest(calendar:)` so the test is locale/CI-independent.

---

## Shared Patterns

### Services-layer shape (ADR-0008)
**Source:** `Services/ReminderService.swift` (whole file)
**Apply to:** `WeeklySummaryService.swift`
Stable identifier constant + pure `makeRequest` factory + idempotent `schedule()`/`cancel()` (remove-then-add) + `scheduleIfEnabled()` gated on `@AppStorage` + best-effort catch-log-never-throw. This is the single template for the entire service; do not deviate from its member ordering or error-handling shape.

### Notification tap-routing delegate
**Source:** `Services/NotificationActionHandler.swift` (whole file)
**Apply to:** `NotificationActionHandler.swift` (edit), `RootShellView.swift` (edit)
`if id == A { ... } else if id == B { ... }` branch structure, each branch: set a persisted `AppStorageKeys` flag (cold-launch survival) + post a `Notification.Name` (warm-launch). Unrecognized ids are silently ignored — do not add a `default`/`else` branch that logs or errors.

### Settings card pattern
**Source:** `Features/Settings/Components/ReminderSection.swift`
**Apply to:** `WeeklySummarySection.swift`
`SettingsSection(...)` wrapper containing `SettingsRow`s + `Divider()`s, a footnote hint (green/secondary vs red/denied), and a conditional `SettingsActionRow` "Open Settings" deep link when `permissionDenied`. Each section owns its own `@State private var permissionDenied` — never shared across sections (Pitfall 1).

### Onboarding opt-in toggle
**Source:** `Features/Onboarding/Components/HealthStep.swift` (Health toggle block)
**Apply to:** `HealthStep.swift` (edit, add Weekly Summary block)
`@AppStorage`-backed `Toggle` + inline hint `Text` that swaps color/copy on denial + an `enable()` async function that requests authorization and flips state back off on denial without blocking the "Done" button. Each toggle's state (`@AppStorage` key + `@State permissionDenied`) is fully independent (D-06, Pitfall 4).

### Week-boundary math (locale-aware)
**Source:** `Features/Insights/InsightsPeriod.swift` lines 40-51 (`dateRange`), and `Calendar.current.firstWeekday` for the notification trigger's `weekday` component
**Apply to:** `WeeklySummaryService.makeRequest`, `WeeklySummaryService.scheduleIfEnabled` (fetch ranges)
Never hardcode `weekday = 1` (Sunday). Always derive from `calendar.firstWeekday` / `calendar.dateInterval(of: .weekOfYear, for:)`, read fresh at call time (not cached at init), so the notification and the Insights screen's week boundary agree by construction.

### Divide-by-zero guard (exact, no epsilon)
**Source:** `Features/Insights/InsightsViewModel.swift` line 226 (`guard prevPeriodTotalGrams > 0`)
**Apply to:** `WeeklySummaryCalculator.content`
Strict `> 0`, no epsilon — this is the same domain-correctness rule for ENGG-05's zero-prior-week qualitative branch.

### Logging discipline
**Source:** `Services/ReminderService.swift` line 91 (`logger.error("Failed to reschedule reminder: \(error.localizedDescription)")`)
**Apply to:** all new/edited service and view files
Log only the error category string, never computed percentages, grams, or fire dates/times (CLAUDE.md + RESEARCH.md Security Domain).

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `drinkpulseTests/Domain/WeeklySummaryCalculatorTests.swift` | test | transform | No existing test isolates the week-over-week % arithmetic as a pure function — `InsightsViewModel`'s `trendFraction` is only exercised indirectly through the view model's other `@Observable` state today. Use RESEARCH.md's Architecture Patterns → Pattern 2 target shape (`WeeklySummaryCalculator.content(currentWeekGrams:priorWeekGrams:hasAnyPriorWeekData:)`) as the spec to test against; write plain `@Test`/`#expect` cases per branch (percentage-up/down, ±5% same-band boundary, zero-prior direction-only, skip-on-no-prior-data). |

## Metadata

**Analog search scope:** `Services/`, `Features/Settings/Components/`, `Features/Onboarding/Components/`, `Features/Insights/`, `Features/Shell/`, `DesignSystem/`, `drinkpulseTests/Services/`
**Files scanned:** 8 read in full this pass (`ReminderService.swift`, `NotificationActionHandler.swift`, `ReminderSection.swift`, `InsightsViewModel.swift` [targeted range], `HealthStep.swift`, `AppStorageKeys.swift`, `RootShellView.swift`, `InsightsPeriod.swift` [targeted range], `ReminderServiceTests.swift` [targeted range], `SettingsView.swift` [targeted range]) — all identified directly from CONTEXT.md's "Reusable Assets" list and RESEARCH.md's "Sources → Primary" list, cross-verified against the current working tree (no stale line numbers carried forward unchecked).
**Pattern extraction date:** 2026-07-20
