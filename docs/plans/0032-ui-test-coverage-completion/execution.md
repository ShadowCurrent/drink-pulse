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
