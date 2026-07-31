# Phase 5: Insights Chart Scrubbing - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-30
**Phase:** 5-Insights Chart Scrubbing
**Areas discussed:** Callout content & style, WeekdayBarChart's own readout, Selection lifecycle across period/scope changes, VoiceOver chart descriptor content

---

## Callout content & style

| Option | Description | Selected |
|--------|-------------|----------|
| Date + value (recommended) | "Jul 24 — 32 g" — standard RuleMark+annotation convention | ✓ |
| Value only | Just the number, terser but loses which day | |
| You decide | Claude picks based on chart height | |

**User's choice:** Date + value

| Option | Description | Selected |
|--------|-------------|----------|
| Glass chip (recommended) | Reuse `dpGlassCard(.chip)` token, same surface as TrendBadge | ✓ |
| Plain text label | No background, no visual separation from chart | |

**User's choice:** Glass chip

| Option | Description | Selected |
|--------|-------------|----------|
| Floating above the RuleMark (recommended) | `.annotation(position: .top)` tracks touch, clamped at edges | ✓ |
| Fixed position | Stays in one place, doesn't track touch | |

**User's choice:** Floating above the RuleMark

---

## WeekdayBarChart's own readout

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, same pattern (recommended) | Reuse RuleMark + glass-chip callout, consistent across both charts | ✓ |
| Different treatment | e.g. bar highlight only | |

**User's choice:** Yes, same pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Weekday + value (recommended) | "Mon — 18 g", mirrors area chart's date+value pattern | ✓ |
| Weekday + value + risk label | Also surfaces risk level in text | |

**User's choice:** Weekday + value

---

## Selection lifecycle across period/scope changes

| Option | Description | Selected |
|--------|-------------|----------|
| Clear immediately (recommended) | Selection resets on period switch, avoids stale/mismatched state | ✓ |
| Try to persist | Keep selection at relative position on new dataset — more complex, rarely meaningful | |

**User's choice:** Clear immediately

| Option | Description | Selected |
|--------|-------------|----------|
| Covered already (recommended) | View-local `@State` naturally drops on scenePhase/tab teardown | ✓ |
| Needs explicit handling | Add explicit reset tied to scenePhase/tab-switch | |

**User's choice:** Covered already

---

## VoiceOver chart descriptor content

| Option | Description | Selected |
|--------|-------------|----------|
| Date + value, user's display unit (recommended) | Reuses `formattedValue(_:)`, single source of truth with visual callout | ✓ |
| Date + value + guideline context | Also states position vs guideline limit — duplicates GuidelineComparisonCard | |

**User's choice:** Date + value, user's display unit

| Option | Description | Selected |
|--------|-------------|----------|
| Existing per-bar labels are sufficient (recommended) | `accessibilityLabel` at `WeekdayBarChart.swift:23` already covers CHART-03 | |
| Add a full AXChartDescriptor anyway | Build the same audio-graph descriptor as the area chart, for consistency | ✓ |

**User's choice:** Add a full AXChartDescriptor anyway
**Notes:** User chose the more thorough option over Claude's "already sufficient" recommendation — consistency across both charts weighed higher than avoiding duplicate work.

---

## Claude's Discretion

- `@State`/binding ownership shape for the scrubbing selection (`InsightsHeroCard` vs `AlcoholAreaChart` owning it)
- Exact `AXChartDescriptor` construction details for both charts
- Whether the categorical `String` x-key (`key(for:)`/`dateByKey`) needs adaptation for `chartXSelection` binding, or works as-is

## Deferred Ideas

None — discussion stayed within phase scope.
