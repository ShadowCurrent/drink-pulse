# 0001 — Retrospective

**Completed**: 2026-05-30

## What went well

- The `DashboardViewModel` architecture (injected events + profile, no SwiftData inside the VM) proved sound — all downstream plans (0011, 0012, 0018) reused the same pattern without changes.
- Test-first on the VM caught the `currentStreakDays` edge case (empty events returning 366) before it reached production.
- Freezing the plan and creating new focused plans (0007–0018) for the visual redesign was the right call. The frozen plan remained a clear contract; the sub-plans stayed small and reviewable.
- 220 tests green at close. All layers meet the ≥90% coverage target.

## What went wrong / surprises

- `Color(.quinarySystemFill)` does not exist in UIKit — had to fall back to `.quaternarySystemFill` for future bar chart entries. Discovered at build time; minor.
- The Claude Design handoff bundle arrived the day after the plan was frozen, expanding visual scope substantially. Handled correctly by spinning off dedicated plans rather than reopening the frozen plan — but the mismatch between the original plan's scope and the final delivered state is significant.
- `weeklyGrams` definition was ambiguous in the plan ("events ≥ 7 days ago") but implemented as a calendar week (Mon–Sun) for chart coherence. Should have been explicit in the plan.

## Decisions made during execution

- **`weeklyGrams` = calendar week (Mon–Sun)**, not rolling 7-day window. Ring and bar chart share the same domain; more coherent UX.
- **Guideline alert card** — rendered non-tappable; Q2 tap action remains deferred.
- **Spend card** — hidden when no events have a `price` field (Q3: hide).
- **Currency** — `NumberFormatter` with `currencyCode` from `UserProfile.currency`; per-drink multi-currency deferred.
- **Sub-plan split (2026-05-19)** — visual redesign carved into plans 0007, 0008, 0010, 0011, 0012, 0015 rather than extending this frozen plan.

## Leftover open questions

- **Q2 — Guideline alert card tap**: still no action. Options remain: switch to Settings tab, open guideline picker sheet, or leave tappable-but-no-op. Tracked in open-questions.md.
- **Multi-currency spend**: each `ConsumptionEvent` currently inherits `UserProfile.currency`. If drinks in different currencies are logged, aggregation is undefined. Requires a separate migration plan before multi-currency support.
