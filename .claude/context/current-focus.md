# Current Focus

_Update this file at the end of every session._

## Status: Phase 09 complete — Phase 10 Data & Platform Integration Modernization next (2026-09-19)

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
