# Phase 3: App Startup Hardening - Context

**Gathered:** 2026-07-27
**Status:** Ready for planning

<domain>
## Phase Boundary

App startup behaves predictably while the SwiftData store isn't yet
settled. Three things change, all inside `drinkpulseApp.swift` /
`RootShellView.swift` / `StoreBootstrap.swift` / `UserProfileStore.swift`:

1. The onboarding gate gets a single authoritative source of truth
   (STARTUP-01).
2. `sharedModelContainer` creation moves off the synchronous `App.init`
   path (STARTUP-02).
3. The two `fatalError` container-failure call sites
   (`drinkpulseApp.swift:59,68`) are replaced with a real, designed
   user-facing error state (STARTUP-03).

Nothing else. No new visible loading UI (that's Cluster B scope), no
destructive data-recovery UX, no touching Cluster B's animation/motion
backlog.

</domain>

<decisions>
## Implementation Decisions

### Onboarding authority (STARTUP-01)

- **D-01:** The persisted `onboardingDone` `@AppStorage` flag becomes the
  sole authoritative source of truth for the onboarding gate. Delete the
  `.onChange(of: profiles.isEmpty) { if isEmpty { onboardingDone = false } }`
  reverse-write at `RootShellView.swift:97-98` entirely — a live `@Query`
  result must never flip the gate. `onboardingDone` only becomes `false`
  via an explicit future user action (e.g. a not-yet-built "delete all
  data" flow), never as a side effect of a query render.
- **D-02:** Document this contract in a new ADR
  (`docs/decisions/0012-*.md`, next available number) — the
  single-source-of-truth decision, and the explicit rule that any future
  delete-profile / delete-all-data flow MUST set `onboardingDone = false`
  itself. This is a forward-looking contract for code that doesn't exist
  yet (no delete flow is currently shipped), so there's nothing to
  regression-test today beyond the ADR itself.
- **D-03:** Regression UI test: simulate mid-session profile deletion via
  a new test-only delete hook (extend the existing
  `-dp_force_onboarding` / `-dp_onboarding_done` launch-argument
  convention rather than inventing a parallel mechanism per CLAUDE.md),
  then assert the app **stays on `RootShellView`** instead of falling
  back to `OnboardingView`. This directly proves the flag alone gates the
  view, independent of query state.
- **D-04:** Fix `UserProfileStore.fetchOrCreate`'s missing
  `context.save()` (`UserProfileStore.swift:30-31`) as part of this
  phase — add `try? context.save()` (or equivalent) right after the
  insert. Rationale: this phase is already touching the exact
  unsaved-object timing gap that made `profiles.isEmpty` unreliable in
  the first place; fixing it here is directly load-bearing for D-01/D-03,
  not scope creep. This is narrower than (and does not replace) the
  separate, broader `context.insert`-audit todo
  (`2026-07-27-audit-context-insert-call-sites-for-missing-save.md`),
  which stays routed to `/gsd-quick` for all *other* call sites.

### Store-failure error UI (STARTUP-03)

- **D-05:** When `StoreBootstrap.makeContainer` fails even after its own
  non-destructive recovery attempt (the existing move-aside-and-retry in
  `StoreBootstrap.swift:42-55`), show a **full-screen SwiftUI error
  view** replacing the entire app content — icon, plain-language message,
  action button(s). Not a `.alert()` over a blank/last-known screen.
- **D-06:** The error screen offers two actions:
  - **Retry** — re-attempts the *full* `StoreBootstrap.makeContainer`
    call from scratch (open → move-aside-on-failure → open again), i.e.
    the exact same sequence that already runs at launch, just re-invoked
    on tap. Not a shortcut straight to a fresh empty store.
  - **Contact/report path** — surfaces non-PII diagnostic info (e.g. an
    error category, copyable) since no support inbox exists yet; this is
    informational/copy-paste only, not a live support channel.
  - No "Quit app" button (no sanctioned programmatic quit on iOS).
- **D-07:** No destructive "Erase and start fresh" option in this phase.
  If Retry keeps failing, the user stays on the error screen. Matches
  CLAUDE.md's "never design a path that silently discards data" — a
  destructive escape hatch is deliberately deferred, not omitted forever.
- **D-08:** Error copy stays generic ("Something went wrong loading your
  data. Try again.") — do **not** mention that a corrupted store copy
  was preserved in `RecoveredStores` (`StoreBootstrap.swift:62-87`).
  That mechanism stays purely internal for now.
- **D-09:** No rate limit / retry cap — each Retry tap is a deliberate
  user action, so no attempt-counter or disabled-after-N-tries state is
  needed.
- **D-10:** While a Retry attempt is in flight, disable the Retry button
  and show an inline spinner until it resolves (success → navigate into
  the app; failure → same error screen again).

### Async container loading UX (STARTUP-02)

- **D-11:** This phase delivers the **technical unblock only** —
  `sharedModelContainer` creation moves off the synchronous `App.init`
  path so the first frame can be drawn before the store finishes
  opening. No new visible loading UI is added. The existing launch
  screen / background holds until the container is ready, then the app
  transitions straight to onboarding-or-shell.
  — **Reversibility:** reversible — a branded loading view can be
  layered on top later (Cluster B's
  `2026-07-27-branded-static-launch-screen.md`) without touching this
  phase's async wiring.
- **D-12:** The exact async/state-machine mechanism for "container ready"
  (e.g. whether it reuses the existing `@State`-flag-in-`App`-struct
  convention seen in `forceOnboardingPending`) is left to the
  planner/executor — not a product decision.

### Claude's Discretion

- Exact async/state wiring for signaling "container ready" (D-12).
- Exact wording of the generic error-screen copy (D-08 sets the tone,
  not the final string).
- Exact non-PII diagnostic info surfaced by the Contact/report action
  (D-06) — category/code only, never file paths, stack traces with user
  data, or anything from `docs/domain.md`'s sensitive-field list.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` — Phase 3 section (Goal, Success Criteria, the
  two "Open decisions" this discussion resolved)
- `.planning/REQUIREMENTS.md` — STARTUP-01, STARTUP-02, STARTUP-03
- `.planning/todos/pending/2026-07-27-harden-onboarding-dual-source-of-truth.md`
  — original problem writeup for STARTUP-01, including the
  `sheet-closes-reopens-loses-state` debug-session history
- `.planning/todos/pending/2026-07-27-async-model-container-startup-and-error-state.md`
  — original problem writeup for STARTUP-02/03

### Project constraints
- `CLAUDE.md` — "Privacy & security" (never silently discard user data,
  informs D-07), "Accessibility" (reduceMotion, informs any future
  Cluster B loading view built on top of D-11), "Change hygiene &
  reversibility" (destructive-action approval gate)
- `.planning/PROJECT.md` — Context section on v1.2 milestone scope and
  Cluster A vs. Cluster B boundary

### Prior architecture decisions (unaffected, but load-bearing)
- `docs/decisions/0008-services-layer.md` — not directly touched by this
  phase, but the error-screen/retry action should stay consistent with
  how the codebase already wraps platform capabilities
- `docs/decisions/0009-versioned-schema-and-migration-plan.md` — the
  `MigrationPlan.self` used by `StoreBootstrap.makeContainer`; this
  phase does not change migration behavior, only what happens when it
  fails

No new ADR exists yet for D-01/D-02 — the planner or executor creates
`docs/decisions/0012-onboarding-single-source-of-truth.md` (next
available ADR number as of this discussion) during execution.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `UITestSeed.swift` — launch-argument-gated hook pattern
  (`-dp_force_onboarding`, `-dp_onboarding_done`, `-dp_uitest_*`) to
  extend for D-03's mid-session-deletion test hook, rather than
  inventing a new mechanism.
- `StoreBootstrap.recoverStore` (`StoreBootstrap.swift:62-87`) — already
  implements non-destructive move-aside recovery; D-05/D-06's error
  screen is what appears when *this already runs and still fails*, not a
  replacement for it.

### Established Patterns
- `@State`-flag-in-`App`-struct startup pattern
  (`forceOnboardingPending` in `drinkpulseApp.swift:37`) — candidate
  shape for the new "container ready" state (D-12, left to
  planner/executor).
- `Services/` protocol-wrapped layer (ADR-0008) — precedent for how
  platform-adjacent capabilities are exposed; not directly reused here
  since store bootstrap already lives in `Domain/Persistence/`, but
  worth checking for consistency if the error screen needs any new
  injected capability.

### Integration Points
- `drinkpulseApp.swift:47-70` — `sharedModelContainer` eager
  stored-property closure; this is what D-11 makes asynchronous, and
  where D-05's error view gets wired in on failure.
- `RootShellView.swift:97-99` — the `.onChange` block D-01 deletes.
- `UserProfileStore.swift:25-32` — `fetchOrCreate`, where D-04 adds the
  missing `context.save()`.

</code_context>

<specifics>
## Specific Ideas

No specific visual/copy references given ("I want it like X"). The
error screen and retry interaction should follow standard SwiftUI/HIG
conventions (icon + message + button, disabled-with-spinner while
in-flight) rather than match a named precedent.

</specifics>

<deferred>
## Deferred Ideas

None raised outside phase scope — discussion stayed within the three
STARTUP requirements. The branded/minimal loading view idea was
explicitly considered (Async container loading UX area) and deliberately
NOT added to this phase; it remains Cluster B scope via the existing
`2026-07-27-branded-static-launch-screen.md` todo.

### Reviewed Todos (not folded)

None reviewed beyond the two todos folded into decisions above (D-01–D-12
draw directly from `2026-07-27-harden-onboarding-dual-source-of-truth.md`
and `2026-07-27-async-model-container-startup-and-error-state.md`, both
already scoped into Phase 3 by the roadmap). The `todo.match-phase` scan
also surfaced several Cluster B UI todos (chart scrubbing, list-row
animation, launch-screen branding, entrance-animation suppression) and
two unclustered todos (context-insert audit, app rename) — all correctly
out of scope per `.planning/PROJECT.md`'s Cluster A/B split and were not
discussed further.

</deferred>

---

*Phase: 3-App Startup Hardening*
*Context gathered: 2026-07-27*
