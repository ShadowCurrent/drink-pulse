# Architecture

## Overview

DrinkPulse is a SwiftUI + SwiftData iOS app. All logic runs on-device;
CloudKit sync is layered on top of SwiftData without any custom backend.

## Folder layout

```
drinkpulse/
├── Domain/                   # SwiftData models + pure-Swift domain types
├── Features/
│   ├── Shell/                # RootShellView — tab bar, UserProfile guard
│   ├── Dashboard/            # Home tab: today's summary, progress
│   ├── AddDrink/             # Two-step log-a-drink flow
│   ├── History/              # Past events grouped by day
│   ├── Insights/             # Trends tab: area chart, weekday bars, health metrics
│   └── Settings/             # User profile, guidelines, preferences, data management
├── Services/                 # Platform-capability wrappers behind protocols (notifications, …)
├── DesignSystem/             # Tokens, shared components, modifiers
└── drinkpulseApp.swift       # App entry point, ModelContainer setup, onboarding gate
```

Each feature folder contains: `*View.swift`, `*ViewModel.swift` (when needed),
and feature-local subviews. Larger views extract sub-views into a `Components/`
subfolder (e.g. `Features/Dashboard/Components/`).

## MVVM

- **Views** own presentation state (`@State`) and query SwiftData via `@Query`.
  Simple mutations (insert, delete) happen directly through `@Environment(\.modelContext)`.
- **View models** are `@Observable final class` marked `@MainActor`.
  They hold business logic that doesn't fit in a view body — computed aggregates,
  risk calculations, chart data. View models receive `[ConsumptionEvent]` and
  `UserProfile?` as plain injected values; they do not own a `ModelContext`.
- **Domain models** (`@Model final class`) are SwiftData entities only.
  No UI logic or formatting lives there.

## Services layer

`Services/` holds **platform-capability wrappers** — types that mediate a
system framework (notifications, Health, file IO) that is neither domain
data, a view model, nor a view. Each capability is exposed through a narrow
**protocol**; the real framework conformance is a thin adapter, and the
service (`@MainActor final class`) takes the protocol via initializer
injection (defaulting to the real adapter) so it is unit-testable with an
injected fake — no real prompt or scheduled item in tests. Services are
**not** data access (no `ModelContext`; reads stay on `@Query` per ADR-0004).
See [ADR-0008](decisions/0008-services-layer.md). First member:
`ReminderService` (+ `NotificationScheduling`).

## State management

| Situation | Wrapper |
|-----------|---------|
| View-owned local state | `@State private var` |
| Injected `@Observable` VM needing bindings | `@Bindable var` |
| Read-only injected value | `let` |
| Shared app-wide state | `@Observable` class via `@Environment` (e.g. `AppLockState`) |

**Never use** `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`.

## Navigation

- Root gate: `drinkpulseApp` checks `@AppStorage("dp_onboarding_done")`. When `true`,
  shows `RootShellView`; when `false`, shows `OnboardingView`.
- `RootShellView` — `TabView` with `Tab {}` value-based syntax (Liquid Glass tab bar
  on iOS 26). Houses all four main tabs
  and the Add Drink sheet. It also guards `UserProfile` existence: if the store is empty
  (e.g. after a data wipe or a failed migration), it resets `onboardingDone = false`,
  sending the user back to onboarding to recreate their profile cleanly.
- Per-tab: `NavigationStack`. Currently only the AddDrink flow uses value-based
  `NavigationLink(value:)` + `.navigationDestination(for:)` (grid → detail step).
  Dashboard, History, and Settings use `NavigationStack` for the title bar only.
- Modals: `.sheet(isPresented:)` for "create new" flows;
  `.sheet(item:)` for model-driven sheets.
- Sheets own their dismiss via `@Environment(\.dismiss)`.
  When a pushed destination inside a sheet needs to dismiss the whole sheet,
  inject a `dismissSheet` closure via a custom `@Entry` environment value.

## Dependency injection

Lightweight manual DI through SwiftUI environment values:
- SwiftData `ModelContext` via `@Environment(\.modelContext)` (provided by `.modelContainer()`).
- Custom closures or services injected via `@Entry` custom environment keys when a child
  view needs to trigger an action owned by an ancestor (e.g. `dismissSheet` in AddDrink).
- No third-party DI framework.

## Concurrency

Swift 6 strict concurrency is enabled.
- All `@Observable` view models are `@MainActor`.
- Async work uses structured concurrency (`async let`, `TaskGroup`).
- SwiftData operations happen on the main actor via `ModelContext`.
  Heavy queries can move to a `@ModelActor` when needed.

## Persistence bootstrap

`Domain/Persistence/StoreBootstrap.swift` owns the `ModelContainer` creation:

- **Versioned schema + migration plan**: the container is governed by an explicit
  `SchemaV1` (`VersionedSchema`, `Schema.Version(1, 0, 0)`, models =
  `[DrinkTemplate, ConsumptionEvent, UserProfile]`) and a `MigrationPlan`
  (`SchemaMigrationPlan`, `schemas = [SchemaV1]`, `stages = []`) under
  `Domain/Persistence/`. `MigrationPlan.self` is passed to every
  `ModelContainer` construction path — `StoreBootstrap.makeContainer` (both the
  initial attempt and the post-recovery retry) and `UITestSeed.makeContainer`;
  `drinkpulseApp` is unchanged because it routes through `StoreBootstrap`. V1 is
  the baseline (no stage yet); it absorbs the prior implicit lightweight
  migrations and makes the schema explicitly versioned so future evolution adds a
  `MigrationStage` rather than introducing the concept. See
  [ADR-0009](decisions/0009-versioned-schema-and-migration-plan.md).
- **Snapshot-on-divergence rule**: `SchemaV1.models` references the **live**
  `@Model` classes (no duplication today). The first schema that diverges from V1
  must first freeze V1 — copy the then-current model definitions into a
  self-contained `SchemaV1` namespace — **before** editing the live classes as
  `SchemaV2`. The discipline lives at the moment of divergence; ADR-0009 records it.
- **Non-destructive recovery**: if `ModelContainer.init` fails (genuine store
  corruption), the existing `.sqlite` / `-wal` / `-shm` files are **moved** (not
  deleted) to a timestamped folder in `Application Support/RecoveredStores/`. A
  fresh container is then created. At most 3 snapshots are retained; older ones
  are trimmed. With the migration plan in place, `RecoveredStores/` recovery is
  now strictly the **genuine-corruption last resort** — it is no longer the
  schema-evolution mechanism, and should not fire on a *planned* schema change.
- `clearRecoveredStores()` is called by "Delete all data" so the destructive
  action is complete and predictable.
- `drinkpulseApp.swift` delegates to `StoreBootstrap.makeContainer` (`@MainActor`).
- The versioned-schema + `SchemaMigrationPlan` **foundation now exists** (plan-0035).
  The remaining CloudKit-compat `SchemaV2` + V1→V2 `MigrationStage` (drop
  `@Attribute(.unique)`, defaults on every attribute, app-level singleton
  enforcement, removing the deprecated `name`) lands in plan-0023.

## Data transfer (backup / restore)

`Domain/DataTransfer/` contains the manual JSON backup/restore layer:

- `ExportBundle` — versioned container (`version: Int`). **v1**: events only.
  **v2**: events + optional `ProfileRecord`. Import must support both versions;
  future unknown versions throw `ImportError.unsupportedVersion`.
- `ProfileRecord` — `Codable` mirror of `UserProfile`'s stored fields (no SwiftData
  dependency). Deserialized and applied to the live profile via `apply(to:)`.
- `BackupExport` — snapshot of events + optional profile. Mapping to value
  records is cheap and eager; the JSON encode is deferred to `encoded()`.
- `BackupDocument` — `FileDocument` wrapping a `BackupExport`, used by the
  Settings export row via SwiftUI's `.fileExporter`. `fileWrapper` calls
  `encoded()` and SwiftUI runs it **off the main actor** when the user picks a
  save destination, so the export tap never blocks the UI and full history hits
  disk only on an actual save. `.fileExporter`'s `onCompletion` gives a real
  success/failure result, which drives the "Export complete" confirmation
  (`ShareLink` offers no such callback). Pure SwiftUI — no UIKit.
- `DataImporter` — decodes v1 or v2 bundles, deduplicates events, and upserts the
  profile (overwrite-in-place if one exists, insert if none). Typed `ImportError`
  cases are propagated to the UI — no silent swallowing.

## Sync

CloudKit integration is handled entirely by SwiftData's built-in
`ModelConfiguration` with CloudKit container ID. No custom sync code.
Conflict resolution is left to SwiftData's default last-write-wins.
