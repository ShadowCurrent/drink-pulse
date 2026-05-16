# 0001 — SwiftData + CloudKit for persistence and sync

**Status**: Accepted  
**Date**: 2026-05-16

## Context

DrinkPulse needs on-device persistence and optional cross-device sync.
The app is privacy-first with no custom backend. Sync must work via the
user's own Apple ID without any account registration.

The stack must support Swift 6 strict concurrency and integrate cleanly
with SwiftUI's data-flow model.

## Decision

Use **SwiftData** for local persistence and **CloudKit** (via SwiftData's
built-in integration) for optional sync. No custom backend, no third-party
database.

## Consequences

### Positive
- Zero-backend: no server to maintain, no sign-up UX, no data leaving
  Apple's infrastructure.
- SwiftData's `@Model` macro integrates directly with SwiftUI's
  `@Environment(\.modelContext)` and `@Query`, reducing boilerplate.
- CloudKit sync is opt-in via `ModelConfiguration` — a single flag,
  no custom sync code.
- Conflict resolution (last-write-wins) is handled by SwiftData/CloudKit;
  no custom logic needed for v1.
- Schema migrations are handled declaratively via `VersionedSchema` and
  `SchemaMigrationPlan` when needed.

### Negative / trade-offs
- CloudKit requires an iCloud-enabled device and an Apple Developer account
  with a CloudKit container. Simulator sync requires signing in to iCloud.
- SwiftData's CloudKit integration does not support `@Attribute(.unique)`
  constraints in CloudKit-synced stores (works fine for local-only store).
  The `UserProfile` singleton uses `.unique` — this must be revisited before
  enabling CloudKit sync on that model.
- Complex queries (aggregations, cross-entity joins) are more verbose than
  raw SQL.

### Alternatives considered
- **Core Data** — rejected: more boilerplate, no first-class Swift 6 support,
  superseded by SwiftData for new projects.
- **SQLite via GRDB** — rejected: excellent library but requires a third-party
  dependency and manual CloudKit sync plumbing.
- **Realm** — rejected: third-party SDK, own sync infrastructure (Atlas),
  conflicts with privacy-first / no-account stance.
