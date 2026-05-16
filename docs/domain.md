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

Density of ethanol = 0.789 g/ml. This is the canonical formula; never
store this derived value — always compute on the fly.

### Alcohol units (UK standard)

```
units = volumeMl × abv / 10
```

Equivalent to `ml × abv% / 1000`. Example: 568 ml pint at 5% = 2.84 units.
**Hand-verify before changing.**

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

### UserProfile
SwiftData singleton (`@Attribute(.unique) id = "singleton"`).
Holds: bodyWeightKg, biologicalSex, ageYears, guidelineChoice,
weeklyGoalGrams, unitSystem, currency.

### GuidelineProfile
Stores threshold values for a named guideline (WHO, DE, UK, US, custom).
Created via static factory methods; seeding into the store is the
repository's responsibility.

## Drink categories

`DrinkCategory` is a `String`-backed `Codable` enum stored on
`ConsumptionEvent`. Adding new cases is always backward-compatible
(existing records decode the stored raw string; unknown cases would
fall back — add a `custom` fallback if decoding unknown raw values
becomes a concern).

Current cases: `beer`, `wine`, `champagne`, `spirits`, `cocktail`,
`cider`, `custom`.

## Guideline thresholds (reference values)

| Guideline | Daily (g) | Weekly (g) | Binge (g) |
|-----------|-----------|------------|-----------|
| WHO       | 20        | 100        | 60        |
| DE (DHS)  | 24        | 168        | 60        |
| UK (NHS)  | 0 *       | 112        | 60        |
| US (NIAAA)| 28        | 196        | 70        |

\* UK states no safe daily limit; weekly is the primary metric.
