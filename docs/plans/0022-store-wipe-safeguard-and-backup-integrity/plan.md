# 0022 — Store-wipe safeguard & backup integrity

**Status**: in-progress
**Size**: medium
**Created**: 2026-06-03
**Frozen**: 2026-06-03

## Summary

Make the app safe to accumulate real data on a physical device before any
further schema work (notably CloudKit, plan-0023). Two problem areas:

1. **Silent data wipe.** `drinkpulseApp.swift` deletes the entire SwiftData
   store file if the `ModelContainer` fails to open — which is exactly what a
   schema change without a migration plan triggers. For a user collecting real
   history this means the first launch after any model change silently destroys
   all data with no warning and no backup.
2. **Backups are incomplete and can be stale or fail silently.** The manual
   JSON backup (plan-0019) exports only `ConsumptionEvent`s — never the
   `UserProfile` (body metrics, guideline, goal, units, currency). The export
   file is only regenerated when the *event count* changes, so an edit produces
   a stale share file. Import errors are swallowed by `try?`, so picking a bad
   file gives no feedback.

This plan hardens the wipe path (back up the store file before any destructive
recreate, and log it) and makes the manual backup a true full-state backup that
round-trips profile + events, regenerates correctly, and surfaces errors.

## Context

- Triggered by a pre-use audit (2026-06-03). User intends to run the app daily
  on-device and later enable iCloud.
- Builds directly on plan-0019 (export/import). The export/import *mechanism*
  stays; this plan extends the payload and fixes correctness/UX bugs.
- This is the prerequisite for plan-0023 (CloudKit): the CloudKit-compat schema
  changes there will otherwise hit the very wipe path this plan removes.
- Constraints from CLAUDE.md: privacy-first (backups are sensitive — no
  auto-upload, no logging of contents), typed errors surfaced not swallowed,
  `os.Logger` only (no `print`), no PII in logs, ≥90% coverage / 100% domain,
  files < 300 lines.

## Scope

### In
- Replace the destructive `try? removeItem(storeURL)` fallback with a
  **back-up-then-recreate** strategy: move the failed store aside (timestamped
  copy kept in the app container) instead of deleting it, and log via
  `os.Logger` that a recovery happened (counts/category only, never contents).
- Add `UserProfile` to the export bundle and restore it on import (upsert into
  the single profile, not a second row).
- Fix stale export: regenerate the share file from content, not `events.count`.
- Surface import failures (bad file / decode error / unknown bundle version) to
  the user instead of swallowing with `try?`.
- Add and check `ExportBundle.version` on import; reject unknown future versions
  with a clear message.
- Bump bundle `version` to 2 (adds profile) while still importing v1 files.
- Tests for all of the above (domain round-trip is 100%).
- Living-docs updates (architecture/domain/README/DEVLOG/roadmap/context).

### Out
- CloudKit / sync (plan-0023).
- A full `SchemaMigrationPlan` with versioned schemas — that is its own task and
  is required before App Store submission (tracked in open-questions). This plan
  only makes the *failure* path non-destructive; it does not add real migrations.
- DrinkControl CSV import changes (that path stays as-is; restore of DrinkControl
  backups is explicitly out of scope per the user).
- Exporting `DrinkTemplate` (the entity is unused in production; revisit only if
  templates become user-editable).
- iCloud backup of the export file (privacy: backups stay local / user-shared).

## Implementation steps

Numbered, ordered; each step ≈ one commit.

1. **Non-destructive store recovery.** In `drinkpulseApp.swift`, extract the
   container bootstrap into a small testable helper type (e.g.
   `StoreBootstrap` in `Domain/Persistence/`) so the recovery logic is unit
   testable without `@main`. On open failure: move the existing store files
   (`.store`, `.store-wal`, `.store-shm`) to a timestamped
   `RecoveredStores/` subfolder in Application Support (kept, not deleted),
   then create a fresh container. Log one `os.Logger` line at `.error`
   (subsystem `com.drinkpulse.app`, category `persistence`) recording that
   recovery ran — no file paths with user identifiers, no data.
2. **Export payload v2 (+ profile).** Add an optional `profile` field to
   `ExportBundle` and a `ProfileRecord` value type mirroring `UserProfile`'s
   stored fields. Bump `version` to 2. `DataExporter.encode` takes the profile
   and includes it; keep encoding events as today.
3. **Stale-export fix.** In `DataSection`, drive temp-file regeneration off a
   content signature (e.g. a hash of events' identifying fields + profile),
   not `events.count`, so edits refresh the share file. Keep regeneration
   cheap and on `.task(id:)`.
4. **Import profile + version handling.** `DataImporter` decodes v1 and v2.
   On unknown/newer `version`, throw a typed `ImportError.unsupportedVersion`.
   When a `profile` is present, upsert it into the existing single `UserProfile`
   (overwrite fields) rather than inserting a duplicate; if none exists, insert
   one. Events import unchanged (dedup preserved).
5. **Surface import errors.** Replace the `try?`/silent `guard … else { return }`
   in `DataSection` import handlers with typed-error propagation that feeds the
   existing result alert (extend it with an error branch). Bad file, unreadable
   data, decode failure, and unsupported version all show a message.
6. **Tests** (see Tests required).
7. **Living docs + checklist.** Update domain.md (backup payload now includes
   profile; version 2), architecture.md (StoreBootstrap recovery helper, no
   silent wipe), README (backup = full state), DEVLOG, roadmap, current-focus,
   open-questions. Run file-size + coverage gates.

## Files

| File | Action |
|------|--------|
| `drinkpulse/drinkpulseApp.swift` | Modify — delegate bootstrap to helper |
| `drinkpulse/Domain/Persistence/StoreBootstrap.swift` | Create — testable container open + non-destructive recovery |
| `drinkpulse/Domain/DataTransfer/ExportBundle.swift` | Modify — version 2, optional `profile` |
| `drinkpulse/Domain/DataTransfer/ProfileRecord.swift` | Create — Codable mirror of UserProfile stored fields |
| `drinkpulse/Domain/DataTransfer/DataExporter.swift` | Modify — encode profile; signature helper |
| `drinkpulse/Domain/DataTransfer/DataImporter.swift` | Modify — version check, typed errors, profile upsert |
| `drinkpulse/Features/Settings/Components/DataSection.swift` | Modify — content-based regen, surface errors |
| `drinkpulseTests/StoreBootstrapTests.swift` | Create |
| `drinkpulseTests/DataExportImportTests.swift` | Create/Modify — round-trip incl. profile, version, errors |
| `docs/domain.md`, `docs/architecture.md`, `README.md` | Modify — living docs |

## Open questions

- [ ] Recovered-store retention: keep all timestamped copies, or keep only the
      most recent N to bound disk use? (options: keep-all / keep-last-3) —
      lean keep-last-3.
- [ ] Should "Delete all data" also clear `RecoveredStores/`? (options: yes /
      no) — lean yes, so the destructive action is complete and predictable.
- [ ] Profile restore conflict: when both an existing profile and an imported
      profile exist, overwrite silently or ask the user? (options:
      overwrite / prompt) — lean overwrite (single-user, restore intent).

## Tests required

- **StoreBootstrap**: opens cleanly when schema matches; on a forced
  open-failure it (a) does NOT delete the original files, (b) moves them to
  `RecoveredStores/`, (c) returns a working fresh container. Use a temp
  on-disk store, not the app container.
- **Export round-trip incl. profile**: export → import into an empty store
  reproduces every event field *and* the profile fields; idempotent re-import
  skips all events and leaves a single profile.
- **Version handling**: v1 file (no profile) imports successfully; a bundle
  with an unknown future `version` throws `unsupportedVersion`.
- **Error surfacing**: unreadable/garbage data and decode failure produce a
  typed error (the view-level alert is exercised by the handler returning an
  error, not a nil result).
- **Profile upsert**: importing a profile when one already exists overwrites
  in place (still exactly one `UserProfile`), and inserts when none exists.
- Regression: edit an event (count unchanged) → export signature changes
  (covers the stale-file bug).
