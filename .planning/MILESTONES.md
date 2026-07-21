# Milestones

## v1.1 Weekly Summary Notification (Shipped: 2026-07-21)

**Phases completed:** 2 phases, 6 plans, 13 tasks

**Key accomplishments:**

- Pure, Foundation-only week-over-week content classifier (skip/directionOnly/percentage) plus the two AppStorage keys and all 13 Localizable.xcstrings entries the rest of the weekly-summary-notification phase needs.
- `Services/` layer notification scheduler mirroring `ReminderService`'s shape, sourcing content from `WeeklySummaryCalculator` and fetching current/prior-week `ConsumptionEvent`s directly via SwiftData, always summing physical `pureAlcoholGrams` (never a display-mode density).
- Wired the weekly-summary notification's tap destination (Insights tab) and its foreground-recompute trigger into NotificationActionHandler and RootShellView, mirroring the existing daily-reminder pattern exactly.
- New `WeeklySummarySection` Settings card (mirrors `ReminderSection` minus the time picker) plus an independent Weekly Summary toggle folded into the existing Onboarding `HealthStep` panel — the only two user-facing ways to opt into ENGG-01/ENGG-02.
- Closed all three Wave-0 UI test gaps (ENGG-01, ENGG-02, ENGG-07) with three new XCUITest files plus a launch-argument-gated cold-launch tap-simulation hook for the untestable UNNotificationResponse path
- HealthStep's onboarding weekly-summary toggle-off now calls WeeklySummaryService.cancel() via a constructor-injected instance, proven by a new HealthStepTests unit test reusing FakeNotificationCenter.

---
