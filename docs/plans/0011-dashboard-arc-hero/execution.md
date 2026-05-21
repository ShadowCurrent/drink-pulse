# Execution Journal — Plan 0011

Append-only. Dated entries only.

---

## 2026-05-21

Starting implementation.
Files: DashboardViewModel (todayPct) → DPChip → DashboardChipRow → DashboardHeroCard
→ DashboardMetricCards (StreakCard zero-state, remove MetricCard) → DashboardView
→ Localizable.xcstrings → DashboardViewModelTests.

---

## 2026-05-21 (close)

All plan deliverables shipped and verified.

**Implemented:**
- `DashboardHeroCard` — left column (eyebrow, 36pt value, limit copy, high-risk pill when `todayPct > 1.0`) + right `DPArcProgress` (100pt). Arc colour is risk-based (`dpRiskLow / dpRiskModerate / dpRiskHigh`).
- `DashboardChipRow` + `DPChip` — two chips: Calories (amber) + Drinks (purple). Spend removed from Dashboard per design.
- `DashboardViewModel` additions: `todayPct` (raw, unclamped), `todayRiskLevel`, `effectiveRiskLevel` (worst of daily + weekly — drives header badge).
- `StreakCard` `zeroStateCopy` API — flame card shows "Start today" copy when streak = 0.
- `DashboardView` refactored to: header (greeting + `RiskBadge`) → hero → chip row → overview → week bars → streak row → alert card.
- Streak row equal-height fix: `maxHeight: .infinity` on `StreakCard` so both cards match the taller one.

**Tests added** (`DashboardViewModelTests`): `todayPct` (zero, half, raw > 1.0), `todayRiskLevel` (safe/caution/exceeded), `effectiveRiskLevel` (daily exceeded, weekly exceeded, both low). 140/140 passing.

**Deviations from plan:**
- None material. Arc colour changed from "theme primary" (Q2 default) to risk-based colours — this was the actual shipped outcome agreed during the session.

**Plan closed.**
