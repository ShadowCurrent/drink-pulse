# Alcohol-free day rule — design (port step 10)

Date: 2026-11-26
Status: awaiting owner approval
Size: small change (one shared Domain rule + three call sites + one display tweak)

## Intent

Port step 10 of plan 0040. The alcohol-free numbers (Insights "Alcohol-Free Days",
"Longest Alcohol-Free Streak"; Today "Alcohol-Free Streak", "Alcohol-Free This Month")
are computed today by three separate pieces of code with three different rules. The owner
wants one rule, written down, so the numbers cannot drift between screens ("nie chcę żeby
się w tej logice coś popierdoliło"). The owner hand-verifies every calculation change.

## Goals

- One rule decides, for every calendar day: does it count, is it alcohol-free, is it heavy.
- Insights and Today use that rule; no screen keeps its own copy.
- The rule and the heavy-day threshold are documented in `docs/domain.md`.

## Non-goals

- No change to grams, density, guideline limits, averages, totals, charts, calories,
  spend, "Highest Day", or the weekly summary notification.
- No per-guideline or per-sex heavy-day threshold.
- No "drinking session across midnight" handling: a day is a calendar day.

## Anti-goals

- A day before the person started logging counted as alcohol-free.
- An unfinished day counted as alcohol-free (the number would rise in the morning and
  fall in the evening).
- Two screens showing different answers for the same day.

## The rule (owner decisions, 2026-11-26)

1. **Start.** Counting starts on the calendar day of the first logged event of any kind,
   0 % ABV included (same as the existing Today "Alcohol-Free This Month"). Days before it
   count neither as alcohol-free nor toward the total. No events → nothing counts.
2. **Finished days** (before today, on or after the start) count normally: alcohol-free
   when their grams are 0, otherwise a drinking day.
3. **Today.** Today counts at once if it already has alcohol (grams > 0). Today without
   alcohol counts only once it is over (it becomes "yesterday" after midnight).
4. **Future days** never count.
5. **Heavy day.** WHO "heavy episodic drinking": **≥ 60 g** of pure alcohol in the day,
   one threshold for everyone. Grams use the display-unit density, the same convention as
   the guideline-limit comparison (`domain.md`: 0.8 in UK-units mode, 0.789 otherwise).
   Today counts as heavy as soon as it reaches 60 g. Unchanged from current behaviour;
   only documented now.

## Approaches considered

1. **One shared rule in `Domain/` (picked by the owner).** A pure value type with no
   SwiftUI or SwiftData; Insights and Today call it. Cost: Domain layer → 100 % coverage
   and a full-suite run before the step closes (AGENTS.md escalation).
2. Patch the three call sites separately. Smaller diff, but three copies of one rule —
   the drift the owner wants to prevent.
3. Today reads numbers from `InsightsViewModel`. Rejected: Today has no period/offset;
   it would couple two screens artificially.

## Effects per screen

| Place | Change |
|---|---|
| Insights "Alcohol-Free Days" (x/y) | y = counted days in the period; x = alcohol-free counted days |
| Insights "Longest Alcohol-Free Streak" | longest run of alcohol-free counted days in the period |
| Insights "Heavy Days" | unchanged logic; threshold moves to the shared rule |
| Today "Alcohol-Free Streak" | still counts back from yesterday; now stops at the start day (fixes ~365/366 for people who log only 0 % drinks); no 365-day cap |
| Today "Alcohol-Free This Month" | today no longer counted while it has no alcohol |
| Insights period with 0 counted days | "Alcohol-Free Days" and "Longest Alcohol-Free Streak" show "–" (the placeholder "Highest Day" already uses), no percent |

## Hand-verification examples

Today is Thursday 2026-11-26, weeks start Monday (week = Mon 23 – Sun 29 Nov). "Beer" =
500 ml × 5 % (19.725 g, or 20.0 g in UK-units mode).

| # | Data | Metric | Now | New |
|---|---|---|---|---|
| 1 | First log: beer Wed 25. Nothing today. | Insights week free days | 3/4 (75 %) | 0/1 (0 %) |
|   |   | Insights week longest streak | 2 days | 0 days |
|   |   | Today month count | 1 | 0 |
|   |   | Today streak | 0 | 0 |
| 2 | First log: 0 % beer Wed 25 only. Nothing today. | Insights week free days | 4/4 | 1/1 |
|   |   | Today streak | 366 | 1 |
|   |   | Today month count | 2 | 1 |
| 3 | Logging since 1 Oct; in November alcohol only on Sat 21. Nothing today. | Insights week free days | 4/4 | 3/3 |
|   |   | Insights week longest streak | 4 days | 3 days |
|   |   | Today streak | 4 (Sun–Wed) | 4 |
|   |   | Today month count | 25 | 24 |
| 4 | As 3, plus 70 g logged today at 20:00. | Insights week free days | 3/4 | 3/4 |
|   |   | Insights heavy days | 1 | 1 |
|   |   | Today streak | 0 | 0 |
|   |   | Today month count | 24 | 24 |
| 5 | As 3, but viewed Monday 23 Nov morning, nothing logged that day. | Insights week free days | 1/1 (100 %) | – (no percent) |
|   |   | Insights week longest streak | 1 day | – |
| 6 | Previous week (16–22 Nov); first log ever: beer Thu 19. | Insights free days | 6/7 | 3/4 |
|   |   | Insights longest streak | 3 days | 3 days |
| 7 | One day: 1500 ml × 5 %. | Heavy day, grams mode (59.175 g) | no | no |
|   |   | Heavy day, UK-units mode (60.0 g) | yes | yes |

## Decided by the builder (Claude's calls, open to owner correction)

- Placeholder for 0 counted days is "–" (en dash, matching "Highest Day").
- Today streak has no 365-day cap; the start day bounds it.
- Names, file split and signatures of the Domain type are left to the plan.

## Constraints

- Domain type is pure (Foundation only), `Sendable`, tested with real inputs, 100 %
  coverage. Calendar is injected; day boundaries via `Calendar.startOfDay`.
- Existing tests that pin the old behaviour (e.g. `drinkFreeDays_allFreeWhenNoEvents`)
  are updated to the new rule, not deleted silently.
- Changed displayed values need a UI test (AGENTS.md).
- Living docs in the same change: `docs/domain.md` (rule + heavy threshold),
  README / PROJECT.md if they describe these metrics.
- Full test suite before merge (Domain change).
