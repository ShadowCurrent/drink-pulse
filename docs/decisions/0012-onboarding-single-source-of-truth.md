# ADR-0012 — Onboarding gate: single source of truth

**Status**: accepted
**Date**: 2026-07-27
**Builds on**: [ADR-0009](0009-versioned-schema-and-migration-plan.md)

## Context

`RootShellView` decided which view to show — itself or `OnboardingView` — from
two sources at once: the persisted `onboardingDone` `@AppStorage` flag, and a
live `@Query private var profiles: [UserProfile]` result. A
`.onChange(of: profiles.isEmpty) { if isEmpty { onboardingDone = false } }`
block silently reset `onboardingDone` to `false` whenever the query briefly
observed zero profiles — including a single transient empty render before a
fresh `UserProfile` insert had settled (the exact timing gap
`UserProfileStore.fetchOrCreate` had, see D-04 below). The practical effect: a
fully onboarded user could be kicked back to `OnboardingView` mid-session with
no data loss and no error, just an unreliable dual source of truth. This was
flagged during the `sheet-closes-reopens-loses-state` debug session
(`docs/DEVLOG.md`, 2026-07-27) as a fragile pattern worth hardening, though no
triggering code path had been found for that specific bug.

## Decision

1. **`onboardingDone` (`@AppStorage`) is the sole authority** for the
   `RootShellView` vs. `OnboardingView` gate. No other signal — a `@Query`
   result, a count, an existence check — may influence which view is shown.
2. **It is write-only from `OnboardingView.onFinish` today.** There is
   currently no other code path that flips it.
3. **Any future delete-profile / delete-all-data flow MUST set
   `onboardingDone = false` itself**, as part of its own implementation. This
   is a forward-looking contract for code that does not exist yet — no such
   flow ships in this phase, so there is nothing to regression-test beyond
   this ADR today. A future implementer of that flow is expected to read this
   decision before wiring it up.
4. **No `@Query` observer of any kind may write to `onboardingDone`.** The
   `.onChange(of: profiles.isEmpty)` reverse-write is deleted entirely, not
   replaced with a narrower variant.

As an adjacent fix directly load-bearing for this decision (D-04):
`UserProfileStore.fetchOrCreate` now calls `try? context.save()` immediately
after `context.insert(profile)`, closing the unsaved-insert timing gap that
made `profiles.isEmpty` transiently — and misleadingly — `true` in the first
place. This phase was already touching that exact gap; fixing it here is
narrower than (and does not replace) the separate, broader `context.insert`
audit todo tracked at
`.planning/todos/pending/2026-07-27-audit-context-insert-call-sites-for-missing-save.md`,
which still covers all other call sites via `/gsd-quick`.

A regression test hook (`UITestSeed.deleteProfileMidSession`,
`RootShellView.deleteProfileMidSessionIfUITest()`) and UI test
(`OnboardingAuthorityUITests`) simulate exactly the scenario decision 3
describes — deleting the only `UserProfile` mid-session — and prove the app
stays on `RootShellView` instead of falling back to onboarding, independent of
`@Query` state.

## Consequences

- No more transient-query-driven onboarding resets — regression-pinned by
  `OnboardingAuthorityUITests`.
- A `UserProfile` can now be deleted (in-app or out-of-band) without
  side-effecting the onboarding gate. This is exactly the invariant a future
  delete-all-data flow needs to build on top of, provided it honors decision
  3 above by explicitly setting `onboardingDone = false`.
- **Accepted risk (T-3-02, threat register):** a user could theoretically end
  up with `onboardingDone = true` and zero `UserProfile` rows (e.g. an
  out-of-band store wipe outside any in-app action this phase adds), with no
  in-app recovery path yet. This phase does not introduce any new way to
  reach that state — it only stops treating a transient query result as if it
  were that state. Recovery is explicitly deferred to the not-yet-built
  delete-all-data flow referenced in decision 3.

### Alternatives considered

- **Keep both sources, but debounce/guard the `@Query` observer** (e.g. only
  reset after N consecutive empty renders). **Rejected**: still a second
  source of truth that could misfire under different timing, and adds
  complexity to paper over a race that D-04 removes at its root instead.
- **Derive onboarding state purely from `profiles.isEmpty`, drop
  `onboardingDone` entirely.** **Rejected**: makes onboarding-completion
  status the same signal as "does a profile currently exist," which is
  exactly the coupling a future delete-all-data flow needs to avoid — a user
  who deletes their data should not be forced back through onboarding unless
  that flow explicitly decides so.
