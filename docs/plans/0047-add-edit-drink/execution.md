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

## 2026-11-23 — Task 4: shared event actions; Log Again writes to Apple Health

Docs: none new (app code: `HealthWriteHooks`, plan 0036; `docs/architecture.md` Health section
re-read).

Done:
- `EventActions.logAgain` / `.delete` (`@MainActor enum`, `Features/History/EventActions.swift`):
  the `HistoryRowActions` bodies moved unchanged, plus `HealthWriteHooks.write(copy, …)` after
  the insert and save (D0047-10). Errors log the type only. `HistoryRowActions` calls it.
- RED: `HealthWriteHooksUITests.test_healthEnabled_logAgain_writesHealthSample` failed on
  "Log Again with Health enabled must write one more Health sample" (two rows, probe stayed 1).
  GREEN after the change.

Runs: HealthWriteHooks 5/5, HistorySwipeActions 5/5, WrongRowContextMenuTarget 2/2,
DuplicateEditPersistence 2/2, plus the Task 3-updated Dashboard classes:
- `DashboardUITests.test_loggingDrink_updatesVisibleDrinkCount` failed once in the batch
  ("got 'Drinks, 1'"), passed alone — timing in the batch; watched again in Task 7.
- `DashboardOverLimitAccessibilityAuditUITests.test_home_dark_overLimit_hasNoAuditIssues`:
  `contrast` on `today.status` (dark, over limit), twice. Same finding plan 0046 recorded and
  later saw stop recurring; the Today screen is not changed in this plan. A bisect against
  `65eefb4` could not build (partial checkout), so it is open for Task 7.

## 2026-11-23 — Task 5: Edit Drink pushed from History

Docs (Xcode MCP `DocumentationSearch`):
- `navigationDestination(for:destination:)` ("Do not put a navigation destination modifier
  inside a 'lazy' container"); `NavigationLink(value:label:)`.
- "Understanding the navigation stack" tip: "Avoid using model types as elements of a
  navigation path" — the row pushes a small `EditEventRoute`, not the `ConsumptionEvent`.
- `PersistentIdentifier.isTemporary`: "Temporary identifiers are only valid until an object is
  persisted"; `ModelContext.registeredModel(for:)`: "if known to the context; otherwise, nil".
- `confirmationDialog(_:isPresented:titleVisibility:actions:message:)`, `ButtonRole.destructive`;
  HIG Context menus: "Always make context menu items available in the main interface, too".

Done:
- History rows are `NavigationLink(value: EditEventRoute(uuid:))`; `HistoryView` registers
  `navigationDestination(for: EditEventRoute.self)` → `EditEventDestination` (live `@Query` on
  the event's `uuid`, "Drink Deleted" placeholder if it is gone). The `onEdit` plumbing is gone
  from the list, search, calendar and row views; the Button label-colour workaround with it.
- `EditEventView`: no NavigationStack / detents; tinted form; shared `DrinkServingSection` and
  `PureAlcoholRow`; Log Again (footer) and Delete Drink sections; `Button(role: .confirm)` id
  `drinkForm.confirm`; delete via `confirmationDialog`, destructive button id
  `confirmDeleteButton`. Actions in `EditEventView+Actions.swift` (save, `EventActions.logAgain`
  then pop, pop then `EventActions.delete`).
- `DrinkTypeSelection` (`apply`, `isSelected`) and `DrinkTypeSelectionView` (sections, checkmark,
  `.isSelected` trait).
- Deleted: `EditServingPickers`, `DeleteConfirmationPopover`, `EditDrinkTypeSelectionView`,
  `DrinkTypeGrid`, `DrinkTypeTile`.
- Copy: `editDrink.deleteConfirm.message` → "This drink will be removed from your history.";
  new `editDrink.logAgain.footer`, `editDrink.delete`, and `editDrink.deleted` "Drink Deleted"
  (placeholder, from the prototype; not in the D0047-11 list).
- Tests: `DrinkTypeSelectionTests` (4; RED on undefined type), `EditDrinkPushUITests` (5; RED
  5/5 on the sheet). `EditDeleteConfirmationUITests` rewritten for the pushed screen (confirm,
  dialog copy, dismiss keeps the drink); its trash-popover, capsule-pixel and Cancel-glyph
  tests went with the UI they tested. Save → `drinkForm.confirm`, "sheet" wording, type row by
  identifier in HistoryInteraction, EditVolumeIntegrity, DuplicateEditPersistence,
  HealthWriteHooks.

Deviations / findings:
- Route identity: first `persistentModelID` + `registeredModel(for:)`, then a `@Query` on
  `persistentModelID`. Both emptied the pushed screen a few seconds after opening a fresh
  event: its identifier was temporary and changed on autosave. Evidence: the UI hierarchy
  showed the form, then only the nav bar. Fix: route by the event's stable `uuid` (the LWW
  identity, deduplicated).
- Type list: a `NavigationLink` (view or value) whose destination called `dismiss()` popped to
  History on iOS 27.2. Now `navigationDestination(isPresented:)`, closed through the binding;
  the Type row is a Button with a chevron.
- Delete order: pop first, then delete, so the form never reads a deleted model.
- The delete dialog shows as a popover anchored to Delete Drink on iOS 27.2; the confirm button
  appears twice in the tree (nested), so tests use `.firstMatch` as the row-menu tests do.
- UI test scrolling: a swipe from the screen centre turns the serving wheels; the helpers drag
  from low on the screen, wait for the scroll to settle, and check frames (`isHittable` throws
  on lazy rows).
- Review focus 2 (Cognac): covered by `DrinkTypeSelectionTests` and the Cognac preview; the UI
  seed has no Cognac event.

Runs: EditDrinkPush 5/5, EditDeleteConfirmation 3/3, then DuplicateEditPersistence,
EditVolumeIntegrity, HealthWriteHooks, HistoryDynamicType, HistoryInteraction (+HitTarget,
+DirectionalTransition), HistorySearch, HistorySwipeActions, ContextMenuDeleteConfirmation,
DrinkTypeSelectionTests, EditEventVolumeGuardTests: 49/49. EditEventDeleteTests 2/2 earlier.
Renders: Edit Light / AX5, type list (Cognac → Brandy & Cognac checked).
