# Open Questions

_Move items here when they arise; remove them when resolved (note the resolution)._

---

## Native UI port: sequencing and conflicts (plan 0040)

**Question**: When does the native UI port start, and how do earlier plans that it reverses
get closed?

**Current state** (2026-11-20): plan 0040 is a draft. Plan 0038 (`in-progress`) moved History
to `ScrollView` + `LazyVStack` and dropped swipe-to-delete; the port uses `List` with swipe
actions. Plan 0039's inline `HistorySearchField` is replaced by native `.searchable`. Plan
0033's ember accent is replaced by the Frost accent. Phase 11 / milestone closure is pending.

**Resolved 2026-11-20:** 0038 closed as superseded by 0040 (its `LazyVStack` was already
reverted by commit `420fc20`); round 21 audit policy accepted.

**To resolve**: start the port before or after milestone closure; measure the `List`
row-build cost on iOS 27 on a device during step 5.


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

Phase 11 (2026-11-16): Listed in the Phase 11 debt ledger as DL-M01; not resolved in Phase 11.

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

Phase 11 full run (2026-11-15): passed (unexpectedly, ledger DL-T01; the entry stays open, the cause was not found).

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

**Phase 09 closure (plan 09-10, 2026-11-13)**: Phase 09 closed with this as the D1 exception; MOD-02 is complete with the exception recorded. This entry stays open on purpose. Also still open: empty-data behavior on the device (never measured), the adjacency and ordering assumptions (unchecked), and a full `RunAllTests` run to confirm the two skipped harness tests stay skipped (only `GetTestList` confirmed it).

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

Phase 11 full run (2026-11-15): passed (ledger DL-T02, DL-T03, observation DL-O02). The two tests had failed in the
Phase 11 scoped run G3 (2026-11-14); the entry stays open because the result differs between runs.

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

## Accessibility audit failures on the old UI (found 2026-11-19, baseline 2026-11-20)

**Question**: Known failing ungated audit tests on the pre-port UI. Not fixed:
the native UI port replaces these screens and the audit is rebuilt on the new
UI (owner, 2026-11-20; plan 0040, plan 0041 abandoned).

**Baseline** (2026-11-20, iPhone 18 Pro simulator, iOS 27.2, app code = `main`
`c1b4bec`; 9 tests, 5 passed, 4 failed):
- `DashboardAccessibilityAuditUITests` standard: `contrast` on the header
  subtitle ("20. Nov · WHO (Global)"). Dark passed this run (failed 2026-11-19).
- `InsightsAccessibilityAuditUITests` standard and dark: `dynamicType` on the
  Health Impact stat tiles ("1 d", "20%", "1/5", "Drink-Free Days",
  "Longest Streak"); likely `minimumScaleFactor` / `lineLimit(1)` in
  `HealthMetricsCard.swift` (not confirmed).
- `OnboardingAccessibilityAuditUITests` standard: `contrast` on "Get Started"
  (element-less on 2026-11-19). **Passes after plan 0042** (Frost accent).
Content is date-dependent (seeded `multiday` data is relative to now).

History lines removed 2026-11-21: plan 0045 ported History; its audit state is in the entry
"History audit findings after the port (plan 0045)".

**Added by plan 0044** (2026-11-21; same findings on the pre-0044 app code, checked by a
temporary checkout of the base sources):
- `InsightsAccessibilityAuditUITests` dark: `contrast` on "Binge Episodes".
- No finding on the `+` (`addDrink.button`) or the tab bar; `AuditBarControls` exempted 0.


**To resolve**: Each port step compares its audit run with this list; a
failure not listed here is a port regression. Remove each line when the
step that ports its screen leaves that audit class green (History: step 5;
Today/Insights: step 6; Onboarding: step 8). Delete the entry after step 8.

## History audit findings after the port (plan 0045)

**Question**: Are the two remaining History audit findings real defects or audit artifacts?

**Current state** (2026-11-21): `HistoryAccessibilityAuditUITests` 6 / 7,
`HistorySearchAccessibilityAuditUITests` 1 / 2 after the owner-approved system-control
exemptions (`HistoryAuditSystemControls`) and D11-29 tab-bar occlusion. Open:
- `test_historyCalendar_standard_hasNoAuditIssues`: `dynamicType` on the calendar mode's own day
  header and row texts ("Today", "1 drink · 2.0 std", "Bottle", "std"). The same texts pass in the
  list variants and the calendar AX5 variant; suspected artifact of the `UICalendarView` relayout.
- `test_historySearch_active_ax5_hasNoAuditIssues`: `contrast` on "Check the spelling or try a
  new search." (already `dpSecondaryText`); suspected position under the keyboard at AX5.
Also unverified: VoiceOver reads calendar decorations as SF Symbol names ("Small circle badge,
filled"), not the risk level.

**To resolve**: Accessibility Inspector / device check of both screens; fix at the source if
real, else an owner decision. Device checks from plan 0045 ("Device check (owner)"): swipe feel,
VoiceOver row actions (manual actions kept; never doubled), decorated days, calendar paging and
Today, search drawer and edge effect, row-build cost while scrolling many pages.

## Plan 0044 gate run and review deferred (owner, 2026-11-21)

**Question**: Do the plan 0044 changes pass the scoped gate together, and does a whole-branch
review find anything?

**Current state**: each Task 1–4 class ran green inside its task, but the closing scoped run
failed with an incomplete result bundle (22 classes in one `RunSomeTests` call), its re-run was
stopped for a device build, and the owner deferred testing. Coverage of `LogFeedback.swift` /
`WithMotion.swift` not measured (owner: skip the CLI run). No superpowers final review.

**To resolve**: run in batches of about 10 classes: `WithMotionTests`, `DPMotionTests`,
`LogFeedbackTests`, `ReduceMotionHistoryUITests`, `DuplicateEditPersistenceUITests`,
`ContextMenuDeleteConfirmationUITests`, `AddDrinkFlowUITests`, `HealthWriteHooksUITests`,
`ShellNavigationUITests`, `SheetDismissTabSwitchUITests`, `LaunchHandoffUITests`,
`WeeklySummaryTapUITests`, `SettingsUITests`, `OnboardingAuthorityUITests`, the four audit
classes (Dashboard, Insights, History, Settings), `DashboardUITests`, `InsightsUITests`,
`HistoryInteractionUITests`; expected green except the audit baseline above.

## Settings AX5 picker-label audit exemption (plan 0043, owner deferred 2026-11-21)

**Question**: Accept the exemption in `SettingsDynamicTypeUITests` for
`dynamicType` / `textClipped` on the five Preferences picker labels
("Appearance", "Volume unit", "Alcohol unit", "ABV precision", "Currency") and
`none#type=nil` at AX5?

**Current state** (2026-11-20): at accessibility sizes those pickers use the
system `.navigationLink` style (plan 0043 D0043-4). The audit reports the two
types on their system-drawn labels although the render shows nothing clipped
("Appearance" on one line, values wrapped). Same shape as D11-28 (system Form
controls on Add Drink step 2). Content controls, so the round-21 policy does
not cover them. `SettingsAccessibilityAuditUITests` passes without it.

**Owner, 2026-11-21**: deferred to a larger test pass, decided together with
the device check of the AX5 pickers.

**To resolve**: owner accepts it (record a decision id) or picks another AX
layout; then remove this entry.

## Contrast-safe secondary ink for List / Form screens (plan 0043)

**Question**: What replaces `Color.dpSecondaryText` when step 11 deletes the
old contrast assets?

**Current state** (2026-11-20): the system grey for section headers, footers
and picker values is about 3.2–3.4:1 on the Light Frost tint and fails the
audit. Settings uses `dpSecondaryText` (Light #636369, 4.96:1 on the tint) for
headers, hint footers and the guideline value. History (step 5) will hit the
same issue.

**To resolve**: keep the asset under a design-system name (for example a
`Brand` secondary ink with a WCAG test) before step 11; do not delete it.

## Increase Contrast variants for the accent and risk colours (plan 0042)

**Question**: Should `AccentColor` and `RiskLow` / `RiskModerate` / `RiskHigh`
get Increase Contrast appearances in the asset catalog?

**Current state** (2026-11-20): not in the prototype. Increase Contrast already
removes the page tint and the Dark card mix (`Brand.tintFraction` /
`surfaceFraction` = 0) and doubles the arc track opacity.

**To resolve**: device check under Increase Contrast, then add variants in
step 11 or a separate small plan (owner, 2026-11-20).

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

Phase 11 full run (2026-11-15): Domain coverage measured 90.06 percent against the 100 percent target, still not met
(overall 94.65 percent; ledger DL-W01, DL-W07, DL-Q14; WINDOWS.md row 7). Not resolved in Phase 11.

Update 2026-11-18 (plan 11-24, D11-33): the owner chose accept-debt. Coverage was not re-measured at the final build (no Domain file changed since `2aa9156`, `DPMotionTests` is green, the other changes are view code); the 94.65 and 90.06 percent figures stay as the historical record of plan 11-05. The Domain shortfall stays open: a later owner-approved CLI coverage run or Domain tests would close the figure.

---

## Human accessibility checklist items still open (Phase 11)

**Question**: How are the open items of the VER-03 owner checklist resolved?

**Current state** (updated 2026-11-18, plan 11-24): VER-03 is complete with open items (owner confirmation). The gap
closure fixed the failed items: CHK-05 and CHK-06 (Reduce Motion) and CHK-04 passed their owner re-run on the plan 11-14
build, CHK-08 and CHK-09 were re-observed on final build 3f70ff6, and the gated audit class passed 16 of 16. Results are
from the iOS 27.2 simulator, not a device; record in
`.planning/phases/11-ios-27-release-verification/11-A11Y-CHECKLIST.md` and `11-EVIDENCE.md`. Still open, none closed:
- CHK-00 (VoiceOver rotor not reachable on the simulator; DL-O04), CHK-01 and CHK-02 (chart Audio Graphs, reason CHK-00;
  DL-O05, DL-O06) and CHK-10 (History row VoiceOver actions, reason CHK-00; DL-O11): a physical device is required.
- CHK-03 (no visible callout animation difference with Reduce Motion on or off, so the gate is not shown by a before and
  after difference; DL-O15): owner decides whether a device recheck is wanted.
- CHK-07 residual DL-O19 only (Add Drink step 2 text-field placeholders truncated at AX5, minor, no fix plan; the owner
  settled CHK-07 as open on 2026-11-18). OBS-D (the Home arc shows no visible animation with Reduce Motion off) is an
  out-of-scope observation.

**To resolve**: A device session for CHK-00, CHK-01, CHK-02 and CHK-10; an owner decision on DL-O19 (fix or accept) and on
a CHK-03 device recheck.

---

## VoiceOver reads a huge number on Insights chart points (OBS-A)

**Question**: Why does VoiceOver read a very large number (about 816 million) instead of date and value when an
Insights chart point is focused?

**Current state**: Owner observation during the Phase 11 session (ledger DL-O12), brief
`.planning/phases/11-ios-27-release-verification/11-DECISION-OBS-A.md`, decision pending. The cause is an unverified
hypothesis (a raw date spoken as the value); related in kind to audit group A11Y-AUDIT-G05. CHK-01 stays open, not fail. Still pending on 2026-11-18 (plan 11-24, D11-27: no fix planned in the gap closure).

**To resolve**: Owner decision on the brief; then verify in code and on a device.

---

## Settings shows an endless spinner without a profile (OBS-C)

**Question**: Can a real user reach a store that has events but no `UserProfile`, and what should Settings show then?

**Current state**: Owner observation during the Phase 11 session (ledger DL-O14), brief
`.planning/phases/11-ios-27-release-verification/11-DECISION-OBS-C.md`, decision pending. `SettingsView` shows a
`ProgressView` when `profiles.first` is nil, so a missing profile looks like loading and gives no way out. Reachability
by a real user is not established (ties to the store recovery entry above). Still pending on 2026-11-18 (plan 11-24, D11-27).

**To resolve**: Owner decision on the brief (retain, change or defer). A change touches a data-creating path.


## Report the cancelled-swipe Back button bug to Apple

**Question**: Should the iOS 27 framework bug behind the Add Drink step 2 fix be filed with Feedback Assistant?

**Current state**: Found 2026-11-18. In a `NavigationStack` inside a sheet, a pushed view with any leading toolbar item
(`.cancellationAction`, text or `Button(role: .cancel)`) loses the system Back button after a cancelled interactive pop
(short edge swipe); the leading item slides into its place. Reproduced 3 of 3 on the iPhone 18 Pro simulator, iOS 27.2.
The app no longer triggers it: step 2 shows Back and Save only (HIG Sheets, multi-step flow). Diagnostic variants A to F2
are on `diag/backbtn-*` branches in the diag worktree. Hiding the system Back button with a custom one also avoids the bug,
but disables swipe-back unless a UIKit delegate bridge is added (variant F2, rejected).

**To resolve**: Owner files a Feedback Assistant report with a minimal repro, or decides not to.
