# Phase 5: Insights Chart Scrubbing - Research

**Researched:** 2026-07-30
**Domain:** Swift Charts interaction (`chartXSelection`), RuleMark/annotation callouts, `AXChartDescriptor` accessibility, `accessibilityReduceMotion`
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Callout shows date + value together (e.g. "Jul 24 — 32 g"), not
  value-only — mirrors the standard Swift Charts RuleMark+annotation
  convention of surfacing both axis dimensions.
- **D-02:** Callout is styled as a glass chip, reusing the existing
  `dpGlassCard(.chip)` token (`DesignSystem/DPGlass.swift`) — same Liquid
  Glass surface already used for `TrendBadge`'s capsule in
  `InsightsHeroCard.swift`. No new design token.
- **D-03:** Callout floats above the `RuleMark` via `.annotation(position:
  .top)`, tracking the touch horizontally (clamped at chart edges) rather
  than sitting in a fixed position.
- **D-04:** WeekdayBarChart gets the identical RuleMark + floating
  glass-chip callout pattern as `AlcoholAreaChart` — not a different
  treatment (e.g. bar highlight only). Consistency across both charts.
- **D-05:** WeekdayBarChart's callout shows weekday + value only (e.g. "Mon
  — 18 g") — no risk-level text appended; the bar's existing risk-level
  color (`color(for:)` in `WeekdayBarChart.swift:45`) already carries that
  signal visually.
- **D-06:** If the user is mid-scrub on `AlcoholAreaChart` and switches
  period (week/month/year/all-time) via `InsightsScopeNavigator`, the
  selection clears immediately — the hero card headline reverts to the new
  period's total rather than attempting to carry a selection onto a
  differently-shaped dataset.
- **D-07:** Backgrounding the app or switching away from the Insights tab
  mid-scrub needs no explicit selection-reset code — selection is
  view-local `@State`, so it's naturally dropped when the view rebuilds
  with fresh data (existing `onChange(of: scenePhase)` / `@Query` refresh
  path already handles this; no special-case required).
- **D-08:** Each `AlcoholAreaChart` audio-graph data point announces date +
  value in the user's display unit (e.g. "July 24, 32 grams" or the
  equivalent in standard drinks/UK units per `profile.alcoholUnit`) —
  reuse `InsightsViewModel+Formatting.formattedValue(_:)` as the single
  source of truth so the audio graph and the visual callout never drift
  apart. No guideline-limit context folded in.
- **D-09:** `WeekdayBarChart` also gets a full `accessibilityChartDescriptor`
  (not just its existing per-bar `accessibilityLabel`) — for consistency
  with the area chart's audio graph, even though the per-bar labels
  already technically satisfy VoiceOver swipe-through access.

### Claude's Discretion
- Exact `@State` ownership/binding shape for scrubbing selection — e.g.
  whether `InsightsHeroCard` owns `@State var selectedDate: Date?` and
  passes a binding down to `AlcoholAreaChart`, or `AlcoholAreaChart` owns
  the selection and exposes it via a callback/binding parameter to satisfy
  CHART-02's "hero card follows touch" requirement. This is implementation
  wiring, not a user-facing decision — resolve during planning per
  ARCHITECTURE.md's "view-local transient UI state" rule.
- Exact `AXChartDescriptor` construction details (series/axis metadata
  types, value formatting glue) for both charts.
- Whether `chartXSelection`'s categorical `String` key type (the existing
  `key(for:)`/`dateByKey` pattern in `AlcoholAreaChart.swift`) needs any
  adaptation to work cleanly with selection binding, or works as-is —
  resolved by this research: no adaptation needed (see Summary).

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope. Also explicitly out of
scope per `.planning/REQUIREMENTS.md`: `chartXSelection(range:)`
chart-range selection (v2+), refactoring the x-axis from categorical
`String` keys to a `Date`-based scale (existing `dateByKey` reverse-lookup
already supports scrubbing without this rework), and any change to
`InsightsViewModel`/`HistoryViewModel` stored state.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-------------------|
| CHART-01 | User can drag across `AlcoholAreaChart` and `WeekdayBarChart` to see the value at the touched point, via native `chartXSelection` + a `RuleMark`/annotation callout styled with existing DesignSystem glass tokens | Pattern 1 & 2 confirm `chartXSelection(value: Binding<String?>)` works directly against the existing categorical `String` keys; Pattern 2 + D-02 confirm the `dpGlassCard(.chip)` callout styling |
| CHART-02 | While scrubbing, the Insights hero card headline follows the selected point's value (formatted through `InsightsViewModel+Formatting`); on release it reverts to the period total | Architectural Responsibility Map + Open Question 1 place this wiring at `InsightsHeroCard`; Pattern 1 shows the binding/lookup flow from selected key → `ChartPoint` → `vm.formattedValue(_:)` |
| CHART-03 | VoiceOver users retain full per-point access via an extended `accessibilityChartDescriptor` — scrubbing is not the only path to the values | Pattern 3 and the System Architecture Diagram's independent path show `AXChartDescriptorRepresentable` is wired via `.accessibilityChartDescriptor(_:)` with no dependency on the drag gesture, satisfying this by construction; D-08/D-09 constraints incorporated |
| CHART-04 | The selection/callout animation honors `accessibilityReduceMotion` | Pitfall 4 documents the two-part gating requirement (both `.animation` and `.transition` must be gated); Code Examples section shows the exact `OnboardingView.swift` pattern to reuse |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

Directives from `./CLAUDE.md` applicable to this phase's implementation:

- **UI**: SwiftUI only, `@Observable` (not `ObservableObject`/`@Published`)
  — already true for `InsightsViewModel`; no new state-management pattern
  should be introduced for the scrubbing selection.
- **Concurrency**: Swift 6 strict concurrency; respect `@MainActor`
  isolation. Chart gesture callbacks and `AXChartDescriptorRepresentable`
  conformances must not introduce concurrency warnings.
- **Architecture**: no repository layer; views query via `@Query`/simple
  mutations; view models are stateless w.r.t. persistence. This phase adds
  **no persistence or `@Query` changes at all** — pure view-local state.
- **File size limit**: 300-line hard ceiling, ~200 target. `AlcoholAreaChart.swift`
  (currently ~121 lines) and `WeekdayBarChart.swift` (~58 lines) have room
  to grow in-place, but the `AXChartDescriptorRepresentable` conformance
  should be split into a `+Accessibility.swift` file per the "Domain types:
  split by responsibility" convention if either file approaches 200 lines.
- **Previews mandatory**: every SwiftUI view needs a preview with mock
  data — both charts already have one; extend to cover the selected state
  if practical, or keep the existing preview and rely on UI tests for the
  selected-state visual.
- **Accessibility (required, not optional)**: every interactive element
  needs a meaningful `accessibilityLabel`; charts need
  `accessibilityChartDescriptor`; Dynamic Type up to AX5; honor
  `reduceMotion`. This phase directly implements the chart-descriptor and
  reduceMotion requirements (CHART-03, CHART-04); the callout's `Text`
  should be verified against Dynamic Type at AX5 (glass chip padding
  should not clip at largest text sizes).
- **Logging & observability**: no PII/health data in logs. Selected chart
  values derive from `ConsumptionEvent` health data — if any debug
  `os.Logger` calls are added around selection state, do not interpolate
  `grams`/`date` at `.public` privacy level.
- **Testing**: minimum 90% line coverage on testable code; every
  user-facing feature requires a `drinkpulseUITests` test (mandatory per
  the "UI tests" section) — this phase's UI test requirement is captured
  in Validation Architecture above and in the source todo
  (`.planning/todos/pending/2026-07-26-scrub-insights-charts-for-per-point-values.md`),
  which explicitly calls out "requires a `drinkpulseUITests` UI test."
- **No force-unwraps** in production code (previews/tests excepted) — the
  `dateByKey[selectedKey]` / `bars.first(where:)` lookups in Pattern 1
  must use `if let`/`guard let`, never `!`.
- **Quality gates**: `xcodebuild build` zero warnings, `xcodebuild test`
  green, no file over 300 lines — all apply unchanged to this phase's
  additions.

## Summary

This phase adds native drag-to-scrub selection to two existing "dumb" chart
views (`AlcoholAreaChart`, `WeekdayBarChart`), wires the selected point's
value into the Insights hero card headline, and extends VoiceOver support
via `accessibilityChartDescriptor` — all using first-party `Charts` and
`Accessibility` framework APIs, no third-party dependencies.

The critical technical question CONTEXT.md flagged — whether
`chartXSelection` works against the app's existing categorical/band
`String`-keyed x-scale (`key(for:)` / `dateByKey`) — resolves cleanly:
`chartXSelection(value:)` is generic over any `Plottable` type, `String`
conforms to `Plottable`, and Swift Charts' nominal/categorical scale
snaps continuous touch positions to the nearest band and returns that
band's exact plotted value through the binding. No adaptation of the
existing `key(for:)`/`dateByKey` pattern is needed — the same reverse
lookup already used for axis labels resolves the selected key back to a
`ChartPoint`/`WeekdayBar`.

The callout is a conditional `RuleMark(x: .value(..., selectedKey))`
paired with `.annotation(position: .top, overflowResolution: .init(x:
.fit(to: .chart), y: .fit(to: .chart)))` — the `overflowResolution`
parameter (iOS 17+) is the mechanism that clamps the floating callout at
chart edges (D-03), not manual geometry math. VoiceOver support is a
`AXChartDescriptorRepresentable` conformance per chart, built from
`import Accessibility` types (`AXChartDescriptor`,
`AXCategoricalDataAxisDescriptor`/`AXNumericDataAxisDescriptor`,
`AXDataSeriesDescriptor`) and attached via `.accessibilityChartDescriptor(_:)`
— entirely independent of the drag gesture, satisfying CHART-03's "not the
only path to the values" requirement by construction. `reduceMotion`
gating reuses the exact ternary pattern already established in
`OnboardingView.swift`.

**Primary recommendation:** Implement selection as view-local `@State`
(owned by `InsightsHeroCard` for the area chart, by `WeekdayBarChart`
itself for the bar chart), bind it via `.chartXSelection(value:)` against
the existing `String` category keys, render the callout as a
`RuleMark` + `.annotation(position: .top, overflowResolution: ...)`
styled with `.dpGlassCard(.chip)`, format all callout/hero text and
`AXChartDescriptor` value strings through the existing
`InsightsViewModel+Formatting.formattedValue(_:)`, and gate the
callout's appear/disappear transition with the established
`@Environment(\.accessibilityReduceMotion)` ternary.

## Architectural Responsibility Map

This is a native SwiftUI/SwiftData app (not a web app), so tiers are
mapped to this project's actual layers (`architecture.md`) rather than a
browser/CDN/API model.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Drag/touch selection tracking | View — view-local `@State` (chart or `InsightsHeroCard`) | — | `chartXSelection` binds to a plain `@State var selection: String?`; REQUIREMENTS.md explicitly forbids VM/persisted stored state for this |
| Selection → hero headline sync (CHART-02) | View — `InsightsHeroCard` | View-local `@State`/binding passed to `AlcoholAreaChart` | CONTEXT.md pins this wiring at `InsightsHeroCard`, the direct parent that already calls `vm.formattedValue(...)` |
| Value formatting (grams → display unit string) | ViewModel (`InsightsViewModel+Formatting`) | View (calls it) | `formattedValue(_:)` is the single source of truth (D-01, D-08); views never format inline |
| Callout visual style | View — `DesignSystem/DPGlass.swift` | — | Reuse `dpGlassCard(.chip)`, no new token (D-02) |
| VoiceOver audio-graph descriptor construction | View — per-chart `AXChartDescriptorRepresentable` conformance | ViewModel (`formattedValue` reused inside the descriptor) | Descriptor built purely from already-loaded `[ChartPoint]`/`[WeekdayBar]`; no new stored state |
| Reduce Motion gating | View — `@Environment(\.accessibilityReduceMotion)` | — | Pure environment read, view-local, matches `OnboardingView.swift:9,80,87` |
| Selection lifecycle on period/scope change (D-06) | View — `@State` reset triggered by `.onChange(of: vm.period)` or natural rebuild | `InsightsScopeNavigator` (the trigger) | No VM involvement; selection is dropped/reset when the parent view re-renders for a new period |

## Standard Stack

### Core
| Framework | Min iOS | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| `Charts` (Swift Charts) | iOS 16 (selection APIs: iOS 17+) | `chartXSelection(value:)`, `RuleMark`, `.annotation(position:overflowResolution:)` | First-party, already the app's only charting framework; project min deployment is iOS 26, far above the iOS 17 selection-API floor `[CITED: developer.apple.com/documentation/swiftui/view/chartxselection(value:)]` |
| `Accessibility` | iOS 14/15 | `AXChartDescriptor`, `AXNumericDataAxisDescriptor`, `AXCategoricalDataAxisDescriptor`, `AXDataSeriesDescriptor` | First-party audio-graph API; requires an explicit `import Accessibility` in the file defining the descriptor `[CITED: developer.apple.com/documentation/accessibility/axnumericdataaxisdescriptor]` |
| `SwiftUI` | — | `@Environment(\.accessibilityReduceMotion)`, `@State`, `Binding` | Already the app's UI framework; no new dependency |

No new packages, no `Package.swift`/SPM changes, no version bump — both
frameworks ship with the SDK already linked by the project (`import
Charts` is already present in both target files).

### Supporting
None. This phase does not introduce any supporting library.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `chartXSelection(value:)` | Hand-rolled `DragGesture` + `chartOverlay`/`GeometryReader` hit-testing | Explicitly rejected in CONTEXT.md/todo — "must feel native iOS 26 — first-party selection API, not a hand-rolled drag gesture." More code, reimplements what the framework already does correctly (nearest-band snapping, coordinate space conversion) |
| `.annotation(overflowResolution:)` for edge clamping | Manual `GeometryReader` + offset math to keep the callout inside chart bounds | `overflowResolution` is the documented first-party mechanism for exactly this (iOS 17+); manual math duplicates framework behavior and is more failure-prone |
| Per-chart `AXChartDescriptorRepresentable` | Relying solely on existing per-mark `accessibilityLabel`s | D-09 explicitly requires the full descriptor even though `WeekdayBarChart`'s per-bar labels already technically work — for audio-graph consistency with the area chart and to satisfy CHART-03 as a chart-level (not gesture-only) capability |

**Installation:** None — both frameworks are already imported in the
target files (`import Charts` at `AlcoholAreaChart.swift:2` and
`WeekdayBarChart.swift:2`). Only `import Accessibility` needs to be added
to whichever new file(s) define the `AXChartDescriptorRepresentable`
conformances.

**Version verification:** Not applicable — no package registry lookup
needed (first-party Apple SDK frameworks, not distributed via SPM/CocoaPods/npm).
Availability was cross-checked against Apple's own documentation URLs
(`developer.apple.com/documentation/...`) via web search rather than a
package registry.

## Package Legitimacy Audit

**Not applicable to this phase.** No external packages (SPM, CocoaPods,
or otherwise) are installed. All APIs used (`Charts`, `Accessibility`,
`SwiftUI`) are first-party Apple frameworks already linked by the Xcode
project. The Package Legitimacy Gate protocol is skipped — there is
nothing to run `npm view`/`pip index`/`cargo search` against.

## Architecture Patterns

### System Architecture Diagram

```
Touch/drag input
      │
      ▼
Chart(...) { AreaMark/LineMark or BarMark }
      │  .chartXSelection(value: $selectedKey)   ← framework does hit-testing,
      │                                             nearest-band snap, coord conversion
      ▼
selectedKey: String?   (view-local @State)
      │
      ├──► dateByKey[selectedKey] / bars.first(where: label == selectedKey)
      │        │
      │        ▼
      │    resolved ChartPoint / WeekdayBar
      │        │
      │        ▼
      │    vm.formattedValue(point.grams)  ──────────┐
      │        │                                     │
      │        ▼                                     ▼
      │  RuleMark(x: selectedKey)              InsightsHeroCard headline
      │    .annotation(position: .top,          (CHART-02: follows touch,
      │      overflowResolution: .fit(to: .chart))    reverts to vm.periodTotalGrams
      │    { glass-chip callout Text }                 on release/nil selection)
      │
      └──► on selectedKey == nil (touch released, OR
              vm.period changes via InsightsScopeNavigator, D-06):
              hero headline reverts to vm.formattedValue(vm.periodTotalGrams)

Independent path (no gesture required, CHART-03):
Chart(...)
      │  .accessibilityChartDescriptor(ChartDescriptor(data: ...))
      ▼
AXChartDescriptorRepresentable.makeChartDescriptor()
      │  xAxis: AXCategoricalDataAxisDescriptor(categoryOrder: [String])
      │  yAxis: AXNumericDataAxisDescriptor(range:, valueDescriptionProvider:)
      │  series: AXDataSeriesDescriptor(dataPoints: [.init(x:,y:)])
      │  — each value formatted via vm.formattedValue(_:), same fn as callout
      ▼
VoiceOver audio graph (swipe-accessible, no drag needed)
```

### Recommended Project Structure
No new folders. Additions land inside the existing `Features/Insights/`
tree:
```
Features/Insights/
├── Components/
│   ├── AlcoholAreaChart.swift        # + @State selection, RuleMark, annotation
│   ├── AlcoholAreaChart+Accessibility.swift   # NEW — AXChartDescriptorRepresentable (keeps main file <300 lines)
│   ├── WeekdayBarChart.swift         # + @State selection, RuleMark, annotation
│   ├── WeekdayBarChart+Accessibility.swift    # NEW — same pattern
│   └── InsightsHeroCard.swift        # + binding/callback wiring for CHART-02
```
Per CLAUDE.md's file-splitting convention ("Domain types: split by
responsibility... e.g. `Foo+Validation.swift`"), the `AXChartDescriptorRepresentable`
conformance for each chart should live in its own `+Accessibility.swift`
extension file rather than growing the chart view file past the 200-line
target — the descriptor struct plus its `makeChartDescriptor()` body is
~25-40 lines on its own.

### Pattern 1: Selection binding against an existing categorical key
**What:** `.chartXSelection(value: Binding<String?>)` bound to the same
`String` type already plotted via `.value(..., key(for: point.date))`.
**When to use:** Any Swift Charts view using a nominal/categorical
(band) x-scale, which is what both `AlcoholAreaChart` and
`WeekdayBarChart` already use.
**Example:**
```swift
// Source: pattern synthesized from developer.apple.com/documentation/swiftui/view/chartxselection(value:)
// and swiftwithmajid.com/2023/07/18/mastering-charts-in-swiftui-selection/
struct AlcoholAreaChart: View {
    let data: [ChartPoint]
    let period: InsightsPeriod
    @Binding var selectedKey: String?   // or @State, owned per D-06/discretion note

    private var chart: some View {
        Chart(data) { point in
            AreaMark(x: .value(..., key(for: point.date)), y: .value(..., point.grams))
            LineMark(x: .value(..., key(for: point.date)), y: .value(..., point.grams))

            if let selectedKey, let date = dateByKey[selectedKey],
               let point = data.first(where: { key(for: $0.date) == selectedKey }) {
                RuleMark(x: .value(..., selectedKey))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .annotation(
                        position: .top,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        calloutView(date: date, grams: point.grams)
                    }
            }
        }
        .chartXSelection(value: $selectedKey)
        // ...existing axis/scale modifiers unchanged
    }
}
```

### Pattern 2: RuleMark + floating glass-chip callout (D-02, D-03)
**What:** Conditional `RuleMark` rendered only while a selection exists,
annotated with a `Text` styled via `.dpGlassCard(.chip)`.
**When to use:** Both charts, per D-04 (identical treatment).
**Example:**
```swift
// Source: pattern synthesized from Apple's annotation(position:overflowResolution:) docs
// (developer.apple.com/documentation/charts/chartcontent/annotation(position:alignment:spacing:overflowresolution:content:))
private func calloutView(date: Date, grams: Double) -> some View {
    Text("\(date, format: .dateTime.month(.abbreviated).day()) — \(vm.formattedValue(grams))")
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .dpGlassCard(.chip)
        .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.9)))
}
```

### Pattern 3: `AXChartDescriptorRepresentable` for full VoiceOver parity
**What:** A struct conforming to `AXChartDescriptorRepresentable`,
attached via `.accessibilityChartDescriptor(_:)`, independent of the
drag gesture.
**When to use:** Both charts (D-09 requires it even for `WeekdayBarChart`,
which already has per-bar labels).
**Example:**
```swift
// Source: pattern synthesized from createwithswift.com/making-charts-accessible-with-swift-charts/
// and developer.apple.com/documentation/accessibility/axnumericdataaxisdescriptor
import Accessibility

struct AlcoholAreaChartAXDescriptor: AXChartDescriptorRepresentable {
    let data: [ChartPoint]
    let formattedValue: (Double) -> String   // pass vm.formattedValue to avoid drift (D-08)

    func makeChartDescriptor() -> AXChartDescriptor {
        let xAxis = AXCategoricalDataAxisDescriptor(
            title: String(localized: "insights.chart.axis.date"),
            categoryOrder: data.map { $0.date.formatted(.dateTime.month().day()) }
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
            dataPoints: data.map { .init(x: $0.date.formatted(.dateTime.month().day()), y: $0.grams) }
        )
        return AXChartDescriptor(
            title: String(localized: "insights.section.areaChart"),
            summary: nil,
            xAxis: xAxis, yAxis: yAxis, additionalAxes: [], series: [series]
        )
    }
}

// Attached: AlcoholAreaChart's `chart` view adds
// .accessibilityChartDescriptor(AlcoholAreaChartAXDescriptor(data: data, formattedValue: vm.formattedValue))
```
Note: exact axis-value key choice (date-string vs. the numeric `key(for:)`
timestamp key) and per-point date/value phrasing (D-08: "July 24, 32
grams") are Claude's-discretion construction details per CONTEXT.md —
this example shows the shape, not the final wording.

### Anti-Patterns to Avoid
- **Hand-rolled `DragGesture` + `chartOverlay` hit-testing:** explicitly
  out — CONTEXT.md and the source todo both call for the native
  `chartXSelection` API, not a manual gesture recognizer computing plot
  coordinates.
- **Storing selection in `InsightsViewModel`:** explicitly out of scope
  per REQUIREMENTS.md — selection must stay view-local `@State`.
- **Formatting callout/AX text inline instead of via `formattedValue(_:)`:**
  explicitly called out in D-01/D-08 as the failure mode that causes the
  audio graph and visual callout to drift apart over time.
- **Applying `overflowResolution` only to `x` and forgetting `y`:** several
  community threads show annotations popping outside the plot vertically
  even when `x: .fit(to: .chart)` is set alone — pass both axes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Touch-to-nearest-data-point mapping | Manual `GeometryReader` + `chartOverlay` + pixel-to-value math | `chartXSelection(value:)` | Framework already does nominal-scale snapping and coordinate-space conversion correctly; a hand-rolled version is explicitly what CONTEXT.md rejects |
| Callout edge-clamping | Manual offset/width calculations in a `GeometryReader` | `.annotation(overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart)))` | First-party iOS 17+ API built for exactly this; less code, matches platform behavior other apps use |
| VoiceOver per-point audio narration | Custom `AVSpeechSynthesizer`/manual swipe-focus ordering | `AXChartDescriptorRepresentable` + `.accessibilityChartDescriptor(_:)` | This *is* VoiceOver's audio-graph feature (Rotor "Audio Graph"); reinventing it would both duplicate system behavior and likely conflict with it |

**Key insight:** Every capability this phase needs (selection,
edge-aware callout positioning, and audio-graph accessibility) has a
first-party Swift Charts / Accessibility API purpose-built for it,
released between iOS 14 and iOS 17 — all comfortably below this
project's iOS 26 floor. The engineering risk in this phase is wiring
existing app formatting/state through those APIs correctly, not building
new interaction primitives.

## Common Pitfalls

### Pitfall 1: `chartXSelection`'s selected `String` not resolving to a data point
**What goes wrong:** After adding `.chartXSelection(value: $selectedKey)`,
the callout doesn't appear or the hero card doesn't update because the
selected `String` never matches a key in `dateByKey`.
**Why it happens:** If the selection binding's generic type doesn't
exactly match the plotted `.value(...)` type (e.g. binding `Date?`
against a `String`-keyed axis, or vice versa), the framework either
fails to compile or silently never produces a match.
**How to avoid:** Bind `Binding<String?>` — the exact same type already
returned by `key(for:)` — never introduce a parallel `Date?` selection
type.
**Warning signs:** Callout `RuleMark` never renders during manual
testing despite the drag gesture visibly tracking.

### Pitfall 2: `overflowResolution` not applied to both axes
**What goes wrong:** Callout still clips or pops outside the chart
frame near the left/right or top edge.
**Why it happens:** `overflowResolution` takes an `x` and a `y`
resolution independently; setting only one leaves the other axis
unclamped. `[CITED: developer.apple.com/documentation/charts/annotationoverflowresolution]`
**How to avoid:** Always pass `.init(x: .fit(to: .chart), y: .fit(to: .chart))`
for a fully edge-safe floating callout, and verify visually on-device at
both extremes (first and last data point) per the swift community
reports of inconsistent behavior when combined with other chart
modifiers (Apple Developer Forums threads 737244, 741642).
**Warning signs:** Callout visible mid-chart but clipped/hidden when
scrubbing to the first or last bar/point.

### Pitfall 3: AX descriptor drifting from visual formatting
**What goes wrong:** VoiceOver announces a different unit or rounding
than the visible callout/hero card (e.g. announces raw grams while the
UI shows standard drinks).
**Why it happens:** Writing a separate, ad-hoc string inside
`AXNumericDataAxisDescriptor`'s `valueDescriptionProvider` instead of
reusing `vm.formattedValue(_:)`.
**How to avoid:** D-08 already mandates reuse — pass
`vm.formattedValue` (or a closure wrapping it) into the descriptor
struct rather than formatting inline.
**Warning signs:** Manual VoiceOver testing reveals a number that
doesn't match what's on screen.

### Pitfall 4: Reduce Motion only suppresses the callout's `.animation`, not its `.transition`
**What goes wrong:** With Reduce Motion on, the callout still appears to
"pop"/scale because the *insertion* transition (`.transition(...)`) is
independent from an `.animation(...)` modifier — muting one doesn't mute
the other.
**Why it happens:** SwiftUI transitions and animations are separate
mechanisms; `OnboardingView`'s existing pattern (`reduceMotion ? nil :
.spring(...)` on `.animation(value:)`) covers value-driven animations,
but an appearing/disappearing view also needs its `.transition(...)`
swapped to `.identity` (or `.opacity` only, per accessibility guidance)
when `reduceMotion` is true.
**How to avoid:** Gate both: wrap the state change causing the callout
to appear/disappear in `withAnimation(reduceMotion ? nil : .spring(...))`
*and* set `.transition(reduceMotion ? .identity : .opacity.combined(with: .scale(...)))`
on the callout view itself (CHART-04).
**Warning signs:** UI test or manual QA with Reduce Motion enabled still
shows a sliding/scaling callout.

### Pitfall 5: Simulating the scrub gesture in XCUITest
**What goes wrong:** A UI test written with `element.tap()` never
triggers `chartXSelection`, and a naive `swipeLeft()`/`swipeRight()` may
move too fast for the drag gesture recognizer to register per-frame
selection updates.
**Why it happens:** `chartXSelection`'s default gesture on iPhone is a
plain `DragGesture` — a real touch-down-then-move, not a single tap or a
flick-style swipe. `[ASSUMED — training knowledge; not independently
verified via an Apple source this session; iPad's chartXSelection
gesture may differ since iPad supports hover, but that's out of scope
for this iPhone-first app]`
**How to avoid:** Drive selection in `drinkpulseUITests` using
`XCUICoordinate.press(forDuration:thenDragTo:)` (already the standard
XCUITest pattern for simulating a drag), starting from a coordinate
inside the chart element and dragging to another coordinate inside it;
assert on the resulting hero-total text change (mirrors the existing
`heroTotalLabel()` helper pattern in `InsightsUITests.swift`) rather than
asserting on the callout's exact position.
**Warning signs:** UI test never observes the callout text or a hero-total
change despite `chartXSelection` working correctly in manual testing.

## Code Examples

### Existing formatting entry point (must be reused, not duplicated)
```swift
// Source: drinkpulse/Features/Insights/InsightsViewModel+Formatting.swift:7-11 (already in repo)
func formattedValue(_ grams: Double) -> String {
    guard let p = profile else { return String(format: "%.0f g", grams) }
    let g = p.guidelineChoice
    return p.alcoholUnit.formattedValue(grams, guideline: g) + " " + p.alcoholUnit.unitLabel(for: g)
}
```

### Existing reduceMotion pattern (must be reused, not reinvented)
```swift
// Source: drinkpulse/Features/Onboarding/OnboardingView.swift:9,80,86-92 (already in repo)
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

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual `DragGesture` + `chartOverlay` + `ChartProxy.value(atX:as:)` hit-testing for chart selection | `.chartXSelection(value:)` | iOS 17 (WWDC23) | Selection gesture, nearest-value snapping, and coordinate conversion are handled by the framework; drastically less code than the iOS 16-era `chartOverlay` pattern |
| Manual geometry math to keep annotations inside chart bounds | `.annotation(overflowResolution:)` | iOS 17 (WWDC23) | Declarative edge-clamping instead of `GeometryReader` offset math |

**Deprecated/outdated:** None specific to this phase — both
`chartXSelection` and `overflowResolution` are the current (not
soft-deprecated) recommended APIs as of iOS 26 / the current Swift Charts
version shipped in Xcode 26.6 (confirmed installed in this environment).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `chartXSelection`'s default gesture on iPhone is a plain drag (touch-down-then-move), not requiring long-press | Pitfall 5 / Code Examples | If wrong, the recommended `press(forDuration:thenDragTo:)` UI test pattern and/or manual QA expectations would need adjustment (e.g. adding a long-press hold before drag) |
| A2 | Nominal/categorical scale selection always snaps to the *nearest* band and never returns an intermediate/interpolated key that fails to match `dateByKey` | Pattern 1, Pitfall 1 | If the framework ever returns a non-matching key (e.g. during fast drags or at exact band boundaries), the callout/hero sync would intermittently fail to update — mitigate with a UI test that drags to several points across the chart width, not just one |
| A3 | Exact axis-value phrasing/type choice for `AXCategoricalDataAxisDescriptor.categoryOrder` (date-formatted string vs. the numeric `key(for:)` timestamp) has no functional difference for VoiceOver | Pattern 3 | Low risk — cosmetic; if VoiceOver reads the raw timestamp-derived key instead of a human date, it would need reformatting, not a redesign |

**Confirmed via cross-checked sources (not in this table):** the
`chartXSelection<P>(value: Binding<P?>) where P: Plottable` signature,
`String`'s `Plottable` conformance, the `AXChartDescriptorRepresentable`
protocol shape, and `AnnotationOverflowResolution`'s `.fit(to: .chart)`
case were each confirmed against an Apple `developer.apple.com`
documentation URL surfaced via web search (title/URL confirmed; full
body not fetchable in this session's tooling) cross-referenced against
at least one independent third-party code example — tagged `[CITED]`
throughout, not `[ASSUMED]`.

## Open Questions (RESOLVED)

1. **RESOLVED** (05-01-PLAN.md) — Exact `@State` ownership split between `InsightsHeroCard` and `AlcoholAreaChart`
   - What we know: CONTEXT.md explicitly defers this to planning
     ("Claude's Discretion" — whether `InsightsHeroCard` owns
     `@State var selectedDate: Date?` and passes a binding down, or
     `AlcoholAreaChart` owns it and exposes a callback/binding parameter).
   - What's unclear: Which shape keeps `AlcoholAreaChart` reusable
     elsewhere without a mandatory hero-card dependency, vs. which
     minimizes prop-drilling.
   - Recommendation: Have `AlcoholAreaChart` own `@Binding var selection:
     String?` (caller-provided), with `InsightsHeroCard` as the actual
     `@State` owner — keeps `AlcoholAreaChart` a "dumb"/reusable view (as
     it is today) while satisfying CHART-02's "hero card follows touch"
     requirement without new VM state. Planner should confirm this
     shape as a discrete task.

2. **RESOLVED** (05-01-PLAN.md) — Whether `WeekdayBarChart`'s callout needs edge-clamping given only 7 discrete bars
   - What we know: D-04 mandates the identical RuleMark+annotation
     pattern as the area chart, including presumably `overflowResolution`.
   - What's unclear: With only 7 fixed-width bars (vs. the area chart's
     variable point count), whether the callout ever actually needs
     clamping in practice, or whether it's included purely for pattern
     consistency.
   - Recommendation: Include `overflowResolution` on both charts
     regardless (D-04 says identical treatment) — the cost is one extra
     parameter, and it guards against future data changes (e.g. adding
     more categories).

3. **RESOLVED** (05-02-PLAN.md) — `AXChartDescriptorRepresentable` file placement and struct naming
   - What we know: Should reuse `vm.formattedValue` and live in a
     `+Accessibility.swift` extension file per file-size rules.
   - What's unclear: Whether the descriptor struct takes the
     `InsightsViewModel` directly or just a formatting closure + raw
     data (looser coupling, easier to preview/test).
   - Recommendation: Prefer the closure-based shape shown in Pattern 3
     (`formattedValue: (Double) -> String`) — keeps the descriptor
     testable without a full `InsightsViewModel`/`ModelContext` fixture.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / iOS SDK (`Charts`, `Accessibility` frameworks) | All of CHART-01..04 | Yes | Xcode 26.6, build 17F113 | — |
| iPhone 17 Pro Simulator (CLAUDE.md's standard build/test destination) | Manual verification, `xcodebuild test` | Yes | Booted, available | iPhone 17 / 17 Pro Max / 17e also present |
| VoiceOver (on-device or Simulator Accessibility Inspector) | CHART-03 manual verification | Not probed by this research (requires interactive device state) | — | Use Xcode's Accessibility Inspector audit + Simulator VoiceOver for the end-of-phase manual check |

No missing dependencies. This phase has no network, database, or CLI
tool dependency beyond the Xcode toolchain already used by every other
phase in this project.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (`drinkpulseTests`) + XCUITest (`drinkpulseUITests`) — both already configured, `PBXFileSystemSynchronizedRootGroup`s |
| Config file | None — scheme-driven via `xcodebuild test -scheme drinkpulse` |
| Quick run command | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseUITests/InsightsUITests` |
| Full suite command | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CHART-01 | Dragging across `AlcoholAreaChart`/`WeekdayBarChart` shows a callout with the touched value | UI (XCUITest, `press(forDuration:thenDragTo:)`) | `xcodebuild test ... -only-testing:drinkpulseUITests/InsightsUITests` | ❌ Wave 0 — new test method needed in `InsightsUITests.swift` |
| CHART-02 | Hero card headline follows scrub, reverts to period total on release | UI (XCUITest) + unit (if selection→display logic is extracted into a testable helper) | same as above | ❌ Wave 0 |
| CHART-03 | `accessibilityChartDescriptor` exposes every point without requiring the drag gesture | Unit test of `AXChartDescriptorRepresentable.makeChartDescriptor()` output (dataPoints count/values match input) | `xcodebuild test ... -only-testing:drinkpulseTests/Features/Insights` | ❌ Wave 0 — new `AlcoholAreaChartAXDescriptorTests.swift` / `WeekdayBarChartAXDescriptorTests.swift` |
| CHART-04 | Reduce Motion suppresses the callout's appear/disappear transition | Manual verification (Simulator Settings → Accessibility → Reduce Motion) — SwiftUI `.transition`/`.animation` behavior under `reduceMotion` is not practically assertable via XCUITest (no visual-diff harness in this project) | Manual, documented in phase verification notes | N/A — manual-only, matches existing project precedent (`OnboardingView`'s reduceMotion path also has no dedicated UI test) |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests/Features/Insights -only-testing:drinkpulseUITests/InsightsUITests`
- **Per wave merge:** Full suite (`xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`)
- **Phase gate:** Full suite green + coverage ≥90% overall (100% for any new `Domain/`-layer code, though this phase adds none — all new code is View/ViewModel-adjacent) before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] New test methods in `drinkpulseUITests/Features/Insights/InsightsUITests.swift` covering CHART-01/CHART-02 (drag-to-scrub, hero total follows/reverts)
- [ ] New unit test file(s) `drinkpulseTests/Features/Insights/AlcoholAreaChartAXDescriptorTests.swift` and `WeekdayBarChartAXDescriptorTests.swift` covering CHART-03 (descriptor point count/value correctness)
- [ ] No new shared fixtures needed — `InsightsDataGenerator.previewEvents(days:)` and the existing `-dp_uitest_dataset multiday` seed already provide multi-point data for both chart types

*Framework install: none — XCTest/XCUITest already fully configured.*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | No auth in this app (no accounts per CLAUDE.md) |
| V3 Session Management | No | N/A |
| V4 Access Control | No | Single-user, on-device only |
| V5 Input Validation | No | This phase reads already-validated `ConsumptionEvent`-derived data (`ChartPoint`/`WeekdayBar`); no new user text/numeric input is introduced — scrubbing only *reads* existing formatted values |
| V6 Cryptography | No | No new cryptographic operation |

**No ASVS category is materially applicable to this phase.** The
capability is purely a read-only, on-device UI interaction over data
that has already passed through the app's domain calculations and
`formattedValue(_:)` formatting layer — there is no new trust boundary,
no new persisted or transmitted data, and no new parsing of untrusted
input. Per CLAUDE.md's privacy/logging standards, the only carry-over
concern is: do not log selected chart values (they derive from health
data) — `os.Logger` calls, if any are added for debugging, must not
interpolate `grams`/`date` values at `.public` privacy level.

### Known Threat Patterns for this stack
None applicable — no network, no persistence write, no untrusted input
parsing in this phase's scope.

## Sources

### Primary (HIGH confidence)
None — no tool-verified source reached HIGH confidence this session
(no Context7/MCP docs tool was available; all lookups went through
`WebSearch`, capped at MEDIUM even when cross-checked).

### Secondary (MEDIUM confidence) — CITED, cross-checked against an Apple documentation URL
- `chartXSelection(value:)` — developer.apple.com/documentation/swiftui/view/chartxselection(value:) — generic signature, `Plottable` constraint
- `AnnotationOverflowResolution` — developer.apple.com/documentation/charts/annotationoverflowresolution — edge-clamping mechanism
- `annotation(position:alignment:spacing:overflowResolution:content:)` — developer.apple.com/documentation/charts/chartcontent/annotation(position:alignment:spacing:overflowresolution:content:)-6w4p3
- `AXNumericDataAxisDescriptor` — developer.apple.com/documentation/accessibility/axnumericdataaxisdescriptor — confirms `import Accessibility` requirement
- Swift with Majid, "Mastering charts in SwiftUI. Selection." (2023-07-18) — swiftwithmajid.com/2023/07/18/mastering-charts-in-swiftui-selection/ — concrete `chartXSelection` + `RuleMark` + `.annotation` code example
- Create with Swift, "Making charts accessible with Swift Charts" — createwithswift.com/making-charts-accessible-with-swift-charts/ — concrete `AXChartDescriptorRepresentable` code example

### Tertiary (LOW confidence) — single-source, not independently cross-checked
- Apple Developer Forums threads 737244 / 741642 (`overflowResolution` edge cases with other chart modifiers) — anecdotal community reports, worth a visual on-device check but not a blocking concern
- The iPhone-vs-iPad `chartXSelection` gesture-shape claim in Pitfall 5 / Assumption A1 — training knowledge, not located in an authoritative source this session

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM — `chartXSelection`/`Charts`/`Accessibility` framework APIs and their signatures were cross-checked against Apple documentation URLs via web search, but full doc bodies could not be fetched in this session (no MCP docs tool available), so nothing reached HIGH/`[VERIFIED]`.
- Architecture: MEDIUM — patterns synthesized from Apple docs + independent third-party code examples that agree with each other.
- Pitfalls: MEDIUM/LOW mix — `overflowResolution` two-axis pitfall and AX-descriptor-drift pitfall are MEDIUM (documented behavior); the XCUITest gesture-shape claim (Pitfall 5) is explicitly flagged LOW/`[ASSUMED]` and logged in the Assumptions table for planner/execution attention.

**Research date:** 2026-07-30
**Valid until:** ~2026-08-29 (30 days — stable first-party Apple APIs, low churn risk; re-verify only if Xcode/iOS SDK version changes materially before execution)
