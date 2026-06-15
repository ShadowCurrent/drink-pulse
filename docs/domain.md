# Domain Rules

## ABV convention

ABV is always stored as a **plain fraction** (0.0–1.0).
- 5% beer → `abv = 0.05`
- 40% whisky → `abv = 0.40`

Display layer multiplies by 100 to show "5.0 %". Input fields accept
percentage and divide by 100 before storing.

## Calculations

### Mass of pure alcohol

```
alcoholGrams = volumeMl × quantity × abv × density
```

`volumeMl` is a **single portion**; `quantity` is how many were logged in one
entry (never fold the count into volume). Never store the derived mass — always
compute on the fly. **Hand-verify before changing.**

**Density depends on the chosen display unit** (`AlcoholUnit.densityGramsPerMl`,
ADR-0005 / plan-0025), so the unit math lands on clean numbers:

| `AlcoholUnit` | density (g/ml) | example |
|---|---|---|
| `.grams` | 0.789 (scientific ethanol, 20 °C) | 500 ml × 5% = 19.725 g |
| `.units` (UK) | 0.8 | 500 ml × 5% = 20.0 g = 2.0 units (WHO/DE) / 2.5 UK |
| `.standardDrinks` (US) | 0.789 | 355 ml × 5% = 14.0 g = 1.0 US standard drink |

**Physical mass always uses 0.789** (`AlcoholUnit.physicalDensityGramsPerMl`),
exposed as `ConsumptionEvent.pureAlcoholGrams`. Calories use it unconditionally
(kcal must not move when the user toggles units); **BAC, when added, also uses
0.789** — never the display-unit density.

### Alcohol units (UK standard)

```
units = volumeMl × abv% / 1000     (NHS: 1 unit = 10 ml pure ethanol)
```

Example: 500 ml at 5% = 2.5 UK units. With the `.units` display density of
0.8 g/ml, 1 UK unit = **8.0 g** (was 7.89 g; changed in plan-0025 so the unit
math is exact). **Hand-verify before changing.**

`AlcoholUnit` converts a mass in grams → the user's display unit via
`gramsPerUnit(for: guideline)` (grams = 1, UK units = 8.0 g, US = 14 g,
WHO/DE/custom = 10 g). `formattedValue` renders that to one decimal.

Consumption (mode-mass, summed with the active unit's density) is compared
**directly** to the physical-gram guideline limits. In `.units` (0.8) mode this
is an intended ~1.4% convention offset that makes one 500 ml 5% beer read exactly
100% of the WHO daily limit. Because the math is clean, percentages and risk are
computed **exactly** and formatted only at the leaf — there is no display-rounding
layer (the old `displayValue`/`displayPct`/`todayDisplayPct` machinery was removed
in plan-0025).

### BAC — Widmark (not yet implemented)

```
BAC‰ = pureAlcoholGrams / (bodyWeightKg × r × 10)
     − eliminationRate × hoursElapsed
```

- `r` = 0.68 for males, 0.55 for females
- `eliminationRate` ≈ 0.15 ‰/hour (configurable)
- Display as **‰ (per mille)** in EU builds, **% BAC** in US builds — never mix.
- Always label as an estimate; never present as medical advice.

**Do not implement BAC without explicit confirmation.**

## Entities

### DrinkTemplate
Reusable preset created by the user (future feature). Fields mirror
a `ConsumptionEvent` snapshot. Editing a template must never alter
past events — the relationship uses `deleteRule: .nullify`.

### ConsumptionEvent
Single logged drink. Captures a snapshot of all display fields
(name, category, icon) at insert time so the record is self-contained.
`template` is an optional back-reference; nil means the event was logged
ad-hoc or the template was later deleted.

Additional fields:
- `volumeMl: Double` — volume of a **single** portion (the count is `quantity`).
- `quantity: Int = 1` — number of identical single portions logged in this one
  entry (e.g. "Bottle · 500 ml ×10"). Additive defaulted field → lightweight
  SwiftData migration. Mass = `volumeMl × quantity × abv × density`.
- `price: Double?` — amount paid; currency stored in `UserProfile.currency`. Captured in AddDrink.
- `notes: String?` — free-text note; scaffolded for a future notes feature, not yet in UI.
- `location: String?` — venue or place name; scaffolded for future use, not yet in UI.

### UserProfile
SwiftData singleton (`@Attribute(.unique) id = "singleton"`).
Holds: `bodyWeightKg`, `biologicalSex`, `ageYears`, `guidelineChoice`,
`weeklyGoalGrams`, `unitSystem` (metric / usCustomary / imperial),
`currency`, `abvPrecisionPermille` (5 = 0.5 % steps, 1 = 0.1 % steps),
`alcoholUnit` (grams / units / standardDrinks).

Guideline thresholds are **not** stored in SwiftData — they are computed
on the fly by `GuidelineChoice.limits(for: BiologicalSex)` in
`Domain/GuidelineChoice+Limits.swift`.

## Drink categories

`DrinkCategory` is a `String`-backed `Codable` enum stored on
`ConsumptionEvent`. Adding new cases is always backward-compatible
(existing records decode the stored raw string; unknown cases would
fall back — add a `custom` fallback if decoding unknown raw values
becomes a concern).

Current cases: `beer`, `wine`, `champagne`, `cider`, `alcopop`,
`spirits`, `brandy`, `cognac`, `vodka`, `whiskey`, `tequila`, `shot`,
`liqueur`, `cocktail`, `fortifiedWine`, `hotDrink`, `custom`.

## Risk level

`RiskLevel` (`Domain/RiskLevel.swift`) is the single source of truth for
categorising any percentage-of-limit value. Use `RiskLevel.from(pct:)` everywhere
— never write inline threshold comparisons.

| Case | Condition | Color (badge/text) | Color (arc/chart) |
|------|-----------|--------------------|-------------------|
| `.safe` | pct < 0.5 | `dpGreen` | `dpRiskLow` |
| `.caution` | 0.5 ≤ pct ≤ 1.0 | `dpAmber` | `dpRiskModerate` |
| `.exceeded` | pct > 1.0 | `dpRed` | `dpRiskHigh` |

The boundary rule: **100% is `.caution`, not `.exceeded`** — the user is at the
limit, not over it. Color extensions live in `DesignSystem/RiskLevel+Color.swift`:
`.color` for badges and text, `.chartColor` for arcs and bar charts.

## Guideline thresholds (reference values)

Thresholds are sex-differentiated where the guideline specifies it.
Source of truth: `GuidelineChoice.limits(for:)` in `GuidelineChoice+Limits.swift`.

| Guideline | Sex | Daily (g) | Weekly (g) |
|-----------|-----|-----------|------------|
| WHO       | male | 20       | 100        |
| WHO       | female | 10     | 70         |
| DE (DHS)  | male | 24       | 168        |
| DE (DHS)  | female | 12     | 84         |
| UK (NHS)  | both | 0 *     | 112        |
| US (NIAAA)| male | 28      | 196        |
| US (NIAAA)| female | 14    | 98         |

\* UK states no safe daily limit; weekly is the primary metric.
UK weekly = 14 units × 8.0 g (10 ml ethanol × 0.8 display density) = 112 g
(plan-0025 / ADR-0005).

### Resolving limits for a profile

`limits(for:)` returns the raw guideline thresholds and uses **sentinel zeros**:
`.custom` returns `(0, 0)` (it has no built-in thresholds) and UK returns
`(0, weekly)` (no daily limit). Call sites must never consume these directly.
Instead use the two resolvers, which centralise the fallbacks:

- `GuidelineChoice.effectiveLimits(weeklyGoalGrams:for:)` — for `.custom`,
  derives limits from the user's weekly goal (clamped to ≥1 g so it can't
  produce a zero denominator); otherwise returns the raw thresholds.
- `GuidelineLimits.effectiveDailyGrams` — the daily figure to compare a single
  day against: `dailyGrams` when set, else `weeklyGrams / 7` (UK fallback).

Dashboard, Insights, and the History calendar all go through these, so the
custom-guideline and UK-no-daily handling lives in exactly one place.

Density used to convert volume → mass depends on the display unit
(`.grams`/`.standardDrinks` → 0.789, `.units` → 0.8); physical mass (calories,
future BAC) always uses **0.789 g/ml** (scientific ethanol density at 20 °C).
See the Calculations section and ADR-0005.

## Backup / restore format

The JSON backup is a versioned `ExportBundle`. The current version is **2**.

```
ExportBundle {
  version: Int          // 1 = events only; 2 = events + profile
  exportedAt: Date      // ISO 8601
  events: [ExportRecord]
  profile: ProfileRecord?  // nil in v1; present in v2
}
```

### Version compatibility

| Imported file version | Behaviour |
|-----------------------|-----------|
| 1 | Imports events; no profile update. |
| 2 | Imports events; upserts profile (overwrite-in-place if one exists). |
| ≥ 3 (future) | Throws `ImportError.unsupportedVersion` — user must update app. |

Per-event `quantity` was added in plan-0025 as an **optional** field (the bundle is
still version 2). Files written before it decode `quantity = 1`; older folded
multi-drink rows keep their grams but show as a single large portion until corrected.

### Profile upsert rule

Single-user app: there is always at most one `UserProfile`. On import:
- If a profile exists → overwrite all fields from `ProfileRecord` (silent, restore intent).
- If no profile exists → insert a new one from the record.

### Export regeneration

The share file is regenerated whenever the **content signature** changes — a hash
over event fields (timestamp, volumeMl, abv, quantity, customName, category, icon,
notes, price) and profile fields.
This ensures edits refresh the file even when the total event count is unchanged.
Regeneration runs in `.task(id: contentSignature)` in `DataSection`.
