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

## 2026-11-23 — Task 2: shared serving section and Pure Alcohol row

Docs (Xcode MCP `DocumentationSearch`):
- `PickerStyle.wheel` ("scrollable wheel that shows the selected option and a few neighboring
  options"), `PickerStyle.navigationLink` (Picker docs, Choosing from a set of options).
- `ContentTransition.numericText(value:)`: "the difference between the old and new values …
  will be used to determine the animation direction"; `contentTransition(_:)` "only has an
  effect within the context of an Animation" — hence `.animation(_:value:)` on the row, `nil`
  under Reduce Motion.
- `ScaledMetric`, `LabeledContent`, `accessibilityReduceMotion`: existing app usage, unchanged
  API.

Done:
- `DrinkServingOptions` (`volumeOptions(for:in:keeping:)`, `abvValues(for:stepPermille:)`,
  `nearest(_:in:)`).
- `DrinkServingSection`: wheels at regular sizes, `.navigationLink` pickers at accessibility
  sizes; header with column titles / "Serving". `PureAlcoholRow` (D0047-7).
- Tests: `DrinkServingOptionsTests` (8). RED: build failed on undefined `DrinkServingOptions`;
  GREEN 22/22 with `DrinkDetailInputMathTests`.

Deviations:
- `test_volumeOptions_keepsForeignVolume_asCurrent` uses 300 ml, not 330 ml: the 330 ml beer
  "Can" is tagged metric + imperial, so it is not foreign in imperial. 300 ml ("0.3 L") is
  metric-only.
- The "Current" option is inserted sorted by volume (plan), where Edit used to put it first.
- Render check: the "Amount" column title wrapped to two lines in the 60 pt column; the titles
  now keep one line (`fixedSize`) and may overhang. The wheel row keeps the default row insets
  (prototype) instead of the old zero insets, so the header titles sit over their wheels.
- `EditServingPickers` stays until Task 5 removes its last user (plan).

## 2026-11-23 — Task 3: Add Drink on the new list

Docs (Xcode MCP `DocumentationSearch`):
- `searchable(text:placement:prompt:)`; `SearchFieldPlacement.NavigationBarDrawerDisplayMode
  .automatic` "Enable hiding the search field in response to scrolling".
- `ContentUnavailableView.search(text:)` (overlay example in the symbol docs).
- `NavigationLink(value:label:)` / `navigationDestination(for:destination:)`: "Do not put a
  navigation destination modifier inside a 'lazy' container, like List" — the modifier sits on
  the List, outside it.
- `FetchDescriptor.fetchLimit` with `Query(_:animation:)` ("If you're displaying the fetched
  models in a SwiftUI view, use the descriptor with the Query macro").
- `ButtonRole.confirm` ("a button that confirms an operation", toolbar example), `.cancel`.
- `containerBackground(_:for:)`: through the existing `brandListBackground()`.

Done:
- `DrinkTypeListView` (step 1): Recent (`@Query` newest 50, `RecentDrinks.make`), the four
  sections (`DrinkTypeSections`, one explicit `Section` each), search, Cancel role, tint.
  Identifiers: `addDrink.type.<rawValue>`, `addDrink.recentRow`, `addDrink.section.<id>`,
  `addDrink.searchEmpty`.
- `AddDrinkRoute` / `DrinkPrefill`; `DrinkDetailInputView(preset:prefill:dismissSheet:)` with
  `DrinkServingSection`, `PureAlcoholRow`, tint, `Button(role: .confirm)` id
  `drinkForm.confirm`.
- Deleted `DrinkTypeGridView.swift` with `SheetActionsModifier`. Catalog: `addDrink.recent`,
  `addDrink.searchPrompt` added; `addDrink.alcoholUnits` removed (`XcodeGrep`: catalog only).
- **Confirm button VoiceOver label: "Done"** (system label of `ButtonRole.confirm`; now asserted
  non-empty in `test_detailStep_navigationBar_offersBackAndConfirm_withoutCancel`).
- UI tests: new `AddDrinkTypeListUITests` (5; RED 5/5 before the list existed). Updated "Save" →
  `drinkForm.confirm` and "tile/grid" wording in AddDrinkFlow, PickerFilter, VolumeServing,
  Currency, CustomNameAutocomplete, DynamicType, Dashboard, DashboardOverLimitAudit,
  ShellNavigation, HistorySwipeActions.

Deviations / findings:
- `DrinkTypeGrid` and `DrinkTypeTile` stay until Task 5: Edit's type picker still uses them.
- Search drawer: with `.automatic`, on iOS 27.2 the field rests collapsed under the large title
  and appears on a pull-down (render and UI test). The search tests pull down first. Flag for
  the owner's device check (D0047-5).
- Step 2 `onAppear` runs again when a pushed `.navigationLink` picker pops (accessibility
  sizes); defaults are now applied on the first appearance only, so they never overwrite a
  choice or a prefill.
- Regression found and fixed: `CurrencyUITests.test_settingsCurrency_becomesAddDefault` failed
  (control read USD, profile GBP). Bisect: green at `65eefb4`; red with the new step 1 even with
  the old step 2. Instrumented: the profile and `priceCurrency` were GBP at step 2, but the
  price row's control still reported USD — the currency was seeded after the row's first
  render. Fix: the price currency is derived (`chosenCurrency ?? profile currency`), never
  seeded, so the first render is right.
- Open for Task 6: `AddDrinkDynamicTypeUITests.test_addDrinkStep1_atAX5_hasNoClippedOrFixedSizeText`
  reports `textClipped` / `dynamicType` on `none#type=nil` (pages 1–2), the same signature as
  the open Today AX5 finding.

Runs: Step 5 batch 39/42, then the three fixed: Currency 2/2, `showsCategories` (lazy list,
now scrolls), AX5 step 1 Beer check (now scrolls back up); AX5 step 1 audit left for Task 6.
