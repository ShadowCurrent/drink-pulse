<!-- refreshed: 2026-07-18 -->
# Architecture

**Analysis Date:** 2026-07-18

## System Overview

DrinkPulse is a privacy-first, offline-first iOS alcohol tracking app built with SwiftUI and SwiftData. All logic runs on-device with no backend dependencies. CloudKit sync integration is built into the schema (ready but gated/OFF). The app uses MVVM with `@Observable` view models, strict concurrency (Swift 6), and lightweight manual dependency injection through SwiftUI environment values.

```text
┌──────────────────────────────────────────────────────────────────┐
│                        Views Layer                               │
│  (SwiftUI + @Query from SwiftData + @Environment injection)      │
│  ├── Shell (RootShellView, tab navigation)                       │
│  ├── Dashboard (home tab)                                        │
│  ├── AddDrink (flow with navigation stack)                       │
│  ├── History (calendar-based list)                               │
│  ├── Insights (analytics)                                        │
│  ├── Settings (profile, preferences)                             │
│  └── Onboarding (initial profile setup)                          │
└──────────────────────────────────────────────────────────────────┘
         │
         │ @State injection, onChange callbacks, modelContext
         │
┌──────────────────────────────────────────────────────────────────┐
│                   View Models Layer                              │
│         (@Observable @MainActor classes, stateless              │
│              w.r.t. persistence; receive injected data)          │
│  ├── DashboardViewModel                                          │
│  ├── AddDrink flow helpers                                       │
│  └── [Other feature VMs]                                         │
└──────────────────────────────────────────────────────────────────┘
         │
         │ Pure computed properties, business logic,
         │ no ModelContext ownership
         │
┌──────────────────────────────────────────────────────────────────┐
│          Domain Layer (Data + Logic)                             │
│         (SwiftData models + pure-Swift types)                    │
│  ├── ConsumptionEvent (drink log)                                │
│  ├── DrinkTemplate (drink preset)                                │
│  ├── UserProfile (user settings)                                 │
│  ├── AlcoholUnit, GuidelineChoice, UnitSystem (calculations)     │
│  └── DataTransfer (import/export)                                │
└──────────────────────────────────────────────────────────────────┘
         │
         │ SwiftData queries, mutations, migrations
         │
┌──────────────────────────────────────────────────────────────────┐
│       Services Layer (Platform Capabilities)                     │
│    (@MainActor classes wrapping protocols, best-effort)          │
│  ├── HealthService (Apple Health write-back)                     │
│  ├── ReminderService + NotificationScheduling (notifications)    │
│  └── UITest stubs (in-memory mocks for testing)                  │
└──────────────────────────────────────────────────────────────────┘
         │
         │ Local file I/O, Health framework, UserNotifications
         │
┌──────────────────────────────────────────────────────────────────┐
│                    SwiftData Store                               │
│  (Persistent on-disk via SQLite; CloudKit integration ready)     │
└──────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| **RootShellView** | Tab navigation gate; UserProfile guard; shared HealthService injection | `Features/Shell/RootShellView.swift` |
| **DashboardView** | Today's summary, progress, risk badge; injects events and profile into VM | `Features/Dashboard/DashboardView.swift` |
| **DashboardViewModel** | Aggregates (today/weekly/monthly grams), risk levels, streak counts, formatting | `Features/Dashboard/DashboardViewModel.swift` |
| **AddDrinkView** | Navigation stack for type grid → detail form; dismisses sheet on save | `Features/AddDrink/AddDrinkView.swift` |
| **DrinkDetailInputView** | Form: volume, ABV, quantity, date, notes, price; calls `modelContext.insert()` | `Features/AddDrink/DrinkDetailInputView.swift` |
| **HistoryView** | Calendar-based event list; mutation via context | `Features/History/HistoryView.swift` |
| **InsightsView** | Trends: area chart, weekday bars, sober days, spending | `Features/Insights/InsightsView.swift` |
| **SettingsView** | Profile editor, guideline selector, unit mode, data export/import | `Features/Settings/SettingsView.swift` |
| **OnboardingView** | Initial profile creation; sets `onboardingDone = true` on completion | `Features/Onboarding/OnboardingView.swift` |
| **DesignSystem** | Design tokens (colors, fonts), shared modifiers, reusable components | `DesignSystem/` (DPColors, DPBrand, etc.) |
| **ConsumptionEvent** | SwiftData model; calculates pure alcohol grams; holds identity (uuid, modifiedDate) | `Domain/ConsumptionEvent.swift` |
| **DrinkTemplate** | Reusable drink preset; immutable; new edits don't affect past events | `Domain/DrinkTemplate.swift` |
| **UserProfile** | Singleton user settings; swapped in/out via uniqueness enforcement | `Domain/UserProfile.swift` |
| **GuidelineChoice, AlcoholUnit** | Guideline engine; density calculation; limit derivation | `Domain/GuidelineChoice*.swift`, `Domain/AlcoholUnit.swift` |
| **StoreBootstrap** | ModelContainer creation; versioned schema + migration plan; recovery on corruption | `Domain/Persistence/StoreBootstrap.swift` |
| **HealthService** | Mirrors logged drinks to Apple Health; serialized per event; best-effort | `Services/HealthService.swift` |
| **ReminderService** | Schedules/cancels drink-log reminders via UserNotifications | `Services/ReminderService.swift` |
| **HealthKitAdapter** | Thin wrapper around `HKHealthStore` (real adapter) | `Services/HealthKitAdapter.swift` |
| **UITestHealthStore** | Non-prompting in-memory stub for UI tests (gate: `-dp_uitest` launch arg) | `Services/UITestHealthStore.swift` |
| **DataImporter, DrinkControlImporter** | Parse exported files or DrinkControl JSON; validate; insert records | `Domain/DataTransfer/` |

## Pattern Overview

**Overall:** MVVM with `@Observable` view models and direct SwiftData mutation. No repository layer; no custom coordinator/router; navigation via `NavigationStack` and `TabView`. Services wrap platform capabilities behind protocols for testability.

**Key Characteristics:**
- **On-device only**: No network calls except CloudKit sync (gated/OFF). Health data never leaves device.
- **Lightweight DI**: Manual injection via `@Environment` custom keys and `@Query` for SwiftData.
- **Best-effort services**: Health/reminder operations catch errors, log categories (never PII), never fail the main flow.
- **Schema-locked identity**: Record identity via `uuid` + `modifiedDate` LWW, not `@Attribute(.unique)`.

## Layers

### Views Layer
**Purpose:** Present data to the user; capture input; trigger mutations via `modelContext`.
**Location:** `Features/<Name>/`; larger features extract subviews into `Components/` subfolder.
**Contains:** SwiftUI `View` structs; local `@State` for presentation; `@Query` for data fetch.
**Depends on:** SwiftData models, view models, environment values (modelContext, custom services).
**Used by:** SwiftUI runtime.

**Key pattern:**
```swift
struct DashboardView: View {
    @State private var vm = DashboardViewModel()  // Owned by view
    @Query private var allEvents: [ConsumptionEvent]  // Direct fetch
    @Environment(\.modelContext) var modelContext
    
    var body: some View { ... }
    
    .onChange(of: allEvents, initial: true) {
        vm.events = allEvents  // Inject into VM
    }
}
```

### View Models Layer
**Purpose:** Stateless business logic; computed aggregates; formatting; not owning persistence.
**Location:** Alongside views in `Features/<Name>/`, typically `<Name>ViewModel.swift`.
**Contains:** `@Observable @MainActor final class`; computed properties; pure functions; no `ModelContext`.
**Depends on:** Plain values (arrays, optionals); domain types.
**Used by:** Views via `@State` injection.

**Key pattern:**
```swift
@Observable @MainActor final class DashboardViewModel {
    var events: [ConsumptionEvent] = []  // Injected from view
    var profile: UserProfile? = nil
    
    var todayGrams: Double {  // Computed, never stored
        events.filter { ... }.reduce(0) { ... }
    }
}
```

### Domain Layer
**Purpose:** Data models, calculations, guidelines, import/export logic.
**Location:** `Domain/` (top-level models), `Domain/DataTransfer/`, `Domain/Persistence/`.
**Contains:** SwiftData `@Model` classes; pure value types (enums, structs); calculation functions.
**Depends on:** Foundation, SwiftData.
**Used by:** Views, view models, services.

**Sub-directories:**
- **`DataTransfer/`**: Import/export, file parsing (DataImporter, DrinkControlImporter, BackupExport).
- **`Persistence/`**: StoreBootstrap, schema versions, migration stages, RecoveredStores recovery.

### Services Layer
**Purpose:** Wrap platform capabilities (notifications, Health, file I/O) behind protocols.
**Location:** `Services/`.
**Contains:** `@MainActor final class` service; `protocol` defining the capability; real adapter; optional test stub.
**Depends on:** Frameworks (UserNotifications, HealthKit, FileManager).
**Used by:** Views/view models; injected via environment.

**Pattern per ADR-0008:**
```swift
// Protocol abstraction
protocol HealthWriting: Sendable {
    func requestAuthorization() async throws -> Bool
    func write(_ event: ConsumptionEvent) async -> UUID?
}

// Real adapter (thin wrapper)
@MainActor final class HealthKitAdapter: HealthWriting { ... }

// Service (injects protocol)
@MainActor final class HealthService {
    private let store: HealthWriting  // Injected
    init(store: HealthWriting) { self.store = store }
}

// Production entry point
convenience init() {
    self.init(store: UITestSeed.isActive ? UITestHealthStore() : HealthKitAdapter())
}
```

### DesignSystem Layer
**Purpose:** Shared design tokens, components, modifiers.
**Location:** `DesignSystem/`.
**Contains:** `DPColors` (semantic colors), `DPBrand` (typography, spacing), reusable view modifiers.
**Depends on:** SwiftUI.
**Used by:** All features.

## Data Flow

### Primary Request Path (View → Mutation)

1. User taps "Add Drink" button → AddDrinkView sheet opens (`Features/Shell/RootShellView.swift:80`)
2. User selects drink type → DrinkTypeGridView navigates to DrinkDetailInputView (`Features/AddDrink/DrinkTypeGridView.swift`)
3. User fills form (volume, ABV, quantity, date, notes, price) → all in local `@State` (`Features/AddDrink/DrinkDetailInputView.swift:14-25`)
4. User taps "Save" → `DrinkDetailInputView.save()` runs (`DrinkDetailInputView+Logic.swift:76`):
   - Creates `ConsumptionEvent` from form state
   - Calls `modelContext.insert(event)` to add to SwiftData store
   - Calls `RecordDeduplicator.ensureUniqueIdentity(event, in: modelContext)` to prevent duplicates
   - Triggers `HealthWriteHooks.write(event, in: modelContext, using: healthService)` (best-effort write-back)
   - Calls `dismissSheet?.()` to close and return to shell
5. SwiftData context is auto-saved on @Query refresh or app backgrounding

**Why this flow:**
- Views own the context mutation (no repository layer per ADR-0004).
- View models compute read-only derived values (today's grams, risk level), never mutate.
- Health write-back happens after the in-app save, so if it fails, the drink is still logged locally.

### Query Refresh Path (Model → View)

1. DashboardView holds `@Query(sort: \ConsumptionEvent.consumptionDate, order: .reverse)` → SwiftData watches and re-fetches when context changes
2. onChange fires → injected into `vm.events`
3. `vm` computes derived values (today's grams, weekly risk, etc.)
4. View reads `vm.todayGrams` → SwiftUI observes `@Observable` VM property changes and re-renders
5. User sees updated dashboard

### Settings Profile Path

1. SettingsView fetches `@Query private var profiles: [UserProfile]` → always exactly one (singleton enforced by `UserProfileStore`)
2. User edits profile (guideline, unit mode, ABV precision) → calls `modelContext.insert(_:)` or updates properties directly
3. Context auto-saves
4. All observing views (`@Query`) re-fetch → DashboardViewModel re-computes with new limits/density/unit labels
5. Dashboard re-renders with new values

### Health Write-Back Path (Best-Effort)

1. `HealthWriteHooks.write(event, in: modelContext, using: healthService)` called after in-app insert/edit/delete
2. HealthService enqueues onto a per-event `uuid` serial chain (no races on the same event)
3. Runs async `healthService.write(event)` → HealthKitAdapter queries HKHealthStore for matching sample by `metadata["dp_event_uuid"]`
4. If found, updates sample; if not found, writes fresh and stamps `event.healthKitUUID` (device-local cache only)
5. Catches all errors, logs category only (not grams/dates/UUIDs), never throws into caller
6. On error: in-app record stays; Health just missed this sync — next edit or manual sync retries

### State Management

| Situation | Wrapper | Example |
|-----------|---------|---------|
| Local presentation (form input, sheet visibility) | `@State private var` | `@State var volumeMl: Double` in AddDrink form |
| Injected read-only model data | `let` | `let preset: DrinkTypePreset` (parameter passed to init) |
| SwiftData persistence | `@Query` | `@Query private var allEvents: [ConsumptionEvent]` |
| Derived read-only values | Computed property on VM | `var todayGrams: Double { ... }` in DashboardViewModel |
| Local form binding | `$state` | `TextField(..., text: $customNameText)` |
| Shared app-wide state | `@Observable` class via `@Environment` | `HealthService` via `@Environment(\.healthService)` |
| Environment system values | `@Environment` | `@Environment(\.dismiss) var dismiss` |

**Never use:** `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject` (Swift 6 uses `@Observable` instead).

## Key Abstractions

### ConsumptionEvent
**Purpose:** Single drink logged at a point in time; carries all log-time metadata (volume, ABV, quantity, date, notes, price, custom name).
**Examples:** `Domain/ConsumptionEvent.swift`
**Pattern:** SwiftData `@Model final class`. Immutable after creation (edits via re-creation + deletion of old). Includes `uuid` + `modifiedDate` for identity and LWW conflict resolution (plan-0023, ADR-0010).
**Key methods:**
- `alcoholGrams(density:)` → pure alcohol mass for the given density (display mode or physical 0.789)
- `pureAlcoholGrams` → always physical mass (calories, BAC)

### GuidelineChoice
**Purpose:** WHO or country-specific alcohol guideline (defines daily/weekly limits).
**Examples:** `Domain/GuidelineChoice.swift`, extensions in `GuidelineChoice+Limits.swift`, `GuidelineChoice+Display.swift`
**Pattern:** Enum with associated data; factory methods for localization. Drives `GuidelineLimits` (value type, computed fresh never stored).
**Key methods:**
- `effectiveLimits(weeklyGoalGrams:, for:)` → derives daily/weekly limits for sex and optional custom goal
- `displayName` → localized string (e.g., "WHO Guidelines")

### AlcoholUnit
**Purpose:** Display mode (standard drinks, UK units, grams); drives density for calculation and unit labels.
**Examples:** `Domain/AlcoholUnit.swift`, extensions
**Pattern:** Enum with three cases (`.standardDrinks`, `.units`, `.grams`). Density depends on unit *and* guideline (ADR-0005, plan-0029).
**Key methods:**
- `density(for: GuidelineChoice)` → mode density (e.g., 0.789 for standard drinks, 0.8 for UK units)
- `formattedValue(_:guideline:)` → human-readable string (e.g., "2.5 units")
- `unitLabel(for:)` → suffix ("units", "drinks", "g")

### RiskLevel
**Purpose:** Categorize consumption risk (low/safe, caution, exceeded).
**Examples:** `Domain/RiskLevel.swift`, `DesignSystem/RiskLevel+Color.swift`
**Pattern:** Enum. `from(pct:)` factory maps a fraction of limit to risk level (0–0.8 = safe, 0.8–1.0 = caution, >1.0 = exceeded).

### UnitSystem
**Purpose:** Regional measurement mode (metric, imperial) — drives serving/volume labels and breakpoints.
**Examples:** `Domain/UnitSystem.swift`, extensions
**Pattern:** Enum. Drives which `DrinkTypePreset.volumes` are shown; provenance field `ConsumptionEvent.enteredUnit` records which system was active at log time.

### DrinkTemplate
**Purpose:** Reusable drink preset (beer, wine, etc.); never edited retroactively (new edits create new template).
**Examples:** `Domain/DrinkTemplate.swift`, presets in `Features/AddDrink/DrinkTypePreset*.swift`
**Pattern:** SwiftData `@Model` with standard ABV range, icon, category. Associated `DrinkTypePreset` (pure struct, not stored) groups templates by category and provides default volumes/ABV values.

### UserProfile
**Purpose:** Singleton user settings (age, sex, body weight, guideline choice, unit mode, currency, ABV precision, reminders).
**Examples:** `Domain/UserProfile.swift`
**Pattern:** SwiftData `@Model` enforced as singleton by `UserProfileStore` (fetch-or-create + de-dup). Carries `modifiedDate` for LWW.

### HealthService + HealthWriting
**Purpose:** Abstract platform capability (Health framework) behind a protocol for testability.
**Examples:** `Services/HealthService.swift`, `Services/HealthKitAdapter.swift`, `Services/UITestHealthStore.swift`
**Pattern:** `HealthWriting` protocol defines surface; `HealthKitAdapter` is the real adapter (thin wrapper over HKHealthStore); `UITestHealthStore` is a non-prompting in-memory stub for UI tests. Service orchestrates logic (serialization per event, error handling, logging).

## Entry Points

### App Startup
**Location:** `drinkpulseApp.swift`
**Triggers:** App launch.
**Responsibilities:**
1. Check `@AppStorage("dp_onboarding_done")` flag.
2. If false, show `OnboardingView` (user creates profile first).
3. If true, open `RootShellView` (main tab interface).
4. Create shared `ModelContainer` via `StoreBootstrap.makeContainer()` (versioned schema + migration plan).
5. Create shared `HealthService()` instance; inject via `@Environment(\.healthService)`.
6. On `RootShellView.onAppear`, call `RecordDeduplicator.sweep()` (cross-device de-dup from backup imports or Phase B CloudKit).
7. Seed in-memory store with UI test fixtures if `-dp_uitest` launch arg is present.

### Shell/Tab Navigation
**Location:** `RootShellView` in `Features/Shell/`
**Triggers:** After onboarding.
**Responsibilities:**
1. `TabView` with value-based tabs (Liquid Glass iOS 26 tab bar).
2. Each tab wraps its feature in a `NavigationStack` for per-tab navigation.
3. Shared "Add Drink" button (toolbar item) that sets `showAddDrink = true`.
4. Guards `UserProfile` existence: if profile is missing (e.g., after data wipe), resets `onboardingDone = false` → return to onboarding.

### Dashboard (Home Tab)
**Location:** `Features/Dashboard/DashboardView.swift`
**Triggers:** When shell loads tab or user switches to home.
**Responsibilities:**
1. Query all `ConsumptionEvent` and `UserProfile` via `@Query`.
2. Inject into `DashboardViewModel` via onChange.
3. Display today's summary (grams, drinks, calories, spend), risk badge, week bar chart, streak counters, guideline alert (if exceeded).

### Add Drink Flow
**Location:** `Features/AddDrink/AddDrinkView.swift` → `DrinkTypeGridView.swift` → `DrinkDetailInputView.swift`
**Triggers:** When user taps "Add Drink" button.
**Responsibilities:**
1. `AddDrinkView` creates a `NavigationStack` with custom environment key `dismissSheet` for closing the sheet.
2. `DrinkTypeGridView` shows drink category grid; tap → navigate to `DrinkDetailInputView`.
3. `DrinkDetailInputView` shows form (volume, ABV, quantity, date, notes, price, custom name).
4. On save: create `ConsumptionEvent`, insert into context, de-dup, trigger Health write-back, dismiss.

### Onboarding
**Location:** `Features/Onboarding/OnboardingView.swift`
**Triggers:** When `onboardingDone = false`.
**Responsibilities:**
1. Collect user profile (age, sex, weight, guideline, unit mode).
2. Create singleton `UserProfile` and insert into context.
3. Call `onFinish` callback → sets `onboardingDone = true` → app navigates to shell.

## Architectural Constraints

- **Threading:** Single-threaded event loop (Main actor). All SwiftUI state mutations, model context operations, and service calls are `@MainActor`. Heavy queries can move to `@ModelActor` if needed (not currently used).
- **Global state:** One shared `HealthService` instance (held in `@State` in `drinkpulseApp`, injected via environment). `UserDefaults` used for onboarding gate and transient test state (via `AppStorageKeys`). No singletons otherwise; services are injected.
- **Circular imports:** None detected. Domain has no UI imports. Services import domain but not features. Features can import anything (domain, services, design system).
- **Persistence ownership:** Views own the `ModelContext` mutation via direct `@Environment(\.modelContext)` access. View models never own a context. SwiftData `@Query` handle the fetching; views perform inserts/updates/deletes directly.
- **Repository layer:** Explicitly absent (ADR-0004 superseded ADR-0003). Direct `@Query` + context mutation keeps code simpler and avoids unnecessary abstraction.
- **Network calls:** Prohibited except CloudKit sync (which is OFF and gated). All user data stays on-device. Health data is never uploaded.

## Anti-Patterns

### Storing Derived Values in the Model
**What happens:** A view model computes `weeklyGrams` and a temptation arises to persist it in the domain model (`ConsumptionEvent` or `UserProfile`).
**Why it's wrong:** Derived values rot. If the calculation logic changes (new guideline, density shift, unit mode switch), old stored values are stale and inconsistent. Recalculating on-read is cheap; maintaining consistency is not.
**Do this instead:** Compute all derived values in view models or domain services (pure functions). Never store them in SwiftData models. Example: `DashboardViewModel.todayGrams` is computed fresh every time from `events` array.

### View Models Owning ModelContext
**What happens:** A view model holds `@Environment(\.modelContext)` and calls `insert()` / `update()` directly.
**Why it's wrong:** It creates tight coupling between presentation logic and persistence. Testing becomes hard (need to mock ModelContext). The view model is supposed to be stateless w.r.t. persistence.
**Do this instead:** Views own the context and call service methods or mutate directly. View models receive plain data (`[ConsumptionEvent]`) and compute. See `DashboardViewModel`: no `modelContext` property, only injected `events` array.

### Using ObservableObject + @Published
**What happens:** Code written with `class ObservableViewModel: ObservableObject` + `@Published var events: [ConsumptionEvent]`.
**Why it's wrong:** Swift 6 strict concurrency requires `@Observable` and `@MainActor` isolation. `ObservableObject` is Combine-based, not concurrency-safe, and conflicts with the codebase's concurrency model.
**Do this instead:** Use `@Observable @MainActor final class ViewModel`. See `DashboardViewModel` for the pattern.

### Swallowing Errors Silently
**What happens:** Code has `try? someAsync()` or empty `catch {}` with no comment or logging.
**Why it's wrong:** Errors are signal. Silent swallowing hides bugs. Health operations are best-effort, but even then, a category-level log is needed for diagnosis.
**Do this instead:** Either handle meaningfully (e.g., retry, fall back to local-only) or log at least the error category and reason. See `HealthService.requestAuthorization()` — it catches, logs reason, returns false. Never leave error handling empty without a comment explaining why it's safe.

### Logging PII or Health Data
**What happens:** Code logs event contents: `logger.info("Added drink: \(event)")` or `logger.debug("Weight: \(profile.bodyWeightKg) kg")`.
**Why it's wrong:** Health data is sensitive. Logs can leak into system diagnostics or crash reports. Console logs are visible in Xcode; device logs can be accessed by MDM.
**Do this instead:** Log only identifiers, counts, or enum cases. Example: `logger.info("Event count: \(events.count)")` or `logger.debug("Risk level changed to \(riskLevel)")`. Never log `weight`, `date`, `notes`, `price`, or sample UUIDs. Use `privacy: .private` (the default for non-numeric) in string interpolation when in doubt.

## Error Handling

**Strategy:** Typed errors, meaningful handling, no silent swallows.

**Patterns:**

- **Domain errors** (import/export, validation): Typed enum (e.g., `ImportError`), surfaced to the user via modal or alert, user-facing message from `localizedDescription`.
- **Service errors** (Health, notifications): Caught, logged by category (no PII), method returns a flag or optional (e.g., `requestAuthorization() -> Bool`). Caller is never forced to handle; operation degrades gracefully (Health write fails → drink still logged locally).
- **SwiftData errors** (store corruption, migration): Non-destructive recovery via `StoreBootstrap.recoverStore()` — old files moved to timestamped `RecoveredStores/` folder, fresh store created. User sees no UI breakage; data is preserved for manual recovery if needed.

**Examples:**
- `DataImporter.importFromFile(_:into:)` throws `ImportError.invalidFormat` → caught by SettingsView, shown in an alert, user can try another file.
- `HealthService.write(_:)` async method catches HK errors internally, logs `logger.error("Health write failed...")`, returns early, caller continues.
- `StoreBootstrap.makeContainer()` catches `ModelContainer.init` failures, calls `recoverStore()`, retries — if recovery succeeds, user is unaffected.

## Cross-Cutting Concerns

**Logging:** `os.Logger` with stable subsystem `"com.drinkpulse.app"` and per-area `category` (e.g., "HealthService", "persistence"). No `print()` in production code. Never log PII/health data; mark numeric interpolations with `privacy: .public` (default is `.private` for non-numeric).

**Validation:** Inputs are validated at the point of use (e.g., ABV 0.0–1.0, volume > 0, weight > 0). `DrinkDetailInputView` bounds selectors (volume picker shows only valid options for the unit system). `DataImporter` validates JSON structure before inserting records.

**Authentication:** Not applicable — no login, no account, privacy-first. Health permission is requested at runtime via `HealthService.requestAuthorization()` (gated by settings toggle).

**Concurrency:** All `@Observable` view models are `@MainActor`. Async work in services (HealthService, file I/O) runs in background tasks that are serial per event UUID (no race conditions). SwiftData operations are on the main actor via `ModelContext`.

---

*Architecture analysis: 2026-07-18*
