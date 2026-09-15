---
phase: 07-swiftui-list-performance-gesture-audit
plan: 01
subsystem: History (SwiftUI list rows + destructive gestures)
tags: [swiftui, foreach-identity, swiftdata, destructive-action, confirmation-dialog, uitest]
status: complete

requires:
  - ConsumptionEvent.uuid (plan-0023 stable identity)
  - EditEventView + DeleteConfirmationPopover (the confirmation posture being mirrored)
  - "-dp_uitest YES seeded fixture (single Today 500 ml 5% beer)"
provides:
  - EventContextMenuModifier (ViewModifier gating the destructive delete)
  - "String Catalog keys history.row.deleteConfirm.title / .message"
  - "accessibility identifier confirmContextDeleteButton"
  - "Owner decisions D-01..D-05 (read by plans 07-03, 07-04, 07-05)"
affects:
  - drinkpulse/Features/History/Components/HistoryDaySectionCard.swift
  - drinkpulse/Features/History/Components/HistoryCalendarDayDetail.swift
  - drinkpulse/Features/History/Components/EventContextMenu.swift

tech-stack:
  added: []
  patterns:
    - "ForEach identity sourced from the model's own stable uuid, never the SwiftData-synthesized PersistentIdentifier"
    - "Destructive row actions arm a @State flag; the mutation runs only from the confirmation's confirm button"
    - "A View extension needing @State becomes a private ViewModifier, keeping the public entry-point signature unchanged so call sites are untouched"

key-files:
  created:
    - drinkpulseUITests/Features/History/ContextMenuDeleteConfirmationUITests.swift
  modified:
    - drinkpulse/Features/History/Components/EventContextMenu.swift
    - drinkpulse/Features/History/Components/HistoryDaySectionCard.swift
    - drinkpulse/Features/History/Components/HistoryCalendarDayDetail.swift
    - drinkpulse/Localizable.xcstrings
    - drinkpulseUITests/Features/History/DuplicateEditPersistenceUITests.swift

decisions:
  - "D-01 approve: History ForEach identity switched to ConsumptionEvent.uuid"
  - "D-02 confirmation: context-menu Delete gated by a confirmation dialog, not undo"
  - "D-03 plain: canonical guideline checkmark is the plain SF Symbol (recorded for 07-04)"
  - "D-04 schedule: A3-1 (#Index on consumptionDate) becomes its own follow-up phase; NOT implemented in Phase 7"
  - "D-05 now: B9-3 runs as 07-04's Task 4 (recorded for 07-04)"
  - "Anchored to a context menu, confirmationDialog presents as a popover in which the system suppresses the explicit .cancel button; the cancel path is exercised by dismissing the popover, matching the Edit sheet's shipped pattern"

metrics:
  duration: ~50 min
  completed: 2026-08-03

actuals:
  tokens: 21000
  tasks: 3
  commits: 4
---

# Phase 07 Plan 01: Blocker Fixes — Row Identity + Destructive Delete Confirmation Summary

Both Phase 7 audit blockers closed: History rows now key their `ForEach` identity on the model's
stable `uuid` instead of SwiftData's synthesized `PersistentIdentifier`, and the context-menu
Delete can no longer destroy a logged health record without a confirmation.

## Owner Decisions

Verbatim owner answer, recorded for plans 07-03, 07-04 and 07-05 to read:

> **"D-01 approve, D-02 confirmation, D-03 plain, D-04 schedule, D-05 now"**

| ID | Answer | Consequence |
|----|--------|-------------|
| D-01 | `approve` | Task 2 executed: both History `ForEach` call sites switched to `ConsumptionEvent.uuid`. |
| D-02 | `confirmation` | Task 3 executed as written — confirmation dialog, not undo. |
| D-03 | `plain` | Recorded only. The canonical guideline checkmark is the plain `checkmark` SF Symbol with `.fontWeight(.semibold)`. Consumed by **07-04**; nothing implemented here. |
| D-04 | `schedule` | Recorded only. A3-1 (`#Index` on `consumptionDate`) becomes its own follow-up phase with `SchemaV5` + a V4→V5 `MigrationStage` + migration tests. **Not implemented in Phase 7** — no file under `Domain/Persistence/Schemas/` was touched (verified). |
| D-05 | `now` | Recorded only. B9-3 runs as **07-04's Task 4**, sequenced after its Tasks 1-3. |

## What Was Built

### Task 2 — Stable row identity (A1-1, blocker)

Both History row call sites — `HistoryDaySectionCard` and its verbatim duplicate
`HistoryCalendarDayDetail` — changed their `ForEach` identity from `\.element.id` (SwiftData's
synthesized `PersistentIdentifier`) to `\.element.uuid`.

A freshly-inserted SwiftData object carries a **temporary** `PersistentIdentifier` that only becomes
permanent when the context saves. SwiftUI reads that flip as remove-plus-insert rather than update,
tearing the row down instead of updating it — the same mechanism that previously destroyed unsaved
edits in the Edit sheet (`.planning/debug/resolved/sheet-closes-reopens-loses-state.md`). `uuid` is
the identity plan-0023 created for exactly this purpose, and is already the key CloudKit LWW de-dup
and `RecordDeduplicator` rely on, so this is view-layer only: no schema change, no migration.

`Array(events.enumerated())` and the `index`-driven `Divider` were deliberately left alone — 07-03
removes the index dependency entirely as part of the `EventRowButton` extraction.

### Task 3 — Confirmation-gated delete (C13-1, blocker)

`eventContextMenu` was a bare `View` extension, which has nowhere to put state, so it became a
private `EventContextMenuModifier: ViewModifier`. The public
`eventContextMenu(for:in:healthService:reduceMotion:)` signature is unchanged, so **neither row call
site needed editing**.

- The menu's destructive button now does nothing but `isPresentingDeleteConfirmation = true`.
- The actual removal — `HealthWriteHooks.remove`, `context.delete`, `try? context.save()`, all still
  inside `animatedHistoryChange(reduceMotion:)` — moved into `performDelete()`, called **only** from
  the confirmation's destructive button.
- Duplicate was carried over verbatim (same `duplicated()` / `insert` / `ensureUniqueIdentity` /
  `save()` sequence, same explanatory comment) and is **not** gated — it is non-destructive.

## Verification

| Check | Result |
|-------|--------|
| `ContextMenuDeleteConfirmationUITests` (3 tests) + `EditDeleteConfirmationUITests` (2) + `DuplicateEditPersistenceUITests` (2) | **7/7 passed, `** TEST SUCCEEDED **`** |
| `grep -Fc 'id: \.element.uuid'` in both row files (comment-stripped) | `1` and `1` |
| `grep -c 'element\.id'` in both row files (comment-stripped) | `0` and `0` |
| `grep -c 'confirmContextDeleteButton'` in `EventContextMenu.swift` | `1` |
| `grep -c 'performDelete'` in `EventContextMenu.swift` | `2` (definition + single call site) |
| `history.row.deleteConfirm.title` en value | `Delete this drink?` |
| `history.row.deleteConfirm.message` present | `True` (`This can’t be undone.` — U+2019) |
| Swift compiler warnings | `0` |
| Files over 300 lines | none (`EventContextMenu.swift` is 125) |
| Files under `Domain/Persistence/Schemas/` changed | `0` |
| `print(` in `EventContextMenu.swift` | none |

## Deviations from Plan

### 1. [Rule 3 - Blocking] Confirmation renders as a popover, which suppresses the Cancel button

**Found during:** Task 3, GREEN phase.
**Issue:** The plan specified a two-button dialog and a `test_contextMenuDelete_cancel_keepsRow` that
taps a Cancel button. Anchored to a context menu, SwiftUI presents the `confirmationDialog` as a
**popover**; a hierarchy dump confirmed the presented popover contains the title, the message and the
identified confirm button, but **no `.cancel`-role button** — in a popover presentation the system
deliberately omits it, because dismissing the popover *is* the cancel affordance.
**Fix:** The `.cancel` button remains declared in `EventContextMenuModifier` (it renders in
presentations that do show one). The test's cancel path now dismisses the popover with the coordinate
tap already proven by `EditDeleteConfirmationUITests.test_editDelete_dismissPopover_keepsEvent`. The
test was **not** weakened — it still asserts the confirm control appeared (so delete did not fire
immediately), that it disappears after dismissal, that the row survives, and that it stays hittable.
**Commit:** `bb5ef2a`

### 2. [Rule 3 - Blocking] `confirmContextDeleteButton` resolves to multiple elements

**Found during:** Task 3, GREEN phase. `tap()` failed with "Multiple matching elements found".
**Issue:** SwiftUI publishes the presented dialog's button at more than one point in the accessibility
hierarchy (the dump shows a `Button` nested inside an identically-identified `Button`).
**Fix:** Test queries route through a `confirmDeleteButton()` helper using `.firstMatch`. The query
stays keyed on the **identifier**, never on the English label "Delete" — which the plan explicitly
forbade and which three controls across these flows share.
**Commit:** `bb5ef2a`

### 3. [Deviation - documented] String Catalog written by hand-placed insert, not a re-serialize

**Found during:** Task 3.
A `json.load`/`json.dump` round-trip re-sorted the whole catalog under Python's byte ordering,
producing a 104-line diff of unrelated key churn. Reverted and inserted the two keys directly in
their correct alphabetical slot instead, giving a purely **additive 22-line diff**.
**Commit:** `bb5ef2a`

## TDD Gate Compliance

| Task | RED | GREEN |
|------|-----|-------|
| Task 3 (C13-1) | **Genuine RED** — `c1a5940`. Both delete tests failed against the unguarded menu ("Context-menu Delete must open a confirmation, not delete immediately"); the Duplicate test passed, correctly pinning that Duplicate must stay un-gated. | `bb5ef2a` |
| Task 2 (A1-1) | **RED did not fail** — see below. Committed as `49f84f8`. | `2b03ed4` |

**Task 2 RED-gate exception (investigated, not skipped).** Per the fail-fast rule, execution stopped
when `test_duplicate_keepsOriginalRowIdentity` passed before the fix. Cause: the Duplicate action
already calls `context.save()` synchronously right after `insert()` (the prior
`sheet-closes-reopens-loses-state` fix), which closes the temporary-identifier window *before* the row
is ever rendered, so the duplicate flow cannot currently reproduce the flip. A1-1 is therefore a
**latent** identity defect — real, but masked in this one path by that mitigation. The test is an
honest regression guard (it fails if the save-immediately mitigation is ever removed while the keying
is fragile), not a driver. The plan anticipated this shape: its `<behavior>` block already labels
Behavior 1 "already covered — must keep passing". No failure was fabricated.

## Known Stubs

None.

## Threat Flags

None. No new network call, no new `os.Logger` interpolation, no new seeding hook, no `@Model` change.
The two new String Catalog keys are static English copy carrying no user data (T-07-04, `accept`).

Threat register outcomes: **T-07-01 mitigated** (delete routes through the confirmation; pinned by
`test_contextMenuDelete_cancel_keepsRow`). **T-07-02 mitigated** (reused the existing `uuid`, no new
field; no schema file changed). **T-07-03 mitigated** (no `@Model` shape touched — verified).
**T-07-05 mitigated** (reused the existing `-dp_uitest` fixture).

## Deferred Issues

- **Pre-existing UI-test batch flakiness (environmental, out of scope).** Batch runs intermittently
  log "Restarting after unexpected exit, crash, or test timeout" and silently drop a test from the
  totals. Confirmed **pre-existing and not caused by this plan**: the untouched
  `EditDeleteConfirmationUITests` reproduces it on its own, and no `drinkpulse` crash report is
  generated. It correlates with a long-lived simulator; restarting the simulator cleared it, after
  which the full 7-test verification suite passed in one run. Worth watching, not fixed here.
- **`appintentsmetadataprocessor` build warning.** `xcodebuild ... | grep -c 'warning:'` returns `1`,
  not `0`. The single line is `warning: Metadata extraction skipped. No AppIntents.framework
  dependency found.` — emitted by a packaging tool, not the Swift compiler, and present on a clean
  baseline. **Swift compiler warnings are zero.** Adding an AppIntents dependency to silence it is
  out of this plan's scope.

## Docs Owed at Phase Close (not written here)

This plan ran as one of five parallel worktree agents, so shared living docs were intentionally left
untouched to avoid cross-agent merge conflicts. Per CLAUDE.md's end-of-task checklist, whoever closes
Phase 7 owes:

- `docs/DEVLOG.md` — a **phase-level** entry (the file's convention is per-phase: "Phase 4 closed…",
  "Phase 5 executed…", never per-plan).
- `.claude/context/current-focus.md` and `.claude/context/open-questions.md` — phase-level state.

No other living doc needs updating for this plan: `architecture.md`, `domain.md`, `README.md` and
`.planning/PROJECT.md` contain no description of context menus, row identity, or `ForEach` keying
(verified by grep), so nothing they say was contradicted.

`.planning/STATE.md` and `.planning/ROADMAP.md` were **not** modified — the orchestrator owns those.

## Commits

| Commit | Type | Description |
|--------|------|-------------|
| `49f84f8` | test | Pin original-row survival across the duplicate identifier flip |
| `2b03ed4` | fix | Key History row `ForEach` loops by `ConsumptionEvent.uuid` (A1-1) |
| `c1a5940` | test | Failing UI tests for context-menu delete confirmation (C13-1) |
| `bb5ef2a` | fix | Gate History context-menu Delete behind a confirmation (C13-1) |
| `83f5fb5` | docs | This SUMMARY |

## Self-Check: PASSED

All claimed files exist on disk and all five commits are present in the branch's history.
