# 0002 — Lower Deployment Target to iOS 17

**Status**: completed
**Size**: small
**Created**: 2026-05-18
**Frozen**: 2026-05-18

## Summary

Lower `IPHONEOS_DEPLOYMENT_TARGET` from `26.5` to `17.0` across all targets
and fix the one iOS 18+ API in use (`Tab { }` in `ContentView`). No other
code changes required — the entire stack (SwiftData, `@Observable`, Swift
Charts, `NavigationStack`) supports iOS 17.

## Context

The app currently targets iOS 26 exclusively. Supporting iOS 17+ covers
2–3 major versions back and captures users who haven't upgraded yet, without
any architectural compromise. The only iOS 18-specific API in the codebase is
the `Tab(title:systemImage:content:)` initialiser in `ContentView.swift`;
replacing it with the universally-supported `.tabItem { Label(...) }` pattern
is a mechanical change.

## Scope

### In
- Deployment target: `26.5` → `17.0` in all four build configurations
  (app Debug, app Release, tests Debug, tests Release)
- `ContentView.swift`: `Tab { }` → `.tabItem { }` (iOS 16+ API, no fallback needed)
- Documentation: CLAUDE.md, product.md, architecture.md

### Out
- Any runtime `#available` checks — not needed; all used APIs are iOS 17+
- UI changes
- Logic changes
- New tests — this is a configuration change; existing 36 tests verify nothing broke

## Implementation steps

1. **`project.pbxproj`** — replace all four occurrences of
   `IPHONEOS_DEPLOYMENT_TARGET = 26.5` with `IPHONEOS_DEPLOYMENT_TARGET = 17.0`.

2. **`ContentView.swift`** — rewrite `TabView` body using `.tabItem { Label(...) }`
   (the old syntax works iOS 16+; no `#available` wrapper needed).

3. **Documentation** — update the three files that state "iOS 26":
   - `CLAUDE.md` — "Minimum deployment: iOS 26" → "iOS 17"
   - `docs/product.md` — "Minimum deployment: iOS 26" → "iOS 17"
   - `docs/architecture.md` — Tab API note: remove "iOS 18+" qualifier
     (new syntax no longer used)

4. **Build + test** — `xcodebuild build` then `xcodebuild test`; confirm
   zero warnings and all 36 tests green.

5. **Checklist** — DEVLOG entry, INDEX.md status → completed.

## Files

| File | Action |
|------|--------|
| `drinkpulse.xcodeproj/project.pbxproj` | Modify (4 occurrences) |
| `drinkpulse/ContentView.swift` | Modify |
| `CLAUDE.md` | Modify |
| `docs/product.md` | Modify |
| `docs/architecture.md` | Modify |
| `docs/plans/INDEX.md` | Update status |
| `docs/DEVLOG.md` | Append |

## Open questions

None.

## Tests required

No new tests. Run existing suite to confirm no regressions.
