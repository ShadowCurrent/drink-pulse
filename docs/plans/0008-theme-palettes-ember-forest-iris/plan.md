# 0008 — Theme palettes: Ember / Forest / Iris

**Status**: in-progress
**Frozen**: 2026-05-20
**Size**: medium
**Created**: 2026-05-19

## Summary

Add three first-class colour palettes the user can pick in Settings.
Each palette drives: the app-wide `.tint()` and the FAB gradient pair.
Card backgrounds stay system glass — no per-theme tinting.

Defaults: **Ember** + **follow system** for appearance.

## Context

The Claude Design handoff (2026-05-19) ships three palettes:

| Theme  | Primary (oklch)  | sRGB hex  | Vibe                  |
|--------|------------------|-----------|-----------------------|
| Ember  | 0.68 0.20 35     | #FA5D36   | warm coral/orange-red |
| Forest | 0.52 0.15 155    | #008140   | deep forest green     |
| Iris   | 0.58 0.20 290    | #7D5BE6   | deep purple/lavender  |

Gradient end (H ± 20°, slightly higher L):

| Theme  | Gradient end hex |
|--------|-----------------|
| Ember  | #FF7C00         |
| Forest | #529420         |
| Iris   | #B85DF1         |

iOS 26 glass surfaces pick up `.tint()` automatically — one call at the
root propagates colour into every glass card, navigation bar, and control.
Explicit per-surface tinting would fight the system and look non-native.

## Scope

### In
- `DesignSystem/DPTheme.swift` — `enum DPTheme: String, Codable, CaseIterable`
  with computed `primary: Color`, `gradientStart: Color`, `gradientEnd: Color`,
  `gradient: LinearGradient`, `displayName: String`. Pre-converted sRGB hex
  constants — no runtime oklch conversion.
- `DesignSystem/DPTheme+Environment.swift` — `@Entry var dpTheme: DPTheme = .ember`
  so any view can read the active theme without prop-drilling.
- `drinkpulseApp.swift` — reads `@AppStorage("dp_theme")` and injects
  `.environment(\.dpTheme, theme)` + `.tint(theme.primary)` on the root.
- Settings UI — new "Appearance" section: 3-swatch theme picker + system/light/dark
  mode `Picker`. Mode selection uses `@AppStorage("dp_color_scheme")`.

### Out
- Card background tinting — stays system glass, theme-independent.
- Tab-bar custom background — stays system `Material.bar`.
- Custom user-defined themes.
- High-contrast accessibility palette.
- Per-screen theme overrides.
- Theme transition animation (system cross-fade is sufficient).

## Open questions resolved

- **Q1 — Tab bar**: system `Material.bar` (B). Tinting it explicitly breaks
  iOS 26 Liquid Glass — the tint propagates naturally via root `.tint()`.
- **Q2 — Colour source**: sRGB hex constants (A). oklch converted once; see
  table above. Values committed inline, not in Asset Catalog.
- **Q3 — Mode picker**: Settings → Appearance (A, default).
- **Q4 — Default theme**: Ember (A, default).

## Implementation steps

1. **`DPTheme.swift`** — enum, sRGB constants, computed `primary`,
   `gradientStart`, `gradientEnd`, `gradient`, `displayName`.
2. **`DPTheme+Environment.swift`** — `@Entry` environment key.
3. **`drinkpulseApp.swift`** — `@AppStorage("dp_theme")` + inject
   `.environment(\.dpTheme, theme)` and `.tint(theme.primary)`.
   Also `@AppStorage("dp_color_scheme")` → `preferredColorScheme` on root.
4. **Settings appearance section** — theme swatch picker + mode picker;
   insert above existing Settings sections.
5. **Tests** — `DPThemeTests.swift`: primary distinct per case, rawValue
   round-trip, gradient endpoints distinct per case.

## Files

| File | Action |
|------|--------|
| `drinkpulse/DesignSystem/DPTheme.swift` | Create |
| `drinkpulse/DesignSystem/DPTheme+Environment.swift` | Create |
| `drinkpulse/Features/Settings/SettingsView.swift` | Modify (new Appearance section) |
| `drinkpulse/drinkpulseApp.swift` | Modify (theme injection + tint) |
| `drinkpulseTests/DPThemeTests.swift` | Create |

## Tests required

- `DPTheme.primary` returns a distinct colour per case.
- `DPTheme(rawValue:)` round-trips correctly; invalid rawValue → nil.
- `gradientStart != gradientEnd` for every case.
- All `CaseIterable` cases have a non-empty `displayName`.

## Future links

- [[plan-0010]] — FAB uses `theme.gradient` for its fill.
- [[plan-0011]] — arc may use `theme.primary` as fallback colour for
  low-risk days (avoids green-on-green clash in Forest theme).
