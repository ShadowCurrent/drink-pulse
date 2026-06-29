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
See [ADR-0008](decisions/0008-services-layer.md). Members: `ReminderService`
(+ `NotificationScheduling`); `HealthService` (+ `HealthWriting`,
`HKHealthStore` adapter, `UITestHealthStore` stub) for Apple Health write-back —
one shared instance is provided via `@Environment(\.healthService)` at the app
root; the gated write/update/remove hooks live in `HealthWriteHooks`
([plan-0036](plans/0036-apple-health-write-back/), [ADR-0011](decisions/0011-health-write-back-and-device-local-sample-identity.md)).

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
  `MigrationPlan` (`SchemaMigrationPlan`, `schemas = [SchemaV1, SchemaV2, SchemaV3]`,
  `stages = [v1ToV2, v2ToV3]`) under `Domain/Persistence/`. **`SchemaV1` and
  `SchemaV2` are frozen self-contained snapshots** (nested `@Model` copies):
  V1 = pre-0023 shape (`name`, `@Attribute(.unique)`, no `uuid`/`modifiedDate`);
  V2 = CloudKit-ready shape (identity + LWW, field `timestamp`, no `creationDate`).
  **`SchemaV3`** (`Schema.Version(3, 0, 0)`) references the **live** top-level
  `@Model` classes — current shape (`timestamp` renamed to `consumptionDate`,
  added `creationDate`). `MigrationPlan.self` is passed to every `ModelContainer`
  construction path — `StoreBootstrap.makeContainer` and `UITestSeed`. See
  [ADR-0009](decisions/0009-versioned-schema-and-migration-plan.md) and
  [ADR-0010](decisions/0010-cloudkit-ready-identity-and-lww.md).
- **Custom stages**: `v1ToV2` backfills a distinct `uuid` + `modifiedDate` per row
  (fetching the **`SchemaV2` snapshot types** — the stage destination); `v2ToV3`
  backfills `creationDate` from `consumptionDate` (the `timestamp`→`consumptionDate`
  rename itself is handled by `@Attribute(originalName: "timestamp")`). The final
  stage fetches the live (`= V3`) classes.
- **Snapshot-on-divergence rule** (ADR-0009): **a shape change must bump the
  version and freeze the prior shape — never edit a shipped `VersionedSchema` in
  place.** Doing so keeps the version number but changes the schema hash, so an
  already-migrated store reports "unknown model version" and falls into recovery
  (data moved aside). This bit us once between the first V2 and the
  rename/`creationDate` change; the fix was to freeze the shipped V2 and add V3 +
  `v2ToV3`. The next divergence freezes V3 first.
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

### Record identity, singleton, de-dup (plan-0023 Phase A)

CloudKit forbids `@Attribute(.unique)` and can deliver a logical record twice, so
identity and uniqueness moved into app code:

- `ConsumptionEvent` / `DrinkTemplate` carry a stable `uuid` (not unique) and a
  `modifiedDate` LWW clock; `UserProfile` carries `modifiedDate` (its identity is
  the singleton `id`).
- `UserProfileStore` (`Domain/Persistence/`) enforces the single-profile invariant
  the dropped `.unique` used to: fetch-or-create + de-dupe keeping the newest
  `modifiedDate`.
- `RecordDeduplicator` runs a launch (Phase A) / post-sync (Phase B) **sweep**:
  group by `uuid`, keep newest `modifiedDate`, delete the rest; plus an insert-time
  `ensureUniqueIdentity` guard.
- Import is an identity-based **upsert** with LWW (events/templates); the profile
  is restored unconditionally on manual import. Export/import carry `uuid` +
  `modifiedDate` (optional, back-compatible) and now include `DrinkTemplate`.
- **CloudKit itself stays OFF** (Phase B: provision container + entitlements +
  `cloudKitDatabase: .private(…)` — one-way, separately approved). See
  [ADR-0010](decisions/0010-cloudkit-ready-identity-and-lww.md).

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
