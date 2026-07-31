# Phase 4: Branded Static Launch Screen - Research

**Researched:** 2026-07-28
**Domain:** iOS `UILaunchScreen` (Info.plist-based launch screen configuration) + Icon Composer asset export
**Confidence:** MEDIUM — the platform mechanism (`UILaunchScreen` dict) is well-documented and stable since iOS 14; the exact `INFOPLIST_KEY_*` build-setting names for this project's `GENERATE_INFOPLIST_FILE = YES` setup, and Icon Composer's PNG-export fidelity, could not be fully confirmed via search and need one hands-on verification step during execution (see Open Questions).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 (Background color):** Launch screen background must match `Color(.systemBackground)` exactly (white in light mode, black in dark mode) — zero-diff match to the existing `.loading` state in `drinkpulseApp.swift:75`, which already renders plain `Color(.systemBackground)` while the model container opens. This guarantees no flash/color mismatch (Success Criterion #3) with no extra changes to app code. Brand coral (`AccentColor`) was considered and rejected — it would also require changing `.loading`'s background to stay consistent, which is out of scope for this phase.
- **D-02 (Icon artwork/treatment):** Use the full flattened `AppIcon.icon` composition (both `drinkpulse-2-drop.svg` and `drinkpulse-3-pulse.svg` layers, per `icon.json`'s gradient fill) as a static image — matches the real Home Screen icon exactly, not a simplified/single-layer mark.
- **D-03 (Icon sizing/placement):** Icon is centered, sized to match the Home Screen icon's on-screen size — not full-bleed, not enlarged. Follows Apple HIG's default launch-screen icon placement.
- **D-04 (Light/Dark adaptation):** Background adapts via `systemBackground` (see D-01); the icon itself does NOT get custom hand-designed dark-mode artwork for this phase. `icon.json` defines only one gradient fill with no explicit dark/tinted override — use whatever Xcode's Icon Composer auto-derives for the dark rendition (same as how the Home Screen icon already behaves in dark mode). Designing new dark-mode icon artwork was explicitly declined as out of scope (design task, not implementation).

### Claude's Discretion

- Exact build-setting mechanism (`INFOPLIST_KEY_UILaunchScreen_*` build settings vs. a standalone `Info.plist`) — this is implementation detail for research/planning to resolve, not a user-facing decision. Note: `GENERATE_INFOPLIST_FILE = YES` is set across all targets in `project.pbxproj`, and `INFOPLIST_KEY_UILaunchScreen_Generation = YES` currently produces the blank generated screen (lines 419, 455).
- Exact image asset export mechanics (how to flatten the Icon Composer `.icon` bundle into a static launch-screen image asset) — implementation detail.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope. (Designing new dark-mode icon artwork was raised and explicitly declined, not deferred — see D-04.)

### Folded Todo (source problem statement)

`2026-07-27-branded-static-launch-screen.md` (resolves_phase: 4): cold launch shows a blank auto-generated screen (`INFOPLIST_KEY_UILaunchScreen_Generation = YES`). Confirmed solution direction: static image only (no spinner/animation — a real `UILaunchScreen` is static UIKit config, not SwiftUI, by platform design), consistent with the existing `AppIcon.icon` asset. A `drinkpulseUITests` assertion on the launch screen itself is not meaningful (it's pre-process UI, XCUITest attaches after process launch) — pin the post-launch first screen instead if a test is added.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAUNCH-01 | Cold launch shows a branded static launch screen (app icon + matching background color, no text, no spinner) instead of the auto-generated blank one — verified via a genuine force-quit cold launch on a real device | `UILaunchScreen` Info.plist dict mechanism (Architecture Patterns), exact build-setting keys and fallback path (Code Examples), Icon Composer export mechanics + margin pitfall (Common Pitfalls), background-color asset approach (Code Examples) |
</phase_requirements>

## Summary

This phase is pure platform configuration, not application code. iOS launch screens are defined by the `UILaunchScreen` Info.plist dictionary (introduced Xcode 12 / iOS 14, still the current mechanism as of Xcode 26 — no evidence found of an iOS 26-specific replacement). The dictionary supports three keys relevant here: `UIImageName` (an Asset Catalog image to display, centered), `UIColorName` (an Asset Catalog color for the background), and `UIImageRespectsSafeAreaInsets`. Nothing about this is SwiftUI — it renders before any app code runs, which is exactly why D-02/D-03/D-04 talk about "artwork" rather than "a view."

This project has `GENERATE_INFOPLIST_FILE = YES` on every target (no standalone `Info.plist` exists) and already has `INFOPLIST_KEY_UILaunchScreen_Generation = YES` set on the app target's Debug and Release configs (`project.pbxproj:419,455`) — this is the exact setting currently producing the blank auto-generated screen. Xcode's own naming convention for *this same dictionary* (`INFOPLIST_KEY_UILaunchScreen_Generation`) strongly implies (but does not, via public Apple docs, formally confirm) that the sibling keys follow the pattern `INFOPLIST_KEY_UILaunchScreen_UIImageName` / `INFOPLIST_KEY_UILaunchScreen_UIColorName`. Because this exact string could not be confirmed from an authoritative source, the safe execution path is to let Xcode's own Target → Info tab UI generate these build settings (rather than hand-typing them into `project.pbxproj`), with a documented fallback to a standalone `Info.plist` (`GENERATE_INFOPLIST_FILE = NO` + `INFOPLIST_FILE = drinkpulse/Info.plist`) if the generated-file path proves unworkable.

The second piece — turning the interactive, layered `AppIcon.icon` bundle into a static image — has one identified, source-confirmed pitfall: Icon Composer's own "File → Export" flattened-PNG feature is known (as of a documented Icon Composer bug, autumn 2025) to export **without the platform's icon margin**, making the exported PNG look larger/differently-cropped than the icon the way iOS actually renders it on the Home Screen. Given D-03's requirement that the launch icon match the Home Screen icon's on-screen size exactly, this is a directly load-bearing pitfall for this phase and needs an explicit visual-verification step, not just "export and ship."

**Primary recommendation:** Use Xcode's Target → Info tab (not hand-edited `project.pbxproj`, not a hand-typed `INFOPLIST_KEY_UILaunchScreen_UIImageName` guess) to wire up the launch screen against a flattened icon image asset and a background color asset that hard-codes `systemBackground`'s white/black values; treat the Icon Composer PNG export as a first draft that must be visually diffed against a real Home Screen icon screenshot before being accepted, and validate the end result only via a genuine force-quit cold launch on a real device (the simulator's launch-screen caching behavior is not equivalent).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Launch screen presentation (image + background) | OS / Springboard (pre-process, Info.plist-driven) | — | `UILaunchScreen` renders from a system snapshot of the Info.plist config before any app code executes; it is not a view in the app's runtime tier at all |
| Icon artwork source-of-truth | Build-time asset compilation (Icon Composer `.icon` → Asset Catalog) | — | `AppIcon.icon` is compiled by `actool`/Xcode into the real Home Screen icon; the launch-screen image must be a *derived, flattened* artifact of that same source, not independently designed |
| Background color continuity | SwiftUI / App tier (`drinkpulseApp.swift` `.loading` state) | Asset Catalog (Color Set consumed by `UIColorName`) | The visual contract (must match `Color(.systemBackground)`) is owned by the existing app-tier code; the launch-screen's own background is a static asset that must be kept in lockstep with it, not the other way around |

## Standard Stack

Not applicable in the conventional sense — this phase installs no third-party packages, frameworks, or libraries. The "stack" is entirely first-party Apple tooling already present via Xcode 26.6 (confirmed installed locally: `xcodebuild -version` → `Xcode 26.6, Build version 17F113`).

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `UILaunchScreen` Info.plist dictionary | Platform API since iOS 14 / Xcode 12 | Declares the static launch screen (image + background color) | Apple's only supported non-storyboard mechanism for a native launch screen; storyboard-based launch screens are legacy |
| Icon Composer (`Icon Composer.app`, bundled in `/Applications/Xcode.app/Contents/Applications/`) | Ships with Xcode 26 | Source-of-truth editor for `AppIcon.icon`; has a one-click flattened-PNG export | New in Xcode 26, required for `.icon`-format app icons (this project already uses it for `AppIcon.icon`) |
| Xcode Asset Catalog (`.xcassets`) | N/A (project format) | Hosts the flattened launch-icon `.imageset` and the background `.colorset` referenced by `UIImageName`/`UIColorName` | Both `UILaunchScreen` keys resolve names against the Asset Catalog exclusively — there is no other supported source |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `actool` (Xcode command-line asset compiler) | Bundled with Xcode | Compiles `.icon` bundles into `Assets.car`; can also be invoked standalone for scripted PNG generation | Only if Icon Composer's own GUI export proves margin-inaccurate and a more controlled, scriptable rasterization is needed |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `INFOPLIST_KEY_UILaunchScreen_*` build settings (generated Info.plist) | Standalone `Info.plist` (`GENERATE_INFOPLIST_FILE = NO`, `INFOPLIST_FILE = drinkpulse/Info.plist`) | Unambiguous, well-documented XML syntax, but reintroduces a file type this project has deliberately avoided everywhere (`GENERATE_INFOPLIST_FILE = YES` is set on *every* target) — larger diff, precedent-breaking. Use only as a fallback if the generated-plist route doesn't work. |
| Icon Composer GUI "File → Export" flattened PNG | `actool` CLI invocation against `AppIcon.icon` with explicit target-device/deployment-target flags | GUI export is one click but has the documented margin bug; CLI is what Xcode uses internally to compile the real Home Screen icon, so it is more likely to match pixel-for-pixel, at the cost of needing to hand-craft the invocation and extract a usable PNG from its output. |
| Hardcoded white/black `.colorset` for the background | An Asset Catalog Color Set built from Xcode's "System Colors" picker (`systemBackground` entry, if present in this Xcode version's color picker) | The System Colors picker is the more "correct" semantic reference (tracks Apple's own definition exactly, including any future adjustments), but its availability in the color-asset UI has regressed in past Xcode betas (documented Xcode 13 beta 3 regression) and was not confirmed present in Xcode 26 during this research session. The hardcoded white/black colorset is a deterministic, zero-ambiguity fallback that exactly matches D-01's own stated expectation ("white in light mode, black in dark mode"). |

**Installation:** N/A — no packages to install. All work is Xcode target configuration + Asset Catalog additions.

## Package Legitimacy Audit

Not applicable — this phase installs no external packages (npm, CocoaPods, SPM, or otherwise). No legitimacy gate applies.

## Architecture Patterns

### System Architecture Diagram

```
Cold launch (force-quit → tap icon)
        │
        ▼
┌───────────────────────────────────────────┐
│  Springboard reads compiled Info.plist      │
│  (UILaunchScreen dict, baked at build time  │
│  from INFOPLIST_KEY_UILaunchScreen_* build  │
│  settings — no app code has run yet)        │
└───────────────────┬─────────────────────────┘
                    │ renders
                    ▼
┌───────────────────────────────────────────┐
│  Static launch screen                       │
│  - background: Color Set → resolves to      │
│    systemBackground white/black             │
│  - image: flattened AppIcon.icon PNG,       │
│    centered, Home-Screen-icon-sized         │
│  (zero code path — pure OS-rendered bitmap) │
└───────────────────┬─────────────────────────┘
                    │ app process actually starts
                    ▼
┌───────────────────────────────────────────┐
│  drinkpulseApp.body → containerState=.loading│
│  Color(.systemBackground).ignoresSafeArea() │
│  (drinkpulseApp.swift:75 — existing code,   │
│  UNCHANGED by this phase)                   │
└───────────────────┬─────────────────────────┘
                    │ container resolves
                    ▼
┌───────────────────────────────────────────┐
│  .ready → OnboardingView or RootShellView   │
│  (first live frame — Success Criterion #3   │
│  requires no visible color/flash mismatch   │
│  across all four frames above)              │
└───────────────────────────────────────────┘
```

A reader can trace the whole flow: Info.plist config (build-time) → Springboard-rendered static bitmap (pre-process) → `.loading` SwiftUI frame (same background color, by construction) → first live frame. The launch screen and `.loading` are two *independently configured* things that happen to need to render pixel-identical backgrounds — there is no shared code path between them, which is exactly why D-01 pins the launch screen's background asset to the same literal white/black values `.loading` already uses, rather than relying on any runtime linkage.

### Recommended Project Structure

```
drinkpulse/Assets.xcassets/
├── AppIcon.appiconset/          # existing — compiled from AppIcon.icon, untouched
├── LaunchIcon.imageset/         # NEW — flattened static export of AppIcon.icon
│   ├── Contents.json            # "Any Appearance" (+ "Dark" if exported twice, per D-04)
│   └── LaunchIcon.png / LaunchIcon-Dark.png
└── LaunchBackground.colorset/   # NEW — hardcoded white(Any)/black(Dark), matches systemBackground
    └── Contents.json
```

### Pattern 1: `UILaunchScreen` dictionary via generated Info.plist

**What:** Configure the launch screen entirely through target build settings, letting Xcode continue to synthesize the Info.plist at build time (no standalone `Info.plist` file added).
**When to use:** Default choice for this project, since `GENERATE_INFOPLIST_FILE = YES` is already the project-wide convention and no other target has a standalone Info.plist.
**Example (raw Info.plist dictionary shape this build setting must ultimately produce — verify the exact `INFOPLIST_KEY_UILaunchScreen_*` build-setting spelling via Xcode's own Target → Info tab UI rather than hand-typing into `project.pbxproj`):**
```xml
<!-- Source: developer.apple.com — UILaunchScreen Info.plist key documentation.
     This is the *effective* Info.plist shape; with GENERATE_INFOPLIST_FILE=YES,
     Xcode derives these from INFOPLIST_KEY_UILaunchScreen_* build settings
     instead of raw XML. -->
<key>UILaunchScreen</key>
<dict>
    <key>UIImageName</key>
    <string>LaunchIcon</string>
    <key>UIColorName</key>
    <string>LaunchBackground</string>
    <key>UIImageRespectsSafeAreaInsets</key>
    <false/>
</dict>
```

### Pattern 2: Standalone `Info.plist` fallback

**What:** Flip `GENERATE_INFOPLIST_FILE = NO`, add `INFOPLIST_FILE = drinkpulse/Info.plist` to the app target only, and hand-author the plist with the exact XML above.
**When to use:** Only if Pattern 1's generated-settings route proves unworkable in the Xcode GUI (this is the fallback explicitly recorded in `.planning/STATE.md`'s Blockers/Concerns section as an unverified mechanic to confirm hands-on).
**Tradeoff:** Diverges from this project's "no Info.plist anywhere" convention — flag to the user/planner if this path is taken, since it's a bigger footprint than intended.

### Anti-Patterns to Avoid

- **Building a SwiftUI "splash view" and calling it the launch screen:** A `UILaunchScreen` is rendered by the OS before the app process starts; it has zero code path. A SwiftUI view shown briefly after launch is a *second*, additional screen — it adds perceived latency, isn't what LAUNCH-01 asks for, and directly contradicts the phase's own scope note ("no change to app startup timing/logic"). The existing `.loading` state in `drinkpulseApp.swift` is not "the launch screen" and must not be treated as satisfying this requirement — it's the *next* frame after the real launch screen hands off.
- **Hand-typing guessed `INFOPLIST_KEY_UILaunchScreen_UIImageName`/`UIColorName` strings directly into `project.pbxproj`:** Info.plist key names that are misspelled or wrong are silently ignored by the OS (no build error, no runtime error) — the launch screen will just stay blank/default with no diagnostic. Prefer the Xcode GUI (Target → Info tab → Launch Screen section), which writes the verified key spelling itself.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Rendering the icon's gradient + layered/glass composition as a static image | A SwiftUI/Core Graphics recreation of the gradient math from `icon.json` | Icon Composer's own flattened-PNG export (or `actool` CLI as a fallback) | `icon.json`'s gradient (display-p3 → srgb linear-gradient) plus per-layer translucency/shadow (`drinkpulse-3-pulse` at 0.5 opacity, neutral shadow) is exactly what Icon Composer already renders correctly for the real Home Screen icon; reimplementing that math risks a visible mismatch that directly violates D-02's "matches the real Home Screen icon exactly" requirement |
| Verifying the launch screen | A custom test harness that tries to screenshot the pre-process launch state via XCUITest | Manual real-device force-quit-and-relaunch inspection | XCUITest only attaches once the app process has started, i.e. *after* the real launch screen has already been shown and handed off — it structurally cannot observe the thing Success Criterion #1 is testing |

**Key insight:** Everything in this phase is either (a) already-solved by an Apple-first-party tool that ships with the exact Icon Composer source file this project already uses, or (b) structurally unverifiable by automation. Trying to script around either invites a worse result than using the built-in tools directly.

## Common Pitfalls

### Pitfall 1: Icon Composer's flattened PNG export has no margin

**What goes wrong:** The exported PNG appears larger/differently cropped than the icon actually looks when iOS composites it onto the Home Screen (with its standard icon margin/corner treatment).
**Why it happens:** Documented behavior — Icon Composer's "File → Export" (as distinct from "Save", which produces the real `.icon` package) generates PNGs "with no margin, so the icon appears too large, even though the outer pixel dimensions are the same" [CITED: mjtsai.com/blog/2025/10/02/how-to-export-a-mac-icon-file-with-the-proper-margins/].
**How to avoid:** Treat the exported PNG as a draft. After adding it to `LaunchIcon.imageset`, run the app and visually compare the launch screen's icon size/position against a real Home Screen icon on the same device — they should look identical per D-03. If they don't, either (a) manually pad the exported PNG's canvas with transparent margin before importing (matching the margin ratio in a compiled `AppIcon.appiconset` rendition, if one is available to diff against), or (b) generate the static image via `actool` instead (the same compiler Xcode uses internally for the real Home Screen icon), which is more likely to reproduce the correct margin.
**Warning signs:** The launch-screen icon looks noticeably bigger, more cropped, or off-center compared to a screenshot of the real Home Screen icon.

### Pitfall 2: Conflicting `UILaunchScreen_Generation` and explicit sub-keys

**What goes wrong:** `INFOPLIST_KEY_UILaunchScreen_Generation = YES` currently exists on the app target's Debug and Release configs (`project.pbxproj:419,455`). If explicit `UIImageName`/`UIColorName` settings are added *without* removing or disabling this flag, behavior is ambiguous — the auto-generated (blank) dict may still win, or the two may conflict silently.
**Why it happens:** `_Generation = YES` is Xcode's synthetic flag meaning "auto-populate this dictionary with system defaults" — it's designed for the no-customization case this phase is replacing.
**How to avoid:** When wiring up the custom image/color via Xcode's Info tab UI, confirm the `_Generation` key is removed (or set to `NO`) from both Debug and Release configs of the app target — verify this in the resulting `project.pbxproj` diff before committing.
**Warning signs:** Build succeeds, but the launch screen still shows blank/default despite the new asset keys being present.

### Pitfall 3: Simulator testing is not equivalent to real-device cold launch

**What goes wrong:** The launch screen appears correct (or incorrect) in the Simulator but behaves differently on a real device, or a stale/cached launch screen snapshot is shown instead of the freshly-configured one.
**Why it happens:** Springboard on both platforms can cache a launch screen snapshot from a previous run; a "cold launch" in the sense Success Criterion #1 means (genuine force-quit, not just a fresh `xcodebuild install`) is the only reliable way to see what a real user sees, and Simulator launch/relaunch semantics don't always match device behavior exactly.
**How to avoid:** Per Success Criterion #1, final verification must happen via a genuine force-quit cold launch on a real device — not just a Simulator run. Delete the app and reinstall, or at minimum force-quit fully (swipe up and away in the app switcher) before each verification pass.
**Warning signs:** Launch screen looks right in Simulator/Xcode preview builds but a teammate or QA report says otherwise on-device.

### Pitfall 4: `UIColorName`/`UIImageName` reference a missing or misnamed asset

**What goes wrong:** The launch screen silently falls back to blank/default (same failure mode the phase is trying to fix) if the string in `UIImageName`/`UIColorName` doesn't exactly match an existing Asset Catalog entry name.
**Why it happens:** These are unvalidated string references resolved at OS render time, not compile-time-checked symbols.
**How to avoid:** Confirm the exact Asset Catalog names (`LaunchIcon`, `LaunchBackground` or whatever is chosen) match precisely, and that the imageset/colorset actually exists in the target's `Assets.xcassets` before wiring up the Info.plist keys.
**Warning signs:** No build error at all; the only symptom is the launch screen not changing.

## Code Examples

### Background Color Set matching `systemBackground` (D-01)

```json
// Source: modeled on this project's existing AccentColor.colorset/Contents.json format
// (drinkpulse/Assets.xcassets/AccentColor.colorset/Contents.json).
// White/black values per D-01's own stated definition of systemBackground,
// corroborated by multiple secondary sources [CITED: developer.apple.com/documentation/UIKit/UIColor/systemBackground
// title page + secondary summaries — exact hex not found verbatim on an Apple page during this
// research session, treat as MEDIUM confidence, cross-check visually against Color(.systemBackground)
// rendered on-device before relying on it].
{
  "colors" : [
    {
      "appearances" : [
        { "appearance" : "luminosity", "value" : "dark" }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : { "red" : "0.000", "green" : "0.000", "blue" : "0.000", "alpha" : "1.000" }
      },
      "idiom" : "universal"
    },
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "red" : "1.000", "green" : "1.000", "blue" : "1.000", "alpha" : "1.000" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

### Effective `UILaunchScreen` Info.plist shape (target reference, regardless of which mechanism produces it)

```xml
<!-- Source: developer.apple.com/documentation/bundleresources/information-property-list/uilaunchscreen -->
<key>UILaunchScreen</key>
<dict>
    <key>UIImageName</key>
    <string>LaunchIcon</string>
    <key>UIColorName</key>
    <string>LaunchBackground</string>
</dict>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `LaunchScreen.storyboard` | `UILaunchScreen` Info.plist dictionary | Xcode 12 / iOS 14 (2020) | Storyboard-based launch screens are legacy; new SwiftUI-first projects (like this one) never had a storyboard to begin with — nothing to migrate away from, just a key to add |
| Manually rasterizing multi-layer icon art | Icon Composer (`.icon` bundle) + its flattened-PNG export | Xcode 26 / iOS 26 (2025) | This project already uses Icon Composer for `AppIcon.icon`; no evidence found of any further iOS-26-specific launch-screen mechanism beyond the existing `UILaunchScreen` dict — the only iOS-26-relevant change is that the *source* icon format changed to `.icon`, which affects how the static image is produced, not the launch-screen config mechanism itself |

**Deprecated/outdated:** `LaunchScreen.storyboard` / `UILaunchStoryboardName` — not present in this project and should not be introduced.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The nested build-setting keys for custom `UILaunchScreen` sub-values follow the pattern `INFOPLIST_KEY_UILaunchScreen_UIImageName` / `INFOPLIST_KEY_UILaunchScreen_UIColorName`, by analogy with the already-present `INFOPLIST_KEY_UILaunchScreen_Generation`. | Architecture Patterns, Pattern 1 | If wrong, hand-typed keys silently do nothing (Pitfall 4-style failure) with no build error — mitigated by recommending the Xcode GUI (Target → Info tab) generate these settings instead of hand-typing them, which sidesteps the need for this assumption to be correct |
| A2 | `UIColor.systemBackground` resolves to exactly `#FFFFFF` (light) / `#000000` (dark) with no other appearance-dependent variation relevant to this app. | Code Examples, background Color Set | If the precise value differs slightly, the launch screen background could show a subtle flash against `.loading`'s `Color(.systemBackground)` — directly threatens Success Criterion #3. Low risk since this matches CONTEXT.md's own D-01 statement, but should be spot-checked with a color picker against the running app before final commit. |
| A3 | Simulator cold-launch behavior is not a reliable proxy for genuine real-device force-quit cold launch, for the purposes of verifying the launch screen. | Common Pitfalls, Pitfall 3 | Low risk to get wrong in the "too cautious" direction (worst case: an unnecessary extra device test); the CONTEXT.md success criteria already mandate real-device testing regardless, so this assumption doesn't change required work, only explains why. |
| A4 | Icon Composer's Export-to-PNG margin bug (documented for macOS `.icns`-style export in one source) also applies to the iOS flattened-icon export path used here. | Common Pitfalls, Pitfall 1 | If the bug is macOS-export-specific and doesn't reproduce for the iOS static-image export, the mandated visual-verification step is simply extra safety margin, not wasted work — no negative consequence either way. |

## Open Questions

1. **What is the exact `INFOPLIST_KEY_UILaunchScreen_*` build-setting spelling Xcode 26 generates for custom `UIImageName`/`UIColorName`?**
   - What we know: The dictionary-level flag (`INFOPLIST_KEY_UILaunchScreen_Generation`) already exists in this project and follows an underscore-joined `<TopLevelKey>_<SubKey>` pattern for at least one other synthetic sub-key.
   - What's unclear: No authoritative Apple documentation or forum post confirming the exact string for `UIImageName`/`UIColorName` specifically was found during this research session.
   - Recommendation: Resolve this empirically during execution — open the app target's Info tab in Xcode, use the "+" control under Custom iOS Target Properties / Launch Screen to add the Image Name and Background Color entries via the GUI, then inspect the resulting `project.pbxproj` diff to confirm the exact keys Xcode writes, rather than guessing. If the GUI path doesn't expose this cleanly, fall back to Pattern 2 (standalone Info.plist) and flag the divergence in `execution.md`.

2. **Does Icon Composer's flattened PNG export actually reproduce the correct Home-Screen-icon margin for iOS app icons (not just the macOS case documented in the one source found)?**
   - What we know: A documented bug exists for Icon Composer's export producing no-margin PNGs, sourced from a macOS `.icns`-focused writeup.
   - What's unclear: Whether the iOS flattened-image export path (used for things like App Store marketing images) has the identical issue.
   - Recommendation: Execution should treat every exported PNG as provisional and require a side-by-side visual check against a real Home Screen icon screenshot before accepting it into `LaunchIcon.imageset` — this satisfies D-03 regardless of which way this question resolves.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode (with Icon Composer bundled) | Editing `AppIcon.icon`, exporting flattened PNG, editing target Info tab | ✓ | Xcode 26.6 (Build 17F113), `Icon Composer.app` confirmed present at `/Applications/Xcode.app/Contents/Applications/Icon Composer.app` | — |
| Real physical iOS device (iOS 26+) | Success Criterion #1 final verification (genuine force-quit cold launch) | Not verified in this research session — requires a human with a paired device | — | None — this is a hard requirement of the phase's own success criteria; cannot be satisfied by Simulator alone |

**Missing dependencies with no fallback:**
- A real device for the final force-quit cold-launch verification pass — this must be performed by a human as part of phase verification (`checkpoint:human-verify`), it cannot be automated or simulated.

**Missing dependencies with fallback:** None beyond the above.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest / XCUITest (existing project convention — see `drinkpulseUITests/Features/Shell/StartupErrorUITests.swift` for the established pattern of asserting app-rendered English strings, never system-process UI) |
| Config file | none — driven by the `drinkpulse` scheme |
| Quick run command | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseUITests` |
| Full suite command | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|--------------------|-------------|
| LAUNCH-01 (Success Criterion #1: real branded launch screen on cold launch) | Pre-process launch screen shows icon + matching background | manual-only | N/A — XCUITest attaches only after the app process starts, structurally after the real launch screen has already rendered and handed off; this cannot be observed by any in-process test | N/A |
| LAUNCH-01 (Success Criterion #2: static image only, no animation/wordmark) | Launch screen config contains only `UIImageName`/`UIColorName`, no storyboard/spinner | manual-only (config review) | Reviewable directly from the `project.pbxproj` diff / Info.plist content — no runtime test possible | N/A |
| LAUNCH-01 (Success Criterion #3: no visible flash/mismatch at handoff) | First live SwiftUI frame's background matches the launch screen's background | manual-only, optionally pinned indirectly | An XCUITest can assert the app launches and its first frame appears within a timeout (proxy for "handoff completed cleanly"), but cannot assert pixel-level color continuity across the pre-process/in-process boundary | N/A |

### Sampling Rate

- **Per task commit:** N/A for the pre-process launch screen itself (no automatable assertion exists); run the existing UI test suite quick pass to confirm no regression to normal app launch (`-only-testing:drinkpulseUITests`).
- **Per wave merge:** Full suite green, plus a manual real-device force-quit cold-launch check.
- **Phase gate:** Full suite green before `/gsd-verify-work`; Success Criteria #1–#3 verified manually on a real device per the folded todo's own note that this is inherently a human-verification item, not an automatable one.

### Wave 0 Gaps

None — existing test infrastructure (`drinkpulseUITests`) is sufficient for any indirect/proxy regression coverage this phase might add. No new test framework or fixture is required. The primary verification mechanism for this phase's actual success criteria is a `checkpoint:human-verify` on a real device, not an automated test — the planner should include that checkpoint explicitly rather than searching for a way to automate around it.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|----------------|---------|-------------------|
| V2 Authentication | no | No auth surface touched |
| V3 Session Management | no | No session state touched |
| V4 Access Control | no | No access-control surface touched |
| V5 Input Validation | no | No user input involved — static config/asset only |
| V6 Cryptography | no | No cryptographic material involved |

### Known Threat Patterns for this stack

None identified. This phase changes only static, build-time, on-device presentation config (an Info.plist key and two Asset Catalog entries) with no data flow, no network activity, no user input, and no persisted user data touched — it is fully consistent with the project's on-device-only, no-network CLAUDE.md constraints and introduces no new attack surface.

## Sources

### Primary (HIGH confidence)
- This project's own `drinkpulse.xcodeproj/project.pbxproj` (lines 269, 406-436, 439-473, 480-513) — confirmed current `GENERATE_INFOPLIST_FILE`/`INFOPLIST_KEY_UILaunchScreen_Generation` state via direct grep/read
- This project's own `drinkpulse/AppIcon.icon/icon.json`, `drinkpulse/drinkpulseApp.swift:67-108`, `drinkpulse/Assets.xcassets/AccentColor.colorset/Contents.json` — confirmed via direct read
- Local `xcodebuild -version` (Xcode 26.6) and filesystem check confirming `Icon Composer.app` is bundled and present

### Secondary (MEDIUM confidence)
- [UIColorName — Apple Developer Documentation](https://developer.apple.com/documentation/bundleresources/information-property-list/uilaunchscreen/uicolorname) — confirms `UIColorName`/`UIImageName`/`UIImageRespectsSafeAreaInsets` as the `UILaunchScreen` dict's supported keys
- [How to Export a Mac .icon File With the Proper Margins — Michael Tsai](https://mjtsai.com/blog/2025/10/02/how-to-export-a-mac-icon-file-with-the-proper-margins/) — source of the Icon Composer export-margin pitfall and the Save-vs-Export distinction
- [Icon Composer Notes — Virtual Sanity](https://www.virtualsanity.com/202507/icon-composer-notes/) — corroborates Save (`.icon`) vs. Export (PNG) distinction
- [Updating App Icons for iOS and macOS 26 — praeclarum.org](https://praeclarum.org/2025/09/12/app-icons.html) — confirms `actool` compiles `.icon` bundles and can produce backwards-compatible PNG output
- [Icon Composer for Apple Platforms — wolfnhare.com](https://wolfnhare.com/icon-composer-for-apple-platforms-build-multi-layer-icons-with-dynamic-lighting-in-xcode) — confirms one-click flattened-PNG export exists

### Tertiary (LOW confidence)
- Aggregated WebSearch summaries on `UIColor.systemBackground` exact hex values (multiple blog/cheat-sheet sources converging on white/black, no single Apple-authored page with the literal hex found) — treat A2 in Assumptions Log accordingly
- Aggregated WebSearch summaries on `INFOPLIST_KEY_UILaunchScreen_UIImageName`/`UIColorName` exact spelling — no authoritative confirmation found; treat A1 in Assumptions Log accordingly, mitigated by the GUI-driven execution recommendation

## Metadata

**Confidence breakdown:**
- Standard stack (tooling identification): HIGH — Icon Composer and `UILaunchScreen` are correctly identified and version-confirmed locally
- Architecture (mechanism understanding): MEDIUM — the platform mechanism is well understood; the exact `GENERATE_INFOPLIST_FILE=YES` build-setting spelling for custom sub-keys is unconfirmed (A1)
- Pitfalls: MEDIUM-HIGH — the Icon Composer margin bug and simulator-vs-device pitfalls are well-sourced and directly relevant; both have a mitigation baked into the recommended approach

**Research date:** 2026-07-28
**Valid until:** 2026-08-27 (30 days — stable platform mechanism, but Icon Composer is new in Xcode 26 and could see rapid tooling changes)
