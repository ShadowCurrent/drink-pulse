# Phase 5: Insights Chart Scrubbing - Context

**Gathered:** 2026-07-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can drag a finger across `AlcoholAreaChart` and `WeekdayBarChart` in
Insights to read the exact value at the touched point, via native Swift
Charts selection (`chartXSelection`) — not a hand-rolled `DragGesture` hack.
While scrubbing `AlcoholAreaChart`, the `InsightsHeroCard` headline follows
the touched point's value and reverts to the period total on release.
VoiceOver users get full per-point access through an
`accessibilityChartDescriptor` without needing to perform the drag gesture.
The selection/callout animation honors `accessibilityReduceMotion`. Scope is
`CHART-01` through `CHART-04` only — no chart-range selection, no
categorical-x-axis rework (the existing `dateByKey` reverse-lookup already
supports scrubbing as-is), no changes to `InsightsViewModel` stored state
(selection stays view-local per ARCHITECTURE.md).

</domain>

<decisions>
## Implementation Decisions

### Callout content & style (AlcoholAreaChart)
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

### WeekdayBarChart's own readout
- **D-04:** WeekdayBarChart gets the identical RuleMark + floating
  glass-chip callout pattern as `AlcoholAreaChart` — not a different
  treatment (e.g. bar highlight only). Consistency across both charts.
- **D-05:** WeekdayBarChart's callout shows weekday + value only (e.g. "Mon
  — 18 g") — no risk-level text appended; the bar's existing risk-level
  color (`color(for:)` in `WeekdayBarChart.swift:45`) already carries that
  signal visually.

### Selection lifecycle across period/scope changes
- **D-06:** If the user is mid-scrub on `AlcoholAreaChart` and switches
  period (week/month/year/all-time) via `InsightsScopeNavigator`, the
  selection clears immediately — the hero card headline reverts to the new
  period's total rather than attempting to carry a selection onto a
  differently-shaped dataset (a selected day in Week view has no
  equivalent meaning in Year view).
- **D-07:** Backgrounding the app or switching away from the Insights tab
  mid-scrub needs no explicit selection-reset code — selection is
  view-local `@State`, so it's naturally dropped when the view rebuilds
  with fresh data (existing `onChange(of: scenePhase)` / `@Query` refresh
  path already handles this; no special-case required).

### VoiceOver chart descriptor content
- **D-08:** Each `AlcoholAreaChart` audio-graph data point announces date +
  value in the user's display unit (e.g. "July 24, 32 grams" or the
  equivalent in standard drinks/UK units per `profile.alcoholUnit`) —
  reuse `InsightsViewModel+Formatting.formattedValue(_:)` as the single
  source of truth so the audio graph and the visual callout never drift
  apart. No guideline-limit context folded in (that's
  `GuidelineComparisonCard`'s job, not this descriptor's).
- **D-09:** `WeekdayBarChart` also gets a full `accessibilityChartDescriptor`
  (not just its existing per-bar `accessibilityLabel` at
  `WeekdayBarChart.swift:23`) — for consistency with the area chart's audio
  graph, even though the per-bar labels already technically satisfy
  VoiceOver swipe-through access to all 7 values.

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
  technical risk for research to confirm.

### Folded Todos
- **`.planning/todos/pending/2026-07-26-scrub-insights-charts-for-per-point-values.md`**
  (severity: minor, already tagged `resolves_phase: 5`) — this todo is the
  direct source of `CHART-01`–`CHART-04`; its "Solution" section (native
  `chartXSelection`, RuleMark/annotation callout via DesignSystem tokens,
  format through `InsightsViewModel+Formatting`, extend
  `accessibilityChartDescriptor`, honor `reduceMotion`, requires a
  `drinkpulseUITests` UI test) is fully captured in the decisions above and
  in `.planning/REQUIREMENTS.md`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` §"Chart Scrubbing (Insights)" — CHART-01..04
  requirement text and explicit "Future Requirements" / "Out of Scope"
  boundaries (no `chartXSelection(range:)`, no x-axis Date-scale rework, no
  VM stored-state changes)
- `.planning/ROADMAP.md` §"Phase 5: Insights Chart Scrubbing" — goal,
  4-point success criteria, UI hint

### Source todo
- `.planning/todos/pending/2026-07-26-scrub-insights-charts-for-per-point-values.md`
  — original problem statement, candidate file list, and the "must feel
  native iOS 26 — first-party selection API, not a hand-rolled drag gesture"
  constraint

### Relevant code
- `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift` — no
  `chartXSelection`/`chartOverlay` today; categorical `String` x-key via
  `key(for:)`/`dateByKey`, `xAxisFormat` per period, 100pt height
- `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift` — no
  selection today; per-bar `accessibilityLabel` already exists at line 23;
  `unitDivisor`/`unitLabel` params for display-unit conversion
- `drinkpulse/Features/Insights/Components/InsightsHeroCard.swift` — owns
  `AlcoholAreaChart` directly (`vm.seriesData`, `vm.period`); headline
  (`vm.formattedValue(vm.periodTotalGrams)`) and `vsPrevLabel` live here —
  CHART-02's "follows touch" behavior is wired at this level
  (`InsightsHeroCard`), not inside `InsightsViewModel`
- `drinkpulse/Features/Insights/InsightsChartModels.swift` — `ChartPoint`
  (date + grams), `WeekdayBar` (weekdayIndex + label + averageGrams +
  riskLevel) value types the selection will key against
- `drinkpulse/Features/Insights/InsightsViewModel+Formatting.swift` —
  `formattedValue(_:)` is the single formatting entry point to reuse for
  both the visual callout and the AX descriptor (D-01, D-08)
  — never format inline in the view
- `drinkpulse/Features/Insights/InsightsView.swift` — screen composition;
  `InsightsScopeNavigator` (period switch) sits above `InsightsHeroCard` and
  `WeekdayBarChart` in the same `ScrollView`
- `drinkpulse/DesignSystem/DPGlass.swift` — `dpGlassCard(_:)` modifier,
  `.chip` size (14pt corner radius) is the callout's background token (D-02)
- `drinkpulse/Features/Onboarding/OnboardingView.swift:9,80,87` —
  established `@Environment(\.accessibilityReduceMotion)` pattern
  (`reduceMotion ? nil : .spring(...)`) to reuse for the callout's
  appear/disappear animation (CHART-04)

[No ADRs directly govern chart interaction — this is new ground.]

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `DesignSystem/DPGlass.swift` `.dpGlassCard(.chip)` — direct reuse for the
  scrub callout background (D-02, D-04)
- `InsightsViewModel+Formatting.formattedValue(_:)` — direct reuse for both
  the visual callout text and the VoiceOver descriptor (D-01, D-08)
- `OnboardingView.swift`'s `reduceMotion` ternary pattern — direct reuse for
  the callout animation (CHART-04)

### Established Patterns
- Both charts are "dumb" views today (no `@State`, no gesture handling) —
  selection state will be the first view-local `@State` either chart or its
  parent card owns; this must stay view-local per
  `.planning/REQUIREMENTS.md`'s explicit Out-of-Scope item (no
  `InsightsViewModel`/`HistoryViewModel` stored-state changes)
- `AlcoholAreaChart` and `WeekdayBarChart` both already use a categorical
  (band) x-scale, not a continuous `Date` scale — `chartXSelection` needs to
  bind against the same type plotted on the x-axis (`String` for the area
  chart's `key(for:)`, `String` label for the bar chart)

### Integration Points
- `InsightsHeroCard` is the integration point for CHART-02 (hero headline
  follows touch) since it's the direct parent of `AlcoholAreaChart` and
  already owns `vm.formattedValue(...)` calls
- `WeekdayBarChart` has no parent "hero" element — its callout is
  self-contained within the chart's own card

</code_context>

<specifics>
## Specific Ideas

No mockup or reference image was provided. Guiding principle from
discussion: reuse existing DesignSystem tokens and formatting/pattern code
end-to-end (glass chip, `formattedValue`, `reduceMotion` ternary) rather
than introducing new visual language for the scrub interaction.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 5-Insights Chart Scrubbing*
*Context gathered: 2026-07-30*
