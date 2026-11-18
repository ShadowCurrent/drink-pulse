# Phase 09: SwiftUI & Design System Modernization - Pattern Map

**Mapped:** 2026-09-18
**Files analyzed:** 8 planned modifications
**Analogs found:** 8 / 8 (two are bounded target-continuity patterns; there is no independent `Shape` or VoiceOver-automation implementation in the tracked source tree)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `drinkpulse/DesignSystem/DPArcProgress.swift` | component | transform/rendering | `drinkpulse/DesignSystem/DPArcProgress.swift` | target-continuity |
| `drinkpulse/Features/AddDrink/AddDrinkView.swift` | component | request-response | `drinkpulse/Features/Settings/Components/GuidelinePickerSheet.swift` | role-match |
| `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift` | component | event-driven navigation | `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift` | target-continuity |
| `drinkpulse/Features/AddDrink/DrinkDetailInputView.swift` | component | CRUD | `drinkpulse/Features/History/EditEventView.swift` | role-match |
| `drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift` | utility | CRUD | `drinkpulse/Features/History/EditEventView.swift` | role-match |
| `drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift` | test | request-response UI flow | `drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift` | exact |
| `drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift` | test | event-driven UI flow | `drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift` | exact |
| `drinkpulseUITests/Features/Dashboard/DashboardUITests.swift` | test | request-response UI flow | `drinkpulseUITests/Features/Dashboard/DashboardUITests.swift` | exact |

`RootShellView.swift` is a tracked integration reference, not a planned source edit: it already owns the selected tab and presents `AddDrinkView` as sheet content. No History, Insights, motion, or Liquid Glass production file is in the planned-change list; their existing implementations are protected below.

## Pattern Assignments

### `drinkpulse/DesignSystem/DPArcProgress.swift` (component, transform/rendering)

**Analog:** `drinkpulse/DesignSystem/DPArcProgress.swift` (the target itself is the only tracked `Shape` implementation).
**Required boundary:** repair only the Swift 6 `Shape` isolation conformance reported at this file's line 33. Do not redesign the arc, convert it to Canvas, or change the view's accessibility/animation contract.

**Imports and rendering contract** (lines 1-24):

```swift
import SwiftUI

struct DPArcProgress: View {
    let pct: Double
    let color: Color
    var size: CGFloat = 100
    var strokeWidth: CGFloat = 9

    @State private var hasSettledOnce = false

    var body: some View {
        ZStack {
            ArcShape(from: 0, to: 1)
                .stroke(color.opacity(0.2), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
            if pct > 0 {
                ArcShape(from: 0, to: min(pct, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                    .animation(hasSettledOnce ? .easeOut(duration: 0.4) : nil, value: pct)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(arcLabel)
        .onChange(of: pct) { _, _ in hasSettledOnce = true }
    }
}
```

**Pure geometry to retain verbatim unless a visual defect is reproduced** (lines 33-50):

```swift
private struct ArcShape: Shape {
    let from: Double
    let to: Double

    private static let startDeg = 60.0
    private static let sweepDeg = 240.0

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2 - 1,
            startAngle: .degrees(Self.startDeg + Self.sweepDeg * from),
            endAngle:   .degrees(Self.startDeg + Self.sweepDeg * to),
            clockwise: false
        )
        return p
    }
}
```

**Verification analogue:** extend the existing Dashboard UI suite only if its present semantic coverage is insufficient; see `DashboardUITests.swift` lines 20-37 and 119-172 below. The baseline evidence in `08-BASELINE.md` lines 34-43 requires fresh Debug and Release builds before treating any UI test as post-repair evidence.

---

### `drinkpulse/Features/AddDrink/AddDrinkView.swift` (component, request-response)

**Analog:** `drinkpulse/Features/Settings/Components/GuidelinePickerSheet.swift` (root sheet reads the standard SwiftUI presentation action); integration owner: `drinkpulse/Features/Shell/RootShellView.swift`.

**Standard sheet dismissal and localized cancellation** — copy the environment/action style, not the surrounding `ScrollView` structure (GuidelinePickerSheet.swift lines 1-39):

```swift
import SwiftUI

struct GuidelinePickerSheet: View {
    @Binding var selection: GuidelineChoice
    let sex: BiologicalSex
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            // Sheet content
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .fraction(0.95)])
        .presentationDragIndicator(.visible)
    }
}
```

**Presentation owner that must remain unchanged** (`RootShellView.swift` lines 76-80):

```swift
TabView(selection: $selectedTab) {
    // Each tab's NavigationStack and Add Drink button
}
.sheet(isPresented: $showAddDrink) {
    AddDrinkView()
}
```

**Target-only replacement boundary** (`AddDrinkView.swift` lines 4-16):

```swift
extension EnvironmentValues {
    @Entry var dismissSheet: (() -> Void)? = nil
}

struct AddDrinkView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DrinkTypeGridView()
        }
        .environment(\.dismissSheet, { dismiss() })
    }
}
```

Remove only this closure-valued custom environment path. Read the sheet-level standard `DismissAction` here and pass a compiler-approved typed value through the already-existing Add Drink navigation chain; do not replace the sheet with destination-local dismissal or change `RootShellView` state ownership. The final typed parameter spelling is intentionally a scoped-build decision (Research assumptions A1/A2), not an inferred refactor.

---

### `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift` (component, event-driven navigation)

**Analog:** `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift` (target-continuity); it is the narrow navigation handoff seam between the sheet root and the detail destination.

**Keep selection state, value navigation, title, and root Cancel behavior** (lines 3-20):

```swift
struct DrinkTypeGridView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection: DrinkTypePreset?

    var body: some View {
        DrinkTypeGrid { selection = $0 }
            .navigationTitle(String(localized: "addDrink.title"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selection) { preset in
                DrinkDetailInputView(preset: preset)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel")) { dismiss() }
                }
            }
    }
}
```

Inject/forward only the correctly scoped sheet action to `DrinkDetailInputView`. Keep the local ambient `dismiss` for the grid's own Cancel unless the focused cancel regression proves the typed sheet action is needed there; neither choice authorizes navigation restructuring.

---

### `drinkpulse/Features/AddDrink/DrinkDetailInputView.swift` (component, CRUD)

**Analog:** `drinkpulse/Features/History/EditEventView.swift` (form toolbar, localized actions, persistence-then-dismiss ordering); use it only for the ordinary sheet-level `DismissAction` idiom, not to merge the Add and Edit forms.

**Dependency and state placement to preserve** (`DrinkDetailInputView.swift` lines 4-29):

```swift
struct DrinkDetailInputView: View {
    let preset: DrinkTypePreset

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissSheet) var dismissSheet
    @Environment(\.healthService) var healthService

    @Query private var profiles: [UserProfile]

    @State var volumeMl: Double
    @State var abvValue: Double
    @State var abvValues: [Double]
    @State var count = 1
    // ...
}
```

**Toolbar action pattern** (`EditEventView.swift` lines 151-175):

```swift
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button(String(localized: "action.cancel")) { dismiss() }
    }
    ToolbarItem(placement: .confirmationAction) {
        Button(String(localized: "action.save")) { save() }
    }
}
```

**Target toolbar seam** (`DrinkDetailInputView.swift` lines 117-124):

```swift
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button(String(localized: "action.cancel")) { dismissSheet?() }
    }
    ToolbarItem(placement: .confirmationAction) {
        Button(String(localized: "action.save")) { save() }
    }
}
```

Replace only the custom-environment dependency/action with the typed action passed from the sheet root. Preserve `ModelContext`, `@Query`, health-service injection, all form fields, and `String(localized:)` action labels.

---

### `drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift` (utility, CRUD)

**Analog:** `drinkpulse/Features/History/EditEventView.swift` lines 201-217 (complete mutation before dismissal).

**Save-then-dismiss order to retain** (`EditEventView.swift` lines 201-217):

```swift
private func save() {
    event.category = category
    event.icon = icon
    // Other established edits and Health hook.
    HealthWriteHooks.update(event, in: modelContext, using: healthService)
    dismiss()
}
```

**Actual Add Drink persistence sequence that must remain in order** (`DrinkDetailInputView+Logic.swift` lines 53-72):

```swift
func save() {
    let trimmedNotes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedCustomName = customNameText.trimmingCharacters(in: .whitespacesAndNewlines)
    let event = ConsumptionEvent(
        consumptionDate: date,
        volumeMl: selectedVolumeMl,
        abv: selectedABV,
        quantity: count,
        enteredUnit: unitSystem,
        category: preset.category,
        icon: preset.icon,
        customName: trimmedCustomName.isEmpty ? nil : trimmedCustomName,
        notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
        price: parsedPrice,
        priceCurrency: parsedPrice == nil ? nil : priceCurrency
    )
    modelContext.insert(event)
    RecordDeduplicator.ensureUniqueIdentity(event, in: modelContext)
    HealthWriteHooks.write(event, in: modelContext, using: healthService)
    dismissSheet?()
}
```

Keep event construction, insertion, identity de-duplication, and Health write unchanged; replace only the last custom action invocation with the propagated sheet action. There is no new error-handling pattern in this flow: current simple SwiftData mutations are intentionally view-owned per ADR-0004.

---

### `drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift` (test, request-response UI flow)

**Analog:** the existing suite itself. Extend it in XCTest style; do not create a parallel test framework for an existing XCTest file.

**Fixture and launch convention** (lines 1-19):

```swift
import XCTest

@MainActor
final class AddDrinkFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
        ]
        app.launch()
    }
}
```

**Existing successful-save flow and semantic checks** (lines 36-56):

```swift
func test_fullLogFlow_savedEvent_appearsInHistory() throws {
    launchApp()
    openAddDrinkSheet()

    let wineTile = app.buttons["Wine"]
    XCTAssertTrue(wineTile.waitForExistence(timeout: 10))
    wineTile.tap()
    XCTAssertTrue(app.navigationBars["Wine"].waitForExistence(timeout: 5))

    let customName = "Barolo Riserva"
    typeCustomName(customName)
    save(on: "Wine")

    openHistoryTab()
    XCTAssertTrue(eventButton(containing: customName).waitForExistence(timeout: 10))
}
```

**Existing dismissal assertion helper** (lines 132-140):

```swift
private func save(on detailTitle: String) {
    let saveButton = app.navigationBars[detailTitle].buttons["Save"]
    XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
    saveButton.tap()

    XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5))
}
```

Add a separately named save regression that begins on a non-Home tab, confirms the Save control is reachable by its semantic label, and asserts the selected originating tab's navigation bar remains after the sheet disappears. Retain the current persisted-event assertion; it protects the save path from becoming a dismiss-only success.

---

### `drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift` (test, event-driven UI flow)

**Analog:** the existing suite itself. It is the exact pattern for asserting a sheet returns to the selected tab.

**Originating-tab cancellation regression** (lines 73-97):

```swift
func test_dismissingAddDrink_returnsToPriorTab() throws {
    launchApp()

    let historyTab = app.tabBars.buttons["History"]
    XCTAssertTrue(historyTab.waitForExistence(timeout: 10))
    historyTab.tap()
    XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))

    let addButton = app.buttons["Add Drink"]
    XCTAssertTrue(addButton.waitForExistence(timeout: 5))
    addButton.tap()
    XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 5))

    dismissAddDrinkSheet()

    XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.navigationBars["Add Drink"].exists)
}
```

**Dismissal-control reachability and label assertion** (lines 101-109):

```swift
private func dismissAddDrinkSheet() {
    let cancelButton = app.navigationBars["Add Drink"].buttons["Cancel"]
    XCTAssertTrue(cancelButton.waitForExistence(timeout: 5),
                  "Add Drink sheet should have a Cancel button to dismiss it")
    cancelButton.tap()

    XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5))
}
```

Keep this regression and strengthen it only as necessary for D-02/D-03. There is no tracked `XCUIVoiceOverService` test to copy: add the single D-14 VoiceOver case here (or in the Add Drink suite if that keeps one flow cohesive) using the compiler-confirmed Xcode 27 API shape from `09-RESEARCH.md`, while retaining the independent semantic-element assertions above.

---

### `drinkpulseUITests/Features/Dashboard/DashboardUITests.swift` (test, request-response UI flow)

**Analog:** the existing suite itself. It supplies the Dashboard-level user-visible regressions required after the shared design-system component compiles again.

**Hero semantic assertion** (lines 20-37):

```swift
func test_heroCard_showsSeededConsumptionValue() throws {
    launchApp()
    waitForHome()

    let hero = app.descendants(matching: .any).matching(
        NSPredicate(format: "label BEGINSWITH %@", "Today's Intake")
    ).firstMatch
    XCTAssertTrue(hero.waitForExistence(timeout: 10))

    let heroLabel = hero.label
    XCTAssertTrue(heroLabel.contains("2.0"))
    XCTAssertTrue(heroLabel.contains("std"))
}
```

**Existing Add Drink → Dashboard regression** (lines 80-117):

```swift
func test_loggingDrink_updatesVisibleDrinkCount() throws {
    launchApp()
    waitForHome()
    // Open Add Drink, select Beer, and tap Save.
    XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5))
    XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Drinks: 2"].waitForExistence(timeout: 5))
}
```

Retain these assertions as the Dashboard integration floor. Add a direct arc accessibility assertion only if the existing hero label does not exercise `DPArcProgress`'s own user-visible accessibility outcome after the compiler repair; no chart/motion modernization follows from this test.

## Shared Patterns

### Presentation ownership and navigation

**Sources:** `drinkpulse/Features/Shell/RootShellView.swift` lines 76-80; `drinkpulse/Features/AddDrink/AddDrinkView.swift` lines 8-16; `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift` lines 8-20.

**Apply to:** the four Add Drink production files and their UI tests.

The shell owns `showAddDrink` and `selectedTab`; the presented `AddDrinkView` is the only correct place to obtain its sheet-level SwiftUI action. The detail destination may need that deliberately propagated value because its ambient action belongs to its navigation context. Do not mutate the shell's presentation state from a child or introduce another custom closure environment key.

### Localization and semantic controls

**Sources:** `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift` lines 9-18; `drinkpulse/Features/AddDrink/DrinkDetailInputView.swift` lines 117-124; `drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift` lines 101-109.

**Apply to:** all changed Add Drink controls and tests.

```swift
ToolbarItem(placement: .cancellationAction) {
    Button(String(localized: "action.cancel")) { dismiss() }
}
ToolbarItem(placement: .confirmationAction) {
    Button(String(localized: "action.save")) { save() }
}
```

Keep framework `Button` controls and localized labels. UI tests may query the established English app-rendered labels (`Cancel`, `Save`, `Add Drink`) and must assert the control exists before tapping it.

### Mutation-before-dismissal

**Sources:** `drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift` lines 53-72; `drinkpulse/Features/History/EditEventView.swift` lines 201-217.

**Apply to:** Add Drink save after its typed-action migration.

Persist/update identity and Health hooks before dismissal. Do not move the dismissal earlier, skip the Health hook, or replace this direct simple-mutation pattern with a repository/service.

### XCTest UI-flow structure

**Sources:** `drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift` lines 1-19, 110-140; `drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift` lines 73-109.

**Apply to:** the cancel, save-return-to-originating-tab, and durable VoiceOver regressions.

Use the existing `@MainActor final class ...: XCTestCase`, deterministic launch arguments, 5–10 second `waitForExistence` assertions, and feature-local helpers. Keep assertions focused: sheet disappearance, originating tab navigation bar, control reachability/label, and persisted event are distinct user-visible outcomes.

### Protected History `List` and context-menu behavior — retain, no Phase 09 edit

**Source:** `drinkpulse/Features/History/HistoryListQueryView.swift` lines 38-90.

```swift
List {
    ForEach(rows) { row in
        switch row {
        case .header(_, let title):
            HistoryDayHeaderRow(title: title)
                .historyListRowChrome(insets: Self.headerRowInsets)
        case .event(let event, let position):
            HistoryEventCardRow(
                event: event,
                position: position,
                unitContext: unitContext,
                onEdit: onEditEvent
            )
            .historyListRowChrome(insets: Self.eventRowInsets)
        }
    }
    if hasMore {
        LoadMoreSentinel(onBecomeVisible: onLoadMore)
            .historyListRowChrome(insets: EdgeInsets())
    }
}
.listStyle(.plain)
.scrollContentBackground(.hidden)
.background(Color(.systemGroupedBackground))
```

Do not convert this to `ScrollView`/lazy stacks or alter row identity, row chrome, paging sentinel, or context-menu targeting. A reproducible iOS 27 defect, focused regression, documented human check, and a new owner brief are prerequisites for any production edit.

### Protected chart accessibility and Reduce Motion — retain, no Phase 09 edit

**Sources:** `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift` lines 20-105; `drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift` lines 4-38; `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift` lines 16-86; `drinkpulse/Features/Insights/Components/WeekdayBarChart+Accessibility.swift` lines 4-41.

```swift
.chartXSelection(value: $selectedKey)
.accessibilityLabel(String(localized: "insights.section.areaChart"))
.accessibilityChartDescriptor(AlcoholAreaChartAXDescriptor(data: data, formattedValue: formattedValue))

.transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)))
.animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: selectedKey)
```

Preserve selection, `value` labels, both AX descriptor builders, callout placement, and Reduce Motion's no-slide behavior. No evidence currently permits a chart, descriptor, or animation edit.

### Protected Liquid Glass boundary — retain, no Phase 09 edit

**Source:** `drinkpulse/DesignSystem/DPGlass.swift` lines 17-47.

```swift
extension View {
    func dpGlassCard(_ size: DPGlassSize = .card) -> some View {
        modifier(DPGlassModifier(size: size))
    }
}

private struct DPGlassModifier: ViewModifier {
    let size: DPGlassSize

    func body(content: Content) -> some View {
        content
            .glassEffect(.regular, in: .rect(cornerRadius: size.cornerRadius))
    }
}
```

Keep the centralized modifier and chart-callout styling. A measured visual, contrast, accessibility, or context-menu defect plus focused evidence is required before modifying either modifier or a consumer.

## No Analog Found

| Need | Role | Data Flow | Reason and planning rule |
|---|---|---|---|
| Independent nonisolated `Shape` conformance | component | transform/rendering | `DPArcProgress.swift` is the only tracked `Shape` implementation. Preserve its source-local geometry and choose the smallest compiler-approved isolation boundary through a scoped Debug build; do not invent a rendering subsystem. |
| Xcode 27 `XCUIVoiceOverService` test | test | event-driven UI flow | No tracked production/UI test invokes `voiceOverService` or `XCUIVoiceOverService`. Use the bounded example and official-source guidance already recorded in `09-RESEARCH.md`; compiler-verify the exact API and retain regular semantic assertions independently. |
| Retained-workaround evidence note | documentation | batch verification | D-15 requires a record of exact path, iOS 27 observation, protected behavior, and no-replacement rationale. No canonical Phase 09 filename exists yet; planner should choose a phase-local evidence artifact without scheduling a History/chart/motion/glass source edit. |

## Metadata

**Analog search scope:** `drinkpulse/DesignSystem`, `drinkpulse/Features/AddDrink`, `drinkpulse/Features/Shell`, `drinkpulse/Features/History`, `drinkpulse/Features/Insights`, and mirrored `drinkpulseUITests/Features` directories.
**Files scanned:** 19 tracked Swift sources/tests plus Phase 08 baseline/decision evidence.
**Tracked-source gate:** verified with `git ls-files -- <path>` for every analog and protected source named above; no `.gsd` mirror path is referenced.
**Pattern extraction date:** 2026-09-18.
