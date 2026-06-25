# Retrospective — Plan 0034

Status: completed (2026-06-25)

## What shipped
Two entry-form fixes:
1. Custom-name field now shows one generic placeholder for every category
   ("Optional name for this drink") instead of a hardcoded beer brand.
2. Currency is wired end to end: a Settings currency picker, a per-event
   currency override in the Add/Edit price row, and the chosen currency
   persisted **with** the price (`ConsumptionEvent.priceCurrency`) so stored
   amounts are never silently reinterpreted.

## What went well
- The additive-optional-field migration pattern (`enteredUnit`/`quantity`)
  applied cleanly to `priceCurrency` — no destructive migration, full
  export/import back-compat.
- Extracting `PriceCurrencySection` removed the duplicated price `HStack`
  from both Add and Edit in one place.

## Surprises
- Module default actor isolation is **MainActor**, so a plain value-type's
  stored property is MainActor-isolated; `map(\.code)` in a test won't form
  a key path. Fix: `nonisolated struct`/`enum` (the codebase's established
  pattern — `ExportRecord`). Worth remembering for every new Domain value type.

## Deviations from plan
None material. Followed the frozen plan; the owner decisions (generic
placeholder, short currency list, entry-only display) were all honoured.

## Follow-ups (not in scope)
- Showing price+currency anywhere (History/Insights) — deliberately omitted.
- Currency conversion / totals across currencies — out of scope; stored
  amounts are face values in their own code.
- Custom volume presets + names (pre-existing backlog) unaffected.
