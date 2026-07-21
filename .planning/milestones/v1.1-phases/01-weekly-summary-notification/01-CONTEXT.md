# Phase 1: Weekly Summary Notification - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

An opt-in, off-by-default local notification that fires once a week (first
day of the new week per system locale, 9am local time) telling the user how
their pure-alcohol consumption changed vs. the prior week. Includes opt-in
controls in Settings and during onboarding, correct edge-case messaging
(zero-last-week, no-prior-week-at-all), and tap-to-open. Covers ENGG-01
through ENGG-07 (`.planning/REQUIREMENTS.md`).

</domain>

<decisions>
## Implementation Decisions

### Content freshness strategy
- **D-01:** Recompute and reschedule the notification's %-change content on
  app foreground (`scenePhase == .active`), mirroring
  `ReminderService.scheduleIfEnabled()`. No new background-task
  infrastructure (`BGTaskScheduler` does not exist anywhere in this
  codebase today — confirmed by codebase scout).
- **D-02:** If the notification fires with stale content (app wasn't
  reopened since the prior week ended — e.g. a backdated entry logged after
  the last reschedule), fire with the best-available value from the most
  recent recompute. Matches the existing best-effort pattern used for
  Health write-back. Do not suppress the notification for staleness.

### Notification tap destination
- **D-03:** Tapping the notification opens the **Insights tab** (not
  Dashboard) — Insights already surfaces the week-over-week trend via
  `TrendBadge` (`Features/Insights/Components/InsightsHeroCard.swift`).
- **D-04:** Open Insights at its default state — no deep-link/period
  pre-selection to "last week." Matches the existing
  `NotificationActionHandler` pattern (no state restoration for the daily
  reminder either).

### Onboarding opt-in flow
- **D-05:** Fold the weekly summary opt-in toggle into the **existing
  Health opt-in step** (the last/4th onboarding step, per plan-0036) rather
  than adding a new dedicated step. Both are opt-in/off-by-default extras
  presented at the end of onboarding.
- **D-06:** The weekly summary and daily reminder opt-ins stay **fully
  independent** even though they share the same OS-level
  `UNUserNotificationCenter` authorization. Enabling weekly summary during
  onboarding must NOT silently enable the (currently off, Settings-only)
  daily reminder.

### Settings placement & copy
- **D-07:** Add a **new sibling `SettingsSection`** ("Weekly Summary")
  placed immediately after the existing `ReminderSection` in
  `SettingsView.swift` — one card per settings concern, matching the
  existing pattern. Do not nest it inside `ReminderSection`.
- **D-08:** Notification body copy: Claude drafts it, following the
  existing `String(localized:)` pattern used by `ReminderService`
  (`reminder.notification.title` / `.body`), neutral/factual tone, no
  risk-language violations (CLAUDE.md: never call consumption "safe").
  Exact strings finalized during planning/execution — no specific wording
  was mandated by the owner.

### Claude's Discretion
User ended discussion before these two could be explicitly locked; treat as
Claude's discretion during planning, but flag both explicitly for the
researcher/planner since they affect correctness of locked requirements:

- **"First-ever week" detection (ENGG-06):** Recommended definition — "no
  prior-week data at all" means **zero `ConsumptionEvent` rows exist with a
  `consumptionDate` before the start of the current calendar week**, NOT
  "less than a week has passed since the weekly-summary toggle was flipped
  on." DrinkPulse already has existing users with months of pre-v1.1
  history (36 shipped plans); an existing user who opts in must get a real
  week-over-week comparison immediately, not a wrongly-suppressed "first
  week" skip. This is distinct from ENGG-05 (prior week existed but logged
  zero grams — that gets the qualitative-only message, not a skip).
- **Permission-denied UX parity:** Recommended — the new Weekly Summary
  Settings section should show the same permission-denied hint pattern
  `ReminderSection` already uses when system notification permission is
  off, for visual/behavioral consistency. Not explicitly confirmed by the
  owner.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Services layer pattern (must follow, not reinvent)
- `docs/decisions/0008-services-layer.md` — ADR-0008: protocol-wrapped
  platform capabilities in `Services/`; this phase's notification service
  must follow this pattern, not invent a new one (carried forward from
  `.planning/STATE.md` Accumulated Context).
- `docs/decisions/0004-data-access-query-stateless-vm.md` — ADR-0004:
  `@Query` + stateless view models, no repository layer.

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — ENGG-01 through ENGG-07, the locked
  requirements for this phase.
- `.planning/ROADMAP.md` — Phase 1 success criteria (5 numbered criteria).
- `.planning/PROJECT.md` — Key Decisions table (all 11 ADRs); Constraints
  section (testing, privacy, schema-evolution rules apply to this phase).

### Domain calculation rule (carried forward, non-negotiable)
- Week-over-week calculation MUST reuse `ConsumptionEvent.pureAlcoholGrams`
  (physical density 0.789 g/ml) — never re-derive alcohol mass from
  scratch (`.planning/STATE.md` Accumulated Context → Decisions).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Features/Insights/InsightsViewModel.swift` — `periodTotalGrams` (line
  212), `prevPeriodTotalGrams` (lines 216-221), `trendFraction` (lines
  225-228, `(current - prev) / prev`) already implement week-over-week
  comparison logic. Strong candidate to reuse or extract rather than
  reimplementing in the new notification service.
- `Features/Insights/InsightsPeriod.swift` (lines 22-23, 42-50) —
  locale-aware week-boundary logic via
  `calendar.dateInterval(of: .weekOfYear, for:)`, matching ENGG-03's
  "first day of the new week (system locale)" requirement.
- `Features/Insights/Components/InsightsHeroCard.swift` (lines 56-88) —
  `TrendBadge`: existing %-formatting pattern (rounds to Int %, arrow icon,
  green/red by sign, "unchanged" when `abs(fraction) <= 0.01`). Note the
  existing ±1% "unchanged" band differs from this phase's spec'd ±5% band
  (ENGG-04) — do not reuse the threshold, only the formatting pattern.
- `Services/ReminderService.swift` — direct template for the new service:
  stable identifier constant, `makeRequest(hour:minute:)` pure factory,
  idempotent `schedule()` (removes-then-adds), `cancel()`,
  `scheduleIfEnabled()` reading `@AppStorage`-backed settings.
- `Services/NotificationScheduling.swift`,
  `Services/UITestNotificationCenter.swift` — protocol + UI-test stub to
  reuse as-is (same `UNUserNotificationCenter` abstraction covers both
  notification types).
- `Services/NotificationActionHandler.swift` (lines 15-29) — tap-routing
  pattern (`didReceive` checks `request.identifier`, sets an
  `AppStorageKeys` pending flag, posts a `Notification.Name`). The new
  weekly-summary notification needs its own identifier + its own
  `AppStorageKeys` pending flag + its own `Notification.Name`, following
  this same branch structure — but routing to Insights instead of the
  Add Drink sheet.
- `Features/Settings/Components/ReminderSection.swift` +
  `SettingsView.swift:96` — settings card pattern to mirror (D-07):
  `SettingsSection(...)` wrapper, toggle + permission-denied hint,
  `AppStorageKeys`-backed state.
- `Domain/ConsumptionEvent.swift` — `consumptionDate: Date` (line 16,
  backdatable), `pureAlcoholGrams` computed property (lines 76-78, fixed
  physical density).

### Established Patterns
- Notification permission requested via `center.requestAuthorization(...)`
  (alert + sound, no badge) — shared OS-level state across both reminder
  types (see D-06 for how this phase keeps the two opt-ins independent
  anyway).
- Best-effort service pattern: catch all errors, log category only (never
  PII/dates/values), never throw into the caller, degrade silently.
- No onboarding step currently touches notifications — this phase
  introduces the first onboarding-time notification permission prompt
  (folded into the Health opt-in step per D-05).

### Integration Points
- `Features/Onboarding/OnboardingView.swift` — Health opt-in step (existing
  4th step) is where the new toggle gets added per D-05.
- `Features/Settings/SettingsView.swift:96` — insertion point for the new
  sibling `SettingsSection`, right after `ReminderSection()`.
- `AppStorageKeys` — needs new keys for weekly-summary-enabled state and
  the tap-pending flag, following the existing `reminderEnabled` /
  `reminderHour` / `reminderMinute` naming convention.

</code_context>

<specifics>
## Specific Ideas

No specific UI mockups or exact wording were provided by the owner — all
copy is Claude's draft (D-08), following existing string-localization and
risk-language conventions.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. No scope-creep suggestions
came up during this discussion.

### Reviewed Todos (not folded)
None — `todo.match-phase` returned zero matches for Phase 1.

</deferred>

---

*Phase: 1-Weekly Summary Notification*
*Context gathered: 2026-07-20*
