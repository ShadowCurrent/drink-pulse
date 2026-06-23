# DrinkPulse — US & imperial serving-list proposal

Proposed expansion of the **US (usCustomary)** and **imperial** quick-pick serving
lists. Companion to `volume-presets-export.md` (plan-0030). Targets:
`DrinkTypePreset.swift`, `+FermentedPresets.swift`, `+SpiritPresets.swift`.

**Scope:** US-mode and IMP-mode offered options only. **Metric is untouched.**
Stored `volumeMl` semantics unchanged — every value below is canonical ml that
rounds cleanly to the stated oz/pint.

Conversions used: `1 US fl oz = 29.5735 ml`, `1 imp fl oz = 28.4131 ml`,
`1 UK pint = 568 ml`, `½ pint = 284 ml`.

---

## Read this first: four categories aren't really imperial

The UK does **not** pour these in imperial fl oz — it pours them in **metric legal
measures**:

| Category | What UK actually uses |
|---|---|
| Wine | 125 / 175 / 250 ml |
| Champagne | 125 ml flute |
| Spirits | 25 / 35 / 50 ml |
| Alcopop / RTD | 275 ml bottle |

Only **Beer** and **Cider** are genuinely imperial (pints) in the UK.

For the four metric-reality categories, the imperial rows below are **round-imp-oz
approximations** offered only to satisfy the coverage invariant (≥1 IMP option per
category). A real UK drinker is mentally picking the metric measure. They're marked
⚠️ `approx`. **Decision needed:** ship the approximations, or let those four fall
back to metric in imperial mode. (My lean: ship them — coverage invariant wins, and
the rounding error is ≤3 ml.)

---

## Tagging strategy (how these map onto VolumeOption)

Two ways to give an existing ml value a new region:

- **TAG** — add the region to an *existing* `VolumeOption.regions`. Only do this when
  the existing descriptor still reads naturally in the new system **and** the number
  is round there. (e.g. spirits `Nip` 30 ml = 1.0 US oz → just add `usCustomary`.)
- **NEW** — add a *separate* `VolumeOption` with a system-appropriate descriptor.
  Use this when the same ml is a *container* in one system but a *confusing pour*
  in the other. Example: 568 ml is a clean UK `Pint` (20 imp oz) but only 19.2 US
  oz — not a round US pour, yet exactly the US craft "stovepipe" can. Sharing the
  `Pint` descriptor across both would mislead a US user (who expects 473 ml), so US
  gets its own `Stovepipe` 568 NEW. Near-duplicate ml with distinct descriptors is
  already a pattern in your data (284 `Half-pint` vs 285 `Pot AU`, 330 `Can` vs 355
  `US can`), so this is consistent.

`Δ` column: **NEW** = add option · **TAG** = add region to existing option.

---

## Beer 🍺 — genuinely imperial

### US
| descriptor | ml | US oz | Δ |
|---|---|---|---|
| Taster | 148 | 5 (flight) | NEW |
| Short pour | 296 | 10 | NEW |
| Can | 355 | 12 | exists (US) |
| Pint | 473 | 16 | exists (US) |
| Stovepipe | 568 | 19.2 (craft can) | NEW |
| Bomber | 651 | 22 | NEW |
| Big can | 710 | 24 | NEW |
| Crowler | 946 | 32 | NEW |
| Forty | 1183 | 40 | NEW |

### Imperial — pint fractions, the real UK draught measures
| descriptor | ml | imp | Δ |
|---|---|---|---|
| Third | 189 | ⅓ pint | NEW |
| Half-pint | 284 | ½ pint (10 oz) | exists (IMP) |
| Schooner | 379 | ⅔ pint | NEW |
| Pint | 568 | 1 pint (20 oz) | exists (IMP) |
| Stein | 1136 | 2 pints | NEW |

## Cider 🍏 — UK is a pint drink, US is canned

### US
| descriptor | ml | US oz | Δ |
|---|---|---|---|
| Can | 355 | 12 | exists (US) |
| Pint | 473 | 16 | exists (US) |
| Stovepipe | 568 | 19.2 (craft can) | NEW |
| Big can | 710 | 24 | NEW |

### Imperial
| descriptor | ml | imp | Δ |
|---|---|---|---|
| Half-pint | 284 | ½ pint | exists (IMP) |
| Pint | 568 | 1 pint | exists (IMP) |
| Flagon | 1136 | 2 pints (scrumpy) | NEW |

## Wine 🍷 — UK is metric ⚠️

### US
| descriptor | ml | US oz | Δ |
|---|---|---|---|
| Taste | 59 | 2 | NEW |
| Small | 89 | 3 | NEW |
| Pour | 148 | 5 (std US pour) | exists (US) |
| Generous | 177 | 6 | NEW |
| Large | 237 | 8 | NEW |
| Bottle | 750 | 25.4 (container) | TAG |

### Imperial ⚠️ approx (≈ 125 / 175 / 250 ml legal measures)
| descriptor | ml | imp oz | Δ |
|---|---|---|---|
| Small | 142 | 5 (≈125 ml) | exists (IMP) |
| Medium | 170 | 6 (≈175 ml) | NEW |
| Large | 256 | 9 (≈250 ml) | NEW |
| Bottle | 750 | 26.4 | TAG |

## Champagne 🥂 — UK is metric ⚠️

### US
| descriptor | ml | US oz | Δ |
|---|---|---|---|
| Toast | 89 | 3 | NEW |
| Flute | 118 | 4 | exists (US) |
| Pour | 148 | 5 | NEW |
| Coupe | 177 | 6 | NEW |
| Bottle | 750 | 25.4 | TAG |

### Imperial ⚠️ approx
| descriptor | ml | imp oz | Δ |
|---|---|---|---|
| Flute | 114 | 4 | exists (IMP) |
| Coupe | 170 | 6 | NEW |
| Bottle | 750 | 26.4 | TAG |

## Alcopop / RTD 🫧 — UK is metric ⚠️

### US — White Claw / hard-seltzer sizing
| descriptor | ml | US oz | Δ |
|---|---|---|---|
| Can | 355 | 12 | exists (US) |
| Tallboy | 473 | 16 | NEW |
| Big can | 710 | 24 | NEW |

### Imperial ⚠️ approx (UK ships 275 ml metric)
| descriptor | ml | imp | Δ |
|---|---|---|---|
| Half-pint | 284 | ½ pint | exists (IMP) |
| Pint | 568 | 1 pint | NEW |

## Cocktail 🍹

### US
| descriptor | ml | US oz | Δ |
|---|---|---|---|
| Coupe | 118 | 4 | NEW |
| Martini | 148 | 5 | exists (US) |
| Rocks | 177 | 6 | NEW |
| Highball | 237 | 8 | exists (US) |
| Collins | 296 | 10 | NEW |
| Tiki | 355 | 12 | NEW |
| Pitcher pour | 473 | 16 | NEW |

### Imperial
| descriptor | ml | imp oz | Δ |
|---|---|---|---|
| Coupe | 114 | 4 | NEW |
| Martini | 142 | 5 | exists (IMP) |
| Rocks | 170 | 6 | NEW |
| Highball | 227 | 8 | exists (IMP) |
| Collins | 284 | 10 | NEW |
| Large | 341 | 12 | NEW |

## Fortified wine 🍾

### US
| descriptor | ml | US oz | Δ |
|---|---|---|---|
| Small | 44 | 1.5 | NEW |
| Pour | 59 | 2 | exists (US) |
| Port | 89 | 3 | NEW |
| Aperitif | 118 | 4 | NEW |

### Imperial
| descriptor | ml | imp oz | Δ |
|---|---|---|---|
| Sherry | 57 | 2 | exists (IMP) |
| Port | 85 | 3 | NEW |
| Aperitif | 114 | 4 | NEW |

## Hot drink ☕

### US
| descriptor | ml | US oz | Δ |
|---|---|---|---|
| Toddy | 148 | 5 | exists (US) |
| Mug | 237 | 8 | exists (US) |
| Large mug | 296 | 10 | NEW |
| Tankard | 355 | 12 | NEW |

### Imperial
| descriptor | ml | imp oz | Δ |
|---|---|---|---|
| Toddy | 142 | 5 | exists (IMP) |
| Mug | 227 | 8 | exists (IMP) |
| Large mug | 284 | 10 | NEW |
| Tankard | 341 | 12 | NEW |

## Spirits 🥃 — ONE shared list (all 8 subtypes)

### US — 1.5 oz shot standard
| descriptor | ml | US oz | Δ |
|---|---|---|---|
| Nip | 30 | 1 | TAG (re-tag existing Nip; don't add "Pony" dup) |
| Shot | 44 | 1.5 | exists (US) |
| Neat | 59 | 2 | rename (was "US double"; 59 ml is a 2 oz neat, not a double) |
| Double | 89 | 3 | NEW (true US double) |

### Imperial ⚠️ approx (≈ 25 / 50 / 70 ml measures)
| descriptor | ml | imp oz | Δ |
|---|---|---|---|
| Single | 28 | 1 (≈25 ml) | exists (IMP) |
| Double | 57 | 2 (≈50 ml) | exists (IMP) |
| Large | 85 | 3 (≈70 ml) | NEW |

---

## Gap-closure summary (before → after)

| Category | US before | US after | IMP before | IMP after |
|---|---|---|---|---|
| Beer | 2 | 9 | 2 | 5 |
| Wine ⚠️ | 1 | 6 | 1 | 4 |
| Champagne ⚠️ | 1 | 5 | 1 | 3 |
| Cider | 2 | 4 | 2 | 3 |
| Alcopop ⚠️ | 1 | 3 | 1 | 2 |
| Cocktail | 2 | 7 | 2 | 6 |
| Fortified | 1 | 4 | 1 | 3 |
| Hot drink | 2 | 4 | 2 | 4 |
| Spirits (×8) ⚠️ | 2 | 4 | 2 | 3 |

⚠️ = contains imperial approximations of metric legal measures.

## New canonical ml values introduced

These ml are not yet in any list and would be new stored values:

`85, 89, 118, 148*, 170, 177, 189, 237, 256, 296, 341, 379, 473*, 568*, 651, 710, 946, 1136, 1183`

(*already present in some categories; new only where that category lacked it.)
All round to the stated oz/pint within display tolerance (metric = whole ml,
oz = 1 dp).

## Constraints honored

- ✅ Canonical ml given for every option; oz/pint shown alongside.
- ✅ US = round US fl oz or standard US containers (12/16/24/32/40 oz, 19.2 oz can).
- ✅ Imperial = round imp oz / UK pints (½ = 284, pint = 568, ⅓ = 189, ⅔ = 379).
- ✅ Descriptors carry no baked-in number.
- ✅ Spirits remain ONE shared US list + ONE shared imperial list across all 8.
- ✅ Metric untouched; no stored-ml semantics changed.
- ✅ Coverage invariant: every category yields ≥1 option per unit system.

## Open judgment calls

1. **Metric-reality categories (⚠️).** Ship imperial approximations, or fall back to
   metric in imperial mode for wine / champagne / spirits / alcopop?
2. **Niche entries.** `Forty` (beer), `Stein` (beer), `Flagon` (cider) are culturally
   real but uncommon — drop for tighter lists if you prefer.
3. **Spirits "US double" rename.** Renaming 59 ml `US double` → `Neat` changes a
   user-visible descriptor on an existing option. Acceptable, or keep the old name?
4. **568 ml split.** Confirm you're OK with a US `Stovepipe` and IMP `Pint` both at
   568 ml (separate options, not a shared multi-tag).
