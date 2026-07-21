# Phase 1: Weekly Summary Notification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-20
**Phase:** 1-Weekly Summary Notification
**Areas discussed:** Content freshness strategy, Notification tap destination, Onboarding opt-in flow, Settings placement & copy

---

## Content freshness strategy

**Q: When should the notification's %-change content get (re)computed, given local notification content is static once scheduled and no BGTaskScheduler infra exists yet?**

| Option | Description | Selected |
|--------|-------------|----------|
| On app foreground | Recompute + reschedule on `scenePhase == .active`, same pattern as `ReminderService.scheduleIfEnabled()`. No new infra. | ✓ |
| New BGAppRefreshTask | Background-refresh infra to wake app near week boundary. No precedent in codebase, no exact-timing guarantee. | |
| Both | Foreground reschedule + best-effort background backstop. | |

**Q: If the notification fires with stale content, what should happen?**

| Option | Description | Selected |
|--------|-------------|----------|
| Fire with best-available value | Use the most recently computed %-change. Best-effort, matches Health write-back pattern. | ✓ |
| Skip that week's notification | Suppress entirely if content wasn't refreshed after the new week began. | |

**User's choice:** On-foreground recompute+reschedule; fire with best-available value if stale.
**Notes:** None.

---

## Notification tap destination

**Q: Where should tapping the weekly summary notification take the user?**

| Option | Description | Selected |
|--------|-------------|----------|
| Insights tab | Already has the week-over-week trend + TrendBadge component. | ✓ |
| Dashboard tab | App's default landing tab. | |
| You decide | Leave to Claude's discretion. | |

**Q: Should tapping deep-link to a specific period (last completed week), or open at default state?**

| Option | Description | Selected |
|--------|-------------|----------|
| Default state | Open tab as-is, no period pre-selection. Matches existing `NotificationActionHandler` (no state restoration). | ✓ |
| Jump to last week | Pre-select "last week" as active period. Requires passing period state through the pending-tap flag. | |

**User's choice:** Insights tab, default state, no deep-link.
**Notes:** None.

---

## Onboarding opt-in flow

**Q: How should the weekly-summary onboarding opt-in fit into the flow (existing daily reminder has no onboarding step at all)?**

| Option | Description | Selected |
|--------|-------------|----------|
| New dedicated step | Standalone 5th onboarding step. | |
| Fold into Health opt-in step | Add toggle to the existing (4th) Health opt-in step. | ✓ |
| You decide | Leave placement to Claude. | |

**Q: Should enabling weekly summary during onboarding also silently enable the (currently off) daily reminder, since they share the same OS notification permission?**

| Option | Description | Selected |
|--------|-------------|----------|
| Fully independent | Shared OS permission prompt, but each opt-in toggle stays independent. | ✓ |
| Link them | Enabling one during onboarding also enables the other. | |

**User's choice:** Fold into existing Health opt-in step; keep the two notification opt-ins fully independent.
**Notes:** None.

---

## Settings placement & copy

**Q: Where should the weekly summary toggle sit in Settings relative to the existing ReminderSection?**

| Option | Description | Selected |
|--------|-------------|----------|
| New sibling section | Separate `SettingsSection` card, placed after `ReminderSection`. | ✓ |
| Inside ReminderSection | Second toggle row inside the existing card under a shared "Notifications" heading. | |

**Q: Tone/content for the %-change notification body — specific wording or Claude drafts it?**

| Option | Description | Selected |
|--------|-------------|----------|
| Claude drafts it | `String(localized:)` pattern, neutral/factual tone matching `ReminderService`, no risk-language violations. | ✓ |
| I have specific wording | Owner supplies exact phrasing. | |

**User's choice:** New sibling Settings section; Claude drafts the copy.
**Notes:** None.

---

## Claude's Discretion

Two additional gray areas were surfaced after the four selected areas were discussed (existing users' history, and permission-denied UX parity), but the owner ended the discussion before locking them explicitly:

- **"First-ever week" detection (ENGG-06):** Recommended in CONTEXT.md — define "no prior-week data" as zero `ConsumptionEvent` rows before the current calendar week (not time-since-toggle-enabled), so existing users with pre-v1.1 history get accurate comparisons immediately rather than a wrongly-suppressed "first week."
- **Permission-denied UX parity:** Recommended — mirror `ReminderSection`'s existing permission-denied hint in the new Weekly Summary settings section.

Both are flagged explicitly for the researcher/planner to confirm during planning, not silently assumed.

## Deferred Ideas

None — discussion stayed within phase scope; no scope-creep suggestions came up.
