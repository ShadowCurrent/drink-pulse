# 0005 — Volume→mass density depends on the chosen display unit

**Status**: Accepted
**Date**: 2026-06-15
**Plan**: [plan-0025](../plans/0025-quantity-field-and-density-by-unit/)

## Context

The unit of truth is grams of pure alcohol; every other measure is derived.
Historically a single physical density (scientific ethanol, **0.789 g/ml** at
20 °C) converted volume → grams everywhere, and a display layer divided grams by
`gramsPerUnit` to show "units" / "standard drinks".

Two problems surfaced (2026-06-14, user-reported):

1. With 0.789, common drinks land on ugly numbers in the user's unit. One
   500 ml × 5 % beer = 19.725 g = 1.97 UK-style "units" (and ten of them read
   "19.7 units / 985 %" instead of the expected 20 / 1000 %). A whole layer of
   display-rounding hacks (`displayValue` / `displayPct` / `todayDisplayPct`)
   had been added on 2026-06-14 purely to paper over this.
2. The Add/Edit live preview already computed grams with `× 0.8` (calling it the
   "canonical formula"), while the stored truth used `× 0.789` — so the preview
   and the dashboard disagreed by ~1.4 % on the same drink. The two constants
   were already inconsistent in-tree.

The previous canonical rule (CLAUDE.md, domain.md) mandated 0.789 as the single
density and called 0.8 wrong. This ADR changes that rule. All calculation-core
values here were hand-verified by the project owner.

## Decision

**The density used to convert volume → mass depends on the active display unit.**

| `AlcoholUnit` | density (g/ml) | rationale (hand-verified) |
|---|---|---|
| `.grams` | 0.789 | scientific ethanol: 500 ml × 5 % = 19.725 g |
| `.units` (UK) | 0.8 | 500 ml × 5 % = 20.0 g = exactly 2.0 units (WHO/DE) / 2.5 UK |
| `.standardDrinks` (US) | 0.789 | 355 ml × 5 % = 14.0 g = exactly 1.0 US standard drink |

A US standard drink is *defined* as 14 g, and 0.789 (not 0.8) is the constant
that lands 355 ml × 5 % on exactly 14 g — hence standard-drinks keeps 0.789.

Consequences of the decision:

- **`AlcoholUnit.densityGramsPerMl`** is the single source of truth for the
  display-unit density; view models sum consumption with the *active* unit's
  density (`ConsumptionEvent.alcoholGrams(density:)`).
- **Physical mass always uses 0.789** (`AlcoholUnit.physicalDensityGramsPerMl`).
  Calories use it unconditionally so kcal never shift when the user toggles
  units. **BAC, when implemented, must also use 0.789** — never the display
  density.
- **Guideline limits stay in physical grams.** Consumption (mode-mass) is
  compared directly to those physical-gram thresholds. In `.units` (0.8) mode
  this is an intended ~1.4 % convention offset that yields the clean
  "one beer = 100 % of the WHO daily limit".
- **UK unit size follows 0.8:** 1 UK unit = 8.0 g (10 ml × 0.8), UK weekly =
  14 × 8.0 = **112 g** (was 7.89 g / 110.46 g).
- **The display-rounding layer is deleted.** With clean math, percentages and
  risk are computed exactly from mode-mass and formatted (`%.1f`) only at the
  leaf. `displayValue` / `displayPct` / `displayRiskLevel` / `todayDisplay*` /
  `trendDisplayFraction` are gone.

## Consequences

- Existing physical-grams history is *recomputed* under the new density when
  viewed in units mode — totals shift ~1.4 % upward **in units mode only**
  (grams and US standard-drinks modes are unchanged). This is intended, not a
  regression; grams of pure alcohol stored on each event are untouched.
- The Add/Edit preview now matches the dashboard (both use
  `densityGramsPerMl`).
- CLAUDE.md § Calculations and `docs/domain.md` are updated to record the new
  rule; this ADR is the authoritative justification.

## Alternatives considered

- **Keep 0.789 everywhere, round at display.** Rejected: it required the
  rounding-hack layer, and ratios (badges, arcs) still drifted from the
  displayed "X / Y unit" copy.
- **Use 0.8 everywhere (including calories/grams mode).** Rejected: 0.8 is not
  the physical density, so calories and the scientific grams figure would be
  wrong; US standard drinks would also miss 14 g.
