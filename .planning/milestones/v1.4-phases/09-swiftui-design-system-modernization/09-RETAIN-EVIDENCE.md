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
| Result bundle | `~/Library/Developer/Xcode/DerivedData/drinkpulse-gfnlqrdtxgswbyguxchmqpggiaoy/Logs/Test/Test-drinkpulse-2026.09.19_07-26-24-+0200.xcresult` |
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
| UI-C-09 follow-up (C013) | Retain, container reverted | Owner decision C013, 2026-11-13: the unauthorized Dashboard `GlassEffectContainer` from `553ea58` was removed (`DashboardView.swift` restored to its pre-`553ea58` form, plan 09-08); `DPGlass.swift` and every `glassEffect` consumer unchanged; the whole-screen flicker is not fixed and is deferred (D1). See the section "UI-C-09 follow-up (C013)" below. |

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

## Domain isolation decision — GuidelineLimits (gap closure D3)

**Recorded:** 2026-11-13 (plan 09-04). Closes owner decision D3 and `09-VERIFICATION.md` Warnings 2: commit `7bf6b2a` had added a member-level `nonisolated` to `GuidelineLimits.effectiveDailyGrams` only to make `drinkpulseTests` compile, with a compile-only justification. This section supersedes that note: the cause is now reproduced and the design is chosen deliberately.

**Reproduced diagnostic.** With the accessor in a plain same-module `extension GuidelineLimits` (the pre-`7bf6b2a` form, no call-site edits), `RunSomeTests` on `drinkpulseTests/GuidelineLimitsTests` failed at `Compile GuidelineLimitsTests.swift` (7 errors, all the same message):

`error: main actor-isolated property 'effectiveDailyGrams' can not be referenced from a nonisolated context`

Raw: `build/d3-negative-control.log` (Xcode MCP, `GetBuildLog` severity error; the MCP issue summary capitalizes it as "Main actor-isolated property ...").

**Target-level cause.** `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is set on the app target only; `drinkpulseTests` and `drinkpulseUITests` set neither it nor `SWIFT_APPROACHABLE_CONCURRENCY`, so test code is nonisolated by default. A member declared in a separate extension block is inferred main-actor by the app target's default even when the extended struct is `nonisolated`, so nonisolated test functions cannot read it. A member declared in the struct body inherits the type-level `nonisolated`.

**Apple documentation consulted (Xcode MCP DocumentationSearch, 2026-11-13).** "Build settings reference: Default Actor Isolation" (`SWIFT_DEFAULT_ACTOR_ISOLATION`: "Controls default actor isolation for unannotated code. When set to 'MainActor', `@MainActor` isolation will be inferred by default"). The same search surfaced the SwiftUI protocol pages' statement that a conformance declared in an extension opts out of the inferred isolation while one in the base declaration inherits it, which confirms that declaration context decides isolation. Search for the `nonisolated` declaration modifier returned no dedicated Apple reference page; the modifier's semantics were therefore verified by the reproduction above and the after-change build, not asserted from the search result. Availability: language feature, no OS availability dimension (iOS 27 deployment target unaffected).

**Decision.** Declare `var effectiveDailyGrams: Double` with the identical expression `dailyGrams > 0 ? dailyGrams : weeklyGrams / 7` inside the body of `nonisolated struct GuidelineLimits: Sendable`; delete the extension block and the member-level `nonisolated`.

**Alternatives considered:**

| Option | Verdict | Reason |
| --- | --- | --- |
| (a) Member-level `nonisolated` inside a separate extension (commit `7bf6b2a`) | Rejected, superseded | Compiles, but every future unannotated extension member re-breaks nonisolated callers, and per-member annotation scatters isolation intent. |
| (b) A `nonisolated` extension block | Rejected | Compiles, but no Domain sibling uses it and it keeps a one-member extension. |
| (c) Accessor in the type body (chosen) | Accepted | Inherits the type-level `nonisolated` by construction, matches `CurrencyOption`, `RiskLevel`, and `WeeklySummaryCalculator`, and a member later added to the body cannot silently regress. |
| (d) Main-actor annotation on the unit tests | Rejected | Changes about 20 test functions to hide a Domain value type's isolation and leaves nonisolated production callers (`GuidelineChoice+Limits`) exposed. |

**Measured evidence.** Destination: iPhone 17 (27.2) simulator, Xcode 27.2 toolchain; no other `GuidelineLimits` extension existed (grep over app and both test targets).

| Step | Source | Result |
| --- | --- | --- |
| Debug baseline at HEAD `9889ca7` (app + drinkpulseTests + drinkpulseUITests, 159 SwiftCompile tasks) | Xcode MCP `BuildProject(buildForTesting)` | succeeded; `GetBuildLog` warning severity: 0 entries; 0 Swift warnings |
| Release baseline at HEAD (app) | CLI `xcodebuild` | succeeded; 0 Swift warnings |
| Debug after change (incremental: `GuidelineLimits.swift` and dependents recompiled in app and drinkpulseTests, 76 SwiftCompile tasks) | Xcode MCP `BuildProject(buildForTesting)` | succeeded; `GetBuildLog` warning severity: 0 entries; 0 Swift warnings |
| Release after change (app) | CLI `xcodebuild` | succeeded; 0 Swift warnings |
| Full `drinkpulseTests` unit suite (64 classes, 721 listed tests) | Xcode MCP `RunSomeTests` | `729 tests: 729 passed, 0 failed, 0 skipped`; raw console shows `Suite GuidelineLimitsTests started` and `passed after 0.003 seconds` |

Warning counts, baseline versus after: Debug 0 versus 0 Swift warnings; Release 0 versus 0 Swift warnings. The only warning-text line in any log is the Xcode packaging note below (Debug baseline: 3 lines, one each for app, drinkpulseTests, drinkpulseUITests; Debug after: 2 emitted by that build for the app and drinkpulseTests, plus 1 UITests line carried over unchanged from the baseline build (its target was not rebuilt); Release baseline and after: 1 line each). The after-change Debug build is incremental, so zero warnings for files untouched by the edit rests on the full baseline compile of all three targets; the edit changes no other file.

`nonisolated` occurrences in `GuidelineLimits.swift`: before 2 (struct declaration and the member-level annotation), after 1 (struct declaration only). No calculation or call site changed (`InsightsViewModel`, `DashboardViewModel`, `HistoryCalendarView`, `GuidelineLimitsTests` compile unedited). Commit `7bf6b2a`'s per-member annotation is superseded.

### Owner ratification O1 — packaging warning exception

Ratified by the project owner on 2026-11-13. AGENTS.md requires zero warnings and records no exception; every clean build prints one Xcode packaging note from `appintentsmetadataprocessor`, which is not a Swift compiler diagnostic and cannot be removed at source (the project uses no App Intents; suppression is forbidden by AGENTS.md). The owner accepted this single line as the only tolerated warning.

- Line named in the ratification: `appintentsmetadataprocessor: warning: Metadata extraction skipped. No AppIntents.framework dependency found.`
- Line as measured in this plan's Xcode 27.2 logs: `appintentsmetadataprocessor[<pid>:<tid>] warning: Metadata extraction skipped, no AppIntents.framework dependency found` (process-id prefix, comma and lowercase "no"). Same tool and same note; the wording differs from the ratified text only in punctuation and case, and `GetBuildLog` does not report it as a warning-severity diagnostic (0 entries in every Debug build).
- Precedent: v1.2 `02-VERIFICATION.md` Known Non-Issue (appintentsmetadataprocessor warning), `02-01-SUMMARY.md`, and the `docs/DEVLOG.md` Phase 07 gate entry.
- Rule: this single line is the only tolerated warning; any other warning still fails the gate.
- AGENTS.md was deliberately left unedited by owner instruction.

### Xcode tooling record (owner decision O2)

| Log (`build/`, git-ignored) | Source header |
| --- | --- |
| `d3-debug-base.log` | `xcode-mcp XcodeListWorkspaces BuildProject(buildForTesting=true) GetBuildLog(severity=warning)` |
| `d3-negative-control.log` | `xcode-mcp RunSomeTests(drinkpulseTests/GuidelineLimitsTests) GetBuildLog(severity=error)` |
| `d3-debug-after.log` | `xcode-mcp BuildProject(buildForTesting=true) GetBuildLog(severity=warning)` |
| `d3-unit-after.log` | `xcode-mcp GetTestList RunSomeTests(64 drinkpulseTests classes)` |
| `d3-release-base.log` | `cli-xcodebuild missing-mcp-capability=Release-configuration-selection` |
| `d3-release-after.log` | `cli-xcodebuild missing-mcp-capability=Release-configuration-selection` |

CLI steps: the two Release builds only. Missing capability: Release-configuration selection. How the live schema showed it: `BuildProject` accepts only `workspaceIdentifier` and `buildForTesting`; `XcodeListSchemes` and `XcodeSwitchScheme` select a scheme, not a build configuration; `XcodeListRunDestinations` and `XcodeSwitchRunDestination` select a destination. No other MCP tool builds. Command: `xcodebuild -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Release -destination "platform=iOS Simulator,id=<iPhone 17 27.2 UDID>" CODE_SIGNING_ALLOWED=NO build`. Xcode MCP responded throughout; no timeout occurred. `XcodeListWindows` is not in this session's tool schema, so `XcodeListWorkspaces` (which lists the drinkpulse project) was used for the responsiveness check. `RunAllTests` was not used because the scheme's test plan also holds the 94-test `drinkpulseUITests` target; the unit suite ran through `RunSomeTests` with the 64 class identifiers from `GetTestList` (a target-level identifier was rejected by the tool).

Note on the Environment table above: for gap-closure planning, this record supersedes the "disabled by project configuration" value of the spec-less probe fallback row. The source for the toggle state is `$HOME/.claude/gsd-core/references/specless-probe-fallback.md` section 0 (the toggle defaults ON and any value other than a literal `false` enables it), not an assertion about the configuration. The original 2026-09-19 row text is untouched.

Living-docs audit: `README.md`, `docs/architecture.md`, and `docs/domain.md` contain no `GuidelineLimits` isolation statement (`docs/domain.md` line 310 describes `effectiveDailyGrams` semantics only, unchanged); no update was needed.

## UI-C-09 follow-up (C013, plan 09-09, 2026-11-13)

Appended without editing any earlier row or section; the original `UI-C-09 | Retain` row above stands as recorded on 2026-09-19.

- **Disposition as approved:** Retain, with the container reverted. Owner decision C013 (`.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C013.md`, register row C013), option `revert-container-only`, outcome approve, 2026-11-13. There is no Change at any Liquid Glass layer.
- **Exact paths changed:** `drinkpulse/Features/Dashboard/DashboardView.swift` only (24 lines, restored to the form before commit `553ea58`, production commit `5b95ab7`). No change to `drinkpulse/DesignSystem/DPGlass.swift`, `drinkpulse/Features/Shell/RootShellView.swift`, or any other `glassEffect` consumer. Test-side, two crashing harness methods in `SheetDismissTabSwitchUITests` are skipped in the shared scheme (commit `830dcd6`; code kept).
- **Measured defect:** the earlier 2026-09-19 record found no defect; the later evidence is in `09-FLASH-DIAGNOSIS.md`. Two symptoms, possibly distinct: (1) the owner reports a whole-screen flicker of about 1 second after Add Drink is dismissed and a tab is switched, on the device since iOS 26 and once on the simulator during a harness run (not measured); (2) an intermittent iOS 27 simulator crash (`EXC_BREAKPOINT` in private `DesignLibrary`, `MaterialProviderBox.resolveLayers(in:)`) narrowed to one live glass card on either tab, with a glass-free material variant clean 20 of 20. The classification is C-INCONCLUSIVE; no cure was proposed. The container was shown not to be required for the crash (V1 crashes like HEAD) and the owner reported the flicker persisted after it was added.
- **Protected behavior:** navigation, sheet dismissal returning to the originating tab, VoiceOver, Reduce Motion, context menus, and adjacency spacing of the glass cards (20 pt apart, never merged). The centralized `dpGlassCard` modifier stays as it is.
- **Apple documentation titles (Xcode MCP `DocumentationSearch`, re-checked 2026-11-13):** `glassEffect(_:in:)`, `GlassEffectContainer`, `Glass`, `sheet(isPresented:onDismiss:content:)`, `TabView`, `Tab`. None states a cause, a trap, or an interaction between a sheet and glass in tab content.
- **Status:** the flicker is not fixed and not device-confirmed. D1 is deferred by the owner to the pending todo `.planning/todos/pending/2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md`. This record does not claim the flash is resolved or MOD-02 complete.

Corrected probe-fallback note (append-only; the Environment table row is untouched): the spec-less probe fallback is enabled by default (`$HOME/.claude/gsd-core/references/specless-probe-fallback.md` section 0: any value other than a literal `false` enables it). The "disabled by project configuration" wording in the Environment table described 2026-09-19 only, and the gap-closure planning passes ran the fallback.
