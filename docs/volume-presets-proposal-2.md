# DrinkPulse — US & imperial serving-list proposal (v3)

Final pass. Folds in the four decisions on top of v2's "exact ml, never approximate"
principle. Companion to `volume-presets-export.md` (plan-0030). Targets:
`DrinkTypePreset.swift`, `+FermentedPresets.swift`, `+SpiritPresets.swift`.

Conversions: `1 US fl oz = 29.5735 ml`, `1 imp fl oz = 28.4131 ml`, `1 UK pint = 568 ml`.

---

## Decisions applied

1. **Inline metric hint.** Real-measure rows render the source ml on the label, so a
   non-round oz reads as intentional: `Small · 4.4 oz · 125 ml`, not a confusing `4.4 oz`.
2. **Per-region display names.** One option can show a different name per unit system,
   so `Standard` (metric) can read `Sherry` in imperial, `Nip` can read `Pony` in US.
3. **Cross-borrow into metric too** — the universally-recognised servings (pint,
   half-pint, US shot) are now offered to metric users as well.
4. **Niche rows kept** — `Forty`, `Stein`, `Flagon` stay.

### Knock-on effect of decision 2: the 568 ml duplicate collapses

In v2, 568 ml needed two options (UK `Pint` + US `Stovepipe`) because one descriptor
couldn't be right in both systems. Per-region names fix that: **one** option at 568 ml,
named `Pint` in metric/imperial and `Stovepipe` in US. Same for any shared-ml/different-
name serving.

---

## Data-model change (minimal)

```swift
struct VolumeOption {
    let volumeMl: Double                    // canonical, exact — unchanged
    let regions: Set<UnitSystem>            // where it's offered
    let descriptor: String                  // default / fallback name
    let regionNames: [UnitSystem: String]   // NEW: optional per-region overrides
}

extension VolumeOption {
    func name(in s: UnitSystem) -> String { regionNames[s] ?? descriptor }

    // Inline metric hint: append source ml when the value is NOT a clean
    // round serving in the active non-metric unit.
    func label(in s: UnitSystem) -> String {
        let n = name(in: s)
        let v = s.formatted(volumeMl)               // "16 oz", "4.4 oz", "1 pint"
        guard s != .metric, !s.isRoundServing(volumeMl) else { return "\(n) · \(v)" }
        return "\(n) · \(v) · \(Int(volumeMl)) ml"  // e.g. "Single · 0.9 oz · 25 ml"
    }
}
```

`isRoundServing` = lands on a whole/half oz (or a clean pint fraction). Round-native (R)
rows skip the hint; real-measure (M) and odd cross-borrow (X) rows show it. Deterministic
from the data — no extra stored flag.

**Tiers** (accuracy guaranteed by exact ml in all three):
**R** round-native · **M** real-measure (exact, non-round oz) · **X** cross-borrow.
**Δ**: `new` = add option · `tag` = add region to an existing option (no new ml).

The **renders as** column below is the literal label the user sees.

---

## Beer 🍺

### US
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Taster | 148 | 5 oz | R | new |
| Short pour | 296 | 10 oz | R | new |
| Can | 355 | 12 oz | R | tag |
| Pint | 473 | 16 oz | R | tag |
| Stovepipe | 568 | 19.2 oz · 568 ml | R | merged¹ |
| Bomber | 651 | 22 oz | R | new |
| Big can | 710 | 24 oz | R | new |
| Crowler | 946 | 32 oz | R | new |
| Forty | 1183 | 40 oz | R | new |
| Bottle | 500 | 16.9 oz · 500 ml | X | tag |

### Imperial
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Third | 189 | ⅓ pint | R | new |
| Half-pint | 284 | ½ pint | R | tag |
| Schooner | 379 | ⅔ pint | R | new |
| Pint | 568 | 1 pint | R | tag¹ |
| Stein | 1136 | 2 pints | R | new |
| Can | 355 | 12.5 oz · 355 ml | X | tag |

### Metric (borrowed)
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Pint | 568 | 568 ml | X | tag¹ |
| Half-pint | 284 | 284 ml | X | tag |

¹ `568 ml` is one option, `regions = {metric, imperial, usCustomary}`,
`regionNames = [.usCustomary: "Stovepipe"]`, default `descriptor = "Pint"`.

## Cider 🍏

### US
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Can | 355 | 12 oz | R | tag |
| Pint | 473 | 16 oz | R | tag |
| Stovepipe | 568 | 19.2 oz · 568 ml | R | merged |
| Big can | 710 | 24 oz | R | new |
| Bottle | 500 | 16.9 oz · 500 ml | X | tag |

### Imperial
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Half-pint | 284 | ½ pint | R | tag |
| Pint | 568 | 1 pint | R | tag |
| Flagon | 1136 | 2 pints | R | new |
| Bottle | 500 | 17.6 oz · 500 ml | X | tag |

### Metric (borrowed)
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Pint | 568 | 568 ml | X | tag |
| Half-pint | 284 | 284 ml | X | tag |

## Wine 🍷 — UK is metric → real-measure imperial

### US — round pours
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Taste | 59 | 2 oz | R | new |
| Small | 89 | 3 oz | R | new |
| Pour | 148 | 5 oz | R | tag |
| Generous | 177 | 6 oz | R | new |
| Large | 237 | 8 oz | R | new |
| Bottle | 750 | 25.4 oz · 750 ml | X | tag |

### Imperial — real UK legal measures
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Small | 125 | 4.4 oz · 125 ml | M | tag |
| Medium | 175 | 6.2 oz · 175 ml | M | tag |
| Large | 250 | 8.8 oz · 250 ml | M | tag |
| Bottle | 750 | 26.4 oz · 750 ml | X | tag |

## Champagne 🥂 — UK is metric → real-measure imperial

### US
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Toast | 89 | 3 oz | R | new |
| Flute | 118 | 4 oz | R | tag |
| Pour | 148 | 5 oz | R | new |
| Coupe | 177 | 6 oz | R | new |
| Bottle | 750 | 25.4 oz · 750 ml | X | tag |

### Imperial — real measures
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Toast | 100 | 3.5 oz · 100 ml | M | tag |
| Flute | 125 | 4.4 oz · 125 ml | M | tag |
| Bottle | 750 | 26.4 oz · 750 ml | X | tag |

## Alcopop / RTD 🫧 — UK is metric → real-measure imperial

### US — hard-seltzer sizing
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Can | 355 | 12 oz | R | tag |
| Tallboy | 473 | 16 oz | R | new |
| Big can | 710 | 24 oz | R | new |

### Imperial — real measures (UK sells 250 / 275 / 500 ml)
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Can | 250 | 8.8 oz · 250 ml | M | tag |
| Bottle | 275 | 9.7 oz · 275 ml | M | tag |
| Large | 500 | 17.6 oz · 500 ml | M | tag |

## Spirits 🥃 — ONE shared list · UK is metric → real-measure imperial

### US — 1.5 oz shot standard
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Pony | 30 | 1 oz | R | tag² |
| Shot | 44 | 1.5 oz | R | tag² |
| Neat | 59 | 2 oz | R | tag² |
| Double | 89 | 3 oz | R | new |

### Imperial — real UK pub measures
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Single | 25 | 0.9 oz · 25 ml | M | tag |
| Irish single | 35 | 1.2 oz · 35 ml | M | tag |
| Double | 50 | 1.8 oz · 50 ml | M | tag |
| Irish double | 70 | 2.5 oz · 70 ml | M | tag |
| US shot | 44 | 1.5 oz | X | tag |

### Metric (borrowed)
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| US shot | 44 | 44 ml | X | tag |

² Per-region names on existing options: 30 ml `Nip`→`Pony` (US), 44 ml `US shot`→`Shot`
(US), 59 ml `US double`→`Neat` (US). Metric labels unchanged.

## Cocktail 🍹 — free pour, round is genuinely real in both

### US
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Coupe | 118 | 4 oz | R | new |
| Martini | 148 | 5 oz | R | tag |
| Rocks | 177 | 6 oz | R | new |
| Highball | 237 | 8 oz | R | tag |
| Collins | 296 | 10 oz | R | new |
| Tiki | 355 | 12 oz | R | new |
| Pitcher pour | 473 | 16 oz | R | new |

### Imperial
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Coupe | 114 | 4 oz | R | new |
| Martini | 142 | 5 oz | R | tag |
| Rocks | 170 | 6 oz | R | new |
| Highball | 227 | 8 oz | R | tag |
| Collins | 284 | 10 oz | R | new |
| Large | 341 | 12 oz | R | new |

## Fortified wine 🍾

### US
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Small | 44 | 1.5 oz | R | new |
| Pour | 59 | 2 oz | R | tag |
| Port | 89 | 3 oz | R | new |
| Aperitif | 118 | 4 oz | R | new |

### Imperial — real UK measures (per-region name on 50 ml)
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Sherry | 50 | 1.8 oz · 50 ml | M | tag³ |
| Aperitif | 75 | 2.6 oz · 75 ml | M | tag |
| Vermouth | 100 | 3.5 oz · 100 ml | M | tag |

³ 50 ml is metric `Standard`; `regionNames[.imperial] = "Sherry"`.

## Hot drink ☕ — free pour, round is real in both

### US
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Toddy | 148 | 5 oz | R | tag |
| Mug | 237 | 8 oz | R | tag |
| Large mug | 296 | 10 oz | R | new |
| Tankard | 355 | 12 oz | R | new |

### Imperial
| name | ml | renders as | tier | Δ |
|---|---|---|---|---|
| Toddy | 142 | 5 oz | R | tag |
| Mug | 227 | 8 oz | R | tag |
| Large mug | 284 | 10 oz | R | new |
| Tankard | 341 | 12 oz | R | new |

---

## Per-region display names (all overrides in one place)

| ml | category | metric | usCustomary | imperial |
|---|---|---|---|---|
| 568 | beer / cider | Pint | **Stovepipe** | Pint |
| 30 | spirits | Nip | **Pony** | — |
| 44 | spirits | US shot | **Shot** | US shot |
| 59 | spirits | US double | **Neat** | — |
| 50 | fortified | Standard | — | **Sherry** |

Everything else uses a single `descriptor` across systems.

## Cross-borrows into metric (new region tags, no new ml)

The universally-recognised servings surfaced to metric users:
`Beer/Cider → Pint 568, Half-pint 284` · `Spirits → US shot 44`.
(Optional further add if wanted: US `Pint` 473 into metric beer as `US pint` — left out
to keep the metric list lean.)

## Re-tags into US / imperial (no new ml)

- **Wine → IMP:** 125, 175, 250, 750
- **Champagne → IMP:** 100, 125, 750
- **Alcopop → IMP:** 250, 275, 500
- **Spirits → IMP:** 25, 35, 50, 70 · **→ US:** 30 · **→ IMP (borrow):** 44
- **Fortified → IMP:** 50, 75, 100
- **Beer → US:** 500 · **→ IMP:** 355 · **Cider → US/IMP:** 500
- Existing category-local values gaining a region: 148, 177, 237, 284, 568, 750.

## New ml introduced (the only new stored values)

`89, 177, 296, 341, 651, 710, 946, 1136, 1183` — nine. Everything else reuses existing
exact ml via region tags. (v1's invented imperial values 142/170/256/57/85 are gone.)

## Gap closure (before → after)

| Category | US before | US after | IMP before | IMP after | Metric added |
|---|---|---|---|---|---|
| Beer | 2 | 10 | 2 | 6 | +2 |
| Wine | 1 | 6 | 1 | 4 | — |
| Champagne | 1 | 5 | 1 | 3 | — |
| Cider | 2 | 5 | 2 | 4 | +2 |
| Alcopop | 1 | 3 | 1 | 3 | — |
| Cocktail | 2 | 7 | 2 | 6 | — |
| Fortified | 1 | 4 | 1 | 3 | — |
| Hot drink | 2 | 4 | 2 | 4 | — |
| Spirits (×8) | 2 | 4 | 2 | 5 | +1 |

## Constraints honored

- ✅ Exact real ml on every option; nothing bent to force a round oz.
- ✅ Metric stored ml untouched; metric additions are region tags + display-name
  overrides only.
- ✅ Descriptors carry no baked-in number; the number is rendered from ml.
- ✅ Inline metric hint makes non-round real-measure servings self-explanatory.
- ✅ Spirits remain ONE shared list.
- ✅ Coverage invariant: ≥1 option per system per category.
