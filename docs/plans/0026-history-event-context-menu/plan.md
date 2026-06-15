# 0026 — History event context menu: Duplicate + Delete

**Status**: in-progress
**Size**: small
**Created**: 2026-06-15
**Frozen**: 2026-06-15

## Summary

Add a long-press context menu to consumption-event rows in History (both the
list segment and the calendar day-detail) offering two actions: **Duplicate**
and **Delete**. Duplicate creates a new `ConsumptionEvent` copying every field
of the source, with only `timestamp` reset to `.now`, and saves it immediately
(no edit sheet). The duplicate therefore lands at the top of the "Today" section
as instant visual confirmation. Delete mirrors the existing swipe-to-delete.

## Context

Triggered by user request: in the history/list views, long-pressing an event
should let you delete or duplicate it. A duplicate is for quickly re-logging the
same drink ("I had that again"). Decided (user-confirmed, 2026-06-15):

- **Save immediately** on duplicate — do NOT open Add/Edit. The whole point is a
  fast re-log; the new row is already tappable for edits if needed.
- **Scope both** the list (`HistoryListQueryView`) and the calendar day-detail
  (`HistoryCalendarDayDetail`).

Constraints: no schema change (all fields already exist on `ConsumptionEvent`);
mutations happen in the view via `@Environment(\.modelContext)` per the
no-repository architecture; the domain helper must be unit-tested to 100%.

## Scope

### In
- `ConsumptionEvent.duplicated(timestamp:)` domain helper (copies all fields,
  resets timestamp).
- A reusable `View.eventContextMenu(for:in:)` modifier with Duplicate + Delete.
- Wire it into `HistoryListQueryView` rows and `HistoryCalendarDayDetail` rows.
- Localization keys for the two action labels.
- Domain tests for `duplicated`.

### Out
- No leading/duplicate swipe action (long-press only, as requested).
- No edit-sheet-on-duplicate path.
- No change to existing trailing swipe-to-delete on the list.
- No undo/toast affordance (the duplicate appearing under "Today" is the
  confirmation; delete keeps current behaviour).

## Implementation steps

1. Add `ConsumptionEvent.duplicated(timestamp: Date = .now) -> ConsumptionEvent`
   (extension, near the model). Copies `volumeMl, abv, quantity, name, category,
   icon, template, customName, notes, price`; sets `timestamp`. Returns a new,
   unmanaged instance (caller inserts it).
2. Add `History/Components/EventContextMenu.swift` — a `View` extension
   `eventContextMenu(for:in:)` that renders a `.contextMenu` with Duplicate
   (`context.insert(event.duplicated())`) and a destructive Delete
   (`context.delete(event)`). Uses `String(localized:)` labels + SF Symbols
   (`plus.square.on.square`, `trash`).
3. Apply `.eventContextMenu(for: event, in: modelContext)` to the row button in
   `HistoryListQueryView` (keep existing trailing swipe-delete as-is).
4. Add `@Environment(\.modelContext)` to `HistoryCalendarDayDetail` and apply the
   same modifier to its row button.
5. Add localization keys `history.action.duplicate` / `history.action.delete`
   (reuse an existing delete key if one is already defined — verify first).
6. Add domain tests for `duplicated`.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Domain/ConsumptionEvent.swift` (or `+Duplicate.swift` if it pushes the file near 300) | Modify / Create |
| `drinkpulse/Features/History/Components/EventContextMenu.swift` | Create |
| `drinkpulse/Features/History/HistoryListQueryView.swift` | Modify |
| `drinkpulse/Features/History/Components/HistoryCalendarDayDetail.swift` | Modify |
| `drinkpulse/.../Localizable.xcstrings` (string catalog) | Modify |
| `drinkpulseTests/...ConsumptionEvent...Tests.swift` | Modify / Create |

## Open questions

- [x] Duplicate behaviour → save immediately (no edit sheet). **Resolved.**
- [x] Scope → list + calendar detail. **Resolved.**
- [ ] Keep `template` reference on the duplicate? Default: **yes** (copy the link;
      a duplicate is the same drink). Confirm during execution if it causes any
      template-deletion edge case.

## Tests required

- `duplicated` copies every value field (volume, abv, quantity, name, category,
  icon, customName, notes, price) and the template reference.
- `duplicated` sets a fresh timestamp (`.now` by default; explicit override
  respected).
- `duplicated` returns a distinct instance (not the same object).
- Domain layer stays at 100% coverage.
