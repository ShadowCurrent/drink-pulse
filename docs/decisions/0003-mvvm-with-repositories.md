# 0003 — MVVM architecture with repository layer

**Status**: Accepted  
**Date**: 2026-05-16

## Context

DrinkPulse needs a consistent architecture that:
- Keeps SwiftUI views focused on presentation.
- Makes business logic testable without a running SwiftData store.
- Scales as features grow without coupling views to persistence details.
- Fits naturally with Swift 6 strict concurrency and `@Observable`.

## Decision

Use **MVVM with a repository layer** between view models and SwiftData.

```
View  ──reads──▶  ViewModel (@Observable, @MainActor)
                      │
                      └──calls──▶  Repository
                                       │
                                       └──owns──▶  ModelContext (SwiftData)
```

**Rules:**
- Views own only presentation state (`@State`). They never call
  `modelContext.insert / delete / fetch` directly.
- View models (`@Observable final class`, `@MainActor`) hold business
  logic and coordinate with repositories.
- Repositories own the `ModelContext`. They are injected via custom
  `@Entry` SwiftUI environment values.
- Domain models (`@Model final class`) are pure data containers.
  No formatting, no UI logic, no business rules.
- Exception allowed during early scaffolding: simple one-liner inserts
  directly in a view are acceptable as scaffolding, with a TODO to move
  them to a repository once the feature matures.

## Consequences

### Positive
- Views stay thin and focused; business logic can be unit-tested by
  providing a mock repository without a real `ModelContext`.
- `@Observable` view models with `@MainActor` satisfy Swift 6 concurrency
  requirements with no extra work.
- Repository is the single point of contact for SwiftData, making future
  migrations or store changes easier to isolate.
- Feature folder structure (`Features/X/XView.swift`, `XViewModel.swift`,
  `XRepository.swift`) scales linearly as features are added.

### Negative / trade-offs
- More files per feature than a simple "view talks directly to `@Query`"
  approach — acceptable overhead given the project's scale.
- Some early scaffolding views (`DrinkDetailInputView`) insert directly
  into `modelContext` as a temporary shortcut. These carry a technical
  debt marker to be resolved when repositories are wired up.

### Alternatives considered
- **Views query SwiftData directly via `@Query`** — rejected for
  non-trivial logic; acceptable for simple read-only list views but
  not for writes or derived computations.
- **TCA (The Composable Architecture)** — rejected: heavyweight dependency,
  verbose for an app of this scale, conflicts with the no-DI-framework rule.
- **Clean Architecture (Use Cases layer)** — rejected: over-engineered for
  current scope; the repository layer provides sufficient separation without
  the extra abstraction cost.
