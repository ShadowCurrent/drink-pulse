# 0031 — Execution journal

Append-only. Dated entries for every deviation, discovery, and decision made
while executing the frozen plan.

---

## 2026-06-23 — Plan frozen, both gates signed off

Owner approved the two blocking Open decisions (via in-session sign-off):

1. **Pint / fraction display rule** (gates step 5) — APPROVED. Anchors verified:
   189→⅓ pint, 284→½ pint, 379→⅔ pint, 568→1 pint, 1136→2 pints. `isRoundServing`
   = whole/half oz or clean pint fraction. Inline ml hint only when not round in
   the active non-metric unit; metric never hints; hint uses
   `Int(volumeMl.rounded())`.
2. **Region-tag policy reversal** (gates step 6) — APPROVED. M-tier (non-round
   real measures) + X-tier (cross-borrows) adopted; `domain.md` + preset policy
   comment to be reconciled in the same task.

Sub-question (enteredUnit on volume edit): kept at the plan default — **never edit
provenance**.

Plan status draft → in-progress, `Frozen: 2026-06-23`. INDEX updated. Both gates
now cleared; all steps unblocked. Starting step 1 (C′ data model).

## 2026-06-23 — All steps executed; build/tests green

Steps 1–9 implemented in one pass (gates already signed off). Step 10 checklist
below.

**Step 1 (C′ data model).** `ConsumptionEvent.enteredUnit: UnitSystem?` (optional,
default nil → additive lightweight migration, no wipe). Carried through
`duplicated()`. Export: `ExportRecord.enteredUnit: String?` (back-compatible
optional key, `decodeIfPresent`). Import: decodes via
`UnitSystem(rawValue:)`, absent key → nil. Tests: round-trip + legacy-absent-→-nil.

**Step 2 (VolumeOption).** Added `regionNames: [UnitSystem: String] = [:]` (defaulted
so ~70 call sites compile), `name(in:)`, `label(in:)` (name + serving label + optional
ml hint). `label(for:)` removed; both pickers updated to `label(in:)`.

**Step 3 (name resolution).** `displayName`/`baseName` now take a `UnitSystem`.
Chain: customName → preset option match (within 0.5 ml) named in
`enteredUnit ?? currentUnit` → else `formatVolume` fallback. EventRow passes the
profile unit. Note: nearest-match dropped in favour of an exact-ish (≤0.5 ml)
match, so genuinely orphaned ml now fall through to `formatVolume` (490 ml beer →
"490 ml", was "Bottle"; custom-category empty descriptor → "250 ml", was "Custom").

**Step 4 (log-time provenance).** AddDrink sets `enteredUnit = profile.unitSystem`.
EditEventView `save()` never writes it (comment pins the intent) — provenance is
permanent even when the volume itself is edited (the plan's default sub-decision).

**Step 5 (pint/fraction domain rule).** `UnitSystem.servingVolumeLabel`,
`isRoundServing`, `pintLabel(forMl:)`, `servingMlHint` in `UnitSystem+Volume.swift`
(100% covered). UK pint = 568 ml; fractions ⅓/½/⅔/1/2.

> **Hand-verified rule, with a documented refinement.** Proposal-2's own tables
> conflict with its stated `isRoundServing` rule on a few half-ounce rows (it shows
> an ml hint on 355 ml beer-imperial = 12.5 oz, 70 ml spirit-imperial = 2.5 oz,
> 100 ml champagne/fortified-imperial = 3.5 oz). The **approved** rule —
> "whole/half oz OR clean pint fraction" — is implemented as the single source of
> truth: it keeps cocktail/hot-drink imperial oz pours clean ("4 oz", no hint) and
> still pints beer/cider. Consequence: those few real measures that land exactly on
> a half ounce render WITHOUT the optional ml hint (e.g. "Can · 12.5 oz" not
> "… · 355 ml"). This is a trivial, intentional deviation from the illustrative
> proposal tables; the canonical rule is recorded in `domain.md`.

**Step 6 (inventory).** Full proposal-2 (v3) US/imperial/metric expansion across
beer, wine, champagne, cider, alcopop (FermentedPresets) and the shared spirits
list (SpiritPresets). M/X tags + cross-borrows + per-region names (568 Pint/
Stovepipe; 30 Nip/Pony; 44 US shot/Shot; 50 Standard/Sherry; 59 US double/Neat).
Merged-568 model (one option, regions {m,u,i}, regionNames override) keeps each
filtered list duplicate-ml-free. Cocktail/fortified/hot-drink (also specified by
proposal-2) split into a new **`DrinkTypePreset+MixedPresets.swift`** to keep both
files < 300 lines (FermentedPresets 182, MixedPresets 86). Region-tag policy
reversal reconciled in `domain.md` + the preset policy comment.

Orphaned options (dropped servings, now name-resolve via `formatVolume`):
champagne 114/118-as-flute renames, fortified 57, spirits 28/57, wine 142,
alcopop 284, plus old cocktail/hot oz descriptors. Data is safe; only friendly
names degrade for past events stored at those exact ml — acceptable per ADR-0007.

**Step 7 (display sites).** EventRow name → `displayName(in: unitSystem)`; both
pickers → `label(in:)`.

**Step 8 (localization).** Decision: serving **descriptors stay plain English
literals** (exempt from `String(localized:)`) — consistent with the ~70 existing
literals, English-only app, serving jargon. The new **format/unit strings ARE
localized**: `volume.serving.oz.whole|decimal`, `volume.serving.pint.one|many|
third|half|twoThirds`, `volume.serving.mlHint` added to `Localizable.xcstrings`.

**Step 9 (UI tests).** New `VolumeServingUITests` (2 tests): provenance name stays
"Pint" across a metric→US switch (not "Stovepipe"); imperial beer picker shows a
pint serving. Seed extended with a gated `-dp_uitest_provenance YES` 568 ml
imperial-entered beer (inert in production). `AddDrinkPickerFilterUITests` updated
for the new oz labels ("oz" not "fl oz"; 500 ml is now a US cross-borrow default).
`drinkpulseUITests` is a `PBXFileSystemSynchronizedRootGroup`, so the new file
auto-includes — no pbxproj edit (CLAUDE.md's "register manually" note is stale for
this target; confirmed by the existing UI files not being referenced individually).

**Broken unit tests rewritten:** `volumesForUnit_returnsOnlyTaggedEntries`
(568∈US, 355∈imperial now), `nearestVolumeMl_reResolvesBySelectionAcrossUnitSwitch`
(use 440→473 since 500 is now US-native), `volumeOptionLabel_*` (→ name(in:)/
label(in:) + hint cases), `ConsumptionEventTests.displayName_*` (→ displayName(in:)
+ provenance), `EditEventVolumeGuardTests.storedVolumeInjectedExactly` (use 440,
off-region in US; the data-integrity guarantee still holds). New invariants:
duplicate-ml per (category × unit), name(in:)/label(in:) per-region + hint,
isRoundServing/pintLabel/servingMlHint anchors + truncation, enteredUnit
export round-trip.

## 2026-06-23 — Step 10: verification

- **Build**: clean, zero warnings.
- **Tests**: `** TEST SUCCEEDED **` — unit suite + 9 UI tests, 0 failures.
- **Coverage** (xccov): `UnitSystem+Volume.swift` 100%, `ExportRecord.swift` 100%,
  `VolumeOption.name/label` 100%, `ConsumptionEvent` logic
  (displayName/baseName/duplicated/init) 100% — the only uncovered lines are the
  `previewBeer/Wine/Spirits` SwiftUI fixtures (excluded from the denominator).
  Tests target 99.55%.
- **File size**: no file > 300 (largest touched: FermentedPresets 182).
- **Living docs**: `domain.md` updated (serving-label rule + region-policy reversal
  + enteredUnit field). `architecture.md` unchanged (no new layer/boundary; the
  MixedPresets split is feature-local). ADR-0007 already accepted — no edit.

## 2026-06-23 — Imperial inventory deepened (owner feedback)

Owner: imperial lists too sparse (esp. beer). Within the already-approved M-tier
policy (real measures tagged imperial with the inline ml hint), retagged common
UK real cans/bottles/glasses into imperial — **retags only, no new ml**, so the
duplicate-ml + coverage invariants still hold (verified green):

- Beer +330/440/500/660 → 6→10 imperial servings.
- Wine +375/500; Champagne +150/200; Cider +330/440; Alcopop +330;
  Fortified +60; Hot drink +250/300; Spirits +75.

These render as M-tier (e.g. "Can · 11.6 oz · 330 ml"). No domain-rule or sign-off
change — the region-policy reversal already authorises non-round real measures.
