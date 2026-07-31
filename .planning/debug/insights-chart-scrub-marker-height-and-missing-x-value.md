---
status: diagnosed
trigger: "insights-chart-scrub-marker-height-and-missing-x-value — After 05-03 gap-closure fix, user re-tested live: (1) scrub marker sits at fixed Y height rather than tracking the data value at the touched X, (2) scrub callout does not display the X-axis value (date/day/month). Most visible in Month period; reported to affect all charts/periods. User wants a properly-researched fix, referenced https://medium.com/@gerastupakov/swiftui-charts-in-ios-18-custom-line-chart-with-gestures-symbols-more-6e46d8b9c072 and asked for Apple docs + community best practices for Swift Charts drag-to-scrub on iOS 18/26."
created: 2026-07-31T06:35:00Z
updated: 2026-07-31T06:35:00Z
---

## Current Focus

bug_class: Bohrbug (deterministic rendering/layout defect — reproduces every drag, every period; no timing/concurrency component)

hypothesis: |
  H1 (symptom 1, "always same height"): `RuleMark(x:)` with NO `y:` spans the ENTIRE plot height by
  Swift Charts' default. `.annotation(position: .top)` anchors to the TOP OF THE MARK'S BOUNDING BOX
  = the top of the plot area, which is a CONSTANT screen Y regardless of the data value at the touched
  X. There is no PointMark anywhere. 05-03's `yDomainUpperBound = peak * 1.6` did not create
  "clearance above the peak" (its stated rationale) — it pushed the DATA DOWN to ~62% of plot height
  while the annotation stayed pinned at the plot top, which is why the overlap disappeared AND why
  the constant height became visually obvious.

  H2 (symptom 2, "no X value"): The X value IS present in both callout strings. Suspect the user is
  reading the Y value off InsightsHeroCard's 40pt headline (which does follow the scrub via
  `selectedGrams`), while the glass chip itself is unreadable/invisible/absent — so only X appears
  "missing". "Most visible in Month" is consistent: Month thins the X axis to 5 labels out of ~30
  bands, so the date cannot be inferred from the axis, unlike Week (7 of 7 labels).

test: on-device XCUITest diagnostic with XCUIScreen screenshots, Month period, both charts
expecting: |
  If H1 true: the RuleMark/chip renders at identical screen Y for a low-value X and a peak X.
  If H2 true: the chip is either absent, or present-but-illegible, while the hero headline tracks.

outcome: |
  H1 CONFIRMED exactly as stated.
  H2 CONFIRMED in its conclusion (the callout is unreadable, not missing a string) but the MECHANISM
  is different and sharper than hypothesised: the callout is invisible because `.glassEffect` does not
  render inside a Swift Charts `.annotation` — Apple DTS states plainly that "Liquid Glass is not a
  part of Swift Charts". Isolation experiment: the identical Text with a solid background in the same
  annotation renders fully legible; with `.dpGlassCard(.chip)` it renders ZERO text pixels.

reasoning_checkpoint:
  hypothesis: |
    Two independent code-category defects in the shared scrub pattern:
    (1) The scrub marker's Y is constant because the annotation is anchored to a `RuleMark` that spans
        the whole plot area (documented Swift Charts behaviour when yStart/yEnd are omitted), so
        `position: .top` resolves to the plot's top edge, not the datum's height. No `PointMark` or
        `.symbol` exists to mark the datum.
    (2) The callout is unreadable because `.dpGlassCard(.chip)` → `.glassEffect(.regular, in:)` does
        not composite inside a Swift Charts annotation; the content renders invisible.
  confirming_evidence:
    - "Apple RuleMark docs: 'To span the plotting area of a chart with a line, omit the optional start and end parameters' — direct observation of the API contract, not inference."
    - "On-device: in the 4-variant isolation build, plain Text / Text+fixedSize / Text+solid-yellow-background ALL rendered '25. Jul — 4.0 std' fully legible in the SAME annotation; the production glass chip in the SAME VStack rendered nothing."
    - "Pixel scan over a plain-white background region (area-month dx0.10): ZERO pixels differing from background in the glass chip's rect — the chip is 100% invisible, not merely low-contrast."
    - "On-device: the annotation renders at identical screen Y for a 0.0-value X and the 4.0-std peak X."
    - "Apple DTS (forums thread 788041): 'Generally speaking, Liquid Glass is not a part of Swift Charts' and 'currently, there's no dedicated support for liquid glass effects in Charts'."
    - "Probe build: replacing RuleMark-full-height with PointMark-at-value + solid-colour callout produced a marker at the datum's height and a fully legible date+value callout that tracks the point."
  falsification_test: |
    If the glass chip were merely low-contrast (not broken), the pixel scan over the plain white
    background would still show glyph pixels at reduced delta. It shows exactly zero. If the constant
    Y were a data artefact rather than an anchoring defect, the annotation would have moved between the
    0.0-value and 4.0-std screenshots. It did not move by a single pixel.
  fix_rationale: |
    Anchoring the annotation to a mark placed AT the datum (PointMark / LineMark .symbol) makes the
    callout's Y a function of the data by construction, and rendering the callout on an opaque
    Color background removes the unsupported glass compositing path entirely. Both address the
    mechanism, not the symptom.
  blind_spots:
    - "Only light mode was exercised; dark-mode contrast of a solid-colour chip is untested."
    - "Only the iPhone 17 Pro simulator at the default Dynamic Type size was exercised; AX5 text in a chart annotation is untested and could overflow a 100pt-tall chart."
    - "WeekdayBarChart's PointMark equivalent (a marker at the bar's top) was not probed; only AlcoholAreaChart's was. The pattern is identical so the finding transfers, but the bar-specific anchoring is unverified."
    - "Reduce Motion behaviour of the new anchor was not re-verified (CHART-04)."
  candidate_causes:
    - "code: RuleMark spanning the full plot → .annotation(.top) anchors to plot top (CONFIRMED, symptom 1)"
    - "code: .glassEffect unsupported inside Chart annotations → callout invisible (CONFIRMED, symptom 2)"
    - "data: duplicate ChartPoint keys causing stacked annotations (ELIMINATED — keys are timeIntervalSinceReferenceDate, unique)"
    - "config: Localizable.xcstrings dropping the date argument from the '%@ — %@' key (ELIMINATED — catalog is a correct positional passthrough)"
    - "environment: simulator locale altering the date format to something unreadable (ELIMINATED — the date renders correctly as '25. Jul' in every legible variant)"
  and_gate: |
    YES for the reported wording, NO for the defect. The defect is single-cause per symptom (code
    category, one cause each). But the user's specific phrasing — "shows the value but nowhere the X" —
    requires three conditions simultaneously: (a) the callout is invisible [C1], (b) InsightsHeroCard's
    40pt headline keeps showing the Y value during the scrub, so Y never feels missing, and (c) the
    Month period thins the X axis to 5 labels out of ~31 bands, so the axis cannot substitute for the
    callout. (c) is exactly why the user singled out Month.

next_action: "Diagnosis complete (goal: find_root_cause_only). Hand off to a fix plan using the verified direction in Resolution."

## Symptoms

expected: |
  While dragging a finger across AlcoholAreaChart or WeekdayBarChart:
  (a) a marker (dot, highlighted point, or similar) visually indicates the actual data value's height
      at the touched X position — not a static/arbitrary height.
  (b) a callout clearly and unambiguously shows BOTH the X-axis value (date, or at minimum day/month)
      AND the Y-axis value (grams/units) for the touched point.

actual: |
  (translated from Polish, user's own words)
  "It's better now because that broken glass chip is gone, however there are 2 problems: first, the
  point is always positioned at the same height on the Y plane (not at the height of the maximum Y
  value at point X). Second, when I drag my finger across the chart to check the value at point X,
  it doesn't show the X value anywhere (i.e. no date, or at least day/month). This problem is most
  visible in the 'Month' tab but actually affects all the charts. I want the user to clearly see the
  Y-axis value at point X and the X value itself. Do this properly, without bugs this time."

errors: |
  None reported. Build and full test suite are clean (per prior debug session and code review).
  This is a live interaction/rendering defect not caught by existing automated tests.

reproduction: |
  Open Insights tab, switch to "Month" period (user says most visible there), drag a finger across
  AlcoholAreaChart. Also check Week/Year/AllTime periods and WeekdayBarChart per "affects all charts".

started: |
  Reported immediately after gap-closure plan 05-03 shipped (commits ea58d02, f3db949) which fixed a
  DIFFERENT bug (flicker/clipping via yDomainUpperBound + animation rescoping). Either newly-introduced
  side effects of that fix, or pre-existing defects masked/harder to notice before the callout
  rendered cleanly.

## Eliminated

<!-- APPEND only -->

- hypothesis: "Duplicate/colliding ChartPoint keys cause multiple RuleMarks + annotations to stack, producing illegible overlapping text (would have been period-dependent, matching 'worst in Month')"
  evidence: "ChartPoint.key(for:) = String(date.timeIntervalSinceReferenceDate) — unique per distinct Date, no day/month truncation. The `if selectedKey == ChartPoint.key(for: point.date)` guard can match at most one datum. Confirmed by source read of InsightsChartModels.swift."
  timestamp: 2026-07-31T06:44:00Z

- hypothesis: "The Localizable.xcstrings catalog swallows or reorders the date argument (both callouts compile to Text(LocalizedStringKey), keys '%@ — %@' and '%@ — %@ %@', which DO exist in the catalog)"
  evidence: "Catalog entries are correct positional passthroughs: '%1$@ — %2$@' and '%1$@ — %2$@ %3$@'. Additionally, the on-device isolation build rendered the identical interpolated Text fully and correctly as '25. Jul — 4.0 std' when the glass background was removed — proving the string pipeline is intact."
  timestamp: 2026-07-31T06:45:00Z

- hypothesis: "The annotation content is width-constrained to the mark's band width and the Text is clipped, cutting off the leading date (would explain 'Month worst' — 31 narrow bands vs 7 wide ones)"
  evidence: "On-device isolation build: a bare Text, a Text with .fixedSize(), and a padded Text on a solid yellow background — all three inside the SAME annotation on the SAME RuleMark in the SAME Month period — rendered the complete string '25. Jul — 4.0 std' at full natural width, overflowing far beyond the ~11pt band. There is no width constraint. The ~10pt-wide dark smudge measured in the first screenshot pass was the em dash alone: the densest glyph, the only one whose ink survived above the detection threshold while the thinner strokes fell below it."
  timestamp: 2026-07-31T06:48:00Z

- hypothesis: "The glass chip is merely LOW CONTRAST against the AreaMark's saturated gradient (the secondary contributor recorded by the prior debug session insights-chart-scrub-callout-flicker-clip.md)"
  evidence: "Pixel scan of the chip's rect over a PLAIN WHITE background (area-month dx0.10, an all-zero region of the chart with no gradient behind it) found ZERO pixels differing from the background — the chip and its text are entirely absent, not washed out. Low contrast against the gradient was a red herring; the chip does not render at all, on any background."
  timestamp: 2026-07-31T06:49:00Z

- hypothesis: "Swapping .glassEffect for a system material (.regularMaterial) is a sufficient fix"
  evidence: "Probe build with `.background(.regularMaterial, in: .rect(cornerRadius: 8))` rendered the chip as an OPAQUE BLACK rounded rectangle with no visible text. Materials are broken inside Chart annotations in the same way glass is — both need a compositing backdrop the annotation layer does not provide. Only an opaque `Color` background works."
  timestamp: 2026-07-31T06:52:00Z

## Evidence

<!-- APPEND only -->

- timestamp: 2026-07-31T06:40:00Z
  checked: "Knowledge base (.planning/debug/knowledge-base.md) and .planning/debug/resolved/"
  found: "No knowledge-base.md exists yet. One resolved session (sheet-closes-reopens-loses-state.md), unrelated domain. The directly-relevant prior session is .planning/debug/insights-chart-scrub-callout-flicker-clip.md (status: diagnosed, same two files)."
  implication: "No known-pattern shortcut. The prior session is the strongest prior: it already recorded 'RuleMark(x: .value(...)) has no y specified → spans full plot height' as an observed fact but treated it as incidental, never as a defect. That observation is the seed of symptom 1."

- timestamp: 2026-07-31T06:42:00Z
  checked: "drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift + WeekdayBarChart.swift (full, current post-05-03 source)"
  found: |
    Both charts: `RuleMark(x: .value(...))` with NO `y:` argument, `.annotation(position: .top,
    overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart)))`. No `PointMark` anywhere in
    either file, nor any `.symbol()` on the LineMark. `.chartYScale(domain: 0...yDomainUpperBound)`
    where `yDomainUpperBound = max(peak * 1.6, 1)` (added by 05-03). Frame heights unchanged
    (100pt / 160pt) per 05-UI-SPEC lock.
    BOTH callouts DO contain the X value in their text:
      AlcoholAreaChart: Text("\(date.formatted(.dateTime.month(.abbreviated).day())) — \(formattedValue(grams))")
      WeekdayBarChart:  Text("\(bar.label) — \(String(format: "%.1f", displayValue(bar))) \(unitLabel)")
  implication: |
    Symptom 1 is explained by construction, not by a subtle runtime fault: an annotation anchored
    `.top` on a full-plot-height RuleMark has a CONSTANT screen Y for every X. Nothing in either file
    marks the data's own height. Symptom 2 is NOT a missing-string bug at the source level — the X
    value is in both format strings — so the cause must be rendering/perception, not string content.

- timestamp: 2026-07-31T06:44:00Z
  checked: "drinkpulse/Features/Insights/InsightsChartModels.swift — ChartPoint.key(for:)"
  found: "key(for:) = String(date.timeIntervalSinceReferenceDate) — globally unique per distinct Date, no truncation to day/month granularity."
  implication: "Rules out the 'duplicate key → multiple stacked RuleMarks/annotations → illegible overlap' hypothesis (which would have been a plausible Month/Year-specific cause). The selection guard can match at most one datum."

- timestamp: 2026-07-31T06:45:00Z
  checked: "drinkpulse/Localizable.xcstrings entries for the LocalizedStringKey keys both callouts actually compile to ('%@ — %@' for AlcoholAreaChart, '%@ — %@ %@' for WeekdayBarChart — Text(String literal with interpolation) resolves to Text(LocalizedStringKey), not Text(verbatim:))"
  found: "Both keys exist with correct positional passthrough values: '%1$@ — %2$@' and '%1$@ — %2$@ %3$@' (state: new, en only)."
  implication: "ELIMINATES the localization-catalog category as a cause of the missing X value — the catalog does not drop or reorder the date argument. Worth noting the code is nonetheless relying on implicit LocalizedStringKey interpolation for a non-translatable composed string, which is a latent fragility but not this bug."

- timestamp: 2026-07-31T06:46:00Z
  checked: "drinkpulse/Features/Insights/Components/InsightsHeroCard.swift"
  found: |
    The hero card owns `@State selectedKey` and renders
    `Text(vm.formattedValue(selectedGrams ?? vm.periodTotalGrams))` at 40pt bold — i.e. the Y VALUE of
    the scrubbed point is displayed in a large, unmissable headline that follows the drag.
  implication: |
    Strong support for H2's perception mechanism: during a scrub the user reliably sees the Y value
    (hero headline) but must rely on the small glass chip for the X value. If the chip is illegible or
    absent, the exact complaint 'shows the value but nowhere the X' follows. This also explains why the
    user framed it as 'doesn't show the X value' rather than 'the callout is missing'.

- timestamp: 2026-07-31T06:47:00Z
  checked: "AlcoholAreaChart.xAxisCount (label thinning) vs period"
  found: "week → 7 labels, month → 5, year → 6, allTime → 6. Month plots ~28-31 daily bands but labels only ~5 of them."
  implication: |
    Explains 'most visible in the Month tab': in Week every band has its own axis label, so a user can
    read the X value off the axis even if the chip fails. In Month, ~26 of ~31 bands have no axis label
    at all, so the chip is the ONLY source of the X value — its failure becomes fully visible there.
    This is a strong signal that the chip's legibility, not the period logic, is the variable.

- timestamp: 2026-07-31T06:47:00Z
  checked: "On-device diagnostic run 1 — temporary XCUITest InsightsScrubDiag2UITests driving stationary long-presses (chartXSelection responds to a static press, per the prior session) at 7 X positions across the Month period on AlcoholAreaChart, 4 on Week, 5 on WeekdayBarChart, each screenshotted mid-press via a run-loop Timer, capturing both the full screen and the chart element's own cropped frame."
  found: |
    (a) The RuleMark correctly tracks the touched X in every shot.
    (b) The RuleMark spans the FULL plot height in every shot, top edge to bottom edge.
    (c) The callout sits at the very top of the plot, at an IDENTICAL screen Y in every shot,
        including a 0.0-value X and the dataset's peak X.
    (d) On WeekdayBarChart, the callout floats near the '4' gridline while the selected 'Thu' bar tops
        out at 1.5 — roughly 90pt of empty space between the marker and the datum it describes.
    (e) The callout's text is not legible in ANY shot. In the Month area chart only a ~4pt dark smudge
        is visible; on WeekdayBarChart a faint illegible fragment.
  implication: |
    Symptom 1 CONFIRMED as an anchoring defect, not a data or animation defect: the annotation's Y is
    literally constant. Symptom 2 confirmed as a legibility failure of the whole callout (both the X
    AND the Y value are unreadable) rather than a missing-X-value string bug — which reframes the
    user's report: they read the Y value off the hero headline, so only the X felt absent.

- timestamp: 2026-07-31T06:48:00Z
  checked: "On-device isolation experiment — AlcoholAreaChart.calloutView temporarily replaced with a VStack of 4 variants of the SAME string in the SAME annotation: (A) bare Text, (B) Text + .fixedSize(), (C) Text + padding + solid Color.yellow background, (D) the production callout byte-for-byte (padding + .dpGlassCard(.chip)). One build, one screenshot per X position — every variant experiences an identical width proposal, position and clipping context, so any difference isolates the responsible modifier."
  found: |
    A, B and C rendered '25. Jul — 4.0 std' completely and legibly at full natural width.
    D rendered nothing legible; over an all-zero (plain white) region of the chart a pixel scan of D's
    rect found ZERO pixels differing from the background.
  implication: |
    Single-variable isolation: the string, the width proposal, the annotation position, the
    overflowResolution and the localisation pipeline are all fine — they are shared by A/B/C/D.
    The ONLY difference in D is `.dpGlassCard(.chip)` → `.glassEffect(.regular, in:)`. That modifier
    is the root cause of the unreadable callout.

- timestamp: 2026-07-31T06:50:00Z
  checked: "Apple Developer Forums thread 788041 'Using .glassEffect in Charts' — DTS Engineer (Apple) responses"
  found: |
    Accepted answer from Apple DTS: "Generally speaking, Liquid Glass is not a part of Swift Charts."
    Follow-up from Apple: "Liquid glass should mainly be used on UI control elements that sit above the
    content. Also, currently, there's no dedicated support for liquid glass effects in Charts."
    Apple asked the reporter to file an enhancement request.
  implication: |
    The empirical finding is corroborated by Apple's own statement — this is unsupported API usage, not
    a project bug to work around cleverly. Any fix that keeps `.glassEffect` inside the annotation is
    building on an explicitly unsupported foundation, regardless of whether it happens to render on a
    given OS build.

- timestamp: 2026-07-31T06:46:00Z
  checked: "Apple Charts documentation for RuleMark (developer.apple.com/documentation/charts/rulemark), fetched as DocC JSON"
  found: |
    Verbatim: "To span the plotting area of a chart with a line, omit the optional start and end
    parameters and plot a constant value." The bounded form is `init(x:yStart:yEnd:)`.
    AnnotationOverflowResolution.Strategy docs: `.fit(to:)` = "Fits the annotation to the given
    boundary, ADJUSTING ITS POSITION to ensure it doesn't overflow" — it repositions, it never resizes
    or clips. A separate `.padScale` strategy exists: "Pads the scale of the chart to make space for
    the annotation."
  implication: |
    Documented confirmation of symptom 1's mechanism: `RuleMark(x:)` without yStart/yEnd spans the plot
    BY DESIGN, so `.annotation(position: .top)` is anchored to the plot's top edge. Also confirms
    overflowResolution cannot be responsible for the clipping originally suspected — it only moves
    things. And it shows 05-03's hand-rolled `yDomainUpperBound = peak * 1.6` was reimplementing what
    `.padScale` provides, while addressing an anchor the annotation was never attached to.

- timestamp: 2026-07-31T06:41:00Z
  checked: "The user's referenced article (https://medium.com/@gerastupakov/... 'SwiftUI Charts in iOS 18: Custom Line Chart with Gestures, Symbols & More'), full text"
  found: |
    Its marker technique is `.symbol { CustomSymbol(value:isSelected:) }` attached to the LineMark —
    a per-datum symbol rendered by Swift Charts at the datum's own (x, y), which is why it always sits
    at the data's height. Its tooltip is a CHILD of that symbol view, offset from it
    (`TooltipView(...).offset(y: value > 88 ? 28 : -28)`) — so the callout is positioned relative to
    the DATA POINT, with a hand-rolled flip near the top of the scale instead of relying on
    overflowResolution. Tooltip background is a plain gradient-filled RoundedRectangle, never a
    material or glass. It also sets `.chartYScale(domain: [-10, 110])` to pad both ends.
    Its late-stage switch AWAY from `chartXSelection` to `.chartGesture { proxy in SpatialTapGesture()
    ... }` + `proxy.value(at:)` is motivated solely by composing selection with
    `.chartScrollableAxes`/`chartXVisibleDomain` (the author states the old .chartOverlay +
    GeometryReader tap approach broke on iOS 18) — it is a SCROLLING concern, and its final chart is
    tap-to-select, not drag-to-scrub.
  implication: |
    The article's transferable lessons are (i) put a mark AT the datum, (ii) anchor the callout to that
    mark, (iii) pad the Y scale, (iv) use an opaque background for the tooltip. Its abandonment of
    chartXSelection is NOT transferable — drinkpulse has no scrollable chart axes, and chartXSelection
    is the Apple-sanctioned drag-to-scrub API for exactly this case. Copying the gesture rewrite would
    trade a supported API for a hand-rolled one to solve a problem this project does not have.

- timestamp: 2026-07-31T06:52:00Z
  checked: "On-device fix-direction probe on AlcoholAreaChart (Month period, 7 X positions): bounded `RuleMark(x:yStart:yEnd:)` from 0 to the datum's value + `PointMark(x:y:)` at the datum + `.annotation(position: .top, spacing: 6, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart)))` carrying the same date+value Text. Ran twice: once with `.background(.regularMaterial, in:)`, once with `.background(Color(.secondarySystemGroupedBackground), in:)` + hairline stroke + soft shadow + .fixedSize()."
  found: |
    Marker: the PointMark sits exactly on the curve at every X — at the peak for the peak day, at the
    baseline for a zero day. The callout moves vertically WITH it.
    Callout, `.regularMaterial` run: rendered as an OPAQUE BLACK rounded rectangle, text invisible.
    Callout, solid-Color run: rendered perfectly — "25. Jul — 4.0 std" above the peak, "31. Jul —
    2.0 std" above the last (lower) point, fully legible, with `x: .fit(to: .chart)` correctly shifting
    the chip inward at the right edge so it stays inside the chart.
  implication: |
    The fix direction is verified end-to-end on device, not merely reasoned about. It also yields a
    second, non-obvious constraint for the fix plan: inside a Chart annotation, SwiftUI MATERIALS are
    broken too (opaque black), not just Liquid Glass — the callout background must be an opaque
    `Color`. Note the existing `yDomainUpperBound` headroom becomes genuinely load-bearing under the
    new anchor (it keeps a peak-point callout from being clamped down onto its own point), whereas
    under the old anchor it did nothing for the annotation.

## Resolution

root_cause: |
  TWO independent defects, both in the RuleMark + `.annotation` scrub pattern shared byte-for-byte by
  `AlcoholAreaChart` and `WeekdayBarChart`. Both are code-category; neither is a regression introduced
  by 05-03 — 05-03 only made defect 1 conspicuous.

  ROOT CAUSE 1 (symptom: "the point is always at the same height on the Y plane") —
  The scrub callout is attached to `RuleMark(x: .value(...))` declared WITHOUT `yStart`/`yEnd`. Apple's
  own RuleMark documentation states that omitting those parameters makes the rule span the entire
  plotting area. Its bounding box is therefore the full plot, so `.annotation(position: .top)` anchors
  to the plot's TOP EDGE — a constant screen Y for every X, structurally independent of the data value
  at the touched point. Compounding this, neither chart has a `PointMark` or a `LineMark.symbol`, so
  nothing at all marks the datum's height. Confirmed on device: the annotation renders at a
  pixel-identical Y for a 0.0-value X and for the dataset's peak X.
  05-03's `yDomainUpperBound = max(peak * 1.6, 1)` was justified as "clearance above the peak for the
  .top annotation", but the annotation was never anchored to the peak. What it actually did was push
  the DATA down to ~62% of the plot height while the annotation stayed pinned at the top. That removed
  the old overlap-with-the-fill symptom (which is why the user says the broken chip is gone) and, in
  the same stroke, opened a large visible gap that made the constant anchor obvious — which is why the
  user reported this immediately after 05-03 rather than before it.

  ROOT CAUSE 2 (symptom: "it doesn't show the X value anywhere") —
  The callout is invisible. Not clipped, not low-contrast, not missing the date from its string:
  it renders zero pixels. The cause is `.dpGlassCard(.chip)` → `.glassEffect(.regular, in: .rect(...))`
  applied to the annotation's content. Liquid Glass does not composite inside a Swift Charts
  annotation. Apple DTS states this directly in Developer Forums thread 788041: "Generally speaking,
  Liquid Glass is not a part of Swift Charts" and "currently, there's no dedicated support for liquid
  glass effects in Charts."
  Established by single-variable isolation on device: four variants of the identical string in the
  identical annotation, same build, same screenshot — bare Text, Text + .fixedSize(), and Text on a
  solid colour all rendered "25. Jul — 4.0 std" fully and legibly; the production glass variant
  rendered nothing, and a pixel scan of its rect over a plain-white area of the chart found zero
  non-background pixels. A follow-up probe showed SwiftUI system materials (`.regularMaterial`) are
  equally broken there, rendering as an opaque black rectangle.
  Because BOTH the date and the value are invisible, the user's precise wording ("shows the value but
  nowhere the X") is explained by two aggravating conditions rather than by the callout omitting the
  date: (a) `InsightsHeroCard` renders the scrubbed Y value in a 40pt headline that follows the drag,
  so the Y value never feels missing; (b) in the Month period `xAxisCount` thins the X axis to 5 labels
  across ~31 bands, so the axis cannot supply the date either — which is exactly why the user singled
  Month out. In Week (7 labels for 7 bands) the axis still answers "which day", masking the defect.

fix: "(not applied — goal: find_root_cause_only). Verified direction recorded below."

verification: |
  Fix direction verified on device by probe build (see final Evidence entry), not merely reasoned:
  bounded `RuleMark(x:yStart:yEnd:)` + `PointMark` at the datum + annotation on the PointMark +
  opaque `Color` background produced a marker at the correct data height and a fully legible
  date+value callout at every tested X in the Month period, correctly clamped at the chart edge.
files_changed: []

## Recommended Fix Direction (verified on device, not applied)

Keep `chartXSelection`. It is Apple's supported drag-to-scrub API, it already works correctly (the
RuleMark tracks the touch accurately in every screenshot), and the article's move to
`.chartGesture` + `proxy.value(at:)` was driven by composing selection with `chartScrollableAxes`,
which this project does not use. Migrating to a hand-rolled gesture would replace a working supported
API to fix a problem drinkpulse does not have, and would forfeit chartXSelection's built-in
accessibility and hit-testing.

Change four things instead, identically on both charts:

1. **Add a mark at the datum.** `PointMark(x:, y: <the datum's value>)` inside the existing selection
   guard (or `LineMark.symbol` gated on selection, the article's technique). This is what makes the
   marker's height a function of the data.
2. **Move the `.annotation` from the RuleMark onto that PointMark.** This is the actual fix for
   symptom 1 — the callout then floats above the touched point, not above the plot.
3. **Bound the RuleMark** with `RuleMark(x:yStart:yEnd:)` from 0 to the datum's value so the guide
   reads as a drop line to the point rather than a full-height divider. (Optional but it is what makes
   the marker read as "this value at this X".)
4. **Replace `.dpGlassCard(.chip)` on the callout with an opaque `Color` background** (e.g.
   `Color(.secondarySystemGroupedBackground)`) plus a hairline stroke and a soft shadow. Do NOT
   substitute `.regularMaterial`/`.ultraThinMaterial` — probed, renders opaque black. This is a
   deliberate, documented exception to the project's Liquid Glass design language, justified by Apple's
   own statement that Liquid Glass is not supported in Swift Charts; it is worth an ADR or a UI-SPEC
   note so a future pass does not "restore" the glass chip and silently reintroduce the bug.

Keep `yDomainUpperBound` (05-03's headroom). Under the new anchor it finally does what its comment
claims: it stops a peak-point callout from being clamped down onto its own PointMark. `.padScale` is
the first-party alternative worth considering.

Secondary, non-blocking cleanups surfaced during the investigation:
- Both callouts use `Text("...\(a) — \(b)")`, which resolves to `Text(LocalizedStringKey)` and has
  auto-generated `"%@ — %@"` / `"%@ — %@ %@"` entries in `Localizable.xcstrings`. The catalog is
  currently a correct passthrough so this is not the bug, but a composed non-translatable display
  string should use `Text(verbatim:)` to stop polluting the catalog with positional-format keys.
- `AlcoholAreaChart.calloutView` wraps its `Text` in `Group { if let grams { ... } }`. If that lookup
  ever returned nil the result would be an empty padded chip rather than no callout. With the callout
  moving onto the PointMark, `point.grams` is available directly in the closure — drop the lookup and
  the optional entirely.
- The existing `InsightsScrubUITests` cannot see this class of defect: Swift Charts annotation content
  is not in the accessibility tree, so the suite asserts on the hero headline and on the RuleMark's own
  element instead. A regression guard for "the callout is legible / the marker is at the data height"
  needs pixel evidence (an `XCUIScreen`/element screenshot assertion), not an a11y-tree query — worth
  deciding explicitly rather than leaving the gate absent.

## Diagnostic Artifacts (not committed)

A temporary XCUITest (`drinkpulseUITests/Features/Insights/InsightsScrubDiag2UITests.swift`) and three
temporary variants of `AlcoholAreaChart.calloutView`/`chart` were created, run, screenshotted, and then
fully reverted. `git status` is clean apart from this debug file. Screenshots and the pixel-analysis
scripts live only in the session scratchpad; the findings they support are transcribed into Evidence
above.
