# Phase 4: Branded Static Launch Screen - Context

**Gathered:** 2026-07-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Cold launch shows a branded, native-feeling static launch screen (app icon +
background color) instead of the auto-generated blank one. Presentation only
— no animation, no wordmark, no change to app startup timing/logic (that's
tracked separately under the async-container-startup work). Scope is
`LAUNCH-01` only.

</domain>

<decisions>
## Implementation Decisions

### Background color
- **D-01:** Launch screen background must match `Color(.systemBackground)` exactly (white in light mode, black in dark mode) — zero-diff match to the existing `.loading` state in `drinkpulseApp.swift:75`, which already renders plain `Color(.systemBackground)` while the model container opens. This guarantees no flash/color mismatch (Success Criterion #3) with no extra changes to app code. Brand coral (`AccentColor`) was considered and rejected — it would also require changing `.loading`'s background to stay consistent, which is out of scope for this phase.

### Icon artwork/treatment
- **D-02:** Use the full flattened `AppIcon.icon` composition (both `drinkpulse-2-drop.svg` and `drinkpulse-3-pulse.svg` layers, per `icon.json`'s gradient fill) as a static image — matches the real Home Screen icon exactly, not a simplified/single-layer mark.
- **D-03:** Icon is centered, sized to match the Home Screen icon's on-screen size — not full-bleed, not enlarged. Follows Apple HIG's default launch-screen icon placement.

### Light/Dark adaptation
- **D-04:** Background adapts via `systemBackground` (see D-01); the icon itself does NOT get custom hand-designed dark-mode artwork for this phase. `icon.json` defines only one gradient fill with no explicit dark/tinted override — use whatever Xcode's Icon Composer auto-derives for the dark rendition (same as how the Home Screen icon already behaves in dark mode). Designing new dark-mode icon artwork was explicitly declined as out of scope (design task, not implementation).

### Claude's Discretion
- Exact build-setting mechanism (`INFOPLIST_KEY_UILaunchScreen_*` build settings vs. a standalone `Info.plist`) — this is implementation detail for research/planning to resolve, not a user-facing decision. Note: `GENERATE_INFOPLIST_FILE = YES` is set across all targets in `project.pbxproj`, and `INFOPLIST_KEY_UILaunchScreen_Generation = YES` currently produces the blank generated screen (lines 419, 455).
- Exact image asset export mechanics (how to flatten the Icon Composer `.icon` bundle into a static launch-screen image asset) — implementation detail.

### Folded Todos
- **`2026-07-27-branded-static-launch-screen.md`** (severity: minor, already tagged `resolves_phase: 4`) — "Replace generated launch screen with branded static launch screen." Problem: cold launch shows a blank auto-generated screen (`INFOPLIST_KEY_UILaunchScreen_Generation = YES`). Solution direction confirmed by this discussion: static image only (no spinner/animation — a real `UILaunchScreen` is static UIKit config, not SwiftUI, by platform design), consistent with the existing `AppIcon.icon` asset. The todo also flags that a `drinkpulseUITests` assertion on the launch screen itself is not meaningful (it's pre-process UI) — pin the post-launch first screen instead if a test is added.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` §"Branded Launch Screen" — LAUNCH-01 requirement text and explicit Out of Scope list (no animation/spinner/wordmark)
- `.planning/ROADMAP.md` §"Phase 4: Branded Static Launch Screen" — goal, success criteria, UI hint

### Source todo
- `.planning/todos/pending/2026-07-27-branded-static-launch-screen.md` — original problem statement, candidate file locations (`project.pbxproj:418,453`, `drinkpulse/AppIcon.icon`), and the "static image, no spinner" constraint

### Relevant code
- `drinkpulse/drinkpulseApp.swift:70-75` — the `.loading` `ContainerLoadState` case whose `Color(.systemBackground)` the launch screen background must match
- `drinkpulse.xcodeproj/project.pbxproj:269,413,419,449,455,480,495,512` — `GENERATE_INFOPLIST_FILE = YES` and `INFOPLIST_KEY_UILaunchScreen_Generation = YES` build settings across targets
- `drinkpulse/AppIcon.icon/icon.json` — Icon Composer definition: linear-gradient fill (display-p3 teal → srgb blue), two layers (`drinkpulse-3-pulse.svg` scale 1.4, `drinkpulse-2-drop.svg` scale 1.4 with `glass: true`), no explicit dark/tinted rendition override
- `drinkpulse/Assets.xcassets/AccentColor.colorset/Contents.json` — brand accent color (coral, srgb 0.98/0.365/0.212), considered and rejected for the launch background (see D-01)

[No ADRs directly govern launch-screen presentation — this is new ground.]

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `drinkpulse/AppIcon.icon` — Icon Composer bundle (iOS 26 format), source of the launch icon artwork (D-02)
- `Color(.systemBackground)` pattern already used at `drinkpulseApp.swift:75` — reuse directly for the launch screen background token

### Established Patterns
- `GENERATE_INFOPLIST_FILE = YES` is set project-wide — no standalone `Info.plist` exists today; any launch-screen config change must work within (or explicitly convert away from) generated-Info.plist build settings.

### Integration Points
- Launch screen is pre-process UI (UIKit/Info.plist level), not a SwiftUI view — it has no runtime code path to integrate with. The only "integration point" is visual continuity with `drinkpulseApp.swift`'s `.loading` state at the moment the launch screen hands off to the first live frame.

</code_context>

<specifics>
## Specific Ideas

No specific mockup or reference image was provided for this phase. The
guiding principle established in discussion: minimal diff, maximum visual
consistency with what already exists (Home Screen icon, `.loading` state's
system background) — no new artwork, no new design decisions beyond asset
export mechanics.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. (Designing new dark-mode icon
artwork was raised and explicitly declined, not deferred — see D-04.)

</deferred>

---

*Phase: 4-Branded Static Launch Screen*
*Context gathered: 2026-07-28*
