# Phase 3: App Startup Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-27
**Phase:** 3-App Startup Hardening
**Areas discussed:** Onboarding authority, Store-failure error UI, Async container loading UX, Retry semantics

---

## Onboarding authority

| Option | Description | Selected |
|--------|-------------|----------|
| Persisted flag only | Drop `.onChange(of: profiles.isEmpty)` reset entirely; `onboardingDone` is sole gate | ✓ |
| Query wins, debounced | Keep query-driven reset, gated on a "store settled" signal that doesn't exist yet | |
| Query authoritative, flag removed | Drop AppStorage flag, gate purely on `profiles.isEmpty` | |

**User's choice:** Persisted flag only (recommended option).
**Notes:** User asked for pros/cons of all three approaches before deciding — see the inline comparison given before the re-ask. Key factor: no delete-profile flow exists yet, so the "flag drifts from reality" risk is currently hypothetical.

| Option | Description | Selected |
|--------|-------------|----------|
| Code comment only | Doc comment on `onboardingDone`/`RootShellView` | |
| ADR | Formal ADR documenting the decision + future contract | ✓ |
| Nothing extra | Trust future code review | |

**User's choice:** ADR (more formal than the recommended code-comment-only option).

| Option | Description | Selected |
|--------|-------------|----------|
| Launch with 0 profiles + onboardingDone=YES | Extend existing hook, seed zero profiles | |
| Simulate mid-session profile deletion | New test-only delete hook, delete profile after launch, assert no reset | ✓ |

**User's choice:** Simulate mid-session profile deletion (closer to the original bug scenario; needs a new test-only delete hook).

| Option | Description | Selected |
|--------|-------------|----------|
| Leave to separate todo | Keep `UserProfileStore.fetchOrCreate`'s missing save in the broader context-insert audit | |
| Fix it here too | Add `context.save()` now since this phase touches the same path | ✓ |

**User's choice:** Fix it here too.

---

## Store-failure error UI

| Option | Description | Selected |
|--------|-------------|----------|
| Full-screen error view | Dedicated SwiftUI screen replacing all app content | ✓ |
| Alert over blank/last-known UI | `.alert()` over an empty shell | |

**User's choice:** Full-screen error view (recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Retry | Re-attempt `StoreBootstrap.makeContainer` | ✓ |
| Quit app | Explicit quit button | |
| Contact/report path | Non-PII diagnostic info surface | ✓ |

**User's choice:** Retry + Contact/report path (multi-select).

| Option | Description | Selected |
|--------|-------------|----------|
| No destructive option now | Retry only; matches "never silently discard data" | ✓ |
| Add "Erase and start fresh" | Second destructive button | |

**User's choice:** No destructive option now (recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, mention it | Reference the RecoveredStores safety-net in copy | |
| No, keep it generic | Plain "something went wrong" copy | ✓ |

**User's choice:** No, keep it generic (user picked against the recommended option here).

---

## Async container loading UX

| Option | Description | Selected |
|--------|-------------|----------|
| Technical unblock only | Async container, no new visible UI; branded loading view stays Cluster B | ✓ (after clarification) |
| Add a minimal loading view now | Small branded loading view, in scope now | |

**User's choice:** Technical unblock only.
**Notes:** The threshold follow-up question ("Always show briefly") initially conflicted with this choice. Flagged the contradiction back to the user and re-asked directly — confirmed "No visible loading UI" as the final answer.

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, same pattern | Reuse `forceOnboardingPending`-style `@State` convention | |
| Let the planner/executor decide | Not a product decision | ✓ |

**User's choice:** Let the planner/executor decide.

---

## Retry semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Full StoreBootstrap.makeContainer call | Re-run the whole open-with-recovery sequence | ✓ |
| Skip straight to a fresh empty store | Bypass reopening the known-bad store | |

**User's choice:** Full StoreBootstrap.makeContainer call (recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| No cap, let the user retry freely | No rate limiting | ✓ |
| Cap after N attempts | Disable/change button after N failures | |

**User's choice:** No cap (recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Disable button + inline spinner | Standard in-flight pattern | ✓ |
| No special state | Button stays tappable | |

**User's choice:** Disable button + inline spinner (recommended).

---

## Claude's Discretion

- Exact async/state-machine mechanism for "container ready" (Async container loading UX area).
- Exact wording of the generic error-screen copy.
- Exact non-PII diagnostic content surfaced by the Contact/report action.

## Deferred Ideas

- Branded/minimal loading view — explicitly discussed and deliberately kept out of this phase; stays Cluster B scope (`2026-07-27-branded-static-launch-screen.md`).
- No other scope-creep ideas surfaced during discussion.
