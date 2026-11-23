# 0047 — Execution journal

Append-only. Dated entries.

## 2026-11-23 — Setup

- Plan frozen (`f199eab`). Owner answers recorded at freeze: D0047-9 as in the prototype (Log
  Again logs the saved drink and discards unsaved edits); D0047-10 in scope (Log Again writes to
  Apple Health). D0047-3 confirmed on the Task 1 render (below).
- Branch `port/0047-add-edit-drink`, main checkout, Xcode MCP workspace `drinkpulse.xcodeproj`
  (identifier resolved with `XcodeListWorkspaces`), destination iPhone 18 Pro simulator (iOS
  27.2).
- Executor: superpowers `executing-plans`, inline.
- Reading source uses read-only shell `cat` / `grep`; builds, tests and previews go through Xcode
  MCP. `Localizable.xcstrings` values are set with a small JSON script that keeps Xcode's format
  (round trip checked byte-identical before the first edit), as in plan 0046.

## 2026-11-23 — Task 1: type groups, search and Recent

Docs (Xcode MCP `DocumentationSearch`):
- `localizedStandardContains(_:)` (Foundation, `NSString` / `StringProtocol`): "case and
  diacritic insensitive, locale-aware search". Basis for D0047-5 matching.
- HIG Lists and tables › Best practices: "Prefer displaying text in a list or table"; a table
  that lists options "highlights a row only briefly before adding an image — such as a
  checkmark" (used again for the Edit type list in Task 5).
- `String(localized:)`: existing project pattern, catalog keys `addDrink.section.*`.

Done:
- `DrinkTypeGroup` (four groups per D0047-1, `presets(matching:)`, `pickerCategory(for:)`).
- `RecentDrink` / `RecentDrinks.make(from:limit:)`: newest distinct by category, volume, ABV and
  trimmed, case-insensitive custom name; blank names become nil.
- `.brandy` renamed "Brandy & Cognac". Emoji: Whiskey 🥃, Brandy & Cognac 🍇, Spirits 🍶,
  Shot ⚡️ (Vodka 🍸, Tequila 🌵, Liqueur 🫗 unchanged). **Owner accepted the set on the
  rendered Spirits section (2026-11-23).** Only new events store the new icons.
- Tests: `DrinkTypeGroupTests` (10), `RecentDrinksTests` (8). RED: build failed on undefined
  `RecentDrinks` / `DrinkTypeGroup`; GREEN: 44/44 with `DrinkTypePresetTests`.
- Extra tests beyond the brief: `test_groups_titles`, `test_make_blankCustomName_isNil`,
  `test_make_distinguishesVolumeAndABV`, `test_make_ids_areDistinct` (coverage of the id and
  trim branches).
