# 0036 — Execution journal

Append-only. Frozen plan: `plan.md` (2026-06-29). Executed by **separate Opus
session(s)** (owner direction); parallelize independent waves where useful.

---

## 2026-06-29 — Handoff (planning session, no feature code)

Plan frozen, decisions locked. No production code written in this session — only
plan/docs/CLAUDE.md. The CLAUDE.md forward-compat rule (CloudKit + HealthKit)
added this session governs every step below.

### Confirmed decisions (owner)
1. Backfill = **ask at enable** (dialog: all-history vs new-only).
2. Error model = **best-effort, non-blocking** — Health failure never blocks or
   rolls back the in-app log/edit/delete; `log.error` by category, no PII, no
   alert beyond Settings auth state. Resolves the revoked-permission sub-question.
3. `healthKitUUID` = **device-local** — NOT synced (CloudKit), NOT exported;
   foreign/absent id → "write fresh".
4. **New ADR-0011** (device-local Health sample identity) — not a note in 0008.
5. Grams written = `ConsumptionEvent.pureAlcoholGrams` (0.789). No calc change.
6. Schema = **new SchemaV4 + v3→v4 stage** (never amend V3) — additive optional
   `healthKitUUID: UUID?`, default nil.

### Wave plan + dependencies (for one or many sessions)

**Critical path is mostly sequential — W1 then W3→W4→W5.** W2 and W6 are
independent and safe to run in a *parallel* session if desired.

- **W1 — Schema (foundation, BLOCKS W3/W5).**
  - Verify `Schemas/SchemaV3.swift` is a self-contained snapshot (own nested
    `@Model` copies), not aliasing live classes; if it aliases, freeze it first.
  - Add live `ConsumptionEvent.healthKitUUID: UUID?` (default nil).
  - Add `Schemas/SchemaV4.swift` (`Schema.Version(4,0,0)`, live classes).
  - `MigrationPlan`: `schemas += SchemaV4`; add `v3ToV4` (lightweight if SwiftData
    infers the optional add; else a no-op custom stage destination = live types).
  - Tests: `MigrationTests` v3→v4 (seed V3 on disk → reopen V4 → data intact,
    `healthKitUUID == nil`, no recovery). `ComprehensiveRoundTripTests`: assert
    `healthKitUUID` is NOT in the export bundle and round-trips unchanged (nil).
  - **Touches:** `Domain/ConsumptionEvent.swift`, `Schemas/`, `MigrationPlan.swift`,
    test files. ⚠ Conflicts with any other schema work — single owner.

- **W2 — Platform protocol + adapters (PARALLEL-SAFE, new files only).**
  - `Services/HealthWriting.swift` (protocol per plan), `HealthAuthStatus` enum.
  - `Services/HealthKitAdapter.swift` (real `HKHealthStore`; coverage-excluded).
  - `Services/UITestHealthStore.swift` (launch-arg-gated non-prompting stub).
  - No dependency on W1 (operates on grams + UUID, not the model). Can start
    immediately in a parallel session.

- **W3 — HealthService (needs W2; field from W1 only for the hooks, not the
  service API).**
  - `Services/HealthService.swift` (`@MainActor`, injected `HealthWriting`):
    requestAuthorization / write / update (delete-old+write) / remove / backfill.
    All best-effort (catch, log category, never throw to UI). Serialize per-event
    ops (key by `persistentModelID`) to avoid edit→delete races.
  - `HealthServiceTests` (≥85%): authorized/denied/unavailable; write stores UUID;
    update deletes-then-writes; remove clears; backfill batches; every error path
    swallowed + event still saved — via a `HealthWriting` fake.

- **W4 — Settings UI (needs W3).**
  - `HealthSection` glass card (toggle + state) in `SettingsView`; persisted
    `dp_health_write_enabled` (AppStorageKeys); first-enable backfill dialog;
    denied → inline message + Open Settings (reuse Reminders pattern).

- **W5 — Wire hooks (needs W1 + W3).**
  - Add Drink save, Edit save, History/context-menu delete call HealthService
    when enabled, fire-and-forget (`Task { await … }`) — UI never waits.

- **W6 — Entitlement + Info.plist (PARALLEL-SAFE).**
  - HealthKit capability; `NSHealthUpdateUsageDescription` (+ Share string only
    if the API surface needs it). English strings. Flag device-vs-simulator to
    owner (simulator/UI tests need no paid account).

- **W7 — Close-out (last, single session).**
  - `ADR-0011`; `HealthSettingsUITests` (toggle + backfill dialog via the stub);
    full suite + coverage (Services ≥85%, overall ≥90%); no file > 300; living
    docs (architecture Services note, domain Health-write note, roadmap 🗓→✅,
    product if scope text changes); DEVLOG; INDEX status; context files.

### Coordination notes for parallel sessions
- Single-owner files (do NOT touch from two sessions): `MigrationPlan.swift`,
  `ConsumptionEvent.swift`, `SettingsView.swift`, `drinkpulseApp.swift`,
  `AppStorageKeys`, `Localizable.xcstrings`, all living docs + this file.
- W2 and W6 are the only cleanly-parallel waves (new files / project settings).
  Everything else shares the model or Settings and should serialize.
- Each executing session: append a dated entry below with what landed + gates.

### Gates (every session, before declaring its wave done)
Build clean (0 warnings) · suite green · no file > 300 · no calc-module change ·
no PII in logs · no new network. Final wave: coverage report + UI test ran.
