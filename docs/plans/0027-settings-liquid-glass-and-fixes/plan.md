# 0027 — Settings: Liquid Glass alignment + bug/privacy fixes

**Status**: completed
**Size**: medium
**Created**: 2026-06-15
**Frozen**: 2026-06-15

## Summary

The Settings tab is the only top-level screen that does not follow the
app's iOS 26 Liquid Glass design language. Every other tab (Dashboard,
Insights, History) is a `ScrollView` floating glass `dpGlassCard`
surfaces over the themed tint background; Settings is an opaque
`List(.insetGrouped)` that paints `systemGroupedBackground`, hiding the
tint and showing no glass at all. This plan brings Settings in line with
the rest of the app and fixes three concrete issues found while
auditing the screen: a privacy/perf problem with eager export-file
writing, and a contrast problem in the theme swatch selection state.

## Context

Audit of `Features/Settings/` on 2026-06-15. Compared against the glass
convention established in plan-0007 (DPGlass primitives) and plan-0018
(native iOS 26 shell + glass cards), which every other feature adopts
via `.dpGlassCard()`.

Reference facts:
- `DPGlassModifier` (`DesignSystem/DPGlass.swift`) already gates on
  `#available(iOS 26, *)` → `.glassEffect(.regular, …)` with an
  `ultraThinMaterial` fallback. Reuse it; do not hand-roll glass.
- `RootShellView` paints `theme.primary.opacity(0.04)` behind the
  `TabView`. Glass tabs let it show through; Settings' opaque list does
  not.

## Findings (what this plan addresses)

### Liquid Glass / visual consistency
- **L1 — Settings ignores Liquid Glass.** `SettingsView` uses
  `List` + `.listStyle(.insetGrouped)` (opaque grouped background, plain
  rows). No `dpGlassCard`, no tint passthrough. Visually disconnected
  from the rest of the app. *(primary)*
- **L2 — Theme swatch selection contrast.** `ThemeSwatch`
  (`AppearanceCard.swift`) draws a white stroke + white checkmark on the
  swatch gradient. On light gradient ends (e.g. Ember light) this falls
  below the 4.5:1 contrast bar required by CLAUDE.md accessibility rules.
- **L3 — `GuidelinePickerSheet` plain list.** Sheet uses a plain `List`
  with no glass treatment. Lower priority (system gives sheets glass
  chrome), include only if it falls out cheaply.

### Bugs / privacy / perf
- **B1 — Export file written eagerly to tmp (privacy).**
  `DataSection.task(id: contentSignature)` calls
  `DataExporter().writeTempFile(...)` on every appearance / content
  change, materializing the **full user history JSON** in
  `FileManager.default.temporaryDirectory` even when the user never taps
  Share. CLAUDE.md: export files "contain full user history — treat them
  as sensitive output, never auto-upload or cache them." Eager caching to
  tmp violates the spirit of that rule. Make the write lazy (on demand).
- **B2 — Full re-serialize on every Settings visit (perf).** Tied to B1:
  `contentSignature` hashes all events and the file is re-encoded on
  every content change. With a large imported DrinkControl history
  (thousands of events) this serializes the whole DB each time Settings
  appears. Fixing B1 (lazy write) resolves this too.
- **B3 — Duplicated AppStorage key literals.** `"dp_theme"` and
  `"dp_color_scheme"` string keys are hand-duplicated in
  `drinkpulseApp.swift` and `AppearanceCard.swift`. A typo in one place
  silently breaks the binding. Extract shared constants.

## Scope

### In
- Restyle Settings to the Liquid Glass language (L1) without losing the
  grouped-section IA, pickers, accessibility-size layouts, or the
  existing `SettingsRow` / `sectionHeader` behavior.
- Fix theme swatch selection contrast (L2).
- Make export-file generation lazy / on-demand (B1, B2).
- Extract shared AppStorage key constants (B3).
- Update tests + living docs as required.

### Out
- No domain/calculation changes (BAC, guidelines, units untouched).
- No change to import logic or the DrinkControl/JSON formats.
- No change to delete-all-data semantics (already correct: profile reset,
  not deletion — see `DataSection.deleteAllData`).
- No new settings entries or features.
- CloudKit (plan-0023) untouched.

## Implementation approach (L1 — to confirm in execution)

Two viable routes; **B is the recommendation**:

- **Option A — keep `List`, drop the opaque background.** Add
  `.scrollContentBackground(.hidden)` so the themed tint shows through,
  and lean on iOS 26's native list glass. Smallest diff, but rows still
  read as a system grouped list, not the app's card aesthetic.
- **Option B — `ScrollView` + `dpGlassCard` sections (recommended).**
  Mirror Dashboard/Insights: a `ScrollView` over the tint with each
  section wrapped in a `dpGlassCard()` surface and the existing
  `sectionHeader` above it. Matches the app; more work; must preserve
  `SettingsRow` accessibility-size (`VStack`) layouts, all pickers, the
  guideline button row, and the `DataSection` alerts/importers/ShareLink.

Decide A vs B in step 1 before building.

## Implementation steps

1. **Decide L1 approach (A vs B)** and capture the choice in
   `execution.md`. (Recommendation: B.)
2. **B3 — shared keys.** Add `AppStorageKeys` (or enum) for `dp_theme`,
   `dp_color_scheme`; use in both `drinkpulseApp` and `AppearanceCard`.
3. **B1/B2 — lazy export.** Stop writing the temp file in
   `.task(id:)`. Generate the file only when the user invokes export
   (e.g. build the `URL` on tap before presenting the share sheet, or
   gate the `ShareLink` behind an on-demand producer). Keep the file in
   tmp only for the share lifetime; confirm no eager write remains.
4. **L1 — restyle Settings** per step-1 decision. Preserve section IA,
   pickers, guideline row, DataSection, and accessibility-size layouts.
   Keep files under 300 lines (split components if needed).
5. **L2 — swatch contrast.** Give the selection stroke/checkmark a
   contrast-safe treatment on light swatches (e.g. dark inner ring or a
   contrasting border + shadow), keeping the existing a11y traits.
6. **L3 (optional)** — if cheap, give `GuidelinePickerSheet` consistent
   glass styling.
7. **Tests + docs + checklist.**

## Files

| File | Action |
|------|--------|
| `drinkpulse/Features/Settings/SettingsView.swift` | Modify (L1) |
| `drinkpulse/Features/Settings/Components/DataSection.swift` | Modify (B1/B2) |
| `drinkpulse/Features/Settings/Components/AppearanceCard.swift` | Modify (L2, B3) |
| `drinkpulse/Features/Settings/Components/GuidelinePickerSheet.swift` | Modify (L3, optional) |
| `drinkpulse/drinkpulseApp.swift` | Modify (B3) |
| `drinkpulse/DesignSystem/` (new keys file) | Create (B3) |
| `drinkpulse/Domain/DataTransfer/DataExporter.swift` | Possibly modify (B1 — only if API needs an on-demand entry point) |
| `docs/architecture.md`, `docs/DEVLOG.md`, roadmap/context | Modify (docs) |

## Open questions

- [ ] L1 approach: Option A (keep List, hide background) or Option B
      (ScrollView + dpGlassCard sections)? Recommendation: B.
- [ ] B1: is there any flow relying on the export `URL` existing before
      a tap (e.g. preview)? Confirm none before going lazy.

## Tests required

- `DataExporter`: existing encode/writeTempFile tests stay green; if a new
  on-demand entry point is added, cover it (file written, correct name,
  content matches `encode`).
- B3: no behavior change to assert directly; rely on build + a smoke test
  that theme/color-scheme persistence still round-trips if such a test
  exists.
- L1/L2: visual — Xcode Previews (light + dark, default + AX5). No unit
  tests for layout per CLAUDE.md.
- Full suite green, coverage ≥90% overall and per-layer; zero build
  warnings; no file >300 lines.

## Notes / non-findings (verified safe)

- Delete-all does **not** wipe the AddDrink grid: drink types come from
  the static `DrinkTypePreset.all`, not SwiftData. `DrinkTemplate`
  deletion only affects user-created templates. No bug.
- Color-scheme + theme AppStorage are correctly applied in
  `drinkpulseApp` (`preferredColorScheme`, `.environment(\.dpTheme)`).
- `.inline` nav title is consistent across all tabs — not a defect.
