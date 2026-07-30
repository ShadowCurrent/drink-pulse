---
phase: 05-insights-chart-scrubbing
reviewed: 2026-07-30T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift
  - drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift
  - drinkpulse/Features/Insights/Components/InsightsHeroCard.swift
  - drinkpulse/Features/Insights/Components/WeekdayBarChart+Accessibility.swift
  - drinkpulse/Features/Insights/Components/WeekdayBarChart.swift
  - drinkpulse/Features/Insights/InsightsChartModels.swift
  - drinkpulseTests/Features/Insights/AlcoholAreaChartAXDescriptorTests.swift
  - drinkpulseTests/Features/Insights/WeekdayBarChartAXDescriptorTests.swift
  - drinkpulseUITests/Features/Insights/InsightsScrubUITests.swift
findings:
  critical: 0
  warning: 0
  info: 4
  total: 4
status: issues_found
---

# Phase 05: Code Review Report

**Reviewed:** 2026-07-30
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Re-review after gap-closure plan `05-03` (commits `ea58d02`, `f3db949`), which
addressed UAT gaps G-05-2/G-05-3 (scrub callout flicker/clip) by (a) adding a
data-derived `yDomainUpperBound` (`peak × 1.6`, floored at `1`) driving
`.chartYScale(domain:)` on both `AlcoholAreaChart` and `WeekdayBarChart`, and
(b) moving the selection `.animation(...)` modifier off the whole `Chart(...)`
view onto just `calloutView`'s own modifier chain.

**Both mechanisms check out as correct, including at the edges called out for
extra scrutiny:**

- `yDomainUpperBound` is a *multiplicative* domain scale, so the fraction of
  the chart's fixed pixel height reserved as headroom is constant
  (`1 − 1/1.6 = 37.5%`) regardless of the data's absolute magnitude — this
  holds for very small and very large peaks alike. The `max(peak × 1.6, 1)`
  floor only engages for sub-`0.625` nonzero peaks and only ever *increases*
  the reserved headroom fraction, never decreases it. `AlcoholAreaChart`'s
  `emptyState` branch (`data.allSatisfy({ $0.grams == 0 })`) runs *before*
  `yDomainUpperBound` is evaluated, so the all-zero/empty-`data` case never
  reaches it; for `WeekdayBarChart` (no equivalent empty-state branch) an
  all-zero or empty `bars` input still resolves safely to `domain: 0...1` via
  the same floor, with no invalid/reversed range and no crash. Single-point
  and negative-adjacent-to-zero inputs were traced and also resolve to a
  valid, non-degenerate domain.
- Both `calloutView`s gate `.transition(...)` and `.animation(..., value:)`
  on the exact same `reduceMotion` boolean, on the same view, evaluated in
  the same body pass — there is no window where one is gated and the other
  isn't; Reduce Motion ON still yields `.identity`/`nil` for both together.
- Attaching `.animation(_:value:)` directly to the conditionally-included
  `calloutView` (rather than to the parent `Chart`) is the pattern Apple
  documents for driving insertion/removal `.transition`s tied to a specific
  state value, and un-scoping it from `Chart` removes the previous risk of a
  chart-wide animation context bleeding into the natively-rendered
  `RuleMark`'s position updates — `RuleMark` now tracks `chartXSelection`
  with no animation wrapper in between, which is the desired instantaneous
  drag-follow behavior.
- The `CR-01`/`CR-02` per-iteration selection guards from the prior review
  (`selectedKey == ChartPoint.key(for: point.date)` /
  `selectedLabel == bar.label`, gating directly on the closure's own
  iteration element) are unchanged and intact — no regression back to the
  previously-fixed "duplicated once per element" bug.
- The prior review's `WR-01` (AX descriptor category labels dropping the
  year) and `WR-02` (`Dictionary(uniqueKeysWithValues:)` trap risk) fixes
  are both confirmed present and correct in the current code.

No hardcoded secrets, no PII/health-data logging (no `Logger`/`print` calls
in any of these files at all), no Swift 6 strict-concurrency issues, and all
files remain well under the 300-line ceiling (`AlcoholAreaChart.swift` ~161
lines, `WeekdayBarChart.swift` ~97 lines).

The only remaining items are pre-existing/newly-introduced maintainability
nits (Info-tier) — none rise to Warning or Critical.

## Critical Issues

None found.

## Warnings

None found.

## Info

### IN-01: `yDomainUpperBound`'s headroom multiplier/floor is duplicated verbatim across both charts with no shared constant

**File:** `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift:81-84`, `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift:73-76`
**Issue:** The gap-closure fix introduces the identical computed property in
both files:

```swift
private var yDomainUpperBound: Double {
    let peakGrams = data.map(\.grams).max() ?? 0   // WeekdayBarChart: bars.map(displayValue).max() ?? 0
    return max(peakGrams * 1.6, 1)
}
```

The magic numbers `1.6` (headroom multiplier) and `1` (degenerate-range
floor) are duplicated verbatim rather than expressed as named constants. Each
file's doc comment explicitly cross-references the other ("same ratio as
AlcoholAreaChart's yDomainUpperBound, per D-04") to keep them in sync
manually, which is exactly the kind of drift risk a future one-line tuning
edit (e.g. bumping the multiplier for one chart but not the other) can
silently break.
**Fix:** Extract a shared constant (or a small free function taking a peak
value), e.g. in a shared chart-metrics file:
```swift
enum DPChartMetrics {
    static let scrubHeadroomMultiplier: Double = 1.6
    static func yDomainUpperBound(peak: Double) -> Double {
        max(peak * scrubHeadroomMultiplier, 1)
    }
}
```
and have both charts call `DPChartMetrics.yDomainUpperBound(peak:)`.

### IN-02: Force-unwrap in `WeekdayBarChart`'s `#Preview` block

**File:** `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift:94`
**Issue:** `[.safe, .caution, .exceeded].randomElement()!` force-unwraps a
`randomElement()` call. The literal array is non-empty so this cannot
actually crash today, but CLAUDE.md's "No force-unwraps in production code"
rule only explicitly carves out `try!` for previews/tests — plain `!` isn't
called out as preview-exempt, and this line will fail an automated `grep -n
'!'` pattern check on the file.
**Fix:** Use a non-crashing form, e.g. `?? .safe`, or hoist the array to a
`let` and index it with `i % 3` to keep the preview fully force-unwrap-free:
```swift
riskLevel: [.safe, .caution, .exceeded].randomElement() ?? .safe
```

### IN-03: Divisor-guard and value-formatting expressions still triplicated in `WeekdayBarChart` (carried over, unresolved)

**File:** `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift:66-67,73`, `drinkpulse/Features/Insights/Components/WeekdayBarChart+Accessibility.swift:20,33`
**Issue:** Still present as of this re-review (flagged as `IN-01` in the
prior review and explicitly out of scope for the `05-03` gap-closure fix
pass). The "safe divisor" guard `unitDivisor > 0 ? unitDivisor : 1.0` is
written independently in `WeekdayBarChart.displayValue(_:)` and again as
`WeekdayBarChartAXDescriptor.safeDivisor`. The value string
`String(format: "%.1f", …) + " " + unitLabel` is written independently three
times: the per-bar `accessibilityLabel`, `calloutView`, and the descriptor's
`valueDescriptionProvider`. All three currently agree, but nothing enforces
that going forward.
**Fix:** Extract a single `WeekdayBar.displayValue(divisor:)` and a single
`formattedUnitValue(_:unitLabel:)` helper that all call sites — including
the descriptor — go through.

### IN-04: `WeekdayBarChart` still has no selection reset on data change, unlike `AlcoholAreaChart` (carried over, unresolved)

**File:** `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift:12`, `drinkpulse/Features/Insights/Components/InsightsHeroCard.swift:21`
**Issue:** Still present as of this re-review (flagged as `IN-02` in the
prior review, out of scope for `05-03`). `InsightsHeroCard` explicitly clears
`AlcoholAreaChart`'s selection on period change
(`.onChange(of: vm.period) { selectedKey = nil }`), but `WeekdayBarChart`
owns `selectedLabel` as private `@State` with no equivalent
`.onChange(of: bars)` reset when its `bars` input changes. Low practical
risk given `chartXSelection` already clears on touch-up, but the two sibling
components handle the same concern inconsistently.
**Fix:** Add `.onChange(of: bars) { selectedLabel = nil }` (or document
explicitly why it's unnecessary) to align with `AlcoholAreaChart`'s pattern.

---

_Reviewed: 2026-07-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
