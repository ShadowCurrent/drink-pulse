# Plan 0034 — Per-event currency + generic custom-name placeholder

Status: in-progress
Frozen: 2026-06-25
Size: medium

## Problem

Two unrelated entry-form defects:

1. **Custom-name placeholder** is hardcoded to a beer brand
   (`"e.g. Tyskie IPA"`) for *every* drink category. Logging wine or
   spirits shows a beer example.
2. **Currency** is broken end to end. `UserProfile.currency` exists
   (default `"USD"`) but has **no Settings UI**, and both the Add and Edit
   forms render a hardcoded `Text("USD")`. Price is stored on the event
   **without** the currency it was entered in, so a stored amount is
   ambiguous once the user changes their currency.

## Decisions (owner-confirmed 2026-06-25)

- **Name:** one universal, generic placeholder for all categories. Do NOT
  prefill, do NOT use the category name. (The drink's smart serving-based
  `displayName` stays the source of truth when no custom name is set.)
- **Currency list:** a short common list (~12 currencies), `.menu` pickers.
- **Price display:** entry only. No price shown in History/Insights. The
  per-event currency override lives only in the Add/Edit price row.
- **Per-event currency** defaults to the profile currency, is editable per
  event, and is **persisted with the price** (`priceCurrency`).

## Scope

### Domain
- New `Domain/Currency.swift`: pure `CurrencyOption` (code + symbol) and a
  `CurrencyCatalog.common` list. 100% unit-tested.
- `ConsumptionEvent.priceCurrency: String?` — additive optional field,
  default nil (lightweight SwiftData migration, same pattern as
  `enteredUnit`/`quantity`). Threaded through `init` and `duplicated()`.
- Naming/calculation untouched — currency never affects grams/risk/BAC.

### Export / import
- `ExportRecord.priceCurrency: String?` — optional, back-compatible
  (`decodeIfPresent`). Wire in `init(from event:)` and `DataImporter`.
- `DataExporter` content signature includes `priceCurrency` (so editing it
  invalidates the auto-backup, consistent with `price`).

### UI
- Replace hardcoded `Text("USD")` in `DrinkDetailInputView` and
  `EditEventView` with a `.menu` currency picker seeded from the profile
  currency (Edit: `event.priceCurrency ?? profile.currency`). Persist
  `priceCurrency` only when a price is present.
- `SettingsView`: currency `.menu` picker row in the Preferences section,
  bound to `profile.currency`.
- Change `editDrink.customNamePlaceholder` to a generic string.
- Remove dead `EditCustomNameSection` (unused; its per-category design
  contradicts the generic-placeholder decision).

### Tests
- `Domain/CurrencyTests` — catalog contents, symbol lookup, default.
- `ExportRecord` round-trip incl. `priceCurrency` (+ absent-key → nil).
- `ConsumptionEvent.duplicated` carries `priceCurrency`.
- UI test: Add a drink with a non-default currency override; Settings
  currency change reflected as the new default in the Add form.

### Living docs
- `domain.md` — `ConsumptionEvent` fields (priceCurrency) + currency note.
- DEVLOG, current-focus, roadmap, README features list as needed.

## Out of scope
- Showing price anywhere in the UI.
- Currency conversion / FX. Stored amounts are face values in their code.
- Full ISO 4217 list (short common list only).

## Risk
Low. Additive optional field (no destructive migration). No calculation
or guideline code touched. The only data-integrity concern — persisting a
currency that silently reinterprets an existing amount — is avoided:
currency is stored *with* the price at write time and never rewritten on a
profile-currency change.
