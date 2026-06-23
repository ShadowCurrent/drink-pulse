# DrinkPulse — Volume preset inventory (export for review)

Generated 2026-06-22 from the live code (plan-0030):
`DrinkTypePreset.swift`, `+FermentedPresets.swift`, `+SpiritPresets.swift`.

## How presets work (context for whoever reviews this)

- `volumeMl` is the **canonical, exact stored value**. Everything else (grams,
  calories, %, BAC) derives from it. Volume unit is **display + which presets are
  offered** only.
- Each serving is a `VolumeOption { descriptor, volumeMl, regions }`.
- `regions` = which unit system(s) the option is **offered in for NEW drinks**:
  - `metric` (M) → round millilitres
  - `usCustomary` (US) → round US fl oz (1 US fl oz = 29.5735 ml)
  - `imperial` (IMP) → round imperial fl oz / pints (1 imp fl oz = 28.4131 ml)
- Policy: an option is tagged to a unit system only where its number is a
  **natural round serving in that unit**. Multi-tag only where genuinely round
  in 2+ systems.
- **Coverage invariant**: every category must yield ≥1 option per unit system.
- Display rounding: metric = whole ml; oz = 1 decimal place.

## THE PROBLEM being reviewed

The **US** and **imperial** lists are far too sparse — most categories offer only
1–2 oz-native servings while metric has 8–16. See the gap counts per category
below. Goal: expand the US-native and imperial-native serving lists to what a
real US-market / UK-market drinker would expect.

---

## Per-category inventory

Legend: `ml` = canonical stored value. `US oz` = ml ÷ 29.5735. `IMP oz` = ml ÷ 28.4131.
Tags: **M** = metric, **US** = usCustomary, **IMP** = imperial.

### Beer  🍺  (default 500 ml, 5.0%)
| descriptor | ml | US oz | IMP oz | tags |
|---|---|---|---|---|
| Stange | 200 | 6.76 | 7.04 | M |
| Small glass | 250 | 8.45 | 8.80 | M |
| Half-pint | 284 | 9.60 | 10.00 | IMP |
| Pot AU | 285 | 9.64 | 10.03 | M |
| 0.3 L | 300 | 10.14 | 10.56 | M |
| Can | 330 | 11.16 | 11.61 | M |
| US can | 355 | 12.00 | 12.49 | US |
| 0.4 L | 400 | 13.53 | 14.08 | M |
| Schooner AU | 425 | 14.37 | 14.96 | M |
| Big can | 440 | 14.88 | 15.49 | M |
| US pint | 473 | 16.00 | 16.65 | US |
| Bottle | 500 | 16.91 | 17.60 | M |
| Pint | 568 | 19.21 | 20.00 | IMP |
| Large bottle | 660 | 22.32 | 23.23 | M |
| Bomber | 750 | 25.36 | 26.40 | M |
| Mug | 1000 | 33.81 | 35.20 | M |
→ **M: 12, US: 2, IMP: 2**

### Wine  🍷  (default 150 ml, 12.5%)
| descriptor | ml | US oz | IMP oz | tags |
|---|---|---|---|---|
| Tasting | 100 | 3.38 | 3.52 | M |
| Small | 125 | 4.23 | 4.40 | M |
| US pour | 148 | 5.00 | 5.21 | US |
| Standard | 150 | 5.07 | 5.28 | M |
| Imperial pour | 142 | 4.80 | 5.00 | IMP |
| Medium | 175 | 5.92 | 6.16 | M |
| Large | 250 | 8.45 | 8.80 | M |
| Half btl | 375 | 12.68 | 13.20 | M |
| Carafe | 500 | 16.91 | 17.60 | M |
| Bottle | 750 | 25.36 | 26.40 | M |
→ **M: 8, US: 1, IMP: 1**

### Champagne  🥂  (default 125 ml, 12.0%)
| descriptor | ml | US oz | IMP oz | tags |
|---|---|---|---|---|
| Toast | 100 | 3.38 | 3.52 | M |
| Flute | 125 | 4.23 | 4.40 | M |
| US flute | 118 | 3.99 | 4.15 | US |
| Imperial flute | 114 | 3.86 | 4.01 | IMP |
| Large | 150 | 5.07 | 5.28 | M |
| Coupe | 180 | 6.09 | 6.34 | M |
| Glass | 200 | 6.76 | 7.04 | M |
| Bottle | 750 | 25.36 | 26.40 | M |
→ **M: 6, US: 1, IMP: 1**

### Cider  🍏  (default 500 ml, 4.5%)
| descriptor | ml | US oz | IMP oz | tags |
|---|---|---|---|---|
| Half-pint | 284 | 9.60 | 10.00 | IMP |
| Can | 330 | 11.16 | 11.61 | M |
| US can | 355 | 12.00 | 12.49 | US |
| Big can | 440 | 14.88 | 15.49 | M |
| US pint | 473 | 16.00 | 16.65 | US |
| Bottle | 500 | 16.91 | 17.60 | M |
| Pint | 568 | 19.21 | 20.00 | IMP |
| Large bottle | 750 | 25.36 | 26.40 | M |
→ **M: 4, US: 2, IMP: 2**

### Alcopop  🫧  (default 275 ml, 5.0%)
| descriptor | ml | US oz | IMP oz | tags |
|---|---|---|---|---|
| Can | 250 | 8.45 | 8.80 | M |
| Bottle | 275 | 9.30 | 9.68 | M |
| US can | 355 | 12.00 | 12.49 | US |
| Half-pint | 284 | 9.60 | 10.00 | IMP |
| Can | 330 | 11.16 | 11.61 | M |
| Large | 500 | 16.91 | 17.60 | M |
→ **M: 4, US: 1, IMP: 1**

### Cocktail  🍹  (default 200 ml, 15.0%)
| descriptor | ml | US oz | IMP oz | tags |
|---|---|---|---|---|
| Short | 100 | 3.38 | 3.52 | M |
| Small | 125 | 4.23 | 4.40 | M |
| Medium | 150 | 5.07 | 5.28 | M |
| US pour | 148 | 5.00 | 5.21 | US |
| Imperial pour | 142 | 4.80 | 5.00 | IMP |
| Long | 200 | 6.76 | 7.04 | M |
| US tall | 237 | 8.01 | 8.34 | US |
| Imperial tall | 227 | 7.67 | 7.99 | IMP |
| Tall | 250 | 8.45 | 8.80 | M |
| XL | 300 | 10.14 | 10.56 | M |
→ **M: 6, US: 2, IMP: 2**

### Fortified wine  🍾  (default 75 ml, 18.0%)
| descriptor | ml | US oz | IMP oz | tags |
|---|---|---|---|---|
| Standard | 50 | 1.69 | 1.76 | M |
| US pour | 59 | 1.99 | 2.08 | US |
| Imperial pour | 57 | 1.93 | 2.01 | IMP |
| Large | 60 | 2.03 | 2.11 | M |
| Aperitif | 75 | 2.54 | 2.64 | M |
| Vermouth | 100 | 3.38 | 3.52 | M |
→ **M: 4, US: 1, IMP: 1**

### Hot drink  ☕  (default 200 ml, 12.0%)
| descriptor | ml | US oz | IMP oz | tags |
|---|---|---|---|---|
| Toddy | 150 | 5.07 | 5.28 | M |
| US pour | 148 | 5.00 | 5.21 | US |
| Imperial pour | 142 | 4.80 | 5.00 | IMP |
| Mug | 200 | 6.76 | 7.04 | M |
| US mug | 237 | 8.01 | 8.34 | US |
| Imperial mug | 227 | 7.67 | 7.99 | IMP |
| Mulled | 250 | 8.45 | 8.80 | M |
| Large | 300 | 10.14 | 10.56 | M |
→ **M: 4, US: 2, IMP: 2**

### Spirits / Brandy / Cognac / Vodka / Whiskey / Tequila / Shot / Liqueur  🥃
All eight spirit categories share ONE shared list (`shotVolumes`). Defaults differ
per category but the serving options are identical.
| descriptor | ml | US oz | IMP oz | tags |
|---|---|---|---|---|
| EU single | 20 | 0.68 | 0.70 | M |
| Single | 25 | 0.85 | 0.88 | M |
| Imperial single | 28 | 0.95 | 0.99 | IMP |
| Nip | 30 | 1.01 | 1.06 | M |
| Irish single | 35 | 1.18 | 1.23 | M |
| Nordic | 40 | 1.35 | 1.41 | M |
| US shot | 44 | 1.49 | 1.55 | US |
| Double | 50 | 1.69 | 1.76 | M |
| Imperial double | 57 | 1.93 | 2.01 | IMP |
| US double | 59 | 1.99 | 2.08 | US |
| Irish double | 70 | 2.37 | 2.46 | M |
| Triple | 75 | 2.54 | 2.64 | M |
→ **M: 8, US: 2, IMP: 2**  (same for all 8 spirit categories)

Spirit category defaults (ml): Spirits 50, Brandy 40, Cognac 40, Vodka 40,
Whiskey 40, Tequila 40, Shot 40, Liqueur 50.

---

## Gap summary (the ask)

| Category | M | US | IMP |
|---|---|---|---|
| Beer | 12 | 2 | 2 |
| Wine | 8 | 1 | 1 |
| Champagne | 6 | 1 | 1 |
| Cider | 4 | 2 | 2 |
| Alcopop | 4 | 1 | 1 |
| Cocktail | 6 | 2 | 2 |
| Fortified | 4 | 1 | 1 |
| Hot drink | 4 | 2 | 2 |
| Spirits (×8) | 8 | 2 | 2 |

US and IMP are starved everywhere. Need realistic, market-typical serving lists
for each.

## Constraints for any proposed new presets

- Output canonical **ml** for each (it is what gets stored), plus the round oz/pint
  it represents.
- US servings should be round **US fl oz** (or standard US container sizes:
  12 oz can, 16 oz pint, 24 oz, 40 oz, etc.).
- Imperial servings should be round **imperial fl oz / UK pints**
  (half-pint = 10 imp oz = 284 ml, pint = 20 imp oz = 568 ml, etc.).
- Keep `descriptor` with NO number baked in (the number is rendered from ml at
  display time). Descriptor is a name like "Can", "Pint", "Shot".
- Spirits share ONE list across all 8 categories — propose one shared US list and
  one shared IMP list for spirits.
- Don't touch metric. Don't change stored ml semantics. This is purely about which
  serving options to OFFER in US and imperial modes.
