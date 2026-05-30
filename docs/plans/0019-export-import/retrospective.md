# 0019 — Retrospective

**Completed**: 2026-05-30

## What went well

- Having the actual DrinkControl export file before writing the importer meant zero guesswork — field names, delimiter, date format, ABV convention, and category values all confirmed from real data.
- The `location` removal (lightweight migration, optional field) was a clean prerequisite that simplified the schema.
- Separating `DataExporter`/`DataImporter`/`DrinkControlImporter` as independent structs made them individually testable without UI or SwiftData coupling.
- 248/248 tests green on first full build after the `import Foundation` fix.

## What went wrong / surprises

- **`import Foundation` missing in test files** — `Date`, `Calendar`, `JSONDecoder` were not in scope. One-line fix, caught immediately at compile time.
- **`isDuplicate` static vs. instance call** — called `isDuplicate(...)` as instance method inside `importData` but the method is `static`. One-line fix.
- **DrinkControl density mismatch** — DrinkControl uses 0.789 g/ml (scientific), DrinkPulse uses 0.8 g/ml (BZgA). Addressed by importing raw ml+ABV and letting DrinkPulse derive grams. This means imported events will show slightly higher grams (~1.5%) than what DrinkControl recorded. Documented in plan.

## Decisions made during execution

- `location: String?` removed from `ConsumptionEvent` before implementation — owner confirmed it was not needed.
- `DataSection` uses `@Query` internally rather than accepting events as a parameter — avoids prop-drilling through `SettingsView`.
- All open questions resolved with their plan defaults (A for all four).

## Leftover open questions

- `.gitignore` for `drinkcontrol.csv` — the file is in the repo root and not committed, but there is no explicit `.gitignore` entry to prevent accidental future commits. Consider adding `*.csv` or the specific filename.
