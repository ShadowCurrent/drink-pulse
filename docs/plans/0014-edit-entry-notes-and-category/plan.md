# 0014 — Edit entry: custom name, notes, category change

**Status**: draft
**Size**: medium
**Created**: 2026-05-19

## Summary

Extend the existing `EditEventView` so a user can:
- Override the auto-derived drink name with a custom one (e.g. "Some Super IPA")
- Add free-form notes to an entry (e.g. "Friday pub night with Anna")
- Change the *category* of an existing entry without deleting and re-adding it

Add two optional fields to `ConsumptionEvent`:
- `customName: String?`
- `notes: String?`

Both are user-facing optional. SwiftData lightweight migration.

## Context

The user explicitly requested all three changes in the Claude Design chat
(2026-05-19). The design's `EditEntrySheet` already mocks the layout:
category-chip row with "Change" pill, custom-name field, drum-roll pickers,
notes textarea, delete button.

The current `ConsumptionEvent` carries `volumeMl`, `abv`, `price`,
`templateId`, `categoryId` and a snapshot `name`/`icon`. We add the two
optional strings without disturbing existing fields.

## Scope

### In
- **Domain**:
  - Add `customName: String?` and `notes: String?` to `ConsumptionEvent`.
  - Add `displayName: String` computed property:
    `customName?.nonEmpty ?? name`.
  - All consumers (History rows, Edit sheet, Quick-Log re-log) switch
    to `displayName`.
- **EditEventView**:
  - Section: "Category" — tap shows a horizontal scroll of all drink
    categories; selection updates `categoryId`, `name`, `icon`, and
    resets `volumeMl` + `abv` to the new category's nearest preset
    (closest-index logic from the prototype).
  - Section: "Custom Name" — `TextField`, placeholder "e.g. Some Super IPA".
  - Section: "Notes" — `TextField(axis: .vertical)` with 3-line min.
  - Existing volume/ABV pickers retained.
- **History rows**: bold subtitle with `displayName` instead of `name`;
  show a tiny note icon when `notes != nil`.
- **SwiftData migration**: lightweight — both fields default to nil; no
  data loss.

### Out
- Photo attachment.
- Multi-language notes / autotagging.
- Bulk edit.
- Per-event date/time editing (display-only, matches current state).

## Implementation steps

1. **Schema** — add `customName: String?` and `notes: String?` to
   `ConsumptionEvent`. Confirm `Schema.Migration` is `lightweight` (it is
   for nullable additions). Run app once on simulator with seeded data
   to verify migration is silent.
2. **`displayName`** — extension property, fall back to `name` when blank.
3. **`EditEventView` refactor** — break into three section subviews:
   `CategorySection`, `CustomNameSection`, `NotesSection`. Keep pickers
   in `ServingSection`. View under 300 lines after split.
4. **Category change logic** — on change, write the new category's
   default `name` + `icon`, reset `volumeMl` / `abv` to closest preset
   values. Save remains a single button.
5. **History row** — use `event.displayName`. Add `SF Symbol "note.text"`
   trailing-icon when `event.notes?.isEmpty == false`.
6. **Tests**:
   - `ConsumptionEvent.displayName` returns `customName` when set; else
     `name`; trims whitespace; empty string falls back to `name`.
   - Migration unit test using an in-memory SwiftData container — seed
     pre-migration model, then re-open with the new schema (use a
     small `MigrationPlan` if needed).

## Files

| File | Action |
|------|--------|
| `drinkpulse/Domain/ConsumptionEvent.swift` | Modify (fields + ext) |
| `drinkpulse/Features/History/EditEventView.swift` | Modify (split + sections) |
| `drinkpulse/Features/History/Components/EditCategorySection.swift` | Create |
| `drinkpulse/Features/History/Components/EditCustomNameSection.swift` | Create |
| `drinkpulse/Features/History/Components/EditNotesSection.swift` | Create |
| `drinkpulse/Features/History/HistoryView.swift` | Modify (row uses displayName) |
| `drinkpulseTests/ConsumptionEventTests.swift` | Append |

## Open questions

- [ ] **Q1 — Default to current name** when opening edit: pre-fill
  `customName` with the category default (so user can clear), or leave
  empty (placeholder shows category)?
  - A) Leave empty + placeholder (default — explicit, easy to skip)
  - B) Pre-fill with current name (easier to tweak; harder to clear)

- [ ] **Q2 — Save behaviour on category change**: do we keep the old
  pickers visible until user re-touches them, or reset on change?
  - A) Reset to nearest preset on category change (default — matches design)

- [ ] **Q3 — Notes max length**: enforce a cap (e.g. 500 chars) to avoid
  pathological inputs?
  - A) Cap at 500 chars with a tiny counter shown below the field (default)
  - B) Uncapped

- [ ] **Q4 — Note indicator in list**: SF Symbol vs. ellipsis line that
  shows the first ~30 chars of the note?
  - A) Symbol only (default — keeps row height stable)
  - B) First line of note

## Tests required

- See implementation step 6.
- Migration smoke test: open store with v(N-1), expect v(N) to load
  without errors and existing events to have `nil` `customName` /
  `notes`.

## Future links

- [[plan-0013]] — calendar day detail rows show `displayName` and the
  notes indicator.
- AI-chat future feature: would write notes naturally (e.g. user says
  "I had a Tyskie at 9pm" — name "Tyskie" goes to `customName`,
  category resolves to beer).
