# Execution journal — plan-0025

Append-only. The frozen `plan.md` is the contract; deviations and discoveries go here.

## 2026-06-15 — full implementation (Opus 4.8, single session)

Executed all nine implementation steps. Build clean (zero warnings), full test
suite green, no file over 300 lines.

### Steps as shipped

1. **Density source of truth.** Added `AlcoholUnit.densityGramsPerMl`
   (`.grams`/`.standardDrinks` → 0.789, `.units` → 0.8) and a single physical
   constant `AlcoholUnit.physicalDensityGramsPerMl = 0.789` (one source of truth
   for calories / future BAC). Removed `AlcoholUnit.displayValue`.
2. **Parameterized mass.** `ConsumptionEvent.alcoholGrams(density:)` =
   `volumeMl × quantity × abv × density`; `pureAlcoholGrams` now delegates to it
   at the physical density (so it counts `quantity` too).
3. **`quantity` field.** Added `var quantity: Int = 1` (defaulted → lightweight
   migration, no custom stage). Threaded through the initializer.
4. **Add/Edit stop folding.** `DrinkDetailInputView` and `EditEventView` now save
   `volumeMl = single portion`, `quantity = count`. Deleted the Edit
   reverse-engineering loop (replaced with nearest single-portion preset match).
   Both live previews use `densityGramsPerMl` instead of the old hardcoded `0.8`.
5. **displayName + EventRow.** `displayName` resolves the single-portion preset
   (now unambiguous) and appends `×N` for `quantity > 1` (decision on the open
   question: the multiplier lives in `displayName`, not a separate chip — keeps
   accessibility and the row title consistent). `EventRow` value now shows
   mode-mass (`alcoholGrams(density:)`).
6. **Importer + dedup.** `DrinkControlImporter` maps `DrinkSizeInMl → volumeMl`,
   `NumberOfDrinks → quantity` (stops folding). `DataImporter.isDuplicate` now
   also matches on `quantity` (defaulted param). The optional lossy JSON backfill
   (plan step 6 / open question) was **skipped** — data-correction path (b) is
   manual in-app, so the backfill is unnecessary.
7. **Aggregation → mode density, rounding removed.** Dashboard / Insights /
   History now sum `alcoholGrams(density: modeDensity)`. Removed
   `DashboardViewModel.displayValue/displayPct/displayRiskLevel/todayDisplayPct/
   todayDisplayRiskLevel` and `InsightsViewModel.trendDisplayFraction` + its
   private `displayValue`; percentages/risk are exact (`fraction`/`riskLevel`
   helpers), formatting happens only at the leaf. This reverts the 2026-06-14
   display-rounding edits as planned. Calories stay physical via
   `physicalGrams(_:)` = `modeMass × 0.789 / modeDensity` (kcal don't move when
   the unit toggles).
8. **Guideline consistency.** UK `gramsPerUnit` 7.89 → **8.0**, UK weekly
   110.46 → **112**; `settings.alcoholUnit.standardDrinks` label →
   "Standard drinks (US)".
9. **Docs + ADR.** ADR-0005 created; CLAUDE.md § Calculations and `docs/domain.md`
   updated; living-docs audit done.

### Deviations / decisions made during execution

- **Export round-trip (not in the Files table).** Added `quantity` to
  `ExportRecord` with a custom `init(from:)` using `decodeIfPresent ?? 1`, so v1/v2
  backup files (which predate the field and folded the count into volume) still
  decode, and new exports preserve `quantity`. Added it to
  `DataExporter.contentSignature` so editing quantity refreshes the auto-backup.
- **History density is a defaulted parameter.** `HistoryViewModel.gramsByDay` /
  `monthCells` gained `density: Double = AlcoholUnit.physicalDensityGramsPerMl`.
  The calendar view (`HistoryCalendarView`) passes the active unit's density;
  the default keeps existing tests valid.
- **Test strategy for the density split.** The default `alcoholUnit` is `.units`
  (0.8), so the legacy VM tests (which build events whose *physical* grams equal a
  target and assert exact sums) were pinned to a grams-mode profile (density
  0.789 = the helper's basis). Added a `gramsProfile(in:)` helper for the
  no-profile Dashboard tests; `InsightsViewModelTests.makeVM()` now injects a
  grams-mode profile. New units-mode end-to-end tests were added separately
  (one 500 ml 5 % beer = 2.0 units & 100 %; ×10 = 20.0 & 1000 %; grams mode
  19.7 g / 98.6 %; calories equal across units).
- **Env note (not a code issue).** Running tests with `-derivedDataPath build/`
  inside the iCloud-synced repo fails CodeSign ("…detritus not allowed", from
  `com.apple.FinderInfo`/fileprovider xattrs on the `.xctest`). Use the default
  DerivedData location for `xcodebuild test`.

### Verification

- `xcodebuild build` — clean, zero warnings.
- `xcodebuild test` — all suites green.
- Per-file coverage on changed logic: GuidelineChoice+Limits 100 %, ExportRecord
  100 %, DataExporter 100 %, DataImporter 97.8 %, DrinkControlImporter 95.9 %,
  DashboardViewModel 98.5 %, InsightsViewModel 94.3 %, HistoryViewModel 98.6 %,
  UserProfile 91.8 %. ConsumptionEvent logic fully covered; the file's residual
  gap is preview-only sample data (`previewWine`/`previewSpirits`), excluded per
  CLAUDE.md.
- No Swift file over 300 lines.

### Still to do by the user (per plan "Manual fixes after execution")

Four already-folded events must be corrected by hand in-app now that `quantity`
exists — see the table in `plan.md`. Grams are unchanged by these edits.
