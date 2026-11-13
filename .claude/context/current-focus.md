# Current Focus

_Update this file at the end of every session._

## Status: Phase 10 INT-01 cold-tap re-test passed; ready for re-verification (2026-11-10)

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
