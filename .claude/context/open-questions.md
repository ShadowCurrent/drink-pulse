# Open Questions

_Move items here when they arise; remove them when resolved (note the resolution)._

---

## Production build date and privacy manifest

**Question**: Should production users see a build date in the Settings version footer, and does the
app need a privacy manifest before App Store submission?

**Current state**: Release builds show only "Version X (Y)". The Debug-only build time reads a file
timestamp (a required-reason API) and is compiled out of Release. The repo has no
`PrivacyInfo.xcprivacy` (confirmed with `find . -name PrivacyInfo.xcprivacy -not -path './build/*'`),
although the app uses UserDefaults and `@AppStorage`, which Apple lists under
`NSPrivacyAccessedAPICategoryUserDefaults` (reason code CA92.1 among the documented reasons).
Relevant to Phase 11 release verification.

**To resolve**: Decide whether production users should see a build date. If yes, add a build-time
source (script phase or Info.plist preprocessing, both edit `project.pbxproj`) and a privacy
manifest. Independently audit required-reason API declarations before App Store submission.

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

**Question**: Why does the whole screen flicker for about a second after Add Drink is dismissed and the user
switches to another tab, and is it the same defect as the intermittent iOS 27 simulator crash in `glassEffect`?

**Current state**: Reported by the owner on an iPhone 15 Pro Max (iOS 27) since iOS 26, in light and dark (weaker in
dark), on Insights and Dashboard, and seen once on the simulator during a harness run. Cross-tab finding (plans
09-06 and 09-07, simulator evidence only): the crash needs one live `glassEffect` card on either tab after a sheet
cycle; a material instead of glass is clean 20 of 20, and the Dashboard `GlassEffectContainer` is not required
(variant V1 crashes like HEAD). Classification C-INCONCLUSIVE; no cure proposed. Owner decision C013
(`revert-container-only`, 2026-11-13) removed the `553ea58` container; it fixes neither symptom. Nothing is
device-confirmed, and the flicker was never measured.

**Status**: Deferred by the owner on 2026-11-13 out of Phase 09 to the pending todo
`.planning/todos/pending/2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md` (resume recipe inside).
Evidence round kept for resumption: worktree `/Users/fempter/Developer/drinkpulse-diag/work`, standalone
`/Users/fempter/Developer/drinkpulse-diag/minimal-repro`, and all `diag/09-flash-*` and `diag/09-crash-r2-*`
branches (the `v1`, `v3`, `v4` worktrees were removed after their diffs were recorded). Two harness tests are
skipped in the scheme until this is resolved. Still open: H1 to H6, crash candidates G1 to G6 (never measured),
the video flicker metric, the unsubmitted Apple Feedback draft, and owner-device confirmation.

## History edit UI tests fail on their own

**Question**: Why do `HistoryInteractionUITests/test_editCustomNameAndNotes_persist` and
`test_editCategoryChange_persists` fail on the iOS 27.2 simulator?

**Current state**: Found at the plan 09-08 scoped gate (2026-11-13). Both fail deterministically, also on retry and
with the `GlassEffectContainer` put back, so they are pre-existing and unrelated to the Dashboard. Waived by name
for Phase 09 by the owner; tracked in `.planning/todos/pending/2026-11-13-history-edit-uitests-failing.md`.

**To resolve**: Diagnose and fix the edit flow or the tests (for example `/gsd-debug`), then confirm the History UI
suite is green.

## Deferred Phase 09 code-review findings

**Question**: Which of WR-01 to WR-04 and IN-01 to IN-04 (Phase 09 review) are worth fixing, and in which phase?

**Current state**: Deferred by owner decision O3 (2026-11-13), none open in `09-REVIEW-DISPOSITION.md`. All but
IN-01 describe behavior that predates Phase 09 (checked against git history). Captured as one item each in
`.planning/todos/pending/2026-11-13-triage-deferred-phase-09-review-findings.md`.

**To resolve**: Triage the todo; the WR-03 and WR-04 items touch user-entered data and need tests.

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
