# 0030 — Volume unit display (make `unitSystem` live)

**Status**: in-progress
**Size**: medium
**Created**: 2026-06-22
**Frozen**: 2026-06-22

## Summary

Make `UserProfile.unitSystem` (`.metric` / `.usCustomary` / `.imperial`)
actually drive how serving volumes are *displayed* and which serving
presets are *offered* for new drinks. Today the setting is stored,
exported/imported, and settable, but read nowhere in calculation,
display, or input — it is a dead setting. This plan wires it into the
volume display + input layer only. It is **not** a data-model change:
`ConsumptionEvent.volumeMl` stays the canonical stored value, grams /
calories / guideline % / risk / BAC are all unchanged, the export/import
file format is unchanged (still ml), and `alcoholUnit` is untouched.

## Context

What triggered this: the Settings "Volume unit" picker exists but does
nothing. A grep for `unitSystem` across the codebase hits only Settings
UI, `UserProfile`, and the data-transfer layer (`DataExporter`,
`ProfileRecord`) — never the calculation, display, or input paths. Only
`alcoholUnit` (`.grams` / `.standardDrinks`) currently affects what the
user sees.

Constraints that shape the design:

- **`volumeMl` is canonical and exact.** Grams and calories convert from
  the stored ml via physical density (`ConsumptionEvent.pureAlcoholGrams`,
  0.789), independent of any display unit. So this is purely a
  display + input concern.
- **No SwiftData migration.** No stored property changes shape.
- **`unitSystem` and `alcoholUnit` / `guidelineChoice` stay independent.**
  Density and grams-per-unit are keyed on the *guideline* (plan-0029 /
  ADR-0006), never on `unitSystem`. Volume unit governs only the ml↔oz
  presentation of serving size. Do not couple them.
- Conversions: **1 US fl oz = 29.5735 ml**, **1 imperial fl oz =
  28.4131 ml**.
- Existing preset volumes are already mostly clean across units
  (355 ml = 12.0 US fl oz, 473 ml = 16.0 US fl oz, 568 ml = 20.0 imperial
  fl oz, 284 ml = 10.0 imperial fl oz), so the cheap path is to
  region-tag the existing master list and format on the fly — not to
  hand-maintain three parallel volume tables.

## Scope

### In

- A Domain-layer volume formatter on `UnitSystem`
  (`formatVolume(_:)`, `volumeUnitLabel`, ml↔oz constants).
- Replace the `[VolumeOption]` shape in `DrinkTypePreset` with a
  region-tagged master list per category: one canonical ml value per
  entry, a unit-neutral `descriptor` (no number baked into the string),
  and a `regions: Set<UnitSystem>` tag for which unit modes list it for
  *new* drinks. Rendered label is composed at display time:
  `"\(descriptor) · \(unitSystem.formatVolume(volumeMl))"`.
- Create screen (`DrinkDetailInputView`): show only region-native
  entries; bind selection to `volumeMl` (a `Double`), not to the array
  index, so a unit switch re-resolves the selection by ml.
- Edit screen (`EditEventView`): same region filter, **but** always
  inject the event's exact stored volume as a pre-selected option (shown
  converted, never snapped); guard `save()` so it only overwrites
  `event.volumeMl` when the user actually changed the volume selection.
- Display-site swaps: thread `profile.unitSystem` into `EventRow`
  (visible subtitle line + accessibility string) and the two input
  pickers; replace hardcoded `"%.0f ml"` / `"millilitres"` with the
  formatter.
- Custom preset volume generation: oz-step rows in oz modes.
- Onboarding default: auto-pick `unitSystem` from
  `Locale.current.measurementSystem`, user-overridable.
- Tests: 100% on the formatter/conversions, ≥90% on changed view-model
  logic, plus a regression test pinning the edit corruption guard and the
  ml↔oz↔ml round-trip drift bound.

### Out

- **No SwiftData migration** (no stored property changes shape).
- **Export/import file format** — stays ml, untouched.
- **Calorie / grams / BAC math, guideline limits, risk %** — untouched;
  all derive from canonical `volumeMl` × physical density.
- **`alcoholUnit`** (grams / standard drinks) and its guideline-keyed
  density — untouched; orthogonal to volume unit.
- The guideline ↔ unitSystem coupling: they stay independent.
- Australian-vs-EU metric disambiguation (see Known subtleties) — out of
  scope, pre-existing limitation.
- Price/currency display — untouched.

## Design

### Governing principle (state this and hold to it)

**Volume is a continuous quantity; ml is canonical. Curated serving
lists are quick-pick shortcuts, never a constraint on stored values. A
stored volume is never rewritten because the visible grid changed.**

### Master list + region tag + per-unit number

Replace the current `DrinkTypePreset.VolumeOption` (which has a `label`
with the number baked into the string, e.g. `"Pint UK · 568 ml"`) with:

```swift
struct VolumeOption: Hashable {
    let descriptor: String        // "Pint UK", "Can", "Bottle" — NO number
    let volumeMl: Double          // canonical, exact
    let regions: Set<UnitSystem>  // which unit modes list it for NEW drinks
}
// rendered label = "\(descriptor) · \(unitSystem.formatVolume(volumeMl))"
```

**Forward-compatibility intent.** This shape
(`descriptor` + `volumeMl` + `regions: Set<UnitSystem>`) is chosen so it
maps cleanly onto a future SwiftData model with the same fields, with no
redesign — see Future direction. The formatter staying pure on
`(ml, unitSystem)` is part of the same intent: it formats any canonical
ml regardless of whether the volume came from a built-in preset or a
future user-created record.

The category volume arrays in `DrinkTypePreset+FermentedPresets.swift`
and `DrinkTypePreset+SpiritPresets.swift` become the single superset
(union of all regions). Because the existing volumes are
already clean across units, region-tagging the existing master list plus
a formatter does the bulk of the work — far less churn than triplicate
tables.

**Region-tag policy (resolved design rule).** Each `VolumeOption` is
tagged to the unit system(s) where its number is a **natural round
serving in that unit, nothing weaker**:

- `.metric` → round ml (330, 500, 750…).
- `.usCustomary` → round US fl oz (355 ml = 12 oz, 473 ml = 16 oz,
  44 ml = 1.5 oz shot…).
- `.imperial` → round imperial fl oz / pints (568 = 20, 284 = 10…).

Multi-tag **only** where a value is genuinely round in 2+ systems — this
is rare, because metric ml almost never lands clean in oz. No "kind of
works" / "the number rounds cleanly" tagging.

**Coverage invariant.** Every category MUST yield ≥1 entry in all three
unit modes. Where US/imperial native servings are missing from a category
(e.g. the spirits shot), **add the native entry to the master list** so
the filtered list is never empty. The default selection per
(category × unitSystem) must be an entry tagged to that unit. This is
pinned by a required test (see Tests) asserting that for every
(category × unitSystem) the filtered list is non-empty **and** its
default is a tagged entry.

### Formatter (Domain layer — 100% test coverage)

A new `UnitSystem` extension exposing:

- `func formatVolume(_ ml: Double) -> String` — renders the canonical ml
  in the active unit (e.g. `"500 ml"`, `"16.9 fl oz"`).
- `var volumeUnitLabel: String` — short unit label (`"ml"` / `"fl oz"`).
- ml↔oz constants (`mlPerUSFluidOunce = 29.5735`,
  `mlPerImperialFluidOunce = 28.4131`).

Rounding (see Open decisions): metric → whole ml; oz → 1 decimal place.
All user-facing strings via `String(localized:)`.

**Where volume formatting lives (resolved).** Conversion *is* domain;
label assembly is UI. The numeric ml↔oz conversion and the rounding
policy live in the Domain layer and are recorded as domain rules in
`domain.md`. The SwiftUI label string assembly — composing
`"Can · 12 oz"` from descriptor + formatted volume — stays a UI concern
and is not a domain rule. The formatter itself stays **pure** on
`(ml, unitSystem)`: it takes a canonical ml plus the active unit system
and returns a string, holding no state and no knowledge of where the ml
came from (built-in preset today, or a future user record — see Future
direction).

### Create screen (`DrinkDetailInputView`)

- Filter to region-native entries: `volumes.filter { $0.regions.contains(currentUnit) }`.
- Change the picker selection from index-based (`@State volumeIndex: Int`)
  to ml-based (`@State volumeMl: Double`), so on a unit switch the
  selection re-resolves by ml and stays stable instead of jumping to an
  unrelated row.
- Compose labels with the formatter.

### Edit screen (`EditEventView`) — THE CENTRAL RISK

Today the edit picker is index-based and **snaps** the stored volume to
the nearest preset row at init (the closest-row loop in `init`), and
`save()` writes back the snapped row's ml. This is harmless *today*
because every stored value came from the same single metric grid —
nearest match is exact, diff is 0. **Unit-dependent grids break that
invariant.** Example: a 500 ml drink viewed in US mode (grid = 12 fl
oz / 354.88 ml, 16 fl oz / 473.18 ml, …) snaps to 473 ml; saving without
touching the volume **silently rewrites 500 → 473 ml = data corruption.**

Fixes:

1. **Inject the exact stored value.** Apply the same region filter, but
   always add the event's exact stored `volumeMl` as a pre-selected
   option even if it is off-region. Show it converted (e.g.
   `"16.9 fl oz"`), exact, never snapped to a grid row.
2. **Guard `save()`.** Only overwrite `event.volumeMl` if the user
   actually changed the volume selection; otherwise keep the original ml
   byte-for-byte. This eliminates the silent-rewrite class entirely.

### Display-site swaps

Replace the hardcoded `"%.0f ml"` / `"%.0f millilitres"` with the
formatter at every render site, threading `profile.unitSystem`:

- `EventRow` — the subtitle line and the accessibility string. (EventRow
  is the shared row used by both the History list and the calendar
  day-detail, so this single change covers both.)
- The two input pickers (`DrinkDetailInputView`, `EditEventView`).

(Note: there is no standalone event-detail screen, and Insights does not
render a raw serving volume — its only `volumeMl` use is mock-data
generation in `InsightsDataGenerator`, which is not a display site.)

### Custom preset

`DrinkTypePreset.custom` generates rows via
`stride(from: 10, through: 1000, by: 10)` ml. In oz modes, generate
oz-step rows instead (canonical ml computed from the oz step), so the
custom wheel reads in the active unit.

### Onboarding default

Auto-pick `unitSystem` at onboarding from
`Locale.current.measurementSystem` (`.metric` → `.metric`, `.us` →
`.usCustomary`, `.uk` → `.imperial`), with the user able to override.

## Risks

1. **Edit-screen silent volume rewrite (HIGHEST).** As above: an
   untouched edit must preserve `volumeMl` exactly across any unit
   switch. The two fixes (inject-exact-value + save-guard) are mandatory
   and are pinned by a regression test. Treat this as the load-bearing
   part of the plan; everything else is mechanical.
2. **Index→ml selection migration.** Both input views move from
   index-based to ml-based picker bindings. Off-by-one or stale-index
   bugs on unit/category switch are the likely defects — covered by
   re-resolve-by-ml logic and tests.
3. **Round-trip drift.** ml→oz→ml is lossy in floating point. The
   formatter must never feed a *displayed, re-parsed* oz value back into
   storage; storage always keeps the canonical ml. A test pins the drift
   bound.
4. **Region-tag gaps (mitigated, not open).** A category whose superset
   had no entry tagged for some unit mode would show an empty picker. The
   region-tag policy resolves this via the **coverage invariant**: every
   category yields ≥1 entry in all three modes (native servings added to
   the master list where missing), each (category × unitSystem) has a
   tagged default, and a required test pins it. The risk is therefore
   mitigated by design rather than left open.

## Known subtleties (note, do not fix here)

`UnitSystem` has only three cases (`.metric` / `.usCustomary` /
`.imperial`). Australian servings (e.g. schooner 425 ml, pot 285 ml) fall
under `.metric`, so AU-named entries appear in metric mode for everyone —
AU cannot be distinguished from EU metric. This is pre-existing and not
made worse by this plan. Out of scope to fix.

## Out of scope

See Scope → Out. Restated for emphasis: no migration, no export/import
format change, no calorie/grams/BAC/guideline/risk math change, no
`alcoholUnit` change, no guideline↔unitSystem coupling.

### Future direction (out of scope for 0030)

Planned **later**, not in this plan: user-created **custom volume
presets** stored in SwiftData, each tied to a `UnitSystem` +
`DrinkCategory`, and custom preset (drink type) **names**. Explicitly out
of scope here. Plan-0030 must stay forward-compatible with it:

- The volume formatter stays **pure** on `(ml, unitSystem)`, so it works
  regardless of whether the volume came from a built-in preset or a future
  user record.
- `VolumeOption` (`descriptor` + `volumeMl` + `regions: Set<UnitSystem>`)
  maps cleanly onto a future SwiftData model with the same fields — no
  redesign needed later.
- The "what units a fully-custom preset should use" question is a
  0030-independent design problem and is **deferred**.

## Open decisions

- [ ] **Oz display precision.** Propose 1 decimal place
      (e.g. `"16.9 fl oz"`); metric rounded to whole ml. Alternative:
      0 decimals for whole-oz presets, 1 for the rest. (Decide before
      writing the formatter tests.)
- [ ] **Onboarding default source.** Propose
      `Locale.current.measurementSystem`, user-overridable. Confirm the
      `.uk` → `.imperial` mapping is desired (UK volume servings are
      pints/imperial fl oz, but the UK alcohol *unit* is its own thing —
      these are independent and that is intended).
- [x] **Region tagging policy — RESOLVED** (see Design → Region-tag
      policy). Each value is tagged where it is a natural round serving in
      that unit (round ml for metric, round US fl oz for US, round
      imperial fl oz / pints for imperial); multi-tag only where genuinely
      round in 2+ systems (rare). No tagging on "the number rounds
      cleanly" alone. The empty-picker case is closed by the coverage
      invariant: every (category × unitSystem) yields ≥1 entry with a
      tagged default, adding native servings to the master list where
      missing, pinned by a required test.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Domain/UserProfile.swift` (or a new `UnitSystem+Volume.swift`) | Modify / Create — `formatVolume`, `volumeUnitLabel`, ml↔oz constants on `UnitSystem` |
| `drinkpulse/Features/AddDrink/DrinkTypePreset.swift` | Modify — change `VolumeOption` to `descriptor` + `volumeMl` + `regions`; helpers to filter by region and resolve by ml |
| `drinkpulse/Features/AddDrink/DrinkTypePreset+FermentedPresets.swift` | Modify — drop baked-in numbers, add region tags; oz-step `custom` generation (the `custom` preset is defined here) |
| `drinkpulse/Features/AddDrink/DrinkTypePreset+SpiritPresets.swift` | Modify — drop baked-in numbers, add region tags |
| `drinkpulse/Features/AddDrink/DrinkDetailInputView.swift` | Modify — region filter, ml-based selection, formatter labels |
| `drinkpulse/Features/History/EditEventView.swift` | Modify — inject exact stored volume, ml-based selection, `save()` guard, formatter labels |
| `drinkpulse/Features/History/Components/EventRow.swift` | Modify — formatter in subtitle + accessibility string |
| Onboarding view (Features/Onboarding) | Modify — default `unitSystem` from locale |
| `drinkpulse/Localizable.xcstrings` (localization) | Modify — `unit.flOz` / volume-format strings |
| `drinkpulseTests/...` | Create / Modify — formatter, conversion, selection, and edit-guard tests |

> Note: `EditEventView.swift` lives under `Features/History/`, not
> `Features/AddDrink/`. The two input views (Add and Edit) live in
> different feature folders but share the picker shape.

## Implementation steps

1. Add the `UnitSystem` volume formatter + ml↔oz constants in Domain,
   with full unit tests (do this first; it is the dependency for
   everything else).
2. Reshape `DrinkTypePreset.VolumeOption` to
   `descriptor` + `volumeMl` + `regions`; add region-filter and
   resolve-by-ml helpers. Update the two preset extension files (drop
   baked numbers, add tags). Add oz-step custom generation.
3. Migrate `DrinkDetailInputView` to region-filtered, ml-based selection
   with formatter labels.
4. Migrate `EditEventView`: inject exact stored volume, region filter,
   ml-based selection, **`save()` guard**, formatter labels. Add the
   corruption regression test.
5. Swap `EventRow` display (line + accessibility) to the formatter.
6. Onboarding locale default.
7. Update `domain.md`: record the ml↔oz conversion constants
   (1 US fl oz = 29.5735 ml; 1 imperial fl oz = 28.4131 ml) and the
   volume rounding policy as domain rules (conversion is domain; label
   string assembly is a UI concern and stays out of `domain.md`).
8. Localization strings + end-of-task checklist (build clean, coverage,
   file-size, living-docs audit — `domain.md` per step 7;
   `architecture.md` only if a new Domain file is added).

## Tests required

- **Formatter / conversions (Domain, 100%):** ml→metric label; ml→US fl
  oz; ml→imperial fl oz; boundary/zero volume; the documented clean
  anchors (355 ml = 12.0 US fl oz, 473 ml = 16.0 US fl oz, 568 ml = 20.0
  imperial fl oz, 284 ml = 10.0 imperial fl oz); rounding rule.
- **Round-trip drift:** ml→oz→ml stays within the pinned bound, and
  storage never adopts the re-parsed value.
- **Region filtering & resolve-by-ml:** create-screen filter returns only
  native entries; unit switch re-resolves selection by ml (no index
  jump).
- **Coverage invariant (required):** for every (category × unitSystem)
  the filtered list is non-empty **and** the default selection is an entry
  tagged to that unit.
- **Edit corruption guard (regression):** an event with `volumeMl = 500`
  opened in `.usCustomary`, with no volume interaction, saved → stored
  `volumeMl` is still exactly 500. Inverse: an explicit volume change is
  persisted.
- **Onboarding default:** locale → `unitSystem` mapping for metric / US /
  UK locales; override is honored.

## Sizing

**Medium.** ~6–8 files. The bulk is mechanical: a formatter, region tags
on existing volumes, and display-site swaps. The genuinely careful part
is the edit-integrity sub-area (inject exact value + save guard), which
is small in code but high in consequence and must be test-pinned.
