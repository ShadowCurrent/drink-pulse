# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.1 — Weekly Summary Notification

**Shipped:** 2026-07-21
**Phases:** 2 | **Plans:** 6 | **Sessions:** 2

### What Was Built
- `WeeklySummaryCalculator` — pure domain classifier for skip/direction-only/percentage week-over-week messaging, including the ±5% "about the same" band and zero-prior-week edge case
- `WeeklySummaryService` — `Services/` layer scheduler mirroring `ReminderService`'s shape, always summing physical `pureAlcoholGrams` (never a display-mode density)
- Settings (`WeeklySummarySection`) and Onboarding (`HealthStep`) opt-in surfaces sharing one `AppStorageKeys.weeklySummaryEnabled` key
- Tap-to-open routing to Insights via `NotificationActionHandler` + `RootShellView`
- Tech-debt closure (Phase 01.1): onboarding toggle-off now calls `WeeklySummaryService.cancel()`, closing the one real Settings/Onboarding parity gap found by the first milestone audit

### What Worked
- Reusing the existing `Services/` protocol-wrapped pattern (ADR-0008) for a second notification type required zero new architecture — `WeeklySummaryService` mirrors `ReminderService` almost 1:1
- Milestone audit (`/gsd-audit-milestone`) caught a real cross-surface inconsistency (Settings toggle-off called `.cancel()`, Onboarding didn't) that per-plan verification alone had missed, because each plan verified its own surface in isolation
- Decimal-phase insertion (01.1) closed that gap cleanly without reopening or amending the frozen Phase 1 plan — the fix, its test, and the two explicitly-accepted no-action items all landed in one small phase
- Constructor injection + convenience-init split (`HealthStep(onDone:weeklySummaryService:)` / `HealthStep(onDone:)`) made the fix unit-testable via the existing `FakeNotificationCenter` mock without touching production call sites

### What Was Inefficient
- The Settings/Onboarding parity gap could have been caught earlier if "toggle-off must mirror toggle-on's counterpart surface" had been an explicit acceptance criterion on Phase 1's plan for the Onboarding toggle, rather than discovered post-hoc by audit
- Swift's actor-isolation rules blocked the planned default-parameter-value init syntax (`weeklySummaryService: WeeklySummaryService = WeeklySummaryService()` inside a `@MainActor` init) — a one-off deviation, but worth flagging as a recurring risk for future `@MainActor`-service-injection plans

### Patterns Established
- Two independent opt-in notification surfaces (Settings + Onboarding) sharing one `AppStorageKeys` key is now the established convention for any future opt-in notification feature
- Constructor-injectable `@MainActor` services need a convenience init that constructs the default *inside the init body*, not as a default parameter value, when the service type itself is `@MainActor`-isolated

### Key Lessons
1. When a feature ships two parallel opt-in entry points (Settings + Onboarding), explicitly verify toggle-off symmetry between them in the same plan/verification pass — don't rely on a separate milestone audit to catch it
2. Decimal-phase insertion is the right mechanism for milestone-audit-flagged tech debt: small, scoped, doesn't reopen frozen plans, and can explicitly close no-action items (not just fix real bugs) so nothing lingers un-triaged

### Cost Observations
- Model mix: balanced profile — planner/executor/debugger on Sonnet, verifier/plan-checker on Haiku, integration-checker on Sonnet
- Sessions: 2 (Phase 1 delivery, Phase 01.1 tech-debt closure + audit + close)
- Notable: first GSD-managed milestone for this project (36 pre-GSD plans predate adoption) — no prior-milestone baseline to compare velocity against

---

## Milestone: v1.2 — Swift 6 + App-Target Hardening

**Shipped:** 2026-07-28
**Phases:** 2 | **Plans:** 4

### What Was Built
- App target flipped to real Swift 6 strict concurrency (`SWIFT_VERSION = 6.0`, Debug+Release), fixing 21 isolation-gap sites and justifying the 4 pre-existing `@unchecked Sendable` suppressions
- SWIFT6-03 decision applied and documented: kept XCTest for `measure {}` performance tests (no Swift Testing equivalent)
- Onboarding gate hardened to a single authoritative source of truth (`onboardingDone`, ADR-0012), removing the `@Query`-driven reverse-write that could kick a fully onboarded user back into `OnboardingView`
- `sharedModelContainer` creation moved off the synchronous `App.init` path into a `.task`-driven `ContainerLoadState` state machine
- Both `fatalError` container-failure crashes replaced with a retryable, non-PII `StartupErrorView`

### What Worked
- Restoring the codebase's existing `nonisolated`/`Sendable` convention (rather than introducing a new concurrency pattern) made the Swift 6 flip mechanical once the real isolation-gap count was known
- Phase ordering (Swift 6 flip before onboarding/container async work) paid off exactly as planned — the concurrency reasoning for Phase 3's async container load was done once, under real Swift 6 rules, with no rework
- Decimal-phase-style tight scoping (Cluster A only, Cluster B explicitly excluded) kept the milestone to pure internal hardening with a clean, auditable 6/6 requirements finish

### What Was Inefficient
- Research undercounted the isolation-gap fix scope by an order of magnitude (predicted 2 sites, actual 21) — the language-mode flip's blast radius should be estimated from a trial build, not a static read of the codebase, before committing to a plan-size estimate
- A post-execution code review found a critical gap (CR-01): the onboarding single-source-of-truth fix had landed on `UserProfileStore.fetchOrCreate` while the real completion path (`OnboardingViewModel.complete(into:)`) was a separate, uncalled function that still didn't save immediately — the fix "worked" against the wrong call site until code review caught it. Plan verification should trace the actual runtime call path, not just the function the plan named.

### Patterns Established
- ADR-0012 establishes the convention: a gate between two app states must have exactly one authoritative signal — no second live query or count may independently influence it, even as a "safety net"
- Async container startup via a small enum-based `ContainerLoadState` (loading/ready/failed) driven by a post-first-frame `.task` is now the pattern for any future SwiftData/CloudKit store-open work that must not block `App.init`

### Key Lessons
1. Before sizing a language-mode-flip plan (Swift 6, or any future strict-mode adoption), do a throwaway trial build first to get a real error count — a static/manual read of isolation boundaries reliably undercounts
2. When a fix targets "the call path that does X," verify by tracing from the actual UI trigger to the mutating function, not by matching a function name that looks like it does X — a plausible-but-uncalled function is an easy miss for both execution and per-plan verification

### Cost Observations
- Model mix: balanced profile — planner/executor on Sonnet, verifier/plan-checker on Haiku
- Sessions: 2 (Phase 2 Swift 6 migration, Phase 3 app startup hardening + post-review fix)
- Notable: fastest milestone timeline yet (~1 day wall-clock, 2026-07-27 → 2026-07-28) for 2 phases / 4 plans — internal hardening with no new UI surface kept iteration tight

---

## Milestone: v1.3 — Native Feel

**Shipped:** 2026-07-31
**Phases:** 3 | **Plans:** 6

### What Was Built
- Branded static launch screen: `LaunchIcon`/`LaunchBackground` Asset Catalog entries wired through a standalone `Info.plist`'s `UILaunchScreen` dict, replacing the auto-generated blank screen
- Native `chartXSelection` drag-to-scrub on both Insights charts, with the hero card headline following the touched point and reverting on release
- Full `AXChartDescriptorRepresentable` VoiceOver audio-graph parity for both charts, independent of the drag gesture
- Directional `.asymmetric` move transition on History's List↔Calendar segmented control, gated by `accessibilityReduceMotion`

### What Worked
- Independent, no-shared-state phase design (Phase 4/5/6 declared zero dependencies on each other) meant a 19-round real-device debug saga on Phase 4 never blocked or delayed Phase 5/6, which shipped on schedule in parallel timeline
- UAT-driven gap closure on Phase 5 (05-03, 05-04) caught real visual bugs (callout clipping, invisible Liquid-Glass background, constant marker height) that automated tests alone would have missed — chart scrubbing is inherently a visual/gestural feature
- Reusing the existing `AXChartDescriptorRepresentable` pattern for a second chart type (`WeekdayBarChart` after `AlcoholAreaChart`) was mechanical once the first was proven

### What Was Inefficient
- Phase 4's launch-icon debugging ran 19 real-device rounds before the actual root cause (iOS 26 SpringBoard's own app-icon launch-zoom animation, not the app's asset) was found — 13 of those rounds edited the wrong asset on the strength of a symptom description alone, without ever measuring what was actually rendered. The measurement that ended the saga (`simctl launch --wait-for-debugger` + screenshot bounding-box measurement) was available from round 2 and took one round to run.
- Phase 4 shipped without formal `UAT.md`/`SECURITY.md`/`VERIFICATION.md` artifacts despite 19 rounds of real human verification already having happened conversationally — the milestone-close audit caught this gap and required a retroactive UAT session, security review, and goal-backward verification pass before the milestone could close. The underlying human verification had already happened; only the paper trail was missing.
- `04-01-SUMMARY.md`'s deviation narrative (round 12: "icon removed entirely") was left stale after round 17 reversed that decision — the SUMMARY's append-only convention means the narrative arc is preserved but a reader following only the "Accomplishments" section could draw a false conclusion about final shipped state without cross-checking the actual files.

### Patterns Established
- When a fix does not converge after two attempts on the same asset/component, stop editing and go measure what is actually happening (hold the process, screenshot, inspect compiled artifacts) before trying a third variant — established explicitly in Phase 4's debug session as "the lesson this saga cost 13 rounds to learn"
- Retroactive verification (UAT + SECURITY + VERIFICATION) is viable and cheap to run after the fact when the underlying human testing already happened — the gap is procedural (missing paper trail), not a re-test of unverified work

### Key Lessons
1. A phase whose success criteria require real-device-only verification should get its `UAT.md`/`SECURITY.md`/`VERIFICATION.md` artifacts created in the same session as the human checkpoint approval, not deferred — otherwise milestone close has to reconstruct paper trail for work that was already verified
2. For any "reported symptom doesn't match expected code behavior" investigation, prefer direct measurement (hold-and-inspect, pixel-probe, compiled-artifact dump) over a second content edit — content edits without measurement can run for many rounds without ever falsifying the actual hypothesis

### Cost Observations
- Model mix: balanced profile — planner/executor on Sonnet, verifier/plan-checker/security-auditor on Haiku
- Sessions: 3+ (Phase 4's 19-round debug saga spanned multiple sessions; Phase 5/6 delivery; milestone-close retroactive verification)
- Notable: first milestone where a phase's debug cost (19 rounds) dominated total milestone effort despite the phase itself being the smallest-scoped of the three — real-device-only verification loops are expensive when root-causing requires hardware the environment doesn't have attached

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.1 | 2 | 2 | First GSD-managed milestone; introduced decimal-phase insertion for audit-flagged tech debt |
| v1.2 | 2 | 2 | First pure-hardening milestone (no new user-facing feature); post-execution code review caught a critical gap per-plan verification missed |
| v1.3 | 3+ | 3 | First milestone with independent (no-shared-state) phases running in parallel timeline; first phase to require retroactive UAT/SECURITY/VERIFICATION reconstruction at milestone close |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.1 | +26 (9 calculator, 16 service, 1 HealthStep) + 4 UI tests | ≥90% (Domain 100%) per CLAUDE.md gate | 0 — no new third-party dependencies |
| v1.2 | Full suite green, 645 tests | 93.31% overall (up from 93.14% post-flip) | 0 — no new third-party dependencies |
| v1.3 | +8 automated (2 launch-handoff, 2 chart-scrub XCUITests, 4 History direction/dataset UI tests) | Full suite green | 0 — no new third-party dependencies |

### Top Lessons (Verified Across Milestones)

1. Reusing an established `Services/` layer pattern for a new capability (rather than inventing one) keeps a single-feature milestone architecturally uneventful — confirmed once, watch for continued validation on future notification/service work
2. A code-review pass that traces actual runtime call paths (not just function names matching intent) is worth keeping as a standing gate — it caught a critical, otherwise-invisible gap in v1.2's onboarding fix
3. Independent (no-shared-state) phase design isolates a single phase's debug cost from the rest of the milestone's timeline — confirmed in v1.3, where Phase 4's 19-round saga didn't block Phase 5/6
4. Create `UAT.md`/`SECURITY.md`/`VERIFICATION.md` in the same session as a real-device human checkpoint approval, not deferred — v1.3 Phase 4 had to reconstruct this paper trail retroactively at milestone close for work that was already verified conversationally
