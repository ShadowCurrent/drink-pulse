# 0021 — Edit screen: delete + type-picker navigation, and swipe-to-delete fix

**Status**: completed
**Size**: medium
**Created**: 2026-06-01
**Frozen**: 2026-06-01
**Completed**: 2026-06-01

## Summary

Three related improvements to the History edit/delete experience:

1. **Delete from the edit screen** — `EditEventView` can currently only
   save. Add a clear, safe destructive delete action (with confirmation)
   so a user can remove an entry while editing it.
2. **Tappable drink-type field in the edit screen** — replace the inline
   category `Picker` (which lists every category in a long inline list)
   with a single tappable row showing the current type (icon + name).
   Tapping pushes to a drink-type selection grid — the same picking
   experience as the Add-Drink flow — and the choice updates the entry's
   category.
3. **Fix the swipe-to-delete bug in the list** — swiping a row in the
   History list briefly hangs the UI, and the expanding red delete button
   does not match the row's height. Diagnose and fix both symptoms.

## Context

The user reported all three in chat (2026-06-01) [translated from Polish]:

> "the edit screen should have the ability to delete a drink — how do I
> do it so it looks good? also, in the edit screen, instead of a list of
> drinks I should have a field that is tappable and navigates to the
> drink-type selection view, similar to when adding a drink. next, I have
> a bug where, in the list view, when I swipe to delete, the view hangs
> for a moment and the expanding red delete-button preview is not the
> same height as the event."

Current state (verified in code):

- `EditEventView.swift` (237 lines) is presented as a `.sheet(item:)`
  from `HistoryView`, wraps its content in its own `NavigationStack`,
  and has **no `@Environment(\.modelContext)`** and **no delete**.
  Category selection is an inline `Picker(...).pickerStyle(.inline)`
  enumerating `DrinkCategory.allCases` (the "drink list" the user
  wants gone). An existing `onChange(of: category)` already resets
  `icon` / `name` / `volumeIndex` / `abvIndex` to the new category's
  preset — so a replacement control only needs to write `category`.
- The Add-Drink flow uses `DrinkTypeGridView` (a `LazyVGrid` of
  `DrinkTypeTile`) → `NavigationLink(value: preset)` →
  `DrinkDetailInputView`. `DrinkTypeTile` is already a standalone,
  reusable view.
- `HistoryListQueryView.swift` renders each row as
  `Button { onEditEvent } label: { EventRow().contentShape(Rectangle()) }`
  with `.buttonStyle(.plain)`, and deletion via `.onDelete`. The section
  data comes from `vm.groupedByDay(events)`, **recomputed on every body
  evaluation** over the full windowed query (≥90 days of events).

### Likely cause of the swipe bug (to confirm during execution)

- **Hang:** `groupedByDay` rebuilds a `Dictionary(grouping:)` + sorts on
  the main thread on every render pass. During a swipe the row animates
  and `@Query` republishes on delete, forcing repeated synchronous
  re-grouping of the whole window mid-gesture → dropped frames.
- **Red-button height mismatch:** the row content is a `.plain` `Button`
  whose label combines an accessibility element; the trailing swipe
  background is measured against a row whose intrinsic height resolves
  differently during the swipe animation than at rest. Moving to an
  explicit `.swipeActions` destructive button (instead of `.onDelete`)
  and stabilizing the row's tap target is the standard fix.

This is a UI-correctness + UX task, not a domain or calculation change.
No `ConsumptionEvent` schema change (deletion uses the existing
`modelContext.delete`). No BAC/guideline logic touched.

## Scope

### In

- **EditEventView — delete action** *(decided: toolbar trash + confirm)*
  - Add `@Environment(\.modelContext)`.
  - Add a destructive `trash` `Button` to the toolbar, in a
    `.topBarLeading`/`.destructiveAction`-style placement so it reads
    clearly as destructive and does not crowd Save/Cancel.
  - Tapping shows a `.confirmationDialog` (health data → confirm before
    destroying). Confirm → `modelContext.delete(event)` then `dismiss()`.
- **EditEventView — tappable type field**
  - Remove the inline category `Picker`.
  - Add a `NavigationLink` row using `LabeledContent` that shows the
    current preset's icon + name (and a chevron via the link).
  - Destination: a reusable drink-type selection grid. Selecting a type
    sets `category` (the existing `onChange` cascade does the rest) and
    pops back to the form.
  - Keep the base-`name` `TextField` (it stays editable; only the
    category list is replaced).
- **Reusable type-selection grid** *(decided: shared component)*
  - Extract a shared `DrinkTypeGrid(onSelect:)` (columns + `ForEach` of
    `DrinkTypeTile`) used by both the Add flow and the Edit flow — no
    duplicated layout. The Add-Drink flow must remain visually and
    behaviourally identical; verify on simulator before/after.
- **HistoryListQueryView — swipe fix**
  - Replace `.onDelete` with an explicit
    `.swipeActions(edge: .trailing, allowsFullSwipe: true)` destructive
    `Button` per row, so height/animation are correct and index→event
    mapping is direct (no `IndexSet` offset math).
  - Memoize day-grouping: compute grouped sections once per `events`
    change (e.g. `@State` recomputed in `onChange(of: events)`) instead
    of every body pass, removing the mid-swipe synchronous re-grouping.
  - Re-verify the row tap-to-edit still works and the row's tap target
    is stable (keep `Button`/`.plain` or switch to
    `.contentShape` + `onTapGesture` — whichever resolves the height
    measurement cleanly).
- **Localization**: new `en` + `pl` strings (delete label, confirm
  title/message, "Change type" / type-field label).
- **Accessibility**: destructive button labelled; swipe action has an
  accessibility label; type-field row reads current type.

### Out

- Calendar day-detail (`HistoryCalendarDayDetail`) swipe-to-delete —
  it has no swipe action today (tap-to-edit only). Not in scope unless
  the grouping memoization naturally applies; do not add swipe there now.
- Any `ConsumptionEvent` schema change or migration.
- Changing the Add-Drink flow's behaviour/UX (only a possible internal
  extraction for reuse — must remain visually and behaviourally
  identical).
- BAC / guideline / calculation changes.
- Undo/restore-after-delete (toast with undo) — possible follow-up.

## Implementation steps

1. **Reusable type-selection grid.** Decide per Q3. Preferred: extract a
   `DrinkTypeGrid` view (columns + `ForEach` of `DrinkTypeTile`) taking an
   `onSelect: (DrinkTypePreset) -> Void`. Re-point `DrinkTypeGridView`
   (Add flow) at it with no behavioural change. Add an
   `EditDrinkTypeSelectionView` that highlights the current selection,
   calls `onSelect`, and pops via its own `dismiss()`.
2. **EditEventView — type field.** Remove the inline category `Picker`;
   add the `NavigationLink` → selection grid row showing current
   icon + name. On select, set `category`; rely on the existing
   `onChange(of: category)` cascade. Keep the name `TextField`.
3. **EditEventView — delete.** Add `modelContext`, the destructive
   `Section` button, the `confirmationDialog`, and `deleteEvent()`
   (`delete` + `dismiss`). Keep the file under 300 lines (extract the
   delete section to a small component if needed).
4. **HistoryListQueryView — swipe fix.** Swap `.onDelete` for explicit
   `.swipeActions` destructive button; memoize grouping via `@State` +
   `onChange(of: events)`; confirm tap-to-edit and row height. Manually
   verify on simulator/device that the hang is gone and the red button
   matches row height.
5. **Localization.** Add `en`/`pl` entries for all new strings.
6. **Tests.** See "Tests required". Add/extend unit tests for any pure
   helper extracted (e.g. nearest-preset mapping if pulled out), and a
   grouping-stability test if memoization adds a pure function. Verify
   coverage stays ≥90% overall and per-layer.
7. **End-of-task checklist.** Build (zero warnings), tests green,
   file-size find, living-docs audit (architecture/product likely
   unaffected; DEVLOG + roadmap + current-focus updated), execution.md
   + retrospective + INDEX status.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift` | Modify (use shared grid; no behaviour change) |
| `drinkpulse/Features/AddDrink/DrinkTypeGrid.swift` (or shared loc) | Create (shared tile grid) — *pending Q3* |
| `drinkpulse/Features/History/EditEventView.swift` | Modify (type field + delete; keep <300 lines) |
| `drinkpulse/Features/History/Components/EditDrinkTypeSelectionView.swift` | Create (edit-flow type picker, uses shared grid) |
| `drinkpulse/Features/History/HistoryListQueryView.swift` | Modify (swipeActions + memoized grouping) |
| `drinkpulse/<localization>.xcstrings` | Modify (new en/pl strings) |
| `drinkpulseTests/...` | Append (helpers / grouping if extracted) |

## Open questions

- [x] **Q1 — Delete confirmation.** RESOLVED → **Yes, confirmation
  dialog** before deleting (health data, irreversible, no undo this
  round).

- [x] **Q2 — Delete button placement/style.** RESOLVED → **Trash icon
  in the toolbar** (with confirmation), not a bottom-section button.

- [x] **Q3 — Reuse shape for the type grid.** RESOLVED → **Shared
  `DrinkTypeGrid` component** used by both Add and Edit; Add flow must
  stay visually/behaviourally identical.

- [ ] **Q4 — Type-selection screen title / current-selection cue.**
  Show the current type as selected/highlighted in the grid?
  - A) Yes — highlight current tile and use title "Change type" (default)
  - B) Plain grid, no highlight, title "Drink type"

- [ ] **Q5 — Undo after delete.** Offer an undo toast after deleting
  (list and/or edit screen)?
  - A) No — out of scope, file as follow-up (default)
  - B) Yes — add a brief undo affordance now

## Tests required

- **Pure helpers only** (views/persistence are excluded from coverage):
  - If the nearest-preset mapping currently inlined in
    `EditEventView.init` is extracted to a testable function during the
    type-field work, cover it (closest volume/count and nearest-ABV
    selection, boundary ABV 0.0/1.0).
  - If grouping memoization introduces a pure helper, assert
    `groupedByDay` ordering/stability is unchanged for representative
    inputs (already partly covered — extend if needed).
- **Regression guard:** a test documenting that deleting an event
  removes exactly that event from a `groupedByDay` result (drive via the
  VM helper with a mutated array, since the actual delete is a view-level
  `modelContext` mutation excluded from unit tests).
- Coverage must remain ≥90% overall and meet per-layer targets; no
  "TODO: add tests".

## Future links

- [[plan-0014]] — established `EditEventView` and the category-change
  cascade this plan reworks into a tappable field.
- [[plan-0013]] — History calendar/list; day-detail rows share `EventRow`
  and may later want the same swipe action.
- Undo-after-delete and DrinkControl-imported entries are unaffected.
