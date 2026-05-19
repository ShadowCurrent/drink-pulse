# 0015 — Risk language: rename "Safe" to "Low Risk"

**Status**: draft
**Size**: small
**Created**: 2026-05-19

## Summary

Replace the user-facing "Safe" risk label everywhere it appears with
"Low Risk". Alcohol consumption is never medically "safe" — every major
guideline (WHO, NHS, NIAAA, DHS) phrases the bottom band as low-risk, not
no-risk. The other two bands ("Caution", "Exceeded") are renamed to
"Moderate Risk" and "High Risk" for symmetry.

The `RiskLevel` enum case names (`.safe`, `.caution`, `.exceeded`) stay
the same — they are internal API. Only the localized display strings change.

## Context

Came out of design-handoff review (2026-05-19). The design uses
"Low / Moderate / High Risk" consistently across `RiskBadge`, the dashboard
header chip, the history calendar legend, and the Insights weekday-pattern
legend.

Current strings in `Localizable.xcstrings`:
- `dashboard.risk.safe`     → "Safe"
- `dashboard.risk.caution`  → "Caution"
- `dashboard.risk.exceeded` → "Exceeded"

## Scope

### In
- Update three string keys in `Localizable.xcstrings` for en, de, pl.
- Audit all call sites that surface those strings to confirm no concatenation
  surprises.
- No enum, view, or test changes beyond strings.

### Out
- Renaming the enum cases (unnecessary churn).
- Threshold changes — only labels move.

## Implementation steps

1. Edit `Localizable.xcstrings`:
   - en: Safe → "Low Risk", Caution → "Moderate Risk", Exceeded → "High Risk"
   - de: equivalent — "Geringes Risiko", "Mittleres Risiko", "Hohes Risiko"
   - pl: "Niskie ryzyko", "Umiarkowane ryzyko", "Wysokie ryzyko"
2. Grep for any hard-coded English literals matching the old labels and
   replace with `String(localized:)` references (there should be none).
3. Run UI Previews on `DashboardView` and `ConsumptionOverviewCard` for
   sanity check; verify `RiskBadge` width fits at largest Dynamic Type.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Localizable.xcstrings` | Modify |

## Open questions

- [ ] **Capitalisation in headline contexts**: keep title-case "Low Risk" or
  switch to "Low risk"? Default: title-case (matches the design).

## Tests required

- No unit tests (string-only change). Verify via Previews; existing snapshot
  / accessibility tests still pass.
