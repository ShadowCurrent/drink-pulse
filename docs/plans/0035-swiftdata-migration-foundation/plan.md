# 0035 — SwiftData versioned-schema migration foundation

**Status**: in-progress
**Size**: medium
**Created**: 2026-06-28
**Frozen**: 2026-06-28

## Summary

Replace the current implicit/lightweight-inference approach to SwiftData
schema evolution with an **explicit, versioned migration foundation**: a
`VersionedSchema` baseline (`SchemaV1`) capturing the schema exactly as it
ships today, a `SchemaMigrationPlan` wired into the plan-0022
`StoreBootstrap`, and a reusable migration test harness. This is the
App-Store-submission blocker called out in `open-questions.md` and
`architecture.md`, and the hard prerequisite that plan-0023 (CloudKit)
builds on. **Infrastructure only — no model-shape changes, no CloudKit, no
behaviour change.**

## Context

What triggered this:

- The repo has **no** `VersionedSchema` / `SchemaMigrationPlan` / `MigrationStage`
  anywhere. Every schema change to date (`quantity`, `enteredUnit`,
  `priceCurrency`, the `ageYears` → `dateOfBirth` swap, `alcoholUnit` enum
  raw-value retirement) relied on SwiftData's **implicit** lightweight
  inference, with the plan-0022 `StoreBootstrap` non-destructive
  `RecoveredStores/` move-aside as the only safety net on an open failure.
- CLAUDE.md ("Change hygiene"): *"Schema changes to SwiftData models require
  a migration plan before shipping … A dev-only store-wipe fallback is
  acceptable in development only … never as the App Store strategy."*
- `architecture.md` (Persistence bootstrap): *"A real `SchemaMigrationPlan`
  is still required before App Store submission — `StoreBootstrap` only makes
  the failure path non-destructive; it does not add real migrations."*
- plan-0023 (CloudKit, draft) explicitly states a **hard dependency**: its
  CloudKit-compat schema edits are themselves a schema change and *"shipping
  these changes would wipe the user's accumulated data"* without a migration
  story. 0023 must not start until that story exists. This plan is that story.

Constraints carried in from the docs (all must hold):

- **Never store derived values.** `volumeMl` stays the frozen canonical truth;
  grams/calories/BAC/risk are always computed. (CLAUDE.md, domain.md, ADR-0007.)
- **No repository layer, no `ModelContext` in services.** A store migration
  touches the container bootstrap, not the `@Query` sites. (ADR-0004, ADR-0008.)
- **Prefer additive, backward-compatible, non-destructive changes.** (CLAUDE.md.)
- `StoreBootstrap` `RecoveredStores/` recovery stays as the genuine-corruption
  last resort — but with a real migration plan it should no longer fire on a
  *planned* schema change. (plan-0022, architecture.md.)

**Documentation contradiction to resolve (found during research):**
`open-questions.md` frames the migration need as migrating *v1
(`ageYears: Int`) → v2 (`dateOfBirth: Date?`)*. The **live `UserProfile`
already has `dateOfBirth: Date?`** and no stored `ageYears` (only a computed
getter) — that swap already shipped via the dev recovery path, and there are
no production users. Separately, **`domain.md` still lists `ageYears`** as a
current stored field — it is stale. This plan reconciles both: the historical
`ageYears` removal is treated as already-applied (pre-baseline), `SchemaV1`
is the **current** shape, and `domain.md` is corrected.

## Scope

### In

- **`SchemaV1` (`VersionedSchema`)** capturing the current 3-model schema
  (`DrinkTemplate`, `ConsumptionEvent`, `UserProfile`) exactly as it ships
  today — including `UserProfile.id`'s `@Attribute(.unique)` (that constraint
  is dropped later, in 0023, not here).
- **`MigrationPlan` (`SchemaMigrationPlan`)** with `schemas = [SchemaV1.self]`
  and `stages = []` (no migration stage yet — V1 is the baseline). The plan
  exists so the container is *governed by an explicit plan*, and so 0023 adds
  `SchemaV2` + one `MigrationStage` rather than introducing the whole concept.
- **Wire the plan into the container**: `StoreBootstrap.makeContainer` passes
  `migrationPlan: MigrationPlan.self` to `ModelContainer`; update the
  `drinkpulseApp` and `UITestSeed` call sites to match.
- **Migration test harness** (`drinkpulseTests/Domain/Persistence/`): a
  reusable helper that seeds an on-disk store under the current schema, closes
  it, reopens it via `MigrationPlan`, and asserts (a) data intact and (b) **no
  `RecoveredStores/` snapshot was created** (i.e. it opened by migration, not
  by recovery). Built so 0023 can drop in a V1→V2 case with one method.
- **Doc reconciliation**: fix `domain.md` (`ageYears` → `dateOfBirth`); update
  `architecture.md` persistence section to describe the versioning policy +
  the snapshot-on-divergence rule; resolve the migration open question;
  DEVLOG, roadmap, current-focus.
- **ADR-0009** documenting the versioned-schema approach, the
  snapshot-on-divergence policy, and the `StoreBootstrap` relationship.

### Out

- **Anything CloudKit** — enabling sync, `cloudKitDatabase:`, entitlements,
  dropping `@Attribute(.unique)`, adding defaults to every attribute,
  app-level singleton enforcement, conflict policy. All of that is plan-0023.
- **Any model-shape change.** `SchemaV1` == current live models. No field
  added, removed, renamed, or re-typed. Zero behaviour change.
- **Removing the deprecated `ConsumptionEvent.name`** — tied to 0023; it is a
  non-optional removal that needs a real `MigrationStage`, which 0023 owns.
- **Changing `RecoveredStores/` recovery behaviour** — it stays as-is, as the
  genuine-corruption fallback.

## Implementation steps

Numbered, ordered. Each step ≈ one commit.

1. **`SchemaV1`.** Create `drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift`:
   `enum SchemaV1: VersionedSchema` with
   `versionIdentifier = Schema.Version(1, 0, 0)` and
   `models: [any PersistentModel.Type] = [DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self]`.
   (References the live model classes — see Open question Q1 for the
   reference-now vs duplicate-now decision.)
2. **`MigrationPlan`.** Create `drinkpulse/Domain/Persistence/MigrationPlan.swift`:
   `enum MigrationPlan: SchemaMigrationPlan` with
   `schemas = [SchemaV1.self]` and `stages: [MigrationStage] = []`.
3. **Wire into the container.** In `StoreBootstrap.makeContainer`, build the
   `ModelContainer(for:migrationPlan:configurations:)` passing
   `MigrationPlan.self`. Keep the existing non-destructive recovery wrapper.
   Update `drinkpulseApp.swift` and `UITestSeed.makeContainer` so all three
   container construction paths go through the same migration plan. Confirm
   the `Schema` used for configuration stays consistent with `SchemaV1.models`.
4. **Migration test harness.** Add
   `drinkpulseTests/Domain/Persistence/MigrationTests.swift` (Swift Testing):
   a helper that creates an on-disk temp store (pattern from
   `StoreBootstrapTests`: `ModelConfiguration(schema:url:)`), seeds known
   `ConsumptionEvent` + `DrinkTemplate` + `UserProfile` data, releases the
   container, then reopens via `StoreBootstrap.makeContainer` (which now
   carries `MigrationPlan`). Assert: counts and key field values intact; no
   new folder under `RecoveredStores/` (proves clean open, not recovery).
5. **Docs reconciliation.**
   - `domain.md`: `UserProfile` field list `ageYears` → `dateOfBirth: Date?`
     (with computed `ageYears`); note the schema is now explicitly versioned.
   - `architecture.md` (Persistence bootstrap): describe `SchemaV1` +
     `MigrationPlan`, the snapshot-on-divergence rule, and that
     `RecoveredStores/` is now strictly the corruption fallback.
   - `open-questions.md`: resolve "SwiftData migration plan before App Store"
     — foundation delivered here; note CloudKit's V1→V2 stage remains in 0023;
     record the `ageYears`/`dateOfBirth` reconciliation.
   - `DEVLOG.md` (append), `roadmap.md`, `.claude/context/current-focus.md`.
6. **ADR-0009.** Create `docs/decisions/0009-versioned-schema-and-migration-plan.md`:
   the versioning approach, the snapshot-on-divergence policy (when the first
   divergent version lands, freeze the prior version's model definitions),
   how it composes with the plan-0022 `StoreBootstrap` recovery, and the
   decision from Q1.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift` | Create |
| `drinkpulse/Domain/Persistence/MigrationPlan.swift` | Create |
| `drinkpulse/Domain/Persistence/StoreBootstrap.swift` | Modify (pass `migrationPlan:`) |
| `drinkpulse/drinkpulseApp.swift` | Modify (call site) |
| `drinkpulse/UITestSeed.swift` | Modify (call site) |
| `drinkpulseTests/Domain/Persistence/MigrationTests.swift` | Create |
| `docs/domain.md` | Modify (ageYears → dateOfBirth) |
| `docs/architecture.md` | Modify (migration section) |
| `.claude/context/open-questions.md` | Modify (resolve) |
| `docs/DEVLOG.md` | Append |
| `docs/roadmap.md` | Modify |
| `.claude/context/current-focus.md` | Modify |
| `docs/decisions/0009-versioned-schema-and-migration-plan.md` | Create |
| `docs/plans/INDEX.md` | Modify (status) |

## Open questions

All resolved 2026-06-28 (owner sign-off) before freeze:

- **Q1 → (A) Reference live model classes now.** `SchemaV1.models` points at
  the live `@Model` classes. ADR-0009 records the snapshot-on-divergence rule:
  when 0023 first changes a model, that session must copy the then-current
  definitions into a frozen `SchemaV1` namespace **before** editing the live
  classes as `SchemaV2`.
- **Q2 → `Schema.Version(1, 0, 0)`.** ADR-0009 notes V1 is the first *explicit*
  version but already absorbed prior implicit lightweight migrations
  (`quantity`, `enteredUnit`, `priceCurrency`, `ageYears` → `dateOfBirth`,
  `alcoholUnit` raw-value retirement).
- **Q3 → Accept + verify on device.** Owner will export a backup on the real
  device before installing the post-change build. **Added requirement:** the
  export/import path must correctly map the *current* code's JSON fields onto
  the schema (0035 makes no shape change, so current == target). Pin this with
  a comprehensive round-trip test covering every current `ExportRecord` /
  `ProfileRecord` field — see Tests required.
- **Q4 → Infra-only.** All CloudKit-compat shape changes (drop `.unique`,
  defaults on every attribute, app-level singleton enforcement, removing
  deprecated `name`) stay in plan-0023 as `SchemaV2` + one `MigrationStage`.

### Original options (for the record)

- Q1 — Version-snapshot strategy. Two ways to define `SchemaV1`:
  - **(A) Reference the live model classes now (Recommended).** `SchemaV1.models`
    points at the current `@Model` classes. Lean, no duplication. When the
    first *divergent* schema lands (0023), that plan snapshots V1 by copying
    the then-current model definitions into a frozen `SchemaV1` namespace, then
    edits the live classes as `SchemaV2`. Risk: discipline-dependent — the
    snapshot must happen at the moment of divergence.
  - **(B) Duplicate the model definitions inside `SchemaV1` now.** Robust and
    self-contained, but V1 is byte-identical to the live models today, so it is
    pure redundancy that can silently drift until 0023 makes it pay off.

  Recommendation: **(A)**, with the snapshot rule captured in ADR-0009. Confirm.
- [ ] **Q2 — `versionIdentifier`.** Baseline `Schema.Version(1, 0, 0)`. Confirm.
- [ ] **Q3 — Developer device store.** If the dev's on-device store predates
  the `ageYears` → `dateOfBirth` swap, opening under `SchemaV1` may still hit
  the `RecoveredStores/` move-aside once (non-destructive; recoverable from
  disk). No production users exist, so this is dev-only. Accept and verify on
  the dev device before declaring done? (Recommended: yes.)
- [ ] **Q4 — Scope boundary.** Confirm this plan stays infra-only and all
  CloudKit-compat shape changes (drop `.unique`, defaults, singleton-in-code)
  remain in plan-0023. (Recommended: yes — keeps each change isolated and the
  migration foundation behaviour-neutral.)

## Tests required

- **Migration harness test** (new): seeded on-disk store reopens under
  `MigrationPlan` with all data intact and **no** `RecoveredStores/` snapshot
  created.
- **`StoreBootstrapTests`** stay green — recovery path is unchanged.
- **Export/import round-trip (Q3 requirement)**: a comprehensive test that
  exports a fully-populated dataset (every current field set:
  `timestamp/volumeMl/abv/quantity/enteredUnit/name/category/icon/customName/
  notes/price/priceCurrency` on `ConsumptionEvent`; all `UserProfile` fields
  incl. `dateOfBirth`), imports it into a fresh store, and asserts every field
  round-trips. Confirms the importer maps the current code's JSON onto the
  (unchanged) schema before the owner installs the post-change build over real
  device data. Existing `DataTransfer` suite stays green.
- Build clean, zero warnings; no file > 300 lines; overall coverage ≥ 90%.
  (`SchemaV1`/`MigrationPlan` are declarative container wiring — like the rest
  of the persistence bootstrap, exercised through the harness, not unit-tested
  line-by-line.)

## Execution parallelization

The user asked whether execution can run across multiple simultaneous
sessions. Assessment: **largely sequential, not worth splitting.**

- Steps 2 → 3 depend on 1; step 4 depends on 3. That is the critical path and
  cannot be parallelized.
- Steps 5 (docs) and 6 (ADR) are independent of the code and *could* run in a
  separate session/worktree concurrently — but they depend on the Q1 decision
  and are small; the coordination + merge overhead exceeds the benefit for a
  medium plan.

Recommendation: **a single execution session**, and — per the established
model-workflow (Opus plans/reviews, Sonnet executes) — hand this frozen plan
to **one Sonnet 4.6 session**, executed steps 1→6 in order. If the owner still
wants concurrency, the only clean split is *code (1–4)* in the main tree and
*docs+ADR (5–6)* in a `worktree` session — flagged here as available, not
recommended.
