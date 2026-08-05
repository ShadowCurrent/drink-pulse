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

## History native swipe-to-delete (post-iOS 27)

**Question**: Re-add native `.swipeActions` trailing swipe-to-delete on
History list rows.

**Current state**: Dropped in plan-0038 and still unavailable, but the
*reason* changed. The list is back on `List` (plan-0038's own 2026-08-03
re-scope reverted the `ScrollView`+`LazyVStack` migration), so the original
"`.swipeActions` needs a `List` row context" blocker no longer applies.
What blocks it now is the row shape: each `List` row is a whole day
(`HistoryDaySectionCard`, holding multiple events), not a single event, and
`.swipeActions` is a row-level affordance. Restoring per-event swipe-to-delete
would require either splitting days back into per-event rows — which is the
nested-`ForEach`-in-`Section` shape that defeats row-level laziness
(FB11280425) and was deliberately abandoned — or `swipeActionsContainer()`,
which is iOS-27-only against a current iOS 26 floor. Context-menu Delete
(now confirmation-gated, Phase 07) remains the sole delete path.

**To resolve**: Once minimum deployment reaches iOS 27, evaluate
`swipeActionsContainer()` on the day card's inner rows. Do **not** resolve it
by reverting to a per-event `List` row shape.

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
