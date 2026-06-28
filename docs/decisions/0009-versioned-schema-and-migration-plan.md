# 0009 — Versioned schema baseline and migration plan

**Status**: Accepted
**Date**: 2026-06-28
**Plan**: [plan-0035](../plans/0035-swiftdata-migration-foundation/)
**Related**: [ADR-0001](0001-swiftdata-cloudkit.md) (SwiftData + CloudKit), [ADR-0008](0008-services-layer.md); plan-0022 (`StoreBootstrap`), plan-0023 (CloudKit)

## Context

Until now SwiftData schema evolution relied entirely on **implicit
lightweight inference**. Every schema change to date — `quantity`,
`enteredUnit`, `priceCurrency`, the `ageYears: Int` → `dateOfBirth: Date?`
swap, and the `alcoholUnit` raw-value retirement — shipped without a
`VersionedSchema`, `SchemaMigrationPlan`, or `MigrationStage` anywhere in the
repo. The only safety net was the plan-0022 `StoreBootstrap` non-destructive
`RecoveredStores/` move-aside, which fires on an open failure.

Two pressures make this insufficient:

- **App Store submission blocker.** CLAUDE.md ("Change hygiene") and
  `architecture.md` both require a real migration plan before shipping; the
  dev-only store-wipe / recovery fallback is explicitly *not* an App Store
  strategy.
- **Hard prerequisite for plan-0023 (CloudKit).** 0023's CloudKit-compat
  edits are themselves a schema change that would wipe accumulated user data
  without a migration story. 0023 must not start until that foundation exists.

This ADR records the decision made by plan-0035 to deliver that foundation —
**infrastructure only, no model-shape change, no behaviour change.**

## Decision

Introduce an explicit versioned-schema baseline and a governing migration
plan, wired through the existing `StoreBootstrap`:

- **`SchemaV1` (`VersionedSchema`)** with
  `versionIdentifier = Schema.Version(1, 0, 0)`, capturing the current
  three-model schema (`DrinkTemplate`, `ConsumptionEvent`, `UserProfile`)
  exactly as it ships today.
- **`MigrationPlan` (`SchemaMigrationPlan`)** with
  `schemas = [SchemaV1.self]` and `stages = []`. V1 is the baseline, so there
  is no stage yet; the plan exists so the container is *governed by an
  explicit plan*, and so 0023 adds `SchemaV2` + one `MigrationStage` rather
  than introducing the whole concept.
- **`StoreBootstrap.makeContainer`** builds the `ModelContainer` passing
  `migrationPlan: MigrationPlan.self`. All container-construction paths
  (`drinkpulseApp`, `UITestSeed`) go through the same plan.

This replaces reliance on implicit lightweight inference with an explicit,
testable plan, resolving the App-Store blocker and unblocking plan-0023.

### Snapshot-on-divergence rule (Q1 — the load-bearing discipline)

`SchemaV1.models` **references the LIVE `@Model` classes** for now. This is
lean and avoids duplication while V1 *is* the current shape. The cost is a
discipline that **must** be honored:

> When the first divergent schema lands (plan-0023), that session MUST first
> copy the then-current model definitions into a frozen `SchemaV1` namespace
> **before** editing the live classes as `SchemaV2`.

If this step is skipped, `SchemaV1` would silently reflect `SchemaV2`'s shape,
making the migration definition describe a no-op and corrupting the migration.
Reference-now was chosen over duplicate-now deliberately; this rule is the
documented tradeoff of that choice.

### Version baseline (Q2)

`Schema.Version(1, 0, 0)` is the first **explicit** version, but it already
**absorbs the prior implicit lightweight migrations**: `quantity` (default
`1`), `enteredUnit?`, `priceCurrency?`, the `ageYears: Int` → `dateOfBirth:
Date?` swap, and the `alcoholUnit` raw-value retirement (handled at the
`Codable` layer). V1 is the *current* shape, not a re-creation of the original
schema; the historical changes are treated as pre-baseline.

### Relationship to `StoreBootstrap` recovery (plan-0022)

The `RecoveredStores/` non-destructive move-aside remains in place as the
**genuine-corruption last resort**. With a real migration plan governing the
container, it should **no longer fire on a planned schema change** — a planned
change now flows through `MigrationPlan`, and recovery is reserved for an
unexpected open failure (true corruption).

### Scope boundary (Q4)

This ADR and plan-0035 are **infra-only**. All CloudKit-compat shape changes
— dropping `@Attribute(.unique)`, adding defaults on every attribute,
app-level singleton enforcement, and removing the deprecated
`ConsumptionEvent.name` — are deferred to **plan-0023** as `SchemaV2` plus one
`MigrationStage`. No field is added, removed, renamed, or re-typed here.

## Consequences

### Positive

- An explicit, testable, App-Store-ready migration foundation replaces
  implicit inference; schema evolution is now governed by a real plan.
- Clean handoff to plan-0023: it adds `SchemaV2` + one `MigrationStage`
  instead of introducing the whole versioning concept under deadline.
- `RecoveredStores/` recovery is reduced to its intended role — true
  corruption — and should not fire on planned changes.

### Negative / trade-offs

- **Discipline-dependent.** The reference-now choice means the
  snapshot-on-divergence step must be performed by hand at the moment of the
  first divergent schema; skipping it corrupts the V1 definition.
- Two migrations / plans across 0035 + 0023 instead of one combined change —
  the cost of keeping the foundation behaviour-neutral and isolated.

### Alternatives considered

- **Duplicate the model definitions inside `SchemaV1` now.** Self-contained
  and not discipline-dependent, but byte-identical to the live models today —
  pure redundancy that can silently drift until 0023 makes it pay off.
  **Rejected** in favor of reference-now + the snapshot-on-divergence rule.
- **Keep relying on implicit lightweight inference.** **Rejected:** it is not
  an App Store strategy and leaves no testable migration definition for 0023
  to build on.
