# Project Research Summary

**Project:** DrinkPulse v1.3 "Native Feel" milestone
**Domain:** Native iOS polish additions (Swift Charts scrubbing, cross-container directional transition, branded launch screen) to an existing production SwiftUI/SwiftData app
**Researched:** 2026-07-28
**Confidence:** MEDIUM-HIGH

## Executive Summary

This milestone is not greenfield work — it is three additive, mutually-independent polish features layered onto an already-shipped MVVM + `@Observable` + SwiftData codebase whose architectural patterns are fixed by `docs/architecture.md` and `CLAUDE.md`. All three features (chart drag-to-scrub, directional List↔Calendar transition, branded launch screen) are achievable entirely with first-party frameworks already linked in the target (`Charts`, `SwiftUI`, `Accessibility`) plus Xcode project configuration — no new SPM dependency, no new capability, no backend or network surface. The headline finding across all four research files is consistent: use more of what's already linked, don't build custom mechanisms for problems Apple's frameworks already solve (`chartXSelection` instead of hand-rolled `DragGesture`; `.transition`/`.animation` instead of third-party animation libs; `UILaunchScreen` Info-tab config instead of a storyboard).

The recommended approach is: (1) ship the branded launch screen first (smallest surface area, zero Swift code, fastest low-risk win), (2) chart scrubbing second (medium scope, low architectural risk, but a genuinely new `accessibilityChartDescriptor` implementation with no existing precedent in the codebase), and (3) the History slide transition last (smallest code diff but highest discovery risk due to the structural mismatch between `List` and `ScrollView` containers). The three features share no files, no view model, and no DesignSystem component required by more than one, so they are also safe to parallelize across sessions/engineers if sequencing isn't required.

The key risks are consistent across FEATURES.md, ARCHITECTURE.md, and PITFALLS.md: (a) shipping `chartXSelection` scrubbing without extending `accessibilityChartDescriptor` in the same change, silently breaking VoiceOver parity — a CLAUDE.md-mandatory accessibility requirement, not optional polish; (b) treating the `List`-vs-`ScrollView` directional transition as a trivial `.transition(.slide)` bolt-on, when the two containers' different internal chrome and `@Query` re-fetch timing can produce visible pops/flashes only discoverable on a real device with real data; and (c) verifying the launch screen only in Simulator warm-relaunch instead of a genuine force-quit cold launch on a physical device, which is the actual scenario the underlying user complaint concerns. All three risks are mitigated by explicit device-based verification steps and reusing the codebase's existing `reduceMotion` and formatting-layer conventions rather than inventing new ones.

## Key Findings

### Recommended Stack

No new stack elements are required. All work uses frameworks already imported in the target: Swift Charts (`chartXSelection(value:)`, `RuleMark` + `.annotation`), `Accessibility` (`accessibilityChartDescriptor`/`AXChartDescriptorRepresentable` — needs its own `import Accessibility`, not re-exported by Charts), plain SwiftUI (`.transition(.asymmetric(insertion:removal:))`, `.animation(_:value:)`), and Xcode target build settings (`UILaunchScreen` Info-tab dictionary, replacing `INFOPLIST_KEY_UILaunchScreen_Generation = YES`). The one flagged gap: the exact mechanics of adding `UILaunchScreen` via Xcode's Info tab when `GENERATE_INFOPLIST_FILE = YES` (no physical `Info.plist`) could not be confirmed from an authoritative source and should be hand-verified in Xcode before committing to the approach — the fallback, if it doesn't "just work," is a small standalone `Info.plist` merged via `INFOPLIST_FILE`.

**Core technologies:**
- `Chart.chartXSelection(value:)` (Swift Charts, iOS 17+) — native drag-to-select, replacing any hand-rolled `DragGesture` — system-provided gesture/haptics/animation.
- `RuleMark` + `.annotation(position:)` — idiomatic scrub-readout callout, styled with existing `dpGlassCard(.chip)` rather than a bespoke bubble.
- `accessibilityChartDescriptor(_:)` / `AXChartDescriptorRepresentable` (`Accessibility` framework, iOS 17+) — first-ever implementation in this codebase; required for VoiceOver parity with the new visual scrub interaction.
- `.transition(.asymmetric(insertion:removal:))` + `.animation(_:value:)` — directional slide between `HistoryView`'s List/Calendar branches; no new framework, just correct usage.
- `@Environment(\.accessibilityReduceMotion)` — reuse the exact existing pattern at `OnboardingView.swift:80`.
- Xcode target "Info" tab `UILaunchScreen` dictionary (`UIImageName`, `UIColorName`) — zero-code, zero-framework project-configuration change.

### Expected Features

**Must have (table stakes / P1):**
- `.chartXSelection(value:)` drag-to-read on `AlcoholAreaChart` and `WeekdayBarChart` with a glass-styled `RuleMark` callout.
- `accessibilityChartDescriptor` extended so VoiceOver retains per-point access.
- Directional slide transition between History List/Calendar segments honoring `reduceMotion`, correctly handling all three states (list / calendar / empty).
- Branded static launch screen (icon + matching background, no text, no spinner) replacing the generated blank one.

**Should have (differentiators, P2):**
- Hero-card headline following the chart selection while scrubbing, reverting to period total on release (open design decision, not a hard requirement).

**Defer (v2+ / P3):**
- `chartXSelection(range:)` multi-point range selection.
- Fully custom segmented-control indicator with `matchedGeometryEffect`.
- Row-level insert/delete animation inside the History `List` (separate related todo).
- Any animation/spinner/wordmark on the launch screen — explicitly an anti-feature.

### Architecture Approach

All three features are additive to the existing Views/DesignSystem layer; none touch Domain or Services. Keep new transient/gesture state (chart selection, previous-segment tracking) in the View layer — never on `InsightsViewModel` or `HistoryViewModel`, both of which currently hold zero or only persistence/navigation-derived state.

**Major components:**
1. `AlcoholAreaChart` / `WeekdayBarChart` — view-local `@State` selection via `chartXSelection`, resolved through the existing `dateByKey` map; bubbles to `InsightsHeroCard` via closure, never through the VM.
2. `InsightsHeroCard` — owns `@State private var selectedPoint`, switches headline source between selection and `vm.periodTotalGrams`, formatted via `InsightsViewModel+Formatting`.
3. `HistoryView` — owns new `@State` for previous-segment/transition-edge tracking (derived from `HistorySegment.allCases`), applied to a `.transition(.asymmetric(...))`; `HistoryViewModel` stays untouched.
4. `project.pbxproj` build settings + `Assets.xcassets` — launch screen is 100% Xcode-config + one new flattened image asset exported from `AppIcon.icon` (Icon Composer format cannot be referenced directly).

**Suggested build order (risk-discovery-cost):** launch screen → chart scrubbing → History transition.

### Critical Pitfalls

1. **`chartXSelection` becomes the only path to a value, silently breaking VoiceOver parity** — extend `accessibilityChartDescriptor` in the same change, test with VoiceOver on.
2. **Directional slide between `List` and `ScrollView` produces pops/flashes** — test with real `HistoryListQueryView` and realistic data on device; handle all three states.
3. **`@Query`-backed list re-fetches mid-transition, causing pop-in** — check residency (opacity/zIndex vs. recreate); test right after add/delete/edit.
4. **`reduceMotion` applied inconsistently or as "less" instead of "no" animation** — reuse `OnboardingView.swift:80` idiom per new animated surface.
5. **Launch screen verified only via Simulator warm relaunch** — require a genuine force-quit cold launch on a real device.

## Implications for Roadmap

### Phase 1: Branded Static Launch Screen
**Rationale:** Smallest surface area, zero Swift source touched, fastest low-risk win, no dependency on other phases.
**Delivers:** `UILaunchScreen` Info-tab config referencing a new flattened image asset; background matches app's real first screen.
**Addresses:** Branded launch screen, visual continuity (FEATURES.md table stakes).
**Avoids:** Pitfall 5 — gate "done" on real-device cold-launch check.

### Phase 2: Insights Chart Scrubbing
**Rationale:** Medium scope, low architectural risk; `accessibilityChartDescriptor` is genuinely new and needs dedicated budget.
**Delivers:** `.chartXSelection(value:)` + `RuleMark`/annotation on both charts, shared `DPChartSelectionCallout` component, first-ever `accessibilityChartDescriptor` implementations, new UI tests.
**Uses:** Swift Charts, `Accessibility` framework, existing formatting/reduceMotion patterns.
**Implements:** Chart → `InsightsHeroCard` selection data flow per ARCHITECTURE.md.

### Phase 3: History List↔Calendar Directional Transition
**Rationale:** Smallest diff, highest discovery risk (container mismatch); sequenced last to isolate risk.
**Delivers:** `.transition(.asymmetric(...))` driven by new direction-tracking `@State` in `HistoryView`; handles empty-state branch; extended UI tests.
**Addresses:** Directional transition, reduceMotion (table stakes).
**Avoids:** Pitfalls 2 and 3 — requires real-device verification with realistic dataset and post-mutation testing.

### Phase Ordering Rationale
- All three phases are independent; order driven by risk-discovery cost.
- Grouping matches ARCHITECTURE.md's component boundaries exactly (config+assets / Insights / History).
- Launch screen first banks a cheap win; History last isolates the least-predictable risk.

### Research Flags
- **Needs research:** Phase 3 (History transition) — List/ScrollView cross-container mismatch has no clean documented answer; flag for `--research-phase` if the naive approach looks broken.
- **Standard patterns (skip research):** Phase 1 (launch screen — well-documented HIG pattern) and Phase 2 (chart scrubbing — well-trodden iOS 17+ APIs).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | APIs cross-checked; Xcode launch-screen mechanics unverified — needs hands-on check. |
| Features | MEDIUM | No MCP research providers enabled; WebSearch/WebFetch only, cross-checked where possible; anchored by direct codebase reads (HIGH). |
| Architecture | HIGH | Grounded in direct reads of current codebase, not general docs. |
| Pitfalls | MEDIUM | Well-documented primitives, but the two combined patterns (chartXSelection+accessibility, cross-container transitions) are synthesized, not sourced directly. |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address
- **Launch screen Xcode mechanics:** verify hands-on in Xcode during Phase 1 before committing; fallback is a standalone `Info.plist` merged via `INFOPLIST_FILE`.
- **List vs. ScrollView transition behavior:** verify on real device with realistic data during Phase 3; be ready to fall back to crossfade.
- **Hero-card scrub-follow behavior:** decide and test explicitly during Phase 2, including reduceMotion on the revert transition.

## Sources

### Primary (HIGH confidence)
- Direct codebase reads: `Features/Insights/*`, `Features/History/*`, `project.pbxproj`, `Assets.xcassets`, `AppIcon.icon/icon.json`, `DesignSystem/DPGlass.swift`, `OnboardingView.swift`.
- `.planning/codebase/ARCHITECTURE.md`, `CONCERNS.md`, CLAUDE.md.
- `.planning/todos/pending/2026-07-26-*`, `2026-07-27-branded-static-launch-screen.md`.
- Apple HIG — Launching.

### Secondary (MEDIUM confidence)
- Swift with Majid — Charts Selection/Accessibility articles (cross-checked).
- Cross-checked search on Apple's launch-screen text/localization guidance.

### Tertiary (LOW confidence)
- Kodeco, createwithswift.com, swiftuirecipes.com, Level Up Coding, Medium/nilcoalescing.com articles.
- Apple Developer Forums threads on `@Query` refresh timing.
- Use Your Loaf / Viget launch-screen articles.

---
*Research completed: 2026-07-28*
*Ready for roadmap: yes*
