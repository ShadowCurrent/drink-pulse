# 0032 — Execution Log

Append-only. Never edit or delete previous entries.

**Standing rule (owner, 2026-06-24):** if a UI test uncovers a real app bug,
fix it when small/clear; escalate to the owner with the choice when it is a
larger matter. Anything touching BAC / guidelines / sync always escalates
(CLAUDE.md). This is passed into every subagent prompt.

---

## 2026-06-24 — Step 1: Shell (ShellNavigationUITests)

### Done
- Plan frozen → in-progress; INDEX updated.
- New `drinkpulseUITests/ShellNavigationUITests.swift` (143 lines), 3 tests, all green, zero warnings:
  - `test_allFourTabs_areReachable_andSwitchContent`
  - `test_addDrinkButton_presentOnEveryTab_opensSheet`
  - `test_dismissingAddDrink_returnsToPriorTab`
- Dispatched to an Opus 4.8 subagent (sequential, per plan).

### Deviations from plan
- None.

### Discoveries
- Shell fully addressable via app-rendered English text — **no accessibility identifiers needed**. Per-tab screens set `navigationTitle == tab name`, so `navigationBars[name]` (distinct from `tabBars.buttons[name]`) proves content switched.
- Add Drink sheet Cancel lives in `DrinkTypeGridView` toolbar (`.cancellationAction` → "Cancel"); dismissal via `navigationBars["Add Drink"].buttons["Cancel"]` is locale-safe (app string).
- Reused existing hooks only (`-dp_onboarding_done`, `-dp_uitest`); no new fixtures.

### Open questions updated
- None.

## 2026-06-24 — Step 2: Dashboard (DashboardUITests)

### Done
- New `drinkpulseUITests/DashboardUITests.swift` (184 lines), 4 tests, all green (ran twice), zero warnings:
  - `test_heroCard_showsSeededConsumptionValue` (hero "Today's Intake: …" contains "2.0" + "std")
  - `test_chipRow_present_andShowsSeededDrinkCount` ("Calories:" chip + "Drinks: 1")
  - `test_overviewAndThisWeekCards_arePresent` ("Overview" / "Today:" / "This Week")
  - `test_loggingDrink_updatesVisibleDrinkCount` (log Beer → "Drinks: 1" → "Drinks: 2")

### Deviations from plan
- None.

### Discoveries
- Every Dashboard card already exposes a combined `accessibilityElement` with an explicit English label → **no a11y identifiers needed**.
- Number formatting uses `String(format: "%.1f", …)` (C-locale "." separator) + integer counts → "2.0", "std", "Drinks: N" are locale-safe.
- Save flow confirmed for step 3: `buttons["Add Drink"]` → `navigationBars["Add Drink"]` → `buttons["Beer"]` → `navigationBars["Beer"]` → `.buttons["Save"]` (action.save/"Save", action.cancel/"Cancel").

### Bugs found
- None.

### Open questions updated
- None.

## 2026-06-24 — Step 3: AddDrink (AddDrinkFlowUITests)

### Done
- New `drinkpulseUITests/AddDrinkFlowUITests.swift` (202 lines), 4 tests, all green, zero warnings:
  - `test_drinkTypeGrid_showsCategories` (Beer/Wine/Cider/Vodka/Whiskey/Cocktail tiles)
  - `test_fullLogFlow_savedEvent_appearsInHistory` (open → Wine → custom name → Save → row in History)
  - `test_quantityControl_logsMultiplePortions_showsTimesNInHistory` (amount wheel `2×` → row shows `×2`)
  - `test_customName_isRenderedInHistory`
- Existing AddDrink tests (PickerFilter, VolumeServing) confirmed not broken.

### Deviations from plan
- None.

### Discoveries
- Detail screen `Form` has 3 wheel pickers: `[0]` volume, `[1]` strength, `[2]` amount (`"1×"`…`"10×"`). Quantity via `pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue:)`.
- `displayName(in:)` appends `×N` when quantity > 1 → user-visible proof count changed, not volume.
- Custom-name field addressable via existing `accessibilityLabel("Custom Name")` → `textFields["Custom Name"]`. No a11y id needed.
- New events get `timestamp = .now` → land in History "Today".

### Bugs found
- None.

### Open questions updated
- New (carry to step 4/5): calendar prev-month navigation + Insights may need a **multi-day seed fixture**. Seed today = single beer; decide fixture shape when step 4 starts.

## 2026-06-24 — Step 4: History (HistoryInteractionUITests)

### Done
- New `drinkpulseUITests/HistoryInteractionUITests.swift` (298 lines) + `…+Helpers.swift` (87 lines), split to stay under the 300 ceiling. 7 tests, all green (3 consecutive clean full-file runs), zero warnings:
  - `test_segmentSwitch_togglesListAndCalendar`
  - `test_tapCalendarDay_revealsDayDetail`
  - `test_contextMenuDuplicate_addsEvent`
  - `test_contextMenuDelete_removesEvent`
  - `test_swipeDelete_removesEvent`
  - `test_editCustomNameAndNotes_persist` (incl. data-integrity guard: subtitle stays "500 ml")
  - `test_editCategoryChange_persists` (Beer→Wine → 150 ml wine default; old 500 ml gone — volume reset on category change is intended)
- Existing History tests (EditVolumeIntegrity, HistoryUnitDisplay) untouched.

### Deviations from plan
- None. Single-day `-dp_uitest` seed sufficed (no multi-day fixture needed for History after all).

### Discoveries
- Segmented control: `app.segmentedControls.buttons["List"|"Calendar"]`.
- Calendar today cell label is locale-formatted ("June 24, 20 g") → addressed by locale-independent " g" suffix / numeric day.
- Context-menu actions = `app.buttons["Duplicate"|"Delete"]`. Swipe-delete trash has NO a11y label (SF Symbol only) → drove it via right-edge→far-left coordinate full-swipe drag.
- Notes `TextField` (vertical axis) exposes content via `.value`, not `staticText`.
- Flakiness: a transient sim "Test crashed with signal kill" cleared via `xcrun simctl shutdown all`; recommend clean-sim start in CI.

### Bugs found
- None. Data-integrity guard held (name/notes edit preserves stored volume).

### Open questions updated
- Carry to step 5: Insights likely DOES need a gated multi-day fixture (period picker, weekday bar chart, guideline-comparison). Add `-dp_uitest_dataset multiday YES`-style additive synthetic fixture in `UITestSeed.swift` if step 5 needs it.

## 2026-06-24 — Step 5: Insights (InsightsUITests)

### Done
- New `drinkpulseUITests/InsightsUITests.swift` (234 lines), 5 tests, all green (final clean run), zero code warnings:
  - `test_periodPicker_switchesRange_changesHeroTotal` (Week → Year changes the hero Total value)
  - `test_areaChartAndWeekdayChart_arePresent` (area chart a11y label "Alcohol Over Time" + "Weekday Patterns" header)
  - `test_heroCard_showsTotalValue` ("Total" eyebrow + value carrying "std" unit token)
  - `test_healthMetrics_rowsArePresent` ("Health Impact" header + "Alcohol Calories" / "Drink-Free Days" cells)
  - `test_guidelineComparison_cardIsPresent` ("Guideline Comparison" header + a "... of limit" row)
- New gated multi-day fixture in `UITestSeed.swift` + extracted `UITestSeed+Fixtures.swift` (kept both < 300 lines).

### Multi-day fixture shape (for step 6/7 + CI reuse)
- Launch arg: `-dp_uitest_dataset multiday` (alongside `-dp_uitest YES`, `-dp_onboarding_done YES`).
- Gating: `UITestSeed.seedMultiDayFixture`; priority-ordered above provenance and the default single beer, so exactly one fixture path runs. Inert in production.
- Profile: same metric / WHO / male / 80 kg / `.standardDrinks` default as the base seed.
- 9 synthetic events (beer + wine only), each at 12:00 local of its day, relative to launch day D:
  - D−0 Beer 500 ml 5%; D−1 Wine 150 ml 12.5%; D−2 Beer 330 ml 5%; D−4 Wine 250 ml 12.5%; D−6 Beer 500 ml 5% ×2 (current week → Week view + weekday chart)
  - D−7 Beer 500 ml 5%; D−9 Wine 150 ml 12.5%; D−11 Beer 330 ml 5%; D−13 Wine 200 ml 12.5% (prior days → Month/All-Time + prev-week trend)
- Today always has data so the default Week view is never empty; drink-free gaps in between feed the streak / drink-free-day metrics. No PII.

### Deviations from plan
- None. Multi-day fixture added as anticipated.

### Discoveries
- Charts ARE addressable via their English a11y labels (no a11y identifiers needed): `AlcoholAreaChart` already sets `.accessibilityLabel("Alcohol Over Time")`; `WeekdayBarChart` exposes both a "Weekday Patterns" header and a matching a11y container. No chart-descriptor gap found — CLAUDE.md's summary requirement is already met for both charts.
- Hero "Total" eyebrow uses `.textCase(.uppercase)` (DISPLAY only) — its accessibility label stays the source string "Total", NOT "TOTAL". First test draft asserted "TOTAL" and failed; fixed the test to assert "Total". (Test-only fix; no app change.)
- Period picker = `app.segmentedControls.firstMatch` with English buttons "Week"/"Month"/"Year"/"All"; switching Week→Year changes the hero Total, proving the picker drives the data.
- Weekday/month axis labels are locale-formatted (Polish system locale) — deliberately NOT asserted; keyed off English card headers / a11y labels instead.

### Bugs found
- None. No app-code behaviour change; only additive gated seed (`UITestSeed.swift` + `UITestSeed+Fixtures.swift`).

### Open questions updated
- None. (Next: step 6 Onboarding — uses existing `-dp_force_onboarding` / locale hooks, no new fixture expected.)

## 2026-06-24 — Step 6: Onboarding (OnboardingFlowUITests)

### Done
- New `drinkpulseUITests/OnboardingFlowUITests.swift` (161 lines), 3 tests, all green, zero warnings:
  - `test_fullWalkthrough_landsOnHome` (Welcome → Profile (Female, Continue) → Guideline (Germany (DHS), Get Started) → Home/Dashboard)
  - `test_skipAllFromWelcome_reachesApp` ("Skip all setup" → app)
  - `test_profileInputs_carryIntoSettings` (sex + guideline chosen in onboarding show in Settings)
- Existing `OnboardingLocaleDefaultUITests` re-run: 2/2 still green.

### Deviations from plan
- Plan coverage table said profile inputs "(weight/sex)". **Onboarding has NO weight input** — `ProfileStep` collects only biological sex + DOB; `OnboardingViewModel.complete` persists sex/DOB/guideline/unit. Test asserts **sex** (+ guideline as a second carried value) instead of weight. Correct given the actual UI, not a bug. (Weight is edited in Settings, not onboarding.)

### Discoveries
- Sex `.menu` Picker surfaces as a button whose label CONTAINS the selected value ("Female"/"Male").
- Guideline row in onboarding = List button whose label combines name + threshold summary → match by CONTAINS, not equality. In Settings it's a plain button labelled exactly `GuidelineChoice.displayName` ("Germany (DHS)").
- Settings sex/guideline values need the form to finish laying out — assert the guideline row first (lets the ScrollView settle) to avoid a flaky first-render miss.

### Bugs found
- None.

### Open questions updated
- None. (Next: step 7 Settings — sex menu label CONTAINS value; guideline row exact `displayName`; volume-unit picker CONTAINS "Millilitres"/"fl oz".)
