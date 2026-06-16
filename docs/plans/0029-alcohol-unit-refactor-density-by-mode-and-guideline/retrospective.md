# Retrospective — plan-0029

**Completed**: 2026-06-16

## What was delivered

`AlcoholUnit` collapsed from three cases to two (`grams`, `standardDrinks`), and
the volume→mass display density now depends on **both** the display mode and the
selected guideline (`AlcoholUnit.density(for:)`, ADR-0006 amending ADR-0005):

- `.grams` → 0.789 for every guideline.
- `.standardDrinks` → 0.789 for US/CA (mass-defined std drink), 0.8 for
  WHO/DE/AU/UK/custom (EU/UK unit convention).

The UK folds into `.standardDrinks` (8 g/unit, 0.8) with a guideline-aware
`unitLabel(for:)` that still reads "units" for the UK. A custom `AlcoholUnit.init(from:)`
migrates any persisted `"units"` (and unknown raw) to `.standardDrinks` — covering
both the SwiftData stored property and imported backups. Gram limits unchanged.

## Acceptance — all met

- `AlcoholUnit` has exactly `grams` + `standardDrinks`; no `.units` remains.
- Std-drinks mode: EU 500 ml 5% = 2.00, UK = 2.50, US 355 ml = 1.00, CA 341 ml =
  1.00; UK weekly limit = 14.0. Grams mode: beer = 19.7 g.
- Calories identical regardless of selected unit (0.789).
- A backup carrying `"units"` loads as `.standardDrinks`.
- ADR-0006 written; domain.md/README/product.md reflect density-by-mode-and-guideline.
- Build clean (0 warnings), tests green, domain refactor logic fully covered,
  no file > 300 lines.

## What went well

- Every old `densityGramsPerMl` call site already had the guideline in scope, so the
  signature change `density(for:)` rippled cleanly with no new plumbing.
- The custom enum decode is one place that fixes both persistence and import.
- The "EU `.units` == EU `.standardDrinks` (both 0.8, 10 g)" equivalence let existing
  WHO-guidelined `.units` tests convert to `.standardDrinks` with identical numerics.

## Surprises / lessons

- Swift Testing's `#expect` macro rejects key paths to a struct's properties in the
  expanded form; use direct property access in test helpers instead of `keyPath:` closures.
- `unitLabel` moving from a property to `unitLabel(for:)` is the one ergonomic cost —
  callers must thread the guideline, but every real call site already had it.

## Follow-ups

- None blocking. BAC (0.789) and monthly-limit display remain out of scope as planned.
