# Phase 5: Insights Chart Scrubbing - Pattern Map

**Mapped:** 2026-07-30
**Files analyzed:** 8 (4 modified, 4 new)
**Analogs found:** 8 / 8 (all self-referential — this phase extends existing files directly)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift` (modify) | component | request-response (touch → selection state → render) | itself (existing file, extend in place) | exact |
| `drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift` (new) | component (accessibility adapter) | transform (data → AX descriptor) | pattern from RESEARCH.md Pattern 3 (no existing AXChartDescriptorRepresentable in repo yet) | no-analog (novel to this repo, but RESEARCH.md gives concrete shape) |
| `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift` (modify) | component | request-response (touch → selection state → render) | `AlcoholAreaChart.swift` (sibling chart, same categorical-key + RuleMark pattern applied per D-04) | exact (cross-file, same phase) |
| `drinkpulse/Features/Insights/Components/WeekdayBarChart+Accessibility.swift` (new) | component (accessibility adapter) | transform (data → AX descriptor) | `AlcoholAreaChart+Accessibility.swift` (sibling, identical shape) | exact (cross-file, same phase) |
| `drinkpulse/Features/Insights/Components/InsightsHeroCard.swift` (modify) | component (container/orchestrator) | request-response (owns selection @State, binds to child, formats headline) | itself (existing file, extend in place) | exact |
| `drinkpulseUITests/Features/Insights/InsightsUITests.swift` (modify — add test methods) | test | UI/event-driven (drag gesture → assertion) | existing test methods in same file (`test_areaChartAndWeekdayChart_arePresent`, `heroTotalLabel()` helper) | exact |
| `drinkpulseTests/Features/Insights/AlcoholAreaChartAXDescriptorTests.swift` (new) | test | transform (unit test of descriptor construction) | `InsightsViewModelTests.swift` (same target/folder, XCTest/Swift Testing conventions) | role-match |
| `drinkpulseTests/Features/Insights/WeekdayBarChartAXDescriptorTests.swift` (new) | test | transform | same as above | role-match |

## Pattern Assignments

### `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift` (component, request-response)

**Analog:** itself — current file already has the categorical key infrastructure (`key(for:)`, `dateByKey`) that scrubbing plugs into directly. No new x-scale work needed (confirmed by RESEARCH.md).

**Current imports** (lines 1-2):
```swift
import SwiftUI
import Charts
```

**Existing categorical key pattern to reuse for selection binding** (lines 24-44, 73-79):
```swift
Chart(data) { point in
    AreaMark(
        x: .value(String(localized: "insights.chart.axis.date"), key(for: point.date)),
        y: .value(String(localized: "insights.chart.axis.grams"), point.grams)
    )
    ...
    LineMark(
        x: .value(String(localized: "insights.chart.axis.date"), key(for: point.date)),
        y: .value(String(localized: "insights.chart.axis.grams"), point.grams)
    )
    ...
}

private func key(for date: Date) -> String {
    String(date.timeIntervalSinceReferenceDate)
}

private var dateByKey: [String: Date] {
    Dictionary(uniqueKeysWithValues: data.map { (key(for: $0.date), $0.date) })
}
```

**What to add** (per RESEARCH.md Pattern 1 & 2, D-01/D-02/D-03):
- New `@Binding var selectedKey: String?` parameter (per Open Question 1's recommendation — `AlcoholAreaChart` stays "dumb"/reusable, `InsightsHeroCard` owns the `@State`).
- `.chartXSelection(value: $selectedKey)` on the `Chart(...)`.
- Conditional `RuleMark(x: .value(..., selectedKey))` + `.annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart)))` rendering a `Text` styled with `.dpGlassCard(.chip)` (copy the DPGlass import/usage below).
- `@Environment(\.accessibilityReduceMotion) private var reduceMotion` + gated `.transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.9)))` on the callout (CHART-04, mirrors OnboardingView pattern below).
- `.accessibilityChartDescriptor(...)` attaching the new `AlcoholAreaChartAXDescriptor` (CHART-03).

---

### `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift` (component, request-response)

**Analog:** `AlcoholAreaChart.swift` (sibling — D-04 mandates the identical RuleMark + callout pattern).

**Current imports and chart body** (lines 1-2, 16-24):
```swift
import SwiftUI
import Charts
...
Chart(bars) { bar in
    BarMark(
        x: .value(String(localized: "insights.chart.axis.weekday"), bar.label),
        y: .value(String(localized: "insights.chart.axis.grams"), displayValue(bar))
    )
    .foregroundStyle(color(for: bar.riskLevel))
    .cornerRadius(4)
    .accessibilityLabel("\(bar.label): \(String(format: "%.1f", displayValue(bar))) \(unitLabel)")
}
```
`bar.label` (a `String`, e.g. "Mon") is already the exact plottable x-key — no adaptation needed, same as `AlcoholAreaChart`'s `key(for:)`.

**What to add:**
- Local `@State private var selectedLabel: String?` (WeekdayBarChart has no parent hero element — CONTEXT.md/RESEARCH.md confirm it owns its own selection self-contained within its own card, unlike `AlcoholAreaChart`'s binding-from-parent shape).
- `.chartXSelection(value: $selectedLabel)`.
- Conditional `RuleMark(x: .value(..., selectedLabel))` + `.annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart)))` with `.dpGlassCard(.chip)` callout showing weekday + value only (D-05 — no risk-level text, since `color(for:)` already encodes it visually).
- Same `reduceMotion` gating as `AlcoholAreaChart`.
- `.accessibilityChartDescriptor(...)` attaching `WeekdayBarChartAXDescriptor` (D-09).

---

### `drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift` (new file, component/accessibility adapter, transform)

**Analog:** No existing `AXChartDescriptorRepresentable` in this codebase — this is genuinely new ground (confirmed in RESEARCH.md: "no ADRs directly govern chart interaction"). Use RESEARCH.md's Pattern 3 as the concrete template, closure-based per Open Question 3's recommendation (keeps it previewable/testable without a full `InsightsViewModel`):

```swift
import Accessibility
import Charts

struct AlcoholAreaChartAXDescriptor: AXChartDescriptorRepresentable {
    let data: [ChartPoint]
    let formattedValue: (Double) -> String   // pass vm.formattedValue — reuse, never reformat inline (D-08)

    func makeChartDescriptor() -> AXChartDescriptor {
        let xAxis = AXCategoricalDataAxisDescriptor(
            title: String(localized: "insights.chart.axis.date"),
            categoryOrder: data.map { $0.date.formatted(.dateTime.month(.abbreviated).day()) }
        )
        let maxGrams = data.map(\.grams).max() ?? 0
        let yAxis = AXNumericDataAxisDescriptor(
            title: String(localized: "insights.chart.axis.grams"),
            range: 0...maxGrams,
            gridlinePositions: []
        ) { formattedValue($0) }

        let series = AXDataSeriesDescriptor(
            name: String(localized: "insights.section.areaChart"),
            isContinuous: true,
            dataPoints: data.map { .init(x: $0.date.formatted(.dateTime.month(.abbreviated).day()), y: $0.grams) }
        )
        return AXChartDescriptor(
            title: String(localized: "insights.section.areaChart"),
            summary: nil,
            xAxis: xAxis, yAxis: yAxis, additionalAxes: [], series: [series]
        )
    }
}
```

Attach in `AlcoholAreaChart.swift`'s chart body:
```swift
.accessibilityChartDescriptor(
    AlcoholAreaChartAXDescriptor(data: data, formattedValue: /* injected formattedValue closure */)
)
```
Note: `formattedValue` must be threaded down as a parameter/closure (e.g. `var formattedValue: (Double) -> String`) since `AlcoholAreaChart` currently takes no `InsightsViewModel` reference — keep it a "dumb" view per its existing doc comment ("Pure chart view — no card wrapper").

---

### `drinkpulse/Features/Insights/Components/WeekdayBarChart+Accessibility.swift` (new file, component/accessibility adapter, transform)

**Analog:** `AlcoholAreaChart+Accessibility.swift` (identical shape, sibling of this same phase) — use `AXCategoricalDataAxisDescriptor` for both x and keep y numeric with `bar.label` as the category order and `displayValue(bar)` as the y value, matching the divisor-adjusted display already computed by `displayValue(_:)` (line 47-49 of current file).

---

### `drinkpulse/Features/Insights/Components/InsightsHeroCard.swift` (container/orchestrator, request-response)

**Analog:** itself — current file already wires `vm.formattedValue(vm.periodTotalGrams)` into the headline (lines 20-27); scrubbing extends this exact call site.

**Current header pattern** (lines 17-45):
```swift
private var headerRow: some View {
    HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "insights.hero.total"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(vm.formattedValue(vm.periodTotalGrams))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            ...
        }
        ...
    }
}
```
Body currently instantiates the chart as: `AlcoholAreaChart(data: vm.seriesData, period: vm.period)` (line 10).

**What to add:**
- `@State private var selectedKey: String?` on `InsightsHeroCard` (Open Question 1's recommendation — the hero card is the `@State` owner, `AlcoholAreaChart` receives `$selectedKey` as a `@Binding`).
- Pass binding: `AlcoholAreaChart(data: vm.seriesData, period: vm.period, selectedKey: $selectedKey)`.
- Compute a resolved selection value (grams) from `selectedKey` via the same `dateByKey`/`data.first(where:)` reverse-lookup pattern shown in RESEARCH.md Pattern 1, then swap the headline `Text` between `vm.formattedValue(selectedGrams)` (while scrubbing) and `vm.formattedValue(vm.periodTotalGrams)` (default/on release) — never a force-unwrap; use `if let`.
- Add `.onChange(of: vm.period) { selectedKey = nil }` for D-06 (selection clears on period switch — no VM change, purely local `@State` reset).

---

### `drinkpulseUITests/Features/Insights/InsightsUITests.swift` (test, UI/event-driven)

**Analog:** existing methods and helper in the same file.

**Existing chart-locator + hero-total-reading helpers to reuse** (lines 123-128, 261-266):
```swift
func test_areaChartAndWeekdayChart_arePresent() throws {
    ...
    let areaChart = firstElement(withLabel: "Alcohol Over Time")
    XCTAssertTrue(areaChart.waitForExistence(timeout: 10), ...)
}

private func heroTotalLabel() -> String {
    let candidate = app.staticTexts.matching(
        NSPredicate(format: "label CONTAINS %@", "std")
    ).firstMatch
    return candidate.exists ? candidate.label : ""
}

private func firstElement(withLabel label: String) -> XCUIElement {
    app.descendants(matching: .any).matching(
        NSPredicate(format: "label == %@", label)
    ).firstMatch
}
```

**New test to add** (per RESEARCH.md Pitfall 5 and Validation Architecture): drive the drag with `XCUICoordinate.press(forDuration:thenDragTo:)` on the `areaChart` element (found via the existing `firstElement(withLabel:)` helper), then assert `heroTotalLabel()` changed from the period-total value — mirroring the exact assertion style already used in `test_hero...` tests in this file (e.g. lines ~69-86 comparing `weekTotal` vs a later `heroTotalLabel()` read).

---

### `drinkpulseTests/Features/Insights/AlcoholAreaChartAXDescriptorTests.swift` / `WeekdayBarChartAXDescriptorTests.swift` (new, test, transform)

**Analog:** `drinkpulseTests/Features/Insights/InsightsViewModelTests.swift` — same folder/target, same Swift Testing (`@Test`/`#expect`) conventions per CLAUDE.md Testing section ("Use Swift Testing for new tests").

**Pattern to follow:** construct `AlcoholAreaChartAXDescriptor(data: [ChartPoint], formattedValue: { "\($0) g" })` (a stub closure, no `InsightsViewModel` needed — this is exactly why the closure-based shape from Pattern 3 was chosen), call `.makeChartDescriptor()`, and assert `series.first?.dataPoints.count == data.count` and that each `dataPoints[i].y == data[i].grams`. No SwiftData/ModelContext fixture required (transform is pure).

---

## Shared Patterns

### Glass chip callout background (D-02, D-04)
**Source:** `drinkpulse/DesignSystem/DPGlass.swift` (lines 1-30)
**Apply to:** Both `AlcoholAreaChart.swift` and `WeekdayBarChart.swift` callout views
```swift
enum DPGlassSize {
    case chip   // 16 — badges, tags (14pt corner radius)
    ...
}

extension View {
    func dpGlassCard(_ size: DPGlassSize = .card) -> some View {
        modifier(DPGlassModifier(size: size))
    }
}
```
Usage for the callout: `Text("...").padding(.horizontal, 10).padding(.vertical, 6).dpGlassCard(.chip)` — same call pattern already used for `TrendBadge`-adjacent chip styling elsewhere in the codebase.

### Value formatting — single source of truth (D-01, D-08)
**Source:** `drinkpulse/Features/Insights/InsightsViewModel+Formatting.swift` (lines 7-11)
**Apply to:** Callout `Text` in both charts, hero headline in `InsightsHeroCard`, and both `AXChartDescriptor` `valueDescriptionProvider` closures
```swift
func formattedValue(_ grams: Double) -> String {
    guard let p = profile else { return String(format: "%.0f g", grams) }
    let g = p.guidelineChoice
    return p.alcoholUnit.formattedValue(grams, guideline: g) + " " + p.alcoholUnit.unitLabel(for: g)
}
```
Never format grams inline in a View or AX descriptor — always route through this method (or a closure wrapping it) to keep the visual callout, hero headline, and VoiceOver audio graph in sync.

### Reduce Motion gating (CHART-04)
**Source:** `drinkpulse/Features/Onboarding/OnboardingView.swift` (lines 9, 80, 86-92)
**Apply to:** Both charts' callout appear/disappear
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

Capsule()
    .animation(reduceMotion ? nil : .spring(response: 0.3), value: vm.step)

private func animatedStep(_ action: () -> Void) {
    if reduceMotion {
        action()
    } else {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { action() }
    }
}
```
Per RESEARCH.md Pitfall 4, this pattern gates `.animation`/`withAnimation` only — the callout's `.transition(...)` modifier must ALSO be gated separately: `.transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.9)))`. Both halves are required; gating only one leaves a visible "pop" with Reduce Motion on.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `AlcoholAreaChart+Accessibility.swift` | component/accessibility adapter | transform | No `AXChartDescriptorRepresentable` conformance exists anywhere in the codebase yet — first one in the project. Use RESEARCH.md's Pattern 3 code example (reproduced above) as the template instead of a codebase analog. |
| `WeekdayBarChart+Accessibility.swift` | component/accessibility adapter | transform | Same as above; use `AlcoholAreaChart+Accessibility.swift` (same phase, sibling file) as its analog once written. |

## Metadata

**Analog search scope:** `drinkpulse/Features/Insights/`, `drinkpulse/DesignSystem/`, `drinkpulse/Features/Onboarding/`, `drinkpulseUITests/Features/Insights/`, `drinkpulseTests/Features/Insights/`
**Files scanned:** 8 read directly (AlcoholAreaChart.swift, WeekdayBarChart.swift, InsightsHeroCard.swift, DPGlass.swift, OnboardingView.swift, InsightsChartModels.swift, InsightsViewModel+Formatting.swift, InsightsUITests.swift) + directory listings of drinkpulseTests/Features/Insights and drinkpulseUITests/Features/Insights
**Pattern extraction date:** 2026-07-30
