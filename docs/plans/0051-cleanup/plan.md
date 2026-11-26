# 0051 — Port step 11: Cleanup

**Status**: draft
**Size**: small
**Created**: 2026-11-26
**Programme**: [0040 — Native UI port](../0040-native-ui-port/plan.md), step 11
**Branch**: `port/0051-cleanup` (from `ui-revamp` at `0cfa7e6`; `main` at `c1b4bec` is already
contained in `ui-revamp`, so no merge was needed)

> Execution: superpowers `executing-plans`, inline, one session (owner workflow, plan 0040
> "Workflow"). Steps use checkbox (`- [ ]`) syntax for tracking. Nothing is deleted before this
> plan is frozen.

**Goal:** Remove the code, strings and docs that the native UI port (steps 2–10) left unused or
out of date, and close the four deferred minors from plan 0050, without changing any behaviour
the user sees.

**Architecture:** Deletion and relocation only. Every deletion below has a "0 uses" proof
collected on 2026-11-26 with `grep` over `drinkpulse/`, `drinkpulseTests/`, `drinkpulseUITests/`
and confirmed with Xcode MCP `XcodeGrep` (workspace `drinkpulse.xcodeproj`). Each task re-runs
the same search before deleting. If a search finds a use that was not there on 2026-11-26, stop
and ask. `Calendar.days(in:)` moves from `Features/Insights/` to `Domain/` unchanged. The
plan 0050 minors are a stronger test, one view-local `let`, and a doc comment.

**Tech stack:** Swift 6.4 / iOS 27.2 SDK, SwiftUI, Swift Testing, Xcode MCP (`XcodeGrep`,
`XcodeRM`, `XcodeMV`, `StringCatalogRead` / `StringCatalogEdit`, `BuildProject`,
`RunSomeTests`). No new Apple API. Before `StringCatalogEdit` is first used, read its tool
description and record it in `execution.md`.

**Spec:** plan 0040 step 11 ("delete `DPGlass.swift`, unused tokens and assets; living docs"),
owner decisions in `.claude/context/open-questions.md` "Plan 0051 input — port step 11 cleanup"
(2026-11-26), and the owner answers to this plan's questions (D0051-1 … D0051-4, 2026-11-26).

## Context

- `DPGlass.swift` (`dpGlassCard`, `DPGlassSize`) has no caller left. Steps 3, 6 and 7 removed the
  last ones.
- The asset catalog holds 8 sets, and all 8 are used:
  - `AccentColor` (`Brand.accent`, build setting `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME`)
  - `RiskLow`, `RiskModerate`, `RiskHigh` (`RiskLevel+Tone.swift`)
  - `SecondaryText` (`DPSemanticColors.swift`)
  - `DeniedText` (`DPSemanticColors.swift`)
  - `LaunchBackground`, `LaunchIcon` (`Info.plist` `UILaunchScreen`)

  So no asset is deleted.
- `Localizable.xcstrings` holds 297 keys: 283 manual and 14 auto-extracted. None is stale.
  21 manual keys appear in no source file. The dynamic lookups were checked and use none of the
  21: `settings.abvPrecision.coarse` / `.fine`, the notification and Health hint / denied pairs,
  and `settings.version.*`.
- The port left 9 members that only tests read.
- Plan 0050 deferred minors: `execution.md` "Final code review" items 1, 2, 3 and 5.
- `docs/plans/0040-native-ui-port/` has no `execution.md`, although the frozen plan says that
  progress goes there.

## Decisions (this plan)

- **D0051-1 Test-only members (owner, 2026-11-26: delete all).** Delete these members, and
  every test that only pins them:
  - `InsightsViewModel.comparisonLabel(_:)`. The gauges use `formattedNumber`.
  - `InsightsViewModel.bingeEpisodesThisMonth`, `.monthCaloriesKcal` and `.monthSpend`. These
    are aliases. Their tests are kept and retargeted to `bingeEpisodes`, `periodCaloriesKcal`
    and `periodSpend`.
  - `DashboardViewModel.todaySpend` and `DashboardViewModel.formattedSpend(_:)`. Today shows no
    spend. `formattedSpend` is the same kind of test-only member, found in the scan for this
    plan. Insights keeps its own `formattedSpend`.
  - `OnboardingViewModel.canContinueProfile`. `ProfileStep` reads `sex != nil`.
  - `DrinkTemplate.previewChampagne`, `.previewCider` and `.previewCocktail`. They have no
    callers.
- **D0051-2 Strings (owner: delete all 21).** The keys are listed in Task 3.
- **D0051-3 Secondary ink (owner: keep names, fix doc).** The `SecondaryText` / `DeniedText`
  assets, `Color.dpSecondaryText` and `Color.dpDeniedText` stay. The doc comment changes from
  "on glass cards" to the Frost tint. This closes the open question "Contrast-safe secondary
  ink for List / Form screens".
- **D0051-4 Out of scope (owner).** The following are not part of this plan:
  - Increase Contrast variants for `AccentColor` / `Risk*` (they need a device check first).
  - The `HistoryAccessibilityAuditUITests.test_historyCalendar_standard_hasNoAuditIssues`
    finding.
  - The `DashboardOverLimitAccessibilityAuditUITests.test_home_dark_overLimit_hasNoAuditIssues`
    finding.

  Their open-questions entries move from "step 11" to the `ui-revamp` → `main` checkpoint.
- **D0051-5 `heavyDayCount` contract (builder).** The fix is a doc comment, with no
  normalisation. Normalising would need a calendar in a `static` API, and the gap really sits
  in `Calendar.days(in:)`. That function steps with `date(byAdding: .day)`. Where DST skips
  midnight, every later day lands at 01:00, and Insights' grams map misses those days. That is a
  pre-existing gap in Insights totals and charts. Fixing it changes calculation results (AGENTS
  "Calculations": flag, owner hand-verifies), so it goes to open-questions as its own item and
  is not fixed here.
- **D0051-6 `Calendar+Days` location.** The file moves to `drinkpulse/Domain/Calendar+Days.swift`,
  with its content unchanged. It is Foundation only, and Today and Insights both use it. A new
  test file `drinkpulseTests/Domain/CalendarDaysTests.swift` follows the mirror rule. The
  existing `InsightsPeriodTests` count checks stay where they are.
- **D0051-7 Test scope (owner).** Tests are scoped `RunSomeTests` per task only:
  - no `RunAllTests`
  - no coverage report
  - no merge into `main`

  Plan 0051 ends with `port/0051-cleanup` merged `--no-ff` into `ui-revamp`. Pushing needs the
  owner's word.

## Scope

### In
- Delete `DPGlass.swift`, `DPColors.swift` and `DPLargeTitle.swift`.
- Delete the D0051-1 members, the D0051-2 keys and the stale doc comment.
- Move `Calendar+Days`.
- Fix the plan 0050 minors 1, 2, 3 and 5.
- Update the living docs (README, `docs/architecture.md`, `.planning/PROJECT.md`).
- Do the close-out (open-questions, `0040` `execution.md`).

### Out
- Assets: all 8 are used.
- The D0051-4 items.
- The DST-at-midnight gap in `days(in:)` (D0051-5).
- Plan 0050 minor 4 (Insights grams-cache calendar on a time-zone change) and minor 6.
- Any `@Model` or schema change.
- Any behaviour or copy change the user can see.

## Global constraints

- Before deleting anything, re-run its search in the same task. Expected result: no match
  outside the file being deleted, apart from the test or doc lines that the task also changes.
- Zero warnings in `BuildProject`. Every Swift file stays under 300 lines. No `print`. No
  logging of user data.
- Xcode MCP is always called with the `workspaceIdentifier` from `XcodeListWorkspaces` (the
  entry whose path ends with `drinkpulse/drinkpulse.xcodeproj`). Simulator: iPhone 18 Pro,
  iOS 27.2.
- Commits are `[plan-0051] …`, with no AI attribution (AGENTS.md).

## Review focus

1. **A deleted key is still shown somewhere.** `Text("…")` with a literal key would show the raw
   key. Task 3 Step 1 re-checks every key against Swift sources and `Info.plist`. Task 3 Step 4
   runs `DashboardUITests`, `InsightsUITests` and `HistorySearchUITests` on the three screens
   that owned the deleted prefixes.
2. **Today's streak tile reads a different value after the single read.** `currentStreakDays`
   is now read once per render. `DashboardAlcoholFreeUITests` and `DashboardUITests` must stay
   green (Task 5).
3. **Insights numbers change after `days(in:)` moves.** Moving the file must not change
   behaviour. `InsightsPeriodTests` and the new `CalendarDaysTests` pin it (Task 4).
4. **Retargeted alias tests lose a case.** The `monthSpend_*`, `monthCaloriesKcal_*` and
   `bingeEpisodes_*` assertions keep the same fixtures and expected values. Only the property
   name changes (Task 2).
5. **A preview breaks after deleting a token.** No preview in the app uses `dpGlassCard`,
   `dp{Teal,Amber,Red,Purple,Green}`, `dpLargeTitle` or the three templates. `BuildProject`
   compiles every `#Preview` (Task 1, Task 2).

---

### Task 1: Delete dead design-system files

**Files:**
- Delete: `drinkpulse/DesignSystem/DPGlass.swift`, `drinkpulse/DesignSystem/DPColors.swift`,
  `drinkpulse/DesignSystem/DPLargeTitle.swift`
- Modify: `drinkpulse/DesignSystem/DPSemanticColors.swift:4-6` (doc comment only)

**Evidence (2026-11-26, `grep -rnw` + `XcodeGrep`):**

| Symbol | File | Uses outside the file (app / unit / UI tests) |
|---|---|---|
| `dpGlassCard`, `DPGlassSize`, `DPGlassModifier` | `DPGlass.swift` | 0 / 0 / 0 |
| `dpTeal`, `dpAmber`, `dpRed`, `dpPurple`, `dpGreen` (the whole file) | `DPColors.swift` | 0 / 0 / 0 |
| `dpLargeTitle`, `DPLargeTitleModifier` | `DPLargeTitle.swift` | 0 / 0 / 0 |

- [ ] **Step 1:** Re-run `XcodeGrep` with
  `pattern: "dpGlassCard|DPGlass|dpTeal|dpAmber|dpRed|dpPurple|dpGreen|dpLargeTitle|DPLargeTitle"`.
  Expected: matches only inside the three files.
- [ ] **Step 2:** Delete the three files with `XcodeRM`.
- [ ] **Step 3:** Rewrite the `dpSecondaryText` doc comment. It must say: secondary text,
  section headers, hint footers and picker values on the Frost tint (List / Form screens and
  cards). It must keep the contrast reason (system grey is about 3.2–3.4:1 on the Light tint;
  the asset is 4.96:1) and the plan reference (11-17, 0043).
- [ ] **Step 4:** Run `BuildProject`. Expected: success, 0 warnings. Then run
  `RunSomeTests drinkpulseTests/DPSemanticColorsTests`. Expected: pass.
- [ ] **Step 5:** Commit `[plan-0051] delete unused glass, colour and title tokens`.

### Task 2: Delete test-only view-model members (D0051-1)

**Files:**
- Modify: `drinkpulse/Features/Insights/InsightsViewModel+Formatting.swift:28-33,43-45`,
  `drinkpulse/Features/Dashboard/DashboardViewModel.swift:64-68,175-181`,
  `drinkpulse/Features/Onboarding/OnboardingViewModel.swift:45`,
  `drinkpulse/Domain/DrinkTemplate.swift:58-61,66-73` (three preview templates)
- Tests:
  - `drinkpulseTests/Features/Insights/InsightsViewModelTests.swift:204-250`
  - `drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift:86-146,320-342`
  - `drinkpulseTests/Features/Dashboard/DashboardViewModelTests+Metrics.swift:47-80`
  - `drinkpulseTests/Features/Dashboard/DashboardViewModelTests+Formatting.swift:74-97`
  - `drinkpulseTests/Features/Onboarding/OnboardingViewModelTests.swift:32-38`
  - `drinkpulseTests/Performance/ScreenComputePerformanceTests.swift:45`

**Evidence (production reads outside the defining file):**

| Member | Prod reads | Test reads |
|---|---|---|
| `InsightsViewModel.comparisonLabel(_:)` | 0 | `InsightsViewModelTests+Aggregates` (2 tests) |
| `InsightsViewModel.bingeEpisodesThisMonth` | 0 | `InsightsViewModelTests` (5 tests) |
| `InsightsViewModel.monthCaloriesKcal` | 0 | `+Aggregates` (2 tests) |
| `InsightsViewModel.monthSpend` | 0 | `+Aggregates` (3 tests) |
| `DashboardViewModel.todaySpend` | 0 | `+Metrics` (3 tests), `ScreenComputePerformanceTests` |
| `DashboardViewModel.formattedSpend(_:)` | 0 (`HealthMetricsCard` calls the Insights one) | `+Formatting` (2 tests) |
| `OnboardingViewModel.canContinueProfile` | 0 | `OnboardingViewModelTests` (1 test) |
| `DrinkTemplate.previewChampagne` / `previewCider` / `previewCocktail` | 0 | 0 |

- [ ] **Step 1: Retarget the alias tests.** Keep the fixtures and the expected values. Change
  only the property read:
  - `bingeEpisodesThisMonth` becomes `bingeEpisodes` in the 5 `bingeEpisodes_*` tests.
  - `monthCaloriesKcal` becomes `periodCaloriesKcal`. Rename the tests
    `monthCaloriesKcal_zeroWithNoEvents` and `…_correctCalculation` to `periodCaloriesKcal_*`.
  - `monthSpend` becomes `periodSpend`. Rename the tests `monthSpend_nilWhenNoEvents`,
    `…_nilWhenNoPrices` and `…_sumsAllPricesInActivePeriod` to `periodSpend_*`.
  - Update the `// MARK:` lines to match.
- [ ] **Step 2: Delete the pinning tests**:
  - `comparisonLabel_formatsInStandardDrinks`, `comparisonLabel_formatsInGrams_whenUnitIsGrams`
    and their MARK
  - the three `todaySpend` tests (the `todaySpend (SB-6)` MARK block)
  - `formattedSpend_USD_containsAmountAndIsNonEmpty`, `formattedSpend_PLN_containsAmount` and
    their MARK
  - `@Test("canContinueProfile is false until a sex is chosen")`
  - the `_ = vm.todaySpend` line in `ScreenComputePerformanceTests`
- [ ] **Step 3:** Re-run `XcodeGrep` for
  `comparisonLabel|bingeEpisodesThisMonth|monthCaloriesKcal|monthSpend|todaySpend|canContinueProfile|previewChampagne|previewCider|previewCocktail`
  and for `formattedSpend` in `Features/Dashboard`. Expected: only the definitions are left.
- [ ] **Step 4:** Delete the members listed in D0051-1. Do not touch `InsightsViewModel.formattedSpend`.
- [ ] **Step 5:** Run `BuildProject`. Expected: 0 warnings. Then run `RunSomeTests` with
  `drinkpulseTests/InsightsViewModelTests`, `drinkpulseTests/DashboardViewModelTests`,
  `drinkpulseTests/OnboardingViewModelTests`, `drinkpulseTests/DrinkTemplateTests` and
  `drinkpulseTests/ScreenComputePerformanceTests`. Expected: all pass. The retargeted tests show
  under their new names.
- [ ] **Step 6:** Commit `[plan-0051] delete view-model members only tests read`.

### Task 3: Delete unused string-catalog keys (D0051-2)

**Files:** Modify `drinkpulse/Localizable.xcstrings`.

**Keys (21; every one is `extractionState: manual`, and none appears in any `.swift` file or in
`Info.plist`):**
- `action.save`
- `dashboard.metric.alcohol`, `dashboard.metric.calories`, `dashboard.metric.drinks`,
  `dashboard.metric.spend`
- `dashboard.ring.days7`, `dashboard.ring.days30`, `dashboard.ring.today`
- `dashboard.weeklyGoal`
- `editDrink.name`
- `history.calendar.future`, `history.calendar.soberSuffix`
- `history.search.clear`, `history.search.scope.picker`
- `insights.comingSoon.description`, `insights.comingSoon.title`
- `insights.metric.risk.high`, `insights.metric.risk.low`, `insights.metric.risk.moderate`
- `insights.section.healthMetrics`
- `tab.add`

- [ ] **Step 1:** For each key, run `grep -rnF '"<key>"' drinkpulse drinkpulseTests drinkpulseUITests --include='*.swift'`
  and also search `drinkpulse/Info.plist`. Expected: 0 matches for each key. Also confirm that
  no `String.LocalizationValue(...)` / `String(localized:)` builds one of these keys at runtime.
  On 2026-11-26 the only dynamic keys were `settings.abvPrecision.*`, the notification and
  Health hint / denied pairs, and `settings.version.*`.
- [ ] **Step 2:** Remove the 21 entries with Xcode MCP `StringCatalogEdit`. If the tool cannot
  delete keys, edit the JSON in Xcode's own format (`"key" : {`, two-space indent). In that case
  record the fallback and its reason in `execution.md`.
- [ ] **Step 3:** Check the result with `StringCatalogRead` or `python3 -I`:
  - 276 keys are left
  - none of the 21 keys is present
  - the file is still valid JSON
- [ ] **Step 4:** Run `BuildProject`. Expected: 0 warnings, and no new stale keys after the
  build. Then run `RunSomeTests` with `drinkpulseUITests/DashboardUITests`,
  `drinkpulseUITests/InsightsUITests` and `drinkpulseUITests/HistorySearchUITests`. Expected:
  pass.
- [ ] **Step 5:** Commit `[plan-0051] delete 21 unused string-catalog keys`.

### Task 4: Move `Calendar.days(in:)` to Domain (plan 0050 minor 2)

**Files:**
- Move: `drinkpulse/Features/Insights/Calendar+Days.swift` → `drinkpulse/Domain/Calendar+Days.swift`
  (content unchanged)
- Create: `drinkpulseTests/Domain/CalendarDaysTests.swift`

**Interfaces:** `extension Calendar { func days(in range: ClosedRange<Date>) -> [Date] }`. The
signature does not change. Callers: `InsightsViewModel`, `InsightsViewModel+Charts`,
`DashboardViewModel`, `InsightsPeriodTests`.

- [ ] **Step 1: Write the tests.** Use a `@MainActor struct CalendarDaysTests`, the same as
  `InsightsPeriodTests`. Fixture: `Calendar(identifier: .gregorian)` with
  `timeZone = TimeZone(identifier: "Europe/Warsaw")!`, and dates in 2026. Write these tests:
  - `days_sameDay_returnsOneStartOfDay`: range Jul 18 09:00…Jul 18 21:00 gives
    `[startOfDay(Jul 18)]`.
  - `days_spanningMonthEnd_isInclusive`: range Jul 30 15:00…Aug 2 09:00 gives 4 days. The first
    is `startOfDay(Jul 30)` and the last is `startOfDay(Aug 2)`.
  - `days_acrossSpringForward_keepsOneEntryPerDay`: range Mar 28…Mar 30 2026 gives 3 days, each
    equal to `startOfDay` of itself. Europe/Warsaw changes at 02:00, so midnight exists.
- [ ] **Step 2:** Run `RunSomeTests drinkpulseTests/CalendarDaysTests`. Expected: PASS, because
  the extension already exists in the module. These tests pin behaviour before the move.
- [ ] **Step 3:** Move the file with `XcodeMV`, or `git mv` if the folders are synchronized and
  `XcodeMV` refuses. Do not change the content.
- [ ] **Step 4:** Run `BuildProject`. Expected: 0 warnings. Then run `RunSomeTests` with
  `drinkpulseTests/CalendarDaysTests`, `drinkpulseTests/InsightsPeriodTests`,
  `drinkpulseTests/InsightsViewModelTests` and `drinkpulseTests/DashboardViewModelTests`.
  Expected: pass.
- [ ] **Step 5:** Commit `[plan-0051] move Calendar.days(in:) to Domain`.

### Task 5: Plan 0050 minors 1, 3, 5

**Files:**
- Modify: `drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift:212-219`
- Modify: `drinkpulse/Features/Dashboard/DashboardView.swift:60-73` (`streakTiles`)
- Modify: `drinkpulse/Domain/AlcoholFreeDayRule.swift:30` (doc comment only)

- [ ] **Step 1: Make the test stronger (minor 5).** Rewrite
  `longestSoberStreak_reducedWhenHasDrinkingDay`:
  - `vm.period = .month` and `vm.now = july18Noon`.
  - Events relative to `july18Noon`: `event(daysAgo: 5, grams: 0)` (Jul 13, the first log at
    0 %) and `event(daysAgo: 2, grams: 30)` (Jul 16).
  - `#expect(vm.longestSoberStreak == 3)`.

  Why 3: the counted days are Jul 13–17. Jul 13, 14 and 15 are alcohol-free, Jul 16 is a
  drinking day, and Jul 17 is alcohol-free. Today (Jul 18) has 0 g, so it does not count. The
  old pre-0050 rule would give 15. Without the Jul 16 event the answer is 5.
- [ ] **Step 2:** Run `RunSomeTests drinkpulseTests/InsightsViewModelTests`. Expected: PASS. If
  the value is not 3, stop and ask, because this is a calculation (AGENTS "Calculations").
- [ ] **Step 3: Read the streak once (minor 3).** In `streakTiles`, bind
  `let streak = vm.currentStreakDays` once. Use it for the value, the zero-state detail and
  `celebrates` (explicit `return TilePair { … }`). The copy, the identifiers and the layout do
  not change.
- [ ] **Step 4: Document the date contract (minor 1).** Add a doc comment to
  `AlcoholFreeDayRule.heavyDayCount(in:grams:)`. It says that `grams` is called with each element
  of `days` unchanged, with no normalisation, so callers pass dates keyed the same way as their
  lookup (Insights: `Calendar.days(in:)` output). It also points to the open question on
  DST-at-midnight days (D0051-5).
- [ ] **Step 5:** Run `BuildProject`. Expected: 0 warnings. Then run `RunSomeTests` with
  `drinkpulseTests/AlcoholFreeDayRuleTests`, `drinkpulseTests/DashboardViewModelTests`,
  `drinkpulseUITests/DashboardUITests` and `drinkpulseUITests/DashboardAlcoholFreeUITests`.
  Expected: pass.
- [ ] **Step 6:** Commit `[plan-0051] plan 0050 minors: exact streak test, single streak read, heavyDayCount contract`.

### Task 6: Living docs after the port

**Files:**
- `README.md:91`: replace the Dashboard `Components/` comment with the real files:
  `TodayHeroCard`, `HeroGauge`, `GuidelineLimitsCard`, `ThisWeekCard`, `GuidelineAlertCard`, ….
- `docs/architecture.md`:
  - Lines 34–37, "Design system" intro: all screens are ported. Remove "until then old screens
    keep their layout and glass…".
  - Line 179: `AppLockState` does not exist. Replace the example with a type that does, or drop
    it.
  - Lines 58–66 / 75: check that the DesignSystem test list and the shared-component list match
    `drinkpulse/DesignSystem/` after Task 1.
  - Note that `Domain/Calendar+Days.swift` is a shared day-list helper.
- `.planning/PROJECT.md`:
  - "Current State": add one paragraph on the native UI port. Steps 2–11 are done on
    `ui-revamp`, plans 0042–0051, not yet on `main`. Name the open checkpoint: full suite,
    coverage, audit classes, device pass.
  - "Context" line 394: "fully native Liquid Glass" becomes system components with glass only
    on bars and controls, per `docs/architecture.md`.
- Each file: before editing, `grep` for identifiers that no longer exist in code. Check
  backticked names against `drinkpulse/`. Fix only the stale ones; history entries stay.

- [ ] **Step 1:** Edit the three files as listed.
- [ ] **Step 2:** Re-run the identifier check over the three files. Expected: every backticked
  type, function or file name that names current code exists. Historical mentions (`SchemaV5`
  as a future name, the `ObservableObject` ban, phase history) are allowed.
- [ ] **Step 3:** Commit `[plan-0051] living docs after the native UI port`.

### Task 7: Review, close and merge into `ui-revamp`

- [ ] **Step 1:** Run the file-size check (AGENTS "File size enforcement"). Expected: no output.
  Run `grep -rn "print(" drinkpulse --include='*.swift'`. Expected: no new hits.
- [ ] **Step 2:** Final review (standing approval): one fresh reviewer subagent on the most
  capable model, using superpowers `requesting-code-review` over `ui-revamp..port/0051-cleanup`.
  Fix Critical and Important findings with TDD in one pass. Minor findings go to `execution.md`
  and the final message.
- [ ] **Step 3:** Close the docs:
  - `docs/plans/0051-cleanup/execution.md` and `retrospective.md`.
  - `docs/plans/INDEX.md`: 0051 is completed, next number 0052.
  - `docs/plans/0040-native-ui-port/execution.md`: create it if missing. Add one entry
    (2026-11-26): steps 2–11 completed as plans 0042–0050 and 0051; 0041 abandoned; 0040 stays
    `in-progress` until `ui-revamp` → `main`.
  - `docs/DEVLOG.md` entry.
  - `.planning/ROADMAP.md`, if it lists the port.
  - `.claude/context/current-focus.md`: step 11 done; next is the `ui-revamp` → `main`
    checkpoint, which is the owner's decision.
  - `.claude/context/open-questions.md`:
    - Delete "Plan 0051 input".
    - Resolve "Contrast-safe secondary ink" (D0051-3).
    - Retag the D0051-4 items to the `ui-revamp` → `main` checkpoint.
    - Add "DST-at-midnight days in `Calendar.days(in:)`" (D0051-5): affected time zones (for
      example `America/Santiago`), affected numbers (Insights totals, charts, Heavy Days), and
      that it is a calculation change the owner verifies by hand.
- [ ] **Step 4:** Commit `[plan-0051] docs: close plan`. Then run
  `git switch ui-revamp && git merge --no-ff port/0051-cleanup`, with the message
  `Merge port/0051-cleanup: plan 0051 Cleanup`.
- [ ] **Step 5:** Ask the owner whether to push `ui-revamp`. Do not push without an explicit
  "push".

## Device check (owner)

None. This plan changes nothing the user sees.
