# 0001 — Execution Log

---

## 2026-05-18 — Implemented in one pass

### Done

- `DesignSystem/DPColors.swift` created with 5 fixed accent colours (`dpTeal`, `dpAmber`, `dpRed`, `dpPurple`, `dpGreen`). Adaptive card colour omitted — `Color(.secondarySystemBackground)` used inline throughout.
- `Features/Dashboard/DashboardViewModel.swift` created. `@Observable @MainActor final class` with all properties from the plan. `weekStartsOnMonday: Bool = true` param wired for future configurability from `UserProfile`.
- `drinkpulseTests/DashboardViewModelTests.swift` created with 16 tests covering all plan-required cases. Manually registered in `project.pbxproj` (test target uses explicit file refs, not file-system sync).
- `Features/Dashboard/DashboardView.swift` fully rewritten. Subcomponents: `RiskBadge`, `MetricCard`, `WeeklyGoalCard` (ring + bar chart), `StreakCard`, `GuidelineAlertCard`.
- `Localizable.xcstrings` — 14 new keys (en/de/pl): greeting × 3, risk × 3, metric × 4, weeklyGoal, streak × 2, alert title.
- 52/52 tests green, 0 build warnings.

### Deviations from plan

- **`weeklyGrams` definition** — plan says "sum for events ≥ 7 days ago" (rolling window). Implemented as current week (Mon–Sun) via `Calendar.dateInterval(of: .weekOfYear)` so the ring and bar chart share the same domain. More coherent UX; documented here.
- **Guideline alert card** — Q2 deferred (user has Figma design). Card is rendered as non-tappable placeholder.
- **Spend card** — hidden when no events have `price` (Q3: hide). Currency formatted via `NumberFormatter.currencyCode` from `UserProfile.currency`.
- **Subcomponents** — kept as private structs inside `DashboardView.swift` (as planned). File exceeds 200-line guideline due to inherent view complexity; acceptable trade-off.
- **`Color(.quinarySystemFill)`** — does not exist in UIKit. Replaced with `Color(.quaternarySystemFill)` for future bars.
- **`currentStreakDays` when events empty** — returns 0 (plan didn't specify; loop would otherwise return 366). Added `if events.isEmpty { return 0 }` guard.

### Open questions resolved

- Q1: No name field — greeting is time-based only.
- Q3: Spend card hidden when no prices.
- Q4: `NumberFormatter` with `currencyCode`; multi-currency (per-drink) deferred to a later plan.

### New open questions

- Multi-currency spend: each `ConsumptionEvent` should eventually have its own `currency` field. When currencies differ from `UserProfile.currency`, aggregation is undefined. Defer to a separate plan.

### Results

- Build: succeeded, 0 warnings
- Tests: 52/52 passed (16 new in DashboardViewModelTests)
