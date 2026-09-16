# C008 — VersionedSchema and migration-plan replacement boundary

**Status:** owner outcome pending — not authorized  
**Proposed destination:** Phase 10 verification

## Current behavior

`drinkpulse/Domain/Persistence/MigrationPlan.swift:7-61`; `Schemas/SchemaV1.swift:4-133`; `SchemaV2.swift:4-70`; `SchemaV3.swift:4-72`; `SchemaV4.swift:4-12`; and `drinkpulseTests/Domain/Persistence/MigrationTests.swift:19-255` implement the current V1→V4 migration path. ADR-0009 requires shipped snapshots to stay immutable and a new model shape to add a version and stage.

## Source-backed decision table

**Availability:** The selected iOS 27 minimum satisfies the current API/toolchain availability described by the official source below; no replacement is inferred from age alone.

| Topic | Evidence |
| --- | --- |
| Official source | [Apple VersionedSchema](https://developer.apple.com/documentation/swiftdata/versionedschema) (checked 2026-09-16). No deprecation or replacement is claimed. |
| Proposed behavior | Retain current migration infrastructure; any future schema/model proposal must add a new schema and migration stage rather than edit snapshots. |
| Benefit | No source-backed target-raise benefit exists for a replacement. |
| Cost | A future change requires legacy/current-store fixtures, migration proof, and CloudKit-off/identity regression evidence. |
| Alternatives | **Retain** V1–V4 snapshots and existing stages. |
| Compatibility | Current SwiftData APIs are available on iOS 27. |
| Data / accessibility / lifecycle risk | High data/lifecycle risk: snapshot mutation can lose fields, corrupt migrations, or change UUID/LWW/Health-cache semantics. Accessibility is unaffected directly. |

## Recommendation and proposed scope

Recommend retain. If the owner later approves a model-shape change, scope it to a new version/stage and full old-to-new proof; it is excluded from Phase 10 until then.

## Owner decision record

**Outcome:** pending  
**Decision date:**  
**Exact scope:**  
**Owner reason:**
