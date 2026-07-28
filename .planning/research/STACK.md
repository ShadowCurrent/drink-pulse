# Stack Research

**Domain:** iOS native-feel additions to an existing SwiftUI/SwiftData app (chart scrubbing, directional container transition, branded launch screen)
**Researched:** 2026-07-28
**Confidence:** MEDIUM (Swift Charts/Accessibility APIs cross-checked against multiple current sources; the launch-screen build-setting mechanics for a `GENERATE_INFOPLIST_FILE = YES` target could not be confirmed against an authoritative source and are flagged LOW below — verify hands-on in Xcode before committing to the approach)

## Recommended Stack

**Headline finding: nothing in this milestone requires a new framework, a new SPM package, or a new Xcode capability.** All three features are covered by frameworks already imported and used elsewhere in the app (`Charts`, `SwiftUI`, `Accessibility`) plus Xcode project configuration. The work is "use more of what's already linked," not "add dependencies."

### Core Technologies

| Technology | Version / Availability | Purpose | Why Recommended |
|------------|------------------------|---------|------------------|
| `Chart.chartXSelection(value:)` | Swift Charts, iOS 17+ (well under the iOS 26 floor) | Native drag-to-select on `AlcoholAreaChart` / `WeekdayBarChart` | System-provided gesture recognition, haptics, and animation — exactly the "not a hand-rolled `DragGesture` hack" requirement in the todo. Already `import Charts` in both files; no new import beyond what's there. |
| `RuleMark` + `.annotation(position:)` | Swift Charts, iOS 16+ | Renders the value callout at the selected x | Idiomatic Swift Charts pattern for scrub readouts; composes with existing `dpGlassCard(.chip)` styling instead of a bespoke bubble view. |
| `accessibilityChartDescriptor(_:)` + `AXChartDescriptorRepresentable` | `Accessibility` framework (`import Accessibility`), iOS 17+ | VoiceOver / Audio Graph access to the same per-point values the scrub interaction exposes visually | Neither chart file currently has this (verified: no `accessibilityChartDescriptor`/`AXChart` hits in the codebase) — it is net-new, not an upgrade. CLAUDE.md requires selection not be the only path to values; this is the first-party mechanism Apple ships for exactly that gap. Needs its own `import Accessibility` in the chart files (Charts does not re-export it). |
| `.transition(.asymmetric(insertion:removal:))` + `.animation(_:value:)` | SwiftUI, all versions on iOS 26 | Directional slide between `HistoryView`'s `listContent` (List) and `calendarContent` (ScrollView) | Plain SwiftUI content-transition idiom; no Charts/Accessibility/UIKit involvement. `List` vs `ScrollView` are different concrete view types, so SwiftUI already treats the two `Group` branches as distinct identities on segment change — the missing piece is purely: attach `.transition` to each branch, wrap the mutation in `withAnimation` (or `.animation(value: segment)`), and track a "previous segment" `@State` to pick `.move(edge: .leading)` vs `.move(edge: .trailing)` per direction (a flat `.slide` is one-directional and looks wrong going backward, per the todo's own analysis). |
| `@Environment(\.accessibilityReduceMotion)` | SwiftUI | Gate both the chart-selection animation and the List↔Calendar transition | Already established in this codebase — `Features/Onboarding/OnboardingView.swift:80,86-92` has the exact `reduceMotion ? nil : .someCurve` / `animatedStep` pattern. Reuse it verbatim rather than inventing a second convention for these two features. |
| Xcode target "Info" custom properties (`UILaunchScreen` dict: `UIImageName`, optionally `UIColorName`) | Xcode 26 project configuration (no code) | Branded static launch screen, replacing `INFOPLIST_KEY_UILaunchScreen_Generation = YES` | Zero-code, zero-framework change — a `project.pbxproj` / target-settings edit. See the dedicated caveat below; this is the one item in this milestone I could not fully verify against a citable current source. |

### Supporting Libraries

None required. `Charts`, `SwiftUI`, `Accessibility`, and `SwiftData` are all first-party system frameworks already linked in the target; no `Package.swift` / SPM dependency changes are needed for any of the three features.

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Xcode 26 target editor → **Info** tab (Custom iOS Target Properties) | Add the `UILaunchScreen` dictionary without hand-editing `project.pbxproj` | Confirmed present at Xcode 26.6 (this machine). Works alongside `GENERATE_INFOPLIST_FILE = YES` — Apple's own SwiftUI-lifecycle template default since Xcode 14 ships with `GENERATE_INFOPLIST_FILE = YES` and still exposes this table for exactly this kind of addition, so there should be no need to introduce a physical `Info.plist` file. **Verify by testing in Xcode** before relying on it (see caveat). |
| Simulator vs. real device for launch-screen QA | `UILaunchScreen` is rendered by the OS pre-process, from a snapshot cache | The existing todo already calls this out: test with a real force-quit cold launch on device, not a simulator warm start — the snapshot/cache behavior differs and is the actual case the user reported. |

## Installation

Nothing to install. All APIs above come from frameworks the target already links (`Charts`, `SwiftUI`, `SwiftData`) plus `Accessibility`, which needs only an added `import Accessibility` in the two chart files that implement `AXChartDescriptorRepresentable`. There is no `Package.swift`, CocoaPods, or `npm` step for this milestone.

```swift
// AlcoholAreaChart.swift / WeekdayBarChart.swift — only new import needed anywhere in this milestone
import Accessibility
```

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| `chartXSelection(value:)` bound to the existing categorical `String` x-key (`AlcoholAreaChart`'s `key(for:)` / `WeekdayBarChart`'s `bar.label`) | Refactor the charts to a continuous `Date`/numeric x-scale so selection binds to `Date?` directly | Unnecessary risk to a working, deliberately-chosen banded categorical layout (the in-file comment on `AlcoholAreaChart` explains the point↔label alignment trade-off). `chartXSelection` binds fine to `String?` for categorical marks — confirmed pattern, no scale change required. Reuse the chart's existing `dateByKey` dictionary (already present in `AlcoholAreaChart`) to map the selected key back to a `Date` for the callout/formatting. |
| SwiftUI `.transition` + tracked previous-segment `@State` | `matchedGeometryEffect` cross-fade between List/ScrollView | `matchedGeometryEffect` is built for morphing between views that share layout geometry (e.g. a card expanding into a detail view); a `List` and a `ScrollView` don't share a meaningful matched frame, and the todo's own risk list ("layout jumps," "flash of unstyled background") is exactly what fighting `matchedGeometryEffect` across structurally different scroll containers tends to produce. Plain move+opacity transitions sidestep that. |
| Xcode Info-tab `UILaunchScreen` dictionary, no physical `Info.plist` | A `LaunchScreen.storyboard` | Storyboard-based launch screens are the pre-iOS-14 pattern; Apple's current guidance and this project's `GENERATE_INFOPLIST_FILE = YES` setup are both plist-key-based. Introducing a storyboard file into an otherwise storyboard-free, SwiftUI-only project (per CLAUDE.md's "SwiftUI only, no UIKit unless wrapping something unavoidable") would be a step backward, not forward. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|--------------|
| Hand-rolled `DragGesture` + manual hit-testing over the chart's plot area | Explicitly called out in the todo as the anti-pattern to avoid; re-implements haptics, snapping, and accessibility behavior the system already provides, and diverges from "native iOS 26" feel | `.chartXSelection(value:)` |
| A bespoke tooltip/bubble `View` for the scrub readout | Would introduce a second visual language next to `dpGlassCard`/Liquid Glass already used throughout Insights | `RuleMark(...).annotation(...)` styled with the existing `dpGlassCard(.chip)` modifier |
| Third-party animation/transition libraries (e.g. Pow, Wave, Lottie) for the List↔Calendar slide | Out of scope per CLAUDE.md stack rules (SwiftUI-only, no unnecessary third-party deps for something native SwiftUI transitions already do) | Native `.transition`/`.animation`, gated by the existing `reduceMotion` pattern |
| `TabView(.page)` as a swap mechanism between list/calendar content | Changes the interaction model to swipeable paging, which is not what was asked for — the segmented `Picker` must remain the sole driver of the switch | `Group { switch segment { ... } }` (already the shape today) with `.transition` added per branch |
| A `LaunchScreen.storyboard` | Reintroduces UIKit/Interface Builder into a project that has deliberately stayed storyboard-free; also can't cleanly coexist with `GENERATE_INFOPLIST_FILE = YES` without extra plumbing | `UILaunchScreen` Info-tab dictionary (image + optional background color) |
| Treating `AppIcon.icon` as a directly-nameable launch-screen image asset | **Codebase-specific gotcha, worth flagging explicitly.** `drinkpulse/AppIcon.icon` is Xcode 26's Icon Composer bundle format — `icon.json` describes a two-layer composition (`drinkpulse-3-pulse.svg`, `drinkpulse-2-drop.svg`) with a linear gradient fill and per-layer glass/translucency/shadow effects, rendered into the actual `AppIcon` slots by Icon Composer/`iconutil` at build time. It is **not** a flat image you can hand to `UIImageName` — there is no plain raster/vector asset by that name for `UILaunchScreen` to reference. | Export/flatten one static rendering of the composed icon (Icon Composer's export, or a manual render) into a normal image set (e.g. `LaunchBrand.imageset`) inside the existing `Assets.xcassets`, and reference *that* asset's name as `UIImageName`. This keeps the "no new artwork" intent (same icon, same gradient) while giving `UILaunchScreen` an asset type it can actually consume. |

## Stack Patterns by Variant

**If the hero-card headline value should track the scrub selection:**
- Bind chart selection state up to `InsightsHeroCard`/`InsightsViewModel` (or keep it chart-local and only mirror the formatted string via a callback) — decide per the todo's own open question ("follow selection while scrubbing, revert on release").
- Route every displayed number through the existing `InsightsViewModel+Formatting` (`formattedValue(_:)`) rather than formatting inline in the chart view, exactly as the current charts already do for axis values — this is a hard existing convention, not new guidance.

**If both charts need consistent selection behavior:**
- Factor the "selected key → callout" rendering into one shared modifier/helper (e.g. a small `ChartSelectionAnnotation` view) used by both `AlcoholAreaChart` and `WeekdayBarChart`, rather than duplicating the `RuleMark`/annotation code twice. Keep each chart's own `key(for:)`/label-lookup local, since the two charts don't share a key space.

**If the List↔Calendar transition needs to also cover the empty state:**
- The todo correctly notes there are three states, not two (`list` / `calendar` / `ContentUnavailableView` empty state nested inside `listContent`). Give the empty state the same `.transition` as the list itself (it's still inside the `.list` case of the outer switch) so the animation is consistent regardless of whether the user currently has data.

## Version Compatibility

| API | Minimum iOS | This project's floor (iOS 26) |
|-----|-------------|-------------------------------|
| `chartXSelection(value:)` / `chartXSelection(range:)` | iOS 17 | Comfortably available — no availability guards needed anywhere in this milestone. |
| `accessibilityChartDescriptor(_:)` / `AXChartDescriptorRepresentable` | iOS 17 | Same — no `@available` checks needed. |
| `.glassEffect(.regular, in:)` (`dpGlassCard`, reused for the scrub callout) | iOS 26 (Liquid Glass) | Matches the project's floor exactly; already in use (`DPGlass.swift`), nothing new to gate. |
| `UILaunchScreen` Info.plist key | iOS 14+ | No compatibility concern; the only open question is the *mechanics* of adding it under `GENERATE_INFOPLIST_FILE = YES`, not OS availability. |

## Sources

- Swift with Majid, "Mastering charts in SwiftUI: Selection" (2023) — `chartXSelection(value:)` gesture/binding behavior, cross-checked against a second independent source (Medium, "SwiftUI Charts in iOS 18") describing the same categorical-`String` binding pattern. **Confidence: MEDIUM** (cross-verified, web source).
- Swift with Majid, "Mastering charts in SwiftUI: Accessibility" (2023) + Kodeco, "iOS Accessibility in SwiftUI: Create Accessible Charts using Audio Graphs" — `accessibilityChartDescriptor`, `AXChartDescriptorRepresentable`, `AXNumericDataAxisDescriptor`/`AXCategoricalDataAxisDescriptor`, `import Accessibility` requirement, iOS 17 availability. **Confidence: MEDIUM** (cross-verified, web source).
- Direct codebase inspection: `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift`, `WeekdayBarChart.swift`, `InsightsChartModels.swift`, `InsightsViewModel+Charts.swift`, `InsightsViewModel+Formatting.swift`, `Components/InsightsHeroCard.swift`, `Features/History/HistoryView.swift`, `HistorySegment.swift`, `Features/Onboarding/OnboardingView.swift`, `DesignSystem/DPGlass.swift`, `DesignSystem/RiskLevel+Color.swift`, `DesignSystem/DPBrand.swift`, `drinkpulse/AppIcon.icon/icon.json`, `drinkpulse.xcodeproj/project.pbxproj` (`GENERATE_INFOPLIST_FILE`, `INFOPLIST_KEY_UILaunchScreen_Generation`, `IPHONEOS_DEPLOYMENT_TARGET = 26.0`), `Assets.xcassets` contents, local `xcodebuild -version` (Xcode 26.6). **Confidence: HIGH** (verified against source, current state as of 2026-07-28).
- SwiftLee, "Launch screens in Xcode: All the options explained"; Sarunw, "How to add Launch Screen in SwiftUI"; WWDC by Sundell & Friends, "Customize your app's Launch Screen using its Info Plist" — confirm the `UILaunchScreen` dictionary shape (`UIImageName`, `UIColorName`, nav/tab/toolbar sub-keys) and that it replaces storyboard-based launch screens since iOS 14/Xcode 12. **Confidence: MEDIUM** (cross-verified across 3 sources, web).
- **Explicitly unresolved / LOW confidence:** none of the fetched sources directly confirmed the exact mechanics of adding a nested `UILaunchScreen` dictionary via Xcode's Info-tab "Custom iOS Target Properties" table when `GENERATE_INFOPLIST_FILE = YES` (i.e., without a physical `Info.plist` file) — search results either didn't address this scenario or explicitly said so. The recommendation above reflects the general, documented Xcode behavior that the Info tab is designed as the GUI front-end for exactly this case, but **this specific mechanic should be hand-verified in Xcode before implementation** (add the key via the Info tab, build, inspect the produced `.app` bundle's `Info.plist` to confirm `UILaunchScreen` actually landed there). If it doesn't work as expected, the fallback is: keep `GENERATE_INFOPLIST_FILE = YES` for everything else, but supply a small standalone `Info.plist` containing only the `UILaunchScreen` key referenced via `INFOPLIST_FILE`, which Xcode explicitly supports merging with generated keys.

---
*Stack research for: DrinkPulse v1.3 "Native Feel" milestone (chart scrubbing, directional transition, branded launch screen)*
*Researched: 2026-07-28*
