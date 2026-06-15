# CLAUDE.md

## Project

iOS app for tracking personal alcohol consumption and comparing it
against health guidelines (WHO + country profiles). Privacy-first,
offline-first, no account required.

Target: iPhone first. iPad and Apple Watch later.
Minimum deployment: iOS 18.

## Documentation to consult before starting

Before working on anything substantial, read in this order:

1. `.claude/context/current-focus.md` — what we're working on right now
2. `.claude/context/open-questions.md` — unresolved decisions
3. `docs/plans/INDEX.md` — active plans (anything `in-progress`)
4. `docs/product.md` — product vision, scope, user stories
5. `docs/domain.md` — domain rules (alcohol calculations, guidelines, units)
6. `docs/architecture.md` — system architecture and patterns
7. `docs/decisions/` — ADRs for significant technical decisions

If you're picking up mid-task, check `docs/DEVLOG.md` for the latest entry.

**While reading, watch for contradictions** between docs and the
current state of the code. If you spot one, surface it before
starting the task — outdated docs cause bad assumptions.

## Documentation update model

Project documentation falls into three categories. Each has different
update rules.

### Append-only (history)
Never edited, only appended to. Old entries stay forever.
- `docs/DEVLOG.md` — session log
- `docs/plans/NNNN-*/execution.md` — execution journal
- `docs/plans/NNNN-*/retrospective.md` — post-completion analysis

### Immutable after freeze
Editable while in `draft` status, frozen after that.
- `docs/plans/NNNN-*/plan.md`
- `docs/decisions/NNNN-*.md` (ADRs — accepted = frozen)

### Living documents (must reflect current state)
These describe the project AS IT IS NOW. Outdated = broken.
Update whenever the reality they describe changes.

| File | Triggers update when... |
|------|------------------------|
| `README.md` | Public-facing facts change: features list, stack, build commands, project structure, status |
| `docs/product.md` | Vision, scope, in/out-of-scope items, target users change |
| `docs/architecture.md` | New layer, pattern, module boundary, or architectural rule is introduced or changed |
| `docs/domain.md` | Domain rules change: calculations, units, guideline definitions, entity relationships |
| `docs/roadmap.md` | Item completed, scope shifted, priority changed |
| `.claude/context/current-focus.md` | Active focus changes |
| `.claude/context/open-questions.md` | Question added or resolved |

### Living docs are part of the change
If you change code that contradicts what a living doc says, the doc
update is part of the same task — not a follow-up. The task is not
done until the doc matches reality.

### Language: English only
**All documentation and notes — every `.md` file, plus `plan.md`,
`execution.md`, `retrospective.md`, ADRs, DEVLOG entries, context files,
and any code comments — must be written in English.** No other language,
even for quick notes or session logs. This applies to new content and to
appended history entries going forward.

Historical Polish-language content was normalized to English on
2026-06-14 by explicit instruction (a one-time exception to the
append-only / frozen-plan immutability rules — facts, dates, and
structure were preserved; only the language was changed). The
immutability rules otherwise still hold; do not re-edit those files
except to append new (English) entries.

## Stack (non-negotiable)

- **UI**: SwiftUI only. No UIKit unless wrapping something unavoidable.
- **State**: `@Observable` macro (Observation framework). Do NOT use
  `ObservableObject` / `@Published` / `@StateObject`.
- **Persistence**: SwiftData. Do NOT propose CoreData.
- **Sync**: CloudKit via SwiftData's built-in CloudKit integration.
- **Charts**: Swift Charts.
- **Concurrency**: async/await + structured concurrency. Strict
  concurrency checking is on. Respect `@MainActor` isolation.
- **Navigation**: `NavigationStack` / `NavigationSplitView`.
- **DI**: Lightweight manual DI via environment values. No DI framework.

## Domain model (canonical)

The unit of truth is **grams of pure alcohol**. Every other measure
(standard drinks, units, BAC) is derived. Never store derived values
as primary data.

Core entities:
- `DrinkTemplate` — reusable preset (type, default volume, ABV, icon).
- `ConsumptionEvent` — a single drink consumed at a point in time.
  References a template OR carries an ad-hoc snapshot of its fields.
- `UserProfile` — body weight, sex, age, country guideline choice,
  unit system (metric/imperial), weekly goal.
- `GuidelineLimits` — value type (not SwiftData); thresholds computed on the fly
  by `GuidelineChoice.limits(for: BiologicalSex)`. Never stored in the database.

**Important**: keep templates and events separate. Editing a template
must never retroactively change past events.

## Calculations

- **Pure alcohol (g)** = volume_ml × ABV × 0.789
  ABV is stored as a plain fraction (0.0–1.0), e.g. 0.05 for 5% beer.
  Density constant 0.789 g/ml is the scientific ethanol density at 20 °C
  (gives 19.725 g for 500 ml × 5% beer). UK unit size is 10 ml × 0.789 = 7.89 g.
- **BAC** uses Widmark with sex-specific r factor. ALWAYS:
  - Label BAC output as an estimate, not medical advice.
  - Show units clearly: app uses **‰ (per mille)** by default in EU
    builds, **% BAC** in US. Never mix.
  - Account for elimination over time (~0.15‰/hour, configurable).
- I will hand-verify every calculation change. Do not refactor the
  calculation module without flagging it explicitly.

## Architecture

- MVVM with `@Observable` view models.
- **Data access**: views query SwiftData with `@Query` and perform simple
  mutations (insert/delete) directly via `@Environment(\.modelContext)`.
  View models are `@Observable @MainActor` and **stateless w.r.t.
  persistence** — they receive `[ConsumptionEvent]` / `UserProfile?` as
  injected plain values and never own a `ModelContext`. There is **no
  repository layer** (the original repository design in ADR-0003 was
  superseded by ADR-0004 — see `docs/decisions/`). Do not introduce one.
- **Services layer** (`Services/`): platform/system capabilities
  (notifications, Health, file IO) are wrapped behind a protocol and exposed
  as `@MainActor` service types, so view models/views depend on the
  abstraction, not the framework. See ADR for the services layer.
- One feature = one folder: `Features/Dashboard/`, `Features/AddDrink/`,
  etc. Each contains View, ViewModel, and feature-local components.
- Shared design system in `DesignSystem/` (tokens, components, modifiers).
- Shared domain in `Domain/` (models, calculations, guideline engine).
- `architecture.md` is the authoritative, up-to-date description of layers
  and boundaries; consult it before adding a new file outside an existing
  feature.

## Conventions

- Swift 6 strict concurrency. Fix warnings, do not suppress them.
- Prefer value types. Use classes only for `@Observable` view models
  and SwiftData models.
- No force-unwraps in production code. `try!` only in previews/tests.
- All user-facing strings go through `String(localized:)`. English (en) only — no other languages.
- File header comment is not needed.
- **File size limit**: keep files under 300 lines. Aim for ~200.
  Hard ceiling is 300; if you cross it, split the file.
- **How to split**:
  - SwiftUI views: extract subviews into separate files in a
    `Components/` subfolder of the feature.
  - View models: extract logic into helper types or extensions
    in separate files (e.g. `DashboardViewModel+Calculations.swift`).
  - Domain types: split by responsibility, not by line count
    (e.g. `DrinkTemplate.swift` + `DrinkTemplate+Validation.swift`
    + `DrinkTemplate+Previews.swift`).
  - Long enums or constants: move to a dedicated file.
- **Previews** can live in the same file if short (~30 lines),
  otherwise extract to `Foo+Previews.swift`.
- One concept per file. If a file name needs "And" or "&", split it.
- Previews are mandatory for every SwiftUI view, with mock data.

## File size enforcement

Files over 300 lines must be split before declaring a task done.
This is part of the end-of-task checklist — run:

```bash
find drinkpulse -name "*.swift" -not -path "*/Preview Content/*" \
  | xargs wc -l | awk '$1 > 300 {print}'
```

If anything is reported, split it. The only exception is auto-generated
files (e.g. localization strings), which should be excluded by path.

## Accessibility (required, not optional)

- Every interactive element has a meaningful `accessibilityLabel`.
- Charts have `accessibilityChartDescriptor` or equivalent summary.
- Respect Dynamic Type up to AX5. Test layouts at largest sizes.
- Honor `reduceMotion` for animations.
- Minimum contrast ratio 4.5:1 for body, 3:1 for large text.

## Engineering standards (non-functional)

These are enforceable requirements, not aspirations. They apply to every
non-trivial change and are part of the end-of-task review.

### Privacy & security (privacy-first is a product promise)

- **On-device only.** No network calls except SwiftData's CloudKit sync.
  Never add a URL request, socket, or third-party SDK. If a task seems to
  need the network, stop and ask.
- **Health data is sensitive.** Consumption events, notes, body metrics
  (weight, sex, age, DOB), and goals are personal health data. Treat every
  field as such: no logging, no telemetry, no leaving the device.
- **Data Protection.** Rely on SwiftData/iOS file protection defaults; do
  not weaken file protection or write app data outside the app container.
  Export files (see export/import feature) contain full user history —
  treat them as sensitive output, never auto-upload or cache them.
- **No analytics, no crash reporters, no ad/attribution SDKs** (also in
  "Out of scope"). Diagnostics use Apple's on-device tooling only.
- **No secrets in the repo.** No API keys, tokens, or credentials — the app
  has no backend, so there should be none to commit.

### Logging & observability

- Use `os.Logger` (`import OSLog`) with a stable subsystem
  (`com.drinkpulse.app`) and a per-area `category`. No `print(...)` in
  production code (previews/tests may use it sparingly).
- **Never log PII / health data.** Do not log drink contents, notes, body
  metrics, prices, timestamps tied to a person, or full model objects. Log
  identifiers, counts, enum cases, and error categories — not values. Mark
  any interpolation of user data `privacy: .private` (the default for
  non-numeric) and never override to `.public` for user data.
- Errors are typed (`enum ...: Error`) and either handled meaningfully or
  surfaced to the user. No empty `catch {}`, no swallowing with `try?`
  unless the failure is genuinely ignorable and a comment says why.

### Quality gates (CI-equivalent — must pass before "done")

- `xcodebuild build` is clean: **zero warnings**. Swift 6 strict-concurrency
  warnings are fixed at the source, never suppressed.
- `xcodebuild test` is green and coverage meets the per-layer targets in the
  Testing section. Below threshold blocks completion.
- No file over the 300-line ceiling (run the find command).
- No force-unwraps / `try!` in production code (previews/tests excepted).
- These checks are the definition of done; treat them as if a CI pipeline
  rejects the merge otherwise.

### Change hygiene & reversibility

- Schema changes to SwiftData models require a migration plan **before**
  shipping (see the open SwiftData-migration question). A dev-only
  store-wipe fallback is acceptable in development only and must be called
  out explicitly — never as the App Store strategy.
- Anything outward-facing or hard to reverse (pushing, releasing, deleting
  user data, enabling CloudKit) needs explicit per-action approval — see
  "Git commits & push".
- Prefer additive, backward-compatible changes. When a change is
  destructive or one-way (e.g. enabling CloudKit, removing a stored
  property), state that plainly and propose before doing it.

## What to ask before assuming

- New screen → ask which navigation context it lives in.
- New domain field → ask if it needs a SwiftData migration.
- Anything touching BAC, guidelines, or sync conflict resolution →
  propose, do NOT implement until I confirm.
- Unclear whether a change needs a plan (see below) → ask.

## Plan-driven development

For any **new feature** or **significant refactor**, create a plan in
`docs/plans/NNNN-kebab-title/` before writing code. Trivial changes
(typos, small bugfixes, formatting, single-line tweaks) do not require
a plan.

### Lifecycle
Each plan has four possible statuses tracked via the `Status` field:

1. **draft** — `plan.md` is editable. Iterate freely.
2. **in-progress** — `plan.md` is FROZEN. Add `Frozen: YYYY-MM-DD` to
   the header. All deviations, discoveries, and changes go into
   `execution.md` as dated append-only entries.
3. **completed** — `retrospective.md` is created. Folder is closed.
4. **abandoned** or **superseded by NNNN** — kept in the repo as
   project history. Never deleted.

### Immutability rules
- Once `plan.md` is frozen, do NOT edit it. Even typos stay.
- All changes during execution go into `execution.md`.
- If the plan turns out fundamentally wrong, mark `superseded by NNNN`
  and create a new plan. Never rewrite a frozen plan.

### Numbering & index
Sequential, zero-padded to 4 digits: `0001-domain-models/`. Check
`docs/plans/INDEX.md` for the next number before creating a new plan.
Update INDEX.md after every status change.

### Commit messages
Reference the active plan in commits: `[plan-0007] add ABV validator`.

### Templates
See `docs/plans/README.md` for plan.md / execution.md / retrospective.md
templates and sizing guidance (small / medium / large).

## Testing (mandatory)

**Minimum 90% line coverage on testable code.** Tests live in
`drinkpulseTests/` and must be kept passing at all times.

### Coverage targets
- **Domain layer** (`Domain/`): 100% — every calculation, validator,
  guideline rule, unit conversion. No exceptions.
- **View models**: ≥90% — every non-trivial branch in business logic.
- **Services** (`Services/`): ≥85% — happy paths plus error/denied paths,
  exercised through the service's injected protocol (mock the platform
  capability, not the service). Thin framework adapters are excluded.
- **Overall project (testable code)**: ≥90%.

Untestable code (SwiftUI view layouts, SwiftData persistence
internals, `@main` entry point) is excluded from the denominator —
see "What does NOT require unit tests" below.

### Coverage is enforced
Coverage is checked in the end-of-task checklist. Anything below
threshold blocks task completion. Use:

```bash
xcodebuild test -scheme drinkpulse \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -enableCodeCoverage YES \
  -derivedDataPath build/

xcrun xccov view --report --only-targets \
  build/Logs/Test/*.xcresult
```

### What must be tested
- All domain calculations (alcohol grams, BAC, guideline limits,
  unit conversions, elimination over time).
- All pure functions and computed values in the domain layer.
- All validators and value-type initializers that reject invalid input.
- Business logic in view models and helpers that does not depend on SwiftUI.
- Service logic: scheduling/cancellation, idempotency, authorization-denied
  and error paths — exercised through the injected protocol fake.
- Edge cases: zero values, negative values, out-of-range inputs,
  empty collections, nil optionals, boundary conditions (e.g. ABV
  exactly 0.0, 1.0), category changes in pickers, timezone boundaries.
- Regression tests for every fixed bug.

### When to write tests
- **New feature**: write tests before or alongside the implementation.
  Do not declare a feature done without tests meeting the coverage
  target for its layer.
- **Bug fix**: write a failing test that reproduces the bug first,
  then fix it.
- **Changed logic**: update existing tests to match the new behaviour
  before shipping the change.
- **Found uncovered code during audit**: add tests in the same task.
  Do not file a "TODO: add tests" — that's how coverage rots.

### Test quality rules
- One assertion concept per test. Multiple `XCTAssert` lines are fine
  if they verify the same logical claim.
- Test names describe behaviour, not implementation:
  `test_pureAlcohol_returnsZero_whenABVIsZero` not `test_calc1`.
- Use Swift Testing (`@Test`, `#expect`) for new tests on iOS 18+.
  Keep legacy XCTest for tests already written in that style.
- Mock at the service / data-access boundary (the injected protocol),
  not below. Domain calculations are tested with real inputs, not mocks.
- No tests that just exercise getters/setters or framework code.
  Test behaviour, not syntax.

### What does NOT require unit tests
- Pure layout / SwiftUI view structure (covered by Xcode Previews).
- SwiftData persistence internals (integration concern).
- `@main` entry point and app-level wiring.
- Auto-generated localization accessors.
- Pure presentation modifiers without logic.

These are excluded from the coverage denominator. Everything else counts.

## Build & verify

```bash
xcodebuild -scheme drinkpulse \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

xcodebuild test -scheme drinkpulse \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Use Xcode Previews for visual verification. Always build after a
multi-file change before declaring done.

## End-of-task checklist

Run this after every **non-trivial change** before declaring the task
done. Non-trivial = new feature, new screen, architectural decision,
data model change, or multi-file refactor. Skip for typo fixes and
single-line tweaks.

1. **Build, tests & coverage** — `xcodebuild build` clean (zero warnings),
   `xcodebuild test` green, coverage ≥90% overall and meeting
   per-layer targets. Run the coverage report command from the
   "Testing" section. If anything dropped below threshold, add
   tests in this task — do not defer.
2. **Privacy & logging review** — per "Engineering standards": no new
   network calls or third-party SDKs; no PII/health data in logs; no
   `print` in production; errors handled or surfaced, no empty `catch`.
3. **Living docs audit** — for every living document listed in the
   "Documentation update model" section, check whether anything you
   changed contradicts what it currently says:
   - README.md — features, stack, structure still accurate?
   - product.md — scope still matches what's shipped?
   - architecture.md — patterns and module boundaries still accurate?
   - domain.md — calculations, entities, rules still accurate?
   - roadmap.md — completed items moved to done?
   
   Update any doc that no longer reflects reality. If unsure whether
   an update is needed, ask me — do not skip silently.
4. **File size** — no Swift file over 300 lines. Run the find command
   from "File size enforcement". Split anything that exceeds it.
5. **Plan tracking** — if working under a plan, update `execution.md`
   with what was done. If the plan is now complete, create
   `retrospective.md` and update `INDEX.md`.
6. **`docs/DEVLOG.md`** — append an entry: date + time, what changed
   and why, key decisions (including rejected alternatives), open
   questions. Never edit or delete existing entries.
7. **`docs/roadmap.md`** — move completed items from "Next up" to
   the done section; update statuses (🗓 → ✅).
8. **`.claude/context/current-focus.md`** — update to reflect what
   was just finished and what comes next.
9. **`.claude/context/open-questions.md`** — remove resolved items,
   add new unresolved ones that surfaced during the task.
10. **`docs/decisions/`** — if a significant architectural choice was
   made, create a new ADR (`NNNN-short-title.md`) before closing.

These files are the source of truth if the conversation history is lost.

## Git commits & push

### Commit messages
Never include Claude Code authorship, co-authorship, or any AI
attribution in commit messages (no "Co-Authored-By: Claude", no
"Generated with Claude Code", no similar lines). Commit messages
should read as if written solely by the developer.

Reference active plans where applicable: `[plan-NNNN] short summary`.

### Pushing to remote
**Never run `git push`, `git push --force`, or any remote-affecting
command without explicit, in-message permission from me for that
specific push.** "Yes, push" or "push it" in chat is the only valid
trigger. Standing permission does not exist — every push needs its
own approval.

Committing locally is fine and expected as part of the workflow.
Pushing is not.

The same rule applies to:
- `git push` (any variant)
- Creating or pushing tags to remote
- Opening pull requests via `gh pr create` or similar
- Any action that publishes changes outside my machine

## Out of scope (do not propose unprompted)

- React Native, Flutter, web frontend.
- Backend services beyond CloudKit.
- Third-party analytics or crash reporters.
- Login / account systems.
- AI-generated drink recognition from photos.
