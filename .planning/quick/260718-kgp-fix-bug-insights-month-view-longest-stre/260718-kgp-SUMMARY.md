---
status: complete
phase: quick-260718-kgp
plan: 01
requirements:
  - BUGFIX-insights-longest-streak-future-days
commits:
  - af4f023 "[quick-260718-kgp] fix longestSoberStreak counting future days in Month/Week view"
  - 840d164 "[quick-260718-kgp] add UI test for Month-view Longest Streak future-day exclusion"
  - 62394d5 "[quick-260718-kgp] record Insights Longest Streak future-days fix in DEVLOG"
---

# Summary: Fix Insights Month view Longest Streak future-days bug

## What was done

Fixed a bug where the Insights tab's "Longest Streak" card (Month period, also
latent in Week) counted days after "today" as sober days, because they carry
zero grams. On July 18 in a 31-day month this inflated the streak by up to 13
phantom days.

**Root cause:** `InsightsViewModel.activeDays` deliberately keeps the full
calendar grid for `.week`/`.month` (so the area chart isn't a stub mid-period).
`longestSoberStreak` (in `InsightsViewModel+HealthMetrics.swift`) iterated
`activeDays` directly, so it ran through the unelapsed tail of the period as
well. Year/All-Time were already safe (`effectiveDateRange` clamps those to `now`).

**Fix:** added `InsightsViewModel.elapsedDays` (`activeDays` filtered to
`<= startOfDay(now)`, placed right after `activeDays`, not cached — a cheap
filter over the already-cached list). `longestSoberStreak` now iterates
`elapsedDays` instead of `activeDays`. No-op for past periods and Year/All-Time;
`effectiveDateRange`, `activeDays`, the chart, and every other metric are
untouched.

## Tasks completed

1. **Fix + unit regression tests** (commit `af4f023`)
   - `drinkpulse/Features/Insights/InsightsViewModel.swift` — new `elapsedDays`
     computed property.
   - `drinkpulse/Features/Insights/InsightsViewModel+HealthMetrics.swift` —
     `longestSoberStreak` reads `elapsedDays`.
   - `drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift` —
     `longestSoberStreak_monthExcludesFutureDays` (18 not 31),
     `longestSoberStreak_monthStreakEndsAtToday_notEndOfMonth` (13 not 26), and
     renamed/re-asserted `longestSoberStreak_fullWeekWhenNoEvents` →
     `longestSoberStreak_noEvents_spansAllElapsedDaysOfWeek` (elapsed-day
     invariant instead of a hard-coded 7).

2. **UI test on the real Month view** (commit `840d164`)
   - New `drinkpulseUITests/Features/Insights/InsightsStreakUITests.swift` —
     `test_monthView_longestStreak_excludesFutureDays` drives the Insights
     Month view with the existing multiday seed and asserts the rendered
     "Longest Streak" value against an elapsed-only computation mirroring
     production `elapsedDays` + `longestSoberStreak`. Split into its own file
     (rather than appended to `InsightsUITests.swift`) to stay under the
     300-line ceiling; confirmed it appears in the test log by name and passes.

3. **End-of-task gates + DEVLOG entry** (commit `62394d5`)
   - Full `xcodebuild build`: zero warnings.
   - Full `xcodebuild test` (unit + UI): `** TEST SUCCEEDED **`.
   - Coverage: app 93.42% overall; `InsightsViewModel+HealthMetrics.swift` 100%;
     `InsightsViewModel.swift` 94.92% (both ≥ targets).
   - File-size check: no production file > 300 lines.
   - No force-unwraps introduced.
   - `docs/DEVLOG.md` entry appended (2026-07-18 15:25).

## Key decisions

- Scoped the fix strictly to `longestSoberStreak`, per the frozen plan's
  non-goals: `effectiveDateRange` and `activeDays` were not touched (the full
  week/month grid is intentional for the chart), and no other metric was
  changed.
- `drinkFreeDays` has the identical latent full-grid behaviour (its "X/Y"
  denominator also includes future days), but fixing it was explicitly out of
  scope for this bug fix. Flagged in DEVLOG as an owner follow-up.
- The pre-existing `longestSoberStreak_fullWeekWhenNoEvents` test asserted a
  hard-coded `== 7`, which was itself an artifact of the bug (only true on the
  week's last day) and would have become flaky post-fix — updated to assert
  the elapsed-day invariant instead of weakening the test.
- Split the new UI test into its own file (`InsightsStreakUITests.swift`)
  rather than exceeding `InsightsUITests.swift`'s 300-line ceiling.

## Open questions / follow-ups

- `drinkFreeDays` (Insights Health Impact card) counts future days in its "X/Y"
  denominator during the current week/month — same root cause, deliberately
  left unfixed here. Needs an owner decision on whether to apply the same
  `elapsedDays` fix or leave the denominator as "days in period".

## Verification

- `xcodebuild build -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` — clean, zero warnings.
- `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -enableCodeCoverage YES -derivedDataPath build/` — `** TEST SUCCEEDED **`.
- `xcrun xccov view --report --only-targets build/Logs/Test/*.xcresult` — drinkpulse.app 93.42% (9051/9689).
- `find drinkpulse -name "*.swift" -not -path "*/Preview Content/*" | xargs wc -l | awk '$1 > 300 {print}'` — no output (clean).
