# Open Questions

_Move items here when they arise; remove them when resolved (note the resolution)._

---

## BAC implementation

**Question**: Design and formula for BAC screen — Widmark, display units (‰ vs %),
elimination rate configurability.

**Current state**: Formula documented in `docs/domain.md`. Not implemented.

**Constraint**: Per CLAUDE.md — propose before implementing; owner hand-verifies
all calculation changes.

---

## Multi-currency spend aggregation

**Question**: When drinks in different currencies exist, how should "Today's Spend" be aggregated on the Dashboard?

**Current state**: `ConsumptionEvent.priceCurrency: String?` now exists (plan-0034) — each priced event carries the currency it was entered in. Spend is **not yet displayed anywhere** (plan-0034 was entry-only by decision). Multi-currency aggregation is still undefined.

**Options**:
- A) Show spend only when all of today's priced drinks share one currency; otherwise hide card
- B) Show spend with a warning label ("Mixed currencies")
- C) Convert to a base currency (requires exchange rates — out of scope)

**To resolve before implementation**: Decide on an option. The per-event `priceCurrency` field is already in place; this is now purely a display/aggregation decision.

---

## Guideline alert card tap action

**Question**: What happens when the user taps the red `GuidelineAlertCard` on the Dashboard?

**Options**:
- A) Switch to Settings tab
- B) Open guideline picker sheet directly
- C) No action (non-tappable)

**Current state**: Card is rendered non-tappable (option C by default per plan-0001 execution).

**To resolve**: Owner picks option before implementing tap action.

---

## History native swipe-to-delete

**Question**: Re-add native `.swipeActions` trailing swipe-to-delete on
History list rows.

**Current state**: The row-shape blocker is GONE. A separate debug session
(`.planning/debug/contextmenu-zoom-glitch.md`, 2026-08-05) flattened
`HistoryListQueryView`'s `List` to one top-level row per `ConsumptionEvent`
(`HistoryFlatRow`/`HistoryEventCardRow`, day boundaries as non-interactive
header pseudo-rows in the same flat `ForEach`) to fix an unrelated
context-menu wrong-row-targeting bug. Each `List` row is now genuinely one
event — the "each row is a whole day, `.swipeActions` is row-level" blocker
this entry used to describe no longer applies, and `swipeActionsContainer()`
(iOS 27+) is no longer needed as a workaround either. `.swipeActions` was
deliberately NOT wired up as part of that fix (out of its scope) —
context-menu Delete (confirmation-gated, Phase 07) remains the sole delete
path for now, but purely by choice, not by any remaining technical blocker.

**To resolve**: Decide whether to add native per-event `.swipeActions`
alongside the existing context-menu Delete, now that nothing blocks it.

---

## Apple Watch: data transport

**Question**: Does the watch app read directly from the shared CloudKit store
(requires watchOS SwiftData + CloudKit), or does it use Watch Connectivity
to relay events to the iPhone for persistence?

**Current state**: Not started. Depends on iCloud sync being in place first.

**To resolve**: Architect data flow before any watchOS target is added.

---

## Domain-layer test coverage is below its stated target

**Question**: How is `Domain/` brought to the 100% line coverage CLAUDE.md
requires, and is 100% still the right bar for every file in it?

**Current state**: First full coverage run since the target was written
(2026-08-04, Phase 07 close) measured `Domain/` at **89.39%** — 15 of 32 files
below 100%. Worst offenders: `DrinkTemplate.swift` 46%,
`DataTransfer/TemplateRecord.swift` 64%, `Persistence/Schemas/SchemaV2` and
`SchemaV3` ~68–69%, `DataTransfer/BackupDocument.swift` 67%,
`DataTransfer/BackupExport.swift` 69%, `ConsumptionEvent.swift` 83%. The overall
app target is fine (94.10%, above the 90% bar); this is specifically the
per-layer Domain target. Pre-existing — Phase 07 touched no `Domain/` file.

**To resolve**: Decide whether frozen `SchemaVN` snapshots and preview/fixture
helpers belong in the Domain denominator at all (they are effectively data
declarations), then write tests for whatever remains. Needs its own task; do not
fold it into an unrelated feature plan.
