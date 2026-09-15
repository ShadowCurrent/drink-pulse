# Feature Research

**Domain:** Native iOS "feel" polish — chart scrubbing, segmented-control content transitions, branded launch screen (v1.3 milestone, DrinkPulse)
**Researched:** 2026-07-28
**Confidence:** MEDIUM (web-only research; no MCP docs/search providers enabled in project config — see Sources)

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist on a native iOS 26 app with charts, a segmented History view, and a real app icon. Missing these makes the app feel unfinished or feel like a cross-platform port.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Chart drag-to-scrub with value readout | Every first-party Apple chart surface (Health, Stocks, Fitness, Weather) lets you drag a finger across a trend line and see the exact value/date under your finger. A chart that only shows shape but not values reads as "just a picture," not a data tool. | MEDIUM | Native mechanism is `.chartXSelection(value:)` bound to `@State`, rendering a `RuleMark`/`PointMark` + `.annotation` callout on selection. This is now the expected baseline implementation, not a stretch goal — the old `chartOverlay` + `GeometryReader` + `DragGesture` + `value(forX:)` hand-rolled pattern is legacy and would look/feel non-native (no built-in haptics/snap behavior). |
| Chart accessibility parity with the visual scrub | If dragging reveals per-point values, VoiceOver users must get equivalent per-point data — Apple's own accessibility guidelines require this, and Swift Charts already builds a baseline accessibility tree (audio graph) for free. | LOW–MEDIUM | `AlcoholAreaChart`/`WeekdayBarChart` already carry a coarse `.accessibilityLabel`; per-point access needs `accessibilityChartDescriptor` (`AXChartDescriptorRepresentable` + `AXNumericDataAxisDescriptor`/`AXCategoricalDataAxisDescriptor`, iOS 17+) so VoiceOver's audio-graph gesture surfaces the same values a sighted user gets by scrubbing. Omitting this is a CLAUDE.md accessibility-rule violation, not just a nice-to-have. |
| Directional transition when switching List↔Calendar | On iOS, tab/segment switches between structurally different content (e.g. Photos' grid vs list, Mail's flat/threaded) always animate — an instant hard swap with no motion reads as unstyled/broken, especially post-iOS 26 Liquid Glass where motion is a core part of the visual language. | LOW–MEDIUM | `HistoryView.swift:67-74` currently has zero animation (`Group { switch segment {...} }`, no `.transition`, no `.animation(_:value:)`). Table stakes here is *any* smooth cross-fade/slide, not necessarily direction-aware — but a same-direction slide regardless of forward/back navigation looks visibly wrong once shipped, so directionality is effectively part of "not broken" for this feature, not a bonus. |
| `reduceMotion` respected on the transition | CLAUDE.md accessibility rule + Apple platform convention: any custom transition must degrade to a plain cross-fade/instant swap under Reduce Motion. | LOW | Existing precedent already in the codebase: `Features/Onboarding/OnboardingView.swift:80` uses `.animation(reduceMotion ? nil : .someCurve, value:)` — reuse that pattern rather than inventing a new one. |
| Branded (non-blank) launch screen | A blank white/generated launch screen on cold launch reads as an unfinished or unbranded app; every shipped App Store app has *at minimum* its icon on launch. | LOW | Currently `INFOPLIST_KEY_UILaunchScreen_Generation = YES` (project.pbxproj:418,453) — Xcode's auto-generated blank screen. Fix is a static `UILaunchScreen` (Info.plist key or storyboard) showing the existing `AppIcon.icon` asset on a background color matching the app's actual first screen. |
| Launch screen visually continuous with first real screen | Apple HIG: the launch screen should be "nearly identical" to the app's actual first screen (matching background color/icon placement) so there's no visible flash/mismatch between launch screen and first frame. | LOW | Background color must match whatever `RootView`/`DashboardView` actually renders as its base background — verify against current design tokens, don't introduce a new color. |

### Differentiators (Competitive Advantage)

Not required for the feature to "work," but the level of polish that separates a good implementation from a merely-adequate one — and align with the milestone's explicit "feel native iOS 26" goal.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Hero-card headline follows the scrub selection, reverts on release | Health/Stocks-style apps update a large "you are looking at THIS point" headline while scrubbing, then snap back to the period summary on release — it makes the scrub feel connected to the rest of the screen, not just a floating tooltip. | MEDIUM | Already flagged as an open design decision in the source todo (`2026-07-26-scrub-insights-charts-for-per-point-values.md`): "probably follow selection while scrubbing, revert on release." Requires wiring `InsightsViewModel+Formatting` output into the hero card conditionally on selection state. |
| Range selection (`chartXSelection(range:)`) in addition to point selection | Lets a user drag to see a multi-day/week total, not just a single point — useful on the weekly bar chart for "how much did I drink this week" without leaving the screen. | MEDIUM–HIGH | Genuine differentiator, not table stakes; adds a second interaction mode and formatting path. Defer unless a specific product need surfaces — the todo scopes only single-point `chartXSelection(value:)` as the target. |
| Custom-styled selection callout using Liquid Glass tokens | A stock `.regularMaterial` callout works, but matching the app's existing `DesignSystem` glass-surface tokens (rather than a bespoke bubble) makes the scrub feel like it belongs to *this* app specifically, not a generic Swift Charts tutorial. | LOW | Explicitly requested in the todo: "styled with existing DesignSystem tokens (Liquid Glass surface, not a bespoke bubble)." Low cost since the tokens already exist — just needs to be applied to the annotation. |
| Custom segmented-control indicator animation (sliding pill) | Beyond content-pane transitions, some native-feeling apps also animate the segmented control's own selection indicator with `matchedGeometryEffect` for a fluid, continuous feel between tap and content swap. | MEDIUM | Out of scope of the current todo (which targets `Picker(.segmented)`, the system control) — a fully custom segmented control is a bigger, separate investment with its own accessibility re-implementation cost (system `Picker` gets VoiceOver/Dynamic Type support for free; a custom one does not). Do not bundle into this milestone. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|------------------|-------------|
| Hand-rolled `DragGesture` + custom hit-testing for chart scrubbing | Seems like more control over the interaction, and is what pre-iOS 17 tutorials show. | Reinvents haptics, snapping, and accessibility wiring that `.chartXSelection` already provides for free; more code, more bugs, and it was explicitly the thing the user asked to *avoid* ("not a hand-rolled DragGesture... hack") because it doesn't feel native. | `.chartXSelection(value:)` / `.chartXSelection(range:)` — the first-party API. |
| Animated/spinner launch screen | Feels like it would reduce perceived wait time on a slow cold launch. | `UILaunchScreen` is static UIKit-side configuration by design — it is a still image and *cannot* animate, regardless of implementation effort; any animation attempt either fails silently or requires abandoning the native launch-screen mechanism entirely (which Apple discourages). | Static icon + matching background only; any animated "loading" affordance belongs to the in-app `StartupErrorView`/loading state (already shipped in v1.2, gated on the separate async-container work), not the launch screen. |
| Wordmark / app name text on the launch screen | Feels more "branded" than an icon alone. | Apple HIG explicitly discourages launch-screen text because a static launch screen cannot be localized per-runtime-locale — any text baked in will not match the user's language at launch time. (DrinkPulse is English-only per CLAUDE.md, which softens the localization argument somewhat, but it's still Apple's own stated guidance and a common source of launch-screen review friction.) | Icon + background color only, consistent with `AppIcon.icon`; skip the wordmark. |
| Full custom List↔Calendar cross-fade using two live `@Query`-backed views mounted simultaneously | Seems like the natural way to overlap outgoing/incoming content during a slide. | The two branches are structurally different containers (`List` via `HistoryListQueryView` vs `ScrollView` via `HistoryCalendarQueryView`), each independently `@Query`-driven and re-fetching on appearance — keeping both mounted during a transition risks visible row-content popping in mid-slide and duplicate/racing fetches, called out explicitly in the source todo. | Standard SwiftUI `.transition` on a `switch`, letting the outgoing view unmount and incoming view remount per the normal SwiftUI diffing/transition lifecycle — verify on-device that the query doesn't visibly race the animation, but don't try to keep both alive concurrently. |
| Direction inferred purely from raw enum `.rawValue`/case order without an explicit "previous segment" state | Looks like a shortcut — "just compare hashValue/rawValue of old vs new." | Fragile if `HistorySegment` cases are ever reordered or a third segment is added later; also doesn't actually need the raw value, just an ordering. | Track the previous `segment` explicitly (e.g. a `@State private var previousSegment` set right before mutating `segment`, or derive index via `HistorySegment.allCases.firstIndex(of:)`) so direction logic is intention-revealing and resilient to enum changes. |

## Feature Dependencies

```
[Chart scrubbing: chartXSelection] ──requires──> [Existing categorical X-axis key scheme in AlcoholAreaChart/WeekdayBarChart]
                                                       └── both charts encode X as a String band-key (`key(for: point.date)`),
                                                           not a raw Date — selection binding + reverse lookup (dateByKey) must
                                                           round-trip through that key, adding a small mapping step vs a plain
                                                           continuous Date-axis chart.

[Chart scrubbing: value callout] ──requires──> [InsightsViewModel+Formatting] (existing formatting layer)
                                                    └── value display must go through the existing AlcoholUnit-aware
                                                        formatter, never format inline in the chart view (per todo).

[Chart scrubbing: accessibility] ──requires──> [Existing .accessibilityLabel on charts, extended to accessibilityChartDescriptor]
                                                    └── scrubbing must not become the ONLY path to values — VoiceOver path
                                                        is additive, not a replacement.

[Hero-card-follows-selection differentiator] ──enhances──> [Chart scrubbing: chartXSelection]
                                                                └── optional; requires the base scrubbing feature first.

[List↔Calendar slide transition] ──requires──> [Directional/previous-segment tracking]
                                                     └── a plain `.transition(.slide)` without direction tracking looks
                                                         wrong on the "back" direction (list→calendar vs calendar→list).

[List↔Calendar slide transition] ──requires──> [reduceMotion handling]
                                                     └── CLAUDE.md accessibility rule; reuse OnboardingView.swift:80 pattern.

[List↔Calendar slide transition] ──conflicts-with──> [Keeping both List and ScrollView query views mounted simultaneously]
                                                            └── risks row-content pop-in mid-slide + duplicate @Query re-fetch races.

[Branded launch screen] ──requires──> [Existing AppIcon.icon asset] (no new artwork)

[Branded launch screen] ──conflicts-with──> [Any progress indicator / animation / wordmark text on the launch screen itself]
                                                  └── UILaunchScreen is static by platform design; animated/loading UI belongs
                                                      to the separate async-container startup work (v1.2, already shipped),
                                                      not this feature.
```

### Dependency Notes

- **Chart scrubbing requires the existing categorical key scheme:** both `AlcoholAreaChart` and `WeekdayBarChart` plot X as a stable `String` band-key derived from `Date` (per the file's own header comment: "X is a categorical (band) scale keyed per point"), with a `dateByKey` reverse-lookup dictionary already present in `AlcoholAreaChart`. `.chartXSelection(value:)` must bind to that same `String` key type (matching whatever type is passed to `.value(...)` in the marks), then resolve back to a `Date`/`ChartPoint` via the existing `dateByKey` map to drive the value callout and the formatting layer. This is a small but real implementation wrinkle vs. a chart with a plain continuous `Date` x-axis — flag for planning, not a blocker.
- **Value callout requires existing formatting layer:** the todo is explicit that the selected value must be formatted via `InsightsViewModel+Formatting`, never inline in the view, to keep `AlcoholUnit` (grams/units/standard-drinks) consistent with the rest of the screen.
- **List↔Calendar transition requires previous-segment tracking:** `HistoryView.swift:64-79` currently switches on `segment` with no memory of the prior value — a directional slide needs that memory (either a stored `previousSegment` or an index comparison against `HistorySegment.allCases`) before a `.transition(.asymmetric(...))` can pick the correct edge per direction.
- **List↔Calendar transition conflicts with dual-mount cross-fades:** because `listContent` resolves to a real `List` (`HistoryListQueryView`, `.insetGrouped`) and `calendarContent` is a `ScrollView` (`HistoryCalendarQueryView`), both independently `@Query`-driven, any transition strategy that tries to render both simultaneously (e.g. an overlapping cross-fade) risks visible re-fetch races and layout jumps — the safer default is the standard mount/unmount `.transition` lifecycle, verified on-device.
- **Launch screen conflicts with anything dynamic:** `UILaunchScreen` is a static, pre-process asset — no SwiftUI, no animation, no localized text is technically renderable at the moment it displays. Any "make the wait feel shorter" ambition belongs entirely to the separate, already-shipped async-container/`StartupErrorView` work (v1.2), not to this feature.

## MVP Definition

### Launch With (v1.3 milestone)

Minimum viable scope per the three todos already scoped into `.planning/PROJECT.md` Active requirements:

- [ ] `.chartXSelection(value:)` drag-to-read on `AlcoholAreaChart` and `WeekdayBarChart`, with `RuleMark`/annotation callout using existing DesignSystem glass tokens — essential: this is the entire ask of the todo, and the native API is genuinely low-effort relative to a hand-rolled gesture.
- [ ] `accessibilityChartDescriptor` extended/kept alongside scrubbing so VoiceOver retains per-point access — essential: non-negotiable per CLAUDE.md accessibility rules, and the todo calls it out explicitly as a constraint, not an option.
- [ ] Directional slide transition between History List and Calendar segments, honoring `reduceMotion`, verified against the three-state reality (list / calendar / empty-state) — essential: this is the entire ask, and shipping a same-direction-always slide would still look wrong (defeats the purpose).
- [ ] Branded static launch screen (icon + matching background, no text) replacing the generated blank one — essential: this is the entire ask, and is explicitly scoped as the "low-risk half" of a previously-split todo.

### Add After Validation (v1.3.x)

- [ ] Hero-card headline following the chart selection during scrub (revert to period total on release) — the todo itself flags this as an open design decision ("probably... decide"), not a hard requirement; ship the baseline scrub first, confirm it feels right, then decide.

### Future Consideration (v2+, not this milestone)

- [ ] `chartXSelection(range:)` multi-point range selection on charts — genuinely useful but a distinct interaction mode with its own formatting/UI needs; not requested by the current todo.
- [ ] Fully custom segmented control with `matchedGeometryEffect` sliding-pill indicator — bigger investment (re-implements what system `Picker(.segmented)` gives for free, including accessibility), and out of scope of the current todo which targets the system control's content transition, not the control itself.
- [ ] Row-level insert/delete animation inside the History `List` — explicitly called out in the slide-transition todo as a *related but deliberately separate* piece of work (`2026-07-26-animate-history-list-row-insert-delete.md`), tracked independently; only keep animation curves consistent if both land together.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|----------------------|----------|
| Chart scrubbing (`chartXSelection` + callout) | HIGH | MEDIUM | P1 |
| Chart accessibility parity (`accessibilityChartDescriptor`) | HIGH (accessibility-blocking, not optional) | LOW–MEDIUM | P1 |
| List↔Calendar directional slide transition | MEDIUM | MEDIUM | P1 |
| `reduceMotion` fallback on the transition | HIGH (accessibility-blocking) | LOW | P1 |
| Branded static launch screen | MEDIUM | LOW | P1 |
| Hero-card follows scrub selection | MEDIUM | MEDIUM | P2 |
| Range selection on charts | LOW–MEDIUM | MEDIUM–HIGH | P3 |
| Custom segmented-control indicator animation | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for this milestone (already the explicit scope of the three todos)
- P2: Should have, add once P1 ships and the design decision it depends on is settled
- P3: Nice to have, defer to a future milestone

## Competitor / Reference-App Feature Analysis

| Feature | Apple Health | Apple Stocks | DrinkPulse's Approach |
|---------|--------------|--------------|------------------------|
| Chart scrubbing | Drag anywhere on a trend chart shows a value callout at the touched point; native Swift Charts selection under the hood | Drag across the price chart shows price + date at the touched point, with a vertical rule line | Same pattern: `.chartXSelection(value:)` + `RuleMark`/annotation, styled with DrinkPulse's own Liquid Glass tokens rather than system defaults |
| List/grid segment switching | N/A (Health uses tab-based navigation, not a segmented content swap in the same screen) | N/A (single continuous chart, not a segmented List/Calendar swap) | No direct first-party analog for *this exact* interaction inside a single screen — closest precedent is Photos' grid/list toggle, which does animate; DrinkPulse implements its own directional `.transition` since there's no single off-the-shelf API for this exact case |
| Launch screen | Icon on branded background, no text, no spinner | Icon on branded background, no text, no spinner | Icon (`AppIcon.icon`) on background matching the app's real first screen, no wordmark, no progress indicator — matches the Apple-app norm exactly |

## Sources

- No MCP research providers were enabled for this project (`brave_search`, `exa_search`, `firecrawl`, `tavily_search`, `ref_search`, `perplexity`, `jina` all `false` in `.planning/config.json`); all research below used the built-in `WebSearch`/`WebFetch` tools, which the research-plan seam classifies as **LOW confidence** by default (MEDIUM where a claim was cross-checked across two independent searches, noted below).
- [Swift with Majid — Mastering charts in SwiftUI: Selection](https://swiftwithmajid.com/2023/07/18/mastering-charts-in-swiftui-selection/) — `chartXSelection` binding pattern, `RuleMark` + `.annotation` callout, `chartXSelection(range:)` for ranges. MEDIUM/LOW confidence (single independent author blog, but consistent with known Swift Charts API shape).
- [Swift with Majid — Mastering charts in SwiftUI: Accessibility](https://swiftwithmajid.com/2023/02/28/mastering-charts-in-swiftui-accessibility/) and [Making charts accessible with Swift Charts (createwithswift.com)](https://www.createwithswift.com/making-charts-accessible-with-swift-charts/) — `accessibilityChartDescriptor` / `AXChartDescriptorRepresentable` mechanism, baseline auto-accessibility tree. LOW confidence (community sources, not Apple docs directly fetched).
- [Drag to Select in SwiftUI Charts — swiftuirecipes.com](https://swiftuirecipes.com/blog/drag-to-select-in-swiftui-charts) and [SwiftUI: Interactive Charts — Level Up Coding](https://levelup.gitconnected.com/swiftui-interactive-charts-c222f9d7133f) — legacy `chartOverlay` + `GeometryReader` + `DragGesture` pattern vs. modern `chartXSelection` one-liner. LOW confidence.
- [SwiftUI segmented Picker with sliding animation — Medium](https://medium.com/@myshkinasasha/swiftui-segmented-picker-with-sliding-animation-f239c57ff191) and [Custom segmented control with matchedGeometryEffect — nilcoalescing.com](https://nilcoalescing.com/blog/CustomSegmentedControlWithMatchedGeometryEffect/) — `matchedGeometryEffect` is for the selection indicator, not content-pane transitions. LOW confidence.
- Apple Developer Forums thread on `SwiftUI Transition Animation with LazyVGrid` (surfaced via search, not fetched directly) — general confirmation that `.transition` + `.animation(value:)` is the standard SwiftUI mechanism for content-swap animation. LOW confidence (not independently fetched).
- [Apple HIG — Launching (developer.apple.com/design/human-interface-guidelines/launching)](https://developer.apple.com/design/human-interface-guidelines/launching) — static launch screen, no progress indicators, should mirror the app's actual first screen. **MEDIUM confidence** (Apple's own documentation, fetched directly, and cross-checked against a second independent search on the "avoid text / localization" guidance below).
- Cross-check search on "Apple HIG launch screen never include text elements localization" — confirms Apple's own stated reasoning: launch-screen text can't be localized because the screen is static, so a wordmark/text label is discouraged by Apple's guidance itself, not just a style preference. **MEDIUM confidence** (same claim surfaced independently across two separate searches).
- Existing codebase read directly (ground truth, not web research): `drinkpulse/Features/History/HistoryView.swift`, `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift`, and the three source todos in `.planning/todos/pending/` — used to anchor dependency and complexity claims to the actual current code, not assumptions.

---
*Feature research for: Native iOS "feel" polish (chart scrubbing, segmented content transitions, branded launch screen)*
*Researched: 2026-07-28*
