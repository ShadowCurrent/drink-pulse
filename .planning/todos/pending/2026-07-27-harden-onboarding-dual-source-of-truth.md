---
created: 2026-07-27T00:00:00.000Z
title: Harden onboarding dual source of truth in RootShellView
area: general
severity: major
cluster: A
resolves_phase: 3
files:
  - drinkpulse/Features/Shell/RootShellView.swift:7 (@AppStorage onboardingDone)
  - drinkpulse/Features/Shell/RootShellView.swift:17 (@Query profiles — the live source)
  - drinkpulse/Features/Shell/RootShellView.swift:97-98 (.onChange(of: profiles.isEmpty) { if isEmpty { onboardingDone = false } })
  - drinkpulse/drinkpulseApp.swift:79-92 (the gate: if onboardingDone && !forceOnboardingPending { RootShellView() } else { OnboardingView(...) })
  - drinkpulse/Domain/Persistence/UserProfileStore.swift:30 (context.insert(profile) with no save — the intersection with the insert-audit todo)
---

## Problem

Onboarding completion has **two sources of truth that can disagree**:

- **Persisted:** `@AppStorage(AppStorageKeys.onboardingDone)`
  (`RootShellView.swift:7`, `drinkpulseApp.swift:7`)
- **Live:** `@Query private var profiles: [UserProfile]`
  (`RootShellView.swift:17`)

They are wired together at `RootShellView.swift:97-98`:

```swift
.onChange(of: profiles.isEmpty) { _, isEmpty in
    if isEmpty { onboardingDone = false }
}
```

And `onboardingDone` gates the entire view tree at `drinkpulseApp.swift:79`:

```swift
if onboardingDone && !forceOnboardingPending {
    RootShellView()
} else {
    OnboardingView(...)
}
```

**Consequence if `profiles` ever transiently reports empty:** the whole
`RootShellView` — and every sheet presented under it, with all unsaved user
input — is torn down and replaced by `OnboardingView`. The user is dropped
back into onboarding mid-task.

Surfaced during the `sheet-closes-reopens-loses-state` debug session
(2026-07-19, archived at
`.planning/debug/resolved/sheet-closes-reopens-loses-state.md`). It was
investigated as a candidate cause and **ruled out for that bug** — a grep of
every `UserProfile` insert/delete call site found no path that removes the
profile row during normal use. So there is **no known reproduction today**;
this is a latent fragility, not an observed failure.

**Why it is nonetheless severity `major`:** the failure mode is not a visual
glitch. It silently discards in-flight user input and resets the app to a
first-run state. A one-frame empty `@Query` result is enough to trigger it,
and `@Query` emptiness during store churn (migration, store recovery,
CloudKit sync when Phase B is eventually enabled) is exactly the kind of
transient the current wiring cannot distinguish from a genuine "user deleted
their profile".

**Direct intersection with the insert-audit todo:**
`UserProfileStore.fetchOrCreate` (`UserProfileStore.swift:30`) inserts a
`UserProfile` into the context and never saves it. An unsaved profile is
exactly the kind of object whose visibility to a `@Query` is timing-dependent
— see `2026-07-27-audit-context-insert-call-sites-for-missing-save.md`.

## Solution

TBD — the shape of the fix is a design decision, not a mechanical edit:

- **Decide which source is authoritative.** Most likely the persisted flag,
  with `profiles.isEmpty` treated as a *hint* rather than a command. A live
  `@Query` result is not a reliable statement about user intent.
- **Distinguish "transiently empty" from "genuinely deleted".** If the
  `profiles.isEmpty` signal is kept at all, it must not fire on a single
  empty render. Options: require the store to be confirmed loaded first, debounce,
  or drive the reset from the explicit delete action instead of from
  query emptiness.
- **Prefer removing the reverse-write entirely.** Onboarding should be reset
  by an explicit user action (or an explicit profile-deletion path), not by a
  view observing that a query happens to be empty right now.
- Check `forceOnboardingPending` / `UITestSeed.forceShowOnboarding`
  (`drinkpulseApp.swift:37`) still behaves after the change — the UI-test
  onboarding hook rides the same gate.

## Why cluster A

Same reason as the async-container todo: this is app-startup / view-identity
structure, not user-facing polish. It also touches the same gate
(`drinkpulseApp.swift`) and the same class of question (what is authoritative
when the store is not yet in a settled state). Doing it alongside the Swift 6
work keeps all startup/identity reasoning in one milestone.

**Gate (CLAUDE.md):** changing the onboarding gate is user-facing, so it needs
a `drinkpulseUITests` test that actually runs. There are existing onboarding
UI tests driven by `-dp_force_onboarding YES` / `-dp_onboarding_done YES`
launch arguments — extend those rather than adding a parallel mechanism. A
regression test should pin the intended behaviour: a transient empty
`profiles` result must NOT drop the user back to onboarding.

Size: plan-worthy — the decision about which source wins has consequences for
onboarding, store recovery, and (later) CloudKit sync.
