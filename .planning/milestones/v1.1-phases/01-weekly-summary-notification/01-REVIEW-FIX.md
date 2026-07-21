---
phase: 01-weekly-summary-notification
fixed_at: 2026-07-20T20:59:13Z
review_path: .planning/phases/01-weekly-summary-notification/01-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 5
skipped: 1
status: partial
---

# Phase 01: Code Review Fix Report

**Fixed at:** 2026-07-20T20:59:13Z
**Source review:** .planning/phases/01-weekly-summary-notification/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (1 critical, 5 warnings — `fix_scope: critical_warning`)
- Fixed: 5
- Skipped: 1

## Fixed Issues

### WR-01: `WeeklySummaryCalculator`'s doc comment contradicts how its only caller uses it

**Files modified:** `drinkpulse/Domain/WeeklySummaryCalculator.swift`
**Commit:** `7461d97`
**Applied fix:** Reworded the `currentWeekGrams` parameter doc comment to describe it as "the current period's window (which may still be in progress)" and cross-referenced `WeeklySummaryService.scheduleIfEnabled`'s `offset: 0` usage and `InsightsViewModel.trendFraction`'s live "This Week" semantics, so the comment now agrees with actual caller behavior instead of implying a completed week.

### WR-02: Toggle-off during pending async authorization can re-enable Weekly Summary against the user's last action

**Files modified:** `drinkpulse/Features/Settings/Components/WeeklySummarySection.swift`, `drinkpulse/Features/Onboarding/Components/HealthStep.swift`
**Commit:** `680a7a9`
**Applied fix:** Introduced a monotonically incremented `toggleGeneration` (`weeklySummaryToggleGeneration` in `HealthStep`) `@State` counter, bumped on every toggle interaction (on or off). The async `enable()` / `enableWeeklySummary()` functions now capture the generation in effect when the task starts and re-check it after each `await` (post-`requestAuthorization()`, and in `WeeklySummarySection` also post-`scheduleIfEnabled`), bailing — and, where scheduling already ran, calling `service.cancel()` — if a newer toggle action has superseded the in-flight one. This closes the race where a fast toggle-off during pending authorization could silently re-arm the notification.
**Note:** This is a concurrency/race-condition fix. Syntax checks (swiftc -parse) passed on both files, but semantic correctness under real async timing cannot be fully verified by static/syntax checks alone — **flagged for human verification** before this phase proceeds to full verification (per verification_strategy's logic-bug limitation).

### WR-03: Non-exhaustive `default:` case silently reinterprets a hypothetical `.down` as `.same`

**Files modified:** `drinkpulse/Services/WeeklySummaryService.swift`
**Commit:** `df4b6c0`
**Applied fix:** Replaced the `default:` branch in `bodyText(for:)`'s inner `directionOnly` switch with explicit `.same` and `.down` cases; `.down` now calls `assertionFailure` (documenting that `WeeklySummaryCalculator.content` never constructs this case today) before falling back to the same "no change" copy, so a future refactor that does produce `.directionOnly(.down)` fails loudly in debug builds instead of silently showing the wrong direction.

### WR-04: New `pendingOpenInsights` flag is not reset by `UITestSeed.resetTransientDefaults()`

**Files modified:** `drinkpulse/UITestSeed.swift`
**Commit:** `e6a78e2`
**Applied fix:** Added `UserDefaults.standard.removeObject(forKey: AppStorageKeys.pendingOpenInsights)` alongside the other `removeObject` calls in `resetTransientDefaults()`. Verified this does not break `WeeklySummaryTapUITests`: `drinkpulseApp.init()` calls `resetTransientDefaults()` *before* re-seeding the flag via `UITestSeed.seedPendingOpenInsights`, so the intentional UI-test seed still applies after the reset.

### WR-05: `.directionOnly(.same)` notification copy can misrepresent a week where a drink actually was logged

**Files modified:** `drinkpulse/Localizable.xcstrings`
**Commit:** `6eb8413`
**Applied fix:** Reworded the `weeklySummary.notification.body.directionOnlySame` string value from "No drinks logged again this week." to "No alcohol logged again this week.", matching what the calculator can actually assert (zero pure-alcohol grams, not zero logged events). Verified no test or source file references the old literal string directly — the one test that checks this copy (`WeeklySummaryServiceTests.makeRequest_bodyText_directionOnlySame`) compares against `String(localized:)` for the same key, so it tracks the new value automatically.

## Skipped Issues

### CR-01: Weekly-summary notification content can be stale/incomplete by delivery time

**File:** `drinkpulse/Services/WeeklySummaryService.swift:82-119` (also `drinkpulse/Features/Shell/RootShellView.swift:104-109`)
**Reason:** This finding is architectural, not a mechanical code fix. The review's own Fix section lists three materially different resolutions with real product/engineering tradeoffs:
1. Register a `BGAppRefreshTask` to recompute closer to delivery — requires adding a new Background Modes capability/entitlement and a new scheduling subsystem, which this agent cannot safely add without Xcode project/capability changes and explicit approval.
2. Soften the notification copy to avoid an exact `%d%%` figure — a unilateral, user-visible UX/copy change to a health-adjacent feature's core value proposition (the whole point of the notification is the percentage), which the project's own CLAUDE.md instructs to propose rather than silently implement for anything BAC/guideline/health-adjacent.
3. Track a recompute timestamp and skip/soften delivery when "too old" — still requires a delivery-time recompute hook that does not exist in this codebase (no `BGTaskScheduler`, no Notification Service Extension), so even the "minimum" option is itself a new mechanism, not a bug-fix-shaped change.

None of the three is a safe, judgment-free automated fix. Per this agent's rollback/skip policy for findings requiring human judgment, this is left unfixed and flagged here for the developer to pick a direction (a design/product decision is required) before implementation.

**Original issue:** `scheduleIfEnabled(context:)` bakes a week-over-week percentage into a *static* notification body at the moment the app happens to be foregrounded, but the notification fires at a fixed future weekly boundary with no mechanism (no `BGTaskScheduler`, no Notification Service Extension) to recompute it closer to delivery. Lapsed users — the exact audience this re-engagement nudge targets — can receive a notification quoting stale or incomplete week data with no indication the figure is outdated.

---

_Fixed: 2026-07-20T20:59:13Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
