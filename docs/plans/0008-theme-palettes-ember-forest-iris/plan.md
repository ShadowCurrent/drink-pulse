# 0008 — Theme palettes: Ember / Forest / Iris

**Status**: draft
**Size**: medium
**Created**: 2026-05-19

## Summary

Add three first-class colour palettes that the user can pick in Settings.
Each palette drives: primary tint, gradient pair (used by FAB and CTAs),
tinted card surface, and tab-bar background. Dark mode follows the system
appearance — palette × appearance is the matrix.

Defaults: **Ember** + **follow system** for appearance.

## Context

The Claude Design handoff (2026-05-19) ships three palettes:

| Theme  | Primary (oklch)       | Vibe                |
|--------|-----------------------|---------------------|
| Ember  | 0.68 0.20 35          | warm coral/amber    |
| Forest | 0.52 0.15 155         | sage + warm gold    |
| Iris   | 0.58 0.20 290         | deep purple/lavender|

Today the app uses `AccentColor` from Assets + a fixed `DPColors` accent
palette (teal/amber/red/purple/green). Those accents are still useful as
*semantic* colours (drinks=purple, calories=amber); the new theme drives
the *brand* surface — the primary tint, the FAB gradient, and tinted card
backgrounds.

## Scope

### In
- `DesignSystem/DPTheme.swift` — `enum DPTheme: String { case ember, forest, iris }`
  with computed `primary`, `primaryMuted`, `gradientStart`, `gradientEnd`,
  `cardTint(scheme:)`, `tabBackground(scheme:)`. Conforms to `Codable` for
  `@AppStorage`.
- `DesignSystem/DPTheme+Environment.swift` — a `@Environment(\.dpTheme)`
  key so any view can read the active theme without prop drilling.
- `@AppStorage("dp_theme") private var theme: DPTheme = .ember` in the root.
- Settings UI: "Appearance" section with theme picker (3 swatches +
  current theme name) and light/dark/system mode picker.
- Asset catalog colours: each palette gets `light` + `dark` variants;
  store as raw hex translated from oklch (see open Q2).

### Out
- Custom user-defined themes.
- High-contrast accessibility palette — separate plan if needed.
- Per-screen theme overrides.
- Theme transition animation on switch (use system default cross-fade).

## Implementation steps

1. **`DPTheme.swift`** — enum + computed colours; unit-tested via raw
   `UIColor` round-trip if oklch conversion is non-obvious.
2. **Environment key** — `@Entry var dpTheme: DPTheme = .ember`.
3. **Root app injection** — `drinkpulseApp` reads `@AppStorage` and
   passes via `.environment(\.dpTheme, theme)`.
4. **Settings UI** — segmented theme picker; saves to AppStorage; live
   preview swatch row.
5. **Migration of fixed-tint call sites**: any place that uses
   `.tint(.accentColor)` or `Color.accentColor` for *brand* meaning
   switches to `.tint(theme.primary)`. Semantic accents (`.dpTeal`,
   `.dpAmber`, `.dpRed`, `.dpPurple`, `.dpGreen`) stay where they
   carry meaning (e.g. risk thresholds).
6. **Assets** — add `RiskLow / RiskModerate / RiskHigh` only — these are
   theme-independent. Theme colours live in code; oklch is converted to
   sRGB once with a helper and constants are committed inline.

## Files

| File | Action |
|------|--------|
| `drinkpulse/DesignSystem/DPTheme.swift` | Create |
| `drinkpulse/DesignSystem/DPTheme+Environment.swift` | Create |
| `drinkpulse/Features/Settings/SettingsView.swift` | Modify |
| `drinkpulse/drinkpulseApp.swift` | Modify |
| `drinkpulseTests/DPThemeTests.swift` | Create |

## Open questions

- [ ] **Q1 — Tab-bar background**: per-theme tinted (matches design) or
  always system `Material.bar`?
  - A) Per-theme tinted (default — matches design)
  - B) System bar (more "iOS-like", less brand)

- [ ] **Q2 — oklch source-of-truth**: keep oklch values in source code and
  convert at build (helper struct) or pre-convert and ship sRGB
  hex constants?
  - A) sRGB hex constants (default — simplest, no runtime cost)
  - B) oklch source + conversion helper (easier to tweak later)

- [ ] **Q3 — Light/dark/system mode override location**: in Settings or
  in the Tweaks-style debug menu?
  - A) Settings → Appearance → Mode picker (default)

- [ ] **Q4 — Theme defaults**: Ember matches a "warm wellness" tone but
  could be perceived as alcohol-themed. Acceptable, or default to Forest
  for a neutral health-app feel?
  - A) Ember (matches design default)
  - B) Forest (more neutral)

## Tests required

- `DPTheme.primary` returns distinct colours per case.
- `DPTheme(rawValue: invalid)` → `nil` (Codable safety).
- AppStorage round-trip preserves selection across cold-start.

## Future links

- [[plan-0007]] — provides `cardTint` consumers (GlassCard).
- [[plan-0011]] — arc colour falls back to theme primary when risk is
  "safe"/low (avoids green-on-green clash in Forest).
