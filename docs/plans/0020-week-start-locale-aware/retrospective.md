# 0020 — Retrospective

**Completed**: 2026-06-01
**Size**: small (actual effort matched estimate)

## What went well

- Plan had already verified the exact scope (only `weekInterval` + its consumers).
  No surprises during implementation.
- Making `calendar` an injectable `var` (not a private computed property) cost nothing
  extra and gave the tests clean injection points without mocks.
- The two locale-aware regression tests use a pinned date (2026-05-27) and a pinned
  event (2026-05-24) so they will never become flaky as time passes.

## What could be improved

- Two pre-existing InsightsViewModel test failures (`monthSpend_sumsAllPricesInActivePeriod`,
  `bingeEpisodes_twoDaysAboveThreshold_countsBoth`) were discovered during testing.
  These should be fixed in a future task so the baseline is clean.

## Decisions

- Used `Calendar(identifier: .gregorian)` with explicit `firstWeekday` in tests rather
  than `Calendar.current` + override, to avoid any ambient locale influence on the test
  machine. This makes the test calendar fully deterministic.
