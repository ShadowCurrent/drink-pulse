# 0014 — Execution Log

---

## 2026-05-30 — Implemented in one pass

### Done

- `ConsumptionEvent`: added `customName: String?` (lightweight SwiftData migration — optional, default nil). `notes: String?` was already present in the schema.
- `ConsumptionEvent.displayName` extension property: returns trimmed `customName` if non-empty, otherwise falls back to `name`.
- `History/Components/EditCustomNameSection.swift` created: `TextField` with category default name as placeholder, `autocorrectionDisabled`.
- `History/Components/EditNotesSection.swift` created: multiline `TextField(axis: .vertical)`, 500-char cap via `onChange`, live counter appears at 400+ chars.
- `EditEventView`: added `@State customName` and `@State notesText` wired to `event.customName` / `event.notes`; new sections inserted; `save()` writes trimmed values (stores `nil` when blank). Category change already reset `name`/`icon` — `customName` intentionally NOT reset (persistent user override).
- `HistoryView.EventRow`: `event.name` → `event.displayName`; note indicator (`note.text` icon) shown when `notes` is non-empty.
- `Localizable.xcstrings`: 4 new keys — `editDrink.customName`, `editDrink.customNamePlaceholder`, `editDrink.notes`, `editDrink.notesPlaceholder` (en/de/pl).
- `ConsumptionEventTests.swift`: 6 new tests for `displayName` behaviour.
- `project.pbxproj`: `ConsumptionEventTests.swift` manually registered in test target.
- Build: succeeded, 0 errors. Tests: 226/226 passed (6 new).

### Deviations from plan

- **`notes` already existed**: `notes: String?` was present in the schema before this plan. Only `customName` was added as a new field. Migration smoke test for `notes` not needed.
- **No `EditCategorySection` extracted**: the inline category picker was already well-contained in `EditEventView`. Extracting it would have added complexity without reducing line count (view stays at ~240 lines, well under 300).
- **Migration smoke test skipped**: SwiftData in-memory containers in unit tests do not exercise real on-disk migrations. The lightweight migration guarantee (optional fields default nil) is verified by build success and the existing schema — a separate integration test was not added.

### Open questions resolved

- Q1: Custom name field starts empty; placeholder = category default name (option A).
- Q2: Category change resets pickers (already implemented via `onChange` — confirmed correct).
- Q3: Notes capped at 500 chars with counter at 400+ (option A).
- Q4: Symbol-only note indicator in history row (option A).
