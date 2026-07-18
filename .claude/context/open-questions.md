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

## Apple Watch: data transport

**Question**: Does the watch app read directly from the shared CloudKit store
(requires watchOS SwiftData + CloudKit), or does it use Watch Connectivity
to relay events to the iPhone for persistence?

**Current state**: Not started. Depends on iCloud sync being in place first.

**To resolve**: Architect data flow before any watchOS target is added.
