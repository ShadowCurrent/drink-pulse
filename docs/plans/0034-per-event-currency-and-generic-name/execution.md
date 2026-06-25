# Execution — Plan 0034

## 2026-06-25 — implemented end to end

### Custom-name placeholder
- `editDrink.customNamePlaceholder` changed `"e.g. Tyskie IPA"` →
  `"Optional name for this drink"` (one generic placeholder, all categories;
  no prefill — owner decision).
- Removed dead `Features/History/Components/EditCustomNameSection.swift`
  (unused; its per-category `categoryDefaultName` design contradicted the
  generic-placeholder decision).

### Per-event currency
- New `Domain/Currency.swift`: `nonisolated struct CurrencyOption` (code +
  symbol) and `nonisolated enum CurrencyCatalog` (`common` 12-currency list,
  `defaultCode = "USD"`, `option(for:)`, `symbol(for:)`). Had to mark both
  `nonisolated` — the module's default actor isolation is MainActor, so a
  plain struct's stored `code` is MainActor-isolated and `map(\.code)` in
  tests failed with "Cannot form key path to main actor-isolated property".
  Matches the existing `nonisolated struct ExportRecord` pattern.
- `ConsumptionEvent.priceCurrency: String?` — additive optional field
  (lightweight SwiftData migration, same pattern as `enteredUnit`). Threaded
  through `init` and `duplicated()`.
- New shared `Features/History/Components/PriceCurrencySection.swift` — price
  TextField + a `.menu` currency picker. `accessibilityLabel` "Currency" +
  `accessibilityValue` = selected code (so the UI test reads the selection via
  the button's `.value`). Used by both Add and Edit forms (replaces the
  hardcoded `Text("USD")` in each).
- Add (`DrinkDetailInputView`): `priceCurrency` state seeded from
  `profiles.first?.currency` in `onAppear`; persisted only when a price is
  present (`parsedPrice == nil ? nil : priceCurrency`).
- Edit (`EditEventView`): state seeded from `event.priceCurrency ??`
  default, then `?? profile.currency` in `onAppear` when the event had none;
  `event.priceCurrency = parsedPrice == nil ? nil : priceCurrency` on save.
- Settings: `.menu` currency picker row added to the Preferences section,
  bound to `profile.currency`.

### Export / import
- `ExportRecord.priceCurrency: String?` — optional, back-compatible
  (`decodeIfPresent`); wired in `init(from event:)` and `DataImporter`.
- `DataExporter` content signature now hashes `priceCurrency`.

### Localization
- Added `addDrink.currency` and `settings.currency` ("Currency"). Xcode's
  string extraction also auto-added format-string entries (`"%@ · %@"`) from
  the `Text("\(code) · \(symbol)")` interpolations — expected, harmless.

### Tests
- `Domain/CurrencyTests.swift` (8 `@Test`): catalog contents/uniqueness,
  `option(for:)`/`symbol(for:)` known + unknown + nil, default in catalog.
- `DataExportImportTests`: extended `roundTrip_preservesAllFields` (PLN) +
  new `roundTrip_preservesPriceCurrency` (GBP) + new
  `import_legacyBundleWithoutPriceCurrency_defaultsToNil`.
- `ConsumptionEventTests.duplicated_copiesEveryValueField`: asserts
  `priceCurrency` copies.
- `drinkpulseUITests/Features/AddDrink/CurrencyUITests.swift` (2 tests):
  Add form defaults to profile currency + follows a menu pick to EUR;
  Settings currency change (→ GBP) becomes the Add-form default.

### Verification
- `xcodebuild build`: clean, zero warnings.
- `xcodebuild test`: `** TEST SUCCEEDED **` — full unit suite + 44 UI tests,
  0 failures. CurrencyUITests + new unit tests green.
- File-size gate: no file > 300 (EditEventView 295).

## 2026-06-25 — currency control UI iteration (owner feedback)

Owner asked for a more integrated currency control in the Add/Edit price row.
- First tried a `.wheel` picker in the price row → too tall (the wheel forces
  a ~120 pt row). Rejected.
- Final: single-line row — price `TextField` (flexes to fill) · a hairline
  vertical `Divider` (`|`) · a `.menu` `Picker` whose label shows the full
  "<code> · <symbol>" with `.fixedSize()` so the selection is never truncated
  and gets the width it needs. Added an `addDrink.price` section header
  ("Price"). The Settings currency control stays a `.menu`.
- `CurrencyUITests` reverted to the button/`.value` form (Menu surfaces as a
  button with `accessibilityLabel` "Currency" + `accessibilityValue` = code).
  Both tests green (`-only-testing:drinkpulseUITests/CurrencyUITests`).
