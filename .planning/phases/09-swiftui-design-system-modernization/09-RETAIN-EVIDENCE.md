# Phase 09 Retain Evidence — iOS 27

**Recorded:** 2026-09-19
**Scope:** Plan 09-03 automated evidence only. No production source or test source was modified.

## Environment and provenance

| Item | Recorded value |
| --- | --- |
| Xcode | 27.0 (build 27A266a) |
| SDK / minimum deployment | iPhoneSimulator 27.0 / iOS 27.0 |
| Simulator | iPhone 18 Pro — `1D35E1B8-4141-4EFF-A493-52CB37B600A5` |
| Test result | **pass** — 49 selected UI tests, 0 failures, 869.086 seconds (persistent CLI run; no MCP timeout was used as a result) |
| Result bundle | `/Users/fempter/Library/Developer/Xcode/DerivedData/drinkpulse-gfnlqrdtxgswbyguxchmqpggiaoy/Logs/Test/Test-drinkpulse-2026.09.19_07-26-24-+0200.xcresult` |
| Spec-less probe fallback | `spec-less probe fallback: disabled` by project configuration; no fabricated probe predicate was used. |

The iOS 27 simulator was selected with `xcrun simctl list devices available` and booted with `xcrun simctl bootstatus "$LOCAL_IOS_27_UDID" -b` before testing.

## Phase 08 candidate disposition index

| Candidate | Disposition | Plan / rationale |
| --- | --- | --- |
| UI-C-01 | Change | Completed by Plan 09-02: approved Add Drink dismissal ownership repair. |
| UI-C-02 | Change | Completed by Plan 09-01: targeted `DPArcProgress` compiler-correctness repair. |
| UI-C-03 | Retain | Stable `ForEach` identities pass the focused source audit and selected iOS 27 UI suite; no replacement evidence. |
| UI-C-04 | Retain | Native History List and separate calendar branch remain covered by focused iOS 27 interactions; no List rewrite evidence. |
| UI-C-05 | Retain | Context-menu target, duplicate, destructive confirmation, and accessibility actions remain protected by focused tests; no replacement evidence. |
| UI-C-06 | Retain | Swift Charts selection, selected-value callout, labels, and descriptor attachments remain source-audited and covered by focused tests; no replacement evidence. |
| UI-C-07 | Retain | Feature model Observation ownership remains source-audited; no speculative state-management change is justified. |
| UI-C-08 | Retain | Existing Reduce Motion behavior remains source-audited and requires human runtime verification before any change; no replacement evidence. |
| UI-C-09 | Retain | Centralized Liquid Glass remains unchanged; no measured visual, contrast, accessibility, or context-menu defect was established. |
| UI-C-10 | Change | Completed by Plan 09-02: approved focused VoiceOver UI regression coverage. |

## Official Apple sources and rationale

Xcode MCP `DocumentationSearch` was not exposed in this execution environment, so the official Apple Developer documentation site was consulted first.

| Area | Official source | Availability / rationale |
| --- | --- | --- |
| Stable `ForEach` identity | [ForEach](https://developer.apple.com/documentation/swiftui/foreach) and [Displaying data in lists](https://developer.apple.com/documentation/swiftui/displaying-data-in-lists?changes=_4) | The app's iOS 27 minimum satisfies SwiftUI support. Apple requires unique identifiers for dynamic List data and describes identifiers as preserving update behavior. The audited model, enum/value, and bounded-label identities therefore remain appropriate; neither source identifies a replacement requirement. |
| Observation ownership | [State](https://developer.apple.com/documentation/swiftui/state?changes=_1) and [Migrating from the Observable Object protocol to the Observable macro](https://developer.apple.com/documentation/SwiftUI/Migrating-from-the-observable-object-protocol-to-the-observable-macro?changes=_5) | Observation support begins with iOS 17, therefore is available on iOS 27. Apple documents `@State` storage for an `@Observable` object owned by a view; this matches the audited feature owner pattern. |
| Accessibility and motion | [Accessibility fundamentals](https://developer.apple.com/documentation/swiftui/accessibility-fundamentals?changes=_2_6_1) and [accessibilityReduceMotion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion?changes=_3) | These SwiftUI facilities are available at the project's iOS 27 minimum. Apple directs UI to avoid large motion when Reduce Motion is enabled; the existing no-callout-slide gate remains justified. |
| Chart descriptors and Audio Graph | [AXChartDescriptorRepresentable](https://developer.apple.com/documentation/swiftui/axchartdescriptorrepresentable) and [Representing chart data as an audio graph](https://developer.apple.com/documentation/accessibility/representing-chart-data-as-an-audio-graph) | `accessibilityChartDescriptor` attaches the semantic chart description used by VoiceOver and other assistive technology. Existing descriptor paths remain justified; a newer API was not treated as replacement evidence. |

## Automated evidence

### Commands and results

```text
xcrun simctl list devices available
export LOCAL_IOS_27_UDID=1D35E1B8-4141-4EFF-A493-52CB37B600A5
xcrun simctl bootstatus "$LOCAL_IOS_27_UDID" -b

xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" \
  -only-testing:drinkpulseUITests/DashboardUITests \
  -only-testing:drinkpulseUITests/AddDrinkFlowUITests \
  -only-testing:drinkpulseUITests/HistoryInteractionUITests \
  -only-testing:drinkpulseUITests/HistoryDynamicTypeUITests \
  -only-testing:drinkpulseUITests/WrongRowContextMenuTargetUITests \
  -only-testing:drinkpulseUITests/ContextMenuDeleteConfirmationUITests \
  -only-testing:drinkpulseUITests/InsightsScrubUITests \
  -only-testing:drinkpulseUITests/InsightsUITests \
  -only-testing:drinkpulseUITests/OnboardingFlowUITests \
  -only-testing:drinkpulseUITests/SettingsUITests

Result: ** TEST SUCCEEDED **
Selected tests: 49 executed, 0 failures, 869.086 seconds.
```

The persistent CLI result replaces neither a full-suite result nor manual accessibility/visual verification. It does establish that every named focused test class started and completed successfully on iOS 27.

### UI-C-03 — stable identity: pass

The focused source audit passed for all listed identity sites:

- Add Drink: `DrinkDetailInputView.swift`, `DrinkTypeGrid.swift` — stable preset/value domains.
- History: `HistoryListQueryView.swift`, `HistoryView.swift`, `Components/CustomNameSuggestionSection.swift`, `EditServingPickers.swift`, `HistoryCalendarDayDetail.swift`, `HistoryCalendarView.swift`, and `PriceCurrencySection.swift` — List models and stable values; calendar event rows retain `ForEach(events, id: \\.uuid)`.
- Onboarding: `OnboardingView.swift`, `Components/GuidelineStep.swift` — bounded step values and guideline enum values.
- Settings: `SettingsView.swift`, `Components/GuidelinePickerSheet.swift` — stable catalog and guideline values.
- Insights: `Components/GuidelineComparisonCard.swift`, `InsightsScopeNavigator.swift` — stable enum/value domains.

`HistoryCalendarView.swift` deliberately uses `rotated.indices.map { WeekdayLabel(id: $0, text: rotated[$0]) }` to build seven bounded `WeekdayLabel` values. The rendered `ForEach(weekdayLabels)` uses those values' identifiers, so this is **not** a positional rendered-row identity failure.

**Frozen-plan verification adjustment:** the plan's literal broad assertion that
every audited file contains no `.indices` reports `HistoryCalendarView.swift`
as a false positive. It does not inspect the rendered collection identity and
therefore conflicts with this intentional bounded-label construction. The
semantic replacement audit verified the actual rendered loops
(`ForEach(weekdayLabels)` and `ForEach(cells)`), the stable label IDs, and the
separate event `uuid` identity. No source change was made; this is a recorded
verification-method deviation, not a retained failure.

Protected behavior: model/event identity continues across History list/calendar presentation, and bounded enum/value domains continue across Add Drink, Onboarding, Settings, and Insights. The selected suite passed relevant Add Drink, History interaction, Onboarding, Settings, and Insights flows. No replacement is justified.

### UI-C-04 / UI-C-05 — History List, calendar, and destructive actions: pass

Checked paths: `HistoryListQueryView.swift`, `HistoryView.swift`, `Components/EventContextMenu.swift`; focused suites `HistoryInteractionUITests`, `HistoryDynamicTypeUITests`, `WrongRowContextMenuTargetUITests`, and `ContextMenuDeleteConfirmationUITests` all passed.

Protected behavior: native `List` presentation, its separate calendar surface, grouped rows, recovery/paging, stable row targeting, long-press duplicate/delete actions, and confirmation-gated destructive deletion remain covered. The test output includes AX5 row hit-target coverage and correct bottom-row duplicate/delete coverage. No List-to-`ScrollView` rewrite or context-menu replacement is justified.

### UI-C-06 / UI-C-08 — Insights charts, descriptors, and Reduce Motion: pass for automated scope

Checked paths: `InsightsView.swift`, `InsightsViewModel.swift`, `Components/AlcoholAreaChart.swift`, `AlcoholAreaChart+Accessibility.swift`, `WeekdayBarChart.swift`, and `WeekdayBarChart+Accessibility.swift`; focused suites `InsightsScrubUITests` and `InsightsUITests` passed.

Protected behavior: chart drag selection, selected-value callout coverage, period/hero follow-revert behavior, semantic labels, and both `AXChartDescriptorRepresentable` attachment paths are retained. Source audit confirms callout animation is gated by `accessibilityReduceMotion`; the selected suite confirms the interaction surfaces but does not substitute for a human VoiceOver, Audio Graph, or motion-preference observation. No chart or animation replacement is justified.

### UI-C-07 — Observation owner pattern: pass

The focused source audit passed:

| Feature | Model | Owner | Result |
| --- | --- | --- | --- |
| Dashboard | `DashboardViewModel.swift` (`@Observable @MainActor`) | `DashboardView.swift` (`@State private var vm`) | pass |
| History | `HistoryViewModel.swift` (`@Observable @MainActor`) | `HistoryView.swift` (`@State private var vm`) | pass |
| Insights | `InsightsViewModel.swift` (`@Observable @MainActor`, cache marked `@ObservationIgnored`) | `InsightsView.swift` (`@State private var vm`) | pass |
| Onboarding | `OnboardingViewModel.swift` (`@Observable @MainActor`) | `OnboardingView.swift` (`@State private var vm`) | pass |

The selected Dashboard, History, Insights, and Onboarding tests passed on iOS 27. This is retention evidence for the existing ownership pattern, not authorization for a state-management rewrite.

### UI-C-09 — centralized Liquid Glass: pass for source and focused regression scope

Checked paths: `DesignSystem/DPGlass.swift` and `Features/History/Components/EventContextMenu.swift`. `dpGlassCard` remains the centralized `.glassEffect(.regular, in: .rect(cornerRadius: ...))` modifier, while chart callouts retain their dedicated opaque background. Focused History and Insights test suites passed without a source change.

Protected behavior: centralized styling and the established context-menu workaround remain intact. No measured visual, contrast, accessibility, preview, or zoom defect was found in automated evidence; no replacement is justified.

## Limited Xcode MCP visual observations

On 2026-09-19, a read-only Xcode MCP simulator interaction on the same iPhone
18 Pro / iOS 27 runtime observed the following visible surfaces. These are
partial visual observations, not substitutes for the complete human checks
below.

| Surface | Result | Observation |
| --- | --- | --- |
| Launch / Dashboard | pass | The app remained running and showed coherent intake, overview cards, and tab navigation. |
| Add Drink | pass | The global button opened the picker sheet with a category grid and Cancel control; no drink was created. |
| History | pass | Seeded Yesterday rows were visible in List mode; Calendar mode opened with day states and a selected-day sober summary. |
| Insights | pass | The week control, total, chart, health-impact cards, and tab navigation were visible. |
| Settings | pass | Profile, guideline, preference, and reminder controls rendered coherently. |
| Light appearance | pass | The existing Light preference was visible across the inspected screens. |

Evidence captures are retained under Xcode MCP action artifacts for Dashboard
(`09_55_57_492`), Add Drink (`09_56_10_001`), History list (`09_56_26_981`),
History calendar (`09_56_38_307`), Insights (`09_56_47_985`), and Settings
(`09_57_01_350`). The session could not safely perform the long-press context
menu gesture, change the persisted appearance preference, or observe assistive
technology settings; none of those outcomes is inferred from these captures.

## Human checks — required checkpoint, not complete

The following checks require a complete human visual/accessibility observation.
`unavailable` means the full required observation is not complete, not pass and
not fail. The limited Xcode MCP observations above are retained separately; no
unavailable row is inferred from them.

| Area | Required iOS 27 observation | Status | Reason / protected behavior |
| --- | --- | --- | --- |
| UI-C-03 stable identity — Add Drink | Grid and detail selections remain visibly correct through interaction. | pass | Owner manual verification reported the flow working. |
| UI-C-03 stable identity — History | List/calendar rows visibly retain the correct event after switching. | pass | Owner manual verification reported the flow working; model/event identity and `uuid` behavior remain protected. |
| UI-C-03 stable identity — Onboarding / Settings / Insights | Guideline, picker, comparison, and period selections visibly retain correct state. | pass | Owner manual verification reported the flows working. |
| UI-C-07 Observation owner — Dashboard / History / Insights / Onboarding | Normal seeded state updates preserve screen continuity for each model/view owner pair. | pass | Owner manual verification reported the flows working. |
| History List/calendar | Switching, grouped rows, and load-more behavior. | pass | Owner manual verification reported the flow working; native List/calendar split remains intact. |
| History destructive controls | Long-press context menu, correct-row targeting, confirmation dialog, and VoiceOver actions / labels. | pass | Owner manual verification reported the flow working; deletion remains confirmation-gated. |
| History AX5 | Dynamic Type at AX5 preserves readable, hittable rows. | pass | Owner manual verification reported the flow working; automated AX5 coverage also passed. |
| Insights charts | Drag selection, selected-value callout, hero follow/revert, semantic labels, VoiceOver descriptions, and Audio Graph. | pass | Owner manual verification reported the flow working. The separate Reduce Motion callout check remains open below. |
| Reduce Motion | Callouts do not slide when Reduce Motion is enabled. | pass | Owner verified that the Insights callout does not slide in either mode: it disappears at one selected point and appears at the next. Reduce Motion does not change this discrete behavior. The native Add Drink sheet's system bottom presentation remains animated, which is outside this plan's app-owned chart-callout criterion. |
| Liquid Glass | light and dark appearance contrast plus context-menu preview / zoom behavior. | pass | Owner manual verification reported the flow working; central modifier remains unchanged. |

If a human check fails, preserve the failing observation, identify the smallest affected component, and obtain a fresh owner decision brief before changing any protected source. Do not treat an API's availability as evidence for a correction.

### Owner observation — system sheet presentation under Reduce Motion

With Reduce Motion enabled, the owner observed that opening the Add Drink sheet
still presents it smoothly from the bottom. This is recorded as a **system
presentation behavior observation**, not as a failed Plan 09 check: the plan
requires the app-owned Insights callout not to slide. Apple describes
`accessibilityReduceMotion` as the system preference that tells app UI to avoid
large animations, especially depth-like motion, and separately notes that
standard system components include their own motion and may adapt it to
accessibility settings. No app-owned replacement presentation or transaction
override is authorized from this observation alone. Revisit only if the product
wants a dedicated Reduce Motion audit/decision for system sheet presentation.

### Owner verification — Insights callout under Reduce Motion

The owner verified that the selected-value callout behaves discretely in both
states: when the finger moves to a new point, the old callout disappears and a
new one appears at the next point. It does not glide between points, and
Reduce Motion does not change that behavior. This satisfies the Plan 09
no-callout-slide criterion; no source change is needed.
