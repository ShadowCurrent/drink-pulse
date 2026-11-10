# Open Questions

_Move items here when they arise; remove them when resolved (note the resolution)._

---

## Store recovery fires on any ModelContainer open error

**Question**: Should `StoreBootstrap.makeContainerReportingRecovery` move the store aside only
for unreadable-store and unknown-model-version errors, and should the user be told when
recovery ran?

**Current state**: Found in the Phase 10 code review (WR-01, left open by the WR-04 fix). Any
error from `ModelContainer.init` triggers the non-destructive move into `RecoveredStores/`,
including transient faults (disk full, file protection while the device is locked, an I/O
error). The user then sees an empty app with no notice, and after three recoveries the oldest
snapshot is trimmed. `docs/architecture.md` now states this behavior instead of claiming
"genuine corruption only".

**To resolve**: Product decision on the user-facing notice, then an allowlist of recovery
triggers (observed signature: `NSCocoaErrorDomain` 259 with underlying `NSSQLiteErrorDomain`
26, plus the unknown-model-version error), checked against Apple's `SwiftDataError` and
`CocoaError` documentation through Xcode MCP. Everything else should rethrow to the existing
`.failed` retry screen.

## Insights hero card height test fails (pre-existing)

**Question**: Why does `InsightsUITests.test_heroCard_holdsHeight_whenSwitchingToAllTimeScope`
fail, and is the hero card actually moving or is the test's tolerance too tight?

**Current state**: Found 2026-11-09 during the plan 10-13 post-merge full suite run. The test
fails reproducibly: Week chart y=323.0, All chart y=320.0, tolerance 1.0. It fails the same way
on the pre-10-13 commit `2cb2649` and on the pre-Phase-10 commit `fbd37fa` (checked 2026-11-10), and Phase 10 changed no Insights files, so it predates Phase 10. The
owner chose to log it and continue to the plan 10-14 device re-test. In the same run,
`HistoryInteractionUITests.test_segmentSwitch_alternatingDirection_endsInCorrectState` failed
once and passed on re-run (flake).

**To resolve**: Investigate the Insights hero card layout across the Week and All scopes in a
later phase or quick task; fix the layout or the test, then confirm the full UI suite is green.

## Weekly summary natural delivery not yet observed on device

**Question**: Does a naturally delivered weekly-summary notification show the owner-approved
as-of-last-visit copy and route to Insights on a real device?

**Current state**: Routing is covered by unit and UI tests (warm path included); no natural
delivery was seen during the 2026-11-09 or 2026-11-10 device sessions. The cold-tap path is now
device-verified for the daily reminder (plan 10-14, 3 of 3 killed-app taps and 1 of 1 backgrounded
tap opened Add Drink); only a natural weekly delivery remains unobserved.

**To resolve**: Observe one natural weekly delivery on the device, and a cold tap on it if the app
is killed at that time. Never change the device clock to force it.

## Debugger attach to the iPhone hangs

**Question**: Why does attaching the Xcode debugger to the owner's iPhone hang ("Xcode has
killed the LLDB RPC server")?

**Current state**: Seen in the 2026-11-09 device session. Detached launches and installs work.
Treated as a tooling observation, not an app result; consistent with the debugger-attached
overhead found while closing the cold-launch todo.

**To resolve**: Not an app task. Retry after an Xcode or device update before relying on
on-device debugging.

---

## Dashboard flash after Add Drink dismissal and tab change

**Question**: Why does Dashboard visibly flash after Add Drink is dismissed and
the user switches to another tab?

**Current state**: Confirmed by the owner on an iPhone 15 Pro Max running iOS
27. It occurs repeatedly after opening Add Drink, dismissing it, and switching
tabs. Xcode MCP simulator interaction completed three equivalent cycles, but
the first available static frame arrived after the short artifact and could
not confirm it. Dashboard's Liquid Glass effects were grouped in a
`GlassEffectContainer` based on Apple performance guidance, but the owner
reports the issue remains.

**Status**: Explicitly deferred by the owner on 2026-09-18 to avoid expanding
the iOS 27 modernization milestone. Reopen as a dedicated rendering/presentation
diagnostic with a real-device capture before changing further source.

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
