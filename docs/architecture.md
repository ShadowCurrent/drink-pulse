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
│   └── Settings/             # User profile, guidelines, preferences
├── DesignSystem/             # Tokens, shared components, modifiers (future)
├── ContentView.swift         # Root TabView coordinator
└── drinkpulseApp.swift       # App entry point, ModelContainer setup
```

Each feature folder contains: `*View.swift`, `*ViewModel.swift` (when needed),
and feature-local subviews. Views never import SwiftData directly except to
read `@Environment(\.modelContext)` for passing to a repository.

## MVVM + Repository

- **Views** own presentation state (`@State`) and read from view models.
- **View models** are `@Observable final class` marked `@MainActor`.
  They hold business logic and call into repositories.
- **Repositories** own the `ModelContext` and perform all SwiftData
  insert / fetch / delete. Views never call `modelContext.insert` directly
  (exception: simple one-liner inserts during early scaffolding, replaced
  once a feature matures).
- **Domain models** (`@Model final class`) are SwiftData entities only.
  No UI logic or formatting lives there.

## State management

| Situation | Wrapper |
|-----------|---------|
| View-owned local state | `@State private var` |
| Injected `@Observable` VM needing bindings | `@Bindable var` |
| Read-only injected value | `let` |
| Shared app-wide state | `@Observable` class via `@Environment` |

**Never use** `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`.

## Navigation

- Root: `TabView` with `Tab` API (iOS 18+).
- Per-tab: `NavigationStack` with value-based `NavigationLink(value:)` +
  `.navigationDestination(for:)`.
- Modals: `.sheet(isPresented:)` for "create new" flows;
  `.sheet(item:)` for model-driven sheets.
- Sheets own their dismiss via `@Environment(\.dismiss)`.
  When a pushed destination inside a sheet needs to dismiss the whole sheet,
  inject a `dismissSheet` closure via a custom `@Entry` environment value.

## Dependency injection

Lightweight manual DI through SwiftUI environment values:
- SwiftData `ModelContext` via `@Environment(\.modelContext)` (provided by `.modelContainer()`).
- Repositories and shared services injected via `@Entry` custom environment keys.
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
