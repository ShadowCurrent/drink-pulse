# CLAUDE.md

## End-of-task checklist

Run this after every **non-trivial change** before declaring the task done.
Non-trivial = new feature, new screen, architectural decision, data model
change, or multi-file refactor. Skip for typo fixes and single-line tweaks.

1. **`docs/DEVLOG.md`** — append an entry: date + time, what changed and
   why, key decisions (including rejected alternatives), open questions.
   Never edit or delete existing entries.
2. **`docs/roadmap.md`** — move completed items from "Next up" to
   the Foundation/done section; update statuses (🗓 → ✅).
3. **`.claude/context/current-focus.md`** — update to reflect what was
   just finished and what comes next.
4. **`.claude/context/open-questions.md`** — remove resolved items,
   add new unresolved ones that surfaced during the task.
5. **`docs/decisions/`** — if a significant architectural choice was made,
   create a new ADR (NNNN-short-title.md) before closing.

These files are the source of truth if the conversation history is lost.

---

## Project

iOS app for tracking personal alcohol consumption and comparing it
against health guidelines (WHO + country profiles). Privacy-first,
offline-first, no account required.

Target: iPhone first. iPad and Apple Watch later.
Minimum deployment: iOS 26.

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
- `GuidelineProfile` — configurable thresholds (WHO / DE / UK / US / custom).

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

## Build & verify

```bash
xcodebuild -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

Use Xcode Previews for visual verification (you can capture them).
Always build after a multi-file change before declaring done.

## Git commits

Never include Claude Code authorship, co-authorship, or any AI attribution
in commit messages (no "Co-Authored-By: Claude", no "Generated with Claude
Code", no similar lines). Commit messages should read as if written solely
by the developer.

## Out of scope (do not propose unprompted)

- React Native, Flutter, web frontend.
- Backend services beyond CloudKit.
- Third-party analytics or crash reporters.
- Login / account systems.
- AI-generated drink recognition from photos.

## Documentation to consult before starting

Before working on anything substantial, read:
- `docs/architecture.md` — system architecture and patterns
- `docs/domain.md` — domain rules (alcohol calculations, guidelines, units)
- `docs/product.md` — product vision, scope, user stories
- `docs/decisions/` — ADRs for significant technical decisions
- `.claude/context/current-focus.md` — what we're working on right now
- `.claude/context/open-questions.md` — unresolved decisions
