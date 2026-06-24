# Retrospective — plan 0033: remove color themes, fixed Ember accent

Status: completed
Date: 2026-06-24
Size: medium (grew from the planned scope via in-flight UI fixes)

## Outcome

Shipped. The 3-colour theme system is gone; the app uses a single fixed Ember
accent sourced from the `AccentColor` asset, tab icons fill only under the Liquid
Glass selection, and Light/Dark/System mode is retained (relocated into the
Preferences card). Full suite green: 480 tests, 0 failures, app coverage 93.81%,
no file >300 lines, zero warnings.

## What went to plan

- Theme deletion was as contained as scoped: `DPTheme`, `DPTheme+Environment`,
  the `dp_theme` key, the swatch row, `DPThemeTests`, and the theme strings all
  came out cleanly. No domain code touched; coverage held.
- The tab `symbolVariants` approach worked first try and matched the owner's
  reference snippet.
- Phase split (Opus subagent for code, inline for tests/docs) kept the build
  green at each checkpoint.

## What didn't (and the fixes)

1. **Previews/canvas showed blue controls.** Root cause was pre-existing: the
   `AccentColor` asset was empty, so anything not under the runtime `.tint`
   (i.e. every preview) fell back to system blue. The theme swatches had masked
   it. Fix: populate the asset and make it the single source of truth; drop the
   redundant explicit tints. Lesson: for a fixed brand accent, the asset catalog
   — not a runtime `.tint` — is the correct single source, because it also feeds
   previews and `Color.accentColor`.

2. **Appearance row collapsed into the menu bubble on tap.** An iOS 26 `.menu`
   morph anchored to the enclosing `dpGlassCard` when that card was a single
   row (card bounds ≈ picker). Two failed attempts (`.fixedSize()`, then a
   segmented picker the owner rejected) preceded the accepted fix: **remove
   single-row menu cards** by folding the mode row into the multi-row
   Preferences card. Lesson: in a glass-card layout, a `.menu` control wants a
   multi-row host; a lone interactive row is a morph hazard.

## Process notes

- Verification ran without computer-use (owner declined it): temporary
  `selectedTab = .settings` + `simctl` screenshots, reverted each time. Worked,
  but static screenshots can't show a tap-time morph — those fixes needed the
  owner to tap-verify, adding round-trips.
- The frozen plan deviated twice (asset-as-source; Settings regroup); both are
  recorded in `execution.md` per the immutability rule.

## Follow-ups

- Orphan `dp_theme` UserDefaults key left in place (harmless). Optional one-shot
  `removeObject` deferred by decision.
- `AppearanceCard.swift` now holds a single `AppearanceModeRow` — candidate for a
  rename/relocation if Settings components get tidied later.
