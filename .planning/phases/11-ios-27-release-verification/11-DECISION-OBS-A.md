# OBS-A - VoiceOver reads a very large number instead of date and value on an Insights chart point

**Status:** owner decision pending. Phase 11 makes no fix and writes no production code.
**Source:** owner observation during the CHK-00 probe (`11-A11Y-CHECKLIST.md`), plan 11-07, on the iOS 27.2 simulator (not a device).
**Result:** observation recorded as a likely defect. Checklist items CHK-01 and CHK-02 stay open per the CHK-00 result and are not marked fail. The file name uses OBS-A, not a C-number, because the plan's gate counts `11-DECISION-C0*.md` files against `fail` results and this observation is not a checklist fail.

## Current behavior

What the owner saw: with VoiceOver on, focusing any point of the Insights chart reads a very large number (about 816 million) instead of the date and value (for example 20 g).

Orchestrator hypothesis, not verified in code and not confirmed: about 816 million is the number of seconds from 2001-01-01 to 2026-11, so a raw `Date` (`timeIntervalSinceReferenceDate`) may be spoken as the value. A related record exists: audit group A11Y-AUDIT-G05 (Insights chart day marks exposed as raw timestamps, for example one of about 815 million, with no sufficient description) lists seven chart elements with raw timestamps as identifier or label. This is similar in kind and location; it is not proof of the cause.

Code context read for this brief (read-only): `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift` line 79 attaches `.accessibilityChartDescriptor(AlcoholAreaChartAXDescriptor(...))`, and `AlcoholAreaChart+Accessibility.swift` builds a categorical x axis from formatted date strings and a numeric y axis through `formattedValue`. The descriptor therefore looks correct on paper; what VoiceOver focused on the owner's session may be the per-mark elements of the chart and not the descriptor. The audio-graph path itself could not be exercised (CHK-00: the rotor cannot be opened on the simulator).

## Source-backed decision table

**Availability:** the APIs below are available at the iOS 27.0 deployment target. The documentation extracts returned by Xcode MCP DocumentationSearch carry no older-availability line, so no older-version claim is made here.

| Topic | Evidence |
| --- | --- |
| Official source | SwiftUI `View.accessibilityChartDescriptor(_:)` (`/documentation/SwiftUI/View/accessibilityChartDescriptor(_:)`); Accessibility `AXChartDescriptor`, `AXDataPoint` and "Representing chart data as an audio graph" (`/documentation/Accessibility/representing-chart-data-as-an-audio-graph`: a value description provider formats values into strings, a formatter such as `DateFormatter` is suggested). Read through Xcode MCP DocumentationSearch on 2026-11-16. |
| Option retain | Keep the chart accessibility as is; treat the spoken number as a simulator artifact. Cost: unverified; the same symptom may exist on a device. |
| Option change | After a device check shows the spoken value, give each chart mark an explicit label and value so the raw date is never spoken. Cost: chart views in both Insights charts; regression proof needs a VoiceOver-capable run. |
| Option defer | Run the device check first (CHK-01 and CHK-02 are already deferred to a device per 11-CONTEXT), then decide. |
| Recommendation | None in Phase 11 by plan rule; the owner chooses retain, change or defer. Verification on a device is the missing evidence. |
| Data, accessibility, lifecycle risk | No data or schema change. Accessibility risk: a VoiceOver user may not get the date and value of a chart point. |

## Recommendation and proposed scope

No fix in Phase 11. The cause is a hypothesis. A device check of the area chart and the weekday chart with VoiceOver should come before any scope is proposed.

## Owner decision record

decision: pending
decision date: none
exact scope: none
owner reason: none
