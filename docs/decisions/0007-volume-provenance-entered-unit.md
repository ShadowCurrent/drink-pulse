# 0007 — Volume provenance: store the entered unit on each event

**Status**: Accepted
**Date**: 2026-06-23
**Plan**: [plan-0031](../plans/0031-volume-serving-expansion-and-provenance/)
**Related**: [plan-0030](../plans/0030-volume-unit-display/), [ADR-0005](0005-density-by-display-unit.md), [ADR-0006](0006-density-by-mode-and-guideline.md)

## Context

Plan-0030 made `UserProfile.unitSystem` drive how serving volumes are
*displayed* and which serving presets are *offered* for new drinks. The
canonical stored value stays `ConsumptionEvent.volumeMl` (exact, frozen,
snapshotted); grams, calories, guideline %, risk, and (future) BAC are all
derived from `volumeMl` × density exactly as before — ADR-0005 / ADR-0006 are
untouched. The "unit of truth is grams" rule and the canonical-ml-is-truth rule
both still hold.

That design left one display defect. A serving's friendly **name** (e.g.
"Pint", "US can", "Bottle") is not stored — it is re-derived at render time by
looking the event's `volumeMl` up in the *current* preset table under the
*current* profile `unitSystem`. Two consequences follow:

1. **The name flips when the user switches unit mode.** A drink logged as a
   500 ml "Bottle" in metric reads as "16.9 fl oz" (or whatever the US/imperial
   table calls 500 ml) the moment the user toggles to US mode — even though the
   logged drink never changed.
2. **The name shifts if the preset table is edited.** Renaming a serving, or
   adding/removing one, retroactively changes how a past event is named.

The event *data* is safe in all cases (the event snapshots its own `volumeMl`;
grams never move). Only the human-readable serving name is unstable. We needed a
way to make the displayed name (a) stable across unit-mode switches and (b) still
correctable later (rename a typo, fix a label) without rewriting history — for a
single-user, offline-first app, with minimal model surface and no store wipe.

All calculation-core behaviour is unchanged by this decision; the owner's
hand-verification requirement on calculations does not apply here because no
calculation is touched. This ADR is purely about display/naming provenance.

## Decision

Add a new **optional** stored field to `ConsumptionEvent`:

```swift
var enteredUnit: UnitSystem?   // the unit system the user logged this drink in
```

- `volumeMl` remains the **canonical, frozen, snapshotted truth.** All
  grams/calorie/guideline/risk/BAC math derives from `volumeMl` × density,
  exactly as today. Nothing in the calculation path changes.
- `enteredUnit` records **a historical fact** — the `UserProfile.unitSystem`
  in effect when the event was logged. It is written once at log time and
  **never edited afterward** (not even when the user later switches unit mode,
  and not by an edit that leaves the volume unchanged).
- The displayed serving **name is derived LIVE** from the preset table: look up
  the `VolumeOption` by `(category, volumeMl)` and render `name(in: enteredUnit)`.
  The name is **not** frozen as a string on the event, **not** a stable slug,
  and there is **no** retired-preset registry.

Resolution order for the displayed name:

1. If `enteredUnit` is set and a preset option matches `(category, volumeMl)`,
   render `option.name(in: enteredUnit)`.
2. If `enteredUnit` is `nil` (legacy event logged before this field existed),
   fall back to the *current* profile `unitSystem` for the lookup.
3. If no preset option matches the canonical ml at all, fall back to
   `unitSystem.formatVolume(volumeMl)` (e.g. "16.9 fl oz") — a graceful,
   data-safe degradation.

This makes the name **stable across unit-mode switches** (it is resolved through
the *logged* unit, not the *current* profile) while keeping it **correctable**
(the name lives in the editable preset table, so renames and typo fixes
propagate to all matching past events).

### Migration & format

- **Additive SwiftData migration, no store wipe.** `enteredUnit` is optional and
  defaults `nil` for every legacy event. Adding an optional property is a
  lightweight migration.
- **Export/import gains one optional key**, back-compatible: older backups omit
  it (decodes to `nil`); the importer tolerates its absence.

## Consequences

### Positive

- The serving name no longer flips when the user toggles unit mode — it reflects
  how the drink was actually logged.
- Renames and typo fixes to presets still propagate to history, because the name
  is looked up live (never frozen on the event).
- No registry to maintain; the model gains exactly one optional field.
- Calculations, grams-truth, and the canonical-ml rule are entirely untouched —
  this is additive provenance for *display only*.
- Migration is additive and reversible; export stays backward-compatible.

### Negative / trade-offs

- **Known limitation — canonical-ml renumbering breaks the name lookup.** If a
  preset's *canonical ml* is later changed (e.g. a "Bottle" moves from 500 ml to
  502 ml), old events stored at the old ml no longer match `(category, volumeMl)`
  and fall through to `formatVolume(volumeMl)` (e.g. "16.9 fl oz"). This is
  **accepted**: the event's DATA and grams never break (the event snapshots its
  own ml); only the *friendly name* degrades gracefully to a formatted volume.
  Changing a preset's canonical ml is rare and is itself a deliberate act.
- Legacy events (`enteredUnit == nil`) still resolve their name through the
  current profile unit, so their name can still flip on a unit switch. This is an
  inherent property of having no provenance for pre-existing data; it is not made
  worse than today.

### Alternatives considered

- **A — current (ml only).** Event data is already safe (snapshotted ml), but the
  serving name is re-derived from the *current* profile unit, so a logged drink's
  name flips on a unit-mode switch and shifts when the preset table is edited.
  **Rejected:** the name is unstable.
- **C-freeze-string (store the rendered descriptor on the event).** Stable across
  unit switches, but you can never fix a typo or rename a serving later, because
  you cannot tell which past events came from which preset. **Rejected by the
  owner for exactly this reason.**
- **Stable slug id on the event.** A slug would also let the canonical ml be
  changed later while keeping the name lookup intact. Explicitly **not chosen**
  (the owner said to ignore the slug) — keep the model minimal; the ml-renumber
  case is rare enough to accept graceful degradation instead.
- **Retired-preset table / registry.** A registry mapping retired presets to past
  events. **Rejected** as an unnecessary maintenance burden for a single-user,
  offline app.
- **C′ (chosen).** Store `volumeMl` (frozen truth) + `enteredUnit` (a historical
  fact, never edited). Name = look up the option by `(category, volumeMl)` and
  render `name(in: enteredUnit)`. Renames/typo-fixes propagate (name lives in the
  editable preset table); the name is stable across unit-mode switches (resolved
  via the logged unit, not the current profile); the only degradation is the
  rare canonical-ml-renumber case, which falls back to `formatVolume` without ever
  touching the event's data.
