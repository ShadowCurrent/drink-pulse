# Domain Rules

## ABV convention

ABV is always stored as a **plain fraction** (0.0–1.0).
- 5% beer → `abv = 0.05`
- 40% whisky → `abv = 0.40`

Display layer multiplies by 100 to show "5.0 %". Input fields accept
percentage and divide by 100 before storing.

## Calculations

### Pure alcohol

```
pureAlcoholGrams = volumeMl × abv × 0.789
```

Density constant 0.789 g/ml is the scientific ethanol density at 20 °C
(gives 19.725 g for a 500 ml × 5% beer). Never store this derived value —
always compute on the fly. **Hand-verify before changing.**

### Alcohol units (UK standard)

```
units = volumeMl × abv / 10
```

Equivalent to `ml × abv% / 1000`. Example: 568 ml pint at 5% = 2.84 units.
This is the NHS definition (1 unit = 10 ml pure ethanol). With the
0.789 g/ml density constant, 1 UK unit = 7.89 g.
**Hand-verify before changing.**

`AlcoholUnit` converts grams → the user's display unit via
`gramsPerUnit(for: guideline)` (grams = 1, UK units = 7.89 g, US = 14 g,
WHO/DE/custom = 10 g). `formattedValue` renders that to one decimal.
**Derived figures that must agree with the displayed "X / Y unit" copy** (e.g.
the Dashboard hero arc percentage) use `displayValue` — the same conversion
rounded to one decimal — rather than raw grams. Otherwise a drink that displays
as "1.0 units" (really ~0.98) would drive an arc reading 49% against a "2.0 unit"
limit. The arc fill, the % label, and the arc colour all derive from this
rounded `todayDisplayPct` so the card tells one consistent story.

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
| UK (NHS)  | both | 0 *     | 110.46     |
| US (NIAAA)| male | 28      | 196        |
| US (NIAAA)| female | 14    | 98         |

\* UK states no safe daily limit; weekly is the primary metric.
UK weekly = 14 units × 7.89 g (10 ml ethanol × 0.789 g/ml) = 110.46 g.

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

Density used in all g-based calculations: **0.789 g/ml** (scientific ethanol density at 20 °C).

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

### Profile upsert rule

Single-user app: there is always at most one `UserProfile`. On import:
- If a profile exists → overwrite all fields from `ProfileRecord` (silent, restore intent).
- If no profile exists → insert a new one from the record.

### Export regeneration

The share file is regenerated whenever the **content signature** changes — a hash
over event fields (timestamp, volumeMl, abv, name, notes, price) and profile fields.
This ensures edits refresh the file even when the total event count is unchanged.
Regeneration runs in `.task(id: contentSignature)` in `DataSection`.
