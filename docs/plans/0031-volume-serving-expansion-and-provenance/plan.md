# 0031 — Volume serving-list expansion + volume provenance (C′)

**Status**: in-progress
**Size**: large
**Created**: 2026-06-23
**Frozen**: 2026-06-23
**Parent**: 0030

> **Subplan of [0030](../0030-volume-unit-display/).** Plan-0030's volume-unit
> feature is considered fully delivered only once 0031 lands: 0030 wired
> `unitSystem` into volume display/input and shipped, but its full volume vision
> (a realistic per-region serving inventory + stable per-event serving naming)
> continues here. 0030's `plan.md` stays frozen; this is additive scope.

## Summary

Two coupled pieces of work that finish the volume story 0030 started:

1. **Provenance (C′)** — add an optional `ConsumptionEvent.enteredUnit:
   UnitSystem?` so the displayed serving *name* is stable across unit-mode
   switches and still correctable later. Canonical `volumeMl` stays the frozen
   truth; no calculation changes. Recorded in
   [ADR-0007](../../decisions/0007-volume-provenance-entered-unit.md).
2. **Serving-list expansion (v3)** — adopt the
   [`volume-presets-proposal-2.md`](../../volume-presets-proposal-2.md) expanded
   US / imperial / metric serving inventory, with per-region display names
   (`regionNames`), pint/fraction display, cross-borrows, and an inline metric
   hint for non-round real measures.

Together these make the US and imperial serving lists realistic (currently
starved — most categories offer 1–2 oz-native servings) and make a logged
drink's serving name reflect how it was actually logged.

## Context

Plan-0030 region-tagged the existing master volume list and added a pure
`(ml, unitSystem)` formatter, but two gaps remain:

- **The US/imperial lists are too sparse** (see
  [`volume-presets-export.md`](../../volume-presets-export.md) gap summary).
  Proposal-2 expands them to market-typical servings.
- **Serving names are unstable.** 0030 re-derives the serving name from the
  *current* profile unit, so the name flips on a unit-mode switch and shifts when
  the preset table is edited. ADR-0007 fixes this with `enteredUnit`.

This plan also surfaces two **policy reversals / new domain rules** that were
implicit in proposal-2 and need the owner's sign-off (see Open decisions):
pint/fraction display formatting, and the region-tag policy reversal (tagging
non-round real measures and cross-borrows, which directly contradicts the
"natural round serving only" rule that 0030 + `domain.md` currently state).

Constraints (unchanged from 0030 / ADR-0005 / ADR-0006):

- `volumeMl` is canonical and exact. Grams/calories/guideline %/risk/BAC derive
  from it via physical density (0.789). **This plan changes none of that math.**
- Conversions: 1 US fl oz = 29.5735 ml; 1 imp fl oz = 28.4131 ml; 1 UK pint = 568 ml.
- SwiftData migration must be additive (no store wipe).

## Scope

### In

- **C′ data model:** `ConsumptionEvent.enteredUnit: UnitSystem?` (optional,
  default nil); additive migration; export/import optional key; set at log time;
  EditEventView behaviour.
- **`VolumeOption` change:** add `regionNames: [UnitSystem: String]` (defaulted),
  `name(in:)` / `label(in:)`.
- **`ConsumptionEvent.baseName` / `displayName`:** take a `UnitSystem`, resolve
  via the option's `name(in:)` using the event's `enteredUnit`.
- **New domain display logic:** pint/fraction formatting, `isRoundServing`
  predicate, inline-ml-hint composition (proposal-2) — 100% test coverage,
  hand-verified, recorded in `domain.md`. **(Gated on Open decision 1.)**
- **Serving-list expansion:** the full proposal-2 (v3) US / imperial / metric
  inventory across all categories, including cross-borrows and per-region names.
  **(Region-policy reversal gated on Open decision 2.)**
- **Reconcile `domain.md` + the preset policy comment** with the new region-tag
  policy.
- Localization for new descriptors + pint/fraction strings.
- Unit tests (rewrite the ones the expansion breaks; add new invariants) + UI
  tests for the user-facing flows.

### Out

- Any change to grams/calorie/guideline/risk/BAC math, density, or the
  canonical-ml-is-truth rule.
- `alcoholUnit`, guideline choice, currency, price display.
- User-created custom volume presets stored in SwiftData (still deferred future
  work; this plan keeps `VolumeOption` forward-compatible with it).
- Australian-vs-EU metric disambiguation (pre-existing `UnitSystem` limitation).

## Design

### 1. C′ provenance (ADR-0007)

- Add `ConsumptionEvent.enteredUnit: UnitSystem?` (optional, default nil).
- **Migration:** additive optional property → SwiftData lightweight migration, no
  store wipe. Legacy events decode `enteredUnit == nil`.
- **Export/import:** add an optional `enteredUnit` key to the event record;
  absent in older backups (decodes nil), tolerated by the importer.
- **Add flow:** at log time, set `enteredUnit = profile.unitSystem`.
- **EditEventView:** `enteredUnit` is a historical fact — it is **never edited**,
  including when the user changes other fields or the volume. (Open sub-question
  flagged below: whether an explicit *volume* change in a *different* unit mode
  should update `enteredUnit`. Default: no — preserve original provenance.)
- **Name resolution** (used by `baseName`/`displayName`): (1) if `enteredUnit`
  set and a preset matches `(category, volumeMl)` → `option.name(in: enteredUnit)`;
  (2) `enteredUnit == nil` → resolve via current profile unit; (3) no match →
  `unitSystem.formatVolume(volumeMl)`.

### 2. `VolumeOption` shape

```swift
struct VolumeOption: Hashable {
    let descriptor: String
    let volumeMl: Double
    let regions: Set<UnitSystem>
    let regionNames: [UnitSystem: String] = [:]   // NEW, defaulted
}
extension VolumeOption {
    func name(in s: UnitSystem) -> String { regionNames[s] ?? descriptor }
    func label(in s: UnitSystem) -> String { /* name + formatted volume (+ inline ml hint) */ }
}
```

- The `= [:]` default keeps the ~70 existing memberwise
  `.init(descriptor:volumeMl:regions:)` call sites compiling unchanged.
- `VolumeOption` and `UnitSystem` stay `Hashable`.

### 3. Pint / fraction display + inline metric hint (NEW domain rule)

Proposal-2 renders `½ pint / 1 pint / ⅓ / ⅔ / 2 pints` and an inline ml hint for
non-round real measures (`Small · 4.4 oz · 125 ml`). It calls `s.formatted(_:)`
and `s.isRoundServing(_:)`, **neither of which exists today** — the 0030
formatter only does whole-ml and 1-dp fl oz.

New Domain logic to add (100% covered, hand-verified, recorded in `domain.md`):

- Pint mode for imperial (and the pint fractions ⅓, ½, ⅔, 1, 2…).
- `isRoundServing(_ ml:)` predicate (lands on whole/half oz or a clean pint
  fraction) — drives whether the inline ml hint is appended.
- Inline-ml-hint composition: append `· \(Int(volumeMl.rounded())) ml` for
  non-round real-measure (M) and cross-borrow (X) rows.

**This is a new domain formatting rule and must be hand-verified by the owner and
recorded in `domain.md`. It is an OPEN decision (Open decision 1) — do not
implement until signed off.**

### 4. Region-tag policy reversal (NEW policy — needs sign-off)

`domain.md`, plan-0030, and the preset policy comment all state: tag an option to
a unit system **only where its number is a natural round serving in that unit,
nothing weaker.** Proposal-2 reverses this:

- **M-tier:** deliberately non-round real measures in the active unit (e.g. UK
  125 ml wine = 4.4 imp oz) get tagged anyway, with the inline ml hint making the
  non-round oz read as intentional.
- **X-tier (cross-borrows):** e.g. 355 ml tagged imperial (= 12.5 oz), 568 ml
  surfaced into US ("Stovepipe") and metric.

Adopting proposal-2 means **reversing the documented policy.** Reconciling
`domain.md` + the preset policy comment is in scope. **This is an OPEN decision
(Open decision 2) — do not implement the M/X tags until signed off.**

### 5. Duplicate-ml invariant

The merged-568 model — one option at 568 ml with `regions = {metric, imperial,
usCustomary}` and a `regionNames` override (`Pint` / `Stovepipe`) — avoids
same-ml collisions within a category's filtered list. Add a **new** test
asserting no two options in `volumes(for: unit)` share a `volumeMl` (per category
× unit).

### 6. Truncation fix

The inline-ml hint (and any `Int(...)` use on `volumeMl`) must use
`Int(volumeMl.rounded())`, never `Int(volumeMl)` — custom oz-wheel ml (e.g.
14.78) and non-integer historical ml (e.g. 444.5) would truncate wrongly.

### 7. Orphaned options

Proposal-2 stops offering some current options (champagne 114/118 flutes,
fortified 57/59, region-specific pours/talls, etc.). Past events stored at those
ml will fall through name resolution to `formatVolume`. Scope a pass to confirm
no past-event display regressions (the data is safe; only friendly names may
degrade — acceptable per ADR-0007, but enumerate them and confirm).

### 8. Localization

New descriptors + pint/fraction strings go through `String(localized:)`. The
**existing** descriptors are currently un-localized; the plan must **decide
localize-vs-exempt** for descriptors as a whole (consistency) and record the
choice.

## Risks

1. **Region-policy reversal contradicts shipped docs/code (HIGH).** Adopting M/X
   tags reverses the "natural round serving only" rule. Must be signed off
   (Open decision 2) and `domain.md` + the preset comment reconciled in the same
   task, or the docs lie.
2. **New pint/fraction formatting is hand-verified domain math (HIGH).** Pint
   fractions and `isRoundServing` are new domain rules; wrong output is a
   user-visible correctness bug. 100% coverage + owner hand-verification + a
   `domain.md` record are mandatory. Gated on Open decision 1.
3. **Migration must stay additive.** `enteredUnit` optional, default nil, no
   store wipe; export back-compatible.
4. **Many existing tests break (see Tests).** The expansion changes which ml are
   tagged to which unit; several 0030 assertions become false and must be
   rewritten, not deleted-and-forgotten.
5. **Truncation / float edges.** `Int(volumeMl)` truncation; ml→oz→ml drift
   (storage always keeps canonical ml).
6. **Orphaned-option name degradation.** Dropped servings degrade to
   `formatVolume`; acceptable but must be enumerated.
7. **`enteredUnit` on edit.** Deciding whether an explicit volume change updates
   `enteredUnit`; default is "never edit provenance" — pin with a test.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Domain/ConsumptionEvent.swift` | Modify — add `enteredUnit: UnitSystem?`; `baseName`/`displayName` take a `UnitSystem`, resolve via `name(in:)` + fallback chain |
| `drinkpulse/Domain/UnitSystem+Volume.swift` | Modify — pint/fraction formatting, `isRoundServing(_:)`, inline-ml-hint composition |
| `drinkpulse/Features/AddDrink/DrinkTypePreset.swift` | Modify — `VolumeOption.regionNames` (defaulted), `name(in:)`, `label(in:)` |
| `drinkpulse/Features/AddDrink/DrinkTypePreset+FermentedPresets.swift` | Modify — expanded US/imperial/metric inventory + region names |
| `drinkpulse/Features/AddDrink/DrinkTypePreset+SpiritPresets.swift` | Modify — expanded shared spirits list + region names |
| `drinkpulse/Features/AddDrink/DrinkDetailInputView.swift` | Modify — set `enteredUnit` at log time; `label(in:)` labels |
| `drinkpulse/Features/History/EditEventView.swift` | Modify — never edit `enteredUnit`; `label(in:)` labels |
| `drinkpulse/Features/History/Components/EventRow.swift` | Modify — name via `enteredUnit` resolution |
| `drinkpulse/Domain/DataTransfer/*` (event record + exporter/importer) | Modify — optional `enteredUnit` key, back-compatible |
| `drinkpulse/Localizable.xcstrings` | Modify — new descriptors + pint/fraction strings |
| `docs/domain.md` | Modify — pint/fraction rule + region-policy reconciliation |
| `drinkpulseTests/...` | Create / Modify — see Tests required (rewrite broken + new invariants) |
| `drinkpulseUITests/...` | Create — per-region names, pint display, expanded picker, provenance |
| SwiftData migration (schema/migration plan as appropriate) | Modify / Create — additive optional field |

> Note: new files in `drinkpulseTests` must be registered manually in
> `project.pbxproj` (that target is not file-system-synchronized — see 0030
> execution log).

## Implementation steps

Ordered; each step ≈ one logical commit. **Steps gated on Open decisions must not
start until those decisions are signed off.**

1. **C′ data model** — add `enteredUnit: UnitSystem?`, additive migration,
   export/import optional key. Tests for migration default + round-trip.
2. **`VolumeOption.regionNames` + `name(in:)`/`label(in:)`** (defaulted so call
   sites compile). Tests.
3. **`baseName`/`displayName` take a `UnitSystem`** and resolve via the
   `enteredUnit` fallback chain. Rewrite affected `ConsumptionEventTests`.
4. **Set `enteredUnit` at log time** (Add flow); confirm EditEventView never
   edits it. Tests.
5. *(gated on Open decision 1)* **Pint/fraction + `isRoundServing` + inline-ml
   hint** in Domain; record in `domain.md`; hand-verify. 100% tests.
6. *(gated on Open decision 2)* **Expanded serving inventory** (proposal-2 M/X
   tags, per-region names, cross-borrows); reconcile `domain.md` + preset
   comment. Rewrite the broken filter/label tests; add duplicate-ml + truncation
   tests.
7. **Display-site labels** (`EventRow`, both pickers) → `label(in:)` / resolved
   name.
8. **Localization** decision + strings.
9. **UI tests** (see below).
10. **End-of-task checklist** — build clean, coverage, file-size, living-docs
    audit (`domain.md`, `architecture.md` if a new Domain file is added),
    DEVLOG, roadmap, context files.

## Tests required

### New / changed unit tests

- **Migration:** legacy event decodes `enteredUnit == nil`; export/import
  round-trips `enteredUnit`; absent key tolerated.
- **`name(in:)` / `label(in:)`:** per-region name override (568 → "Pint" /
  "Stovepipe"); inline ml hint appended only for non-round (M/X) rows; skipped
  for round (R) rows.
- **`isRoundServing` + pint/fraction:** whole/half oz and ⅓/½/⅔/1/2 pint cases;
  hand-verified anchors.
- **Provenance resolution:** name resolved via `enteredUnit` (stable across a
  current-profile unit switch); `nil` falls back to current profile; no-match
  falls back to `formatVolume`.
- **Duplicate-ml invariant (new):** no two options in `volumes(for: unit)` share
  a `volumeMl` (per category × unit).
- **Truncation:** inline hint uses `Int(volumeMl.rounded())` (verify 14.78 →
  "15 ml", 444.5 → "445 ml" or per the chosen rule).
- **`enteredUnit` on edit:** an edit (including an explicit volume change)
  preserves the original `enteredUnit` (per the default decision).

### Existing tests that WILL break and must be rewritten

(in `drinkpulseTests` — the expansion changes which ml are tagged to which unit)

- `volumesForUnit_returnsOnlyTaggedEntries` — asserts 568 ∉ US and 355 ∉ imperial;
  proposal-2 tags **both** (Stovepipe 568 → US; Can 355 → imperial). Rewrite.
- `nearestVolumeMl_reResolvesBySelectionAcrossUnitSwitch` — 500 → 473 changes once
  500 ml is US-native ("Bottle" tagged US). Rewrite.
- `volumeOptionLabel_composesDescriptorAndUnit` — label composition now includes
  per-region name + optional inline ml hint. Rewrite.
- `ConsumptionEventTests.displayName_*` — 473 ml "US pint" → "Pint", etc.; names
  now resolve via `name(in:)` and `enteredUnit`. Rewrite.
- `EditEventVolumeGuardTests.storedVolumeInjectedExactly` — 500 ml is now US-native,
  so the "off-region injection" path for 500 in `.usCustomary` changes. Rewrite
  (the data-integrity guarantee itself must still hold).

### UI tests (mandatory per CLAUDE.md)

- Per-region serving names render in History in each unit mode.
- Pint / fraction display renders correctly in imperial.
- The expanded picker offers the expected servings in each unit mode (metric /
  US / imperial).
- **Provenance test:** a logged drink's serving name stays stable across a
  unit-mode switch (driven by `enteredUnit`, not the current profile).

## Open decisions

Both are UNRESOLVED — the owner has not yet approved them. Do not implement the
gated steps until each is checked off.

- [x] **Pint / fraction display as a new domain rule.** Proposal-2 introduces
      pint-mode + fraction rendering (½/⅓/⅔/1/2 pint) and the `isRoundServing`
      predicate + inline-ml-hint, none of which exist today (0030 does ml + 1-dp
      fl oz only). This is a new Domain formatting rule, must be hand-verified by
      the owner, and recorded in `domain.md`. **SIGNED OFF 2026-06-23** (anchors
      verified: 189→⅓, 284→½, 379→⅔, 568→1, 1136→2 pints; hint uses
      `Int(volumeMl.rounded())`).
- [x] **Region-tag policy reversal.** `domain.md` + plan-0030 + the preset policy
      comment say "tag only where a natural round serving in that unit, nothing
      weaker." Proposal-2's M-tier (non-round real measures, e.g. 125 ml = 4.4 imp
      oz) and X-tier (cross-borrows, e.g. 355 ml → imperial, 568 ml → US/metric)
      reverse that policy. Adopting it requires reconciling `domain.md` + the
      preset comment. **SIGNED OFF 2026-06-23.**

Sub-question (default chosen, confirm during execution): does an explicit
*volume* change in EditEventView update `enteredUnit`? Default: **no** —
`enteredUnit` is permanent provenance.

## Sizing

**Large.** Cross-cutting: a SwiftData migration + export/import change, a model
field, a `VolumeOption` reshape touching ~70 call sites, a whole new domain
formatting rule (pint/fractions), a full serving-inventory rewrite across the
preset files, several test rewrites + new invariants, and UI tests — plus two
domain-policy sign-offs that gate the bulk of the work.
