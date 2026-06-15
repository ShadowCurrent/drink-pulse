# 0027 — Retrospective

**Completed**: 2026-06-15

## What shipped

Settings now follows the app's iOS 26 Liquid Glass language (`ScrollView` of
`dpGlassCard` sections over the themed tint) instead of an opaque
`.insetGrouped` List. Three concrete fixes alongside the restyle:

- **Privacy/perf (B1/B2):** export file is no longer written to tmp on every
  Settings appearance. `BackupExport: Transferable` defers the JSON encode +
  temp-file write into the share-sheet transfer closure — full user history
  only touches disk when the user actually exports.
- **Maintainability (B3):** shared `AppStorageKeys` constants replace duplicated
  `dp_theme` / `dp_color_scheme` / `dp_onboarding_done` literals.
- **Accessibility (L2):** theme swatch checkmark gained a dark scrim so it meets
  contrast on light gradient ends.

## What went well

- `dpGlassCard` already gated on iOS 26 with a material fallback, so the restyle
  was pure composition — no new glass plumbing.
- `Transferable.FileRepresentation` gave true lazy export with zero UIKit, so the
  privacy fix needed no `UIActivityViewController` wrapper.
- Keeping the `DataExporter` API intact meant no existing test churn.

## What to watch

- `DataExporter.contentSignature` is now dead in production (kept only because
  tests cover it). If a future change removes those tests, drop the function too.
- L3 (GuidelinePickerSheet glass) deferred — revisit only if the plain sheet list
  looks out of place against the restyled Settings.

## Tests

+5 `BackupExport` tests (fileName, snapshot, encoded ×2, writeTempFile). Full
suite green, build clean (zero warnings), no file > 300 lines.
