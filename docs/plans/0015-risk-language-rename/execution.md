# 0015 — Execution Journal

_Append-only. Newest entry at the bottom._

---

## 2026-05-19

**What was done**

- Discovered the plan's "Current strings" section listed "Safe / Caution / Exceeded" but actual en values were "On track / Watch out / Over limit". The intent of the plan (align with design's Low/Moderate/High Risk language) was still correct; noted the discrepancy here per immutability rules.
- Updated `Localizable.xcstrings` — three keys, all three locales:
  - `dashboard.risk.safe`:     "On track" → "Low Risk" / "Im Rahmen" → "Geringes Risiko" / "W normie" → "Niskie ryzyko"
  - `dashboard.risk.caution`:  "Watch out" → "Moderate Risk" / "Aufpassen" → "Mittleres Risiko" / "Uważaj" → "Umiarkowane ryzyko"
  - `dashboard.risk.exceeded`: "Over limit" → "High Risk" / "Limit überschritten" → "Hohes Risiko" / "Powyżej normy" → "Wysokie ryzyko"
- Audited all Swift call sites: all three keys are consumed via `String(localized:)` in `DashboardView.swift:161-163`; no hard-coded literals found.
- Build: clean (0 errors, 0 warnings).
- File sizes: no Swift file over 300 lines.

**Open question resolved**

Capitalisation: title-case ("Low Risk") used as per plan default; matches the design handoff.
