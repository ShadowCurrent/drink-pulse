# Phase 3: App Startup Hardening - Research

**Researched:** 2026-07-27
**Domain:** SwiftUI app startup sequencing, SwiftData `ModelContainer` async loading, error-state UI, `@AppStorage` state ownership
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Onboarding authority (STARTUP-01)**
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

**Store-failure error UI (STARTUP-03)**
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

**Async container loading UX (STARTUP-02)**
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

### Deferred Ideas (OUT OF SCOPE)
None raised outside phase scope — discussion stayed within the three
STARTUP requirements. The branded/minimal loading view idea was
explicitly considered (Async container loading UX area) and deliberately
NOT added to this phase; it remains Cluster B scope via the existing
`2026-07-27-branded-static-launch-screen.md` todo.

No new ADR exists yet for D-01/D-02 — the planner or executor creates
`docs/decisions/0012-onboarding-single-source-of-truth.md` (next
available ADR number as of this discussion) during execution.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STARTUP-01 | Onboarding gate (`RootShellView`/`drinkpulseApp.swift`) has a single authoritative source of truth; a transient empty `@Query profiles` result no longer resets the user to onboarding mid-task | Pattern 2 (single-authority gate, delete reverse-write); Pitfall 5 (fetchOrCreate save-point audit); Validation Architecture row STARTUP-01 (unit + new D-03 UI regression test) |
| STARTUP-02 | `sharedModelContainer` creation no longer blocks the synchronous `App.init` path | Pattern 1 (`.task`-deferred `ContainerLoadState` state machine); Pitfall 3 (`.task` re-run guard); Assumption A1 (first-frame timing); Validation Architecture row STARTUP-02 |
| STARTUP-03 | The two `fatalError` container-failure call sites (`drinkpulseApp.swift:59,68`) are replaced with a real, designed user-facing error state | Pattern 3 (full-recovery-sequence retry); `StartupErrorView`/`StartupError` Code Examples; Pitfall 1 (non-PII error categorization); Security Domain V7/V8; Validation Architecture row STARTUP-03 |
</phase_requirements>

## Summary

This phase is a narrow, well-scoped concurrency + state-ownership fix inside
three files: `drinkpulseApp.swift`, `RootShellView.swift`, and
`StoreBootstrap.swift`/`UserProfileStore.swift`. All three STARTUP
requirements are variations on one theme: **stop treating a transient or
in-flight SwiftData signal as if it were a settled, authoritative fact.**

- STARTUP-01 removes a `@Query`-driven reverse-write that can fire on a
  single empty render and silently reset the user to onboarding.
- STARTUP-02 moves `ModelContainer` creation out of `App.init` (an
  eagerly-evaluated stored-property closure) so the first SwiftUI frame is
  not gated on disk I/O / migration work.
- STARTUP-03 replaces two `fatalError` calls with a designed, retryable
  error screen — using the exact same non-destructive recovery flow that
  already exists in `StoreBootstrap.makeContainer`.

There is no framework mystery here: `ModelContainer` is documented as
`Sendable` (safe to hand across a `Task` boundary), and the codebase's own
convention (`@State`-flag-in-`App`-struct, seen in `forceOnboardingPending`)
is directly reusable for "container ready" state — this is the answer to
D-12's open question. No new library, no new architectural layer. The two
places that need care are (1) not introducing a second onboarding source of
truth while fixing the first one, and (2) not leaking filesystem-path-bearing
error text into the new user-facing error screen (CLAUDE.md logging/privacy
rules apply to UI text too, not just `os.Logger` calls).

**Primary recommendation:** Introduce a single `@State private var
containerState: ContainerLoadState` enum (`.loading`, `.ready(ModelContainer)`,
`.failed(StartupError)`) in `drinkpulseApp`, populate it from a `.task` on a
lightweight root `Group` (not from the `sharedModelContainer` stored
property), and gate `RootShellView`/`OnboardingView` construction — and their
`.modelContainer(_:)` attachment — behind `.ready`. Keep
`StoreBootstrap.makeContainer` `@MainActor` and synchronous/throwing exactly
as it is today; do not attempt to move it to a background thread — the win is
purely in *when* it runs (after first frame, inside `.task`), not *which
actor* runs it. Delete the `RootShellView.onChange(of: profiles.isEmpty)`
reverse-write entirely; `onboardingDone` becomes write-only from explicit user
actions (`OnboardingView.onFinish`, and — later — a delete-all-data flow per
the new ADR-0012 contract).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Onboarding gate authority (`onboardingDone`) | Frontend (SwiftUI `App`/`RootShellView`) | — | Pure view-routing state; no backend, no persistence layer beyond `@AppStorage` (UserDefaults) |
| `ModelContainer` lifecycle (open, recover, fail) | Domain / Persistence (`StoreBootstrap`) | Frontend (`drinkpulseApp` orchestrates *when* it's called) | `StoreBootstrap` already owns open/recover logic (ADR-0009); this phase changes only *when* the App layer calls it and what it shows on failure |
| Store-failure error UI | Frontend (SwiftUI View) | — | Full-screen SwiftUI view per D-05; no new service/domain type needed |
| Missing `context.save()` after profile insert (D-04) | Domain / Persistence (`UserProfileStore`) | — | Data-integrity fix scoped to the exact function that creates the timing gap |
| Regression UI-test hook (mid-session profile deletion) | Test infrastructure (`UITestSeed`) | — | Extends the existing launch-argument-gated hook convention; inert in production |

There is no API/backend or CDN tier in this app (on-device only, per
CLAUDE.md) — all capabilities above live in the Frontend/Domain tiers.

## Standard Stack

This phase does not add any new third-party dependency, package, or SDK.
Everything needed is native SwiftUI + SwiftData, already in use in the
codebase.

### Core (already in project — no new packages)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftData | iOS 26 SDK | `ModelContainer`, `ModelConfiguration`, `Schema` | Project-mandated persistence layer (CLAUDE.md) |
| SwiftUI `.task` modifier | iOS 26 SDK | Defers async work until after the view's first appearance | Apple-documented mechanism for post-first-frame async work; view-scoped, auto-cancelled |
| `@Observable`/`@State` | iOS 26 SDK (Observation) | Holds `containerState` in the `App` struct | Matches existing `forceOnboardingPending` convention; no `ObservableObject` per CLAUDE.md |

### Package Legitimacy Audit

**Not applicable — no external packages are introduced by this phase.**
All work uses first-party Apple frameworks already present in the project
(`SwiftUI`, `SwiftData`, `Foundation`, `OSLog`). Skip the legitimacy gate.

## Architecture Patterns

### System Architecture Diagram

```
Process launch
     │
     ▼
drinkpulseApp.init()                    ← synchronous, MUST stay cheap
     │  - UITestSeed.resetTransientDefaults() (no-op in prod)
     │  - notification delegate wiring
     │  - NO ModelContainer creation here anymore (moved out)
     ▼
WindowGroup { RootLaunchGate }          ← first frame renders HERE
     │
     ▼
RootLaunchGate.task { }                 ← runs AFTER first frame is shown
     │
     ├─▶ StoreBootstrap.makeContainer(...)   [@MainActor, throws, unchanged internals]
     │        │
     │        ├─ success ──▶ containerState = .ready(container)
     │        │
     │        └─ failure (after internal recoverStore retry
     │                     already failed too) ──▶ containerState = .failed(error)
     │
     ▼
switch containerState:
   .loading  → existing launch-screen-matching placeholder (no new UI, D-11)
   .ready    → Group { onboardingDone ? RootShellView() : OnboardingView() }
                   .modelContainer(container)   ← attached HERE, not at Scene level
   .failed   → StartupErrorView(onRetry: { containerState = .loading; retry })
                   - Retry re-runs the FULL makeContainer sequence (D-06)
                   - button disabled + spinner while in flight (D-10)
                   - no destructive "erase" option (D-07)
```

Within `.ready`, the existing onboarding gate (`onboardingDone` `@AppStorage`,
sole authority per D-01) decides `RootShellView` vs `OnboardingView` exactly
as today — this phase does not change *that* branch's shape, only removes the
reverse-write that used to corrupt it.

### Recommended Structure (no new files/folders required)

This phase edits existing files in place; no new feature folder is needed.
If the `ContainerLoadState` enum and `StartupErrorView` grow non-trivially,
CLAUDE.md's 300-line file-size rule applies — likely split as:

```
drinkpulse/
├── drinkpulseApp.swift              # trimmed: init(), body, .task orchestration
├── Domain/Persistence/
│   ├── StoreBootstrap.swift         # unchanged internals; maybe +1 small
│   │                                 #   "categorize error" helper (D-06)
│   └── ContainerLoadState.swift     # NEW (small): the 3-case enum, if body
│                                     #   composition needs it decoupled
└── Features/Shell/
    ├── RootShellView.swift          # .onChange(profiles.isEmpty) DELETED
    └── StartupErrorView.swift       # NEW: full-screen error + retry (D-05/D-06)
```

### Pattern 1: Defer `ModelContainer` creation past `App.init` via `.task`

**What:** Replace the eagerly-evaluated `var sharedModelContainer:
ModelContainer = { ... }()` stored property with `@State private var
containerState: ContainerLoadState = .loading`, and call
`StoreBootstrap.makeContainer` from inside `.task { await loadContainer() }`
attached to the outermost view in `WindowGroup`.

**When to use:** Any time a SwiftUI `App`'s synchronous `init`/stored-property
path does real I/O that should not block the first frame.

**Why this satisfies STARTUP-02 without moving work off the main actor:**
SwiftUI does not render the first frame during `App.init()` — it renders it
once the `Scene`'s view hierarchy has been constructed and laid out.
`onAppear`/`.task` run *after* that initial layout pass, not during it
[CITED: community consensus across multiple SwiftUI startup-optimization
write-ups — no single normative Apple doc pins this exact ordering guarantee,
tag as MEDIUM confidence]. So simply moving the `try
ModelContainer(...)` call from a stored-property closure (evaluated
synchronously as part of struct init, before any frame exists) into a
`.task` closure (which only runs once a view has appeared) is sufficient to
unblock the first frame — regardless of which actor the work subsequently
runs on. Keeping it on `@MainActor` (as `StoreBootstrap.makeContainer`
already is) avoids relitigating whether `ModelContainer.init` is safe to call
off the main actor, which the codebase does not currently need to answer.

**Example (shape, not literal, of the new `drinkpulseApp.swift`):**
```swift
// Source: pattern synthesized from Apple's own "structured startup" guidance
// plus the existing Xcode-template ModelContainer-error-handling pattern
// (see Sources — Mike Buss, "SwiftData Error Handling in Xcode Templates").
enum ContainerLoadState {
    case loading
    case ready(ModelContainer)
    case failed(StartupError)
}

@main
struct drinkpulseApp: App {
    @AppStorage(AppStorageKeys.onboardingDone) private var onboardingDone = false
    @State private var containerState: ContainerLoadState = .loading
    @State private var isRetrying = false
    // ...existing @State healthService, forceOnboardingPending unchanged...

    var body: some Scene {
        WindowGroup {
            Group {
                switch containerState {
                case .loading:
                    LaunchPlaceholderView()          // reuses existing launch-screen look, D-11
                case .ready(let container):
                    Group {
                        if onboardingDone && !forceOnboardingPending {
                            RootShellView()
                        } else {
                            OnboardingView(onFinish: { onboardingDone = true; forceOnboardingPending = false })
                        }
                    }
                    .modelContainer(container)        // attached here, not at Scene level
                case .failed(let error):
                    StartupErrorView(error: error, isRetrying: isRetrying, onRetry: retryContainerLoad)
                }
            }
            .task { await loadContainerIfNeeded() }
        }
        // NOTE: .modelContainer(sharedModelContainer) at the Scene level is REMOVED —
        // it required a container to exist synchronously, which is exactly what's being fixed.
    }

    @MainActor
    private func loadContainerIfNeeded() async {
        guard case .loading = containerState else { return }
        if UITestSeed.isActive {
            // In-memory container creation is effectively instant; still routed
            // through the same state machine so tests exercise the same code path.
            do { containerState = .ready(try UITestSeed.makeContainer(schema: schema)) }
            catch { containerState = .failed(.init(underlying: error)) }
            return
        }
        let configuration = StoreBootstrap.productionConfiguration(schema: schema)
        do {
            containerState = .ready(try StoreBootstrap.makeContainer(schema: schema, configuration: configuration))
        } catch {
            containerState = .failed(.init(underlying: error))
        }
    }

    @MainActor
    private func retryContainerLoad() {
        isRetrying = true
        containerState = .loading
        Task {
            await loadContainerIfNeeded()
            isRetrying = false
        }
    }
}
```

### Pattern 2: Single-authority `@AppStorage` gate (delete the reverse-write)

**What:** `onboardingDone` is read in exactly the places it already is
(`drinkpulseApp.body`), and is **only ever written** from
`OnboardingView.onFinish` (existing) — never from a `@Query` observer.

**When to use:** Any boolean/state flag that gates top-level navigation and
must not flicker due to a transient upstream signal (query re-render, sync
merge, migration in progress).

**Example — the deletion (D-01):**
```swift
// RootShellView.swift — DELETE this block entirely (currently lines 97-99):
// .onChange(of: profiles.isEmpty) { _, isEmpty in
//     if isEmpty { onboardingDone = false }
// }
```
No replacement observer is added. `profiles.isEmpty` becomes purely
informational (if used at all elsewhere) — never a trigger for navigation
state. `@Query private var profiles: [UserProfile]` in `RootShellView` can
stay for other reads (e.g. Settings profile row logic elsewhere in the file
tree), but this phase's job is to sever its link to the onboarding gate.

### Pattern 3: `ModelContainer` retry — repeat the *whole* recovery sequence, not a shortcut

**What:** The Retry button calls the same `StoreBootstrap.makeContainer`
entry point used at launch — which internally already does open → (on
failure) `recoverStore` move-aside → open again (`StoreBootstrap.swift:42-55`,
unchanged). Do not add a second, different "just make an empty store" retry
path — that would silently discard data recovery opportunities.

**Example:**
```swift
// StartupErrorView's retry action calls back up to the SAME
// loadContainerIfNeeded()/retryContainerLoad() used above — no new
// "quick recreate" function. D-06 is explicit about this.
```

### Anti-Patterns to Avoid

- **Two onboarding gates:** Do not add a *second* `@AppStorage`/`@State` flag
  that also influences the `RootShellView` vs `OnboardingView` branch (e.g. a
  "container just became ready, also re-check profile existence" check). One
  flag (`onboardingDone`), one writer path (`OnboardingView.onFinish` + future
  delete flow). This is the exact bug being fixed — do not reintroduce a
  second source of truth while fixing the first.
- **Applying `.modelContainer(_:)` at the `Scene` level with an optional or
  placeholder container:** `.modelContainer(_:)` expects a real
  `ModelContainer`. Do not construct a throwaway empty in-memory container
  just to satisfy the modifier while the real one loads — that would give
  `.loading`-state views (if any ever query `@Environment(\.modelContext)`
  or `@Query`) a phantom empty store to observe. Keep `.modelContainer(_:)`
  scoped only to the subtree that actually has a real container (the
  `.ready` case), as shown in Pattern 1.
- **Surfacing raw `Error.localizedDescription` in the error screen:** SwiftData
  errors and `FileManager` errors can embed absolute filesystem paths (which
  may include the device's real, though not user-identifying, container
  path) and internal SQLite diagnostic strings. D-08 requires generic copy;
  D-06 requires only a coarse, non-PII "category" for the copyable
  diagnostic text — never the raw error string. See Common Pitfalls below.
- **Retry attempt counters / exponential backoff:** Explicitly rejected by
  D-09. Do not add rate-limiting logic the user didn't ask for.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting "is the container in a good state" | A custom health-check ping against the store | The existing `StoreBootstrap.makeContainer` try/catch — it already reports success/failure via Swift's native throwing mechanism | Redundant health-check logic would just re-implement what `ModelContainer.init` already tells you by throwing |
| Retry backoff / rate limiting | Attempt counters, exponential backoff, cooldown timers | Nothing — D-09 explicitly says no rate limit is needed | Adds unrequested complexity; user-initiated taps are inherently rate-limited by human interaction speed |
| Non-destructive store recovery on corruption | A new move-aside-and-retry mechanism for the error screen's Retry button | `StoreBootstrap.makeContainer`'s existing internal recovery (already calls `recoverStore` on first failure before the caller ever sees an error) | Already built, already tested (`StoreBootstrapTests.swift`); Retry just re-invokes the same entry point |
| Error categorization for the "Contact/report" diagnostic text | A parsing layer that inspects `NSError` domains/codes ad hoc at the UI call site | A small, dedicated `StartupError` type that does this categorization once, in `Domain/Persistence/`, testable in isolation | Keeps the categorization logic out of the View layer and unit-testable per CLAUDE.md's Domain-layer 100% coverage target |

**Key insight:** Nearly everything this phase needs already exists in the
codebase (`StoreBootstrap`'s recovery logic, `UITestSeed`'s launch-argument
hook convention, the `@State`-flag-in-`App`-struct pattern). The work is
almost entirely *rewiring where these pieces are called from and who is
allowed to write to `onboardingDone`* — not building new mechanisms.

## Common Pitfalls

### Pitfall 1: Leaking filesystem paths or SQLite internals into the error screen

**What goes wrong:** `error.localizedDescription` on a SwiftData/Core Data
-backed `NSError` frequently includes the full on-disk store path and
low-level SQLite failure text (e.g. `NSCocoaErrorDomain Code=134060`, path
under `Application Support/...`). Surfacing this raw string in a "Contact
Support" copyable field violates D-08's "generic copy" requirement and the
CLAUDE.md rule against exposing internal implementation detail to users.

**Why it happens:** It is the path of least resistance to just do `Text(error
.localizedDescription)` in a new error view.

**How to avoid:** Build a small `StartupError` (or similarly named) type in
`Domain/Persistence/` that maps the underlying thrown `Error` to a **coarse
category** — e.g. `.storeUnavailable`, `.recoveryFailed`, `.unknown` — and
exposes only that category (plus, optionally, the `NSError` domain+code pair,
which is not PII) as the copyable diagnostic string. Never interpolate
`localizedDescription` or the `ModelConfiguration.url` into user-facing text.
[ASSUMED: exact categorization taxonomy — 3 known SwiftData `ModelContainer`
failure classes were surfaced by community investigation (schema-version
mismatch / "unknown model version", low disk space, concurrent-migration race)
but there is no exhaustive first-party enumeration of all `ModelContainer`
throw cases — treat any categorization as best-effort, with an `.unknown`
catch-all]

### Pitfall 2: `.modelContainer(_:)` applied before a real container exists

**What goes wrong:** If `.modelContainer(_:)` (or `@Environment(\.modelContext)`
/ `@Query`) is reachable in the `.loading` or `.failed` states — e.g. because
a shared placeholder view accidentally sits inside the same view tree as
`RootShellView`/`OnboardingView` instead of being a true sibling branch —
SwiftUI will crash or silently create an unwanted default in-memory store
depending on version/context. Keep the state-machine `switch` exhaustive and
make sure only the `.ready` branch's subtree ever touches SwiftData.

**Why it happens:** Refactoring an existing `if onboardingDone { A } else { B
}` into a three-state switch is easy to get subtly wrong by leaving a
shared parent view that still expects `@Environment(\.modelContext)` to be
populated.

**How to avoid:** `.modelContainer(container)` must be attached to the
smallest subtree that actually needs it (the `Group` wrapping
`RootShellView`/`OnboardingView` in Pattern 1's example), not to the
`WindowGroup`/`Scene` itself, and not to the `.loading`/`.failed` branches.

### Pitfall 3: `.task` re-running on every view re-render / re-triggering a load already in flight

**What goes wrong:** `.task` re-runs if its identity-relevant inputs change
or the view is recreated; naively calling `loadContainer()` from `.task`
without a guard could kick off a second concurrent
`StoreBootstrap.makeContainer` call (e.g. if the outer `Group` is recreated
for any reason while still `.loading`).

**Why it happens:** `.task {}` (without an `id:`) is tied to the view's
identity/lifecycle, and the outer `Group`'s identity in a `switch`-driven
body can be less stable than expected.

**How to avoid:** Guard `loadContainerIfNeeded()` with `guard case .loading =
containerState else { return }` (shown in Pattern 1) so a second invocation
while already `.ready` or already loading again via Retry's own `Task` is a
no-op. Since `StoreBootstrap.makeContainer` involves real disk I/O, an
accidental double-invocation is wasted work, not a correctness bug per se
(SwiftData does not maintain global mutable state that a second `open`
call would corrupt) — but avoiding it keeps startup deterministic and
testable.

### Pitfall 4: UI tests timing out because the async gate adds a real (if small) delay

**What goes wrong:** Every existing onboarding UI test
(`OnboardingFlowUITests`, `OnboardingLocaleDefaultUITests`,
`OnboardingHealthStepUITests`, `OnboardingWeeklySummaryUITests`) currently
launches the app and immediately looks for `"Get Started"`
(`waitForExistence(timeout: 10)`), implicitly relying on
`sharedModelContainer` having already been built synchronously by the time
`launch()` returns control. After this phase, the in-memory container is
built inside `.task`, one runloop tick later than before.

**Why it happens:** The existing 5–10s `waitForExistence` timeouts were
generous even before this change; an in-memory `ModelConfiguration` open is
sub-millisecond, so in practice this should not regress. But if the
state-machine `switch` is implemented with any conditional view identity
churn (Pitfall 3's failure mode) the extra render pass could theoretically
add visible flicker.

**How to avoid:** Keep existing `waitForExistence` timeouts as-is (they
already tolerate normal SwiftUI settle time); do not shorten them. Add the
new D-03 regression test using the same `waitForExistence` idiom. Manually
verify (or note as a UAT checkpoint) that onboarding UI tests still pass
after the refactor — this is explicitly Success Criterion 5 in the phase
scope.

### Pitfall 5: `context.save()` added in `UserProfileStore.fetchOrCreate` masking a caller that expected to control the save point

**What goes wrong:** `UserProfileStore.fetchOrCreate` is called from
multiple sites (production `RootShellView`, and — per the existing test file
— test code explicitly calls `try context.save()` right after). Adding an
internal `try? context.save()` (D-04) inside `fetchOrCreate` itself means a
caller that batches multiple inserts before saving (if any exists) would now
get an intermediate save it didn't ask for.

**Why it happens:** `context.save()` is a global-to-the-context operation —
it flushes *everything* pending in that `ModelContext`, not just the
`UserProfile` insert.

**How to avoid:** Before adding the `try? context.save()`, grep every call
site of `UserProfileStore.fetchOrCreate` (`RootShellView.swift` and any
other production call site) to confirm no caller relies on deferring the
save (e.g. because it's about to insert a paired `ConsumptionEvent` in the
same unsaved transaction). If such a caller exists, the D-04 fix may need a
`save: Bool = true` parameter or an explicit save-after-insert convention
documented at the call site instead of an unconditional internal save.
Existing unit tests (`UserProfileStoreTests.swift`) already call
`context.save()` redundantly after `fetchOrCreate` — that stays harmless
(SwiftData tolerates a save with nothing new pending).

## Code Examples

### Full-screen error view shape (D-05, D-06, D-10)

```swift
// Source: pattern synthesized from Apple's ContentUnavailableView conventions
// (already used elsewhere in this codebase — see HistoryView.swift's emptyState)
// plus D-05/D-06/D-10's explicit requirements. Not a literal copy of any
// external source — assembled from project conventions + locked decisions.
struct StartupErrorView: View {
    let error: StartupError
    let isRetrying: Bool
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(
                String(localized: "startup.error.title"), // "Something went wrong loading your data."
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text(String(localized: "startup.error.body")) // "Try again."
        } actions: {
            Button(action: onRetry) {
                if isRetrying {
                    ProgressView()
                } else {
                    Text(String(localized: "startup.error.retry"))
                }
            }
            .disabled(isRetrying)
            .accessibilityLabel(String(localized: "startup.error.retry.accessibilityLabel"))

            // Non-PII diagnostic, copy-paste only (no live support channel exists yet).
            ShareLink(item: error.diagnosticSummary) {
                Text(String(localized: "startup.error.contact"))
            }
        }
    }
}
```

`ContentUnavailableView`'s three-closure initializer (`label:`,
`description:`, `actions:`) is already the codebase's established
empty/error-state idiom (`HistoryView.emptyState`), so reusing it here for
the startup error screen is consistent with existing conventions rather than
introducing a new visual pattern — even though D-05 calls for a full custom
screen, `ContentUnavailableView` composed with custom actions satisfies "icon
+ plain-language message + action button(s)" without inventing new chrome.

### `StartupError` categorization (Pitfall 1)

```swift
// Domain/Persistence/StartupError.swift (new, small file)
enum StartupError: Error, Equatable {
    case storeUnavailable   // ModelContainer.init failed even after recoverStore retry
    case unknown

    /// Non-PII, copy-paste diagnostic text — category only, never the
    /// underlying error's localizedDescription or any file path.
    var diagnosticSummary: String {
        switch self {
        case .storeUnavailable: "startup-error-category: store-unavailable"
        case .unknown:          "startup-error-category: unknown"
        }
    }

    init(underlying: Error) {
        // Best-effort coarse categorization — see Pitfall 1 for why this
        // stays deliberately shallow rather than parsing NSError codes.
        self = .storeUnavailable
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `fatalError` on `ModelContainer` open failure (Apple's own Xcode 15/16 SwiftData project template default) | Structured `loading`/`ready`/`failed` state machine with a retry-capable error view | Community best practice since SwiftData's GA (2023); still the default Xcode template behavior as of this research — teams are expected to replace it manually | Prevents unrecoverable crashes on first-run migration or disk issues; this phase is exactly this well-known fix, applied to this codebase's specific structure |
| Building `ModelContainer` synchronously as an `App` stored property | Deferring via `.task` after first frame | No version-gated API change — this is a structuring choice available since SwiftUI's `App` protocol existed; only newly *necessary* here because this app now does real recovery work (`StoreBootstrap`) that can take longer than instant | First frame renders immediately; store-open work (migration, recovery) no longer holds the launch window |

**Deprecated/outdated:** None — no APIs used here are deprecated. This is a
structural/pattern change, not an API migration.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | SwiftUI defers `.task`/`onAppear` execution until after the first frame has been laid out/rendered, so moving `ModelContainer` creation into `.task` genuinely unblocks "first frame drawn before store finishes opening" (Success Criterion 3) | Pattern 1 | If SwiftUI's actual scheduling coalesces `.task` execution with the first frame commit in some cases (e.g. certain `WindowGroup` configurations), the perceptible win could be smaller than expected — mitigate by verifying with Instruments (App Launch template) during execution, not just code review |
| A2 | `ModelContainer.init` does not strictly require running on `@MainActor` at the framework level (only this codebase's own convention isolates `StoreBootstrap.makeContainer` to `@MainActor`) | Pattern 1 discussion | Low risk — the plan does not depend on this being true; it explicitly recommends *keeping* the existing `@MainActor` isolation rather than changing it. Flagged only so the planner doesn't feel obligated to "verify and move it off-main-actor" as part of this phase — that would be scope creep beyond D-11's "technical unblock only" |
| A3 | The exhaustive list of `ModelContainer` failure categories (schema-version mismatch, low disk space, concurrent-migration race) is not officially documented by Apple as a closed set — it's inferred from community failure-report investigation | Pitfall 1 / Code Examples (`StartupError`) | If a failure mode outside these categories occurs, the `.unknown` catch-all handles it gracefully (no crash), so risk is contained; do not build UI copy that claims to enumerate "the" causes |
| A4 | No production call site of `UserProfileStore.fetchOrCreate` other than `RootShellView` currently relies on deferring `context.save()` past the point `fetchOrCreate` returns | Pitfall 5 | If a caller does exist and is missed, D-04's added `context.save()` could commit a partially-built object graph earlier than intended — mitigate by grepping all call sites during planning/execution, not just trusting this assumption |

## Open Questions

1. **Should `LaunchPlaceholderView` (the `.loading` state's content) be a
   literal blank/clear view, or must it visually match the system launch
   screen to avoid a flash-of-different-background?**
   - What we know: D-11 explicitly says "no new visible loading UI is added
     ... the existing launch screen / background holds until the container
     is ready."
   - What's unclear: whether "the existing launch screen" means the iOS
     system-rendered `LaunchScreen` storyboard/asset-catalog launch image
     handing off cleanly to an equivalent SwiftUI `Color`/background, or
     whether the current app already has some SwiftUI-rendered placeholder
     that this phase should just leave in place unchanged.
   - Recommendation: planner should grep for the current launch-screen asset
     configuration (`Info.plist` `UILaunchScreen` key /
     `LaunchScreen.storyboard`) and confirm the `.loading` state's background
     color matches it, so there's no visible flash between system launch
     screen and the SwiftUI `.loading` placeholder. This is a small
     verification task, not a design decision (D-11 already settled the
     "no new UI" scope).

2. **Does any other production call site besides `RootShellView` call
   `UserProfileStore.fetchOrCreate`?**
   - What we know: `RootShellView.swift` is the call site referenced in the
     todo/context docs.
   - What's unclear: whether Settings, onboarding, or the data-import flow
     also call it directly.
   - Recommendation: `grep -rn "UserProfileStore.fetchOrCreate"
     drinkpulse/` during planning to enumerate all call sites before adding
     the D-04 `context.save()`, per Pitfall 5.

## Environment Availability

Skip — this phase has no external tool/service dependencies. All work is
Xcode-project-local Swift/SwiftUI/SwiftData code; build/test tooling
(`xcodebuild`) is already verified working per Phase 2's completion.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`Testing` module, `@Test`/`#expect`) for unit tests; XCTest (`XCUITest`) for UI tests — both already in use project-wide |
| Config file | None — no `.xctestplan`; driven by scheme defaults (`xcodebuild test -scheme drinkpulse`) |
| Quick run command | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests/StoreBootstrapTests` (swap target per file under test) |
| Full suite command | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STARTUP-01 | A transient empty `@Query profiles` result does not reset `onboardingDone` | unit + UI | `xcodebuild test -only-testing:drinkpulseTests/UserProfileStoreTests` (unit, existing) + new UI test (D-03) | ✅ unit / ❌ UI test — Wave 0 |
| STARTUP-01 (D-03 regression) | Mid-session profile deletion via a new test-only hook does NOT drop the app back to `OnboardingView` | UI (XCUITest) | `xcodebuild test -only-testing:drinkpulseUITests/<NewOnboardingAuthorityUITests>` | ❌ Wave 0 — new file + new `UITestSeed` hook needed |
| STARTUP-02 | `sharedModelContainer`/container creation does not run synchronously in `App.init` | unit (behavioral, via `StoreBootstrapTests`) + manual Instruments verification | `xcodebuild test -only-testing:drinkpulseTests/StoreBootstrapTests` (existing, unaffected — `StoreBootstrap.makeContainer` itself is unchanged) | ✅ existing coverage of `makeContainer`'s own behavior; the *timing* claim (not run during `init`) is structural and best verified by code review + a manual launch-time check, not a unit test |
| STARTUP-03 | Container-open failure shows a designed error view with Retry, not a crash | unit (`StartupError` categorization) + UI (error screen presence, retry disables button) | New `StartupErrorTests` (unit) + new `StartupErrorUITests` (UI, needs a launch-argument hook to force a container-open failure deterministically) | ❌ Wave 0 — both new |
| STARTUP-03 (D-10) | Retry button disables + shows spinner while in flight | UI | Part of the same new `StartupErrorUITests` | ❌ Wave 0 |
| Existing onboarding UI tests still pass (Success Criterion 5) | `forceOnboardingPending`/`UITestSeed.forceShowOnboarding` unaffected | UI (regression, existing files) | `xcodebuild test -only-testing:drinkpulseUITests/OnboardingFlowUITests -only-testing:drinkpulseUITests/OnboardingLocaleDefaultUITests -only-testing:drinkpulseUITests/OnboardingHealthStepUITests -only-testing:drinkpulseUITests/OnboardingWeeklySummaryUITests` | ✅ files exist — must re-run and confirm green after the refactor, no new file needed |

### Sampling Rate
- **Per task commit:** run the specific new/changed test target
  (`StoreBootstrapTests`, `UserProfileStoreTests`, or the new UI test file)
  via `-only-testing:`.
- **Per wave merge:** full `xcodebuild test -scheme drinkpulse` suite green,
  including all four existing onboarding UI test files (regression gate).
- **Phase gate:** Full suite green before `/gsd-verify-work`, plus a manual
  Instruments "App Launch" trace (or simple stopwatch/log-timestamp check)
  confirming the first frame is not blocked on `StoreBootstrap.makeContainer`
  — this specific claim (STARTUP-02's "first frame before store settles") is
  not mechanically provable by `xcodebuild test` alone.

### Wave 0 Gaps
- [ ] New UI test file for D-03: mid-session profile-deletion regression
      (proves `onboardingDone` alone gates the view, independent of
      `profiles` query state) — extends `UITestSeed` with a new launch-argument
      or in-app test-only hook per D-03's instruction, not a parallel
      mechanism.
- [ ] New `StartupErrorView` + `StartupError` unit tests (categorization
      logic, `Equatable` conformance if used for state comparison).
- [ ] New UI test(s) for the error screen: needs a deterministic way to force
      `StoreBootstrap.makeContainer` to fail under `-dp_uitest` (e.g. a new
      launch argument like `-dp_uitest_force_store_failure YES` that makes
      `UITestSeed.makeContainer` throw) so the error screen, Retry-disables,
      and spinner states are all UI-testable without real disk corruption.
- [ ] ADR `docs/decisions/0012-onboarding-single-source-of-truth.md` (D-02) —
      documentation artifact, not a test, but required by this phase's
      definition of done per CONTEXT.md.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | App has no accounts (CLAUDE.md "no login/account systems") |
| V3 Session Management | No | No sessions beyond app-local UI state |
| V4 Access Control | No | Single-user, on-device, no roles |
| V5 Input Validation | No | This phase introduces no new user input surface (error screen is read-only + a button) |
| V6 Cryptography | No | No new crypto surface |
| V7 Error Handling & Logging | **Yes** | Never surface raw error internals (stack traces, file paths, SQLite diagnostics) to the user-facing error screen; log via `os.Logger` with `privacy: .private` for anything derived from the error, per CLAUDE.md's existing logging rules — this phase's `StartupError` categorization (Pitfall 1) is the concrete control |
| V8 Data Protection | **Yes** | The error screen's "Contact/report" diagnostic text must stay non-PII (D-06) — category/code only, never file paths or user data, consistent with `docs/domain.md`'s sensitive-field list |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Information disclosure via verbose error messages (filesystem paths, internal store structure leaked to a "Contact/report" copyable field that could be pasted into a public bug report or support email) | Information Disclosure | Coarse error categorization only (`StartupError`, Pitfall 1) — never `localizedDescription` or `ModelConfiguration.url` in user-facing text |
| Denial of service via unbounded retry loop hammering a corrupted store | Denial of Service (self-inflicted, not attacker-driven) | Explicitly out of scope per D-09 (no rate limit needed) — each Retry is a deliberate single user tap, not an automated loop; low risk in a single-user offline app |
| Silent data loss via a "quick fix" retry that recreates an empty store instead of re-attempting real recovery | Tampering / data integrity | D-06/D-07: Retry always re-runs the *full* `StoreBootstrap.makeContainer` sequence (including its internal non-destructive `recoverStore` move-aside); no destructive "erase and start fresh" shortcut exists in this phase |

## Sources

### Primary (HIGH confidence)
- `drinkpulse/drinkpulseApp.swift`, `RootShellView.swift`,
  `StoreBootstrap.swift`, `UserProfileStore.swift`, `UITestSeed.swift` — read
  directly, current on-disk state as of this research.
- `docs/architecture.md`, `docs/decisions/0008-services-layer.md`,
  `docs/decisions/0009-versioned-schema-and-migration-plan.md` — read
  directly.
- Project build settings (`project.pbxproj`) — confirmed `SWIFT_VERSION =
  6.0` and `IPHONEOS_DEPLOYMENT_TARGET = 26.0` across all targets via grep.
- `.planning/phases/03-app-startup-hardening/03-CONTEXT.md` — locked
  decisions D-01 through D-12.

### Secondary (MEDIUM confidence)
- [Leveling Up SwiftData Error Handling in Xcode Templates — Mike Buss](https://www.mikebuss.com/posts/swiftdata-template) — direct precedent for the `loading`/`loaded`/`error` state-machine shape in an `App` struct with a retryable `ErrorView`; independently arrived-at pattern matches this research's recommendation.
- [All the ways SwiftData's ModelContainer can Error on Creation — Scott Driggers](https://scottdriggers.com/blog/swiftdata-modelcontainer-creation-crash/) — enumerates known `ModelContainer` failure modes (schema mismatch code 134504, disk space, concurrent-migration races 134110/134100) used to inform Pitfall 1 and the `StartupError` categorization sketch.
- WebSearch results confirming `ModelContainer` is `Sendable` (multiple independent community sources: BrightDigit's ModelActor tutorial, Fatbobman's concurrent-programming-in-SwiftData post) — used to support that passing a `ModelContainer` out of a `Task`/`.task` closure into `@State` is safe under Swift 6 strict concurrency.

### Tertiary (LOW confidence)
- [Async initialization of the SwiftUI app — Viacheslav Tkachenko](https://medium.com/@tkachenko.slava/async-iniatilization-of-the-swiftui-app-62920f6d2ec9) — confirms `.task`/`onAppear` both run after first appearance (supports Assumption A1) but ultimately recommends a riskier unsafe-global-variable workaround for a *different* problem (avoiding flash-of-wrong-screen for login-state); not adopted here — noted only for the "runs after first appearance" observation.
- General claim that SwiftUI defers `.task` execution until after first-frame layout (Assumption A1) is corroborated across multiple blog posts but not pinned to a single authoritative Apple document — tagged MEDIUM/LOW and flagged for Instruments-based verification during execution rather than treated as certain.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; entirely existing project conventions and first-party Apple frameworks.
- Architecture: HIGH — the state-machine pattern is directly derived from the codebase's own existing `@State`-flag convention plus a well-corroborated community pattern (Mike Buss) that matches Apple's own (unfixed) Xcode template shape.
- Pitfalls: MEDIUM — the SwiftData `ModelContainer` failure-mode taxonomy (Pitfall 1) and the exact first-frame-timing guarantee (Assumption A1) are community-sourced, not from a single normative Apple document; both are flagged and have a safe fallback (`.unknown` category; Instruments verification) if the assumption is imprecise.

**Research date:** 2026-07-27
**Valid until:** 2026-08-26 (30 days — SwiftUI/SwiftData startup patterns are stable; no fast-moving dependency involved)
