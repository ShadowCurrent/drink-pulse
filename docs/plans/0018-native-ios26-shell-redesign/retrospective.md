# Retrospective — Plan 0018

Completed: 2026-05-21

## What went well

- Scope was well-defined before starting: 12 files, all changes purely visual.
- No compilation surprises — `AppTab.addDrink` was only referenced in the two
  files we were rewriting; grep confirmed this upfront.
- `List + insetGrouped` conversion in SettingsView was straightforward. The
  flash bug root cause (explicit background + glassEffect rerender timing) was
  correctly diagnosed before writing a line of code.
- `AppearanceRows` (renamed from `AppearanceCard`) works cleanly inside a List
  Section — SwiftUI correctly expands the body's implicit Group into multiple rows.
- 127/127 tests passed with zero changes — confirmed all changes were pure UI
  with no testable logic involved.

## What was harder than expected

- SourceKit generated many false-positive "Cannot find type" errors throughout
  the session (every file edited triggered cascading diagnostics from other files
  analyzed in isolation). Learned to ignore these and rely on `BuildProject` MCP
  as the authoritative compilation check.

## Decisions made during execution

- `GuidelineAlertCard`: kept a `Color.dpRed.opacity(0.10)` overlay on top of
  `dpGlassCard()` rather than going fully transparent glass. The overlay preserves
  the visual urgency of the alert even when the card background is glass.
- `SettingsRow` padding strategy: removed horizontal padding only (keep vertical
  12pt); List default insets handle horizontal spacing. This avoids double-indentation
  without needing per-row `.listRowInsets()` calls in SettingsView.
- `AddDrinkButton` accessibility label reuses the existing `addDrink.title`
  localization key rather than introducing a new key.

## What would I do differently

- Nothing significant. The plan was accurate and the execution matched it closely.
