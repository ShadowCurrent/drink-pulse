# Phase 4: Branded Static Launch Screen - Pattern Map

**Mapped:** 2026-07-28
**Files analyzed:** 4 (2 new assets, 1 build-setting edit, 1 read-only visual-contract reference)
**Analogs found:** 4 / 4

This phase is pure Xcode project configuration + Asset Catalog additions — there
is no application Swift code to write. "Files" below are asset-catalog entries
and a `project.pbxproj` build-setting edit, not source files.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|---------------|
| `drinkpulse/Assets.xcassets/LaunchBackground.colorset/Contents.json` | config (asset-catalog colorset) | static-value (no data flow) | `drinkpulse/Assets.xcassets/AccentColor.colorset/Contents.json` (single-appearance form) and `drinkpulse/Assets.xcassets/RiskHigh.colorset/Contents.json` (dual-appearance/dark-mode form) | exact |
| `drinkpulse/Assets.xcassets/LaunchIcon.imageset/Contents.json` + `.png` | config (asset-catalog imageset) | static-value (no data flow) | No existing standalone `.imageset` in the catalog (project only has `.colorset` entries + the Icon Composer `AppIcon.icon` bundle) — no analog imageset exists; use Xcode's standard 1x/2x/3x (or "Any Appearance"/"Dark") `Contents.json` shape when Xcode generates the imageset via drag-in | none (see "No Analog Found") |
| `drinkpulse.xcodeproj/project.pbxproj` (App target Debug + Release `XCBuildConfiguration` blocks) | config (build settings) | static-value (no data flow) | Same file, `INFOPLIST_KEY_UILaunchScreen_Generation = YES` lines already present at lines 419 (Debug) and 455 (Release), inside the same `buildSettings` blocks that also set `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor` | exact |
| `drinkpulseApp.swift` `.loading` case (lines 70-75) | reference only — NOT modified this phase | static-value (visual contract) | itself — this is the pixel-match target for D-01, read but do not edit | n/a (reference) |

## Pattern Assignments

### `drinkpulse/Assets.xcassets/LaunchBackground.colorset/Contents.json` (config, static-value)

**Analog (single-appearance shape):** `drinkpulse/Assets.xcassets/AccentColor.colorset/Contents.json` (full file, 21 lines)
```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.212",
          "green" : "0.365",
          "red" : "0.980"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

**Analog (dual-appearance / dark-mode shape):** `drinkpulse/Assets.xcassets/RiskHigh.colorset/Contents.json` (full file, 39 lines) — shows the exact `"appearances": [{ "appearance": "luminosity", "value": "dark" }]` block structure to add a second color entry for Dark mode alongside the default ("Any Appearance") entry:
```json
{
  "colors" : [
    {
      "color" : { "color-space" : "srgb", "components" : { "alpha" : "1.000", "blue" : "0.210", "green" : "0.220", "red" : "0.900" } },
      "idiom" : "universal"
    },
    {
      "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
      "color" : { "color-space" : "srgb", "components" : { "alpha" : "1.000", "blue" : "0.300", "green" : "0.330", "red" : "1.000" } },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

**How to combine for `LaunchBackground`:** Use `RiskHigh.colorset`'s two-entry structure (default entry first, `"appearances"` dark-mode entry second) but substitute D-01's white/black component values:
- Default (light) entry components: `{ "alpha": "1.000", "blue": "1.000", "green": "1.000", "red": "1.000" }`
- Dark entry components: `{ "alpha": "1.000", "blue": "0.000", "green": "0.000", "red": "0.000" }`

This must resolve to the exact same RGB as `Color(.systemBackground)` at `drinkpulseApp.swift:75` (see Shared Patterns below) — RESEARCH.md flags this as MEDIUM-confidence (A2) and calls for an on-device spot-check with a color picker before final commit.

**File/dir naming convention:** colorset directories are named `<AssetName>.colorset/Contents.json`, matching the asset name referenced elsewhere (e.g. `AccentColor` is referenced via `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor` in `project.pbxproj:407,443`). `LaunchBackground.colorset` should follow the same 1:1 name-to-reference convention for the `UIColorName` key.

---

### `drinkpulse/Assets.xcassets/LaunchIcon.imageset/Contents.json` (config, static-value)

**No analog exists in this catalog** — see "No Analog Found" below. Use Xcode's own generated `Contents.json` shape when the flattened PNG(s) are dragged into a new Image Set (File > New > Image Set, or drag-and-drop in Xcode's Asset Catalog editor) rather than hand-authoring the JSON. If D-04's "Any + Dark" split is needed, follow the same `"appearances"` block pattern shown above in `RiskHigh.colorset/Contents.json`, adapted for an `images` array (`idiom`, `filename`, `appearances`) instead of a `colors` array.

**Source of the flattened artwork:** `drinkpulse/AppIcon.icon/icon.json` — Icon Composer bundle, two SVG layers (`drinkpulse-3-pulse.svg` scale 1.4, `drinkpulse-2-drop.svg` scale 1.4, glass:true), single gradient fill, no dark/tinted override defined. Export via Icon Composer's flattened-PNG export (see RESEARCH.md Pitfall 1 re: margin bug — visually diff against the real Home Screen icon before accepting).

---

### `drinkpulse.xcodeproj/project.pbxproj` — App target Debug/Release `buildSettings` (config, static-value)

**Analog:** same file, same target's existing `buildSettings` blocks — Debug at lines 403-438, Release at lines 439-474.

**Current state to modify (both Debug line 419 and Release line 455):**
```
INFOPLIST_KEY_UILaunchScreen_Generation = YES;
```

**Sibling-key naming convention** (justifies the `INFOPLIST_KEY_UILaunchScreen_*` prefix pattern, per RESEARCH.md A1) — other `INFOPLIST_KEY_*` entries in the same blocks:
```
INFOPLIST_KEY_CFBundleDisplayName = DrinkPulse;
INFOPLIST_KEY_NSHealthShareUsageDescription = "DrinkPulse reads its own Alcohol Consumption entries in Apple Health to avoid writing duplicate drinks.";
INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
INFOPLIST_KEY_UILaunchScreen_Generation = YES;
INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
```

**Asset-name-reference convention analog** (shows how an asset-catalog name is threaded into a build setting, same pattern the new `UIImageName`/`UIColorName` sub-keys will follow):
```
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
```

**Recommended change (per RESEARCH.md Pattern 1 + Pitfall 2):** remove/disable `INFOPLIST_KEY_UILaunchScreen_Generation = YES` in both Debug and Release blocks, and add the sibling sub-keys (spelling to be confirmed via Xcode's Target > Info tab GUI, not hand-typed — see RESEARCH.md Open Question 1):
```
INFOPLIST_KEY_UILaunchScreen_UIColorName = LaunchBackground;
INFOPLIST_KEY_UILaunchScreen_UIImageName = LaunchIcon;
```
Both Debug (~line 419) and Release (~line 455) blocks need the identical edit — this project keeps Debug/Release build settings symmetric for all `INFOPLIST_KEY_*` entries (verified: every key present in one block is present in the other, same values, across lines 403-474).

---

## Shared Patterns

### Visual-contract reference (do not edit, only match)
**Source:** `drinkpulse/drinkpulseApp.swift:70-75`
```swift
case .loading:
    // D-11: no new UI here — the existing system-generated
    // launch background simply holds until the container
    // resolves.
    Color(.systemBackground).ignoresSafeArea()
```
**Apply to:** `LaunchBackground.colorset`'s RGB values must render pixel-identical to this `Color(.systemBackground)` call in both light and dark appearance, per D-01 and Success Criterion #3. This file is READ, never modified, this phase.

### Asset Catalog Contents.json conventions
**Source:** `AccentColor.colorset/Contents.json` (single-appearance) and `RiskHigh.colorset/Contents.json` (dual-appearance)
**Apply to:** `LaunchBackground.colorset/Contents.json` — both existing colorsets use `"color-space": "srgb"`, string-quoted numeric components (`"1.000"` not `1.0`), `"idiom": "universal"`, and `"info": {"author": "xcode", "version": 1}`. Follow this exact formatting (let Xcode write it via the GUI color picker to guarantee an exact match, rather than hand-typing).

### Build-setting symmetry (Debug/Release)
**Source:** `project.pbxproj` lines 403-474 (App target)
**Apply to:** Any `INFOPLIST_KEY_UILaunchScreen_*` edit — must be applied identically to both the Debug (`4FD1C70B2FB844AF003FD1F6`) and Release (`4FD1C70C2FB844AF003FD1F6`) `XCBuildConfiguration` blocks, matching this project's existing convention of zero divergence between Debug/Release for all `INFOPLIST_KEY_*` settings.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `drinkpulse/Assets.xcassets/LaunchIcon.imageset/` | config (asset-catalog imageset) | static-value | This project has zero standalone `.imageset` entries in `Assets.xcassets` today — the only icon asset is the Icon Composer `AppIcon.icon` bundle (a different, non-`.imageset` format: `icon.json` + `.svg` layers, compiled by `actool`/Icon Composer rather than authored as a flat imageset). Planner/executor should let Xcode generate the `Contents.json` via its GUI "New Image Set" / drag-and-drop flow rather than hand-authoring, since no in-repo template exists to copy structurally. |

## Metadata

**Analog search scope:** `drinkpulse/Assets.xcassets/` (all `.colorset` and `.imageset` entries), `drinkpulse.xcodeproj/project.pbxproj` (App target build settings, lines 269-513), `drinkpulse/drinkpulseApp.swift` (lines 1-108), `drinkpulse/AppIcon.icon/icon.json`
**Files scanned:** 4 colorsets (AccentColor, RiskHigh, RiskLow, RiskModerate), full `project.pbxproj` grep for `GENERATE_INFOPLIST_FILE`/`INFOPLIST_KEY_UILaunchScreen_Generation`, `drinkpulseApp.swift` `.loading` case, `AppIcon.icon/icon.json`
**Pattern extraction date:** 2026-07-28
