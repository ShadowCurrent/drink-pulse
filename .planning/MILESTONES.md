# Milestones

## v1.4 iOS 27 Migration & Modernization (Shipped: 2026-11-18)

**Phases completed:** 4 phases (08–11), 56 plans, 59 tasks
**Timeline:** 2026-09-16 → 2026-11-18 (64 days), 430 commits
**Closeout type:** override_closeout (no milestone audit run; phases 08 and 10 verification stale, phase 09 gaps_found with the owner-deferred D1 exception)
**Known verification overrides:** 10 newly acknowledged, 0 carried forward from a prior close (see STATE.md Deferred Items)
**Requirements:** 13/13 checked off (PLAT-01–02, MOD-01–05, DATA-01, INT-01–02, VER-01–03), several with named exceptions

**Key accomplishments:**

- App and both test targets require iOS 27.0; Xcode 27.2 / Swift 6.4.2 toolchain recorded, with a complete source-backed inventory of every production and test area and owner decisions C001–C012 before any modernization.
- Approved SwiftUI changes applied: Dashboard strict-concurrency fix, one sheet-root `DismissAction` for Add Drink, `GuidelineLimits` isolation cleanup, and a VoiceOver dismissal test proven able to fail.
- V1, V2 and V3 SwiftData stores proven to migrate to V4 with every stored property intact; the owner's real store upgraded on device with 214 events preserved and a clean import round trip.
- Health edit-then-delete orphan (F2) and notification cancel-while-scheduling race (F3) fixed with regression tests; Thread Sanitizer clean over 21 suites.
- Notification delegate assigned synchronously in `App.init`: killed-app reminder taps now open Add Drink (owner device re-test 3 of 3, was 0 of 1).
- Warning-clean Debug and Release builds (app-owned deprecations 0); final full suite 888 tests with 4 known failures; per-screen accessibility audit classes plus a gated full audit passing 16/16, Reduce Motion gated through one seam, AX5 layouts fixed (ADR-0013).

### Known Gaps

- D1: cross-tab Liquid Glass flicker after Add Drink dismissal and the iOS 27 simulator `glassEffect` crash are deferred, not fixed (MOD-02 exception).
- VER-01: Domain coverage 90.06% against the 100% target; final-tree coverage not re-measured (historical 94.65% carried, D11-33); known failures DL-T01 to DL-T04.
- VER-02: limitations L-01 to L-09 (no backup-import UI test, partial edit coverage, simulator-only results).
- VER-03: open items CHK-00, CHK-01, CHK-02, CHK-10 (device needed), CHK-03, CHK-07 (DL-O19), OBS-A, OBS-C, verifier items T06, T08, T09, T16, T17, T28.
- Code-review debt DL-O26 to DL-O35 (D11-35).

---

## v1.3 Native Feel (Shipped: 2026-07-31)

**Phases completed:** 3 phases, 6 plans, 12 tasks

**Key accomplishments:**

- LaunchIcon/LaunchBackground Asset Catalog entries wired through a standalone `drinkpulse/Info.plist`'s `UILaunchScreen` dict (Pattern 2 fallback), replacing the auto-generated blank launch screen -- Tasks 1-2 complete and committed; Task 3's real-device cold-launch verification is a blocking checkpoint awaiting human execution (round 8: abandoned the dual-appearance solid-background `LaunchIcon` approach after round 7's dark-mode-only symptom persisted through an install-time cache-bust -- external precedent points to a real Apple platform limitation around per-appearance IMAGE selection specifically, unlike COLOR selection. Reverted to a single, appearance-independent, genuinely-transparent icon, relying on `LaunchBackground`'s already-proven-reliable color switching instead. Also enlarged the icon from 60pt to 84pt (@2x: 120px -> 168px) per explicit, confirmed user request -- a deliberate deviation from D-03's original "exact Home-Screen-icon size match" wording. Round 9: enlarged the icon a further 3x to 252pt (@2x: 504px), and -- as an explicit, user-authorized exception to two of this plan's own prohibitions -- added a persistent icon overlay to `drinkpulseApp.swift`'s `.loading` state to bridge the now-visible seam between the branded launch screen and the app's first live frame, without touching the `.loading` background value or any startup timing/logic. Round 10: root-caused a reported size-mismatch/pixelation between the two icon appearances to `LaunchIcon.imageset` declaring only a single "2x" scale entry -- completed the scale set to standard 1x/252px, 2x/504px, 3x/756px, regenerated from a higher-fidelity native source to avoid a fourth generation of upsample loss. Round 11: pixelation resolved, but the size mismatch persisted -- removed the round-10-added `1x` bucket (dead weight, since no supported device is ever 1x scale) as a working hypothesis for the early-boot launch compositor mis-resolving an unnecessary scale bucket, keeping only 2x/3x; honestly flagged as a strong hypothesis, not a certainty, since this cannot be fully verified without real hardware.
- Native `chartXSelection` drag-to-scrub wired into both Insights charts, with `InsightsHeroCard`'s headline following the touched point and reverting on release — proven end-to-end by two real drag-driven XCUITests.
- Both Insights charts gain a full `AXChartDescriptorRepresentable` conformance wired via `.accessibilityChartDescriptor(_:)`, giving VoiceOver users a drag-gesture-independent audio-graph path to every plotted point, formatted through the exact same closures already driving each chart's visual callout.
- Closed UAT gaps G-05-2 and G-05-3 by giving both Insights charts' scrub callout real vertical headroom (`.chartYScale(domain: 0...yDomainUpperBound)`) and rescoping their selection `.animation` from the whole `Chart` view onto just the callout's own modifier chain — the two root-cause mechanisms confirmed in `.planning/debug/insights-chart-scrub-callout-flicker-clip.md`.
- Moved both Insights charts' scrub annotation from an unbounded RuleMark onto a PointMark at the selected datum, and replaced the invisible Liquid-Glass callout background with a new opaque-Color `dpChartCalloutBackground()` modifier — closing UAT gaps G-05-4 (constant marker height) and G-05-5 (illegible callout).
- Directional `.asymmetric` move transition wired into `HistoryView` via a single synchronous `selectSegment(_:)` entry point, gated by `accessibilityReduceMotion`, plus 6 new automated tests (2 unit + 4 UI) covering direction correctness, rapid/alternating taps, the empty state, and a larger dataset.

---

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
