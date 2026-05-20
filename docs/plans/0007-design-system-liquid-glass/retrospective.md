# 0007 — Retrospective

**Completed**: 2026-05-20

## What was built

Four reusable DesignSystem primitives (`DPGlass`, `DPSemanticColors`, `DPLargeTitle`, `DPArcProgress`) plus a pilot adoption of the glass card on the Settings screen. All primitives sit in `drinkpulse/DesignSystem/` and are ready to be picked up by plans 0008, 0010, 0011, 0012, 0013.

## What went well

- The iOS 26 `#available` pattern worked cleanly — the glass modifier is a single call site that transparently picks native vs. fallback.
- Extracting `GuidelineChoice+Display.swift` to `Domain/` eliminated a duplicate private extension that had grown between SettingsView and GuidelineStep. A minor clean-up that pays forward.
- Visual QA caught a critical AX5 regression on the first render — `HStack` rows collapsed to character-by-character stacking at accessibility text sizes. Fixed with `SettingsRow<Content>` that switches to `VStack(alignment: .leading)` when `dynamicTypeSize.isAccessibilitySize`.

## What to improve

- **Open questions should be asked before implementation, not after.** The Q3 corner-radius answer came post-implementation and required a patch commit. For future plans with documented Q-items, pause and ask them before writing code.
- The `guidelineCard` needed a separate AX5 fix (inline `@Environment(\.dynamicTypeSize)` conditional) because it is a full-width button row rather than a `SettingsRow`. A future pass could unify all disclosure-style rows into a shared component if the pattern recurs.

## Stats

- 9 files created, 5 files modified.
- 583 insertions, 128 deletions.
- 73 tests, all green. Build clean.
- 3 commits: initial implementation, corner-radius correction, AX5 fix.
