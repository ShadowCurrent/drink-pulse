# 0011 — Dashboard: arc-progress hero + chip refactor

**Status**: draft
**Size**: medium
**Created**: 2026-05-19

## Summary

Replace the dashboard's title-bar greeting + 2×2 metric grid with the
design's compact layout:

1. **Header** — greeting (left) + `RiskBadge` (right). Below it: date · guideline name.
2. **Hero card** — large numeric value (today's intake) + 240° arc gauge
   on the right showing percent-of-daily-limit. If risk is "high", an
   inline pill below the value says "⚠️ High risk".
3. **Chip row** — two `Chip` cards: Calories (amber), Drinks (purple).
   The Spend chip moves to Insights only (per design).
4. **This Week** card — keep existing `WeekBars`; lighten its title.
5. **Overview** card — keep existing today/7-day/30-day rows.
6. **Streak row** — two cards. Show *zero-state copy* instead of "0 days"
   when the user just drank today (matches design).
7. **Guideline alert card** — keep, only on `riskLevel == .exceeded`.

## Context

The current dashboard is dense and repeats today's number in the hero ring
and the Overview card. The design promotes the arc gauge as the hero and
collapses the metric grid to two chips, which scans faster on the 393pt
iPhone width and leaves room for the Streak row to breathe.

## Scope

### In
- `Features/Dashboard/Components/DashboardHeroCard.swift` — composes the
  arc gauge and the numeric value; consumes `DashboardViewModel`.
- `Features/Dashboard/Components/DashboardChipRow.swift` — two-chip layout.
- `Features/Dashboard/Components/DPChip.swift` — single chip view (icon,
  value, label).
- `DashboardView` — re-layout to match the design top-to-bottom.
- Zero-state streak copy:
  - `currentStreakDays == 0` → "Start today / no drinks = streak"
  - `currentStreakDays > 0`  → "N day streak" (unchanged)

### Out
- Removing the "Spend" metric entirely (it stays in Insights — see
  [[plan-0012]]).
- Arc gauge primitive itself — provided by [[plan-0007]].
- New section: 30-day sparkline (mentioned in design as a future polish
  idea; defer).

## Implementation steps

1. **`DPChip`** — `init(icon: String, value: String, label: String, accent: Color)`;
   uses `dpGlassCard()`.
2. **`DashboardHeroCard`** — left column with localized "Today's Intake"
   eyebrow + 36pt bold value + "of N {unit} daily limit" + inline high-risk
   pill (when applicable). Right column: `DPArcProgress` 100pt size with
   `Math.round(pct * 100)` centred.
3. **Header refactor** — keep `RiskBadge`; greeting becomes 22pt bold with
   weather-emoji prefix from the existing `vm.greetingText`.
4. **Chip row** — replace `metricsGrid` (LazyVGrid) with two-`DPChip`
   `HStack`. Delete the spend `MetricCard` from Dashboard (it moves to
   Insights).
5. **Streak row** — modify `StreakCard` API to accept an optional
   `zeroStateCopy: String?`. Or introduce two-case rendering inline.
6. **VM additions** — none beyond what's already there. `riskLevel`,
   `todayGrams`, `effectiveDailyLimitGrams`, `currentStreakDays`,
   `soberDaysThisMonth` are already exposed.
7. **Tests** — extend `DashboardViewModelTests`:
   - Hero pct = todayGrams / effectiveDailyLimitGrams; clamps at 100% for
     gauge but raw value still surfaces for the high-risk pill.
   - Zero-state copy selection: just verify the boolean — view tests via
     Previews.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Features/Dashboard/Components/DashboardHeroCard.swift` | Create |
| `drinkpulse/Features/Dashboard/Components/DashboardChipRow.swift` | Create |
| `drinkpulse/Features/Dashboard/Components/DPChip.swift` | Create |
| `drinkpulse/Features/Dashboard/DashboardView.swift` | Modify |
| `drinkpulse/Features/Dashboard/Components/DashboardMetricCards.swift` | Modify (StreakCard zero state) |
| `drinkpulseTests/DashboardViewModelTests.swift` | Append cases |
| `drinkpulse/Localizable.xcstrings` | Add keys |

## Open questions

- [ ] **Q1 — Spend card removal from Dashboard**: confirmed by user per
  transcript ("Spend chip removed; lives in Insights only").
  - A) Remove from Dashboard (default — matches design)

- [ ] **Q2 — Arc colour when below 50%**: use `dpRiskLow` (green) or theme
  primary?
  - A) Theme primary (default — keeps green for *high risk = bad*)
  - B) Risk-low green (matches Health app)
  - Note: in Forest theme, primary is greenish — picking A keeps the green
    family but is brand-aligned.

- [ ] **Q3 — "Daily limit" copy** when guideline.daily == 0 (UK): show
  "of N {unit} daily average" instead of "daily limit". Default: A.

- [ ] **Q4 — Hero arc when over 100%**: clamp sweep at 100% (design) or
  overshoot ring with a danger stripe?
  - A) Clamp + show "High risk" pill (default)

## Tests required

- View-level via Previews (high/medium/low risk; zero events; over limit).
- VM tests for clamping pct at the view layer and the badge inclusion rule.

## Future links

- [[plan-0007]] — `DPArcProgress`, `dpGlassCard`.
- [[plan-0012]] — Spend lives there now.
- [[plan-0015]] — Risk badge label rename.
