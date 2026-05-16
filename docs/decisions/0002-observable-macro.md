# 0002 — @Observable macro over ObservableObject

**Status**: Accepted  
**Date**: 2026-05-16

## Context

DrinkPulse targets iOS 26 (minimum). SwiftUI offers two observation
systems: the legacy `ObservableObject` / `@Published` / `@StateObject`
trio (iOS 13+) and the modern `@Observable` macro (iOS 17+, Swift 5.9+).

The project uses Swift 6 strict concurrency. The chosen observation
system must integrate cleanly with `@MainActor` isolation.

## Decision

Use **`@Observable`** for all view models and shared state objects.
`ObservableObject`, `@Published`, `@StateObject`, and `@ObservedObject`
are prohibited in this codebase.

Property wrapper usage in views:

| Situation | Wrapper |
|-----------|---------|
| View-owned `@Observable` instance | `@State private var` |
| Injected `@Observable` needing bindings | `@Bindable var` |
| Shared via environment | `@Environment(MyClass.self)` |

## Consequences

### Positive
- Granular invalidation: SwiftUI only re-renders views that read a
  property that actually changed, rather than re-rendering on any
  `@Published` mutation.
- Less boilerplate: no `@Published` annotations, no `objectWillChange`
  publisher, no `@StateObject` / `@ObservedObject` distinction.
- `@Observable` classes work naturally as nested objects — a known pain
  point with `ObservableObject`.
- Swift 6 compatible: marking `@Observable` classes `@MainActor` cleanly
  satisfies strict concurrency without extra ceremony.
- `@State private var model = MyViewModel()` replaces the awkward
  `@StateObject private var model = MyViewModel()` pattern.

### Negative / trade-offs
- iOS 17+ only — not relevant here since minimum deployment is iOS 26.
- Property wrappers (`@AppStorage`, `@Query`) inside `@Observable` classes
  require `@ObservationIgnored` to avoid a compiler error (the two
  transformation macros conflict on the same stored property).
- Slightly less familiar for developers who know SwiftUI primarily through
  pre-iOS 17 tutorials.

### Alternatives considered
- **`ObservableObject`** — rejected: coarser invalidation, more boilerplate,
  nested object tracking requires manual workarounds, not idiomatic for
  Swift 6 / iOS 17+.
