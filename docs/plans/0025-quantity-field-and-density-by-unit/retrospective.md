# Retrospective — plan-0025

**Completed**: 2026-06-15 (Opus 4.8, single session)
**Status**: completed

## What shipped

Both linked corrections landed exactly as scoped:

- **Part A — `quantity` (×N) as a real field.** `ConsumptionEvent.quantity: Int = 1`
  (additive, lightweight migration). `volumeMl` is the single portion again; mass =
  `volumeMl × quantity × abv × density`. Add/Edit save `(volumeMl, quantity)` instead
  of folding; the Edit reverse-engineering loop is gone. `displayName` resolves the
  unambiguous single-portion preset and appends "×N". `DrinkControlImporter` maps
  `NumberOfDrinks → quantity` (the original folding bug). Export round-trips quantity
  with backward-compatible decoding.
- **Part B — density by display unit + rounding removed.** `AlcoholUnit.densityGramsPerMl`
  (0.789 / 0.8 / 0.789); a single `physicalDensityGramsPerMl` for calories/BAC.
  Aggregation sums mode-mass; percentages/risk are exact; the 2026-06-14
  display-rounding layer is deleted. UK unit 8.0 g / weekly 112; US standard-drink
  label gained "(US)".

ADR-0005 records the canonical-rule change. CLAUDE.md § Calculations and
`docs/domain.md` updated.

## What went well

- The plan was a genuinely self-contained handoff — every calculation constant was
  pre-resolved and hand-verified, so execution was mechanical with no mid-flight
  calculation questions.
- Removing the rounding layer net-simplified the code: exact `fraction`/`riskLevel`
  helpers replaced five `display*` members plus `AlcoholUnit.displayValue`.

## Surprises / deviations

- **Test fallout from the default unit.** The app's default `alcoholUnit` is `.units`
  (0.8), but the legacy VM tests build events whose *physical* grams equal a target
  and assert exact sums. Under mode density those drifted ~1.4%. Resolved by pinning
  those tests to a grams-mode profile (density 0.789 = the helper's basis) and adding
  separate units-mode end-to-end tests. This was more test churn than the plan
  implied, but it improved coverage (grams-mode regression + units-mode behaviour are
  now both explicit).
- **Export was not in the plan's Files table** but is clearly part of "add quantity
  done right" — added `quantity` to `ExportRecord` (optional decode → 1) and the
  content signature.
- **Env gotcha:** `xcodebuild test -derivedDataPath build/` fails CodeSign inside the
  iCloud-synced repo (`com.apple.FinderInfo` detritus on the `.xctest`); use the
  default DerivedData location.

## Open question decisions made

- **quantity display** → "×N" in `displayName` (not a separate chip).
- **quantity bounds / migration default** → picker 1…10 (unchanged), `Int = 1`
  default confirmed lightweight; store opened against existing data without a wipe.
- The optional lossy JSON backfill (plan step 6) was **skipped** — data-correction
  path (b) is manual in-app, so it was unnecessary.

## Follow-ups

- **User action:** correct the four already-folded events by hand (table in `plan.md`
  / `execution.md`). Grams are unchanged; only label/count/per-portion volume.
- The SwiftData `SchemaMigrationPlan` (existing open question) is still required before
  App Store submission; `quantity` is additive-defaulted so it's migration-friendly,
  but it does not on its own resolve that question.
