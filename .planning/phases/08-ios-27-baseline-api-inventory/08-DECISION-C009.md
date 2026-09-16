# C009 — Backup/export and import representation boundary

**Status:** owner-approved eligibility recorded — modernization not started
**Proposed destination:** Phase 10

## Current behavior

`drinkpulse/Domain/DataTransfer/BackupExport.swift:5-44`, `DataImporter.swift:4-157`, `ExportBundle.swift:3-17`, `ExportRecord.swift:3-64`, `ProfileRecord.swift:3-42`, `TemplateRecord.swift:3-62`, `BackupDocument.swift:3-20`, `ImportError.swift:3-15`, `ImportResult.swift:3-8`, and `DrinkControlImporter.swift:3-112` define v2 export/import. Coverage is in `ComprehensiveRoundTripTests.swift:1-84`, `DataBackupExportTests.swift:1-71`, `DataImporterEdgeCaseTests.swift:1-135`, `DataImporterRoundTripTests.swift:1-231`, `DataImporterUpsertTests.swift:1-129`, and `DrinkControlImporterTests.swift:1-192`.

## Source-backed decision table

**Availability:** The selected iOS 27 minimum satisfies the current API/toolchain availability described by the official source below; no replacement is inferred from age alone.

| Topic | Evidence |
| --- | --- |
| Official source | [Transferable](https://developer.apple.com/documentation/coretransferable/transferable) and [Swift 6.4 release notes](https://www.swift.org/blog/swift-6.4-released/) (checked 2026-09-16). No deprecation/replacement is claimed. |
| Proposed behavior | Retain v2 JSON, atomic `FileRepresentation`, ISO-8601, UUID/LWW upsert, legacy heuristic, and profile restore. |
| Benefit | No current-platform benefit supports a format or importer rewrite. |
| Cost | Future work needs round-trip, legacy-v1/v2, malformed-import, upsert, and existing-data proof. |
| Alternatives | **Retain** the compatibility contract. |
| Compatibility | Existing APIs remain available on iOS 27. |
| Data / accessibility / lifecycle risk | High persisted-data risk: a changed format/rule can lose values, identity, or profile state. Accessibility is indirect; lifecycle risk is low. |

## Recommendation and proposed scope

Recommend retain. A future owner-approved scope must name the exact format/model change and preserve compatibility or add a tested migration; it is not a Phase 10 authorization now.

## Owner decision record

**Outcome:** approve
**Decision date:** 2026-09-16
**Exact scope:** Nie zmieniać modelu danych ani formatu kopii zapasowej bez konkretnego celu biznesowego; modernizacja ogranicza się do testów zgodności i potwierdzenia granicy eksportu/importu.
**Owner reason:** Modernizacja ma być ostrożna, oparta na mierzalnych problemach i testach regresji; bez szerokich przebudów ani zmian danych/formatów bez celu biznesowego.
**Owner response:** `zatwierdzam wszystkie C001–C012 z tym powodem, jednak nie zaczynaj modernizacji, jedynie zapisz stan tak abym po wyczyszczeniu kontekstu mogl go wznowic jutro`

No modernization has started. Only compatibility testing and boundary confirmation are eligible for Phase 10; no data-model or backup-format change is authorized.
