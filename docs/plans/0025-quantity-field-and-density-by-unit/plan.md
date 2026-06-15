# 0025 — Quantity field (×N) + density-by-display-unit, drop unit rounding

**Status**: in-progress
**Size**: large
**Created**: 2026-06-14
**Frozen**: 2026-06-14

> **Execution handoff.** This plan is frozen and will be executed in a **fresh
> session (Opus 4.8)**. It is self-contained: read this file end-to-end, then
> `CLAUDE.md`, `docs/domain.md`, and `Domain/UserProfile.swift` +
> `Domain/ConsumptionEvent.swift` before coding. All calculation-core decisions
> are user-hand-verified and recorded under "Open questions → Resolved". Log all
> deviations in `execution.md` (do not edit this frozen plan). The
> post-execution manual-fix list is the section "Manual fixes after execution".

## Summary

Two linked corrections that both touch `ConsumptionEvent` and the unit-display
math:

- **Part A — Quantity (×N) as a real field.** Today, logging "10× Bottle 500 ml"
  stores a *single* event with `volumeMl = 5000`, folding the count into the
  volume. The original `(count, unitVolume)` decomposition is lost, so the
  History row mislabels it ("Mug ×5", because 5000 ml is ambiguous: 5×1000 =
  10×500) and `displayName` picks the nearest single preset (Mug · 1 L). Fix:
  add a persisted `quantity` field; `volumeMl` reverts to the **single-portion**
  volume. One log = one event = "Bottle · 500 ml ×10".

- **Part B — Density constant depends on the chosen display unit, and the
  unit-rounding machinery is removed.** Density is keyed to `AlcoholUnit`:
  - `.grams` → `0.789` (scientific).
  - `.units` (UK) → `0.8` → 500 ml × 5 % = 20 g = exactly 2.0 units (WHO/DE) /
    2.5 UK units; ×10 = 20.0 / 1000 %.
  - `.standardDrinks` (US) → `0.789` → 355 ml × 5 % = 14.0 g = exactly 1.0 US
    standard drink (a US standard drink is *defined* as 14 g, so 0.789 is the
    constant that lands on clean numbers here, not 0.8).

  With clean math, the `displayValue`/`displayPct` rounding hacks (added
  2026-06-14 for the hero arc and overview) become unnecessary and are deleted —
  percentages are computed from exact values and formatted only at the leaf.

## Context

- Triggered by two user-reported issues (2026-06-14): "Mug ×5 instead of Bottle
  ×10" in History, and "10 beers = 19.7 units / 985 %" instead of 20 / 1000 %.
- **Pre-existing contradiction discovered while scoping** (must be resolved
  here, per CLAUDE.md "surface contradictions"):
  - `ConsumptionEvent.pureAlcoholGrams` uses `× 0.789` (the stored truth used by
    Dashboard / History / Insights aggregation).
  - `DrinkDetailInputView.swift:44` and `EditEventView.swift:89` compute their
    live grams **preview** with `× 0.8` (comment even claims "canonical
    formula"). So the Add screen previews 2.0 units for a 500 ml 5 % beer, but
    once saved the dashboard recomputes 1.97. The two density constants already
    disagree in-tree.
  - CLAUDE.md § "Calculations" and `docs/domain.md` currently mandate `0.789`
    as the single canonical density and call `0.8` wrong. **This plan changes
    that rule**, so both docs (and likely a new ADR) must be updated as part of
    the work, and the wording is owned by the user (hand-verifies calculations).
- **BAC is not implemented yet** (no Widmark code in the tree). So the density
  split does not affect BAC today, but the principle must be recorded: **BAC,
  when added, always uses physical `0.789`**, never the display-unit density.
  Calories (`todayGrams * 7.1`) are physical too — see open questions.
- **Root cause of the folded data is the importer.**
  `DrinkControlImporter.parseLine` (`:66`) does `totalVolumeMl = sizeInMl ×
  count` and drops `NumberOfDrinks` — even though the source CSV
  (`drinkcontrol.csv`) carries `DrinkSizeInMl` and `NumberOfDrinks` as separate
  columns. So every multi-drink row was mis-shaped on import. The CSV is the
  **ground truth** for the user's history.
- The CSV has **4 multi-drink rows** (of 101); the importer folded all four:

  | CSV row | drink | size | count | folded volumeMl | heuristic backfill recovers? |
  |---|---|---|---|---|---|
  | 6  | other "Sml shot" | 20  | 5 | 100  | ❌ 100 matches a custom preset → missed |
  | 11 | beer "Med bottle"| 330 | 3 | 990  | ✅ 990 matches nothing → 3×330 |
  | 12 | beer "Med bottle"| 330 | 3 | 990  | ✅ |
  | 14 | beer "Bottle"    | 500 | 2 | 1000 | ❌ 1000 = "Mug · 1 L" preset → missed |

- **Therefore the volume-decompose backfill is unreliable** — it recovers the
  990s but misses the 100 ml (5×20) and 1000 ml (2×500) folds, because they
  coincide with real preset volumes (the inherent 5000-ml-ambiguity). The only
  exact correction is **re-importing the CSV through the fixed importer**.
  Caveat: the backup has 106 events vs 101 CSV rows → ~5 events were added
  in-app after the import; a wipe-and-reimport would drop those. See open
  questions for the chosen data-correction path.
- Constraints (CLAUDE.md): grams is the unit of truth; calculation-core changes
  must be proposed + hand-verified (this plan is that proposal); SwiftData
  schema change needs a migration plan before shipping; privacy-first; ≥90 %
  coverage / 100 % domain; files < 300 lines; no force-unwraps.

## Scope

### In

**Part A — quantity field**
- Add `var quantity: Int = 1` to `ConsumptionEvent` (additive, defaulted →
  lightweight SwiftData migration; no custom migration stage needed).
- `volumeMl` becomes the **single-portion** volume again. Mass becomes
  `volumeMl × quantity × abv × density`.
- `AddDrink` (`DrinkDetailInputView`): stop folding — save `volumeMl =
  selectedVolumeMl`, `quantity = count`.
- `EditEventView`: store/edit `quantity` directly; delete the
  `(count, volumeIndex)` reverse-engineering loop (`:28–41`); save `volumeMl =
  selectedVolumeMl`, `quantity = count`.
- `ConsumptionEvent.displayName`: resolve preset from the **single-portion**
  `volumeMl` (now unambiguous → "Bottle"). Append "×N" affordance for N > 1
  (exact location TBD — see open questions: label vs separate count chip).
- History row (`EventRow`) shows the quantity (e.g. "Bottle · 500 ml ×10").
- **Fix `DrinkControlImporter`** (`:66`): store `volumeMl = sizeInMl`,
  `quantity = count` — stop folding. Update `DataImporter.isDuplicate` to match
  on single-serving `volumeMl` + `quantity` (so a corrected re-import recognises
  / replaces folded duplicates rather than double-adding).
- **Existing folded data correction** = re-import the CSV through the fixed
  importer (exact), **not** the volume-decompose heuristic (which misses the
  100 ml and 1000 ml folds). The optional heuristic backfill may still ship as a
  best-effort fallback for JSON-only data with no CSV, but it is explicitly
  documented as lossy and is **not** the mechanism for this user's data. Final
  data-correction path chosen in open questions.

**Part B — density by unit + drop rounding**
- `AlcoholUnit.densityGramsPerMl`: `.grams → 0.789`, `.units → 0.8`,
  `.standardDrinks → 0.789`.
- Settings label: `settings.alcoholUnit.standardDrinks` "Standard drinks" →
  "Standard drinks (US)" (mirrors the existing "Units (UK)").
- **Calories use physical `0.789`** regardless of display unit (kcal must not
  shift when the user toggles units).
- Mass for display/guideline comparison is computed with the **active unit's
  density**; physical mass (calories, future BAC) uses `0.789`. Proposed shape:
  `ConsumptionEvent.alcoholGrams(density:)` (model stays mode-agnostic); view
  models sum with `profile.alcoholUnit.densityGramsPerMl`.
- Delete the rounding layer: `AlcoholUnit.displayValue`, and Dashboard's
  `displayValue` / `displayPct` / `displayRiskLevel` / `todayDisplayPct` /
  `todayDisplayRiskLevel`, and Insights' `displayValue`. Percentages and risk
  use exact mode-mass; formatting (`%.1f`) happens only in the leaf `Text`.
  This **supersedes the 2026-06-14 display-rounding edits** (hero arc + overview
  + week chart), which were a workaround for exactly this problem.
- Re-unify the two density constants: `DrinkDetailInputView` / `EditEventView`
  previews use `densityGramsPerMl` (not a hardcoded 0.8).
- UK / standard-drink unit sizes revisited for consistency with 0.8 — see open
  questions (UK unit 7.89 → 8.0; UK weekly 110.46 → 112).

### Out
- Removing the deprecated `ConsumptionEvent.name` field (owned by plan-0023).
- CloudKit schema work (plan-0023). Note: adding `quantity` is CloudKit-friendly
  (optional-with-default), so it does not conflict.
- Implementing BAC (only the density principle is recorded).
- Grouping *distinct* events into one row (this plan keeps one-log = one-event;
  ×N is intrinsic, not post-hoc grouping).

## Implementation steps

Ordered; each ≈ one commit.

1. **Density source of truth.** Add `AlcoholUnit.densityGramsPerMl`
   (0.789 / 0.8 / 0.8). Unit-test the constant. No behaviour change yet.
2. **Parameterize mass.** Add `ConsumptionEvent.alcoholGrams(density:)` =
   `volumeMl × quantity × abv × density`. Keep a transitional
   `pureAlcoholGrams` (physical, 0.789) for calories/future-BAC. (quantity
   defaults to 1, so step is safe before Part A wiring.)
3. **Add `quantity` field** to the model (`= 1` default). Lightweight migration;
   verify store opens against existing data without a wipe.
4. **Add/Edit stop folding.** Save `volumeMl = unitVolume`, `quantity = count`;
   delete the Edit reconstruction loop; previews use `densityGramsPerMl`.
5. **displayName + EventRow** show single-portion preset + "×N".
6. **Fix `DrinkControlImporter`** (`volumeMl = sizeInMl`, `quantity = count`) +
   `DataImporter.isDuplicate` on (timestamp, single volumeMl, abv, quantity).
   Tests: the 4 CSV multi-drink rows import as exact (size, quantity) pairs.
   (Optional best-effort JSON backfill for non-preset decomposable volumes may
   be added here, flagged lossy.)
7. **Switch aggregation to mode density + drop rounding.** Dashboard / Insights
   / History sum `alcoholGrams(density:)`; remove `displayValue`/`displayPct`/
   `displayRiskLevel`/`todayDisplay*` and `AlcoholUnit.displayValue`; compute
   exact pct/risk; format at leaves. Revert the 2026-06-14 rounding edits.
8. **Guideline unit consistency** (resolved): UK `gramsPerUnit` 7.89 → **8.0**
   and UK weekly 110.46 → **112** (14 × 8) so 500 ml 5 % = 2.5 UK units;
   `.standardDrinks` density 0.789 keeps US 355 ml 5 % = 1.0; settings label →
   "Standard drinks (US)".
9. **Docs:** update CLAUDE.md § Calculations + `docs/domain.md` (density now
   depends on display unit; canonical examples), new ADR
   `docs/decisions/NNNN-density-by-display-unit.md`, plus the living-docs audit.

## Files

| File | Action |
|------|--------|
| `Domain/UserProfile.swift` (AlcoholUnit) | Modify — add `densityGramsPerMl`; remove `displayValue`; revisit `gramsPerUnit` (UK) |
| `Domain/ConsumptionEvent.swift` | Modify — add `quantity`; `alcoholGrams(density:)`; `displayName` from single volume + ×N |
| `Domain/GuidelineChoice+Limits.swift` | Modify — UK weekly limit (open q) |
| `Features/AddDrink/DrinkDetailInputView.swift` | Modify — save quantity; preview density |
| `Features/History/EditEventView.swift` | Modify — quantity directly; drop reconstruction; preview density |
| `Features/History/Components/EventRow.swift` | Modify — show ×N |
| `Features/Dashboard/DashboardViewModel.swift` | Modify — mode-density sums; remove display* rounding |
| `Features/Dashboard/Components/ConsumptionOverviewCard.swift` | Modify — exact pct (revert rounding) |
| `Features/Dashboard/Components/ThisWeekCard.swift` | Modify — exact pct (revert rounding) |
| `Features/Dashboard/Components/DashboardHeroCard.swift` | Modify — exact pct |
| `Features/Insights/InsightsViewModel.swift` | Modify — mode-density sums; remove `displayValue` |
| `Domain/DataTransfer/DrinkControlImporter.swift` | Modify — `quantity = count`, stop folding volume |
| `Domain/DataTransfer/DataImporter.swift` | Modify — `isDuplicate` includes single volume + quantity |
| `Domain/Persistence/…` (store bootstrap) | Modify — optional best-effort backfill (lossy, flagged) |
| `docs/decisions/NNNN-density-by-display-unit.md` | Create — ADR |
| `CLAUDE.md`, `docs/domain.md` | Modify — canonical density rule |
| `drinkpulseTests/…` | Create/Modify — see Tests |

## Open questions

### Resolved (2026-06-14, user hand-verified)

- [x] **UK unit size under 0.8** → UK `gramsPerUnit` = **8.0**, UK weekly limit
      = **112 g**. 500 ml 5 % = 2.5 UK units (matches NHS `ml×ABV%/1000`).
- [x] **US standard drinks** → density **0.789** for `.standardDrinks` so 355 ml
      5 % = 14.0 g = 1.0 US standard drink. Settings label gets a "(US)" suffix.
- [x] **Limit grams vs density** → compare mode-mass to the unchanged physical
      gram limits. In `.units` (0.8) mode this is the intended ~1.4 % convention
      offset that yields the clean "one beer = 100 % of WHO daily".
- [x] **Calories** → physical **0.789** always (kcal never shift on unit toggle).
- [x] **Importer is in scope** → `DrinkControlImporter` must map
      `NumberOfDrinks → quantity` and `DrinkSizeInMl → volumeMl` (stop folding).
- [x] **Data-correction path → option (b)** (no data loss). Fix the importer for
      the future; do **not** wipe/re-import (would drop ~5 in-app-added events);
      do **not** rely on the lossy heuristic backfill. The 4 already-folded
      events are corrected by hand in-app once `quantity` exists — exact list in
      "Manual fixes after execution". (Grams are unchanged by these edits, so no
      totals shift.) The optional backfill step (6) may be skipped entirely.

### Still open (decide while executing)

- [ ] **`quantity` display.** "×10" appended to the preset label, or a separate
      count chip / multiplier badge in the row?
- [ ] **quantity bounds & migration default.** Add picker range, and confirm
      `Int = 1` default is fine for SwiftData lightweight migration on-device.

## Tests required

- `AlcoholUnit.densityGramsPerMl` returns 0.789 / 0.8 / 0.8.
- `alcoholGrams(density:)`: 500 ml 5 % → 20 g at 0.8, 19.725 g at 0.789;
  quantity multiplies (×10 → 200 g / 197.25 g).
- Units mode end-to-end: one 500 ml 5 % beer = 2.0 units & 100 % of WHO daily;
  ×10 = 20.0 units & 1000 %; no rounding drift; risk levels from exact pct.
- Grams mode unchanged: 500 ml 5 % = 19.7 g display, 98.6 % (regression guard).
- `displayName`: single 500 ml beer → "Bottle"; quantity 10 → "Bottle … ×10".
- `EditEventView` round-trips quantity (no reconstruction).
- **Importer**: the 4 CSV multi-drink rows import as exact `(volumeMl, quantity)`
  = (20,5), (330,3), (330,3), (500,2) — not folded; single-drink rows still
  `quantity 1`; `isDuplicate` skips a corrected re-import of the same event.
- Optional backfill (if shipped): beer 990 → quantity 3 / volume 330; documented
  as lossy (does not touch the 100/1000 ml folds); idempotent on second run.
- UK/US unit sizes per the resolved open questions (100 % domain coverage).
- Overall ≥90 %, domain 100 %, build clean, files < 300 lines.

## Manual fixes after execution

Per the chosen data-correction path **(b)**, four already-imported events were
folded by the old importer and must be corrected **by hand in-app** once the
`quantity` field exists (open `EditEventView`, set the single-serving volume +
quantity, save). Derived by cross-referencing `drinkcontrol.csv` (ground truth:
`DrinkSizeInMl` + `NumberOfDrinks`) against `drinkpulse-backup-2026-06-12.json`
(what is actually stored). **Grams are unchanged** by these edits (e.g. 990 ml ×
1 @ 5 % = 330 ml × 3 @ 5 %), so no total/percentage shifts — only the label,
count, and per-portion volume become correct.

| Find this event (local time = stored UTC + 1 h) | Currently shows | Correct to |
|---|---|---|
| **2026-01-10 20:42** — "Other" 100 ml, 38 % (UTC `2026-01-10T19:42:48Z`) | Custom 100 ml ×1 | **20 ml × 5** (small shot, custom) |
| **2026-01-17 21:14** — Beer 990 ml, 5.0 % (UTC `2026-01-17T20:14:26Z`) | Beer "Mug" 990 ml ×1 | **330 ml × 3** (beer, Can) |
| **2026-01-17 21:14** — Beer 990 ml, 5.5 % (UTC `2026-01-17T20:14:27Z`) | Beer "Mug" 990 ml ×1 | **330 ml × 3** (beer, Can) |
| **2026-01-24 18:32** — Beer 1000 ml, 5.0 % (UTC `2026-01-24T17:32:42Z`) | Beer "Mug" 1000 ml ×1 | **500 ml × 2** (beer, Bottle) |

**Do NOT touch** the other three genuine 1 L beers (single Mugs, count = 1 in the
CSV): `2026-01-24T18:35:41Z` (5 %), `2026-03-21T16:36:02Z` (7 %),
`2026-03-21T16:36:03Z` (5 %). They are real, not folded.

> Identify each event by its timestamp + current volume (the table's UTC value is
> unambiguous; the local time is what the History list shows in CET/UTC+1). If
> the user later re-runs the export, regenerate this table the same way (match
> CSV rows with `NumberOfDrinks > 1` to JSON events by registered timestamp).

## Risks & notes
- **Calculation-core + canonical-doc change** — this *is* the proposal CLAUDE.md
  requires; do not start coding the density split until the open questions above
  are confirmed.
- Schema migration: additive defaulted field is lightweight, but verify on a
  copy of real data (and the dev store-wipe fallback stays dev-only).
- Existing physical-grams history is **recomputed** under the new density when
  viewed in units mode (totals shift ~1.4 % upward in units mode only). Call
  this out to the user — it is intended, not a regression.
- One ADR + CLAUDE.md/domain.md edits are part of "done", not follow-ups.
```
