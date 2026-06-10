# 0023 — CloudKit sync (SwiftData + iCloud)

**Status**: draft
**Size**: large
**Created**: 2026-06-03

## Summary

Enable cross-device sync and cloud backup of DrinkPulse data using SwiftData's
built-in CloudKit integration — no custom backend, per the project's
non-negotiable stack. The current models are **not** CloudKit-compatible:
`UserProfile` uses an `@Attribute(.unique)` constraint (unsupported with
CloudKit), and `ConsumptionEvent`, `DrinkTemplate` and `UserProfile` have
non-optional stored properties with no default values (CloudKit requires every
attribute to be optional or defaulted). This plan makes the schema
CloudKit-ready, wires up the private CloudKit database + entitlements, replaces
the now-impossible unique constraint with an app-level singleton invariant, and
defines sync-conflict behaviour.

This is an **outward-facing, hard-to-reverse change** (enabling CloudKit writes
user data to iCloud). Per CLAUDE.md it must be proposed and explicitly approved
before implementation, and anything touching sync-conflict resolution must be
proposed, not silently implemented.

## Context

- Triggered by the 2026-06-03 audit; user wants iCloud after daily on-device use.
- **Hard dependency on plan-0022**: the schema edits below are themselves a
  schema change. Until plan-0022 removes the destructive open-failure path,
  shipping these changes would wipe the user's accumulated data. Do not start
  0023 until 0022 is completed and a migration story exists.
- SwiftData + CloudKit constraints (the blockers found in the audit):
  - No `@Attribute(.unique)`.
  - Every attribute optional **or** has a default value.
  - Relationships must be optional and have inverses. (`ConsumptionEvent.template`
    is already optional; `DrinkTemplate.events` already has an inverse + `[]`
    default — these are fine.)
- CLAUDE.md: privacy-first (CloudKit is the *only* permitted network path),
  additive/backward-compatible changes preferred, schema changes need a
  migration plan before shipping, sync-conflict resolution must be proposed.

## Scope

### In
- Make all three `@Model` types CloudKit-compatible:
  - `UserProfile`: drop `@Attribute(.unique)`; give every stored property a
    default; preserve the single-profile invariant in app code instead.
  - `ConsumptionEvent`: give `timestamp/volumeMl/abv/name/category/icon`
    defaults (or make optional where a default is meaningless).
  - `DrinkTemplate`: give all stored properties defaults.
- App-level singleton enforcement for `UserProfile` (fetch-or-create; de-dupe
  on read if CloudKit produced two), since the DB constraint is gone.
- `ModelConfiguration` with `cloudKitDatabase: .private("iCloud.com.drinkpulse.app")`;
  add CloudKit + push entitlements and the "Remote notifications" background mode.
- A `SchemaMigrationPlan` (lightweight) covering the current → CloudKit-ready
  schema so existing on-device data migrates instead of being recreated.
- Defined, documented sync-conflict behaviour (proposal first — see Open
  questions) — default to last-writer-wins per field, which is SwiftData's
  CloudKit default, and confirm it is acceptable for this data.
- Tests for the singleton-enforcement helper and any de-dupe logic.

### Out
- Custom CloudKit schema, CKRecord-level code, sharing, public database.
- Conflict-resolution UI / merge screens.
- Apple Watch / widget targets (separate future work).
- Migrating DrinkControl data (separate, already handled by import).

## Implementation steps

Numbered, ordered; each step ≈ one commit. **Do not start until 0022 is done
and this plan is approved (outward-facing change).**

1. **Singleton helper first (no schema change yet).** Introduce a
   `UserProfileStore`/helper that fetches the profile, creates one if absent,
   and collapses duplicates to a single canonical row (keep earliest, delete
   the rest). Route existing `profiles.first` call sites through it. Cover with
   tests. This makes step 2 safe.
2. **Schema → CloudKit-compatible.** Remove `@Attribute(.unique)` from
   `UserProfile.id`; add default values to every non-optional stored property
   across `UserProfile`, `ConsumptionEvent`, `DrinkTemplate`. Keep the public
   initializers' behaviour identical so call sites and snapshots are unaffected.
3. **Migration plan.** Add a `SchemaMigrationPlan` with the pre-change schema as
   V1 and the CloudKit-ready schema as V2 (lightweight migration — defaults +
   dropped constraint are non-destructive). Wire it into the container via the
   plan-0022 `StoreBootstrap`. Verify an existing store migrates with data
   intact (test on a seeded store before enabling CloudKit).
4. **Entitlements & capabilities.** Add iCloud (CloudKit) capability with the
   `iCloud.com.drinkpulse.app` container, the push entitlement, and the
   background mode. (Project/entitlement files — call out clearly; needs the
   Apple Developer account / signing.)
5. **Enable CloudKit on the configuration.** Set `cloudKitDatabase: .private(…)`
   in `StoreBootstrap`. This is the one-way switch — gate behind explicit
   approval. Validate the schema initializes against the dev CloudKit
   environment (CloudKit requires the schema to be pushed/initialized).
6. **Conflict behaviour.** Document the chosen strategy (Open questions) in
   architecture.md and an ADR; add a regression-style test only where there is
   app-level merge logic (SwiftData's built-in LWW needs no test).
7. **Living docs + ADR + checklist.** New ADR for "Enable CloudKit sync"
   (records the schema-compat changes, singleton-in-code decision, conflict
   strategy, and the irreversibility note). Update architecture.md, domain.md
   (defaults, no unique constraint, singleton enforced in code), README
   (sync now on), roadmap, context. Coverage + file-size gates.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Domain/UserProfile.swift` | Modify — drop unique, add defaults |
| `drinkpulse/Domain/ConsumptionEvent.swift` | Modify — add defaults |
| `drinkpulse/Domain/DrinkTemplate.swift` | Modify — add defaults |
| `drinkpulse/Domain/Persistence/UserProfileStore.swift` | Create — fetch-or-create + de-dupe |
| `drinkpulse/Domain/Persistence/StoreBootstrap.swift` | Modify — migration plan + CloudKit config |
| `drinkpulse/Domain/Persistence/DrinkPulseMigrationPlan.swift` | Create — V1→V2 lightweight |
| `drinkpulse/drinkpulse.entitlements` (+ project capabilities) | Modify — iCloud/CloudKit/push/background |
| Call sites using `profiles.first` (Root/Settings/Dashboard/etc.) | Modify — route via store helper |
| `docs/decisions/NNNN-enable-cloudkit-sync.md` | Create — ADR |
| `drinkpulseTests/UserProfileStoreTests.swift` | Create |
| `drinkpulseTests/MigrationTests.swift` | Create |

## Open questions

Must be resolved (with the user) before/while executing.

- [ ] **Approval to enable CloudKit** (outward-facing, one-way). Required before
      step 5. (options: approve now / hold)
- [ ] **CloudKit container id**: confirm `iCloud.com.drinkpulse.app` and that
      the bundle id / Apple Developer account are set up for it.
- [ ] **Sync-conflict resolution** for concurrent edits across devices.
      (options: SwiftData default last-writer-wins per field / custom merge)
      — proposal: accept LWW; this is low-stakes single-user data. Needs
      explicit sign-off per CLAUDE.md.
- [ ] **Defaults for `ConsumptionEvent`**: a drink with no real values is
      meaningless — use harmless defaults (e.g. `timestamp = .now`, numerics
      `0`, strings `""`, `category = .custom`) purely to satisfy CloudKit, since
      every insert sets them explicitly anyway. Confirm acceptable.
- [ ] **Initial-sync UX**: show any "syncing…" indication, or silent? Likely
      silent for v1.

## Tests required

- **UserProfileStore**: fetch-or-create returns the same instance on repeat;
  given two profiles it collapses to one (earliest kept) and the rest deleted;
  call sites see exactly one profile.
- **Migration**: a store seeded with the pre-change schema (events + profile)
  migrates to the CloudKit-ready schema with all data intact and exactly one
  profile.
- **Defaults**: initializers still produce identical objects (defaults never
  change behaviour for explicitly-set fields).
- Note: actual CloudKit round-trip / multi-device sync is an integration concern
  validated manually on-device against the dev iCloud environment, not in unit
  tests.
