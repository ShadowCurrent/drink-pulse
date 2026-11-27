---
last_mapped_commit: 19ce3159ee64540aaea8411fc85f24e6bea68714
last_mapped_at: 2026-11-27
---
<!-- refreshed: 2026-11-27 -->
# Architecture

**Analysis Date:** 2026-11-27

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│        `drinkpulse/drinkpulseApp.swift` (@main, scenes)      │
│        ModelContainer load, healthService env injection      │
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│     `Features/Shell/RootShellView.swift` (TabView shell)     │
│     Home · History · Insights · Settings · AddDrink sheet    │
│     onboarding cover (first run)                             │
└──────┬───────────────┬──────────────┬──────────────┬────────┘
       ▼               ▼              ▼              ▼
┌───────────┐  ┌──────────────┐ ┌────────────┐ ┌────────────┐
│ Dashboard │  │   History    │ │  Insights  │ │  Settings  │
│ `Features/│  │ `Features/   │ │ `Features/ │ │ `Features/ │
│ Dashboard`│  │ History`     │ │ Insights`  │ │ Settings`  │
└─────┬─────┘  └──────┬───────┘ └─────┬──────┘ └─────┬──────┘
      │ @Query + VM   │               │              │
      ▼               ▼               ▼              ▼
┌─────────────────────────────────────────────────────────────┐
│  `Domain/` — @Model types, pure calculations, guideline      │
│  engine, DataTransfer, Persistence (schemas, migrations)     │
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  SwiftData store (+ CloudKit container `iCloud.com.drinkpulse.app`)│
└─────────────────────────────────────────────────────────────┘

Side layer: `Services/` (HealthService, ReminderService,
WeeklySummaryService, NotificationActionHandler) wraps HealthKit and
UserNotifications behind protocols. `DesignSystem/` and `Diagnostics/`
are shared, cross-cutting.
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| App entry | Builds `ModelContainer`, loads it async, shows `StartupErrorView` on failure, injects `healthService` | `drinkpulse/drinkpulseApp.swift` |
| Container bootstrap | Store creation, CloudKit config, recovery of corrupt stores (max 3 snapshots) | `drinkpulse/Domain/Persistence/StoreBootstrap.swift` |
| Migration plan | Ordered `VersionedSchema` list V1 to V5 | `drinkpulse/Domain/Persistence/MigrationPlan.swift` |
| Tab shell | Tab selection, add-drink sheet, first-run onboarding cover, haptics, pending-action flags | `drinkpulse/Features/Shell/RootShellView.swift` |
| Today | Hero, tiles, limits, week chart; `@Observable` VM | `drinkpulse/Features/Dashboard/DashboardView.swift`, `DashboardViewModel.swift` |
| History | Events grouped by day; VM | `drinkpulse/Features/History/HistoryView.swift`, `HistoryViewModel.swift`, `EditEventView.swift` |
| Insights | Trends, area/weekday charts, health metrics; VM | `drinkpulse/Features/Insights/InsightsView.swift`, `InsightsViewModel.swift` |
| Add drink | Two-step log flow | `drinkpulse/Features/AddDrink/` |
| Onboarding | First-run flow; VM | `drinkpulse/Features/Onboarding/OnboardingViewModel.swift` |
| Settings | Profile, guideline, notifications, Health, data import/export | `drinkpulse/Features/Settings/` |
| Domain models | Canonical entities (grams of pure alcohol as unit of truth) | `drinkpulse/Domain/ConsumptionEvent.swift`, `DrinkTemplate.swift`, `UserProfile.swift` |
| Guideline engine | Limits per guideline and sex | `drinkpulse/Domain/GuidelineChoice+Limits.swift`, `GuidelineLimits.swift` |
| Data transfer | Export/import bundles and records | `drinkpulse/Domain/DataTransfer/` |
| Health service | HealthKit authorization and dietary alcohol write-back, `@MainActor` | `drinkpulse/Services/HealthService.swift` |
| Reminders | Notification scheduling behind `NotificationScheduling` protocol | `drinkpulse/Services/ReminderService.swift`, `NotificationScheduling.swift` |
| Design system | Tokens, cards, risk palette, motion, adaptive layout | `drinkpulse/DesignSystem/` |

## Pattern Overview

**Overall:** SwiftUI + SwiftData MVVM, with `@Query`-driven views, stateless `@Observable @MainActor` view models, and a protocol-wrapped Services layer. No repository layer (ADR-0004 supersedes ADR-0003).

**Key Characteristics:**
- Views read persistence via `@Query` and mutate via `@Environment(\.modelContext)`. Confirmed by `docs/decisions/0004-data-access-query-stateless-vm.md`.
- View models are `@Observable` (ADR-0002) and receive plain values (`[ConsumptionEvent]`, `UserProfile?`), never a `ModelContext`.
- Platform capabilities (HealthKit, UserNotifications) sit behind protocols (`HealthWriting`, `NotificationScheduling`) for injection and tests (ADR-0008).
- Swift 6 strict concurrency; UI and services are `@MainActor`.
- Offline-first, on-device only. Only network path is SwiftData CloudKit sync.

## Layers

**App / Shell:**
- Purpose: scene setup, container loading, tab navigation
- Location: `drinkpulse/drinkpulseApp.swift`, `drinkpulse/Features/Shell/`
- Contains: `@main` app, `RootShellView`, `AddDrinkToolbarItem`
- Depends on: Domain (schema), Services (HealthService), Features
- Used by: system (entry point only)

**Features:**
- Purpose: one folder per user flow
- Location: `drinkpulse/Features/<Name>/`
- Contains: `*View.swift`, `*ViewModel.swift`, feature-local `Components/`
- Depends on: Domain, Services (via environment), DesignSystem
- Used by: Shell

**Domain:**
- Purpose: models, calculations, guideline rules, persistence and migration, import/export
- Location: `drinkpulse/Domain/`
- Contains: `@Model` classes, value types (`AlcoholUnit`, `RiskLevel`, `UnitSystem`), `WeeklySummaryCalculator`, `AlcoholFreeDayRule`, `Persistence/Schemas/SchemaV1-4.swift`
- Depends on: Foundation, SwiftData only (no SwiftUI)
- Used by: Features, Services

**Services:**
- Purpose: wrap system frameworks behind protocols
- Location: `drinkpulse/Services/`
- Contains: `HealthService` + `HealthKitAdapter` + `HealthWriting`, `ReminderService` + `NotificationScheduling`, `WeeklySummaryService`, `NotificationActionHandler`, `UITestHealthStore`/`UITestNotificationCenter` (test doubles)
- Depends on: Domain, HealthKit, UserNotifications
- Used by: Features, App

**DesignSystem:**
- Purpose: shared tokens, components, modifiers
- Location: `drinkpulse/DesignSystem/`
- Contains: `Brand.swift`, `BrandCardStyle.swift`, `RiskLevel+Tone.swift`, `DPArcProgress.swift`, `DPMotion.swift`, `MetricTile.swift`
- Depends on: SwiftUI
- Used by: Features

**Diagnostics:**
- Purpose: dev-only instrumentation, compiled under `#if DEBUG`
- Location: `drinkpulse/Diagnostics/ViewLoadLogger.swift`

## Data Flow

### Primary Request Path (log a drink)

1. Tap add button, `AddDrinkToolbarItem` sets `showAddDrink` (`drinkpulse/Features/Shell/RootShellView.swift`)
2. Two-step flow in `drinkpulse/Features/AddDrink/` builds a `ConsumptionEvent` (grams = volume x quantity x ABV x density, `drinkpulse/Domain/ConsumptionEvent.swift`)
3. View inserts via `modelContext.insert`; `touch()` bumps `modifiedDate` (LWW contract, ADR-0010)
4. `@Query` in Dashboard/History re-renders; `HealthWriteHooks` may write dietary alcohol (`drinkpulse/Services/HealthWriteHooks.swift`, ADR-0011)

### App Launch

1. `drinkpulseApp.init` resets transient defaults, assigns `NotificationActionHandler` as delegate
2. `loadContainerIfNeeded` runs `StoreBootstrap.makeContainer` with `MigrationPlan` (`drinkpulse/Domain/Persistence/StoreBootstrap.swift`)
3. `ContainerLoadState` moves `.loading` to `.ready(container)` or `.failed(StartupError)`
4. `RootShellView` mounts with `.modelContainer(container)`; first run presents onboarding as cover (D0048-1)

### State Management

- Persistent state: SwiftData only (`@Model`)
- Preferences and flags: `@AppStorage` keys in `drinkpulse/DesignSystem/AppStorageKeys.swift`
- Transient UI state: `@State` in views; view models hold derived values only
- Custom environment values: `healthService`, `addDrink` (`AddDrinkAction`), `firstRunRevealed`, `numbersCountDown`

## Key Abstractions

**VersionedSchema snapshots:**
- Purpose: migration history; each shipped shape frozen
- Examples: `drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift` through `SchemaV5.swift`
- Pattern: `enum SchemaVN: VersionedSchema` with static `models`; `MigrationPlan.swift` lists stages (ADR-0009)

**Unit of truth (grams):**
- Purpose: all measures derived from pure-alcohol grams
- Examples: `drinkpulse/Domain/AlcoholUnit.swift`, `drinkpulse/Domain/ConsumptionEvent.swift`
- Pattern: density depends on display unit (ADR-0005, ADR-0006); physical mass uses 0.789

**Guideline choice:**
- Purpose: country/WHO limits, computed on the fly, never stored
- Examples: `drinkpulse/Domain/GuidelineChoice.swift`, `GuidelineChoice+Limits.swift`
- Pattern: `GuidelineChoice.limits(for: BiologicalSex)` returns value type `GuidelineLimits`

## Entry Points

**App entry:**
- Location: `drinkpulse/drinkpulseApp.swift`
- Triggers: launch, scene phases
- Responsibilities: container load, notification delegate, Health env injection

**Shell entry:**
- Location: `drinkpulse/Features/Shell/RootShellView.swift`
- Triggers: after container ready
- Responsibilities: tabs, add sheet, onboarding cover, scene-phase handling

**Test entries:**
- Unit: `drinkpulseTests/` (mirrors source tree)
- UI: `drinkpulseUITests/Features/` driven by launch args via `drinkpulse/UITestSeed.swift`

## Architectural Constraints

- **Threading:** main actor for UI, view models, and services; async/await for HealthKit work (`HealthService.runSerial`).
- **Global state:** `UserDefaults.standard` via `@AppStorage`; `UNUserNotificationCenter.current().delegate` set in app init (`drinkpulse/drinkpulseApp.swift`).
- **Circular imports:** Not detected (single module).
- **Schema drift risk:** `drinkpulseApp.swift` builds `Schema` from the three live models directly; `SchemaV5` points at the live models, while `SchemaV1` to `SchemaV4` are frozen snapshots. Keep both aligned when the model changes.
- **Live models are not frozen:** Any `@Model` change needs a new `SchemaVN` plus `MigrationStage` (ADR-0009).

## Anti-Patterns

### Repository layer reintroduced

**What happens:** Proposals to wrap `ModelContext` in a repository.
**Why it's wrong:** ADR-0003 was superseded by ADR-0004; the layer adds indirection with no payoff here.
**Do this instead:** Use `@Query` in views and `modelContext` for insert/delete, and keep view models stateless (`drinkpulse/Features/Dashboard/DashboardViewModel.swift` as reference).

### Amending a shipped schema

**What happens:** Editing a `SchemaVN` in place after release.
**Why it's wrong:** Changes its hash; devices report "Cannot use staged migration with an unknown model version".
**Do this instead:** Add `SchemaV(N+1)` and a `MigrationStage` in `drinkpulse/Domain/Persistence/MigrationPlan.swift`.

### Stored derived values

**What happens:** Persisting standard drinks, units, or BAC.
**Why it's wrong:** Violates grams-as-truth and drifts when density rules change.
**Do this instead:** Derive in `drinkpulse/Domain/` calculators at read time.

## Error Handling

**Strategy:** Typed errors, surfaced to the user or logged via `os.Logger`.

**Patterns:**
- Startup failures become `StartupError` and `StartupErrorView` with retry (`drinkpulse/Domain/Persistence/StartupError.swift`)
- Store corruption recovered by moving stores aside, keeping up to 3 snapshots (`StoreBootstrap.swift`)
- Import errors typed as `ImportError` (`drinkpulse/Domain/DataTransfer/ImportError.swift`)

## Cross-Cutting Concerns

**Logging:** `os.Logger`, subsystem `com.drinkpulse.app`, per-area category (e.g. `startup`, `persistence`, `Shell`). No `print` in production.
**Validation:** Domain validators and value-type initializers (`drinkpulse/Domain/`).
**Authentication:** Not applicable. No accounts; HealthKit and notification permissions are requested in-app.
**Accessibility:** Reduce Motion and Dynamic Type handled in `DesignSystem/` (`DPMotion.swift`, `DPAdaptiveStack.swift`).

---

*Architecture analysis: 2026-11-27*
