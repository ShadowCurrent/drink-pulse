# 0047 — Port step 7: Add / Edit Drink

**Status**: in-progress
**Size**: large
**Created**: 2026-11-23
**Frozen**: 2026-11-23
**Programme**: [0040 — Native UI port](../0040-native-ui-port/plan.md), step 7
**Branch**: `port/0047-add-edit-drink` (from `ui-revamp` at `caf8d98`; `main` has no new commits)

> Execution: superpowers `executing-plans`, inline, one session where possible (owner workflow,
> plan 0040 "Workflow"). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Drink and Edit Drink use system components on the Frost tint. Step 1 of Add Drink
is a sectioned `List` with Recent and search instead of the tile grid. Step 2 and Edit share one
serving section with a rolling Pure Alcohol figure. Edit is pushed inside History, with Log
Again and a Delete button at the bottom. Toolbars use system roles only.

**Architecture:** Views change in place. The persistence rule stays: views query with `@Query`
and mutate through `modelContext` (ADR-0004). New logic is pure and tested: type groups and
search (`DrinkTypeGroup`), Recent drinks (`RecentDrinks`), serving options
(`DrinkServingOptions`). Log Again and Delete of an existing event move into one shared helper
(`EventActions`), used by the History row actions and by Edit. No Domain calculation change. No
persistence change. No schema change.

**Tech stack:** SwiftUI `List` / `Form`, `Section`, `NavigationLink(value:)`,
`navigationDestination(for:destination:)`, `searchable(text:placement:prompt:)` with
`.navigationBarDrawer(displayMode: .automatic)`, `ContentUnavailableView.search(text:)`,
`Picker` `.wheel` / `.navigationLink`, `@ScaledMetric`, `LabeledContent`,
`contentTransition(.numericText(value:))`, `Button(role: .cancel / .confirm / .destructive)`,
`confirmationDialog(_:isPresented:titleVisibility:actions:message:)`, `@Query` with
`FetchDescriptor.fetchLimit`; Swift Testing; XCUITest.

**Spec:** plan 0040 ("Decisions carried into the port": UI structure, wheel pickers, Visual
design, History row actions; step 7; "Accessibility audit policy"). Prototype
`~/Developer/drinkpulse-native-proto/DrinkPulseNativeProto/DrinkPulseNativeProto/`:
`Shell/AddDrinkSheetSketch.swift` (step 1), `Shell/AddDrinkSheet.swift`,
`Shell/DrinkFormSections.swift` (step 2 / Edit form), `History/EditEventView.swift`. FINDINGS
"What replaced what" (Edit as sheet, `SheetActionsModifier`), "Wheel pickers", round 6 (Log
Again on Edit), round 15 (sheet tint, Pure Alcohol row, copy), round 22 (type picker). `VOICE.md`
rows `addDrink.*`, `editDrink.*`. Owner answers to the "Plan 0047 input" questions (2026-11-23).

## Summary

Add Drink step 1 is a 17-tile grid built from a custom tile control. Step 2 and Edit have two
copies of the serving wheels, and only step 2 has an accessibility-size layout. Sheet actions
move into a custom bottom bar at accessibility sizes (`SheetActionsModifier`). Edit is a sheet
with a trash popover. The prototype replaced all of these with system components, and the owner
accepted every round. This step ports them onto the app's real presets, servings, units and
Apple Health hooks. Every number the screens show stays the same.

## Context

- Port steps 2–6 are merged into `ui-revamp`. The shell already owns the Add Drink sheet, the
  `drinkLogged` haptic and `withMotion` (plan 0044). History already has Log Again and Delete row
  actions (plan 0045).
- D0045-6 kept Edit a sheet until this step. `docs/architecture.md` says so; this step changes
  it.
- **Bug found while planning:** History "Log Again" (`HistoryRowActions.logAgain`) inserts the
  copy but never calls `HealthWriteHooks.write`. The old `EventContextMenu` Duplicate had the same
  gap, because plan 0036 wired Health into Add, Edit and Delete only. With Apple Health on, a
  logged-again drink is missing from Health. Plan 0040 rule: failing test first, then the fix in
  this plan (D0047-10).
- Unchanged: `DrinkCategory`, `ConsumptionEvent` and the schema; `DrinkMassCalculator` and the
  unit densities; `HealthWriteHooks`; `CustomNameSuggestionSection` and `PriceCurrencySection`
  (they get the row tint only).

## Decisions (this plan)

Owner answers (2026-11-23) are marked **owner**. Everything else follows from plan 0040,
FINDINGS or earlier port plans, and the owner can review it in this draft.

- **D0047-1 — Step 1 is a sectioned `List` (owner, round 22).** Sections in this order:
  **Recent**, **Beer & Cider**, **Wine**, **Spirits**, **Mixed & Other**. Each section is written
  out on its own. Do not use `ForEach` over `Section`s: it crashed the List in the iOS 27.2
  preview (FINDINGS round 22). Section contents (**owner**: Alcopop and Hot Drink go to Mixed &
  Other):
  - Beer & Cider: Beer, Cider
  - Wine: Wine, Champagne, Fortified
  - Spirits: Vodka, Whiskey, Tequila, Brandy & Cognac, Spirits, Liqueur, Shot
  - Mixed & Other: Cocktail, Alcopop, Hot Drink, Custom

  A preset row shows the emoji and name only, with no serving (owner, round 22). The emoji is
  decorative (`DecorativeEmoji`). The row's accessibility label is the preset name, so
  `app.buttons["Wine"]` keeps working. Its identifier is `addDrink.type.<category rawValue>`.
  Retired: `DrinkTypeGrid`, `DrinkTypeGridView`, `DrinkTypeTile`.
- **D0047-2 — Brandy and Cognac become one row (owner).** The `.brandy` preset is renamed
  "Brandy & Cognac". `.cognac` stays in `DrinkCategory` and keeps its preset, so existing events
  still resolve through `DrinkTypePreset.preset(for:)`. It is not listed in the picker. History
  names come from the serving or the custom name (`ConsumptionEvent.displayName`), not from the
  preset name, so history rows do not change. In Edit's type list, an event with category
  `.cognac` shows the Brandy & Cognac row as selected
  (`DrinkTypeGroup.pickerCategory(for: .cognac) == .brandy`). Tapping that already-selected row
  changes nothing: the category stays `.cognac` and the serving is not reset. Search for
  "cognac" finds the row by its name.
- **D0047-3 — Separate emoji for the 🥃 rows (owner: "different emoji for the rest").**
  Proposal: Whiskey 🥃, Brandy & Cognac 🍇, Spirits 🍶, Shot ⚡️. Vodka 🍸, Tequila 🌵 and
  Liqueur 🫗 stay. The owner confirms the set on the Task 1 render before the commit. This
  changes only the `icon` that new events store; past events keep theirs. Custom SF Symbols for
  drinks stay a later question (plan 0040, open).
- **D0047-4 — Recent (owner: 3 rows).** Source: the 50 newest events (`@Query`,
  `consumptionDate` descending, `fetchLimit` 50). Rows are distinct by category, volume, ABV and
  trimmed custom name (case-insensitive), with the newest first and at most 3.
  - Title: the custom name, or else the preset name.
  - Subtitle: `volume · strength`, formatted in the profile's unit system. At accessibility
    sizes volume and strength go on two lines, with no-break spaces inside each value
    (round 22).
  - The section is hidden when there are no events and while a search is active.
  - Tapping a row opens step 2 prefilled with the volume (kept even if it is not one of the
    preset's servings), the ABV (snapped to the strength grid) and the custom name. Count is 1,
    the date is now, and notes and price are empty: Recent repeats the drink, not the occasion.
  - No schema change.
- **D0047-5 — Search (owner: `.automatic`).**
  `.searchable(text:placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search
  Drinks")`. The drawer hides on scroll (SwiftUI docs: "Enable hiding the search field in
  response to scrolling"). Search matches preset names with `localizedStandardContains`, and
  empty sections disappear. If nothing matches, the list shows
  `ContentUnavailableView.search(text:)`.
- **D0047-6 — System toolbar roles; `SheetActionsModifier` is removed.** Toolbars:
  - Step 1: `Button(role: .cancel)`.
  - Step 2: system Back plus `Button(role: .confirm)`.
  - Edit (pushed): system Back plus `Button(role: .confirm)`.

  Both confirm buttons carry the identifier `drinkForm.confirm`. At accessibility sizes, bar
  buttons rely on the system Large Content Viewer, as in the round 21 policy. The audit exempts
  them by identifier in `AccessibilityAuditBarControls.swift`. Sources: `ButtonRole.confirm` ("a
  button that confirms an operation", toolbar example) and `ToolbarItemPlacement.confirmationAction`
  ("in iOS … same location as primaryAction"). If the `.confirm` button's accessibility label
  turns out to be empty or unstable, UI tests look it up by identifier only. Task 3 records the
  label it actually has.
- **D0047-7 — Pure Alcohol row (round 15).** One `LabeledContent("Pure Alcohol")` row. Its value
  is `alcoholUnit.formattedValue(previewMassGrams, guideline:)` followed by `unitLabel(for:)`,
  e.g. "1.4 std" or "19.7 g". It uses rounded SF and `monospacedDigit`, and
  `.contentTransition(.numericText(value: previewMassGrams))` rolls the figure. Under Reduce
  Motion there is no animation. The mass math and the densities do not change (display only).
  This replaces the row labelled by the unit name. `addDrink.alcoholUnits` is unused today: it is
  deleted if `XcodeGrep` confirms no reader.
- **D0047-8 — Edit is pushed inside History (round 6 / FINDINGS; ends D0045-6).**
  - Rows become `NavigationLink(value: event)` with
    `.navigationDestination(for: ConsumptionEvent.self)` on History's stack. This works in list,
    search and calendar modes. The Button label-colour workaround goes.
  - The title stays "Edit Drink" (UI tests use it).
  - Form order: Type, Name, Serving (shared section), Date, Notes, Price, Pure Alcohol, Log Again
    (with footer), Delete Drink.
  - Delete Drink (`role: .destructive`) opens a `confirmationDialog`. Its title is "Delete this
    drink?" and its message is "This drink will be removed from your history." (VOICE.md). The
    destructive button keeps the identifier `confirmDeleteButton`. `DeleteConfirmationPopover`
    is deleted.
  - Saving or deleting pops back to History. `presentationDetents` goes.
  - Changing the type pushes `DrinkTypeSelectionView`: the sections from D0047-1 with no Recent
    and no search, and a checkmark on the current type.
- **D0047-9 — Log Again on Edit logs the saved drink (prototype).** It copies the stored event
  with `duplicated()`, then pops. Unsaved edits on the form are discarded. The section footer
  says so: "Logs the saved drink again with the current time." The shell plays the haptic
  through `drinkLogged`. Alternative if the owner prefers: disable Log Again while the form has
  unsaved changes.
- **D0047-10 — Log Again writes to Apple Health (bug fix, flagged: touches Health).**
  `EventActions.logAgain` calls `HealthWriteHooks.write(copy, …)`, as Add Drink does. Both
  History and Edit use it. The copy has no `healthKitUUID` (`duplicated()` does not carry it), so
  it gets a fresh sample. The failing UI test comes first
  (`test_healthEnabled_logAgain_writesHealthSample`).
- **D0047-11 — Copy.** Applied here:
  - `editDrink.deleteConfirm.message` → "This drink will be removed from your history."
  - New keys: `addDrink.recent` "Recent", `addDrink.section.beerCider` "Beer & Cider",
    `addDrink.section.wine` "Wine", `addDrink.section.spirits` "Spirits",
    `addDrink.section.mixed` "Mixed & Other", `addDrink.searchPrompt` "Search Drinks",
    `addDrink.pureAlcohol` "Pure Alcohol", `editDrink.logAgain.footer` "Logs the saved drink
    again with the current time.", `editDrink.delete` "Delete Drink".

  `history.row.deleteConfirm.message` is not listed in VOICE.md, so it is left for step 9.
  Preset names stay plain strings, as today. Localizing them is step 9.
- **D0047-12 — Tint.** Step 1, step 2, Edit and the type list get `brandListBackground()`, and
  their rows get `brandRowBackground()`. A sheet's own `NavigationStack` takes
  `containerBackground(for: .navigation)` (RESUME "Port notes"). The Add sheet keeps the large
  detent and the visible drag indicator.
- **D0047-13 — Tests.** Scoped runs of the changed classes only. Plan 0040 requires the full
  suite at the end of step 8, not step 7.

## Scope

### In
- Add Drink step 1 (list, Recent, search), step 2 (shared serving section, prefill, roles,
  tint), Edit (pushed, shared section, Log Again, Delete, type list), the History rows'
  navigation, the shared `EventActions` with the Health fix, the copy in D0047-11, and the audit
  and Dynamic Type classes for Add and Edit.
- `docs/architecture.md`: Navigation (Edit pushed, no sheet), AddDrink flow,
  `SheetActionsModifier` gone, `EventActions`. `docs/domain.md` only if it names the Brandy /
  Cognac presets (check with `XcodeGrep`).

### Out
- Onboarding and first run (step 8). The full copy pass and localized preset names (step 9).
- Drink SF Symbols and the app icon (plan 0040, open).
- Undo for Delete. Templates (`DrinkTemplate`) in the picker.
- Any calculation, unit or Health-service change beyond D0047-10.

## Global constraints

- **Xcode MCP for everything it covers** (main checkout, no worktree). At session start, call
  `XcodeListWorkspaces` and take the entry whose `workspacePath` ends with
  `drinkpulse.xcodeproj`. Pass its `workspaceIdentifier` on every call that accepts one. Call
  `XcodeListRunDestinations` before every test call: the target is the iPhone 18 Pro iOS 27.2
  simulator, never the physical device.
  - Build: `BuildProject`, then `GetBuildLog`. Zero warnings.
  - Tests: `RunSomeTests` with named classes, about 10 classes per call at most. Use
    `GetTestList` to confirm that new tests exist and ran. No `RunAllTests` (D0047-13).
  - Code: `XcodeRead`, `XcodeGrep`, `XcodeGlob`, `XcodeUpdate` / `XcodeWrite`, `XcodeMV`,
    `XcodeRM`, and `XcodeRefreshCodeIssuesInFile` after each edited file. Strings:
    `StringCatalogRead` / `StringCatalogEdit`. Visual: `RenderPreview` (Light, Dark, AX5).
  - **No CLI `xcodebuild` / `xcrun` without the owner's approval.**
- **Apple docs first:** run `DocumentationSearch` (API and HIG) before each API use. Record the
  query, the symbol and its availability in `execution.md`. Each task's Step 0 lists its
  lookups.
- **No calculation change.** `DrinkMassCalculator`, densities and guideline numbers stay as
  they are (AGENTS.md "Calculations").
- **No schema change.** `DrinkCategory` keeps every case, `.cognac` included. If a schema change
  appears, stop.
- Swift 6 strict concurrency, zero warnings. Files under 300 lines. Every view has previews
  (Light, Dark, AX5, plus empty Recent and search where relevant) with in-memory data.
- No PII in logs, no `print`, and no empty `catch` or `try?` without a comment. `EventActions`
  logs the error type only, as `HistoryRowActions` does today.
- Unit tests use Swift Testing in mirrored folders (`drinkpulseTests/Features/AddDrink/`,
  `drinkpulseTests/Features/History/`). UI tests go in `drinkpulseUITests/Features/AddDrink/`
  and `…/History/`. Never match system UI by a localized label (the simulator locale is
  Polish).

## Review focus

1. **Recent with a volume not in the current unit system's servings** (logged in metric, now
   imperial; or a Custom drink). Expected: step 2 shows the stored volume as the selected wheel
   row, labelled "Current", and does not jump to the nearest serving. Pinned in Task 2
   (`test_volumeOptions_keepsForeignVolume_asCurrent`) and Task 3 (`onAppear` must not overwrite
   a prefill: `test_recentRow_opensStep2_withStoredServing`).
2. **Edit a Cognac event.** Expected: the type list shows Brandy & Cognac as selected. Tapping
   it keeps `.cognac` and the serving. Pinned in Task 1 (`pickerCategory`) and Task 5 (UI test
   on a seeded Cognac event, if the seed hook supports the category; otherwise a unit test of
   `DrinkTypeSelection.apply(_:to:)`).
3. **Log Again on Edit with unsaved changes.** Expected: the stored drink is logged and the edit
   is discarded, as the footer says. Pinned in Task 5 (UI test: change the count, tap Log Again,
   and History shows the original and one copy with the stored count).
4. **Search with no match, and search when Recent exists.** Expected: the
   `ContentUnavailableView.search` view; Recent hidden; clearing the search restores everything.
   Pinned in Task 1 (`test_sections_noMatch_isEmpty`) and Task 3 (UI test).
5. **Apple Health on: Log Again from a History row and from Edit.** Expected: one new sample per
   Log Again, and deleting the copy removes only its own sample. Pinned in Task 4
   (`HealthWriteHooksUITests`).

---

### Task 1: Type groups, search and Recent (pure)

**Files:**
- Create: `drinkpulse/Features/AddDrink/DrinkTypeGroup.swift`,
  `drinkpulse/Features/AddDrink/RecentDrinks.swift`
- Modify: `DrinkTypePreset+SpiritPresets.swift` (Brandy name, emoji per D0047-3)
- Test: `drinkpulseTests/Features/AddDrink/DrinkTypeGroupTests.swift`,
  `drinkpulseTests/Features/AddDrink/RecentDrinksTests.swift`; update
  `drinkpulseTests/Domain/DrinkTypePresetTests.swift` if it pins names or icons

**Interfaces:**
- Produces:
  - `enum DrinkTypeGroup: CaseIterable { case beerCider, wine, spirits, mixed;
    var title: String; var presets: [DrinkTypePreset];
    func presets(matching query: String) -> [DrinkTypePreset];
    static func pickerCategory(for category: DrinkCategory) -> DrinkCategory }`
  - `struct RecentDrink: Hashable, Identifiable { let category: DrinkCategory; let icon: String;
    let volumeMl: Double; let abv: Double; let customName: String?; var id: String }`
  - `enum RecentDrinks { static func make(from events: [ConsumptionEvent], limit: Int = 3)
    -> [RecentDrink] }` (expects events sorted newest first)

- [ ] **Step 0: Docs** — `DocumentationSearch`: `localizedStandardContains(_:)`,
  `String(localized:)`, HIG Lists and tables.
- [ ] **Step 1: Write the failing tests**
  - `test_groups_coverEveryPickerCategory_onceEach`: the union of the four groups is every
    `DrinkCategory` except `.cognac`, with no duplicates (16 presets).
  - `test_groups_order`: the D0047-1 lists exactly, e.g. `.mixed` = cocktail, alcopop,
    hotDrink, custom.
  - `test_brandyPreset_isNamedBrandyAndCognac`.
  - `test_pickerCategory_mapsCognacToBrandy_andKeepsOthers`.
  - `test_presetsMatching_emptyQuery_returnsAll`; `test_presetsMatching_cognac_findsBrandyRow`;
    `test_presetsMatching_isCaseAndDiacriticInsensitive` ("WHISK" finds Whiskey);
    `test_sections_noMatch_isEmpty` ("zzz" leaves every group empty).
  - `test_spiritRows_haveDistinctIcons`: the icons of the Spirits group are pairwise distinct.
  - Recent: `test_make_returnsNewestDistinct_upToLimit` (5 events, 2 duplicates, gives 3 in
    newest order); `test_make_distinguishesCustomName_caseInsensitive` ("IPA" and "ipa " are one
    row, "Stout" another); `test_make_ignoresQuantity` (×1 and ×3 of the same drink are one
    row); `test_make_emptyEvents_isEmpty`; `test_make_keepsStoredVolumeAndABV`.
- [ ] **Step 2: Run** `DrinkTypeGroupTests` and `RecentDrinksTests` with `RunSomeTests`.
  Expected: FAIL (undefined).
- [ ] **Step 3: Implement.** Group titles go through `StringCatalogEdit` (D0047-11 keys).
  Render a temporary preview of the Spirits rows and show the owner the D0047-3 emoji; record
  the answer in `execution.md`.
- [ ] **Step 4: Run** the same classes plus `DrinkTypePresetTests`. Expected: PASS.
- [ ] **Step 5: Commit** `[plan-0047] type groups, search and Recent drinks`.

### Task 2: Shared serving section

**Files:**
- Create: `drinkpulse/Features/AddDrink/DrinkServingOptions.swift`,
  `drinkpulse/Features/AddDrink/Components/DrinkServingSection.swift`,
  `drinkpulse/Features/AddDrink/Components/PureAlcoholRow.swift`
- Delete: `drinkpulse/Features/History/Components/EditServingPickers.swift`
- Test: `drinkpulseTests/Features/AddDrink/DrinkServingOptionsTests.swift`

**Interfaces:**
- Produces:
  - `enum DrinkServingOptions { static func volumeOptions(for preset: DrinkTypePreset, in
    unitSystem: UnitSystem, keeping volumeMl: Double?) -> [DrinkTypePreset.VolumeOption];
    static func abvValues(for preset: DrinkTypePreset, stepPermille: Int) -> [Double];
    static func nearest(_ abv: Double, in values: [Double]) -> Double }`. The custom preset uses
    `customVolumes(for:)`. If the unit system has no servings, use all of them. A kept volume
    that is not in the list is added as `editDrink.currentServing` ("Current"), sorted by
    volume.
  - `struct DrinkServingSection: View { @Binding volumeMl: Double; @Binding abv: Double;
    @Binding count: Int; let volumeOptions: [VolumeOption]; let abvValues: [Double];
    let unitSystem: UnitSystem }`. It shows wheels with `@ScaledMetric` widths 88 / 60 and
    height 160 (the app's values). At `isAccessibilitySize` it shows `.navigationLink` pickers.
    The header has column titles (Volume / Strength / Amount) at regular sizes, and "Serving" at
    accessibility sizes (prototype).
  - `struct PureAlcoholRow: View { let grams: Double; let alcoholUnit: AlcoholUnit;
    let guideline: GuidelineChoice }` (D0047-7).

- [ ] **Step 0: Docs** — `Picker`, `WheelPickerStyle`, `PickerStyle.navigationLink`,
  `ScaledMetric`, `LabeledContent`, `ContentTransition.numericText(value:)`,
  `accessibilityReduceMotion`.
- [ ] **Step 1: Write the failing tests** —
  `test_volumeOptions_keepsForeignVolume_asCurrent` (beer, imperial, kept 330 → contains 330
  named "Current", sorted); `test_volumeOptions_knownVolume_addsNothing`;
  `test_volumeOptions_custom_usesCustomVolumes`; `test_abvValues_followStep` (wine, step 5 and
  10); `test_nearest_snapsToGrid` (0.0537 on a 0.005 grid → 0.055).
- [ ] **Step 2: Run** `DrinkServingOptionsTests`. Expected: FAIL.
- [ ] **Step 3: Implement** the helper and both views. Previews: Light, Dark, AX5, and a kept
  foreign volume. Move the `syncAbvValues` / `volumeOptions` math out of `DrinkDetailInputView`
  and `EditEventView` to the helper in Tasks 3 and 5. Delete `EditServingPickers` once nothing
  uses it (Task 5).
- [ ] **Step 4: Run** `DrinkServingOptionsTests` and `DrinkDetailInputMathTests`. Expected:
  PASS.
- [ ] **Step 5: Commit** `[plan-0047] shared serving section and Pure Alcohol row`.

### Task 3: Add Drink on the new list

**Files:**
- Create: `drinkpulse/Features/AddDrink/DrinkTypeListView.swift` (step 1),
  `drinkpulse/Features/AddDrink/AddDrinkRoute.swift`,
  `drinkpulse/Features/AddDrink/Components/DrinkTypeSections.swift`,
  `drinkpulse/Features/AddDrink/Components/RecentDrinkRow.swift`
- Modify: `AddDrinkView.swift`, `DrinkDetailInputView.swift`, `DrinkDetailInputView+Logic.swift`
- Delete: `DrinkTypeGrid.swift`, `DrinkTypeGridView.swift` (and `SheetActionsModifier` in it),
  `Components/DrinkTypeTile.swift`
- Test: create `drinkpulseUITests/Features/AddDrink/AddDrinkTypeListUITests.swift`; update the
  Add Drink UI tests that tap "Save" or rely on tiles (`XcodeGrep` `buttons["Save"]`,
  `"Add Drink grid"`, `sheetActions`). Known files: `AddDrinkFlowUITests`,
  `AddDrinkDynamicTypeUITests`, `CustomNameAutocompleteUITests`, `HealthWriteHooksUITests`,
  `DashboardUITests`, `DashboardOverLimitAccessibilityAuditUITests`, `ShellNavigationUITests`,
  `HistorySwipeActionsUITests`

**Interfaces:**
- Consumes: `DrinkTypeGroup`, `RecentDrinks` (Task 1); `DrinkServingOptions`,
  `DrinkServingSection`, `PureAlcoholRow` (Task 2).
- Produces:
  - `enum AddDrinkRoute: Hashable { case preset(DrinkCategory); case recent(RecentDrink) }`
  - `struct DrinkPrefill: Equatable { let volumeMl: Double; let abv: Double;
    let customName: String? }`
  - `DrinkDetailInputView(preset: DrinkTypePreset, prefill: DrinkPrefill? = nil,
    dismissSheet: DismissAction)`. With a prefill, `onAppear` keeps the prefilled volume, snaps
    the ABV and sets the custom name.
  - `struct DrinkTypeSections<Row: View>: View { let query: String;
    @ViewBuilder let row: (DrinkTypePreset) -> Row }`, with one explicit `Section` per group
    (D0047-1). Task 5 reuses it.

- [ ] **Step 0: Docs** — `searchable(text:placement:prompt:)`,
  `SearchFieldPlacement.NavigationBarDrawerDisplayMode.automatic`,
  `ContentUnavailableView.search(text:)`, `NavigationLink(value:label:)`,
  `navigationDestination(for:destination:)`, `Query.init(_:animation:)` with `FetchDescriptor`,
  `ButtonRole.cancel` / `.confirm`, `containerBackground(_:for:)`; HIG Sheets, Search fields.
- [ ] **Step 1: Write the failing UI tests** (`AddDrinkTypeListUITests`, `-dp_uitest` metric):
  - `test_step1_showsSections_andNoRecent_whenNoHistory`: the four section headers exist and
    "Recent" does not.
  - `test_search_cog_showsBrandyAndCognac_only`: after typing, "Brandy & Cognac" exists and
    "Beer" does not.
  - `test_search_noMatch_showsSearchEmptyState`: there are no `addDrink.type.*` buttons. Assert
    by identifier, not by system label.
  - `test_recentRow_opensStep2_withStoredServing`: log Wine with the second-largest wheel
    serving and custom name "Recent Wine", then reopen Add Drink. A "Recent Wine" row appears
    under Recent. Tapping it shows the navigation bar "Wine", the volume wheel value equal to
    the logged serving, and the name field "Recent Wine".
  - `test_recent_showsAtMostThree`: log 4 distinct drinks; 3 Recent rows.
- [ ] **Step 2: Run** `AddDrinkTypeListUITests`. Expected: FAIL.
- [ ] **Step 3: Implement** step 1:
  - `List` with Recent (`@Query` per D0047-4, `RecentDrinks.make`) and `DrinkTypeSections`.
  - Search per D0047-5, Cancel role, tint per D0047-12, title "Add Drink" `.large`.
  - Destination via `AddDrinkRoute`.

  Then step 2:
  - Form tint, `DrinkServingSection` and `PureAlcoholRow`.
  - Prefill, and the confirm role with identifier `drinkForm.confirm`.
  - Remove `sheetActions`, then delete the modifier and the grid files (`XcodeRM`).
- [ ] **Step 4: Update** the existing UI tests. Find "Save" by `drinkForm.confirm`. Rename the
  "tile" wording in messages. `AddDrinkDynamicTypeUITests` step 2: the confirm button is in the
  navigation bar, so assert it exists and is hittable instead of "inside the bottom bar".
  Record the confirm button's VoiceOver label in `execution.md` (D0047-6).
- [ ] **Step 5: Run** `AddDrinkTypeListUITests`, `AddDrinkFlowUITests`,
  `AddDrinkPickerFilterUITests`, `VolumeServingUITests`, `CurrencyUITests`,
  `CustomNameAutocompleteUITests`, `AddDrinkDynamicTypeUITests`, `DrinkDetailInputMathTests`,
  `ShellNavigationUITests`. Expected: PASS. `RenderPreview` step 1 (Light, Dark, AX5, search,
  no Recent) and step 2 (Light, AX5).
- [ ] **Step 6: Commit** `[plan-0047] Add Drink: sectioned list, Recent, search, system roles`.

### Task 4: Shared event actions; Log Again writes to Apple Health

**Files:**
- Create: `drinkpulse/Features/History/EventActions.swift`
- Modify: `drinkpulse/Features/History/Components/HistoryRowActions.swift`
- Test: `drinkpulseUITests/Features/AddDrink/HealthWriteHooksUITests.swift` (new test; split
  into `HealthWriteHooksUITests+LogAgain.swift` if the file passes 300 lines)

**Interfaces:**
- Produces: `@MainActor enum EventActions { static func logAgain(_ event: ConsumptionEvent, in
  context: ModelContext, healthService: HealthService?, reduceMotion: Bool, drinkLogged:
  DrinkLoggedAction); static func delete(_ event: ConsumptionEvent, in context: ModelContext,
  healthService: HealthService?, reduceMotion: Bool) }`. Same behaviour as
  `HistoryRowActions` today: `withMotion`, the dedup check, an explicit save, and logging the
  error type only. `logAgain` also calls `HealthWriteHooks.write(copy, in:using:)` (D0047-10).

- [ ] **Step 0: Docs** — none new (`HealthWriteHooks`, plan 0036, is app code); re-read
  `docs/architecture.md` Health section.
- [ ] **Step 1: Write the failing test** — `test_healthEnabled_logAgain_writesHealthSample`.
  Health is enabled, the probe reads "0". Log Wine: the probe reads "1". In History, swipe the
  row to Log Again (identifier `history.row.logAgain`): the probe reads "2".
- [ ] **Step 2: Run** it. Expected: FAIL (the probe stays "1").
- [ ] **Step 3: Implement** `EventActions`, and make `HistoryRowActions` call it.
- [ ] **Step 4: Run** `HealthWriteHooksUITests`, `HistorySwipeActionsUITests`,
  `WrongRowContextMenuTargetUITests`, `DuplicateEditPersistenceUITests`. Expected: PASS.
- [ ] **Step 5: Commit** `[plan-0047] Log Again writes to Apple Health (shared EventActions)`.

### Task 5: Edit Drink pushed from History

**Files:**
- Create: `drinkpulse/Features/History/Components/DrinkTypeSelectionView.swift` (replaces
  `EditDrinkTypeSelectionView.swift`), `drinkpulse/Features/History/EditEventView+Actions.swift`
  (save / log again / delete; keeps the view under 300 lines)
- Modify: `EditEventView.swift`, `HistoryView.swift`, `Components/HistoryEventRow.swift`,
  `HistoryListQueryView.swift` / `HistorySearchResultsQueryView.swift` /
  `HistoryCalendarList.swift` (remove `onEdit` plumbing)
- Delete: `Components/EditServingPickers.swift`, `Components/DeleteConfirmationPopover.swift`,
  `Components/EditDrinkTypeSelectionView.swift`
- Test: create `drinkpulseUITests/Features/History/EditDrinkPushUITests.swift`; update
  `EditDeleteConfirmationUITests`, `EditVolumeIntegrityUITests`,
  `DuplicateEditPersistenceUITests`, `HistoryInteractionUITests` (+`HitTarget`),
  `HealthWriteHooksUITests` (Edit save via `drinkForm.confirm`; "sheet" wording). Unit:
  `drinkpulseTests/Features/History/DrinkTypeSelectionTests.swift`; keep
  `EditEventVolumeGuardTests` and `EditEventDeleteTests` green

**Interfaces:**
- Consumes: `DrinkTypeSections` (Task 3), `DrinkServingSection` / `DrinkServingOptions` /
  `PureAlcoholRow` (Task 2), `EventActions` (Task 4), `DrinkTypeGroup.pickerCategory` (Task 1).
- Produces: `enum DrinkTypeSelection { static func apply(_ tapped: DrinkCategory, to current:
  DrinkCategory) -> DrinkCategory? }`. It returns nil when `pickerCategory(for: current) ==
  tapped` (no change, D0047-2), and `tapped` otherwise.

- [ ] **Step 0: Docs** — `navigationDestination(for:destination:)` with a `PersistentModel`
  value (`Hashable`), `NavigationLink(value:)` in `List`,
  `confirmationDialog(_:isPresented:titleVisibility:actions:message:)`, `ButtonRole.destructive`;
  HIG Context menus ("make context menu items available in the main interface, too").
- [ ] **Step 1: Write the failing tests**
  - Unit: `test_apply_sameRow_returnsNil`, `test_apply_cognacEvent_tapBrandy_returnsNil`,
    `test_apply_otherRow_returnsTapped`.
  - UI (`EditDrinkPushUITests`, seeded `multiday` or logged via the UI):
    `test_tapRow_pushesEditDrink_withBackButton` (navigation bar "Edit Drink" with a back button,
    History's tab bar still visible); `test_save_popsToHistory_andShowsChange`;
    `test_logAgain_logsStoredDrink_discardsEdits` (Review focus 3);
    `test_deleteDrink_confirms_thenPops` (`confirmDeleteButton`);
    `test_changeType_showsCheckmarkOnCurrent`.
- [ ] **Step 2: Run** them. Expected: FAIL.
- [ ] **Step 3: Implement** per D0047-8 / D0047-9:
  - Rows become `NavigationLink(value: event)`, with the destination on `HistoryView`'s
    `NavigationStack`.
  - Edit gets the tinted form, the shared section and `PureAlcoholRow`, plus the Log Again and
    Delete Drink sections and the `.confirm` role.
  - Delete the three files.
  - Copy keys per D0047-11.
- [ ] **Step 4: Update** the existing History / Edit UI tests: find Save by `drinkForm.confirm`,
  and dismiss with Back (`navigationBars["Edit Drink"].buttons.element(boundBy: 0)`, by
  position, never by label). Change "sheet" to "screen" in messages.
- [ ] **Step 5: Run** the new and updated classes plus `HistorySearchUITests` and the History
  calendar classes that open Edit (`XcodeGrep` "Edit Drink"). Expected: PASS. Render Edit in
  Light, Dark and AX5.
- [ ] **Step 6: Commit** `[plan-0047] Edit Drink pushed in History: shared form, Log Again,
  Delete`.

### Task 6: Audit and Dynamic Type on the new UI

**Files:**
- Modify: `AddDrinkAccessibilityAuditUITests.swift`, `AddDrinkDynamicTypeUITests.swift`,
  `AccessibilityAuditUITests.swift` (`.addDrink` screen; add `.editDrink` standard / AX5 if
  missing), `Features/Shell/AccessibilityAuditBarControls.swift` (`drinkForm.confirm`, Cancel,
  search field only if reported)

- [ ] **Step 0: Docs** — XCTest `performAccessibilityAudit(for:_:)`,
  `XCUIAccessibilityAuditType`; UIKit `UILargeContentViewerInteraction`.
- [ ] **Step 1: Run** the audit classes (standard, dark, AX5) for step 1, step 2 and Edit, plus
  `AddDrinkDynamicTypeUITests`. Record every finding in `execution.md`.
- [ ] **Step 2: Fix** content findings at the source. Exempt bar controls only, by identifier
  (round 21). The wheels and `.navigationLink` pickers get no exemption.
- [ ] **Step 3: Run** again. Expected: green. Remove the Add Drink lines from open-questions
  "Accessibility audit failures on the old UI".
- [ ] **Step 4: Commit** `[plan-0047] Add and Edit audit classes green on the native UI`.

### Task 7: Gates, docs, close

**Files:**
- Modify: `docs/architecture.md` (Navigation: Edit pushed and the `onEdit` plumbing gone;
  AddDrink flow: list, Recent, `AddDrinkRoute`, no `SheetActionsModifier`; `EventActions`;
  Health: Log Again writes), `docs/domain.md` if it names Brandy / Cognac presets, `README.md`
  if it describes the tile grid (`XcodeGrep` first), `execution.md`, `retrospective.md`,
  `INDEX.md`, `DEVLOG.md`, `current-focus.md`, `open-questions.md` (remove "Plan 0047 input")

- [ ] **Step 1: Build** with zero warnings.
- [ ] **Step 2: Scoped re-run** every class changed or added in Tasks 1–6, in batches of about
  10. Expected: green, except open-questions entries named by test (e.g. the two History edit
  tests, todo `2026-11-13-history-edit-uitests-failing.md`: check whether the pushed Edit fixes
  them and record the result).
- [ ] **Step 3: Coverage.** `DrinkTypeGroup`, `RecentDrinks`, `DrinkServingOptions` and
  `DrinkTypeSelection` need 100 %. MCP has no coverage report, so ask the owner before running
  the AGENTS.md CLI command, and record the answer.
- [ ] **Step 4: File size and privacy.** Run the AGENTS.md `find` command. Check: no new
  network, no PII in logs, no `print`.
- [ ] **Step 5: Docs close-out.** Then commit `[plan-0047] docs: close plan`.
- [ ] **Step 6: Final review.** Run one fresh superpowers reviewer over the branch (standing
  approval). Fix Critical / Important; list minors in `execution.md`.
- [ ] **Step 7:** `git switch ui-revamp && git merge --no-ff port/0047-add-edit-drink`, then ask
  the owner about push.

## Device check (owner)

- Step 1: the search drawer hides on scroll and returns on pull-down; Recent rows read well in
  Light and Dark and at AX5; the new emoji are distinguishable.
- Step 2 and Edit: the wheels scroll smoothly; the Pure Alcohol figure rolls when a wheel
  settles, and does not roll under Reduce Motion; Large Content Viewer works on the confirm
  button at AX5.
- Edit: the push and pop animation from list, search and calendar; Log Again plays the success
  or warning haptic once; Delete dialog wording.
- Apple Health on: Log Again from a row and from Edit each adds one sample in the Health app.

## Open questions

- [x] Recent row count — 3 (owner, 2026-11-23).
- [x] Brandy / Cognac / Spirits — merge Brandy and Cognac, give the rest distinct emoji (owner,
      2026-11-23).
- [x] Search — keep, `.automatic` (owner, 2026-11-23).
- [x] Alcopop and Hot Drink — Mixed & Other (owner, 2026-11-23).
- [ ] D0047-3 emoji set — owner confirms on the Task 1 render.
- [x] D0047-9 — Log Again discards unsaved edits, as in the prototype (owner, 2026-11-23).
- [x] D0047-10 — the Health fix for Log Again is in scope here (owner, 2026-11-23).

## Tests required

New: `DrinkTypeGroupTests`, `RecentDrinksTests`, `DrinkServingOptionsTests`,
`DrinkTypeSelectionTests` (Swift Testing); `AddDrinkTypeListUITests`, `EditDrinkPushUITests`,
`test_healthEnabled_logAgain_writesHealthSample`. Updated: every Add / Edit / History UI test
that tapped "Save", relied on tiles, or expected the Edit sheet or the trash popover; the Add
and Edit audit and Dynamic Type classes. Removed with their code: nothing beyond tests of
deleted views (none exist as unit tests). Gate: scoped runs only (D0047-13).
