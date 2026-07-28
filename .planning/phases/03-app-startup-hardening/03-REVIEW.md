---
phase: 03-app-startup-hardening
reviewed: 2026-07-28T00:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - .claude/context/current-focus.md
  - docs/DEVLOG.md
  - docs/architecture.md
  - docs/decisions/0012-onboarding-single-source-of-truth.md
  - drinkpulse/Domain/Persistence/ContainerLoadState.swift
  - drinkpulse/Domain/Persistence/StartupError.swift
  - drinkpulse/Domain/Persistence/UserProfileStore.swift
  - drinkpulse/Features/Shell/RootShellView.swift
  - drinkpulse/Features/Shell/StartupErrorView.swift
  - drinkpulse/Localizable.xcstrings
  - drinkpulse/UITestSeed.swift
  - drinkpulse/drinkpulseApp.swift
  - drinkpulseTests/Domain/Persistence/StartupErrorTests.swift
  - drinkpulseTests/Domain/Persistence/UserProfileStoreTests.swift
  - drinkpulseUITests/Features/Shell/OnboardingAuthorityUITests.swift
  - drinkpulseUITests/Features/Shell/StartupErrorUITests.swift
findings:
  critical: 1
  warning: 3
  info: 3
  total: 7
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-07-28T00:00:00Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

Phase 3's async-container-load / `StartupErrorView` work (STARTUP-02/03) is
solid: `ContainerLoadState`, `StartupError`, `drinkpulseApp`'s
`loadContainerIfNeeded()`/`retryContainerLoad()`, and `StartupErrorView` all
line up with their own documentation, are non-PII (per D-08), and are
UI-test-covered without relying on real disk corruption.

The onboarding-authority work (STARTUP-01, D-01/D-04, ADR-0012) does **not**
hold up under tracing the real call path. D-01 (deleting the
`.onChange(of: profiles.isEmpty)` reverse-write in `RootShellView`) is a
correct, verified fix. But D-04 — the `try? context.save()` added to
`UserProfileStore.fetchOrCreate`, which ADR-0012 and `docs/DEVLOG.md`
describe as "closing the unsaved-insert timing gap" and call "directly
load-bearing for this decision" — is patched onto a function that has **zero
production call sites**. The actual onboarding-completion insert
(`OnboardingViewModel.complete(into:)`, invoked from
`OnboardingView.finish()`) inserts a fresh `UserProfile` without ever calling
`context.save()`, and is completely unaffected by D-04. This reopens, via a
live code path this phase touched, exactly the "`onboardingDone == true` with
zero `UserProfile` rows" failure mode that ADR-0012 labels an "accepted risk"
for future, not-yet-built code. See CR-01.

Two smaller loose ends from the same refactor: the dedupe branch of
`fetchOrCreate` has the identical unsaved-mutation gap the create branch was
just fixed for (WR-01), and `RootShellView`'s `@Query private var profiles`
is now completely unused dead code left over from deleting its only
consumer (WR-03).

## Critical Issues

### CR-01: D-04's "fix" patches a function nothing in production calls; the real onboarding-insert path is still unsaved

**File:** `drinkpulse/Domain/Persistence/UserProfileStore.swift:25-33` (the patched function)
**Cross-referenced:** `drinkpulse/Features/Onboarding/OnboardingViewModel.swift:49-56`, `drinkpulse/Features/Onboarding/OnboardingView.swift:94-97`, `docs/decisions/0012-onboarding-single-source-of-truth.md:40-48`, `docs/DEVLOG.md` (Phase 3 Plan 01 entry)

**Issue:** `docs/DEVLOG.md` and ADR-0012 describe D-04 as an "adjacent fix
directly load-bearing for this decision": adding `try? context.save()` right
after `context.insert(profile)` in `UserProfileStore.fetchOrCreate`, to
"clos[e] the unsaved-insert timing gap that made `profiles.isEmpty`
unreliable in the first place."

Tracing every call site of `fetchOrCreate` in the codebase:

```
$ grep -rn "fetchOrCreate" --include="*.swift" .
UserProfileStore.swift:25:    static func fetchOrCreate(...)
UserProfileStoreTests.swift: (4 test call sites only)
```

`fetchOrCreate` is called **only from `UserProfileStoreTests`** — nowhere in
production code. The doc comment on the type even says "All `profiles.first`
call sites should route through here," but no call site actually does.

The real onboarding-completion insert is a different, unrelated code path:

```swift
// OnboardingViewModel.swift:49-56
func complete(into context: ModelContext) {
    context.insert(UserProfile(
        biologicalSex: sex ?? .male,
        dateOfBirth: dateOfBirth,
        guidelineChoice: guideline,
        unitSystem: unitSystem
    ))
}
```
```swift
// OnboardingView.swift:94-97
private func finish() {
    vm.complete(into: context)
    onFinish()   // → drinkpulseApp: onboardingDone = true (synchronous @AppStorage write)
}
```

This insert is never saved — not by `complete(into:)`, not by `finish()`,
and not anywhere up the call chain to `onFinish`. `onboardingDone` (backed by
`UserDefaults`/`@AppStorage`) is written synchronously and durably the
instant `onFinish()` runs, but the just-inserted `UserProfile` only becomes
durable whenever SwiftData's default autosave next fires (backgrounding,
scene-phase change, or an unrelated explicit save elsewhere) — not
immediately on insert.

**Concretely:** if the process is terminated (crash, OS jetsam, force-quit)
in the window between `vm.complete(into: context)` and the next autosave, the
device is left with `onboardingDone == true` and zero `UserProfile` rows on
next launch — exactly the state ADR-0012 calls out as "accepted risk (T-3-02)
... with no in-app recovery path yet" and frames as a *pre-existing,
theoretical* edge case unrelated to this phase's scope. It is not
pre-existing here: this phase's own onboarding-completion code is a live,
everyday path into that state, and the fix this phase shipped to close that
exact class of gap (D-04) does not touch it at all.

`OnboardingAuthorityUITests` does not catch this either — it only exercises
mid-session deletion of an *already-saved* profile (via
`-dp_uitest_delete_profile_midsession`), never a fresh onboarding completion
followed by a process kill/relaunch before the next autosave.

**Fix:** Route onboarding completion through `UserProfileStore` (or add an
explicit, error-surfaced save directly in `complete(into:)`) so the fix is
actually load-bearing on the real path:

```swift
// OnboardingViewModel.swift
func complete(into context: ModelContext) {
    context.insert(UserProfile(
        biologicalSex: sex ?? .male,
        dateOfBirth: dateOfBirth,
        guidelineChoice: guideline,
        unitSystem: unitSystem
    ))
    try? context.save() // TODO: surface failure instead of swallowing (see WR-02)
}
```
Then either delete the now-truly-unused `UserProfileStore.fetchOrCreate` (its
doc comment's claimed convention is followed by nobody), or wire real call
sites through it so the convention it documents is actually true. Update
ADR-0012/DEVLOG's D-04 description once the real path is fixed, since as
written they currently describe behavior the shipped code does not have.

## Warnings

### WR-01: `fetchOrCreate`'s dedupe branch has the same unsaved-mutation gap D-04 "fixed" for the create branch

**File:** `drinkpulse/Domain/Persistence/UserProfileStore.swift:26-28, 40-52`
**Issue:** `fetchOrCreate` only calls `try? context.save()` after the
*create* branch (line 31). When `deduplicated(in:)` collapses existing
duplicate profiles (deleting the losers), `fetchOrCreate` returns
immediately (line 27) without saving those deletes. This is the identical
category of "mutation left pending in-context" gap D-04 was written to
close — just on the delete side instead of the insert side. It's provable
from the test suite itself: `UserProfileStoreTests.deduplicated_
collapsesToNewestModifiedDate` calls `UserProfileStore.deduplicated(in:
context)` and then has to call `try context.save()` **itself**, in the test,
because the production function does not.
**Fix:**
```swift
@MainActor
static func fetchOrCreate(in context: ModelContext) -> UserProfile {
    if let profile = deduplicated(in: context) {
        try? context.save()   // flush any dedupe deletes too
        return profile
    }
    let profile = UserProfile()
    context.insert(profile)
    try? context.save()
    return profile
}
```

### WR-02: `try? context.save()` swallows have no justification comment (CLAUDE.md violation)

**File:** `drinkpulse/Domain/Persistence/UserProfileStore.swift:31`, `drinkpulse/Features/Shell/RootShellView.swift:161`
**Issue:** CLAUDE.md's engineering standards require: "No empty `catch {}`,
no swallowing with `try?` unless the failure is genuinely ignorable and a
comment says why." `deduplicated(in:)`'s own `try? context.fetch(...)` *does*
carry such a comment ("A fetch failure is treated as 'no profile'
(best-effort)"), but the two `try? context.save()` sites added/touched in
this phase have no adjacent comment explaining why a save failure (e.g. disk
full, container invalidated) is safe to ignore. A silently-failed save here
means the in-memory object graph and the on-disk store diverge with zero
signal to the user or the log.
**Fix:** Add a one-line comment at each site (or route through a shared
helper that logs the failure at `.error` with a non-PII category), e.g.:
```swift
// Best-effort: a failed save here just re-opens the D-04 timing gap on the
// next @Query render; logged, not surfaced, since there's no user action to
// retry from this call site.
try? context.save()
```

### WR-03: `RootShellView.profiles` is now dead code

**File:** `drinkpulse/Features/Shell/RootShellView.swift:17`
**Issue:** `@Query private var profiles: [UserProfile]` has no remaining
reader anywhere in the file — its only consumer, the
`.onChange(of: profiles.isEmpty)` reverse-write, was deleted as part of D-01.
The property (and its live query subscription) is leftover dead code from an
incomplete cleanup.
**Fix:** Remove the property entirely:
```swift
// delete: @Query private var profiles: [UserProfile]
```

## Info

### IN-01: `StartupError.unknown` is unreachable from production

**File:** `drinkpulse/Domain/Persistence/StartupError.swift:13-17, 30-36`
**Issue:** `init(underlying:)` unconditionally maps every error to
`.storeUnavailable` (documented, intentional per Pitfall 1), which means the
`.unknown` case can currently only ever be reached by directly constructing
`StartupError.unknown` (as `StartupErrorTests` does). This is fine as a
forward-looking placeholder, but the case itself carries no comment noting
it's currently dead in production — only the initializer's comment implies
it.
**Fix:** Add a one-line note at the case declaration itself (`/// Currently
unreachable in production — see init(underlying:)`) so a future reader
scanning the enum alone isn't misled into thinking both cases are live.

### IN-02: Empty-string `accessibilityValue` on the Retry button

**File:** `drinkpulse/Features/Shell/StartupErrorView.swift:33`
**Issue:** `.accessibilityValue(isRetrying ? String(localized: "startup.error.retry.inProgress") : "")`
sets an explicit empty-string value when not retrying, which can cause
VoiceOver to announce a blank/empty value trait rather than simply omitting
one.
**Fix:** Use a conditional modifier instead of an empty-string sentinel:
```swift
.modifier(ConditionalAccessibilityValue(isRetrying ? String(localized: "startup.error.retry.inProgress") : nil))
```
or simply omit the modifier when `!isRetrying` via an `if isRetrying { ... }` view builder branch.

### IN-03: Diagnostic text is shown to the user without going through `String(localized:)`

**File:** `drinkpulse/Features/Shell/StartupErrorView.swift:38`
**Issue:** CLAUDE.md states unconditionally: "All user-facing strings go
through `String(localized:)`." `Text(error.diagnosticSummary)` renders a raw
Swift string literal (`"startup-error-category: store-unavailable"`)
directly on screen. This is clearly a deliberate, documented choice (D-08 —
never let this string carry PII or a path, so it must stay a fixed literal,
not translated), but the project rule as written doesn't carve out this
exception explicitly.
**Fix:** No functional change needed; add a one-line comment at the
`diagnosticSummary` declaration noting this is an intentional, permanent
exception to the localization rule (technical category code, not a
translatable message) so a future contributor doesn't "fix" it into a
localized string and risk it drifting per-locale.

---

_Reviewed: 2026-07-28T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
