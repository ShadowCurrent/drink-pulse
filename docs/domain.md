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

**Density depends on the display mode AND the selected guideline**
(`AlcoholUnit.density(for:)`, ADR-0006 / plan-0029, amending ADR-0005), so the
unit math lands on clean numbers for every country:

| mode | guideline | density (g/ml) | example |
|---|---|---|---|
| `.grams` | any | 0.789 (scientific ethanol, 20 °C) | 500 ml × 5% = 19.725 g |
| `.standardDrinks` | US, CA | 0.789 | US 355 ml × 5% = 14.0 g = 1.0; CA 341 ml × 5% = 13.45 g = 1.0 |
| `.standardDrinks` | WHO, DE, AU, UK, custom | 0.8 | EU 500 ml × 5% = 20.0 g = 2.0 (WHO/DE/AU) / 2.5 UK |

`AlcoholUnit` has exactly two cases: `grams` and `standardDrinks` (the old `.units`
case was removed in plan-0029; the UK folds into `.standardDrinks` at 8 g/unit, 0.8
density). A persisted `"units"` — and any unknown raw value — decodes to
`.standardDrinks` via `AlcoholUnit.init(from:)` (lightweight migration, no store wipe).

**Physical mass always uses 0.789** (`AlcoholUnit.physicalDensityGramsPerMl`),
exposed as `ConsumptionEvent.pureAlcoholGrams`. Calories use it unconditionally
(kcal must not move when the user toggles units); **BAC, when added, also uses
0.789** — never the display-unit density.

### Alcohol units (UK standard)

```
units = volumeMl × abv% / 1000     (NHS: 1 unit = 10 ml pure ethanol)
```

Example: 500 ml at 5% = 2.5 UK units. With the UK std-drinks display density of
0.8 g/ml, 1 UK unit = **8.0 g** (was 7.89 g; changed in plan-0025 so the unit
math is exact). **Hand-verify before changing.**

`AlcoholUnit` converts a mass in grams → the user's display unit via
`gramsPerUnit(for: guideline)` (grams = 1, UK = 8.0 g, US = 14 g, CA = 13.45 g,
WHO/DE/AU/custom = 10 g). `formattedValue` renders that to one decimal.
`unitLabel(for: guideline)` is guideline-aware: UK reads "units", every other
guideline reads "standard drinks", `.grams` always reads "g".

Consumption (mode-mass, summed with the active mode/guideline density) is compared
**directly** to the physical-gram guideline limits. In `.standardDrinks` mode for
the **EU/UK guidelines (WHO/DE/AU/UK/custom, 0.8 density)** this is an intended
~1.4% convention offset that makes one 500 ml 5% beer read exactly 100% of the WHO
daily limit. **US/CA have no offset** (consumption and limits both at 0.789).
Because the math is clean, percentages and risk are computed **exactly** and
formatted only at the leaf — there is no display-rounding layer (the old
`displayValue`/`displayPct`/`todayDisplayPct` machinery was removed in plan-0025).

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

## Volume units (display only)

`volumeMl` is the **canonical, exact** stored value for every serving. The
`UserProfile.unitSystem` (`.metric` / `.usCustomary` / `.imperial`) governs only
how that volume is *displayed* and which serving presets are *offered* for new
drinks — it never changes stored data, grams, calories, BAC, guideline %, or
risk (all of those derive from canonical `volumeMl` × physical density). Volume
unit and `alcoholUnit` / `guidelineChoice` are independent (plan-0030).

### Conversion constants (domain rule)

```
1 US fluid ounce       = 29.5735 ml   (UnitSystem.mlPerUSFluidOunce)
1 imperial fluid ounce = 28.4131 ml   (UnitSystem.mlPerImperialFluidOunce)
```

Clean display anchors: 355 ml = 12.0 US fl oz, 473 ml = 16.0 US fl oz,
568 ml = 20.0 imperial fl oz, 284 ml = 10.0 imperial fl oz.

### Rounding policy (domain rule)

`formatVolume` (the raw renderer, e.g. History subtitle / orphaned-serving fallback):

- `.metric` → whole millilitres (`"500 ml"`).
- `.usCustomary` / `.imperial` → fluid ounces to **one decimal place**
  (`"16.9 fl oz"`).

Conversion and rounding live in the Domain layer (`UnitSystem+Volume.swift`,
pure on `(ml, unitSystem)`). ml→oz→ml is lossy in floating point; storage always
keeps the canonical ml and never adopts a displayed/re-parsed oz value.

### Serving-label rule (domain rule, plan-0031, hand-verified)

`servingVolumeLabel` is the **serving-list / picker** renderer (distinct from
`formatVolume`). It adopts pint mode for imperial:

- `.metric` → whole ml (`"568 ml"`).
- `.usCustomary` → ounces, whole or one decimal, with the `.0` dropped
  (`"16 oz"`, `"16.9 oz"`, `"1.5 oz"`).
- `.imperial` → **pint** when pint-native (`"⅓ pint"`, `"½ pint"`, `"⅔ pint"`,
  `"1 pint"`, `"2 pints"`; UK pint = 568 ml), otherwise ounces (`"4.4 oz"`).

`isRoundServing(ml)` decides whether an **inline ml hint** is appended to a
composed serving label (`"Small · 4.4 oz · 125 ml"`): a value is *round* (no hint)
when it lands on a **whole or half ounce**, OR (imperial only) on a **clean pint
fraction**. Metric never hints. The hint uses `Int(ml.rounded())` — never
`Int(ml)` — so non-integer ml (14.78, 444.5) round rather than truncate.

Consequence: a real measure that happens to land exactly on a half ounce
(e.g. 355 ml = 12.5 imp oz, 70 ml = 2.5 imp oz) renders cleanly *without* the ml
hint; the hint appears only for genuinely off-grid values (125 ml = 4.4 oz).

### Region-tag policy (domain rule, plan-0031 — REVERSES plan-0030)

plan-0030 tagged an option to a unit system **only** where its number was a
natural round serving there. plan-0031 **reverses** this to give the US/imperial
serving lists realistic depth:

- **R (round-native)** — a clean round serving in the tagged unit (355 ml = 12 oz
  US).
- **M (real measure)** — a real, deliberately non-round serving in the tagged unit
  (UK 125 ml wine = 4.4 imp oz); the inline ml hint makes the odd oz intentional.
- **X (cross-borrow)** — a serving borrowed across systems (355 ml → imperial,
  568 ml → US as "Stovepipe" and into metric, 500 ml → US/imperial).

Per-region display names (`VolumeOption.regionNames`) let one canonical-ml option
read differently per unit (568 ml = "Pint" in metric/imperial, "Stovepipe" in US).
The merged-568 model keeps each `volumes(for: unit)` list free of duplicate ml.

Label string assembly composes the per-region name + `servingVolumeLabel` +
optional ml hint (`VolumeOption.label(in:)`).

## Entities

### DrinkTemplate
Reusable preset created by the user (future feature). Fields mirror
a `ConsumptionEvent` snapshot. Editing a template must never alter
past events — the relationship uses `deleteRule: .nullify`. Carries a stable
`uuid` and a `modifiedDate` (plan-0023), same identity/LWW role as on
`ConsumptionEvent`.

### ConsumptionEvent
Single logged drink. Captures a snapshot of its display fields
(category, icon) at insert time so the record is self-contained.
`template` is an optional back-reference; nil means the event was logged
ad-hoc or the template was later deleted. (The deprecated `name` snapshot was
**removed in plan-0023 / SchemaV2** — the display name is derived from
category + volume; see "Naming".)

Additional fields:
- `uuid: UUID` — stable record identity (plan-0023). NOT `@Attribute(.unique)`
  (CloudKit can't enforce it), so de-dup/upsert by `uuid` lives in app code
  (`RecordDeduplicator`, importer). `duplicated()` mints a fresh `uuid`.
- `modifiedDate: Date` — last-write-wins clock (plan-0023). Set to `.now` on
  create and on every edit (`touch()`); drives import LWW + the de-dup sweep.
- `consumptionDate: Date` — when the drink was **consumed** (user may backdate).
  Renamed from `timestamp` (plan-0023); `@Attribute(originalName: "timestamp")`
  maps the old column so no data is lost, and the backup wire key stays
  `"timestamp"`. This is the date all day/period aggregation keys off.
- `creationDate: Date` — when the record was **created/logged** (non-optional).
  New inserts seed it from `consumptionDate`; the V1→V2 migration backfills
  existing rows from their `consumptionDate`. Metadata only — no calculation uses it.
- `volumeMl: Double` — volume of a **single** portion (the count is `quantity`).
- `quantity: Int = 1` — number of identical single portions logged in this one
  entry (e.g. "Bottle · 500 ml ×10"). Additive defaulted field → lightweight
  SwiftData migration. Mass = `volumeMl × quantity × abv × density`.
- `enteredUnit: UnitSystem?` — unit-system **provenance** (plan-0031 / ADR-0007).
  The unit in effect when the drink was logged; drives which serving *name* is
  shown so it stays stable across later unit-mode switches. Optional, default nil
  (additive lightweight migration; legacy events name via the current profile
  unit). Never edited after log time, never affects any calculation.
- `price: Double?` — amount paid. Captured in Add/Edit.
- `priceCurrency: String?` — ISO 4217 code the `price` was entered in (plan-0034).
  Persisted **with** the price so a stored amount is never reinterpreted when the
  user later changes `UserProfile.currency`. Optional, default nil (additive
  lightweight migration; legacy/no-price events fall back to the profile currency
  for display). Seeded from the profile currency at entry, overridable per event.
  Never affects any calculation. Currency choices: `CurrencyCatalog.common`
  (a short common list, not full ISO 4217).
- `notes: String?` — free-text note; scaffolded for a future notes feature, not yet in UI.
- `location: String?` — venue or place name; scaffolded for future use, not yet in UI.
- `healthKitUUID: UUID?` — device-local cache of the Apple Health sample this event
  was written to (plan-0036, SchemaV4; additive optional → lightweight migration).
  **Never exported, never synced** — an HKSample UUID is meaningful only on the
  device that created it; the durable cross-device key is the sample's
  `metadata["dp_event_uuid"] == uuid`. Never affects any calculation. See ADR-0011.

### Apple Health write-back mapping (domain rule, plan-0036)
HealthKit has **no grams-based alcohol type**. Logged drinks are mirrored to
`numberOfAlcoholicBeverages` as a **count = `pureAlcoholGrams / 14.0`** (Apple fixes
one beverage = a US standard drink = 14 g). The 14 g divisor is **fixed** —
independent of the user's guideline/display unit — so Health values never shift when
the user toggles units, matching the calories/BAC posture of using physical 0.789.
The count is written at full `Double` precision (no rounding); grams are recoverable
as `count × 14`. This is a derived output only — no stored value and no existing
calculation changes.

### UserProfile
SwiftData singleton. `id = "singleton"` is **no longer** `@Attribute(.unique)` —
the constraint was dropped for CloudKit (plan-0023 / SchemaV2), and the single-
profile invariant is now enforced in code by `UserProfileStore` (fetch-or-create
+ de-dupe keeping the newest `modifiedDate`).
Holds: `bodyWeightKg`, `biologicalSex`, `dateOfBirth: Date?`,
`guidelineChoice`, `weeklyGoalGrams`, `unitSystem`
(metric / usCustomary / imperial), `currency`, `abvPrecisionPermille`
(5 = 0.5 % steps, 1 = 0.1 % steps), `alcoholUnit`
(grams / standardDrinks; default standardDrinks), and `modifiedDate` (LWW clock,
plan-0023). `ageYears` is **not** stored — it is a computed getter derived from
`dateOfBirth`.

All `UserProfile` / `ConsumptionEvent` / `DrinkTemplate` attributes carry an
**inline default** (CloudKit materializes records without running `init`).

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

| Guideline | Sex | Daily (g) | Weekly (g) | Std drink (g) | Weekly basis |
|-----------|-----|-----------|------------|---------------|--------------|
| WHO       | male | 20       | 100        | 10            | daily × 5 (2 free days) |
| WHO       | female | 10     | 50         | 10            | daily × 5 (2 free days) |
| DE (DHS)  | male | 24       | 120        | 10            | daily × 5 (2 free days) |
| DE (DHS)  | female | 12     | 60         | 10            | daily × 5 (2 free days) |
| UK (NHS)  | both | 0 *     | 112        | 8.0           | independent published value |
| US (NIAAA)| male | 28      | 196        | 14            | daily × 7 (no free days) |
| US (NIAAA)| female | 14    | 98         | 14            | daily × 7 (no free days) |
| AU (NHMRC 2020) | both | 40 | 100       | 10            | independent published value |
| CA (Health Canada) | male | 40.35 | 201.75 | 13.45      | 3/15 std drinks, daily × 5 |
| CA (Health Canada) | female | 26.9 | 134.5 | 13.45     | 2/10 std drinks, daily × 5 |

\* UK states no safe daily limit; weekly is the primary metric.
UK weekly = 14 units × 8.0 g (10 ml ethanol × 0.8 display density) = 112 g
(plan-0025 / ADR-0005).

AU: NHMRC 2020 "≤4 standard drinks on any day, ≤10/week". 1 AU std drink = 10 g.
Daily and weekly are independent published caps (4 × 10 ≠ 10 × anything; weekly is
not derivable from daily × n — this is why all guidelines store daily+weekly as
independent constants rather than using a formula).

CA: Health Canada LRDG-2011 (page updated 2025-03-25; still LRDG-2011, not the
stricter CCSA-2023 guidance). 1 CA std drink = 13.45 g (341 ml × 5% × 0.789).
Men 3/day × 13.45 = 40.35 g/day; 15/week × 13.45 = 201.75 g/week.
Women 2/day × 13.45 = 26.9 g/day; 10/week × 13.45 = 134.5 g/week.

### Resolving limits for a profile

`limits(for:)` returns the raw guideline thresholds and uses **sentinel zeros**:
`.custom` returns `(0, 0)` (it has no built-in thresholds) and UK returns
`(0, weekly)` (no daily limit). Call sites must never consume these directly.
Instead use the two resolvers, which centralise the fallbacks:

- `GuidelineChoice.effectiveLimits(weeklyGoalGrams:for:)` — for `.custom`,
  derives limits from the user's weekly goal (clamped to ≥1 g so it can't
  produce a zero denominator); otherwise returns the raw thresholds.
- `GuidelineLimits.effectiveDailyGrams` — the daily figure to compare a single
  day against: `dailyGrams` when set, else `weeklyGrams / 7` (UK fallback only —
  AU and CA supply a real daily limit and bypass this fallback).

Dashboard, Insights, and the History calendar all go through these, so the
custom-guideline and UK-no-daily handling lives in exactly one place.

Density used to convert volume → mass depends on the display mode and guideline
(`.grams` → 0.789 always; `.standardDrinks` → 0.789 for US/CA, 0.8 for
WHO/DE/AU/UK/custom); physical mass (calories, future BAC) always uses **0.789 g/ml**
(scientific ethanol density at 20 °C). See the Calculations section and ADR-0006.

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
notes, price, priceCurrency) and profile fields.
This ensures edits refresh the file even when the total event count is unchanged.
Regeneration runs in `.task(id: contentSignature)` in `DataSection`.
