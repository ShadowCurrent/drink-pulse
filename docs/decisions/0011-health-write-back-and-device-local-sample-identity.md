# ADR-0011 — Apple Health write-back & device-local sample identity

**Status**: accepted (plan-0036)
**Date**: 2026-06-29
**Builds on**: [ADR-0008](0008-services-layer.md) (Services layer),
[ADR-0009](0009-versioned-schema-and-migration-plan.md) /
[ADR-0010](0010-cloudkit-ready-identity-and-lww.md) (versioned schema + identity).

## Context

plan-0036 mirrors logged drinks into Apple Health, opt-in and off by default. Two
facts shaped the design and contradicted the original roadmap premise:

1. **HealthKit has no grams-based alcohol type.** The roadmap assumed
   `dietaryAlcohol` (grams) — it does not exist. The only writable alcohol-logging
   type is `HKQuantityTypeIdentifier.numberOfAlcoholicBeverages`, a **count** where
   Apple fixes one beverage = a US standard drink = **14 g** pure alcohol.
   (`bloodAlcoholContent` is BAC %, an estimate — out of scope, belongs to the
   future BAC feature.)
2. **An HKSample UUID is device-scoped, not portable.** It is valid only in the
   Health store that created it; Apple's own Health iCloud sync does not guarantee a
   stable UUID across devices. App deletion does **not** remove Health samples (they
   persist until the user clears them), and our SwiftData store — including any
   cached sample UUID — is wiped with the app. So duplicates can arise on
   reinstall/restore and on multi-device sync.

## Decision

1. **Write `numberOfAlcoholicBeverages` as an exact fractional count** =
   `ConsumptionEvent.pureAlcoholGrams / 14.0`. `HKQuantity` count is a `Double`, so
   precision is preserved (e.g. 500 ml @5% → 1.409); grams are recoverable as
   `count × 14`. The 14 g divisor is **fixed** (Apple's definition), independent of
   the user's guideline/display unit — so Health values never shift on a unit toggle,
   matching the calories/BAC posture of using physical 0.789. The grams→count
   conversion lives in `HealthKitAdapter`; the `HealthWriting.save(grams:)` API stays
   grams-based. **No calculation-module change.**
2. **Durable identity = sample metadata `dp_event_uuid` = `ConsumptionEvent.uuid`**
   (stable, synced, backup-preserved). Before any write/backfill we query Health for
   that key and **relink** an existing sample instead of writing a duplicate —
   idempotent across reinstall, restore-to-new-device, Health-sync-off, manual
   deletes, and CloudKit multi-device. This requires **read** authorization, so the
   integration is **read + write** (`NSHealthShareUsageDescription` +
   `NSHealthUpdateUsageDescription`).
3. **`ConsumptionEvent.healthKitUUID: UUID?` is a device-local cache only** —
   **never exported, never synced** (SchemaV4, additive optional). It just skips a
   re-query on the same device; the metadata key is the source of truth. Considered
   and rejected including it in backup/CloudKit: it doesn't remove the read scope
   (must still verify against the live store), adds a stale-trust hazard, and feeds
   other devices a meaningless id.
4. **Best-effort, non-blocking.** Every Health op (denied, revoked, error) is caught
   and logged by category (no PII) and never blocks or reverts the in-app
   log/edit/delete. Authorization is requested on opt-in (Settings or the onboarding
   4th step); denied → inline hint, never a nag.
5. **Service shape** (ADR-0008): `HealthWriting` protocol + `HKHealthStore` adapter +
   non-prompting `UITestHealthStore` stub; `@MainActor HealthService` mediates,
   serialized per `event.uuid` to avoid an edit→delete race. Delete uses a
   value-based `removeSample(healthKitUUID:eventUUID:)` so the UI can delete the
   SwiftData event immediately while the sample is removed off the sync path.

## Consequences

- Health surfaces drinks as "Alcohol Consumption" (a count), not a gram mass — copy
  says "drinks", never grams.
- Duplicates are structurally prevented without trusting a portable sample id.
- Device install needs the HealthKit capability provisioned (free dev provisioning
  generally allows it; App Store needs the paid account). Simulator + UI tests need
  neither — the stub avoids real HealthKit.
- Read access is requested even though the feature is "write-back": it is used only
  to dedup against the app's own samples, never to import data into the app.
