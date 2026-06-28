# 0035 — Retrospective

**Completed**: 2026-06-28

## What went well

- Clean infra-only landing: an explicit `SchemaV1` (`VersionedSchema`,
  `Schema.Version(1,0,0)`) + `MigrationPlan` (`SchemaMigrationPlan`, no stage yet)
  now govern the `ModelContainer` with **zero behaviour change** — every container
  path (`StoreBootstrap` initial + post-recovery retry, `UITestSeed`) routes
  through the same plan, and `drinkpulseApp` needed no change because it already
  delegates to `StoreBootstrap`.
- The App-Store migration blocker called out in `architecture.md` and
  `open-questions.md` is cleared, and plan-0023 (CloudKit) — which was hard-blocked
  on a real migration story — is now unblocked.
- Doc contradiction reconciled in the same task: the historical `ageYears` →
  `dateOfBirth` swap is treated as already-applied (pre-baseline, no production
  users) and absorbed into `SchemaV1`; `domain.md` corrected.
- Gates passed comfortably: build clean (zero new warnings), `** TEST SUCCEEDED **`,
  app coverage 94.22% (≥90%), no file introduced/modified over 300 lines.

## What went wrong / surprises

- `SchemaV1.versionIdentifier` could not be a stored `static let` — under Swift 6
  with the module's MainActor default isolation it had to be a computed
  `nonisolated static var`. Minor, but a recurring gotcha for new Domain-level
  static members in this codebase.
- SourceKit reported transient same-module "cannot find type" diagnostics that
  turned out to be stale indexer lag; real `xcodebuild` build/test runs were clean.
  Lesson: trust the command-line build over the editor's live diagnostics here.
- `DataImporterRoundTripTests` looked comprehensive but silently missed
  `dateOfBirth`, `icon`, and the combined `enteredUnit` case — caught only by
  writing the new `ComprehensiveRoundTripTests`.

## Decisions made during execution

- Q1 → reference the **live** `@Model` classes from `SchemaV1.models` now (no
  duplication), with the snapshot-on-divergence rule recorded in ADR-0009: the
  first divergent schema must freeze V1 before editing the live classes as V2.
- Q2 → baseline `Schema.Version(1, 0, 0)`; V1 absorbs the prior implicit
  lightweight migrations.
- Q3 → accept + verify on device; owner backs up the real device before
  installing the post-change build. Added a comprehensive export/import round-trip
  test (every current field + a nil-optionals case) as the safeguard.
- Q4 → infra-only; all CloudKit-compat shape changes (drop `@Attribute(.unique)`,
  defaults on every attribute, app-level singleton enforcement, removing the
  deprecated `name`) stay in plan-0023 as `SchemaV2` + one `MigrationStage`.

## Leftover open questions

- The **snapshot-on-divergence discipline** now rests on plan-0023: when its first
  model-shape change lands, that session must copy the then-current definitions
  into a frozen `SchemaV1` namespace **before** editing the live classes as
  `SchemaV2`. Until then `SchemaV1` is byte-identical to the live models.
- The comprehensive round-trip safeguard is in place for the owner's device
  re-install; the actual on-device verification is the owner's step.
