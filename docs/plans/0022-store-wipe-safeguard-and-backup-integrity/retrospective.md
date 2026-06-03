# 0022 — Retrospective

**Completed**: 2026-06-03
**Executed by**: Sonnet 4.6 (plan authored by Opus)

## What went well

- All 6 plan steps landed cleanly in a single session without deviations.
- `StoreBootstrap.nonisolated` approach is clean — no actor coupling on
  filesystem-only methods; `@MainActor` only where `ModelContainer.init` requires it.
- Content-signature approach for export regen is simple and correct: a Swift `Hasher`
  over event + profile fields, no external hashing framework needed.
- Profile upsert test (`profileUpsert_overwritesExistingProfile`) caught the single-row
  invariant explicitly — good regression anchor for future schema changes.

## What was harder than expected

- **Test target file registration**: the app target uses `PBXFileSystemSynchronizedRootGroup`
  (auto-detects new files), but the test target uses explicit `PBXFileReference` entries.
  New test files must be added manually to `project.pbxproj`. Not documented anywhere obvious.
- **Making ModelContainer fail reliably**: writing garbage bytes to the `.sqlite` file
  isn't enough — SQLite is resilient. Removing read permissions (chmod 000) is the
  reliable trigger. Something to document for future persistence tests.
- **Swift 6 actor inference**: without `nonisolated` annotations, Swift inferred all
  `StoreBootstrap` static methods as `@MainActor` because `makeContainer` calls
  `ModelContainer.init`. The explicit annotations resolved this but required an iteration.

## Coverage note

5 lines remain uncovered across `StoreBootstrap` and `DataImporter`:
- `guard ... else { return }` when `Application Support` directory doesn't exist (impossible on iOS).
- 4 compiler-generated implicit closures for `?? []` and `?? .distantPast` nil branches.

These are infrastructure edge cases that cannot be triggered in a running iOS app or simulator.
The domain logic (calculations, rules, validators) remains at 100%.

## What to watch

- `SchemaMigrationPlan` is still required before App Store. `StoreBootstrap` makes
  the failure path non-destructive but does not prevent data loss from schema changes.
  Plan-0023 (CloudKit) will add the first real schema migration.
- `RecoveredStores/` disk usage: capped at 3 snapshots (~3× store size). Monitor on
  devices with large event histories once real usage accumulates.
