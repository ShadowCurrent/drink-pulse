# Requirements: DrinkPulse v1.3 Native Feel

Milestone goal: make History, Insights, and cold-launch feel native
iOS 26 — chart scrubbing, directional slide transition, and a branded
launch screen. Source: Cluster B from the pending-todos triage
(`.planning/todos/CLUSTERS.md`).

## v1.3 Requirements

### Chart Scrubbing (Insights)

- [x] **CHART-01**: User can drag across `AlcoholAreaChart` and
  `WeekdayBarChart` to see the value at the touched point, via native
  `chartXSelection` + a `RuleMark`/annotation callout styled with
  existing DesignSystem glass tokens.

- [x] **CHART-02**: While scrubbing, the Insights hero card headline
  follows the selected point's value (formatted through
  `InsightsViewModel+Formatting`); on release it reverts to the period
  total.

- [ ] **CHART-03**: VoiceOver users retain full per-point access via an
  extended `accessibilityChartDescriptor` — scrubbing is not the only
  path to the values.

- [x] **CHART-04**: The selection/callout animation honors
  `accessibilityReduceMotion` (reuses the existing pattern at
  `OnboardingView.swift:80`).

### History List↔Calendar Transition

- [ ] **HIST-01**: Switching the History segmented control between
  List and Calendar animates with a directional slide — list→calendar
  and calendar→list travel in opposite directions.

- [ ] **HIST-02**: The transition honors `accessibilityReduceMotion`.
- [ ] **HIST-03**: All three states (list, calendar, empty) transition
  correctly with no layout pop or `@Query` re-fetch flash, verified
  with a real dataset on device.

### Branded Launch Screen

- [x] **LAUNCH-01**: Cold launch shows a branded static launch screen
  (app icon + matching background color, no text, no spinner) instead
  of the auto-generated blank one — verified via a genuine force-quit
  cold launch on a real device. Closed by owner decision 2026-07-30:
  background match and icon presence confirmed across many real-device
  rounds; exact on-screen icon *size* could not be pinned down further
  (device shows no visible change across content-verified opposite-size
  edits) and owner chose to stop chasing it — see
  `.planning/debug/slow-container-cold-start.md` and
  `.planning/phases/04-branded-static-launch-screen/04-01-SUMMARY.md`
  Deviation 16.

## Future Requirements

<!-- Deferred from this milestone. -->

- Chart range selection (`chartXSelection(range:)`) — v2+, not needed
  for the table-stakes scrub interaction.

- Custom segmented-control indicator with `matchedGeometryEffect` — v2+
  polish, not required for the directional transition to read as
  native.

- History row-level insert/delete animation — separate todo
  (`2026-07-26-animate-history-list-row-insert-delete.md`), already
  completed independently of this milestone.

## Out of Scope

<!-- Explicit exclusions with reasoning. -->

- Any animation, progress indicator, or wordmark on the launch screen
  — `UILaunchScreen` is a static image by platform design; Apple HIG
  actively discourages unlocalized text on it.

- Refactoring chart x-axis from categorical `String` keys to a
  `Date`-based scale — the existing `dateByKey` reverse-lookup already
  supports scrubbing without this rework.

- Any change to `InsightsViewModel` or `HistoryViewModel` stored state
  — selection/direction-tracking state stays view-local per
  ARCHITECTURE.md's findings (both VMs are currently stateless/near-
  stateless w.r.t. transient UI state; this milestone doesn't change
  that).

## Traceability

<!-- Filled by roadmapper: which phase satisfies which requirement. -->

| Requirement | Phase | Status |
|-------------|-------|--------|
| CHART-01 | Phase 5 | Complete |
| CHART-02 | Phase 5 | Complete |
| CHART-03 | Phase 5 | Pending |
| CHART-04 | Phase 5 | Complete |
| HIST-01 | Phase 6 | Pending |
| HIST-02 | Phase 6 | Pending |
| HIST-03 | Phase 6 | Pending |
| LAUNCH-01 | Phase 4 | Done |
