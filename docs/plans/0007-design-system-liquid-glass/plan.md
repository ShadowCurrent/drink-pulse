# 0007 — Design system: iOS 26 Liquid Glass primitives

**Status**: completed
**Frozen**: 2026-05-19
**Size**: medium
**Created**: 2026-05-19

## Summary

Introduce a small set of reusable SwiftUI primitives that give every card,
sheet, and badge in DrinkPulse the iOS 26 "Liquid Glass" look: blur +
saturation backdrop, a subtle specular highlight on the top edge, layered
inset borders, and consistent corner radii. The work is structural — once
in place, all feature surfaces (Dashboard, History, Insights, Settings,
sheets) inherit the look by switching from `.background(Color(.secondarySystemBackground))`
to `.dpGlassCard()`.

## Context

The Claude Design handoff (2026-05-19) is built around a `GlassCard`
component. The current SwiftUI app uses plain
`Color(.secondarySystemBackground)` panels which look flat next to iOS 26
system surfaces (Maps cards, Photos info, Music NowPlaying). We want the
upgrade without adopting any third-party library.

iOS 26 ships a `Glass.regular` material and a `glassEffect()` modifier as
first-class API. The plan uses these where available and falls back to a
hand-rolled equivalent for parity in Previews and snapshot tests.

## Scope

### In
- `DesignSystem/DPGlass.swift` — `dpGlassCard()` view modifier:
  - Corner radius: 22 (cards), 16 (chips), 28 (sheets top corners).
  - `Material.regular` background with `.opacity(0.72)` tint of theme card.
  - Specular highlight: top-aligned radial overlay (`white.opacity(0.35)` in
    light, `0.06` in dark) fading to transparent.
  - Inset border via `.overlay { RoundedRectangle().stroke(...) }` — 0.5pt
    line with `.white.opacity(0.75)` (light) / `0.12` (dark) and an inner
    1pt highlight stroke.
  - Outer shadow: `.shadow(color: .black.opacity(0.06), radius: 16, y: 2)`
    in light; `.opacity(0.30), radius: 24, y: 4` in dark.
- `DesignSystem/DPSemanticColors.swift` — semantic colour tokens for
  risk-low / risk-moderate / risk-high (replaces ad-hoc use of `dpGreen`,
  `dpAmber`, `dpRed` where the *meaning* is "risk"). Existing accent
  tokens stay.
- `DesignSystem/DPLargeTitle.swift` — `dpLargeTitle()` view modifier
  rendering a 28pt bold title with -0.6 letter-spacing and proper top
  inset (above status bar) — matches design.
- `DesignSystem/DPArcProgress.swift` — reusable arc gauge (240° sweep,
  configurable size/strokeWidth). Used by [[plan-0011]].
- Update one screen (Settings, lowest risk) end-to-end as the pilot
  adoption; the rest of the migration is broken out into the dependent
  plans.

### Out
- Theme palettes Ember/Forest/Iris — see [[plan-0008]].
- Floating tab bar — see [[plan-0010]].
- Per-screen application of the glass card to Dashboard, History,
  Insights, Sheets — those land in their own plans.

## Implementation steps

1. **`DPGlass.swift`** — create the modifier; expose three sizes via
   parameter (`small`, `regular`, `sheetTop`). Add a `cornerRadius:
   CGFloat = 22` default.
2. **`DPSemanticColors.swift`** — `Color.dpRiskLow / .dpRiskModerate /
   .dpRiskHigh` adaptive to light/dark via Asset Catalog (preferred) or
   inline `Color(light:dark:)` initialisers.
3. **`DPLargeTitle.swift`** — a `ViewModifier` rather than a wrapper
   `View` so it composes with `.navigationBarHidden(true)` headers.
4. **`DPArcProgress.swift`** — pure SwiftUI `Path` drawing two arcs;
   `pct: Double`, `color: Color`, `size: CGFloat = 100`, `strokeWidth:
   CGFloat = 9`. Accessibility: announces "{pct}% of daily limit".
5. **Pilot — Settings**: refactor `SettingsView` to use `dpGlassCard()`
   on each `Form` section (or replace `Form` with `ScrollView` + custom
   cards — TBD in Q1). Confirm visual parity against the prototype.
6. **Tests** — none required (visual); add `#Preview` blocks covering
   light + dark.

## Files

| File | Action |
|------|--------|
| `drinkpulse/DesignSystem/DPGlass.swift` | Create |
| `drinkpulse/DesignSystem/DPSemanticColors.swift` | Create |
| `drinkpulse/DesignSystem/DPLargeTitle.swift` | Create |
| `drinkpulse/DesignSystem/DPArcProgress.swift` | Create |
| `drinkpulse/Features/Settings/SettingsView.swift` | Modify (pilot) |
| `drinkpulse/Assets.xcassets/RiskLow.colorset/` | Create |
| `drinkpulse/Assets.xcassets/RiskModerate.colorset/` | Create |
| `drinkpulse/Assets.xcassets/RiskHigh.colorset/` | Create |

## Open questions

- [ ] **Q1 — Form vs custom cards in Settings**: keep `Form` (iOS-standard,
  free Dynamic Type) or hand-roll with `ScrollView`?
  - A) Custom — matches the design exactly (default if no answer)
  - B) Form — less work, slightly off-design

- [ ] **Q2 — Adopt iOS 26 `glassEffect()` API**: since deployment target is
  iOS 18, do we conditionally use `glassEffect()` on iOS 26+ and fall back
  to the hand-rolled material on iOS 18?
  - A) Yes — `if #available(iOS 26, *)` (default)
  - B) Use hand-rolled material everywhere for visual consistency
       across versions

- [ ] **Q3 — Corner radius scale**: 22 / 16 / 28 (from design) or align to
  Apple's HIG default of 24 / 14 / 20?
  - A) Design values (default — matches prototype)
  - B) HIG values

## Tests required

- Visual via Previews. No unit tests.
- Confirm `dpArcProgress` accessibility label format with VoiceOver.

## Future links

- [[plan-0008]] — theme palettes provide the tinted glass body colour.
- [[plan-0011]] — uses `dpArcProgress` directly.
- [[plan-0010]] — floating tab bar uses the same glass material.
