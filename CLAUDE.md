# CLAUDE.md

## Project

iOS app for tracking personal alcohol consumption and comparing it
against health guidelines (WHO + country profiles). Privacy-first,
offline-first, no account required.

Target: iPhone first. iPad and Apple Watch later.
Minimum deployment: iOS 26.

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

- **Pure alcohol (g)** = volume_ml × ABV × 0.8
  ABV is stored as a plain fraction (0.0–1.0), e.g. 0.05 for 5% beer.
  Density constant 0.8 g/ml follows BZgA/European health authority convention
  (gives 20 g for 500 ml × 5% beer). Scientific ethanol density is 0.789 g/ml.
- **BAC** uses Widmark with sex-specific r factor. ALWAYS:
  - Label BAC output as an estimate, not medical advice.
  - Show units clearly: app uses **‰ (per mille)** by default in EU
    builds, **% BAC** in US. Never mix.
  - Account for elimination over time (~0.15‰/hour, configurable).
- I will hand-verify every calculation change. Do not refactor the
  calculation module without flagging it explicitly.

## Architecture

- MVVM with `@Observable` view models.
- Repositories sit between view models and SwiftData. Views never
  touch `ModelContext` directly.
- One feature = one folder: `Features/Dashboard/`, `Features/AddDrink/`,
  etc. Each contains View, ViewModel, and feature-local components.
- Shared design system in `DesignSystem/` (tokens, components, modifiers).
- Shared domain in `Domain/` (models, calculations, guideline engine).

## Conventions

- Swift 6 strict concurrency. Fix warnings, do not suppress them.
- Prefer value types. Use classes only for `@Observable` view models
  and SwiftData models.
- No force-unwraps in production code. `try!` only in previews/tests.
- All user-facing strings go through `String(localized:)`. Polish (pl)
  and English (en) are first-class.
- File header comment is not needed. Keep files focused (~200 lines max).
- Previews are mandatory for every SwiftUI view, with mock data.

## Accessibility (required, not optional)

- Every interactive element has a meaningful `accessibilityLabel`.
- Charts have `accessibilityChartDescriptor` or equivalent summary.
- Respect Dynamic Type up to AX5. Test layouts at largest sizes.
- Honor `reduceMotion` for animations.
- Minimum contrast ratio 4.5:1 for body, 3:1 for large text.

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

**Every non-trivial piece of logic must have a unit test.** Tests live
in `drinkpulseTests/` and must be kept passing at all times.

### What must be tested
- All domain calculations (alcohol grams, guideline limits, unit conversions).
- All pure functions and computed values in the domain layer.
- Business logic in view models and helpers that does not depend on SwiftUI.
- Edge cases: zero values, out-of-range inputs, category changes in pickers.

### When to write tests
- **New feature**: write tests before or alongside the implementation.
  Do not declare a feature done without tests for its core logic.
- **Bug fix**: write a failing test that reproduces the bug first,
  then fix it.
- **Changed logic**: update existing tests to match the new behaviour
  before shipping the change.

### What does NOT require unit tests
- Pure layout / SwiftUI view structure (covered by Xcode Previews).
- SwiftData persistence (integration concern, not unit concern).

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

1. **Build & tests** — `xcodebuild build` clean, `xcodebuild test` green.
2. **Plan tracking** — if working under a plan, update `execution.md`
   with what was done. If the plan is now complete, create
   `retrospective.md` and update `INDEX.md`.
3. **`docs/DEVLOG.md`** — append an entry: date + time, what changed
   and why, key decisions (including rejected alternatives), open
   questions. Never edit or delete existing entries.
4. **`docs/roadmap.md`** — move completed items from "Next up" to
   the done section; update statuses (🗓 → ✅).
5. **`.claude/context/current-focus.md`** — update to reflect what
   was just finished and what comes next.
6. **`.claude/context/open-questions.md`** — remove resolved items,
   add new unresolved ones that surfaced during the task.
7. **`docs/decisions/`** — if a significant architectural choice was
   made, create a new ADR (`NNNN-short-title.md`) before closing.

These files are the source of truth if the conversation history is lost.

## Git commits

Never include Claude Code authorship, co-authorship, or any AI
attribution in commit messages (no "Co-Authored-By: Claude", no
"Generated with Claude Code", no similar lines). Commit messages
should read as if written solely by the developer.

Reference active plans where applicable: `[plan-NNNN] short summary`.

## Out of scope (do not propose unprompted)

- React Native, Flutter, web frontend.
- Backend services beyond CloudKit.
- Third-party analytics or crash reporters.
- Login / account systems.
- AI-generated drink recognition from photos.
