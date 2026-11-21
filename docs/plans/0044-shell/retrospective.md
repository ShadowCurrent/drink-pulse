# 0044 — Retrospective

**Completed**: 2026-11-21 (scoped gate run and coverage deferred by the owner)

## What went well
- The shell no longer writes into the tabs: each logging screen owns its `+`, Settings has none,
  and the sheet and the haptic stay in one place behind two environment actions.
- The over-limit haptic reuses `DashboardViewModel.todayPct`, so the haptic and the Today hero
  cannot disagree; six unit tests pin the edge cases from the review focus.
- An explicit `drinkLogged` action instead of a store-count trigger kept imports, the Health
  backfill and seeding silent by design.

## What went wrong / surprises
- Two UI tests were wrong at first (one passed vacuously, one matched a category name that
  History does not show); both caught by watching RED.
- The audit baseline in open-questions was incomplete; checking against the pre-step code took a
  temporary checkout of the old sources.
- A large combined `RunSomeTests` call failed with an incomplete result bundle; smaller batches
  work.
- Two edits were made with a shell script instead of Xcode MCP.

## Decisions made during execution
- Settings audit calls get no bar-control keys; the shared home / settings case was split.
- `HealthWriteHooks.write` stays outside `withMotion` (not a view-state change).
- Fetch-error log interpolates only the error type name, `privacy: .public`.

## Follow-ups
- Run the Step 2 scoped gate (all Task 1–4 classes + `DashboardUITests`, `InsightsUITests`,
  `HistoryInteractionUITests`) in batches of about 10 classes.
- Owner device check (haptic, `+` placement, Large Content Viewer, motion).
- Final whole-branch review was not run.
