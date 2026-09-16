# Phase 08 UI and UI-test inventory

**Reviewed:** 2026-09-16  
**Scope:** app entry/startup, every SwiftUI feature, design system, diagnostics,
UI/runtime resources, and every tracked UI-test source file. This is an inventory,
not an authorization to change production or test code.

## Evidence rules and reading result

- The census was generated from tracked files (`git ls-files`) in the paths named
  in 08-03-PLAN.md; source locations below are current checked-in paths and
  1-based source lines.
- Apple documentation is the authority for API behavior and availability. The
  SwiftUI expert-skill material was used only to find leads; it is not evidence
  that a replacement is beneficial.
- All candidates list a lookup date of **2026-09-16**. “No deprecation claim”
  means this review found no compiler diagnostic or official documentation that
  deprecates the current use; it is not a claim that the API cannot change later.
- 08-BASELINE.md records that Debug, Release, and the unfiltered full suite all
  stopped at app compilation (exit 65). No UI test is represented as run, green,
  failed, or skipped by this inventory.

## Production and resource reviewed-file census

Every area has a separate **no-candidate** record below, including areas that
also contain a candidate. “No candidate” means no additional modernization
candidate beyond the separately listed IDs, not that the files were omitted.

| Area | Tracked files reviewed | APIs/patterns checked | Explicit no-candidate record |
| --- | --- | --- | --- |
| App entry / startup | `drinkpulse/drinkpulseApp.swift`; `drinkpulse/UITestSeed.swift`; `drinkpulse/UITestSeed+Fixtures.swift` | `App`, `WindowGroup`, `@State`, `@AppStorage`, `task`, model-container startup, notification delegation, color scheme; UI-test launch arguments, in-memory `ModelContainer`, fixture insertion, `@MainActor` test seeding | **NC-UI-01 — no-candidate:** aside from UI-C-07’s current Observation ownership check, no official deprecation or iOS 27-specific replacement lead was found. `UITestSeed` intentionally keeps launch-only in-memory fixtures and the production migration plan; changing its startup/fixture behavior needs a demonstrated test failure, not a compiler-version rewrite. Startup/lifecycle semantics remain unchanged. |
| AddDrink | `Features/AddDrink/{AddDrinkView.swift,DrinkDetailInputView.swift,DrinkDetailInputView+Logic.swift,DrinkTypeGrid.swift,DrinkTypeGridView.swift,DrinkTypeTile.swift,DrinkTypePreset.swift,DrinkTypePreset+FermentedPresets.swift,DrinkTypePreset+MixedPresets.swift,DrinkTypePreset+SpiritPresets.swift}` | `NavigationStack`, `@Entry`, `@Environment`, forms, pickers, `ForEach`, `onChange`, localization, accessibility | **NC-UI-02 — no-candidate:** no deprecated presentation, form, picker, or localization API was found beyond UI-C-01 and UI-C-03. |
| Dashboard | `Features/Dashboard/{DashboardView.swift,DashboardView+Previews.swift,DashboardViewModel.swift,Components/ConsumptionOverviewCard.swift,Components/DPChip.swift,Components/DashboardChipRow.swift,Components/DashboardHeroCard.swift,Components/GuidelineAlertCard.swift,Components/StreakCard.swift,Components/ThisWeekCard.swift}` | `@Observable`, `@State`, `@Query`, card composition, animation, `onChange`, semantic accessibility | **NC-UI-03 — no-candidate:** the current state, animation, and accessibility patterns have no documented iOS 27 replacement lead. |
| History | `Features/History/{HistoryView.swift,HistoryViewModel.swift,HistoryListQueryView.swift,HistoryCalendarQueryView.swift,HistorySegment.swift,EditEventView.swift,Components/CustomNameSuggestionSection.swift,Components/DeleteConfirmationPopover.swift,Components/EditDrinkTypeSelectionView.swift,Components/EditNotesSection.swift,Components/EditServingPickers.swift,Components/EventContextMenu.swift,Components/EventRow.swift,Components/EventRowButton.swift,Components/EventRowStrings.swift,Components/HistoryCalendarDayCell.swift,Components/HistoryCalendarDayDetail.swift,Components/HistoryCalendarView.swift,Components/HistoryEventCardRow.swift,Components/HistoryFlatRow.swift,Components/PriceCurrencySection.swift,Components/RowUnitContext.swift}` | `List`, `ScrollView`, `@Query`, `ForEach`, `NavigationStack`, sheets, context menu, confirmation dialog, transitions, Reduce Motion, Dynamic Type, accessibility actions | **NC-UI-04 — no-candidate:** no unsupported replacement is proposed; the behavior-sensitive UI-C-03, UI-C-04, UI-C-05, and UI-C-08 retain records are the only leads. |
| Insights | `Features/Insights/{InsightsView.swift,InsightsViewModel.swift,InsightsViewModel+Charts.swift,InsightsViewModel+Formatting.swift,InsightsViewModel+HealthMetrics.swift,InsightsDataGenerator.swift,InsightsChartModels.swift,InsightsPeriod.swift,Calendar+Days.swift,Components/AlcoholAreaChart.swift,Components/AlcoholAreaChart+Accessibility.swift,Components/WeekdayBarChart.swift,Components/WeekdayBarChart+Accessibility.swift,Components/GuidelineComparisonCard.swift,Components/HealthMetricsCard.swift,Components/InsightsHeroCard.swift,Components/InsightsScopeNavigator.swift}` | `@Observable`, `@Query`, `ScrollView`, Swift Charts, selection, chart descriptors/Audio Graph, `ForEach`, animation, Reduce Motion, localized labels | **NC-UI-05 — no-candidate:** no chart replacement is recommended; UI-C-06 and UI-C-08 retain the existing accessible interaction. |
| Onboarding | `Features/Onboarding/{OnboardingView.swift,OnboardingViewModel.swift,Components/WelcomeStep.swift,Components/ProfileStep.swift,Components/GuidelineStep.swift,Components/HealthStep.swift}` | `@Observable`, `@State`, multi-step `ForEach`, animation, Reduce Motion, buttons, accessibility | **NC-UI-06 — no-candidate:** current navigation, state ownership, and accessibility have no official modernization lead. |
| Settings | `Features/Settings/{SettingsView.swift,Components/AppearanceModeRow.swift,Components/DataSection.swift,Components/GuidelineChoiceRow.swift,Components/GuidelinePickerSheet.swift,Components/HealthSection.swift,Components/ReminderSection.swift,Components/SettingsActionRow.swift,Components/SettingsRow.swift,Components/SettingsSection.swift,Components/WeeklySummarySection.swift}` | `NavigationStack`, sheets, forms, `ForEach`, `@AppStorage`, `onChange`, localization, accessibility | **NC-UI-07 — no-candidate:** no deprecated navigation, form, accessibility, or localization API was found. |
| Shell | `Features/Shell/{AppTab.swift,RootShellView.swift,StartupErrorView.swift,Components/AddDrinkButton.swift}` | `TabView`, value-based `Tab`, `NavigationStack`, sheet, sensory feedback, scene phase, notification tasks, accessibility | **NC-UI-08 — no-candidate:** the current tab/sheet/notification handoff is retained; it has no iOS 27 diagnostic or deprecation evidence. |
| Design system | `DesignSystem/{AppStorageKeys.swift,DPArcProgress.swift,DPBrand.swift,DPColors.swift,DPGlass.swift,DPLargeTitle.swift,DPSemanticColors.swift,RiskLevel+Color.swift}` | `Shape`, `animation(_:value:)`, `onChange`, `glassEffect`, color and semantic styling, accessibility | **NC-UI-09 — no-candidate:** aside from the baseline compiler diagnostic in UI-C-02 and the deliberate Liquid Glass retain record UI-C-09, no candidate was found. |
| Diagnostics | `Diagnostics/ViewLoadLogger.swift` | `OSLog`, `OSSignposter`, DEBUG gating, navigation instrumentation | **NC-UI-10 — no-candidate:** diagnostics are intentionally DEBUG-gated and have no iOS 27 UI API lead. |
| UI/runtime resources | `drinkpulse/Info.plist`; `drinkpulse/drinkpulse.entitlements`; `drinkpulse/Localizable.xcstrings`; `drinkpulse/Assets.xcassets/{Contents.json,AccentColor.colorset/Contents.json,LaunchBackground.colorset/Contents.json,LaunchIcon.imageset/Contents.json,LaunchIcon.imageset/LaunchIcon@2x.png,LaunchIcon.imageset/LaunchIcon@3x.png,RiskHigh.colorset/Contents.json,RiskLow.colorset/Contents.json,RiskModerate.colorset/Contents.json}`; `drinkpulse/AppIcon.icon/{icon.json,Assets/drinkpulse-2-drop.svg,Assets/drinkpulse-3-pulse.svg}` | launch screen, scene manifest, Health usage strings, localized strings, named colors/images, icon asset | **NC-UI-11 — no-candidate:** resource identifiers are in use and no iOS 27 runtime-resource replacement or migration is supported by evidence. Entitlements are not changed. |

## Candidate and retain register

| ID | Current API / exact occurrences | Official source and availability/deprecation statement | Evidence and disposition | Priority / destination / substantial |
| --- | --- | --- | --- | --- |
| UI-C-01 | Custom `@Entry` environment value carrying a dismiss closure — `drinkpulse/Features/AddDrink/AddDrinkView.swift:4,12`. | [Entry macro](https://developer.apple.com/documentation/swiftui/entry()) (looked up 2026-09-16). The app’s iOS 27 minimum satisfies the API’s availability. No official deprecation is claimed; the issue is the baseline compiler warning, not API age. | **Change.** 08-BASELINE.md attributes an app-owned warning at `AddDrinkView.swift:5`: the stored `dismissSheet` closure may invalidate dependents because closures are not comparable. Evaluate a behavior-preserving ownership/injection shape in Phase 09; do not replace merely because the macro is newer. | P1 / Phase 09 / **yes — decision brief before implementation** because dismissal/navigation semantics could change. |
| UI-C-02 | `Shape` conformance used by the animated dashboard arc — `drinkpulse/DesignSystem/DPArcProgress.swift:6-25,33-49`. | [Shape](https://developer.apple.com/documentation/swiftui/shape) (looked up 2026-09-16). The app’s iOS 27 minimum satisfies its availability; no deprecation is claimed. | **Change.** The baseline’s app-owned compiler error identifies `DPArcProgress.swift:33`: `ArcShape` conformance crosses into main-actor-isolated code and may race. Phase 09 must make the isolated/nonisolated boundary compile while preserving the rendered arc, its value animation, and accessibility label. | P0 / Phase 09 / no — a targeted compiler-correctness repair is expected to preserve behavior; reclassify if its visual or accessibility contract changes. |
| UI-C-03 | Stable `ForEach` identity patterns — `drinkpulse/Features/AddDrink/DrinkDetailInputView.swift:55,64,73`; `drinkpulse/Features/AddDrink/DrinkTypeGrid.swift:12`; `drinkpulse/Features/Onboarding/OnboardingView.swift:74`; `drinkpulse/Features/Onboarding/Components/GuidelineStep.swift:26`; `drinkpulse/Features/Settings/SettingsView.swift:69,86`; `drinkpulse/Features/Settings/Components/GuidelinePickerSheet.swift:12`; `drinkpulse/Features/History/HistoryListQueryView.swift:40`; `drinkpulse/Features/History/HistoryView.swift:119`; `drinkpulse/Features/History/Components/{CustomNameSuggestionSection.swift:25,EditServingPickers.swift:15,24,33,HistoryCalendarDayDetail.swift:57,HistoryCalendarView.swift:67,73,PriceCurrencySection.swift:21}`; `drinkpulse/Features/Insights/Components/{GuidelineComparisonCard.swift:11,InsightsScopeNavigator.swift:9}`. | [ForEach](https://developer.apple.com/documentation/swiftui/foreach) (looked up 2026-09-16). Availability is satisfied by iOS 27; no deprecation claim. | **Retain.** The reviewed collections use model identity, stable enum/value domains, or bounded constants. In particular, History event identity is `uuid` at `drinkpulse/Features/History/Components/HistoryCalendarDayDetail.swift:57`; do not change it to positional identity. | P2 / Phase 09 only if a measured correctness/performance failure emerges / no. |
| UI-C-04 | History’s List/ScrollView split — `drinkpulse/Features/History/HistoryListQueryView.swift:39-81` and `drinkpulse/Features/History/HistoryView.swift:82-109,147-162`; related horizontal-card scroll handling is in `Features/History/Components/HistoryEventCardRow.swift:55,75`. | [List](https://developer.apple.com/documentation/swiftui/list), [ScrollView](https://developer.apple.com/documentation/swiftui/scrollview), and [iOS/iPadOS 27 release notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes) (looked up 2026-09-16). The inventory makes no unsupported deprecation claim. | **Retain.** `history-scrollview-bugs.md` records that an earlier List-to-`ScrollView`/`LazyVStack` change caused variable row heights, grouping, pagination, and gesture issues and was reverted. The protected behavior is native List rendering for list history plus a distinct calendar scroll surface. Revisit only after a focused iOS 27 reproduction proves the protected interactions and official guidance supports a concrete replacement. | P0 / Phase 09 / **yes — decision brief before any rewrite**; user behavior, scrolling, paging, Dynamic Type, and accessibility could change. |
| UI-C-05 | History context menu and explicit destructive confirmation — `drinkpulse/Features/History/Components/EventContextMenu.swift:5-58`; exercised by `Features/History/HistoryInteractionUITests.swift:88-132` and `Features/History/WrongRowContextMenuTargetUITests.swift:26-83`. | [contextMenu(menuItems:preview:)](https://developer.apple.com/documentation/swiftui/view/contextmenu%28menuitems%3Apreview%3A%29) and [confirmationDialog](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:message:)) (looked up 2026-09-16). The app’s iOS 27 minimum satisfies availability; no deprecation claim. | **Retain.** `contextmenu-zoom-glitch.md` records a Liquid Glass preview/zoom glitch when the prior ScrollView approach was used; the protected behavior is long-press acting on the correct row, VoiceOver duplicate/delete actions, and destructive-delete confirmation. A future change needs deterministic iOS 27 reproduction of those interactions plus official guidance for the exact replacement. Missing replacement documentation alone is **not** an external block. | P0 / Phase 09 / **yes — decision brief before any change** because visible destructive action and accessibility behavior are involved. |
| UI-C-06 | Accessible Swift Charts selection and descriptors — `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift:21-79`; `drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift:4-34`; `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift:16-62`; `drinkpulse/Features/Insights/Components/WeekdayBarChart+Accessibility.swift:4-35`. | [accessibilityChartDescriptor(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilitychartdescriptor(_:)), [chartXSelection(value:)](https://developer.apple.com/documentation/swiftui/view/chartxselection(value:)), and [Swift Charts](https://developer.apple.com/documentation/charts) (looked up 2026-09-16). `chartXSelection` is an iOS 17+ API; the project minimum is iOS 27. No deprecation claim. | **Retain.** Both chart families already expose semantic labels and `AXChartDescriptor` data for VoiceOver/Audio Graph. Do not substitute a newer chart API without an observed accessibility or interaction defect. | P0 / Phase 09 or 11 only if evidence requires it / **yes — decision brief before change** because Audio Graph and VoiceOver behavior are release criteria. |
| UI-C-07 | Observation-owned feature models and `@State` owners — `drinkpulse/Features/Dashboard/DashboardViewModel.swift:12`; `drinkpulse/Features/History/HistoryViewModel.swift:18`; `drinkpulse/Features/Insights/InsightsViewModel.swift:3,17,158-159`; `drinkpulse/Features/Onboarding/OnboardingViewModel.swift:4`; owners at `drinkpulse/Features/Dashboard/DashboardView.swift:5`, `drinkpulse/Features/History/HistoryView.swift:20`, `drinkpulse/Features/Insights/InsightsView.swift:5`, and `drinkpulse/Features/Onboarding/OnboardingView.swift:8`. | [Observable](https://developer.apple.com/documentation/observation/observable()) (looked up 2026-09-16). Observation is available on iOS 17+; project minimum is iOS 27. No deprecation claim. | **Retain.** Models are already `@Observable @MainActor`, views use `@State` when owning a model, and cache-only state in Insights is marked `@ObservationIgnored`. No `ObservableObject` migration candidate was found. | P2 / no implementation destination unless a measured invalidation issue appears / no. |
| UI-C-08 | Reduce Motion-aware transition/animation patterns — `drinkpulse/Features/History/HistoryView.swift:9,84-109`; `drinkpulse/Features/History/Components/EventContextMenu.swift:5-13`; `drinkpulse/Features/Insights/Components/{AlcoholAreaChart.swift:10,100-105,WeekdayBarChart.swift:10,75-86}`; `drinkpulse/Features/Onboarding/OnboardingView.swift:9,78-88`. | [accessibilityReduceMotion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion) and [animation(_:value:)](https://developer.apple.com/documentation/swiftui/view/animation(_:value:)) (looked up 2026-09-16). Availability is satisfied by iOS 27; no deprecation claim. | **Retain.** Current code explicitly removes or avoids animation when Reduce Motion is enabled and every inspected implicit animation supplies `value:`. iOS 27 simulator behavior still needs later Phase 11 human accessibility verification; this inventory makes no passing claim. | P0 / Phase 11 verification / **yes — decision brief before behavior change**. |
| UI-C-09 | Deliberate Liquid Glass styling — `drinkpulse/DesignSystem/DPGlass.swift:18-31`; consumed by the chart/card system. | [glassEffect(_:in:)](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)) (looked up 2026-09-16). This is an iOS 26+ API, so iOS 27 satisfies availability; no deprecation claim. | **Retain.** The design system centralizes the deliberate glass surface. The prior context-menu investigation demonstrates why changing glass-related rendering needs interaction evidence rather than a cosmetic rewrite. | P1 / Phase 09 only if a documented defect exists / **yes — decision brief before visual/accessibility change**. |

## Current test-evidence boundary

The selected iOS 27 full-suite invocation in 08-BASELINE.md was unfiltered but
could not compile `DPArcProgress`; therefore neither unit nor UI tests began and
their total/passed/failed/skipped counts are **unavailable**. The known History
workaround tests listed in UI-C-05 have not been called green. A focused rerun
cannot presently establish interaction evidence because the app target fails
before tests execute. After the Phase 09 compiler repair, run the named History
tests on iPhone 18 Pro (`1D35E1B8-4141-4EFF-A493-52CB37B600A5`, iOS 27.0), record
raw evidence outside Git, and only then decide whether either retain record can
be revisited.

## Traceability and next decision gate

- All **change** items route to Phase 09; no production source was edited here.
- Every **substantial** item is explicitly marked for a separate Phase 08
  decision brief before it can enter a Phase 09 execution plan (D-09/D-10).
- No item is externally blocked: uncertainty is recorded as **retain** with the
  iOS 27 observation and official guidance required for reconsideration.

## UI-test reviewed-file census

The following is a tracked-file census of `drinkpulseUITests/`. Test source was
reviewed for launch seeding, accessibility assertions, query/wait primitives,
long-press and scrolling interactions, and any explicit iOS-version assumption.
Each folder has a no-candidate row even where it supplies a source anchor for
UI-C-10.

| Test area | Tracked files reviewed | Test APIs/patterns checked | Explicit no-candidate record |
| --- | --- | --- | --- |
| AddDrink | `drinkpulseUITests/Features/AddDrink/{AddDrinkFlowUITests.swift,AddDrinkPickerFilterUITests.swift,CurrencyUITests.swift,CustomNameAutocompleteUITests.swift,HealthWriteHooksUITests.swift,VolumeServingUITests.swift}` | `XCUIApplication`, launch arguments, accessibility identifiers/labels, picker/filter interaction, Health test hooks, `waitForExistence`, XCTest assertions | **NC-TEST-01 — no-candidate:** no deprecated or iOS 27-specific UI-test API was found; retain deterministic seeded-flow coverage. |
| Dashboard | `drinkpulseUITests/Features/Dashboard/DashboardUITests.swift` | application launch, tab navigation, dashboard accessibility labels, wait/assertion primitives | **NC-TEST-02 — no-candidate:** no candidate beyond the general VoiceOver capability lead UI-C-10. |
| History | `drinkpulseUITests/Features/History/{ContextMenuDeleteConfirmationUITests.swift,DuplicateEditPersistenceUITests.swift,EditDeleteConfirmationUITests.swift,EditVolumeIntegrityUITests.swift,HistoryDynamicTypeUITests.swift,HistoryInteractionUITests.swift,HistoryInteractionUITests+DirectionalTransition.swift,HistoryInteractionUITests+Helpers.swift,HistoryInteractionUITests+HitTarget.swift,HistoryInteractionUITests+LoadingState.swift,HistoryInteractionUITests+Pagination.swift,HistoryUnitDisplayUITests.swift,WrongRowContextMenuTargetUITests.swift}` | launch seed data, `press(forDuration:)`, tap/swipe, List/calendar transition, pagination, Dynamic Type, hit target, context-menu targeting, destructive confirmation, accessibility labels, XCTest waits | **NC-TEST-03 — no-candidate:** retain all existing focused behavior tests. UI-C-04/UI-C-05 name the protected production behavior and the specific reproduction evidence required before a workaround change. |
| Insights | `drinkpulseUITests/Features/Insights/{InsightsDrinkFreeDaysUITests.swift,InsightsScrubUITests.swift,InsightsStreakUITests.swift,InsightsUITests.swift}` | chart labels, scrub long-press/drag, period selection, scroll visibility, value/height assertions, XCTest waits | **NC-TEST-04 — no-candidate:** no iOS 27-specific rewrite is justified. UI-C-10 is only a future capability review, not authorization to replace these tests. |
| Onboarding | `drinkpulseUITests/Features/Onboarding/{OnboardingFlowUITests.swift,OnboardingHealthStepUITests.swift,OnboardingLocaleDefaultUITests.swift,OnboardingWeeklySummaryUITests.swift}` | launch arguments, walkthrough/back navigation, Health permission hook, locale default, weekly-summary option, accessibility labels, XCTest waits | **NC-TEST-05 — no-candidate:** retain current deterministic onboarding and localization coverage; no deprecated test API was found. |
| Settings | `drinkpulseUITests/Features/Settings/{ExportUITests.swift,GuidelinePickerUITests.swift,HealthSettingsUITests.swift,ReminderSettingsUITests.swift,SettingsUITests.swift,WeeklySummarySettingsUITests.swift}` | launch seeding, file-export sheet, settings navigation, semantic control state, scroll/swipe, accessibility/hit target assertions, XCTest waits | **NC-TEST-06 — no-candidate:** no iOS 27 test API replacement is supported by observed evidence. |
| Shell | `drinkpulseUITests/Features/Shell/{LaunchHandoffUITests.swift,OnboardingAuthorityUITests.swift,ShellNavigationUITests.swift,StartupErrorUITests.swift,WeeklySummaryTapUITests.swift}` | startup handoff, app/tab navigation, notification seed, onboarding authority, retry state, launch arguments, XCTest waits | **NC-TEST-07 — no-candidate:** retain startup and notification-routing tests; no specific test modernization lead was found. |

## UI-test candidate and workaround evidence

| ID | Current test/source anchor | Official source and availability/deprecation statement | Evidence and disposition | Priority / destination / substantial |
| --- | --- | --- | --- | --- |
| UI-C-10 | Current XCTest UI tests use `XCUIApplication`, semantic element queries, seeded launch arguments, and XCTest waits. Representative anchors: `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift:13-26,88-132`; `drinkpulseUITests/Features/History/WrongRowContextMenuTargetUITests.swift:26-83`; `drinkpulseUITests/Features/Insights/InsightsUITests.swift:74-89`; `drinkpulseUITests/Features/Onboarding/OnboardingFlowUITests.swift:8-105`. No `XCUIVoiceOverService` occurrence currently exists. | [Xcode 27 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes) (looked up 2026-09-16) is the official discovery source for `XCUIVoiceOverService`; the relevant toolchain is Xcode 27. This is an availability/capability lead, **not** a statement that XCTest or the current tests are deprecated. | **Change candidate, deferred for decision.** Evaluate whether the new service can add deterministic VoiceOver regression coverage without replacing the existing semantic UI tests. The baseline could not compile, so it provides no execution evidence for the current tests or this capability. | P1 / Phase 11 after a D-09 brief / **yes — test accessibility behavior is in scope for the decision gate.** |

### Protected History workaround evidence

| Workaround / behavior protected | Current production locations | Current focused UI-test locations | Required evidence before revisiting | Disposition |
| --- | --- | --- | --- | --- |
| Native List history with paged day rows, plus a separate calendar `ScrollView` branch | `drinkpulse/Features/History/HistoryListQueryView.swift:39-81`; `drinkpulse/Features/History/HistoryView.swift:82-109,147-162` | `HistoryInteractionUITests.swift:26-86`; `HistoryInteractionUITests+DirectionalTransition.swift`; `HistoryInteractionUITests+Pagination.swift`; `HistoryDynamicTypeUITests.swift` | Fix UI-C-02’s compile error, then reproduce list/calendar switching, row grouping, load-more, Dynamic Type, and gesture behavior on the named iOS 27 simulator; pair any proposed replacement with applicable official List/ScrollView guidance. | **Retain.** Earlier List-to-ScrollView evidence is preserved in `history-scrollview-bugs.md`; lack of a replacement document is not an external block. |
| Context-menu actions select the intended History row, expose VoiceOver actions, and show an explicit destructive confirmation | `drinkpulse/Features/History/Components/EventContextMenu.swift:25-58`; application at `Features/History/Components/EventRowButton.swift:20-31` | `HistoryInteractionUITests.swift:88-132`; `WrongRowContextMenuTargetUITests.swift:26-83`; `ContextMenuDeleteConfirmationUITests.swift` | Fix compilation, then run these exact focused tests on iOS 27 and manually inspect Liquid Glass preview/zoom behavior; cite an official replacement only if one is proposed. | **Retain.** `contextmenu-zoom-glitch.md` remains the protected-behavior record; missing replacement documentation alone is not an external block. |

## UI-test evidence handoff

No focused test was run by this plan: the known app-owned compilation error in
UI-C-02 prevents the app target and therefore every UI test from starting. This
is not a new failure classification and it does not turn a blocked test into a
pass. Phase 09 must first repair the compiler error; Phase 11 then owns the
focused and full-suite iOS 27 execution evidence, including VoiceOver/Audio
Graph and the retained History interaction cases.

## Exact tracked file manifest

This canonical manifest expands the grouped census tables into repository-relative
paths so every reviewed file can be mechanically compared with `git ls-files`.

### Production UI, startup, design system, diagnostics, and resources

```text
drinkpulse/drinkpulseApp.swift
drinkpulse/UITestSeed.swift
drinkpulse/UITestSeed+Fixtures.swift
drinkpulse/Features/AddDrink/AddDrinkView.swift
drinkpulse/Features/AddDrink/Components/DrinkTypeTile.swift
drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift
drinkpulse/Features/AddDrink/DrinkDetailInputView.swift
drinkpulse/Features/AddDrink/DrinkTypeGrid.swift
drinkpulse/Features/AddDrink/DrinkTypeGridView.swift
drinkpulse/Features/AddDrink/DrinkTypePreset+FermentedPresets.swift
drinkpulse/Features/AddDrink/DrinkTypePreset+MixedPresets.swift
drinkpulse/Features/AddDrink/DrinkTypePreset+SpiritPresets.swift
drinkpulse/Features/AddDrink/DrinkTypePreset.swift
drinkpulse/Features/Dashboard/Components/ConsumptionOverviewCard.swift
drinkpulse/Features/Dashboard/Components/DPChip.swift
drinkpulse/Features/Dashboard/Components/DashboardChipRow.swift
drinkpulse/Features/Dashboard/Components/DashboardHeroCard.swift
drinkpulse/Features/Dashboard/Components/GuidelineAlertCard.swift
drinkpulse/Features/Dashboard/Components/StreakCard.swift
drinkpulse/Features/Dashboard/Components/ThisWeekCard.swift
drinkpulse/Features/Dashboard/DashboardView+Previews.swift
drinkpulse/Features/Dashboard/DashboardView.swift
drinkpulse/Features/Dashboard/DashboardViewModel.swift
drinkpulse/Features/History/Components/CustomNameSuggestionSection.swift
drinkpulse/Features/History/Components/DeleteConfirmationPopover.swift
drinkpulse/Features/History/Components/EditDrinkTypeSelectionView.swift
drinkpulse/Features/History/Components/EditNotesSection.swift
drinkpulse/Features/History/Components/EditServingPickers.swift
drinkpulse/Features/History/Components/EventContextMenu.swift
drinkpulse/Features/History/Components/EventRow.swift
drinkpulse/Features/History/Components/EventRowButton.swift
drinkpulse/Features/History/Components/EventRowStrings.swift
drinkpulse/Features/History/Components/HistoryCalendarDayCell.swift
drinkpulse/Features/History/Components/HistoryCalendarDayDetail.swift
drinkpulse/Features/History/Components/HistoryCalendarView.swift
drinkpulse/Features/History/Components/HistoryEventCardRow.swift
drinkpulse/Features/History/Components/HistoryFlatRow.swift
drinkpulse/Features/History/Components/PriceCurrencySection.swift
drinkpulse/Features/History/Components/RowUnitContext.swift
drinkpulse/Features/History/EditEventView.swift
drinkpulse/Features/History/HistoryCalendarQueryView.swift
drinkpulse/Features/History/HistoryListQueryView.swift
drinkpulse/Features/History/HistorySegment.swift
drinkpulse/Features/History/HistoryView.swift
drinkpulse/Features/History/HistoryViewModel.swift
drinkpulse/Features/Insights/Calendar+Days.swift
drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift
drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift
drinkpulse/Features/Insights/Components/GuidelineComparisonCard.swift
drinkpulse/Features/Insights/Components/HealthMetricsCard.swift
drinkpulse/Features/Insights/Components/InsightsHeroCard.swift
drinkpulse/Features/Insights/Components/InsightsScopeNavigator.swift
drinkpulse/Features/Insights/Components/WeekdayBarChart+Accessibility.swift
drinkpulse/Features/Insights/Components/WeekdayBarChart.swift
drinkpulse/Features/Insights/InsightsChartModels.swift
drinkpulse/Features/Insights/InsightsDataGenerator.swift
drinkpulse/Features/Insights/InsightsPeriod.swift
drinkpulse/Features/Insights/InsightsView.swift
drinkpulse/Features/Insights/InsightsViewModel+Charts.swift
drinkpulse/Features/Insights/InsightsViewModel+Formatting.swift
drinkpulse/Features/Insights/InsightsViewModel+HealthMetrics.swift
drinkpulse/Features/Insights/InsightsViewModel.swift
drinkpulse/Features/Onboarding/Components/GuidelineStep.swift
drinkpulse/Features/Onboarding/Components/HealthStep.swift
drinkpulse/Features/Onboarding/Components/ProfileStep.swift
drinkpulse/Features/Onboarding/Components/WelcomeStep.swift
drinkpulse/Features/Onboarding/OnboardingView.swift
drinkpulse/Features/Onboarding/OnboardingViewModel.swift
drinkpulse/Features/Settings/Components/AppearanceModeRow.swift
drinkpulse/Features/Settings/Components/DataSection.swift
drinkpulse/Features/Settings/Components/GuidelineChoiceRow.swift
drinkpulse/Features/Settings/Components/GuidelinePickerSheet.swift
drinkpulse/Features/Settings/Components/HealthSection.swift
drinkpulse/Features/Settings/Components/ReminderSection.swift
drinkpulse/Features/Settings/Components/SettingsActionRow.swift
drinkpulse/Features/Settings/Components/SettingsRow.swift
drinkpulse/Features/Settings/Components/SettingsSection.swift
drinkpulse/Features/Settings/Components/WeeklySummarySection.swift
drinkpulse/Features/Settings/SettingsView.swift
drinkpulse/Features/Shell/AppTab.swift
drinkpulse/Features/Shell/Components/AddDrinkButton.swift
drinkpulse/Features/Shell/RootShellView.swift
drinkpulse/Features/Shell/StartupErrorView.swift
drinkpulse/DesignSystem/AppStorageKeys.swift
drinkpulse/DesignSystem/DPArcProgress.swift
drinkpulse/DesignSystem/DPBrand.swift
drinkpulse/DesignSystem/DPColors.swift
drinkpulse/DesignSystem/DPGlass.swift
drinkpulse/DesignSystem/DPLargeTitle.swift
drinkpulse/DesignSystem/DPSemanticColors.swift
drinkpulse/DesignSystem/RiskLevel+Color.swift
drinkpulse/Diagnostics/ViewLoadLogger.swift
drinkpulse/Info.plist
drinkpulse/drinkpulse.entitlements
drinkpulse/Localizable.xcstrings
drinkpulse/Assets.xcassets/.DS_Store
drinkpulse/Assets.xcassets/Contents.json
drinkpulse/Assets.xcassets/AccentColor.colorset/Contents.json
drinkpulse/Assets.xcassets/LaunchBackground.colorset/Contents.json
drinkpulse/Assets.xcassets/LaunchIcon.imageset/Contents.json
drinkpulse/Assets.xcassets/LaunchIcon.imageset/LaunchIcon@2x.png
drinkpulse/Assets.xcassets/LaunchIcon.imageset/LaunchIcon@3x.png
drinkpulse/Assets.xcassets/RiskHigh.colorset/Contents.json
drinkpulse/Assets.xcassets/RiskLow.colorset/Contents.json
drinkpulse/Assets.xcassets/RiskModerate.colorset/Contents.json
drinkpulse/AppIcon.icon/icon.json
drinkpulse/AppIcon.icon/Assets/drinkpulse-2-drop.svg
drinkpulse/AppIcon.icon/Assets/drinkpulse-3-pulse.svg
```

### UI-test sources

```text
drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift
drinkpulseUITests/Features/AddDrink/AddDrinkPickerFilterUITests.swift
drinkpulseUITests/Features/AddDrink/CurrencyUITests.swift
drinkpulseUITests/Features/AddDrink/CustomNameAutocompleteUITests.swift
drinkpulseUITests/Features/AddDrink/HealthWriteHooksUITests.swift
drinkpulseUITests/Features/AddDrink/VolumeServingUITests.swift
drinkpulseUITests/Features/Dashboard/DashboardUITests.swift
drinkpulseUITests/Features/History/ContextMenuDeleteConfirmationUITests.swift
drinkpulseUITests/Features/History/DuplicateEditPersistenceUITests.swift
drinkpulseUITests/Features/History/EditDeleteConfirmationUITests.swift
drinkpulseUITests/Features/History/EditVolumeIntegrityUITests.swift
drinkpulseUITests/Features/History/HistoryDynamicTypeUITests.swift
drinkpulseUITests/Features/History/HistoryInteractionUITests+DirectionalTransition.swift
drinkpulseUITests/Features/History/HistoryInteractionUITests+Helpers.swift
drinkpulseUITests/Features/History/HistoryInteractionUITests+HitTarget.swift
drinkpulseUITests/Features/History/HistoryInteractionUITests+LoadingState.swift
drinkpulseUITests/Features/History/HistoryInteractionUITests+Pagination.swift
drinkpulseUITests/Features/History/HistoryInteractionUITests.swift
drinkpulseUITests/Features/History/HistoryUnitDisplayUITests.swift
drinkpulseUITests/Features/History/WrongRowContextMenuTargetUITests.swift
drinkpulseUITests/Features/Insights/InsightsDrinkFreeDaysUITests.swift
drinkpulseUITests/Features/Insights/InsightsScrubUITests.swift
drinkpulseUITests/Features/Insights/InsightsStreakUITests.swift
drinkpulseUITests/Features/Insights/InsightsUITests.swift
drinkpulseUITests/Features/Onboarding/OnboardingFlowUITests.swift
drinkpulseUITests/Features/Onboarding/OnboardingHealthStepUITests.swift
drinkpulseUITests/Features/Onboarding/OnboardingLocaleDefaultUITests.swift
drinkpulseUITests/Features/Onboarding/OnboardingWeeklySummaryUITests.swift
drinkpulseUITests/Features/Settings/ExportUITests.swift
drinkpulseUITests/Features/Settings/GuidelinePickerUITests.swift
drinkpulseUITests/Features/Settings/HealthSettingsUITests.swift
drinkpulseUITests/Features/Settings/ReminderSettingsUITests.swift
drinkpulseUITests/Features/Settings/SettingsUITests.swift
drinkpulseUITests/Features/Settings/WeeklySummarySettingsUITests.swift
drinkpulseUITests/Features/Shell/LaunchHandoffUITests.swift
drinkpulseUITests/Features/Shell/OnboardingAuthorityUITests.swift
drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift
drinkpulseUITests/Features/Shell/StartupErrorUITests.swift
drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift
```
