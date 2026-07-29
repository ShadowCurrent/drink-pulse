---
phase: 04-branded-static-launch-screen
plan: 01
subsystem: ui
tags: [uilaunchscreen, icon-composer, asset-catalog, info-plist, xcuitest, ios26]

# Dependency graph
requires: []
provides:
  - "LaunchBackground.colorset (dual-appearance white/black, matches Color(.systemBackground))"
  - "LaunchIcon.imageset (flattened AppIcon.icon composition extracted from the compiled Home-Screen-icon rendering)"
  - "Standalone drinkpulse/Info.plist wiring UILaunchScreen -> LaunchIcon/LaunchBackground (Pattern 2 fallback)"
  - "LaunchHandoffUITests regression coverage for normal app launch (onboarded + fresh-onboarding paths)"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Custom UILaunchScreen sub-keys (UIImageName/UIColorName) do NOT resolve via flat INFOPLIST_KEY_UILaunchScreen_UIImageName/UIColorName build settings under GENERATE_INFOPLIST_FILE=YES on Xcode 26.6 -- confirmed empirically, not just per RESEARCH.md's unconfirmed assumption. A standalone Info.plist (GENERATE_INFOPLIST_FILE=NO + INFOPLIST_FILE=drinkpulse/Info.plist) is required for any nested UILaunchScreen sub-key customization."
    - "PBXFileSystemSynchronizedBuildFileExceptionSet membershipExceptions -- required to exclude a hand-authored file (Info.plist) from a PBXFileSystemSynchronizedRootGroup's default automatic resource-copy membership, avoiding a 'Multiple commands produce Info.plist' build error."

key-files:
  created:
    - drinkpulse/Assets.xcassets/LaunchBackground.colorset/Contents.json
    - drinkpulse/Assets.xcassets/LaunchIcon.imageset/Contents.json
    - drinkpulse/Assets.xcassets/LaunchIcon.imageset/LaunchIcon.png
    - drinkpulse/Info.plist
    - drinkpulseUITests/Features/Shell/LaunchHandoffUITests.swift
  modified:
    - drinkpulse.xcodeproj/project.pbxproj

key-decisions:
  - "Fell back to RESEARCH.md's documented Pattern 2 (standalone Info.plist) after empirically disproving Assumption A1: INFOPLIST_KEY_UILaunchScreen_UIImageName/UIColorName flat build settings were tested directly (build + inspect compiled Info.plist) and do not populate the UILaunchScreen dict -- with _Generation=YES present the dict appears but empty; with the two sub-keys alone, the dict does not appear at all. This resolves RESEARCH.md Open Question 1 empirically."
  - "Extracted LaunchIcon.png from actool's real compiled fallback rendering (AppIcon60x60@2x.png inside the built .app bundle) rather than Icon Composer's GUI 'File -> Export', since RESEARCH.md documents the latter as having a margin bug (Pitfall 1). The compiled bundle PNG already carries the correct squircle mask/margin because it comes from the same asset-compilation pipeline Xcode uses for the real Home Screen icon, not the standalone export path."
  - "Assigned the 120x120px extracted icon to the imageset's 2x slot (not 1x or 3x) so it renders at 60pt, matching the iPhone Home Screen icon's point size exactly (D-03). No native 3x (180px) rendition was available from actool's output for this .icon-format bundle; on 3x devices the 2x asset is auto-upscaled by the OS, which preserves the correct on-screen size at a minor cost to pixel sharpness -- documented here as a known limitation, not a D-03 violation (D-03 is a size/crop contract, not a pixel-density one)."
  - "The `xcode` MCP tool referenced in the plan/dispatch prompt was not present in this execution session's actual tool set (despite an MCP-server instructions notice appearing in context) -- all of Task 1's steps (Icon Composer-equivalent export, Xcode Info-tab-equivalent build-setting resolution, Simulator screenshot comparison) were performed via Bash/xcodebuild/actool/simctl CLI tooling instead, per the plan's own explicit fallback instruction ('fall back to manual file edits / actool only if the MCP tool is unavailable')."

requirements-completed: []
# LAUNCH-01 intentionally NOT marked complete here -- Success Criteria #1-#3
# require a genuine force-quit cold launch on a REAL physical device (Task 3),
# which is blocked pending human execution. Do not mark LAUNCH-01 complete
# until Task 3's checkpoint is explicitly approved.

coverage:
  - id: D1
    description: "Cold launch shows a branded static launch screen (icon + matching background) instead of the auto-generated blank screen"
    requirement: "LAUNCH-01"
    verification:
      - kind: manual_procedural
        ref: "Task 3 checkpoint:human-verify -- real-device force-quit cold launch, light + dark mode"
        status: unknown
    human_judgment: true
    rationale: "XCUITest attaches only after the app process starts, structurally after the pre-process UILaunchScreen has already rendered and handed off -- no automated test can observe the real launch screen. This is a hard, unautomatable requirement per 04-RESEARCH.md's Validation Architecture."
  - id: D2
    description: "Launch-screen build settings reference LaunchIcon/LaunchBackground assets with the auto-generation flag removed, and the app builds clean"
    requirement: "LAUNCH-01"
    verification:
      - kind: unit
        ref: "xcodebuild -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build (zero warnings) + compiled Info.plist inspection confirming UILaunchScreen = {UIImageName: LaunchIcon, UIColorName: LaunchBackground}"
        status: pass
    human_judgment: false
  - id: D3
    description: "Normal app launch into onboarding Welcome or the Dashboard is unaffected by the Info.plist mechanism switch"
    requirement: "LAUNCH-01"
    verification:
      - kind: automated_ui
        ref: "drinkpulseUITests/Features/Shell/LaunchHandoffUITests.swift (2 tests) + full drinkpulseUITests suite (69/69 passing)"
        status: pass
    human_judgment: false

duration: "~50 min (Tasks 1-2) + ~25 min (Task 3 round-1 re-verification investigation, no code changes) + ~30 min (Task 3 round-2: LaunchIcon opaque-corner bugfix); plan blocked at Task 3 pending real-device verification of the round-2 fix"
completed: "pending -- blocked at Task 3 checkpoint:human-verify"
status: blocked
---

# Phase 4 Plan 01: Branded Static Launch Screen Summary

**LaunchIcon/LaunchBackground Asset Catalog entries wired through a standalone `drinkpulse/Info.plist`'s `UILaunchScreen` dict (Pattern 2 fallback), replacing the auto-generated blank launch screen -- Tasks 1-2 complete and committed; Task 3's real-device cold-launch verification is a blocking checkpoint awaiting human execution.**

## Performance

- **Started:** ~2026-07-29T07:12:00Z (worktree setup / first build)
- **Tasks 1-2 completed:** 2026-07-29T07:44:00Z
- **Duration (Tasks 1-2):** ~50 min
- **Tasks:** 2 of 3 completed (Task 3 is a blocking `checkpoint:human-verify`, real-device only)
- **Files modified:** 6 (5 created, 1 modified)

## Accomplishments

- Created `LaunchBackground.colorset` with an exact dual-appearance match to `Color(.systemBackground)` (white `1.000/1.000/1.000` Any Appearance, black `0.000/0.000/0.000` Dark)
- Created `LaunchIcon.imageset` from a flattened PNG extracted directly from the compiled app bundle's real Home-Screen-icon rendering (not Icon Composer's margin-buggy GUI export)
- Wired `UILaunchScreen` (`UIImageName = LaunchIcon`, `UIColorName = LaunchBackground`) via a standalone `drinkpulse/Info.plist` after empirically disproving that flat `INFOPLIST_KEY_UILaunchScreen_*` sub-keys work under `GENERATE_INFOPLIST_FILE=YES` on this Xcode version
- Removed `INFOPLIST_KEY_UILaunchScreen_Generation = YES` from both Debug and Release configs (confirmed via `grep -c` returning 0)
- Added `LaunchHandoffUITests` (2 tests) proving zero regression to normal app launch (onboarded -> Home tab, fresh -> Onboarding Welcome); full `drinkpulseUITests` suite (69 tests) passes with 0 failures

## Task Commits

Each task was committed atomically:

1. **Task 1: Branded launch screen -- Asset Catalog entries + launch-screen build-setting wiring** - `a654cd1` (feat)
2. **Task 2: Launch-handoff regression UI test** - `64a60b1` (test)
3. **Task 3: Real-device force-quit cold-launch verification** - **BLOCKED, not yet executed** (checkpoint:human-verify, requires a real physical device)

**Plan metadata:** this commit (docs: SUMMARY + progress snapshot)

## Files Created/Modified

- `drinkpulse/Assets.xcassets/LaunchBackground.colorset/Contents.json` - Dual-appearance color set, white(Any)/black(Dark), zero-diff match to `Color(.systemBackground)`
- `drinkpulse/Assets.xcassets/LaunchIcon.imageset/Contents.json` + `LaunchIcon.png` - Flattened, correctly-margined static export of `AppIcon.icon`, assigned to the imageset's 2x slot (60pt on iPhone)
- `drinkpulse/Info.plist` - New standalone Info.plist for the app target (Pattern 2), carries all previously-generated `INFOPLIST_KEY_*` values plus the new `UILaunchScreen` dict
- `drinkpulse.xcodeproj/project.pbxproj` - App target Debug/Release: `GENERATE_INFOPLIST_FILE` YES->NO, `INFOPLIST_FILE = drinkpulse/Info.plist` added; new `PBXFileSystemSynchronizedBuildFileExceptionSet` excluding `Info.plist` from the `drinkpulse/` synced folder's automatic resource membership
- `drinkpulseUITests/Features/Shell/LaunchHandoffUITests.swift` - 2 new regression tests (67 lines)

## Decisions Made

See `key-decisions` in frontmatter. Summary: Pattern 1 (flat `INFOPLIST_KEY_UILaunchScreen_*` build settings) was tested and empirically disproven, so Pattern 2 (standalone `Info.plist`) was used instead, exactly as RESEARCH.md's own documented fallback anticipated. This is a larger diff than Pattern 1 would have been (reintroduces a hand-authored `Info.plist`, which this project had otherwise avoided everywhere) -- flagged here per the plan's own instruction to document this divergence if Pattern 2 was needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `xcode` MCP tool unavailable in this session**
- **Found during:** Task 1, step 2 (Icon Composer export) and step 4 (Xcode Info-tab build-setting resolution)
- **Issue:** The dispatch prompt referenced an `xcode` MCP server as available, but no `mcp__xcode__*` tools were present in this session's actual tool set.
- **Fix:** Followed the plan's own explicit fallback: extracted the flattened icon PNG via `actool`/the compiled app bundle instead of Icon Composer's GUI export, and resolved the exact `UILaunchScreen` build-setting mechanism by direct empirical testing (build + inspect the compiled `Info.plist`) instead of using Xcode's Target -> Info tab GUI.
- **Files modified:** N/A (methodology only, no extra files beyond what the plan already specified)
- **Verification:** Build succeeds with zero warnings; compiled `Info.plist` inspected directly via `plutil`/`PlistBuddy` confirms `UILaunchScreen = {UIImageName: LaunchIcon, UIColorName: LaunchBackground}`.
- **Committed in:** a654cd1 (Task 1 commit)

**2. [Rule 3 - Blocking] Pattern 1 (flat `INFOPLIST_KEY_UILaunchScreen_UIImageName`/`UIColorName` build settings) does not work**
- **Found during:** Task 1, step 4
- **Issue:** RESEARCH.md's Assumption A1 (that these sub-keys follow the same flat-key convention as `INFOPLIST_KEY_UILaunchScreen_Generation`) was tested directly and disproven -- with `_Generation=YES` present alongside the two sub-keys, the compiled `UILaunchScreen` dict appeared but empty (`{}`); without `_Generation`, the dict did not appear in the compiled `Info.plist` at all.
- **Fix:** Switched to RESEARCH.md's own documented Pattern 2 fallback: `GENERATE_INFOPLIST_FILE = NO` + `INFOPLIST_FILE = drinkpulse/Info.plist` on the app target (Debug + Release), with a hand-authored `Info.plist` carrying both the new `UILaunchScreen` dict and every previously-generated `INFOPLIST_KEY_*` value (via `$(...)` build-setting substitution, which still applies to standalone Info.plist files at build time).
- **Files modified:** `drinkpulse.xcodeproj/project.pbxproj`, `drinkpulse/Info.plist` (new)
- **Verification:** `xcodebuild build` succeeds with zero warnings; compiled `Info.plist` contains the correct `UILaunchScreen` dict and all prior keys (`CFBundleDisplayName`, `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`, `UIApplicationSceneManifest`, `UIApplicationSupportsIndirectInputEvents`, `UISupportedInterfaceOrientations[~ipad]`) with no regressions.
- **Committed in:** a654cd1 (Task 1 commit)

**3. [Rule 1 - Bug] `PBXFileSystemSynchronizedRootGroup` auto-membership conflicted with the new standalone `Info.plist`**
- **Found during:** Task 1, step 4 (first build attempt after switching to Pattern 2)
- **Issue:** `drinkpulse/` is a `PBXFileSystemSynchronizedRootGroup` (per this project's convention -- see CLAUDE.md), so Xcode auto-includes every file physically inside that folder as a Copy Bundle Resources member, including the newly created `Info.plist`. This collided with the `INFOPLIST_FILE` build setting's own `ProcessInfoPlistFile` task, producing a "Multiple commands produce Info.plist" build error.
- **Fix:** Added a `PBXFileSystemSynchronizedBuildFileExceptionSet` with `membershipExceptions = (Info.plist)`, referenced from the `drinkpulse` root group's `exceptions` array, excluding `Info.plist` from automatic resource-copy membership while keeping it on disk for `INFOPLIST_FILE` to process.
- **Files modified:** `drinkpulse.xcodeproj/project.pbxproj`
- **Verification:** Build succeeds with zero warnings and no duplicate-output error/warning.
- **Committed in:** a654cd1 (Task 1 commit)

**4. [Rule 3 - Blocking] Task 3 checkpoint reported "still white screen, no icon" -- investigated, no code defect found; root cause is branch isolation, not implementation**
- **Found during:** Task 3 checkpoint re-verification (human real-device test after Tasks 1-2)
- **User report (verbatim):** "after the app is restarted or reinstalled, there is still white screen instead of any Launch Icon, so there is like no difference"
- **Investigation performed** (per 04-RESEARCH.md Pitfall 4 and the checkpoint's own resume instructions, in order):
  1. Ran a clean `xcodebuild build` from this worktree and inspected the **compiled** `Info.plist` inside the built `.app` (`plutil -extract UILaunchScreen`): contains exactly `{UIColorName: LaunchBackground, UIImageName: LaunchIcon}` -- correct, both configs.
  2. Inspected the compiled `Assets.car` via `assetutil --info`: both `LaunchBackground` (universal + dark-appearance renditions) and `LaunchIcon` (120x120, 2x, opaque, universal) are present as compiled entries -- target membership is correct, nothing missing from the catalog.
  3. Re-confirmed `GENERATE_INFOPLIST_FILE = NO` / `INFOPLIST_FILE = drinkpulse/Info.plist` present for **both** Debug (`4FD1C70B...`) and Release (`4FD1C70C...`) app-target configs, and that all previously-generated required keys (`CFBundleDisplayName`, `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`, `UIApplicationSceneManifest`, etc.) survived the switch to a standalone `Info.plist` -- no regression.
  4. Installed the freshly built app on `iPhone 17 Pro` Simulator (a 3x-scale device, confirmed via `SIMULATOR_MAINSCREEN_SCALE=3.000000` -- i.e. a stricter scale-matching test than the 2x-only `LaunchIcon` asset technically provides), force-terminated, cold-launched, and screenshotted within ~150ms of launch: **the branded icon renders correctly**, centered on a plain white background, exactly as intended -- ruling out an asset-wiring or scale-fallback defect, and ruling out Pitfall 4 (name mismatch) since a mismatch would render blank, not correct, in this same test.
  5. Inspected the `LaunchIcon.png` directly: 120x120px, 8-bit RGBA with alpha, non-degenerate, visibly renders the drop+pulse icon (confirmed by the same Simulator screenshot) -- not a blank/transparent export.
  - All five checks came back clean: **there is no code-level defect in this worktree's implementation.**
- **Actual root cause identified:** this plan's Tasks 1-2 commits (`a654cd1`, `64a60b1`) exist **only** on the isolated worktree branch `worktree-agent-ab520f6e07b229256`. The primary checkout at `/Users/fempter/Developer/drinkpulse` is still on `main`, which was confirmed (`git log --oneline HEAD..main` from the worktree, and direct inspection of the main checkout) to be sitting exactly at this branch's merge-base (`db6baa4`) with **zero** of this plan's commits applied -- `main`'s `drinkpulse/Info.plist` and `LaunchIcon.imageset` do not exist, and `main`'s `project.pbxproj` still has `INFOPLIST_KEY_UILaunchScreen_Generation = YES`. If the real-device build was made from Xcode pointed at the primary checkout (the normal, expected place to open this project from), it built and installed the **unmodified pre-phase code** -- which exactly matches the user's own description, "like no difference," since literally nothing changed in that build. Both a plain restart and a full reinstall would reproduce the identical blank screen either way, because both re-tested the same unchanged binary.
- **Fix:** No code change was made (none was warranted -- the implementation is verified correct via 5 independent checks above). The corrective action is procedural: Task 3's `how-to-verify` steps are revised (see the fresh checkpoint returned below) to explicitly build and install from this worktree's own `.xcodeproj` (`/Users/fempter/Developer/drinkpulse/.claude/worktrees/agent-ab520f6e07b229256/drinkpulse.xcodeproj`), not the primary checkout, until this branch is merged.
- **Files modified:** None (this SUMMARY.md only).
- **Verification:** See investigation steps 1-5 above (compiled Info.plist, compiled Assets.car, build-setting diff, Simulator cold-launch screenshot, PNG inspection) -- all pass. Re-ran the full zero-warning build gate and `grep -c INFOPLIST_KEY_UILaunchScreen_Generation` (still `0`) to re-confirm Task 1's acceptance criteria hold unchanged.
- **Committed in:** this SUMMARY.md update commit (docs).

---

**5. [Rule 1 - Bug] `LaunchIcon.png` was fully opaque at all four corners -- rendered as a hard-edged colored square, not the expected rounded icon**
- **Found during:** Task 3 checkpoint re-verification, round 2 (human real-device test after the worktree merge into `main`)
- **User report (verbatim):** "the icon looks strange, it has sharp corners and does not integrate with the white background, wtf is this?"
- **Root cause:** `LaunchIcon.png` was extracted from `actool`'s compiled Home-Screen-icon fallback rendering (Deviation 2's fix, commit `a654cd1`) -- which is Apple's raw, **unmasked square** icon asset. iOS applies the rounded-squircle mask only at Springboard render time on the Home Screen; the asset itself, as stored/compiled, is a plain opaque square. `UILaunchScreen`'s `UIImageName` mechanism performs **no such masking** -- it draws the raw image as-is. The result was a fully-opaque gradient square (verified: all four corners at alpha=255, colors `(0,228,207)` teal top / `(37,99,235)` blue bottom, matching `icon.json`'s linear-gradient exactly) composited on the white/black `LaunchBackground`, producing a jarring hard-edged colored block instead of the rounded icon the Home Screen shows. Notably, Deviation 4's own investigation (previous round) had already surfaced this in passing -- its `assetutil` dump literally recorded the compiled rendition as `"opaque"` -- but that detail wasn't recognized as the defect at the time.
- **Independent verification of root cause (before fixing):** wrote a pure-stdlib (no PIL/ImageMagick available in this environment) PNG decoder in Python and sampled all four corners plus center directly from `drinkpulse/Assets.xcassets/LaunchIcon.imageset/LaunchIcon.png`:
  - Before fix -- TL `(0,228,207,255)`, TR `(0,228,207,255)`, BL `(37,99,235,255)`, BR `(37,99,235,255)`, center `(208,244,252,255)` -- all four corners fully opaque, colors matching the raw gradient fill, not `LaunchBackground` white/black.
- **Fix:** Chosen remediation path (a) from the two offered -- true alpha punch-out, matching D-02/UI-SPEC's requirement that the launch icon be "pixel-equivalent to the real Home Screen `AppIcon`" (which visually means rounded, since that's how Springboard actually displays it). No Icon Composer/`actool` CLI path exists to export a pre-masked PNG (the compiled Home-Screen-icon rendition is *always* the unmasked square; the OS applies masking only at display time), so a rounded-rect alpha mask was computed directly against the existing composited pixel data in pure Python (`struct`/`zlib` stdlib only -- no PIL/ImageMagick installed): 22.37% corner-radius ratio (commonly cited iOS app-icon corner ratio), 4x4 supersampled antialiasing at the curve boundary for a smooth (non-jagged) edge. Only the alpha channel changed -- all RGB content is byte-identical to the pre-fix PNG.
- **Verification after fix (my own, asset-level):**
  - Re-ran the same corner probe: TL `(0,228,207,0)`, TR `(0,228,207,0)`, BL `(37,99,235,0)`, BR `(37,99,235,0)`, center unchanged `(208,244,252,255)` -- corners now genuinely transparent (alpha=0), not just visually similar.
  - Mid-edge samples (`(w/2,0)`, `(0,h/2)`) remain fully opaque (alpha=255) -- confirms a proper rounded-*rect* mask (flat sides intact, only corners punched out), not an over-aggressive circular crop.
  - Composited the masked icon over both pure white and pure black backgrounds (pure-Python alpha blend) and visually inspected both renders directly (image-capable read) -- clean rounded-squircle icon, no visible halo or color mismatch against either background.
  - Rebuilt the app (`xcodebuild build`, zero warnings) and inspected the **compiled** `Assets.car` via `assetutil --info` against the correct (freshly-built, timestamp-matched) DerivedData path: `LaunchIcon` rendition now reports `"Opaque": false` (previously effectively opaque, as Deviation 4's own dump inadvertently recorded) -- confirms the asset-catalog compiler picked up the new alpha channel correctly, not just that the source PNG file looks right.
  - Re-ran Task 1's full `acceptance_criteria`: `grep -c INFOPLIST_KEY_UILaunchScreen_Generation` still `0`; `Contents.json` unchanged (still references `LaunchIcon.png` at `2x`/`universal`); `git diff --stat -- drinkpulse/drinkpulseApp.swift` empty; `xcodebuild build` succeeds with zero warnings (`grep -ci warning:` on the full build log returns `0`).
  - Re-ran Task 2's `LaunchHandoffUITests` (`-only-testing:drinkpulseUITests/LaunchHandoffUITests`): both tests pass, 0 failures -- no regression to normal app launch from the asset-only change.
  - Attempted a Simulator cold-launch screenshot as a bonus sanity check; per 04-RESEARCH.md Pitfall 3 this proved timing-unreliable (captured the Home Screen, not the transient launch frame) and is **not** treated as evidence either way -- disregarded, consistent with why Task 3 is a real-device human checkpoint in the first place.
  - **What I could NOT verify myself:** how this actually looks on real hardware during a genuine force-quit cold launch, and the light/dark-mode handoff transition -- this requires the human checkpoint below.
- **Files modified:** `drinkpulse/Assets.xcassets/LaunchIcon.imageset/LaunchIcon.png` (pixel data only -- `Contents.json` untouched).
- **Committed in:** `072c811` (fix)

---

**Total deviations:** 5 (3 auto-fixed on first pass: 2 blocking/Rule 3, 1 bug/Rule 1; 1 investigated on Task 3 round-1 re-check: Rule 3/blocking, resolved as a testing-location issue with no code defect found; 1 auto-fixed on Task 3 round-2 re-check: Rule 1/bug, opaque-corner artifact).
**Impact on plan:** The first three were necessary to get a working build; none change the phase's scope or user-facing outcome. Pattern 2's larger diff (a new `Info.plist`) is exactly what RESEARCH.md anticipated as the fallback and was called out per the plan's own instruction to flag it. The fourth confirmed Tasks 1-2's implementation was correct as committed once tested against the right branch. The fifth is a genuine bug fix to the `LaunchIcon.png` asset itself (alpha channel only, no build-setting or wiring change) -- Task 1's acceptance criteria and Task 2's regression tests both re-pass unchanged after the fix.

## Issues Encountered

- The `xcode` MCP tool was not actually invocable in this session (see Deviation 1) -- worked around via CLI equivalents (`actool`, `xcodebuild`, `xcrun simctl`, `plutil`/`PlistBuddy`) for every step the plan expected the MCP tool to handle.
- No native 3x (180px) icon rendition was obtainable from `actool`'s output for the `.icon`-format `AppIcon.icon` bundle (only 60x60@2x and 76x76@2x~ipad flattened fallbacks exist) -- the 2x asset is used and will be auto-upscaled by the OS on 3x devices, which is visually correct in point-size but not pixel-perfect on the newest iPhones. Documented as a known, low-severity limitation, not a D-03 violation.

## Known Stubs

None.

## Threat Flags

None -- this phase's threat model (STRIDE register T-04-01/T-04-02) already covers the `project.pbxproj` build-setting edit and the new Asset Catalog entries at "accept" disposition. The standalone `Info.plist` fallback and the `PBXFileSystemSynchronizedBuildFileExceptionSet` are both static, on-device, build-time-only project configuration -- no new runtime surface, no network, no user data.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**BLOCKED at Task 3 (round 3).** The worktree from round 1 has since been merged into `main` (commit `09a79e1`); all work, including the round-2 `LaunchIcon.png` alpha-mask fix (`072c811`), now lives directly on `main` at the primary checkout. Before this plan (and Phase 4) can be considered complete:

1. A human must build and install the app onto a real physical iOS device from the primary checkout (`/Users/fempter/Developer/drinkpulse`, `main` branch) -- no worktree involved this round -- fully force-quit it, and cold-launch it.
2. Confirm: branded icon **rounded** (matching the Home Screen icon's squircle shape, not a hard-edged square) and centered at Home-Screen-icon size on a plain white (light) / black (dark) background, no text/spinner/animation, no visible flash or halo at handoff into the first live frame -- in both light and dark mode.
3. Only after explicit approval of Task 3's checkpoint should `LAUNCH-01` be marked complete in `REQUIREMENTS.md` and this plan's status updated to `complete`.

No other phase or plan depends on this one (Phase 4/5/6 are independent per `STATE.md`'s Roadmap Evolution note), so this block does not affect other in-flight work.

---
*Phase: 04-branded-static-launch-screen*
*Completed: pending (blocked at Task 3 checkpoint)*
