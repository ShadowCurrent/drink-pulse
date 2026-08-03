# Current Focus

_Update this file at the end of every session._

## Status: GSD Phase 07 execution complete — SwiftUI List performance & gesture audit (2026-08-04)

All five plans of `07-swiftui-list-performance-gesture-audit` have executed and
committed. Verification (`/gsd-verify-work`) has **not** run yet — the phase is
code-complete, not signed off.

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

**Verification state**: full suite 93/93 green on iPhone 17 Pro, build clean
with zero Swift warnings, app-target coverage 94.10%.

**Outstanding — next session should start here**, in priority order:

1. **Two accessibility human-checks** (from 07-03, still unperformed; need a
   human at a device): the VoiceOver Actions rotor on a History row — does it
   announce Duplicate and Delete, and does Delete present the confirmation? —
   and an Accessibility Inspector contrast audit of `.secondary` captions over
   the glass background, in light, dark, and Increase Contrast. Tracked in
   `open-questions.md` and `.planning/WINDOWS.md`.
2. **Domain-layer coverage is below its target**: `Domain/` aggregates to
   89.39% against CLAUDE.md's 100% requirement (worst: `DrinkTemplate.swift`
   46%, `DataTransfer` and `Schemas` files in the 64–77% band). Pre-existing —
   Phase 7 touched no `Domain/` file — and surfaced by the first coverage run
   since the target was written. Needs its own task.
3. **Finding A3-1 — `#Index` on `consumptionDate`** — deferred by owner
   decision D-04 = `schedule`. It changes the model's schema hash, so it needs
   `SchemaV5` + a V4→V5 `MigrationStage` + migration tests, never an in-place
   edit of `SchemaV4`.
4. **Pre-GSD plan-0038 is still `in-progress`** in `docs/plans/INDEX.md`. Its
   remaining step is manual real-hardware verification (cold-install hitch feel,
   day-card insert/delete/duplicate animation feel), then removing the last
   diagnostic logger (`extendListWindow`). Note that the plan's own re-scope on
   2026-08-03 moved the History list back from `ScrollView`+`LazyVStack` to
   `List`, so its title in INDEX.md no longer describes the shipped shape.
