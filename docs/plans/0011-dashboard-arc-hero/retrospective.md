# Retrospective — Plan 0011

**Closed**: 2026-05-21
**Size**: medium (estimated) / medium (actual)

## What went well

- The three-file split (DPChip / DashboardChipRow / DashboardHeroCard) kept each file well under 100 lines and made Previews trivial.
- `todayPct` being unclamped in the VM and clamped at the arc layer was the right call — it meant the high-risk pill logic was a simple `> 1.0` check with no duplication.
- Risk-based arc colour (low/moderate/high) ended up more expressive than "theme primary" default from Q2 in the plan. Good that it was a question rather than a hard decision.
- Streak equal-height fix (`maxHeight: .infinity`) was a one-line change that required zero API additions.

## What could be improved

- Q2 (arc colour strategy) was listed as open in the plan but the answer was implicit in `DashboardHeroCard`'s `arcColor` property. Future plans should pre-resolve these during the draft phase rather than leaving them as execution surprises.

## Decisions made during execution

- **Arc colour = risk-based** (Q2 option B, not the default A). Chosen because risk-colour alignment felt more meaningful than brand-primary, especially in Forest theme where primary is already greenish.
- **`effectiveRiskLevel`** (worst of daily + weekly) added to the VM as a clean way to drive the header `RiskBadge` without duplicating threshold logic in the view.

## Links

- [[plan-0001]] — Dashboard Redesign (parent epic; still open pending plan-0012+)
- [[plan-0007]] — Design System (arc + glass card primitives used here)
- [[plan-0012]] — Insights screen (Spend metric lives there)
