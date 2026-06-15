# 0027 — Execution journal

## 2026-06-15 — Kickoff & decisions

- Frozen plan; status → in-progress.
- **L1 decision: Option B** — `ScrollView` + `dpGlassCard` sections,
  mirroring Dashboard/Insights. Settings now floats glass section cards
  over the themed tint instead of an opaque `.insetGrouped` List.
- **B1/B2 lazy export decision:** keep `DataExporter` API intact (tests
  depend on `encode` / `writeTempFile` / `fileName` / `contentSignature`).
  Introduce `BackupExport: Transferable` (`FileRepresentation`,
  `.json`) so the temp file + JSON encode happen only when the user
  actually invokes the share sheet, not on every Settings appearance.
  Removed the eager `.task(id: contentSignature)` write from
  `DataSection`. `contentSignature` stays (still test-covered; no longer
  used in production — harmless util).
- **B3:** new `AppStorageKeys` enum; both `drinkpulseApp` and
  `AppearanceCard` reference shared constants.
- **L2:** theme swatch — added a dark scrim circle behind the white
  checkmark so it meets contrast on light gradient ends (e.g. Ember).

## 2026-06-15 — Implementation complete

Files:
- **New** `DesignSystem/AppStorageKeys.swift` (B3).
- **New** `Domain/DataTransfer/BackupExport.swift` — `Transferable`, lazy
  encode/write via `FileRepresentation`; `encoded()` + `writeTempFile()`
  extracted for testability (B1/B2).
- **New** `Features/Settings/Components/SettingsSection.swift` —
  `SettingsSection` (glass card) + `SettingsActionRow`.
- **Mod** `SettingsView.swift` — `List(.insetGrouped)` → `ScrollView` + glass
  sections; guideline row simplified; dropped `sectionHeader`/`typeSize` (L1).
- **Mod** `DataSection.swift` — glass section; lazy `ShareLink(item:)` with
  `BackupExport`; removed eager `.task` write + `exportURL` (B1/B2).
- **Mod** `AppearanceCard.swift` — shared keys (B3); swatch dark scrim (L2).
- **Mod** `SettingsRow.swift` — own vertical padding for card context.
- **Mod** `drinkpulseApp.swift`, `RootShellView.swift` — shared keys (B3).
- **Tests** `DataExportImportTests.swift` — +5 BackupExport tests.

Deviations from plan: none material. `DataExporter` API left fully intact
(tests depend on it); `contentSignature` retained though no longer called in
prod. L3 deferred (sheet already gets system glass; low value).

Gates: `xcodebuild build` clean (zero warnings); full test suite green
(`** TEST SUCCEEDED **`); no file > 300 lines (largest touched: DataSection 184).
Coverage: DataTransfer logic 100%; BackupExport 70.6% (remainder = declarative
`transferRepresentation`, excluded framework-adapter).

Status → completed.
