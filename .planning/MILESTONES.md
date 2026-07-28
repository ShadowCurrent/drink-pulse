# Milestones

## v1.2 Swift 6 + App-Target Hardening (Shipped: 2026-07-28)

**Phases completed:** 2 phases, 4 plans, 12 tasks

**Key accomplishments:**

- Flipped the drinkpulse app target to real Swift 6 strict concurrency (`SWIFT_VERSION = 6.0`, Debug + Release), fixing 21 isolation-gap sites (not the 2 the research run predicted) by restoring the codebase's existing `nonisolated`/`Sendable` convention, and justified all 4 pre-existing `@unchecked Sendable` suppressions with concurrency-safety rationale.
- Applied the SWIFT6-03 decision (keep XCTest for `measure {}` performance tests), ran the full Debug+Release build and coverage gate proving no regression after the Swift 6 flip (93.14% overall coverage), and brought architecture.md/DEVLOG.md/current-focus.md up to date — closing Phase 2.
- Removed the `@Query`-driven reverse-write of `onboardingDone` in `RootShellView`; `UserProfileStore.fetchOrCreate` now saves its insert immediately, closing the timing gap that made the reverse-write look necessary in the first place.
- Moved `ModelContainer` creation off the synchronous `App.init` path into a `.task`-driven `ContainerLoadState` state machine, and replaced both `fatalError` container-failure crashes with a full-screen, retryable `StartupErrorView`.

---

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
