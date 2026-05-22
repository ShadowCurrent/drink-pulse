# Architecture

## Overview

DrinkPulse is a SwiftUI + SwiftData iOS app. All logic runs on-device;
CloudKit sync is layered on top of SwiftData without any custom backend.

## Folder layout

```
drinkpulse/
├── Domain/                   # SwiftData models + pure-Swift domain types
├── Features/
│   ├── Dashboard/            # Home tab: today's summary, progress
│   ├── AddDrink/             # Two-step log-a-drink flow
│   ├── History/              # Past events grouped by day
│   ├── Insights/             # Trends tab: area chart, weekday bars, heatmap, health metrics
│   └── Settings/             # User profile, guidelines, preferences
├── DesignSystem/             # Tokens, shared components, modifiers
├── ContentView.swift         # Root TabView coordinator
└── drinkpulseApp.swift       # App entry point, ModelContainer setup
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

## State management

| Situation | Wrapper |
|-----------|---------|
| View-owned local state | `@State private var` |
| Injected `@Observable` VM needing bindings | `@Bindable var` |
| Read-only injected value | `let` |
| Shared app-wide state | `@Observable` class via `@Environment` (e.g. `AppLockState`) |

**Never use** `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`.

## Navigation

- Root: `TabView` with `.tabItem { Label(...) }` (iOS 16+).
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

## Sync

CloudKit integration is handled entirely by SwiftData's built-in
`ModelConfiguration` with CloudKit container ID. No custom sync code.
Conflict resolution is left to SwiftData's default last-write-wins.
