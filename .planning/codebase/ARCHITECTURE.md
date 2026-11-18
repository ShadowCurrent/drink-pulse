---
last_mapped_commit: 8f0cefeb8c0f6f0169a34fe15b31dce3c8005d57
last_mapped_at: 2026-11-18
---
<!-- refreshed: 2026-11-18 -->
# Architecture

**Analysis Date:** 2026-11-18

## System Overview

```text
┌──────────────────────────────────────────────────────────────────────┐
│  drinkpulseApp  (`drinkpulse/drinkpulseApp.swift`)                   │
│  onboarding gate · ContainerLoadState · notification delegate        │
└───────────────┬──────────────────────────────┬───────────────────────┘
                │ onboardingDone == true        │ false
                ▼                               ▼
┌──────────────────────────────┐   ┌────────────────────────────────┐
│ RootShellView (TabView)      │   │ OnboardingView + VM            │
│ `Features/Shell/`            │   │ `Features/Onboarding/`         │
├──────┬──────────┬───────┬────┤   └────────────────────────────────┘
│Home  │Insights  │History│Set.│   Feature screens (View + VM + Components)
└──┬───┴────┬─────┴───┬───┴─┬──┘   `Features/Dashboard|Insights|History|Settings|AddDrink`
   │        │         │     │
   ▼        ▼         ▼     ▼
┌──────────────────────────────┐   ┌──────────────────────────────────┐
│ @Query (views read SwiftData)│   │ @Observable @MainActor VMs        │
│ modelContext (views mutate)  │──▶│ receive [ConsumptionEvent] etc.   │
└──────────────┬───────────────┘   └──────────────┬───────────────────┘
               │                                   │ pure calls
               ▼                                   ▼
┌──────────────────────────────┐   ┌──────────────────────────────────┐
│ Domain/ (@Model entities,    │   │ Domain/ pure types                │
│ Persistence, DataTransfer)   │   │ AlcoholUnit, GuidelineChoice,     │
│ `drinkpulse/Domain/`         │   │ WeeklySummaryCalculator, RiskLevel│
└──────────────┬───────────────┘   └──────────────────────────────────┘
               ▼
┌──────────────────────────────┐   ┌──────────────────────────────────┐
│ SwiftData ModelContainer     │   │ Services/ (protocol-wrapped       │
│ (on-device SQLite store)     │   │ platform capabilities):           │
│                              │   │ HealthService, ReminderService,   │
│                              │   │ WeeklySummaryService, notifications│
└──────────────────────────────┘   └──────────────────────────────────┘
```

## Pattern Overview

**Overall:** SwiftUI + SwiftData, MVVM-lite. Views own presentation state and query
persistence directly; a small set of `@Observable @MainActor` view models hold
non-trivial logic; pure-Swift domain types carry calculations; platform capabilities
sit behind protocols in `Services/`. No repository layer (ADR-0004 supersedes ADR-0003).

**Key Characteristics:**
- Single SwiftData `ModelContainer` injected at the app root with `.modelContainer(_:)`.
- Views read with `@Query` and mutate with `@Environment(\.modelContext)`.
- View models are stateless with respect to persistence: they receive plain values
  (`[ConsumptionEvent]`, `UserProfile?`) and never own a `ModelContext`.
- Unit of truth is grams of pure alcohol; every other measure is derived.
- Swift 6 strict concurrency; UI and persistence work on the main actor.
- Offline-first, on-device only. No backend, no network calls by the app itself.
- Lightweight manual DI through SwiftUI environment (`@Environment(\.healthService)`).

## Layers

**App entry and bootstrap:**
- Purpose: Choose between loading, startup error, onboarding and the main shell; build the container.
- Location: `drinkpulse/drinkpulseApp.swift`, `drinkpulse/Domain/Persistence/`
- Contains: `@main` `drinkpulseApp`, `ContainerLoadState`, `StartupError`, `StoreBootstrap`, `MigrationPlan`, `Schemas/SchemaV1-V4.swift`, `UserProfileStore`, `RecordDeduplicator`
- Depends on: `Domain/`, `Services/`, `Features/Shell`, `Features/Onboarding`, `Features/Shell/StartupErrorView.swift`
- Used by: The OS (scene lifecycle only)

**Features (presentation):**
- Purpose: One folder per user-facing feature; each holds the view, optional view model and feature-local components.
- Location: `drinkpulse/Features/<Feature>/`
- Contains: `*View.swift`, `*ViewModel.swift`, `Components/` subviews, feature-only helpers (e.g. `DrinkTypePreset+*.swift`, `InsightsViewModel+Charts.swift`)
- Depends on: `Domain/`, `DesignSystem/`, `Services/` (via environment or initializer), SwiftData `@Query`
- Used by: `RootShellView` tabs and sheets, `OnboardingView`

**Shell / navigation:**
- Purpose: Tab bar, add-drink sheet entry, scene-phase reactions, notification-driven routing.
- Location: `drinkpulse/Features/Shell/`
- Contains: `RootShellView.swift`, `AppTab.swift`, `StartupErrorView.swift`, `Components/`
- Depends on: All feature views, `ReminderService`, `WeeklySummaryService`, `AppStorageKeys`
- Used by: `drinkpulseApp`

**Design system:**
- Purpose: Tokens, shared components and modifiers. Visual decisions live here, not in features.
- Location: `drinkpulse/DesignSystem/`
- Contains: `DPColors.swift`, `DPSemanticColors.swift`, `DPBrand.swift`, `DPGlass.swift`, `DPMotion.swift` (Reduce Motion seam), `DPAdaptiveStack.swift`, `DPArcProgress.swift`, `DPLargeTitle.swift`, `RiskLevel+Color.swift`, `AppStorageKeys.swift`
- Depends on: SwiftUI only
- Used by: All features

**Domain:**
- Purpose: Entities, calculations, guideline rules, unit conversions, data transfer. Must stay free of UI.
- Location: `drinkpulse/Domain/`
- Contains: `@Model` entities (`ConsumptionEvent.swift`, `DrinkTemplate.swift`, `UserProfile.swift`); value types (`AlcoholUnit.swift`, `GuidelineChoice*.swift`, `GuidelineLimits.swift`, `RiskLevel.swift`, `UnitSystem*.swift`, `DrinkCategory.swift`, `Currency.swift`, `BiologicalSex.swift`); `WeeklySummaryCalculator.swift`; `DataTransfer/`; `Persistence/`
- Depends on: Foundation, SwiftData (entities only)
- Used by: Features, Services

**Services:**
- Purpose: Wrap a platform capability (notifications, HealthKit, file IO) behind a narrow protocol so view models and views depend on the abstraction.
- Location: `drinkpulse/Services/`
- Contains: `ReminderService.swift`, `WeeklySummaryService.swift`, `NotificationScheduling.swift`, `NotificationActionHandler.swift`, `HealthService.swift`, `HealthWriting.swift`, `HealthKitAdapter.swift`, `HealthWriteHooks.swift`, `HealthServiceEnvironment.swift`, `UITestHealthStore.swift`, `UITestNotificationCenter.swift`
- Depends on: UserNotifications, HealthKit, OSLog, Domain
- Used by: `RootShellView`, `drinkpulseApp`, Settings/AddDrink/History through environment or initializer injection. Governed by ADR-0008.

**Diagnostics:**
- Purpose: Dev-only instrumentation, `#if DEBUG`.
- Location: `drinkpulse/Diagnostics/ViewLoadLogger.swift`
- Used by: Feature screens' load timing; no user data logged.

## Data Flow

### Primary Request Path (log a drink)

1. Tap add button; `AddDrinkButton` sets `showAddDrink` in `RootShellView` (`drinkpulse/Features/Shell/RootShellView.swift`).
2. `AddDrinkView` presents the two-step flow: `DrinkTypeGridView` then `DrinkDetailInputView` (`drinkpulse/Features/AddDrink/`), using value-based `NavigationLink` and `navigationDestination(for:)`.
3. Detail view inserts a `ConsumptionEvent` through `@Environment(\.modelContext)` and dismisses via an explicitly passed `DismissAction`.
4. SwiftData persists to the on-device store; `@Query` in Dashboard, Insights and History re-renders.
5. Dashboard and Insights view models recompute aggregates from the injected `[ConsumptionEvent]` (`DashboardViewModel.swift`, `InsightsViewModel.swift`).

### Startup Path

1. `drinkpulseApp.init()` resets transient defaults, then assigns `UNUserNotificationCenter.current().delegate` synchronously (INT-01).
2. `.task { loadContainerIfNeeded() }` runs after first frame; `StoreBootstrap.makeContainer` opens or recovers the store off the `App.init` path (STARTUP-02/03).
3. `containerState` moves `.loading` → `.ready(container)` or `.failed(StartupError)` (`StartupErrorView` with Retry).
4. `.ready` branch shows `RootShellView` if `@AppStorage("dp_onboarding_done")` is true, else `OnboardingView`. `RecordDeduplicator.sweep` runs on the shell's `onAppear`.

### Notification Route Path

1. `NotificationActionHandler` (`UNUserNotificationCenterDelegate`) receives a tap in `didReceive`.
2. `static route(identifier:defaults:)` sets a pending flag for cold launch, or posts a tap notification for a warm app.
3. `RootShellView` consumes the flag or notification and switches tab or opens the add sheet.

### Health Write-Back Path (opt-in)

1. Save/update/remove of an event goes through `HealthWriteHooks`, gated on user opt-in.
2. `HealthService` serializes operations via `runSerial` and writes `dietaryAlcohol` samples through `HealthWriting` (`HealthKitAdapter` in production, `UITestHealthStore` in UI tests).
3. Device-local `healthKitUUID` is cached on the event and never synced or exported (ADR-0011).

### Data Transfer Path

1. Settings export builds `BackupExport` (events + optional profile), wrapped in `BackupDocument` (`FileDocument`) and handed to `.fileExporter`; encoding runs off the main actor in `fileWrapper`.
2. Import: `DataImporter` decodes `ExportBundle` v1 or v2, dedupes by `uuid`, upserts events/templates by LWW `modifiedDate`, and overwrites the profile in place. Typed `ImportError` surfaces to the UI.

**State Management:**
- View-owned: `@State private var`.
- Injected `@Observable` VM needing bindings: `@Bindable var`.
- App-wide: `@Observable` class via `@Environment` (`healthService` is the only one in code; no `AppLockState` exists yet).
- Persisted flags: `@AppStorage` keys centralized in `drinkpulse/DesignSystem/AppStorageKeys.swift`.

## Key Abstractions

**`ConsumptionEvent` / `DrinkTemplate` / `UserProfile`:**
- Purpose: SwiftData entities. Events carry a stable `uuid` and `modifiedDate` (LWW clock); templates and events stay separate so template edits never rewrite history.
- Examples: `drinkpulse/Domain/ConsumptionEvent.swift`, `drinkpulse/Domain/DrinkTemplate.swift`, `drinkpulse/Domain/UserProfile.swift`
- Pattern: `@Model final class`, CloudKit-safe shape (no `.unique`, defaulted properties), `touch()` on mutation.

**`GuidelineChoice` + `GuidelineLimits`:**
- Purpose: Country guideline selection and the thresholds derived from it. Limits are never stored.
- Examples: `drinkpulse/Domain/GuidelineChoice.swift`, `GuidelineChoice+Limits.swift`, `GuidelineLimits.swift`
- Pattern: Value types; `limits(for: BiologicalSex)` computes on demand.

**`AlcoholUnit` (density by display unit):**
- Purpose: Mass-of-alcohol conversion; display density differs by unit mode, physical density fixed at 0.789 (ADR-0005, ADR-0006).
- Examples: `drinkpulse/Domain/AlcoholUnit.swift`, `drinkpulse/Domain/UnitSystem+Volume.swift`
- Pattern: Pure functions and value types; hand-verified calculations.

**`ContainerLoadState`:**
- Purpose: Three-state gate that keeps UI from touching the store before it is ready.
- Examples: `drinkpulse/Domain/Persistence/ContainerLoadState.swift`

**Services (`ReminderService`, `WeeklySummaryService`, `HealthService`):**
- Purpose: Platform capabilities with injected protocol fakes for tests.
- Examples: `drinkpulse/Services/ReminderService.swift`, `drinkpulse/Services/HealthService.swift`
- Pattern: `@MainActor final class`, initializer injection with real adapter as default; lifecycle/cancel epochs guard in-flight schedules (ADR-0008).

**Versioned schema:**
- Purpose: Explicit migrations for persisted shape.
- Examples: `drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift` through `SchemaV4.swift`, `drinkpulse/Domain/Persistence/MigrationPlan.swift`
- Pattern: `SchemaMigrationPlan` with `schemas = [V1, V2, V3, V4]` and stages `v1ToV2`, `v2ToV3`, `v3ToV4`. V1–V3 frozen snapshots; shipped versions are never edited in place (ADR-0009).

## Entry Points

**App entry:**
- Location: `drinkpulse/drinkpulseApp.swift`
- Triggers: App launch, scene lifecycle.
- Responsibilities: Notification delegate assignment, container load, onboarding gate, color-scheme preference, environment injection of `healthService`.

**UI test entry:**
- Location: `drinkpulse/UITestSeed.swift`, `drinkpulse/UITestSeed+Fixtures.swift`
- Triggers: Launch argument `-dp_uitest` (and related flags such as `-dp_onboarding_done`, `-dp_uitest_warm_weekly_tap`).
- Responsibilities: In-memory container, fixture seeding, fake Health store and notification center. Never active in production paths.

**Tab roots:**
- `drinkpulse/Features/Dashboard/DashboardView.swift` (Home)
- `drinkpulse/Features/Insights/InsightsView.swift`
- `drinkpulse/Features/History/HistoryView.swift`
- `drinkpulse/Features/Settings/SettingsView.swift`

## Architectural Constraints

- **Threading:** Main-actor UI and SwiftData. View models and services are `@MainActor`. Heavy export encoding runs off main via `FileDocument.fileWrapper`. Structured concurrency (`async let`, `TaskGroup`) for async work.
- **Global state:** `UserDefaults` / `@AppStorage` keys (`AppStorageKeys.swift`); `drinkpulseApp` holds `NotificationActionHandler` as a stored property because `UNUserNotificationCenter` holds its delegate weakly; `UITestSeed` static flags.
- **Circular imports:** Not applicable (single Swift module). Keep `Domain/` free of `Features/` and `DesignSystem/` imports.
- **Persistence rule:** Change to any `@Model` shape requires a new `SchemaVN` plus a `MigrationStage`. Never amend a shipped schema (ADR-0009).
- **CloudKit forward-compat:** Model must stay CloudKit-safe even while sync is off. Current `ModelConfiguration` is local-only (`isStoredInMemoryOnly: false`, no `cloudKitDatabase`); container ID `iCloud.com.drinkpulse.app` is defined but unused in code (`StoreBootstrap.swift`). See Stale Docs below.
- **No repository layer:** Do not introduce one (ADR-0004).

## Anti-Patterns

### Storing derived values as primary data

**What happens:** Storing standard drinks, units or BAC on entities.
**Why it's wrong:** Violates the grams-as-truth rule and breaks unit toggles and HealthKit derivation.
**Do this instead:** Store grams-driving fields (`volumeMl`, `quantity`, ABV fraction) and derive in `Domain/` (`ConsumptionEvent.pureAlcoholGrams`).

### Editing a shipped `VersionedSchema` in place

**What happens:** Changing a property on `SchemaV4` (or any frozen snapshot) without bumping the version.
**Why it's wrong:** Schema hash changes; devices on that version hit "unknown model version" and store recovery moves data aside.
**Do this instead:** Freeze current shape as `SchemaV5`-style snapshot, add a stage in `MigrationPlan.swift`. See `Domain/Persistence/Schemas/`.

### Using `ObservableObject` / `@Published` / `@StateObject`

**What happens:** Legacy observation in a view or model.
**Why it's wrong:** Project standard is the Observation framework (ADR-0002).
**Do this instead:** `@Observable @MainActor final class` with `@State` / `@Bindable` / `@Environment`.

### Calling `ModelContext` inside a view model

**What happens:** A view model holds or fetches through a `ModelContext`.
**Why it's wrong:** Breaks the stateless-VM rule (ADR-0004) and makes tests depend on SwiftData.
**Do this instead:** Pass `[ConsumptionEvent]` into the VM from `@Query`; keep mutations in the view.

### Detached assignment of the notification delegate

**What happens:** Assigning `UNUserNotificationCenter.current().delegate` after `init()` returns.
**Why it's wrong:** A tap on a killed app can land on the wrong tab (INT-01).
**Do this instead:** Keep the synchronous assignment in `drinkpulseApp.init()`.

## Error Handling

**Strategy:** Typed errors surfaced to the user or logged by category. No silent swallow.

**Patterns:**
- Startup failures become `StartupError` and render `StartupErrorView` with Retry and Share Diagnostic Details; the app does not crash.
- Store open failure: `StoreBootstrap` moves store files to `Application Support/RecoveredStores/` (non-destructive), then reopens. Recovery trigger is broad (see Stale Docs).
- Import failures: typed `ImportError`, propagated to UI.
- Health and notification failures: logged via `os.Logger` (subsystem `com.drinkpulse.app`) without user values; features degrade gracefully when permission denied.

## Cross-Cutting Concerns

**Logging:** `os.Logger` with subsystem `com.drinkpulse.app` and per-area category (`startup`, `ReminderService`, ...). Privacy-marked interpolation; no drink or body data.

**Validation:** Value-type initializers and domain validators reject invalid input (e.g. ABV bounds, volume). Import validates bundle version.

**Authentication:** None for the app. Optional biometric app lock is planned (plan-0005); no account system.

**Accessibility and motion:** `DPMotion.animation(_:reduceMotion:)` is the single Reduce Motion seam; adaptive layout via `DPAdaptiveStack` (ADR-0013). Dynamic Type up to AX5.

## Stale or Contradicting Docs

Found while mapping. Surface before next task.

- `docs/architecture.md` "Sync" section says CloudKit is wired via `ModelConfiguration` with the container ID and that SwiftData default LWW resolves conflicts. Code: `StoreBootstrap.productionConfiguration` has no CloudKit configuration (sync OFF). ADR-0010 and plan-0023 say conflict resolution is app-level `uuid` + `modifiedDate` LWW plus `RecordDeduplicator`. Doc is wrong on both points.
- `docs/architecture.md` Shell entry says `RootShellView` is a "UserProfile guard". Code: the onboarding gate lives in `drinkpulseApp`; `RootShellView.swift` reads `onboardingDone` and fetches `UserProfile` (~line 155). Wording is loose; verify before relying on it.
- `docs/architecture.md` lists `Features/Settings/` as containing "data management"; `docs/architecture.md` also says the DI `@Entry` for dismiss was removed in Phase 09. Consistent with code, no action.
- ADR-0003 (repositories) is superseded by ADR-0004 but still listed as an active pattern in some sections of `docs/architecture.md`; the current text correctly states no repository layer.
- `.claude/context/current-focus.md` says DashboardView/Insights etc.; `docs/architecture.md` Folder layout omits `Features/Onboarding/` and `Features/Dashboard/Components/`. Layout doc is incomplete.
- Recovery trigger: `docs/architecture.md` says recovery fires on any open error. Matches code; flagged in open questions as a follow-up.

---

*Architecture analysis: 2026-11-18*
