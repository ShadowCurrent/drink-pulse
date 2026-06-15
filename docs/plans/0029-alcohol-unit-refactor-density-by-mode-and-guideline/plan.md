# 0029 — Alcohol-unit refactor: two display modes + density by mode AND guideline

**Status**: in-progress
**Size**: medium-large
**Created**: 2026-06-15
**Frozen**: 2026-06-15

## Summary

Collapse the three display units (`grams`, `units`, `standardDrinks`) into **two**
(`grams`, `standardDrinks`), and make the volume→mass density depend on **both
the display mode and the selected guideline**, so every country reads on clean,
canonical numbers and no guideline "suffers".

The model (confirmed with the owner 2026-06-15 after a long design discussion):

- **`.grams` mode → density 0.789 always** (scientific ethanol): a 500 ml 5% beer
  reads **19.7 g** — the true physical mass, consistent with calories/BAC.
- **`.standardDrinks` mode → density depends on the guideline**, because countries
  define a "standard drink" differently:
  - **US, CA → 0.789** (their standard drink is *mass*-defined: US 14 g, CA 13.45 g).
    This makes each country's canonical reference beer read **exactly 1.0**
    (US 355 ml 5% = 14.0 g; CA 341 ml 5% = 13.45 g).
  - **WHO, DE, AU, UK, custom → 0.8** (the EU/UK unit convention), so a European
    500 ml 5% beer reads **exactly 2.0** and UK lands on clean units.
- **Drop `.units`** entirely — UK folds into `.standardDrinks` (8 g/unit, 0.8),
  which is where it now naturally lives.

Guideline gram limits are unchanged (from plan-0028); only the *display* changes.
Calories and (future) BAC continue to use the physical 0.789 unconditionally.

## Resulting numbers (the target behaviour)

| Guideline | std drink | density (std-drinks mode) | 0.5 L 5% beer | daily limit | weekly limit |
|-----------|-----------|---------------------------|---------------|-------------|--------------|
| WHO | 10 g | 0.8 | **2.00** | 2.0 | 10.0 |
| DE | 10 g | 0.8 | 2.00 | 2.4 | 12.0 |
| AU | 10 g | 0.8 | 2.00 | 4.0 | 10.0 |
| UK | 8 g | 0.8 | 2.50 | — | **14.0** |
| US | 14 g | 0.789 | 1.41 | 2.0 | 14.0 |
| CA | 13.45 g | 0.789 | 1.47 | 3.0 | 15.0 |

Canonical reference drinks (std-drinks mode): US 355 ml 5% = **1.00**, CA 341 ml
5% = **1.00**. In `.grams` mode every guideline shows the physical grams
(beer = 19.7 g; limits = the plan-0028 gram values).

## Context

- End state of the 2026-06-15 design thread. Earlier wrong turns (weekly = daily×7,
  then "are units/standardDrinks duplicates?", then "single density 0.789 vs 0.8")
  are resolved here. The owner explicitly wants European beer = 2.0 **and** US/CA
  canonical, which is only simultaneously possible with density keyed to the
  guideline in std-drinks mode.
- This **amends ADR-0005** (density-by-display-unit). ADR-0005 already established
  per-display-unit density; this refines it: `.standardDrinks` moves 0.789→0.8 for
  EU/UK guidelines and stays 0.789 for US/CA, and `.units` is removed. Because
  accepted ADRs are frozen, write a **new ADR (0006) that supersedes/amends 0005**,
  don't edit 0005.
- The known **~1.4% convention offset** (consumption summed at 0.8 vs gram limits
  at 0.789) now applies **only to EU/UK guidelines**; US/CA have **no offset**
  (both consumption and limits at 0.789) — call this out in domain.md.
- Constraints (CLAUDE.md): this is a refactor touching the hand-verified display
  density, so it is **proposed for confirmation before coding**. Removing a stored
  enum case is a **schema change** → needs the migration below before shipping.
  ≥90% coverage / 100% domain, files < 300 lines, no force-unwraps, en-only, no
  new network/logging of health data.

## Scope

### In

**Domain (`Domain/UserProfile.swift`)**
- `enum AlcoholUnit`: remove `.units` → `case grams, standardDrinks`.
- Replace the `densityGramsPerMl` *property* with `density(for guideline:)`:
  `.grams` → 0.789; `.standardDrinks` → `(.us, .ca) ? 0.789 : 0.8`. Keep
  `physicalDensityGramsPerMl = 0.789` for calories/BAC.
- `gramsPerUnit(for:)`: drop the `.units` branch; `.standardDrinks` returns
  US 14, CA 13.45, UK 8, WHO/DE/AU/custom 10.
- `displayName` / `unitLabel`: drop `.units`. Decide the UK label (sub-decision
  below): keep a single "standard drinks" label, or make `unitLabel(for:)`
  guideline-aware so UK reads "units".
- **Migration**: `alcoholUnit` is a stored SwiftData property whose current
  **default is `.units`**. Add a custom `Decodable`/`RawRepresentable` fallback so
  any persisted `"units"` (and unknown values) decode to `.standardDrinks`; change
  the stored default and the `init` default to `.standardDrinks`. This is a
  dev-acceptable lightweight migration (additive-compatible decode), not a
  store-wipe — state it in execution.md.

**Call sites (density now needs the guideline)** — update every consumer of the
old `densityGramsPerMl` and every `?? .units` fallback (`?? .standardDrinks`):
- `Features/Dashboard/DashboardViewModel.swift` (modeDensity → `density(for:)`, the
  `modeMass * physical / modeDensity` conversion, `?? .units` ×2).
- `Features/Insights/InsightsViewModel.swift` (+`+Formatting.swift`) (modeDensity,
  the 7-day projection at line ~186, `?? .units`).
- `Features/History/Components/EventRow.swift`, `HistoryCalendarView.swift`,
  `HistoryCalendarDayDetail.swift`; `Features/History/EditEventView.swift`;
  `Features/AddDrink/DrinkDetailInputView.swift` (preview mass).
- `Features/Settings/SettingsView.swift` (picker now 2 cases — verify),
  `Features/Settings/Components/DataSection.swift:169` (reset → `.standardDrinks`).
- `Domain/DataTransfer/ProfileRecord.swift` + `DataExporter.swift` decode/hash via
  the new enum (covered by the custom decode).

**Localization**: retire `settings.alcoholUnit.units` (and `unit.units` if unused);
no new keys unless the UK guideline-aware label is added.

**Docs / ADR**: new `docs/decisions/0006-*.md` amending ADR-0005; update
`docs/domain.md` (density table → mode×guideline, the offset note, AlcoholUnit
cases), DEVLOG, roadmap, context files.

**Tests** (domain 100%):
- `density(for:)`: `.grams` = 0.789 for all guidelines; `.standardDrinks` = 0.789
  for US/CA, 0.8 for WHO/DE/AU/UK/custom.
- Consumption: 500 ml 5% = 2.00 std drinks for WHO/DE/AU, 2.50 UK; 355 ml 5% US =
  1.00; 341 ml 5% CA = 1.00; `.grams` mode = 19.725 g for all.
- Limits in std drinks per the target table (incl. UK weekly = 14.0).
- Migration: decoding `"units"` (and an unknown raw) yields `.standardDrinks`.
- Regression: calories unchanged across unit toggles (still 0.789).

### Out
- Any change to the gram limit values (owned by plan-0028 — frozen/correct).
- BAC implementation.
- Monthly limit display.
- Making `.custom` selectable in the picker.
- Re-litigating EU beer = 2.0 vs 1.97 (decided: 2.0 via 0.8).

## Sub-decisions (resolved 2026-06-15)
1. **UK label**: guideline-aware `unitLabel(for:)` → UK reads **"units"**, all
   other guidelines read **"standard drinks"**.
2. **Default unit** after dropping `.units`: **`.standardDrinks`** (stored default,
   `init` default, and the `?? .units` fallbacks all become `.standardDrinks`).

## Risks & notes
- The same drink reads a slightly different **% of limit** between `.grams`
  (98.6% of WHO daily) and `.standardDrinks` (100%) for EU/UK guidelines — the
  documented intended offset; US/CA have none. Acceptable, but note it in domain.md.
- `density(for:)` signature change ripples through ~10 view-layer call sites;
  miss one and consumption mass silently uses the wrong density. The test that a
  500 ml 5% beer = 2.0 (EU) / 1.0 (US 355 ml) per screen guards this.
- Removing the stored enum case: verify the decode fallback actually runs for a
  store created with `"units"` (add a decode test), and that import of an old
  `ProfileRecord` with `alcoholUnit == "units"` maps to `.standardDrinks`.

## Acceptance
- `AlcoholUnit` has exactly `grams` and `standardDrinks`; no `.units` remains.
- Std-drinks mode: EU 500 ml 5% = 2.00, UK = 2.50, US 355 ml = 1.00, CA 341 ml =
  1.00; UK weekly limit = 14.0. Grams mode: beer = 19.7 g, plan-0028 gram limits.
- Calories identical regardless of selected unit (0.789).
- A profile/store/backup carrying `"units"` loads as `.standardDrinks`.
- New ADR-0006 written; domain.md reflects density-by-mode-and-guideline.
- Build clean (0 warnings), tests green, domain 100% / overall ≥90%, no file >300 lines.
