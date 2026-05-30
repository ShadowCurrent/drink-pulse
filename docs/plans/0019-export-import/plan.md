# 0019 — File export / import + DrinkControl migration

**Status**: draft
**Size**: medium
**Created**: 2026-05-30

## Summary

Add file-based backup (export all events to JSON, re-import from JSON) and a
one-time migration importer for DrinkControl CSV files. Primary motivation:
the owner has 101 historical entries in DrinkControl (2026-01-02 – 2026-05-29)
that need to move into DrinkPulse before daily use begins.

No iCloud sync involved — this is offline file sharing via the system share sheet
and `fileImporter`.

## Context

DrinkControl exports a semicolon-delimited CSV. The actual format (analysed from a
real export file) is:

```
AccountedForDate;RegisteredDate;Name;Serving;DrinkSizeInMl;AlcoholVolumePercentage;
NumberOfDrinks;PriceForSingleDrink;TotalPrice;TotalAlcoholInGrams;
TotalUnits(Germany);TotalAlcoholCalories;TotalCalories
```

Key observations:
- `AccountedForDate` is always `12:00:00` — it is the "accounted date" without time.
- `RegisteredDate` carries the exact log time (e.g. `2026-01-10 20:42:48`). Use this
  as the event timestamp.
- `AlcoholVolumePercentage` is a plain fraction (0.05 = 5%), matching DrinkPulse's
  convention.
- `NumberOfDrinks` can be > 1 (e.g. `3` bottles logged together as one row).
- `TotalAlcoholInGrams` uses scientific density 0.789 g/ml — **do not import this
  value**; re-derive from `DrinkSizeInMl × NumberOfDrinks × ABV × 0.8` per
  DrinkPulse convention.
- Categories seen in the real file: `beer`, `other`, `cocktail`, `wine`, `vodka`.
  `vodka` maps to `.spirits`; `other` maps to `.custom`.
- No prices in the real export (all zero) — skip price import.

## Scope

### In

**Phase 1 — Native DrinkPulse JSON round-trip:**
- `DataExporter`: `[ConsumptionEvent]` → JSON `Data`
  (file: `drinkpulse-backup-YYYY-MM-DD.json`)
- `DataImporter`: JSON `Data` → insert `ConsumptionEvent`s, skip duplicates
- Deduplication by `(timestamp, volumeMl, abv)` — no schema change required
- `ImportResult` value type: `(imported: Int, skipped: Int, failed: Int, errors: [String])`

**Phase 2 — DrinkControl CSV importer:**
- `DrinkControlImporter`: parses the semicolon-delimited CSV format described above
- Category mapping table (see Implementation steps)
- `customName` set to `Serving` name from the row (e.g. "Bottle", "Med bottle")
- `NumberOfDrinks > 1` → single event with `volumeMl = size × count`
  (consistent with DrinkPulse's count picker)
- Same `ImportResult` and deduplication as Phase 1

**UI (Settings screen — new "Data" section):**
- Export button → `ShareLink` with JSON file
- "Import DrinkPulse backup" button → `fileImporter` (`.json`)
- "Import from DrinkControl" button → `fileImporter` (`.commaSeparatedText`)
- Import result: `.alert` showing imported / skipped / failed counts
- `DataSection.swift` extracted as a component to keep `SettingsView` under 300 lines

### Out

- iCloud backup / sync (separate plan)
- Incremental or scheduled exports
- Export of `DrinkTemplate` (user presets) — events only for now
- Other third-party apps (Drinkaware, AlcoDroid, etc.)
- Editing imported events before confirming (bulk edit is out of scope)

## Category mapping (DrinkControl → DrinkPulse)

| DrinkControl `Name` | DrinkPulse `DrinkCategory` | `name`    | `icon` |
|---------------------|---------------------------|-----------|--------|
| `beer`              | `.beer`                   | "Beer"    | "🍺"   |
| `wine`              | `.wine`                   | "Wine"    | "🍷"   |
| `champagne`         | `.champagne`              | "Champagne" | "🥂" |
| `spirits`           | `.spirits`                | "Spirits" | "🥃"   |
| `vodka`             | `.spirits`                | "Spirits" | "🥃"   |
| `whisky` / `whiskey`| `.spirits`                | "Spirits" | "🥃"   |
| `rum`               | `.spirits`                | "Spirits" | "🥃"   |
| `gin`               | `.spirits`                | "Spirits" | "🥃"   |
| `cocktail`          | `.cocktail`               | "Cocktail"| "🍹"   |
| `cider`             | `.cider`                  | "Cider"   | "🍺"   |
| `other` / unknown   | `.custom`                 | "Other"   | "🥤"   |

## Native JSON export format

```json
{
  "version": 1,
  "exportedAt": "2026-05-30T14:00:00Z",
  "events": [
    {
      "timestamp": "2026-01-02T18:30:00Z",
      "volumeMl": 500,
      "abv": 0.05,
      "name": "Beer",
      "category": "beer",
      "icon": "🍺",
      "customName": null,
      "notes": null,
      "location": null,
      "price": null
    }
  ]
}
```

`category` is the raw `DrinkCategory.rawValue` string. `template` is not exported
(it's a SwiftData relationship to local templates — not portable).

## Implementation steps

1. **`Domain/DataTransfer/ExportRecord.swift`** — `Codable` struct mirroring
   `ConsumptionEvent` (no SwiftData dependency).

2. **`Domain/DataTransfer/ExportBundle.swift`** — `Codable` wrapper:
   `{ version: Int, exportedAt: Date, events: [ExportRecord] }`.

3. **`Domain/DataTransfer/DataExporter.swift`** — `struct DataExporter`:
   - `func export(_ events: [ConsumptionEvent]) throws -> Data` (JSON-encoded bundle)
   - `func fileName(for date: Date) -> String` → `"drinkpulse-backup-YYYY-MM-DD.json"`

4. **`Domain/DataTransfer/DataImporter.swift`** — `struct DataImporter`:
   - `func `import`(_ data: Data, into context: ModelContext) throws -> ImportResult`
   - Decode bundle, iterate events, insert if not duplicate.
   - Deduplication: `abs(existing.timestamp.timeIntervalSince(candidate.timestamp)) < 1`
     AND `existing.volumeMl == candidate.volumeMl`
     AND `abs(existing.abv - candidate.abv) < 0.001`

5. **`Domain/DataTransfer/DrinkControlImporter.swift`** — `struct DrinkControlImporter`:
   - `func `import`(_ csvString: String, into context: ModelContext) throws -> ImportResult`
   - Parse semicolon-delimited rows (skip header), map fields per table above.
   - Per-row errors: caught and counted as `failed`; do not abort the whole import.
   - Same deduplication logic as `DataImporter`.

6. **`Features/Settings/Components/DataSection.swift`** — `View`:
   - Export button (calls `DataExporter`, drives `ShareLink`)
   - Import DrinkPulse backup button (drives `fileImporter`)
   - Import from DrinkControl button (drives `fileImporter`)
   - Holds `@State private var importResult: ImportResult?` and `.alert` presentation.

7. **`SettingsView.swift`** — add `DataSection()` to the form; stay under 300 lines.

8. **Tests** (two files):
   - `DataExportImportTests.swift`:
     - round-trip: export 3 events → import → same 3 events in store
     - deduplication: import same bundle twice → still 3 events
     - empty export: zero events → valid JSON, zero events on import
   - `DrinkControlImporterTests.swift`:
     - valid row: beer/Bottle/500/0.05/1 → correct `ConsumptionEvent` fields
     - NumberOfDrinks > 1: size × count stored as single event volumeMl
     - vodka category → `.spirits`
     - other/unknown category → `.custom`
     - malformed row: counted as failed, rest imported successfully
     - duplicate row: counted as skipped

## Files

| File | Action |
|------|--------|
| `drinkpulse/Domain/DataTransfer/ExportRecord.swift` | Create |
| `drinkpulse/Domain/DataTransfer/ExportBundle.swift` | Create |
| `drinkpulse/Domain/DataTransfer/DataExporter.swift` | Create |
| `drinkpulse/Domain/DataTransfer/DataImporter.swift` | Create |
| `drinkpulse/Domain/DataTransfer/DrinkControlImporter.swift` | Create |
| `drinkpulse/Features/Settings/Components/DataSection.swift` | Create |
| `drinkpulse/Features/Settings/SettingsView.swift` | Modify |
| `drinkpulse/Localizable.xcstrings` | Modify |
| `drinkpulseTests/DataExportImportTests.swift` | Create |
| `drinkpulseTests/DrinkControlImporterTests.swift` | Create |
| `drinkpulse.xcodeproj/project.pbxproj` | Modify (test files) |

No SwiftData schema change.

## Open questions

- [ ] **Q1 — NumberOfDrinks > 1**: Import as single event with `volumeMl = size × count`
  (option A — consistent with DrinkPulse count picker, default) **OR** split into N
  separate events at the same timestamp (option B)?

- [ ] **Q2 — Timestamp source**: Use `RegisteredDate` (actual log time, option A —
  default) **OR** `AccountedForDate` (the "accounted" date, always 12:00 — option B)?
  In the real export, `AccountedForDate` is always midnight-noon. `RegisteredDate`
  carries real times for entries logged with time — use this.

- [ ] **Q3 — Import result presentation**: Show counts in an `.alert` (simple, option A
  — default) **OR** a dedicated result sheet with per-row detail (complex, option B)?

- [ ] **Q4 — DrinkControl import: confirm before inserting**: Show a preview count
  ("Found 101 drinks — import all?", option A — default) **OR** import immediately
  without preview (option B)?

## Tests required

See implementation step 8. All importers must be unit-testable without SwiftData
(accept `ModelContext` as parameter; use in-memory container in tests).
