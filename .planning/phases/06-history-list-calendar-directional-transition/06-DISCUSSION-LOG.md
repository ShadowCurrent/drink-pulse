# Phase 6: History List↔Calendar Directional Transition — Discussion Log

**Date:** 2026-07-31

This log is for human reference only (audits, retrospectives) — it is not
consumed by downstream agents. See `06-CONTEXT.md` for the canonical record.

## Areas discussed

### Transition mechanism
- **Options presented:** (1) Common container + `.transition` [recommended],
  (2) Snapshot-based crossfade, (3) `TabView(.page)` paging container.
- **Selection:** Common container + `.transition`.
- **Notes:** Chosen as the simplest native approach; recorded as primary with
  crossfade as an explicit fallback (see next area).

### Direction semantics
- **Options presented:** (1) Follow segment order [recommended] — List (left)
  → Calendar (right) slides leftward, reverse slides rightward, (2) Fixed
  direction independent of picker position.
- **Selection:** Follow segment order.

### Reduce Motion + empty-state handling
- **Options presented:** (1) Instant cut + empty state included in the same
  transition container [recommended], (2) Instant cut but empty state
  short-circuits (bypasses transition).
- **Selection:** Instant cut + empty state included.

### Fallback strategy if native transition misbehaves
- **Options presented:** (1) Try native slide first, fall back to crossfade
  only if verification finds bugs [recommended], (2) Commit to crossfade from
  the start given known research risk.
- **Selection:** Try native slide first, fall back if needed.

## Deferred ideas

None — discussion stayed within phase scope.

## Claude's discretion (not asked to user)

- Exact `@State` shape for tracking transition direction.
- Whether an explicit `.id(segment)` is needed to force transition identity.
- Whether `calendarNavHeader` sits inside or outside the sliding container.

---

*Phase: 6-History List↔Calendar Directional Transition*
*Log written: 2026-07-31*
