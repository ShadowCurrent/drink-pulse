# Phase 09: SwiftUI & Design System Modernization - Research

**Researched:** 2026-09-18
**Domain:** Behavior-preserving SwiftUI and design-system remediation on iOS 27
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

<!-- DATA_V8a4Nq2P_START -->
### Add Drink dismissal ownership
- **D-01:** Replace the custom `@Entry` dismissal closure with standard SwiftUI dismissal access inside the presented Add Drink view where possible. Preserve sheet presentation, navigation, and VoiceOver behavior.
- **D-02:** Add focused UI regression coverage for opening Add Drink and independently exercising cancel and successful-save dismissal; each returns to the originating tab.
- **D-03:** Retain semantic accessibility assertions and add a UI-level check that the dismissal control is reachable and correctly labeled.

### History and Liquid Glass safeguards
- **D-04:** Change History or Liquid Glass production code only for a reproducible iOS 27 defect with focused automated regression evidence or a clear documented human check.
- **D-05:** Keep `List` as the History implementation and make the smallest targeted correction. A List-to-`ScrollView`/lazy-stack rewrite requires a new owner decision brief.
- **D-06:** Retain the existing Liquid Glass layer unless a measured visual, contrast, accessibility, or context-menu interaction defect appears; modify only the affected modifier or component.
- **D-07:** For every approved History correction, verify VoiceOver actions and labels, Dynamic Type through AX5, and Reduce Motion whenever the changed view animates.

### Insights charts and motion
- **D-08:** Change an Insights chart only for a reproducible iOS 27 interaction or accessibility defect with focused regression evidence.
- **D-09:** Preserve drag selection, selected-value callouts, and the Insights hero card's follow/revert behavior exactly.
- **D-10:** Preserve both charts' semantic labels, VoiceOver descriptions, and Audio Graph descriptors; test the changed descriptor path.
- **D-11:** Preserve the existing Reduce Motion rule: callouts do not slide when Reduce Motion is enabled. Add a focused check if animation code changes.

### Verification evidence
- **D-12:** Every approved production change needs focused automated regression plus a documented human check for its affected visual or accessibility behavior.
- **D-13:** The `DPArcProgress` repair must clear iOS 27 Debug and Release builds and pass affected Dashboard regressions; the full suite is not a per-change gate.
- **D-14:** Add one durable Xcode 27 VoiceOver UI test for the Phase 09 flow with the most meaningful behavior change, retaining all existing semantic assertions.
- **D-15:** A retained workaround must record the exact path checked, iOS 27 evidence, protected behavior, and why no replacement is justified.
<!-- DATA_V8a4Nq2P_END -->

### the agent's Discretion

No separate discretion list was recorded. The exact local ownership shape for standard sheet dismissal is discretionary only if it preserves every D-01 through D-03 behavior. [VERIFIED: .planning/phases/09-swiftui-design-system-modernization/09-CONTEXT.md:10-42]

### Deferred Ideas (OUT OF SCOPE)

<!-- DATA_H5z2Lm7Q_START -->
- Proactively simplify or remove Liquid Glass styling in History without a reproduced defect — future design work, outside the evidence-first modernization scope.
- Practical History list filtering — product capability, outside Phase 09.
- Scope custom-name autocomplete by drink category and ABV — product capability, outside Phase 09.
<!-- DATA_H5z2Lm7Q_END -->
</user_constraints>

## Project Constraints (from CLAUDE.md)

- Use SwiftUI only; do not introduce UIKit unless unavoidable. Keep `@Observable` state, SwiftData, Swift Charts, structured concurrency, `NavigationStack`/`NavigationSplitView`, and lightweight environment DI. [VERIFIED: CLAUDE.md:94-102]
- Preserve feature folders and the shared `DesignSystem/`; use `@State private` for view-owned state, `@Bindable` for injected observable bindings, and never introduce `ObservableObject`, `@Published`, `@StateObject`, or `@ObservedObject`. [VERIFIED: CLAUDE.md:153-172]
- Use `String(localized:)` for user-facing strings; keep documentation and comments in English; maintain previews for SwiftUI views. [VERIFIED: CLAUDE.md:188-211]
- Keep production Swift files at or below 300 lines, use no production force unwraps, and fix Swift 6 concurrency warnings at their source. [VERIFIED: CLAUDE.md:198-214] [VERIFIED: CLAUDE.md:272-289]
- Every interactive element needs a meaningful accessibility label; preserve chart descriptors, test Dynamic Type through AX5, honor Reduce Motion, and retain required contrast. [VERIFIED: CLAUDE.md:229-235]
- Do not add network access, third-party SDKs, analytics, telemetry, PII/health-data logging, or secrets. [VERIFIED: CLAUDE.md:240-267]
- Build with zero warnings. Use scoped iOS 27 `xcodebuild test -only-testing:` runs for the changed areas; use the full suite only at its defined escalation/checkpoint conditions. [VERIFIED: CLAUDE.md:272-289] [VERIFIED: CLAUDE.md:535-552]
- A changed user-facing control or flow needs a real XCUITest in the mirrored feature directory; new tests use Swift Testing, while existing XCTest files remain XCTest. [VERIFIED: CLAUDE.md:377-406] [VERIFIED: CLAUDE.md:475-481] [VERIFIED: CLAUDE.md:496-533]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MOD-02 | Users retain navigation, forms, sheets, History and Insights behavior after all approved SwiftUI/design-system replacements are applied and verified. Known platform workarounds are removed only after iOS 27 evidence establishes they are obsolete. | Targeted `DPArcProgress` compilation repair; correct-environment `DismissAction` handoff; focused Add Drink and Dashboard UI tests; a durable VoiceOver test; retain records and human-check gates for History, charts, motion, and Liquid Glass. [VERIFIED: .planning/REQUIREMENTS.md:15-21] |
</phase_requirements>

## Summary

Phase 09 has two evidence-backed production changes: the `DPArcProgress` `Shape` actor-isolation compilation failure and the Add Drink custom-environment closure warning. The Phase 08 baseline established that Debug, Release, and the unfiltered test invocation all stopped at compilation before either test target ran; test counts are unavailable. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md:19-43] Repair the pure `Shape` boundary first, then establish fresh targeted build and UI-test evidence before considering any optional retain record.

For Add Drink, use the standard SwiftUI `DismissAction` obtained at the presented sheet root and pass that value through the Add Drink navigation path instead of storing a custom `@Entry` closure. Apple documents that `dismiss` dismisses the current presentation and that its behavior depends on the environment where it is read; the presented sheet content is the correct owner for a sheet-level action. [CITED: https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/dismiss] The detail destination's own ambient dismissal can pop navigation, so it must not replace the sheet-level action without an explicit behavioral proof. [CITED: https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/dismiss]

History `List`, History context menus, Swift Charts selection/Audio Graph descriptors, Reduce Motion gating, localization, and Liquid Glass are retain-by-default scope. The Phase 08 inventory found no documented replacement or iOS 27 failure for them, and prior History/List and context-menu changes had behavior regressions. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:47-55] A plan may inspect and record their iOS 27 state, but must not schedule a source edit unless it first obtains the D-04/D-08 evidence and, where required, a new owner brief.

**Primary recommendation:** Plan two implementation tasks in dependency order—first the smallest nonisolated `Shape` repair with Debug/Release/Dashboard proof, then standard `DismissAction` propagation plus Add Drink and VoiceOver UI regressions—followed by a verification-only retain-evidence task for protected UI surfaces.

## Phase 08 Candidate Disposition Matrix

| Candidate | Phase 09 disposition | Planning rule |
|-----------|----------------------|---------------|
| UI-C-01 Add Drink custom dismissal entry | Change | Replace only the closure-valued environment entry with a correctly scoped standard `DismissAction`; test cancel and save independently. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:47-48] |
| UI-C-02 `DPArcProgress` shape isolation | Change | Repair only the protocol isolation boundary; preserve arc geometry, animation, and label; clear Debug and Release builds. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:48-48] |
| UI-C-03 `ForEach` identity | Retain | Plan 03 must audit the exact Add Drink (`DrinkDetailInputView.swift`, `DrinkTypeGrid.swift`), History (`HistoryListQueryView.swift`, `HistoryView.swift`, `HistoryCalendarDayDetail.swift` and named identity-bearing components), Onboarding (`OnboardingView.swift`, `GuidelineStep.swift`), Settings (`SettingsView.swift`, `GuidelinePickerSheet.swift`), and Insights (`GuidelineComparisonCard.swift`, `InsightsScopeNavigator.swift`) paths. Preserve model IDs, enum/value domains, bounded constants, and History event `uuid`; the iOS 27 focused-flow evidence and source audit must record why no replacement is justified. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:49-49] |
| UI-C-04 History List/calendar split | Retain | Keep native `List` and separate calendar scroll branch; a rewrite needs a new owner brief and reproduced iOS 27 defect. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:50-50] |
| UI-C-05 History context menu/confirmation | Retain | Preserve correct-row targeting, VoiceOver actions, and destructive confirmation; change only after deterministic iOS 27 evidence. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:51-51] |
| UI-C-06 Insights charts/accessibility | Retain | Preserve selection, labels, and both `AXChartDescriptor` paths; a chart change needs observed interaction/accessibility failure. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:52-52] |
| UI-C-07 Observation ownership | Retain | Plan 03 must audit `DashboardViewModel.swift`/`DashboardView.swift`, `HistoryViewModel.swift`/`HistoryView.swift`, `InsightsViewModel.swift`/`InsightsView.swift`, and `OnboardingViewModel.swift`/`OnboardingView.swift`: retain `@Observable @MainActor` models, their `@State` view owners, and Insights-only `@ObservationIgnored` caches. Record post-repair iOS 27 focused-flow evidence and the no-replacement rationale; no `ObservableObject` migration is authorized. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:53-53] |
| UI-C-08 Reduce Motion animation | Retain | Keep the no-motion behavior and test it if affected animation code changes. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:54-54] |
| UI-C-09 Liquid Glass | Retain | Keep the centralized modifier unless a measured visual, contrast, accessibility, or context-menu defect appears. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:55-55] |
| UI-C-10 Xcode 27 VoiceOver UI testing | Change | Add one durable VoiceOver test to the most meaningful Phase 09 flow; do not replace existing semantic assertions. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:95-115] |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Arc progress rendering and accessibility label | Browser / Client | — | `DPArcProgress` is a SwiftUI `View` and pure drawing `Shape`; its failure is a client-side Swift concurrency boundary. [VERIFIED: drinkpulse/DesignSystem/DPArcProgress.swift:3-50] |
| Add Drink sheet dismissal | Browser / Client | — | SwiftUI presentation state is owned at `RootShellView`'s sheet boundary, while the presented hierarchy must invoke the correct presentation action. [VERIFIED: drinkpulse/Features/Shell/RootShellView.swift:17-80] [VERIFIED: drinkpulse/Features/AddDrink/AddDrinkView.swift:4-16] |
| Add Drink save | Browser / Client | Database / Storage | The form creates a `ConsumptionEvent` via `ModelContext`, then must dismiss only after the established save path. [VERIFIED: drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift:53-73] |
| VoiceOver regression | Browser / Client | — | XCUITest drives and observes assistive-technology behavior in the app UI. [CITED: https://developer.apple.com/documentation/xcuiautomation/xcuivoiceoverservice] |
| History and Insights safeguards | Browser / Client | Database / Storage | Rendering, gestures, selection, and accessibility are client responsibilities; History's query/paging data remains untouched unless a reproduced defect demands a local correction. [VERIFIED: drinkpulse/Features/History/HistoryListQueryView.swift:4-75] [VERIFIED: drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift:20-105] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | Xcode 27 / iOS 27 SDK | Sheets, navigation, `Shape`, rendering, environment actions, accessibility | Project-mandated native UI stack; `DismissAction` is the documented presentation mechanism. [VERIFIED: CLAUDE.md:94-102] [CITED: https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/dismiss] |
| Swift Charts + Accessibility | iOS 27 SDK | Existing chart selection, labels, Audio Graph descriptors | Keep the established native chart implementation; descriptors are the documented way to describe chart content to assistive technologies. [VERIFIED: drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift:21-80] [CITED: https://developer.apple.com/documentation/swiftui/view/accessibilitychartdescriptor(_:)] |
| XCTest/XCUITest | Xcode 27 | Existing screen-flow regression and the required VoiceOver test | Existing UI suites are XCTest; `XCUIVoiceOverService` provides programmatic VoiceOver control through `XCUIDevice`. [VERIFIED: drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift:1-19] [CITED: https://developer.apple.com/documentation/xcuiautomation/xcuivoiceoverservice] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Observation | iOS 27 SDK | Existing state ownership | Retain; the Phase 08 inventory found no `ObservableObject` migration candidate. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:53-53] |
| SwiftData | iOS 27 SDK | Existing Add Drink persistence | Keep the current save path intact; this phase introduces no schema or model change. [VERIFIED: drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift:53-73] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Sheet-root `DismissAction` passed as a value | Detail destination's ambient `@Environment(\\.dismiss)` | The destination action may pop the navigation stack rather than dismiss the enclosing sheet, so it cannot replace the sheet action without passing the save/cancel return-to-tab tests. [CITED: https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/dismiss] |
| Native History `List` plus distinct calendar scroll branch | `ScrollView`/lazy-stack rewrite | Disallowed without a new owner brief; the prior rewrite had grouping, paging, gesture, and Dynamic Type regressions. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C002.md:1-32] |
| Existing Swift Charts and descriptors | New chart API/substitution | No observed interaction/accessibility defect supports a replacement; a change risks labels, selection, and Audio Graph behavior. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C004.md:1-32] |

**Installation:** No packages. This phase must not add dependencies. [VERIFIED: .planning/REQUIREMENTS.md:39-46]

## Package Legitimacy Audit

No external package installation is authorized or needed; package legitimacy checks do not apply. [VERIFIED: .planning/REQUIREMENTS.md:39-46]

## Architecture Patterns

### System Architecture Diagram

```text
User taps Add Drink from a selected tab
        |
        v
RootShellView (.sheet isPresented)
        |
        v
AddDrinkView reads sheet-root DismissAction
        |
        +--> DrinkTypeGridView --navigationDestination--> DrinkDetailInputView
                                                        |
                      cancel --------------------------+----> sheet-root action --> originating tab
                      save --> existing SwiftData mutation --+-> sheet-root action --> originating tab

DashboardView --> DPArcProgress (pure file-scope/nonisolated Shape) --> render + accessibility label

XCUITest --> Add Drink cancel/save and VoiceOver focus/speech --> user-visible outcome
```

### Recommended Project Structure

```text
drinkpulse/
├── DesignSystem/DPArcProgress.swift                 # isolated drawing-boundary repair only
└── Features/AddDrink/
    ├── AddDrinkView.swift                            # sheet-root DismissAction owner
    ├── DrinkTypeGridView.swift                       # passes sheet action through navigation destination
    └── DrinkDetailInputView{,+Logic}.swift           # invokes sheet action after cancel/save

drinkpulseUITests/Features/
├── AddDrink/AddDrinkFlowUITests.swift                # cancel/save sheet regressions
└── Shell/ShellNavigationUITests.swift                # originating-tab and Xcode 27 VoiceOver regression
```

### Pattern 1: Correct-environment sheet dismissal

**What:** Read `DismissAction` in the view that is actually installed as the sheet content, and propagate that typed action to the nested navigation destination that needs to dismiss the whole sheet.

**When to use:** A push destination inside a sheet must close the enclosing sheet after a successful mutation, while its own ambient action could otherwise pop the push.

**Example:**

```swift
// Source: https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/dismiss
struct AddDrinkView: View {
    @Environment(\.dismiss) private var dismissSheet

    var body: some View {
        NavigationStack {
            DrinkTypeGridView(dismissSheet: dismissSheet)
        }
    }
}
```

**Resolved Xcode 27 form:** `DismissAction` is `@MainActor`, conforms to `Sendable`, and exposes `callAsFunction()` in the shipped iPhoneSimulator 27.0 SwiftUI interface at `SwiftUI.swiftinterface:1680-1685,33334`. A no-write `xcrun swiftc -typecheck` run on 2026-09-18 accepted `@Environment(\.dismiss) private var dismissSheet` in `AddDrinkView` and the explicit stored child parameter `let dismissSheet: DismissAction` in both nested views. The execution plan must use that exact typed initializer handoff, invoke it on the main actor, and not introduce a closure or custom environment entry. This preserves the sheet-root ownership documented by Apple. [CITED: https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/dismiss] [VERIFIED: iPhoneSimulator27.0.sdk SwiftUI interface and local typecheck, 2026-09-18]

### Pattern 2: Keep drawing helper independent of view isolation

**What:** Keep a geometry-only `Shape` outside the `View` type's actor-isolated lexical context, or otherwise satisfy the protocol's nonisolated boundary using the smallest compiler-approved form.

**When to use:** Swift 6.4 reports that the current nested shape crosses into main-actor-isolated code.

**Example:**

```swift
private struct ArcShape: Shape {
    let from: Double
    let to: Double

    func path(in rect: CGRect) -> Path {
        // Preserve the current arc math exactly; no rendering redesign.
    }
}
```

The exact path math must remain unchanged unless a Dashboard visual defect is reproduced. The current failure is specifically `ArcShape`'s `Shape` conformance crossing into main-actor-isolated code. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md:34-43]

### Pattern 3: Accessibility-preserving chart retention

**What:** Retain each chart's descriptive `.value` labels, selection binding, semantic label, and `AXChartDescriptorRepresentable` attachment when no defect justifies a change.

**When to use:** Any incidental change reaches an Insights chart or its descriptor.

**Example:**

```swift
Chart(data) { point in
    // Existing marks retain descriptive axis values.
}
.chartXSelection(value: $selectedKey)
.accessibilityChartDescriptor(descriptor)
```

Apple documents `accessibilityChartDescriptor` as the modifier that exposes a chart representation to VoiceOver and other assistive technologies. [CITED: https://developer.apple.com/documentation/swiftui/view/accessibilitychartdescriptor(_:)]

### Anti-Patterns to Avoid

- **Calling the destination-local dismiss action as a sheet replacement:** It can dismiss a current navigation presentation instead of the sheet. Retain a distinct, correctly scoped sheet action. [CITED: https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/dismiss]
- **Moving `ArcShape` to a rendering subsystem or replacing it with Canvas:** The documented baseline asks for an isolation boundary repair, not a drawing rewrite. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md:34-43]
- **List-to-ScrollView rewrite:** Explicitly requires a fresh owner decision brief and is unsupported by current evidence. [VERIFIED: .planning/phases/09-swiftui-design-system-modernization/09-CONTEXT.md:24-29]
- **Changing chart selection, callouts, labels, or descriptors during unrelated work:** Those are protected behavior. [VERIFIED: .planning/phases/09-swiftui-design-system-modernization/09-CONTEXT.md:31-37]
- **Cosmetic Liquid Glass rewrite:** Apple documents performance and container considerations, but that does not establish a DrinkPulse defect. [CITED: https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sheet dismissal | Custom closure-valued environment key | SwiftUI `DismissAction` read in the presented environment | The framework action is scoped to the active presentation; custom closure environment values caused the recorded comparability warning. [CITED: https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/dismiss] [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md:34-43] |
| VoiceOver UI automation | Custom notification/polling harness | `XCUIDevice` VoiceOver service in the existing XCUITest target | Apple supplies focus navigation and speech-output controls for UI tests. [CITED: https://developer.apple.com/documentation/xcuiautomation/xcuivoiceoverservice] |
| Chart accessibility | Hand-authored speech-only substitute | Existing `AXChartDescriptorRepresentable` plus semantic labels | The system uses the descriptor to make a chart accessible to VoiceOver and other assistive technologies. [CITED: https://developer.apple.com/documentation/swiftui/view/accessibilitychartdescriptor(_:)] |

**Key insight:** Phase 09 removes an app-owned warning by adopting the framework's typed presentation action, but it must preserve hierarchy-specific dismissal semantics rather than treating every `dismiss()` as equivalent. [CITED: https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/dismiss]

## Common Pitfalls

### Pitfall 1: Repairing a compiler error by broad rendering replacement

**What goes wrong:** Replacing the arc with a different drawing subsystem changes animation, geometry, or accessibility while obscuring the actual actor-isolation issue.

**Why it happens:** The baseline names a protocol-conformance boundary, not a drawing API deprecation. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md:34-43]

**How to avoid:** Move only the pure `Shape` boundary or apply the smallest compiler-proven nonisolated annotation; preserve arc math, `.animation(_:value:)`, frame, and accessibility label.

**Warning signs:** Debug or Release still emits the `ArcShape` concurrency diagnostic, the Dashboard arc differs visually, or its accessibility label disappears.

### Pitfall 2: Dismissing the wrong presentation

**What goes wrong:** Cancel/save from the pushed detail screen pops to the grid instead of closing Add Drink, or loses VoiceOver focus/order.

**Why it happens:** `DismissAction` is scoped to the environment where it is read. [CITED: https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/dismiss]

**How to avoid:** Capture the sheet-level action at `AddDrinkView`; pass that typed action deliberately to the detail flow; independently test cancel and save from an originating non-Home tab.

**Warning signs:** The Add Drink navigation bar remains after save/cancel, a detail view is revealed instead of the selected tab, or the cancel control has no semantic label.

### Pitfall 3: Treating blocked baseline tests as passing evidence

**What goes wrong:** Retain/change decisions claim an iOS 27 UI test pass even though compilation stopped before tests started.

**Why it happens:** The Phase 08 full suite failed before unit/UI test execution. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md:28-43]

**How to avoid:** Run and record fresh focused commands only after the compiler repair; distinguish automated result from the required human check.

**Warning signs:** A report contains test counts without a post-repair invocation/result bundle, or labels a retained workaround "verified" from Phase 08 alone.

### Pitfall 4: Removing a protected workaround because a newer API exists

**What goes wrong:** History scrolling/context menu, chart accessibility, Reduce Motion, or glass interaction regresses without a reproduced iOS 27 defect.

**Why it happens:** API availability is not evidence that the existing behavior is obsolete. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:10-21]

**How to avoid:** Record the exact tested path, iOS 27 observation, protected behavior, and no-replacement rationale for every retained workaround; require an owner brief before a substantial rewrite.

**Warning signs:** A plan includes `ScrollView`, chart, animation, or glass edits without a repro, focused regression, and documented human check.

## Code Examples

### VoiceOver regression shape

```swift
// Source: https://developer.apple.com/documentation/xcuiautomation/xcuivoiceoverservice
let voiceOver = XCUIDevice.shared.voiceOverService
try voiceOver.enable()
defer { try? voiceOver.disable() }

// Drive the existing Add Drink flow, then assert the focused control's speech
// and the selected tab after cancellation or save.
```

Use this only for the one durable Phase 09 flow required by D-14; retain semantic element assertions as independent coverage. [VERIFIED: .planning/phases/09-swiftui-design-system-modernization/09-CONTEXT.md:39-42]

### Reduce Motion retain guard

```swift
.transition(reduceMotion ? .identity : animatedTransition)
.animation(reduceMotion ? nil : animation, value: selection)
```

This is the current protected pattern for chart callouts; do not alter it without a reproduced defect and focused check. [VERIFIED: drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift:97-105] [VERIFIED: drinkpulse/Features/Insights/Components/WeekdayBarChart.swift:76-87]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom environment closure for an Add Drink sheet action | Standard typed SwiftUI `DismissAction` with correct presentation ownership | Phase 09 | Removes the documented closure-comparability warning while keeping sheet behavior under regression protection. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C001.md:1-28] |
| Generic/implicit chart accessibility | `accessibilityChartDescriptor` backed by `AXChartDescriptorRepresentable` | Existing implementation | Retain descriptor coverage for VoiceOver and Audio Graph. [CITED: https://developer.apple.com/documentation/swiftui/view/accessibilitychartdescriptor(_:)] |

**Deprecated/outdated:**

- No additional deprecated API replacement is authorized in this phase. The Phase 08 inventory records no deprecation claim for the protected History, chart, motion, Observation, or Liquid Glass patterns. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:47-55]

## Planning Resolutions and Execution-Evidence Boundary

### R1: Exact Add Drink typed handoff

The planning-ready implementation is fixed: `AddDrinkView` reads `@Environment(\.dismiss) private var dismissSheet`; `DrinkTypeGridView` and `DrinkDetailInputView` each store `let dismissSheet: DismissAction`; the grid passes the same value through its existing `navigationDestination`; grid/detail cancellation and the final step of `save()` invoke `dismissSheet()`. The local iPhoneSimulator 27.0 interface declares `DismissAction` as `@MainActor` and `Sendable`, and the exact three-view shape typechecked on 2026-09-18. The custom `@Entry` closure and a destination-local dismissal read are outside this resolved handoff. [CITED: https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/dismiss] [VERIFIED: iPhoneSimulator27.0.sdk SwiftUI interface:1680-1685,33334 and local `xcrun swiftc -typecheck`, 2026-09-18]

### R2: Retained-surface disposition after the compiler repair

The post-repair execution result is evidence to record, not a decision required to make the plan executable. UI-C-03 through UI-C-09 have the fixed planning disposition **Retain**; Plan 03 creates their source-scoped iOS 27 evidence rows with a truthful `pass`, `fail`, or `unavailable` result. A recorded failure does not authorize a source edit: it records the smallest affected component and the D-04/D-08 owner-brief gate. UI-C-01, UI-C-02, and UI-C-10 are the only approved change paths and are completely specified in Plans 02, 01, and 02 respectively. Thus no Plan 03 task selects work based on unplanned discovery. [VERIFIED: .planning/phases/09-swiftui-design-system-modernization/09-CONTEXT.md:16-37] [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:47-55,95-115]

### R3: Arc repair boundary

Plan 01 owns one fixed scope: move only the geometry-only `ArcShape` protocol conformance across the strict-concurrency boundary while preserving all drawing and accessibility behavior. Debug/Release builds and `DashboardUITests` are the acceptance evidence; a build failure is recorded as that scoped repair failing, never permission to change Dashboard behavior or expand the phase. [VERIFIED: .planning/phases/09-swiftui-design-system-modernization/09-01-PLAN.md:71-106]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Xcode | Debug/Release build and XCUITest | ✓ | `Xcode 27.0 (27A266a)` | — [VERIFIED: environment probe 2026-09-18] |
| Swift compiler | Strict-concurrency repair | ✓ | `Apple Swift version 6.4 (swiftlang-6.4.0.34.1 clang-2100.3.34.1)` | — [VERIFIED: environment probe 2026-09-18] |
| iOS Simulator | Focused iOS 27 UI evidence | ✓ | iPhone 18 Pro, iOS 27.0 | Select local available UDID at execution time. [VERIFIED: environment probe 2026-09-18] |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest/XCUITest in the checked-in unit and UI targets. [VERIFIED: drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift:1-19] |
| Config file | `drinkpulse.xcodeproj/project.pbxproj`; file-system-synchronized targets need no build-phase registration for correctly placed Swift test files. [VERIFIED: CLAUDE.md:403-406] |
| Quick run command | `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" -only-testing:drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests -only-testing:drinkpulseUITests/Features/Shell/ShellNavigationUITests -only-testing:drinkpulseUITests/Features/Dashboard/DashboardUITests` [VERIFIED: CLAUDE.md:535-552] |
| Full suite command | `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID"` [VERIFIED: CLAUDE.md:535-544] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MOD-02 | Dashboard arc still builds/renders and keeps its accessibility outcome after the isolation repair | build + UI regression | Debug and Release `xcodebuild build`, then scoped `DashboardUITests` | ✅ Dashboard UI suite; confirm the affected arc assertion or add a focused semantic assertion. [VERIFIED: .planning/phases/09-swiftui-design-system-modernization/09-CONTEXT.md:39-41] |
| MOD-02 | Add Drink cancel returns to the originating tab and its control remains reachable/labeled | UI regression + VoiceOver UI test | Scoped `AddDrinkFlowUITests` and `ShellNavigationUITests` | ✅ Existing suites; extend with focused cancel/originating-tab and durable VoiceOver behavior. [VERIFIED: drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift:73-109] |
| MOD-02 | Add Drink save persists the event and dismisses the sheet to the originating tab | UI regression | Scoped `AddDrinkFlowUITests` plus an originating-tab assertion | ✅ Save flow exists; extend the return-to-tab coverage. [VERIFIED: drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift:34-56] |
| MOD-02 | Retained History/list-calendar, context-menu, Insights chart, motion, and glass behavior is not claimed obsolete without proof | focused UI/manual evidence | Run the named existing focused tests only after compilation; document human checks separately | ✅ Existing History/Insights suites; no production edit planned absent a repro. [VERIFIED: .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md:101-115] |

### Sampling Rate

- **Per task commit:** Scoped build and the specific focused UI tests for the edited surface. [VERIFIED: CLAUDE.md:272-289]
- **Per wave merge:** Debug and Release builds after the `DPArcProgress` repair, then the scoped Add Drink/Shell/Dashboard suite.
- **Phase gate:** Every source edit has focused automated evidence plus a documented human visual/accessibility check; do not claim the full suite passed unless it actually ran. [VERIFIED: .planning/phases/09-swiftui-design-system-modernization/09-CONTEXT.md:39-42]

### Wave 0 Gaps

- [ ] Extend an existing Add Drink or Shell UI suite with separately named cancel and save return-to-originating-tab cases.
- [ ] Add one Xcode 27 `XCUIVoiceOverService` regression for the most meaningful Add Drink dismissal flow while retaining semantic assertions.
- [ ] Confirm a Dashboard UI assertion exercises the arc's user-visible/accessibility outcome after the build repair; add a focused assertion only if absent.
- [ ] Create retain-evidence notes for History, charts, motion, and glass only from post-repair simulator/human evidence; no source change is a Wave 0 prerequisite.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No account/authentication surface is in scope. [VERIFIED: CLAUDE.md:1-7] |
| V3 Session Management | no | No remote session is introduced; the phase must not add network access. [VERIFIED: CLAUDE.md:240-251] |
| V4 Access Control | no | This is a local single-user UI flow; no authorization boundary changes. [VERIFIED: CLAUDE.md:1-7] |
| V5 Input Validation | yes | Preserve existing form/input validation and test that save/cancel does not change the wrong flow; no new input parser is needed. [VERIFIED: drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift:53-73] |
| V6 Cryptography | no | No cryptographic behavior is added or changed. [VERIFIED: .planning/REQUIREMENTS.md:39-46] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Save/cancel dismisses the wrong presentation or leaves a persisted event behind | Tampering | Keep the established save path, use sheet-root action ownership, and run independent cancel/save end-to-end tests. [VERIFIED: drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift:53-73] [CITED: https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/dismiss] |
| Accessibility regression hides a dismissal control or changes chart descriptions | Denial of service | Preserve semantic assertions/descriptors and add the required VoiceOver test plus human accessibility check. [VERIFIED: .planning/phases/09-swiftui-design-system-modernization/09-CONTEXT.md:14-42] |
| Test/diagnostic output exposes health data | Information disclosure | Use deterministic non-sensitive fixtures and do not log event contents, notes, body metrics, or timestamps. [VERIFIED: CLAUDE.md:240-267] |
| Context-menu or List rewrite targets the wrong History record | Tampering | Retain current workaround unless a repro and owner-approved local correction meet D-04/D-05/D-15. [VERIFIED: .planning/phases/09-swiftui-design-system-modernization/09-CONTEXT.md:24-29] |

## Sources

### Primary (HIGH confidence)

- [Apple SwiftUI `dismiss`](https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/dismiss) — environment-scoped dismissal behavior and sheet-content example.
- [Apple XCUITest `XCUIVoiceOverService`](https://developer.apple.com/documentation/xcuiautomation/xcuivoiceoverservice) — programmatic VoiceOver control, navigation, and speech output.
- [Apple SwiftUI `accessibilityChartDescriptor`](https://developer.apple.com/documentation/swiftui/view/accessibilitychartdescriptor(_:)) — chart descriptors for assistive technology.
- [Apple Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views) — glass effect/container and rendering considerations.
- [Phase 08 baseline](../08-ios-27-baseline-api-inventory/08-BASELINE.md) — current toolchain, compiler failure, warning, and truthful test-state boundary.
- [Phase 08 UI inventory](../08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md) — candidate dispositions and protected-workaround evidence.

### Secondary (MEDIUM confidence)

- SwiftUI expert skill references for current API, sheets/navigation, lists, animation, accessibility, charts, chart accessibility, Liquid Glass, localization, and soft-deprecation behavior; used as routing guidance only, not as authority for a DrinkPulse replacement. [VERIFIED: /Users/fempter/.agents/skills/swiftui-expert-skill/SKILL.md:1-178]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — project constraints and native Apple API documentation agree; no packages are added.
- Architecture: HIGH — directly grounded in the current sheet, Add Drink, drawing, chart, and test source plus Apple's environment-scoping guidance.
- Pitfalls: HIGH — baseline compiler/test evidence and Phase 08 decision records define the main risks; exact typed handoff and shape repair syntax remain explicitly assumed until compiled.

**Research date:** 2026-09-18
**Valid until:** 2026-10-18, unless Xcode/iOS 27 SDK documentation changes first.
