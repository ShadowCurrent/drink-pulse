# Deferred Items — Phase 05 (Insights Chart Scrubbing)

Out-of-scope discoveries logged during execution, per the executor's scope
boundary rule (only auto-fix issues directly caused by the current task's
changes; pre-existing issues in unrelated files are logged here, not fixed).

## 05-01

- `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift` is
  319 lines, over the project's 300-line file-size ceiling (CLAUDE.md). This
  file was not touched by plan 05-01 (Insights chart scrubbing) — pre-existing
  and unrelated to this plan's scope. Flagged here for a future cleanup task.
