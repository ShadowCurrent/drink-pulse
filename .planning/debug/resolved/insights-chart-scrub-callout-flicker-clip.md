---
status: resolved
trigger: "UAT gaps G-05-2 (AlcoholAreaChart) and G-05-3 (WeekdayBarChart): drag-to-scrub glass-chip callout flickers and appears partially hidden/clipped by the chart during a drag, on all period scopes (week/month/year/all-time) and on both charts. Shared root cause, investigated once."
created: 2026-07-30T00:00:00Z
updated: 2026-07-31T09:20:00Z
resolved_by: 05-03-PLAN.md
resolved_at: 2026-07-31
---

## Current Focus

hypothesis: "CONFIRMED (see Resolution). Root cause is two compounding mechanisms in the shared RuleMark+.annotation+chart-wide-.animation pattern used identically by both charts."
test: "n/a — root cause confirmed on-device via three targeted XCUITest diagnostics with embedded XCUIScreen screenshots (temporary, not committed)."
expecting: "n/a — diagnosis complete, goal is find_root_cause_only."
next_action: "Hand off to fix workflow (out of scope for this diagnose-only session) with the two confirmed mechanisms and suggested fix directions in Resolution."

## Symptoms

expected: Dragging a finger across AlcoholAreaChart or WeekdayBarChart shows a date/weekday+value glass-chip callout tracking the touch, clamped so it never renders outside the chart's bounds, with a clean native-feeling appearance (CHART-01, D-01 through D-05).
actual: User reports (translated from Polish): "when I drag my finger across the chart in the Insights view, the label that appears flickers, is not fully visible, as if it's partially covered by the chart, overall it looks bad, it doesn't look native — there's a problem with this chip, it happens on the week, month, year and all charts."
errors: None reported by user; xcodebuild build/test clean (581 unit + 71 UI tests pass). Swift Charts' `.annotation` content isn't in the accessibility tree the UI tests assert against, so this defect is invisible to the existing automated suite.
reproduction: Open Insights tab, drag a finger across AlcoholAreaChart (top chart, ~100pt tall) or WeekdayBarChart (bottom chart, ~160pt tall) in any period (week/month/year/allTime). Observe the glass-chip callout during the drag.
started: Introduced in phase 05 (Insights Chart Scrubbing), just merged. A code-review pass already fixed a duplicated-RuleMark bug (commits 254ae6a, 2630a34 — selection guard was matching on every chart datum instead of the current iteration's own element) but that did not resolve this flicker/clipping complaint, reported afterward.

## Eliminated

- hypothesis: "Duplicated RuleMark rendering (multiple RuleMarks stacking because the selection guard matched every datum, not just the touched one)"
  evidence: "Already fixed by commits 254ae6a (AlcoholAreaChart) and 2630a34 (WeekdayBarChart) prior to this UAT round; current source at both files gates correctly with `if selectedKey == ChartPoint.key(for: point.date)` / `if selectedLabel == bar.label` inside the per-element ForEach body — confirmed by reading current file contents. User reported this flicker/clip issue AFTER that fix landed, so it's a distinct root cause."
  timestamp: 2026-07-30T00:00:00Z

## Evidence

- timestamp: 2026-07-30T00:00:00Z
  checked: "drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift (full file)"
  found: "Chart(data) height is .frame(height: 100). RuleMark(x: .value(...)) has no y specified → spans full plot height. .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) wraps calloutView(date:). .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: selectedKey) is applied to the outer Chart(...) view (i.e. the whole chart incl. AreaMark/LineMark/RuleMark/axis), not scoped to just the annotation/RuleMark. calloutView wraps Text in .dpGlassCard(.chip) = .glassEffect(.regular, in: .rect(cornerRadius: 14)), no GlassEffectContainer used anywhere in the file."
  implication: "Two candidate mechanisms present simultaneously: (1) 100pt frame height + .top annotation + y-overflow clamp = likely visual overlap near chart top; (2) chart-wide .animation(value: selectedKey) driving a spring re-layout of the ENTIRE Chart (not just the callout) on every rapid chartXSelection update during a continuous drag — since chartXSelection fires continuously, selectedKey changes many times per second while dragging, each retriggering the spring on the whole view tree."

- timestamp: 2026-07-30T00:00:00Z
  checked: "drinkpulse/Features/Insights/Components/WeekdayBarChart.swift (full file)"
  found: "Identical pattern to AlcoholAreaChart: .frame(height: 160), RuleMark with no y (full-height), .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))), .animation(reduceMotion ? nil : .spring(...), value: selectedLabel) on the whole Chart(...). Taller frame (160 vs 100) but same overall mechanism."
  implication: "Confirms 'shared root cause' framing from UAT — both charts use byte-for-byte the same annotation/animation pattern, just different frame heights. This rules out a chart-specific bug and supports investigating the shared pattern (RuleMark+annotation+chart-wide animation+glassEffect) rather than something unique to one chart."

- timestamp: 2026-07-30T00:00:00Z
  checked: "drinkpulse/DesignSystem/DPGlass.swift (full file)"
  found: ".dpGlassCard(.chip) applies .glassEffect(.regular, in: .rect(cornerRadius: 14)) directly on the content view, with no GlassEffectContainer anywhere in the file or in either chart file."
  implication: "Per Apple's iOS 26 Liquid Glass guidance, .glassEffect() without a GlassEffectContainer is documented to be more expensive to render/recomposite on every geometry change (each reposition recomputes the glass sampling region independently) — a candidate contributor to visible flicker/stutter during rapid annotation repositioning, though this alone would not explain the 'covered by chart' clipping complaint. Needs on-device confirmation to weight against hypothesis 1/2 rather than assumed as primary cause."

- timestamp: 2026-07-30T00:00:00Z
  checked: "05-01-PLAN.md Pitfall 2 (overflowResolution not applied to both axes) and Pitfall 4 (Reduce Motion two-gate)"
  found: "Plan's own research already flagged (LOW confidence, community-report-sourced) that overflowResolution can produce inconsistent clamping behavior 'even when x: .fit(to: .chart) is set alone' — hinting at documented flakiness in this exact API combined with other chart modifiers. Both axes ARE set correctly in the current code (x AND y), so Pitfall 2 as literally described is not present — but the broader community-reported unreliability of overflowResolution interacting with other modifiers (here: chart-wide .animation) is exactly the kind of interaction not covered by research."
  implication: "The plan's own MEDIUM/LOW-confidence research flagged this exact API surface as having documented edge-case unreliability — reinforces treating overflowResolution's interaction with the whole-chart .animation(value:) as the prime suspect rather than a novel/unexplained bug."

- timestamp: 2026-07-30T00:00:00Z
  checked: "On-device diagnostic 1: XCUITest driving a real press(forDuration:thenDragTo:withVelocity:thenHoldForDuration:) drag across AlcoholAreaChart from dx=0.15 to dx=0.75 (chart element's own frame, targeted via its explicit .accessibilityLabel('Alcohol Over Time') — not the loose card container), holding 2.5s at the end, with a screenshot captured via XCUIScreen.main.screenshot() ~0.6s into the hold (well past the RuleMark's landing)."
  found: "The RuleMark (vertical gray line) renders correctly at the drag's end position (near 'Sat', a near-zero-value point). But the glass-chip callout is NOT floating above that RuleMark at all. Instead, a bare, glass-styling-less text reading '1.5 std' (no visible rounded chip/backdrop) is rendered near the CHART'S PEAK (~Wed/Thu, a completely different x-position, ~35 percentage points away from the actual touch/RuleMark position), overlapping the AreaMark's own orange gradient fill."
  implication: "The annotation's SwiftUI content view is NOT tracking the live selectedKey during a continuous drag — it lags/sticks near an earlier (likely first-touched) selection while the native RuleMark (rendered directly by Swift Charts' own pipeline, not subject to the same SwiftUI diff/animation path) has already moved on. This desync, replayed continuously during a real drag, directly matches the reported 'flickers' — and the stale callout landing inside the AreaMark's own fill directly matches 'as if it's partially covered by the chart.'"

- timestamp: 2026-07-30T00:00:00Z
  checked: "On-device diagnostic 2: a STATIONARY long-press (press(forDuration: 3.0), no drag motion at all) at AlcoholAreaChart's peak value point (dx=0.5, the 'Thu' data point, the dataset's max), with a screenshot ~1.5s into the 3s hold — isolates whether the mispositioning above is drag-motion-induced desync or a pure static-position bug."
  found: "With NO drag motion, the callout ('30. Jul — 2...', locale-formatted per the simulator's Polish system locale) DOES render at the correct x-position (aligned with the RuleMark, directly under 'Thu'), but it visually overlaps/is embedded WITHIN the AreaMark's peak fill — there is no visible clearance above the plotted line; the chip's top edge is at/below the top of the orange peak, not floating cleanly above it. Additionally the callout text appears truncated at the crop edge (screen-relative), and the glass-chip background is barely distinguishable from the underlying gradient (very low contrast)."
  implication: "CONFIRMS a second, independent mechanism (not just drag-desync): the chart's `.frame(height: 100)` does not leave enough vertical room, for a `.top`-positioned annotation with `overflowResolution: y: .fit(to: .chart)`, to float above a near-max-value RuleMark — the resolver squeezes the callout back down into the plot area, directly overlapping the AreaMark's own fill. This alone reproduces 'as if partially covered by the chart' even with zero drag motion, zero animation-timing involvement."

- timestamp: 2026-07-30T00:00:00Z
  checked: "Same stationary-press diagnostic's post-release screenshot (~120ms after the 3s hold's synchronous XCUITest call returns, i.e. touch already lifted)."
  found: "The RuleMark has already disappeared (no vertical line), but the callout text is STILL visible, mid-fade, overlapping the chart peak."
  implication: "Directly confirms the RuleMark (native Swift Charts mark) and the `.annotation` content (SwiftUI view subject to `.transition` + the chart-wide `.animation(reduceMotion ? nil : .spring(...), value: selectedKey)`) are on two DIFFERENT, desynchronized render/removal timelines. The RuleMark disappears instantly on selection clearing; the annotation's SwiftUI removal transition lags behind by a visible, non-trivial fraction of a second. Under a real continuous drag (selection changing many times per second, not just once), this same lag/desync repeats continuously — producing the perceived 'flicker.'"

- timestamp: 2026-07-30T00:00:00Z
  checked: "Attempted a third diagnostic targeting WeekdayBarChart via its container accessibility label ('Weekday Patterns'), reusing the existing (uncommitted-to-this-finding) InsightsScrubUITests.swift's own code comments as a cross-check."
  found: "The existing (already-in-repo, passing) InsightsScrubUITests.swift explicitly documents this exact pitfall in its own comments: 'waitForExistence only proves the element is laid out somewhere in the scroll content — not that it's within the visible viewport. A coordinate computed against an off-screen frame can land beyond the app's bounds, in the system gesture zone near the bottom edge (triggering the OS app-switcher instead of a touch inside the app).' My ad-hoc diagnostic test skipped that guard and produced a screenshot showing an unrelated full-screen blur/shift artifact — almost certainly a mistargeted gesture hitting a system-level edge zone, not a production rendering bug."
  implication: "This result is INVALID as evidence of the production bug and is excluded from the root-cause conclusion below. It does NOT change the diagnosis: WeekdayBarChart shares byte-for-byte the same RuleMark+annotation+chart-wide-.animation pattern as AlcoholAreaChart (already confirmed via source read), so the two confirmed AlcoholAreaChart mechanisms apply equally to WeekdayBarChart, consistent with the user's own 'shared root cause across both charts' framing in the UAT gap."

## Resolution

root_cause: "Two compounding mechanisms in the RuleMark + `.annotation(position: .top, overflowResolution:)` + chart-wide `.animation(value: selectedKey)` pattern shared identically by AlcoholAreaChart and WeekdayBarChart: (1) Overflow-clamp overlap — AlcoholAreaChart's `.frame(height: 100)` (and to a lesser extent WeekdayBarChart's 160pt) does not leave enough vertical clearance for a `.top`-positioned annotation above a near-max-value RuleMark; `overflowResolution: y: .fit(to: .chart)` squeezes the callout back down into the plot area so it renders overlapping/embedded within the AreaMark's own gradient fill instead of floating cleanly above it — confirmed on-device via a stationary (non-dragging) long-press at the chart's peak value. (2) Annotation/RuleMark desync under continuous selection updates — the annotation's SwiftUI content view (governed by its own `.transition` plus the ENTIRE Chart's `.animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: selectedKey)`) does not stay synchronized with the native RuleMark's position/visibility, which Swift Charts renders directly and independently of that SwiftUI animation pipeline. During a real drag, the callout can visibly lag at a stale x-position while the RuleMark has already moved on to the live touch position (confirmed: a drag ending near a zero-value point still showed a stray callout hovering near an unrelated earlier peak position); on release, the callout also visibly outlives the RuleMark's instantaneous disappearance by a non-trivial fraction of a second (confirmed via post-release screenshot). Replayed continuously during a real, fast, continuous drag (chartXSelection fires many updates per second), this lag/desync is what reads as 'flickers.' Both mechanisms trace to the same design choice the phase's own 05-RESEARCH.md flagged as risky (Pitfall 2 — community-reported inconsistency of `overflowResolution` combined with other chart modifiers) but did not fully anticipate: pairing `.annotation(overflowResolution:)` with a chart-wide `.animation(value:)` on a rapidly, continuously changing selection binding, inside frames too short to give the annotation room above real data peaks. A secondary, compounding factor: the glass chip (`.dpGlassCard(.chip)` → `.glassEffect(.regular, in:)`, no `GlassEffectContainer`) has low contrast against the AreaMark's saturated orange gradient, so even when correctly positioned it can look washed-out/blended-in rather than a crisp floating chip — reinforcing the 'not fully visible' perception."
fix: ""
verification: ""
files_changed: []

## Diagnostic Artifacts (not committed)

A temporary XCUITest file (`drinkpulseUITests/Features/Insights/InsightsScrubDiagnosticUITests.swift`) was created, run three times to capture on-device screenshots via `XCUIScreen.main.screenshot()` embedded as XCTAttachments, then deleted after the diagnosis was confirmed — it was diagnostic-only, not a deliverable test. The three runs are documented in Evidence above. No repo files were changed by this debug session other than this debug file.
