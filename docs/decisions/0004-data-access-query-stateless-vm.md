# 0004 — Data access via `@Query` + stateless view models

**Status**: Accepted  
**Date**: 2026-05-31  
**Supersedes**: [ADR-0003](0003-mvvm-with-repositories.md)

## Context

ADR-0003 proposed a repository layer that owns `ModelContext` and sits
between view models and SwiftData. That layer was never implemented. The
codebase converged on a simpler, idiomatic SwiftData pattern, and
`architecture.md` already describes it. This ADR records that reality and
formally supersedes ADR-0003 so the docs, CLAUDE.md, and code agree.

Constraints in play:
- SwiftData's `@Query` is the framework-blessed way to read models into a
  view, with automatic change tracking and live updates.
- Swift 6 strict concurrency: `ModelContext` is main-actor bound;
  `@Observable @MainActor` view models satisfy this without extra wiring.
- The app is single-user, offline-first, with modest data volumes; a
  repository abstraction adds indirection without a payoff here.

## Decision

**Views own data access; view models are stateless with respect to
persistence.**

```
View  ──@Query reads──▶  SwiftData models
  │
  ├── simple mutations (insert/delete) ──▶ @Environment(\.modelContext)
  │
  └──passes [Model] / Profile?──▶  ViewModel (@Observable, @MainActor)
                                       (pure computation, no ModelContext)
```

**Rules:**
- Views read models with `@Query`. For filtered/windowed reads, build the
  `Query` in the view's `init` from plain parameters (dynamic-query pattern).
- Simple mutations (insert, delete, single-field edits) happen directly via
  `@Environment(\.modelContext)` in the view.
- View models are `@Observable final class`, `@MainActor`. They receive
  already-fetched `[ConsumptionEvent]` / `UserProfile?` as injected plain
  values and return derived/computed results. They **never** own a
  `ModelContext` or a `@Query`. This keeps them trivially unit-testable
  with in-memory arrays — no store required.
- Domain models (`@Model final class`) are pure data containers.
- **Platform capabilities** (notifications, Health, file IO) are not data
  access; they live in the `Services/` layer behind a protocol (see the
  services-layer ADR).

## Consequences

### Positive
- Matches SwiftData idioms; less code than a hand-rolled repository.
- View models are pure functions over injected data → fast, store-free
  unit tests and high coverage with no mocking of persistence.
- Live UI updates come for free from `@Query`.

### Negative / trade-offs
- Mutation logic is spread across views rather than centralised. Mitigated
  by keeping mutations to trivial insert/delete/edit; anything with
  business rules belongs in a view-model computation or a domain type.
- Filtered reads require the slightly verbose `init`-constructed `Query`.
- No single choke point for persistence, so a future store migration
  touches each `@Query` site. Acceptable at current scale.

### Alternatives considered
- **Repository layer (ADR-0003)** — superseded: never built; added
  indirection without benefit for this app's scale and offline model.
- **`@ModelActor` for all reads** — rejected for now: warranted only for
  heavy background queries; introduce per-need, not as the default.
