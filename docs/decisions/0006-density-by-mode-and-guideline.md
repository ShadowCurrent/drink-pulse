# 0006 — Volume→mass density depends on the display mode AND the guideline

**Status**: Accepted
**Date**: 2026-06-15
**Plan**: [plan-0029](../plans/0029-alcohol-unit-refactor-density-by-mode-and-guideline/)
**Amends**: [ADR-0005](0005-density-by-display-unit.md) (which stays frozen)

## Context

ADR-0005 made the volume→mass display density depend on the active display
**unit** (`AlcoholUnit`): `.grams`/`.standardDrinks` → 0.789, `.units` (UK) → 0.8.
That worked for the UK (via the `.units` case) and the US, but it left an
inconsistency: the owner wants a European 500 ml 5 % beer to read **exactly 2.0**
standard drinks while a US 355 ml 5 % beer reads **exactly 1.0** US standard drink.
These two cannot both hold under a single per-unit density, because:

- US/CA define a standard drink as a **mass** (US 14 g, CA 13.45 g). Only the
  scientific density 0.789 lands 355 ml × 5 % on 14.0 g (and 341 ml × 5 % on 13.45 g).
- WHO/DE/AU/UK use the EU/UK unit convention (10 ml ethanol). Only 0.8 lands
  500 ml × 5 % on the clean 20.0 g = 2.0 (WHO/DE/AU) / 2.5 (UK).

There were also three display units (`grams`, `units`, `standardDrinks`) where
`units` and `standardDrinks` only differed on the UK guideline. That duplication
is removed here.

All calculation-core values were hand-verified by the project owner.

## Decision

**The volume→mass display density depends on both the display mode and the
selected guideline**, and `AlcoholUnit` collapses to two cases (`grams`,
`standardDrinks`).

| mode | guideline | density (g/ml) | rationale (hand-verified) |
|------|-----------|----------------|---------------------------|
| `.grams` | any | **0.789** | scientific ethanol: 500 ml × 5 % = 19.725 g, consistent with calories/BAC |
| `.standardDrinks` | US, CA | **0.789** | mass-defined std drink: US 355 ml = 14.0 g = 1.0; CA 341 ml = 13.45 g = 1.0 |
| `.standardDrinks` | WHO, DE, AU, UK, custom | **0.8** | EU/UK unit convention: EU 500 ml = 20.0 g = 2.0 (WHO/DE/AU) / 2.5 (UK) |

Implemented as `AlcoholUnit.density(for guideline:)` (replacing the old
`densityGramsPerMl` property). `gramsPerUnit(for:)` keeps the guideline-specific
std-drink size (UK 8.0 g, US 14 g, CA 13.45 g, WHO/DE/AU/custom 10 g).

Other consequences:

- **`.units` is removed.** The UK now folds into `.standardDrinks` (8 g/unit at
  0.8 density), where it naturally lives. The unit label is guideline-aware:
  `unitLabel(for:)` reads **"units"** for the UK and **"standard drinks"** for
  every other guideline (`.grams` always reads "g").
- **Default unit is `.standardDrinks`** (stored SwiftData default, `init` default,
  and all `?? .units` fallbacks become `?? .standardDrinks`).
- **Migration (lightweight, additive, no store wipe):** `AlcoholUnit` gets a
  custom `init(from:)` that decodes any persisted `"units"` raw value — and any
  unknown raw — to `.standardDrinks`. This covers the stored SwiftData property
  and imported `ProfileRecord`s.
- **Physical mass still always uses 0.789** (`physicalDensityGramsPerMl`).
  Calories use it unconditionally; **BAC, when implemented, must also use 0.789**.
- **Guideline gram limits are unchanged** (owned by plan-0028).

## Consequences

- The documented **~1.4 % convention offset** (consumption summed at 0.8 vs gram
  limits at 0.789) now applies **only to EU/UK guidelines** (WHO/DE/AU/UK/custom).
  **US/CA have no offset** — both consumption and limits use 0.789.
- Targets verified by tests: std-drinks mode — EU 500 ml 5 % = 2.00 (WHO/DE/AU),
  UK = 2.50, US 355 ml = 1.00, CA 341 ml = 1.00; UK weekly limit = 14.0.
  `.grams` mode — 19.7 g for every guideline. Calories identical across unit toggles.
- ADR-0005 stays frozen; this ADR is the authoritative density rule going forward.
  CLAUDE.md § Calculations and `docs/domain.md` are updated to match.

## Alternatives considered

- **Keep a single per-unit density (ADR-0005).** Rejected: cannot make EU beer = 2.0
  and US beer = 1.0 simultaneously; the `.units` case was redundant outside the UK.
- **Use 0.8 for std-drinks everywhere (including US/CA).** Rejected: US/CA standard
  drinks are mass-defined; 0.8 would miss 14.0 g / 13.45 g and break the "1.0" reference.
- **Re-litigate EU beer = 1.97 (pure 0.789).** Rejected by the owner: the clean
  "one beer = 2.0 / 100 % of WHO daily" reading is the intended product behaviour.
