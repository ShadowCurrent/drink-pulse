# Current Focus

_Update this file at the end of every session._

## Status: native UI port, step 6 (Today / Insights, plan 0046) completed (2026-11-21)

Active work is the native UI port (plan
[0040](../../docs/plans/0040-native-ui-port/plan.md)) on the integration branch `ui-revamp`.

**2026-11-21:** plan [0046](../../docs/plans/0046-today-insights/plan.md) executed on
`port/0046-today-insights` and merged into `ui-revamp` (not pushed): Today and Insights are card
screens on the Frost tint with system components (hero arc + cut-out glyph, tiles, `Gauge` limit
rows, charts with slot identity and a daily-limit rule, Insights empty state, period "Today"
button, VoiceOver announcement); the tab is called "Today". Audit classes for Today, Today over
limit and Insights are green; `ViewThatFits` / lazy adaptive grids are no longer used around text
(audit). Owner: Settings keeps no `+`.

**Owner, 2026-11-21:** built on "iPhone Dawid"; step 6 provisionally accepted, UI corrections
come later in a separate pass.

**Open:** owner device checks and the percent-rounding question (open-questions "Plan 0046 open
items"); coverage skipped (owner).

**2026-11-21 (evening):** final superpowers review of plan 0046 done; fixes on
`fix/0046-review` (UK chart rule captioned "Daily average", Review focus 3 pin corrected), merged
into `ui-revamp`, not pushed. Minors in plan 0046 `execution.md`.

**2026-11-23:** Add Drink step 1 redesign accepted in the prototype (round 22: Recent +
sectioned presets without servings + search); open details in open-questions "Plan 0047 input".

**Next:** port step 7 (Add / Edit Drink, plan 0047). Full suite at step 8.

## Historical: native UI port, step 5 (History, plan 0045) completed (2026-11-21)

Active work is the native UI port (plan
[0040](../../docs/plans/0040-native-ui-port/plan.md)) on the integration branch `ui-revamp`.

**2026-11-21:** plan [0045](../../docs/plans/0045-history/plan.md) executed on `port/0045-history`
and merged into `ui-revamp`, pushed to `origin` with the paging fix (`ec916f0`): picker in the bar, inset-grouped day sections with
totals, count-based list paging (50 events a page, fixed after the merge on
`fix/history-pagination`), native swipe / context-menu row actions, native `.searchable`
with scopes, `UICalendarView` calendar (`DecoratedCalendar`) with risk marks, Frost tint, empty
state with "Log a Drink".

**Owner decisions this step:** no full suite, scoped runs of the changed areas only; recorded audit
exemptions for system-owned History controls (`HistoryAuditSystemControls`). Coverage not measured.

**Open:** two History audit findings (open-questions); the two History edit UI tests (existing
entry); owner device checks for plans 0042–0045 (larger test pass).

**Next:** plan 0046 (port step 6, Today / Insights). Full suite at step 8.

## Historical: native UI port, step 4 (Shell, plan 0044) completed (2026-11-21)

Active work is the native UI port (plan
[0040](../../docs/plans/0040-native-ui-port/plan.md)) on the integration branch `ui-revamp`.

**2026-11-21:** plan [0044](../../docs/plans/0044-shell/plan.md) executed on `port/0044-shell` and
merged into `ui-revamp` (not pushed): `RootShellView` is a plain `TabView` that injects
`\.addDrink` and `\.drinkLogged`; Today, Insights and History own a `+` (`AddDrinkToolbarItem`,
`.primaryAction`, `.glassProminent`); Settings has none; one logging haptic in the shell
(`LogFeedback`: `.warning` when a drink crosses the daily limit, else `.success`); `withMotion`
is the single animated-mutation helper; `AuditBarControls` holds the round 21 bar-control
exemption. Built and launched on the owner's iPhone ("iPhone Dawid") for a later check.

**Owner deferred testing:** the plan 0044 scoped gate run (all Task 1–4 classes together plus
`DashboardUITests`, `InsightsUITests`, `HistoryInteractionUITests`) and the final whole-branch
review were not run; coverage not measured (owner said skip). In open-questions.

**Owner device checks deferred to a larger test pass:** plan 0042 (arc sweep, Reduce Motion,
Frost accent, risk tones), plan 0043 (VoiceOver on the guideline picker and denied footers, AX5
pickers), plan 0044 (logging haptic success / warning, no haptic on sheet open, `+` placement in
Light / Dark, none on Settings, Large Content Viewer on `+` at AX5, logging motion and Reduce
Motion).

**2026-11-21:** plan [0045](../../docs/plans/0045-history/plan.md) (port step 5, History)
written, owner accepted, frozen (`in-progress`) on `port/0045-history` (from `ui-revamp` at
`699c9d6`). Owner decisions: D0045-2 year only outside the current year, D0045-5 full-swipe
Delete without undo, D0045-6 Edit stays a sheet until step 7, D0045-10 History copy from
`VOICE.md` in this step.

**Next:** execute plan 0045 (Tasks 1–7, superpowers `executing-plans` inline) on
`port/0045-history`; full suite at its end (plan 0040 checkpoint).

## Historical: native UI port, step 3 (Settings → Form, plan 0043) completed (2026-11-20)

Active work is the native UI port (plan
[0040](../../docs/plans/0040-native-ui-port/plan.md)) on the integration branch `ui-revamp`.

**2026-11-20:** plan [0043](../../docs/plans/0043-settings-form/plan.md) executed and completed on
`port/0043-settings-form`: Settings is a system `Form` (section views in
`Features/Settings/Components/`, Notifications merged, guideline `.navigationLink` picker, Frost
tint, rounded large title); the glass Settings components are deleted. Settings audit class green
in standard, dark and AX5.

**2026-11-21:** merged into `ui-revamp` (`bb15e91`), not pushed. Denied footer text now uses
`Color.dpDeniedText` (asset `DeniedText`, Light #B3261E, Dark #FF6961, >= 4.5:1 on the Frost
page; owner choice). Device check on the owner's iPhone: Settings tint and large title pass.

**Owner decisions deferred:** the provisional AX5 exemption for the five Preferences picker labels
(`SettingsDynamicTypeUITests`); a design-system name for the contrast-safe secondary ink
(`dpSecondaryText`) before step 11. Both in open-questions.

**Owner device checks deferred to a larger test pass:** plan 0042 (arc sweep from 0, Reduce
Motion, Frost accent, risk tones) and plan 0043 (VoiceOver on the guideline picker and denied
footers, AX5 pickers).

**2026-11-21:** plan [0044](../../docs/plans/0044-shell/plan.md) (port step 4, Shell) written,
owner accepted, frozen (`in-progress`) on `port/0044-shell` (D0044-2 explicit `drinkLogged`
action, D0044-5 no accent wash until steps 5 / 6: both accepted).

## Historical: native UI port, step 2 (design tokens, plan 0042) completed (2026-11-20)

Plan 0042 completed on `port/0042-design-tokens` and merged into `ui-revamp`: `RiskLevel.tone`,
Frost `AccentColor` / `Brand`, tint and surface helpers, `BrandCardStyle` + `CardMetrics`,
rounded title helpers, animatable arc; design rules and audit policy in `docs/architecture.md`.

## Historical: Phase 11 (iOS 27 Release Verification) all 24 plans executed (2026-11-18)

Phase 11 finished its gap closure (plans 11-12 to 11-24). MOD-04, VER-01, VER-02 and VER-03 are recorded complete (with
named exceptions, limitations or open items below). Next step: re-run the phase verifier for Phase 11, then milestone
closure. Toolchain: Xcode 27.2 (build 27B52), Apple Swift 6.4.2, iphoneos and iphonesimulator 27.2 SDKs, deployment target
27.0, iPhone 18 Pro simulator on iOS 27.2. Everything is simulator evidence; no physical device was used. Source of every
figure: [11-EVIDENCE.md](../../.planning/phases/11-ios-27-release-verification/11-EVIDENCE.md), sections Gap closure
(plans 11-12 to 11-24) and Requirement outcome. Final build hash 3f70ff6.

- **MOD-04 complete:** Debug and Release device-SDK builds of the final tree have app-owned deprecation warnings 0 (the
  Release simulator-SDK build was not run, D11-20, L-07; the Release rebuild on the final tree was D11-32).
- **VER-01 complete with named exceptions:** final full run (plan 11-23) 888 tests, 866 passed, 4 failed (DL-T01 to
  DL-T04, all known), 18 skipped by gate. **Open: Domain coverage is 90.06 percent against its 100 percent target**
  (DL-W01, DL-W07, WINDOWS.md row 7). Coverage was not re-measured at the final tree; the historical 94.65 percent of plan
  11-05 is carried (owner accept-debt, D11-33).
- **VER-02 complete with named limitations:** L-01 to L-04 and L-09, plus L-05 to L-08.
- **VER-03 complete with open items (owner confirmation 2026-11-18):** the gated audit class passed 16 of 16 and no
  checklist item has the effective result fail. Open: CHK-00, CHK-01, CHK-02, CHK-10 (device), CHK-03, CHK-07 (DL-O19
  only), OBS-A and OBS-C (briefs pending), verifier items T06, T08, T09, T16, T17, T28.
- **New decision records:** ADR 0013 (accessibility motion seam and adaptive layout); D11-23 to D11-33 in 11-CONTEXT.md.

**Next:** re-run the Phase 11 verifier, then milestone closure. Also open: owner decisions on OBS-A and OBS-C, a device
pass for the VoiceOver items, DL-O19, the D1 flash and crash (todo `2026-09-18-...`), the phase-verifier re-runs for Phases
08, 09 and 10 (deferred by D11-01), and the Domain coverage gap.

**Side task done 2026-11-19:** plan 0039 (History List search by custom name, inline field with All / Named /
Unnamed scopes) completed on branch `plan-0039-history-search`, not pushed. It found 5 audit tests that already fail
on `main` (open-questions, "Five accessibility audit tests fail on main"); diagnose them before the Phase 11 verifier
re-run.

## Historical: native UI port planned (plan 0040, draft, 2026-11-20)

The native SwiftUI prototype (`~/Developer/drinkpulse-native-proto`, rounds 1–21) is
accepted by the owner up to round 20; round 21 (accessibility-size alternatives + audit
policy) awaits review. Plan [0040](../../docs/plans/0040-native-ui-port/plan.md) records every
decision, the step order (audit policy → tokens → Settings → Shell → History → Today/Insights
→ Add/Edit → Onboarding → copy → streak calculation → cleanup) and the rules. No app code
changed yet. Owner (2026-11-20): start the port as soon as possible, in parallel with Phase 11
closure on `main`. Workflow (plan 0040 "Workflow"): integration branch `ui-revamp`, one
`port/00NN-…` branch per step merged `--no-ff`, `ui-revamp` → `main` once after step 11,
main checkout (Xcode MCP), ask about push after each step. Round 21 accepted; plan 0038
superseded. Next session (owner: fresh session, superpowers skills inline, not GSD): plan
0041 (step 1, audit policy) on `port/0041-audit-policy` from `ui-revamp`. No ADRs for the port;
design rules go into `docs/architecture.md` in step 2.

## Historical: Phase 09 closed with D1 deferred; next was the Phase 09 re-verification run, then Phase 11 (2026-11-13)

Phase 10 (Data & Platform Integration Modernization) finished all code plans (10-01 to 10-11)
and the owner's device session (plan 10-12). Gates (plan 10-11): zero-warning build,
Thread Sanitizer clean over 21 suites, schema and CloudKit-off guards, full suite 678 unit
and 93 UI tests, 94.61 percent overall coverage.

Device session results on the owner's iPhone (counts and timings only, in
[10-DEVICE-SESSION.md](../../.planning/phases/10-data-platform-integration-modernization/10-DEVICE-SESSION.md)):
in-place upgrade of the real store, import round trip and Apple Health write, edit and delete
all PASS (214 events before and after, no duplicates, one sample per logged drink);
backgrounded reminder tap PASS; detached cold launch near container-load time (Dashboard
appeared in 104 to 118 ms), so the cold-launch todo is closed as not an app-code bug.

Quick task 261112-kvl (2026-11-12) added a version footer at the bottom of Settings; it does not change the Phase 11 focus.

**INT-01 cold-tap re-test passed (2026-11-10, plan 10-14).** The earlier finding was a daily-reminder
tap on a **killed** app opening Dashboard instead of the Add Drink sheet (pre-existing since commit
`ba4b326`, 2026-08-01). The owner decided `sync-assign` in
[10-DECISION-DEVICE-FINDING.md](../../.planning/phases/10-data-platform-integration-modernization/10-DECISION-DEVICE-FINDING.md)
and plan 10-13 assigned the delegate synchronously in `drinkpulseApp.init()`. The device re-test
in [10-DEVICE-RETEST.md](../../.planning/phases/10-data-platform-integration-modernization/10-DEVICE-RETEST.md)
recorded 3 killed-app taps with 3 correct, 1 backgrounded tap with 1 correct, detached launches
with delegate assignment at 5 to 7 ms and Dashboard appeared at 95 to 117 ms (D-17 verdict: near),
and the weekly cold tap as N/A (no natural delivery). The owner accepted residual risk R-03
(three taps are a finite sample). No startup change was made.

**Still open:** a natural weekly-summary delivery on a killed app is unobserved; the Xcode debugger
attach to the iPhone hangs (tooling); `InsightsUITests.test_heroCard_holdsHeight_whenSwitchingToAllTimeScope`
fails on the pre-10-13 baseline too (pre-existing, in open-questions). The plan 10-13 post-merge
run had 683 of 683 unit tests green and 93 UI tests with 2 failures (one a flake that passed on
re-run, one the pre-existing Insights failure), so the full suite was not fully green.
Next: Phase 10 re-verification, then Phase 11 (deprecation-diagnostics closure and release
verification, MOD-04, VER-01 to VER-03).

**Phase 09 closed with D1 deferred (2026-11-13, plan 09-10).** MOD-02 is complete with an explicit exception: the
whole-screen glass flicker and the intermittent iOS 27 simulator `glassEffect` crash (D1) are NOT fixed and NOT
device-confirmed. The owner's reply to the on-device checkpoint was the deferral, so no flicker counts were collected;
UAT test 7 is `skipped`. The D1 todo stays pending. Next: the orchestrator runs `phase complete` and the phase verifier
(regenerates `09-VERIFICATION.md`; do not hand-edit it). Open item: the scheme skip of the two crashing harness tests
(commit `830dcd6`) is confirmed only via `GetTestList`; a full `RunAllTests` run has not yet confirmed it end to end.

**Phase 09 gap-closure D1 deferred (2026-11-13, C013).** Owner decision C013 (`revert-container-only`) removed
the unauthorized Dashboard `GlassEffectContainer` from commit `553ea58` (plan 09-08). It fixes neither the
whole-screen glass flicker seen after Add Drink dismissal and a tab switch, nor the intermittent iOS 27 simulator
`glassEffect` crash; the owner deferred both (D1) to the pending todo
`.planning/todos/pending/2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md`. Two harness tests in
`SheetDismissTabSwitchUITests` are skipped in the `drinkpulse` scheme (they crash the simulator); two
`HistoryInteractionUITests` edit tests fail on their own and have their own todo
(`2026-11-13-history-edit-uitests-failing.md`). Plan 09-09 (records and cleanup) is done; plan 09-10 closes Phase 09
with D1 marked deferred. The eight remaining Phase 09 review findings (WR-01 to WR-04, IN-01 to IN-04) are deferred
into `2026-11-13-triage-deferred-phase-09-review-findings.md`.

## Historical: Phase 09 complete (2026-09-19)

Plan 09-03 is complete. On Xcode 27.0 (27A266a),
the iPhone 18 Pro iOS 27 simulator completed the selected Dashboard, Add Drink,
History, Insights, Onboarding, and Settings UI suites: **49 tests passed, 0
failures** in 869.086 seconds. The persistent CLI command was used because the
Xcode MCP test backend has a fixed timeout that is not a valid test result.

The retain record is
[09-RETAIN-EVIDENCE.md](../../.planning/phases/09-swiftui-design-system-modernization/09-RETAIN-EVIDENCE.md).
No production source changed in Plan 09-03. Owner verification confirmed the
remaining human checks, including that the Insights callout does not slide in
either Reduce Motion state. Native Add Drink sheet presentation remains system
behavior and is documented separately. Next: Phase 10 planning.

## Historical: GSD Phase 08 — iOS 27 Baseline & API Inventory

The app and both test targets now require iOS 27.0 in Debug and Release under
Xcode 27.0 (27A266a) with the Apple Swift 6.4 compiler; `SWIFT_VERSION = 6.0`
remains the selected Swift language mode. The reproducible evidence, exact
commands, and named iPhone 18 Pro iOS 27 simulator are in
[08-BASELINE.md](../../.planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md).

**Baseline result:** dependency resolution passed, but Debug and Release builds
and the unfiltered full suite each failed before tests began because of the
app-owned `DPArcProgress.swift:33` actor-isolation compiler error. The
`AddDrinkView.swift:5` `@Entry` closure warning is also recorded. Do not describe
this baseline as clean or infer test counts; remediation belongs to Phase 09.

**Historical Phase 07 verification (2026-08-04):** all five
`07-swiftui-list-performance-gesture-audit` plans were verified and signed off:
UAT 5/5 passed (`07-UAT.md`), the security threat register closed 26/26
(`07-SECURITY.md`, threats_open: 0), and `07-VERIFICATION.md` status was
`passed`. Its iPhone 17 Pro suite result is historical evidence, not the active
iOS 27 baseline.

**What landed.** Two blockers: History `ForEach` row identity moved to
`ConsumptionEvent.uuid` (the previous key flips when a duplicated event is
persisted — documented data-loss precedent), and context-menu Delete is now
confirmation-gated, sharing one flag with the new VoiceOver Delete action.
Then the per-render work: three pure value types (`RowUnitContext`,
`EventRowStrings`, `DaySection` + `daySections(_:now:calendar:)`) replaced
per-row profile observation, double formatting, and in-body day grouping;
`EventRowButton` and `GuidelineChoiceRow` each replaced a duplicated hierarchy;
the History list caches its day sections with a three-trigger refresh contract;
an empty initial window with older data now shows a labelled loading row beside
(never instead of) the pagination sentinel. Full narrative in
`docs/DEVLOG.md` (2026-08-04 entry) and the five `07-0N-SUMMARY.md` files.

**Historical backlog:**

1. **Phase 08 evidence and inventory:** use the linked baseline as the only
   active build/test entry point. Keep existing SwiftData data and behavior
   intact while inventorying modernization candidates.
2. **Phase 09 compiler remediation:** fix the recorded `DPArcProgress.swift:33`
   error before recapturing Debug, Release, and full-suite evidence; assess the
   `AddDrinkView.swift:5` warning without changing behavior speculatively.
3. **Domain-layer coverage is below its target**: `Domain/` aggregates to
   89.39% against CLAUDE.md's 100% requirement (worst: `DrinkTemplate.swift`
   46%, `DataTransfer` and `Schemas` files in the 64–77% band). This is
   pre-existing and needs separately scoped work.
4. **Finding A3-1 — `#Index` on `consumptionDate`** — deferred by owner
   decision D-04 = `schedule`. It changes the model's schema hash, so it needs
   `SchemaV5` + a V4→V5 `MigrationStage` + migration tests, never an in-place
   edit of `SchemaV4`.
5. **Pre-GSD plan-0038 is still `in-progress`** in `docs/plans/INDEX.md`; its
   remaining real-hardware verification is historical backlog, not the iOS 27
   build baseline.

2026-11-16: the exploratory audit record was corrected (385 reports, 311 byte-wise distinct keys; 9 of 16 rows ran in dark
appearance and are unreliable); a refreshed baseline follows in plan 11-13.
