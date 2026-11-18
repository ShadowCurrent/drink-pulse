# Architecture

## Overview

DrinkPulse is a SwiftUI + SwiftData iOS app with an iOS 27.0 minimum deployment
for the app and both test targets. All logic runs on-device; CloudKit sync is
layered on top of SwiftData without any custom backend. For the selected Xcode
27/Swift 6.4 evidence environment and exact build/test commands, see
[Phase 08 baseline evidence](../.planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md).

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
├── Diagnostics/              # Dev-only #if DEBUG instrumentation (view-load timing, …)
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

- **Route seam**: `NotificationActionHandler` (the `UNUserNotificationCenterDelegate`,
  plain `Sendable`) exposes `static route(identifier:defaults:)`, which sets the
  matching pending flag for a cold launch and posts the matching tap notification
  for a warm app. The delegate's `didReceive` callback calls it, and so does the
  UI-test notification center's `deliverTap`, reached only through the
  `-dp_uitest_warm_weekly_tap` launch flag, which lets tests drive a tap without
  constructing a `UNNotificationResponse`.
- **Delegate assignment** (INT-01, Phase 10): the notification delegate is
  assigned synchronously in `drinkpulseApp.init()` on the main actor, before the first
  frame, because the SDK requires the delegate before launch finishes. An earlier detached
  assignment ran after `init()` returned, and a tap on a killed app landed on
  Dashboard. The center holds the delegate weakly, so `drinkpulseApp` keeps the
  handler as a stored property for the process lifetime. The `didReceive` callback
  logs the tap kind only (`daily`, `weekly` or `other`), and `init()` logs the
  assignment duration in milliseconds; neither line carries user data.
- **Notification cancel epoch** (F3, Phase 10): `ReminderService` and
  `WeeklySummaryService` each keep two private counters, a lifecycle epoch advanced
  by every schedule and cancel and a cancel epoch recording the lifecycle value at
  the latest cancel. After `add` returns, a schedule removes its own identifier only
  when the latest lifecycle event is a cancel issued after it began, so an opt-out
  during an in-flight schedule wins and a superseded schedule never removes a later
  schedule's request. There is no `Task` cancellation or shielding involved.
- **Health remove resolution** (F2, Phase 10): the serialized `HealthService`
  remove resolves the current sample by its `dp_event_uuid` metadata first and uses
  the captured `healthKitUUID` only as a fallback when the lookup finds nothing or
  throws, so an edit followed by a quick delete leaves no orphan sample. Ordering
  through `runSerial`, opt-in, non-blocking behavior and the device-local cache
  semantics are unchanged.

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
  shows `RootShellView`; when `false`, shows `OnboardingView`. `onboardingDone` is
  the **single source of truth** for this gate (ADR-0012): it is write-only from
  explicit user action (`OnboardingView.onFinish`, and — in the future — an
  explicit delete-all-data flow); a transient or empty `@Query` result never
  writes to it.
- Before the onboarding/shell branch is reachable at all, `drinkpulseApp` gates
  on `ContainerLoadState` (`.loading` / `.ready(ModelContainer)` /
  `.failed(StartupError)`, STARTUP-02/STARTUP-03). Container creation runs
  inside a `.task` after the first frame renders — never in `App.init` or an
  eagerly-evaluated stored property — so the first frame is never blocked on
  disk I/O. `.modelContainer(_:)` attaches only to the `.ready` subtree.
  `.failed` shows `StartupErrorView` (Retry + Share Diagnostic Details) instead
  of crashing; Retry always re-runs the full `StoreBootstrap.makeContainer`
  open→recover→open sequence.
- `RootShellView` — `TabView` with `Tab {}` value-based syntax. The Liquid Glass
  tab-bar implementation was introduced for iOS 26; that is historical context,
  while the current minimum deployment is iOS 27. Houses all four main tabs and
  the Add Drink sheet.
- Per-tab: `NavigationStack`. Currently only the AddDrink flow uses value-based
  `NavigationLink(value:)` + `.navigationDestination(for:)` (grid → detail step).
  Dashboard, History, and Settings use `NavigationStack` for the title bar only.
- Modals: `.sheet(isPresented:)` for "create new" flows;
  `.sheet(item:)` for model-driven sheets.
- Sheets own their dismiss via `@Environment(\.dismiss)`.
  When a pushed destination inside a sheet needs to dismiss the whole sheet,
  read `dismiss` at the sheet root (outside the sheet's `NavigationStack`) and pass
  the `DismissAction` down explicitly (`AddDrinkView` -> `DrinkTypeGridView` ->
  `DrinkDetailInputView`); the former `\.dismissSheet` custom `@Entry` was removed
  in Phase 09 (plan 09-02).

## Dependency injection

Lightweight manual DI through SwiftUI environment values:
- SwiftData `ModelContext` via `@Environment(\.modelContext)` (provided by `.modelContainer()`).
- Custom closures or services injected via `@Entry` custom environment keys when a child
  view needs to trigger an action owned by an ancestor. (AddDrink's sheet dismissal is no
  longer one of these: it passes a `DismissAction` explicitly, see Navigation above.)
- No third-party DI framework.

## Accessibility and motion

Decided in [ADR-0013](decisions/0013-accessibility-motion-and-adaptive-layout.md) (Phase 11).
- `DesignSystem/DPMotion.swift` is the single Reduce Motion decision seam: animations go through
  `DPMotion.animation(_:reduceMotion:)`, fed by `accessibilityReduceMotion`. Unit tested by `DPMotionTests`.
- `DPMotionProbe` elements and the `-dp_uitest_reduce_motion` override are test only and exist only under `-dp_uitest`
  (`UITestSeed.isActive`); they never reach a production path.
- `DesignSystem/DPAdaptiveStack.swift` and the `DynamicTypeSize.isAccessibilitySize` rule: side by side at regular
  sizes, stacked at accessibility sizes (`AnyLayout`), `ScaledMetric` for fixed sizes, wrapping instead of one-line
  limits, never a `dynamicTypeSize` range cap.
- Audit tests: ungated per-screen classes (`*AccessibilityAuditUITests`) and the gated full class
  `AccessibilityAuditUITests` (`DP_RUN_A11Y_AUDIT`, opt-in).

## Concurrency

Swift 6 strict concurrency is enabled, enforced via `SWIFT_VERSION = 6.0` on
the app target in `project.pbxproj` as of Phase 2 of v1.2 (previously only
the test targets carried it).
- All `@Observable` view models are `@MainActor`.
- Async work uses structured concurrency (`async let`, `TaskGroup`).
- SwiftData operations happen on the main actor via `ModelContext`.
  Heavy queries can move to a `@ModelActor` when needed.

## Persistence bootstrap

`Domain/Persistence/StoreBootstrap.swift` owns the `ModelContainer` creation:

- **Versioned schema + migration plan**: the container is governed by an explicit
  `MigrationPlan` (`SchemaMigrationPlan`, `schemas = [SchemaV1, SchemaV2, SchemaV3, SchemaV4]`,
  `stages = [v1ToV2, v2ToV3, v3ToV4]`) under `Domain/Persistence/`.
  **SchemaV1, SchemaV2, and SchemaV3 are frozen self-contained snapshots**
  (nested `@Model` copies): V1 = pre-0023 shape (`name`, `@Attribute(.unique)`,
  no `uuid`/`modifiedDate`); V2 = CloudKit-ready shape (identity + LWW, field
  `timestamp`, no `creationDate`); V3 = the shipped `consumptionDate` and
  `creationDate` shape. **`SchemaV4` is the live top-level-model shape.**
  `MigrationPlan.self` is passed to every `ModelContainer`
  construction path — `StoreBootstrap.makeContainer` and `UITestSeed`. See
  [ADR-0009](decisions/0009-versioned-schema-and-migration-plan.md) and
  [ADR-0010](decisions/0010-cloudkit-ready-identity-and-lww.md).
- **Custom stages**: `v1ToV2` backfills a distinct `uuid` + `modifiedDate` per row
  (fetching the **`SchemaV2` snapshot types** — the stage destination); `v2ToV3`
  backfills `creationDate` from `consumptionDate` (the `timestamp`→`consumptionDate`
  rename itself is handled by `@Attribute(originalName: "timestamp")`). `v3ToV4`
  is the existing lightweight stage from the frozen V3 snapshot to the current
  V4 model shape.
- **Snapshot-on-divergence rule** (ADR-0009): **a shape change must bump the
  version and freeze the prior shape — never edit a shipped `VersionedSchema` in
  place.** Doing so keeps the version number but changes the schema hash, so an
  already-migrated store reports "unknown model version" and falls into recovery
  (data moved aside). This bit us once between the first V2 and the
  rename/`creationDate` change; the fix was to freeze the shipped V2 and add V3 +
  `v2ToV3`. For the next divergence, freeze V4, add `SchemaV5`, and add a
  `v4ToV5` `MigrationStage`; do not edit any shipped snapshot in place.
- **Non-destructive recovery**: if `ModelContainer.init` fails **for any
  reason**, the existing `.sqlite` / `-wal` / `-shm` files are **moved** (not
  deleted) to a uniquely named (timestamp plus random suffix) folder in
  `Application Support/RecoveredStores/`. The move is all-or-nothing:
  if any of the three files cannot be moved, the ones already moved are put back and the
  error propagates. If a put-back itself fails, the rollback is incomplete: it moves
  every store file still at the store location into the snapshot folder and keeps that folder.
  The guarantee holds for every failure and is pinned by `StoreBootstrapTests+Rollback`:
  nothing is deleted, and each store file is either at the store location or in the
  snapshot. After a complete rollback all files are at the store location; after an
  incomplete one the store location holds only files whose own move into the snapshot
  failed. This is best effort: a file whose move keeps failing cannot be handled, and the
  failure is logged. A fresh container is then created. At most 3 snapshots are
  retained; older ones are trimmed. With the migration plan in place, `RecoveredStores/` recovery is
  the **last resort** — it is no longer the schema-evolution mechanism, and
  should not fire on a *planned* schema change. The trigger is
  **not** limited to genuine corruption: the open error is not classified, so a
  transient fault (disk full, file protection while the device is locked, an I/O
  error) also moves the store aside and shows an empty app. Narrowing the trigger
  to the observed unreadable-store and unknown-model-version errors, and telling
  the user when recovery ran, is an open follow-up (see
  `.claude/context/open-questions.md`).
- **Recovery-reporting seam**: `StoreBootstrap` exposes an internal
  `makeContainerReportingRecovery` variant that returns the container together
  with whether recovery fired. `makeContainer` delegates to it unchanged, so the
  production and test paths share one open, recover and reopen body. Migration
  tests open legacy V1, V2 and V3 stores through it and assert no recovery
  happened, which proves a migration was not silently masked by a move-aside.
- `clearRecoveredStores()` is called by "Delete all data" so the destructive
  action is complete and predictable.
- `drinkpulseApp.swift` delegates to `StoreBootstrap.makeContainer` (`@MainActor`),
  invoked from inside `loadContainerIfNeeded()`'s `.task` after the first frame
  renders — not eagerly at `App.init` (STARTUP-02).

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
