---
created: 2026-07-27T00:00:00.000Z
title: Audit every context.insert call site for the missing-save identity race
area: general
severity: minor
cluster: none
files:
  - drinkpulse/Domain/Persistence/UserProfileStore.swift:30 (fetchOrCreate — insert, no save)
  - drinkpulse/Features/Onboarding/OnboardingViewModel.swift:50 (complete(into:) — insert, no save)
  - drinkpulse/Domain/DataTransfer/DataImporter.swift:83,153,173 (events, templates, profile — insert, no save at call site)
  - drinkpulse/Domain/DataTransfer/DrinkControlImporter.swift:35 (imported event — insert, no save at call site)
  - drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift:92 (already checked — safe)
  - drinkpulse/Features/History/Components/EventContextMenu.swift:16-28 (already fixed — the reference pattern)
---

## Problem

The `sheet-closes-reopens-loses-state` bug (fixed 2026-07-26, commit
`084b1fe`, session archived at
`.planning/debug/resolved/sheet-closes-reopens-loses-state.md`) had this
mechanism:

> A freshly `insert()`-ed but **not yet saved** SwiftData `@Model` object
> carries a **temporary `PersistentIdentifier`** that only becomes permanent
> once the `ModelContext` saves. Any SwiftUI presentation keyed by that
> identifier (`.sheet(item:)`, `NavigationStack` path, `ForEach` identity)
> sees the identifier flip when autosave eventually fires — and reads it as
> "a different object", tearing down and reconstructing the view, discarding
> local `@State`.

During that session only a **targeted grep** was done, not a full audit. This
todo closes that gap.

A survey on 2026-07-27 found that **none of the remaining production insert
sites call `save()` either**:

| Call site | Saves? |
|-----------|--------|
| `UserProfileStore.swift:30` (`fetchOrCreate`) | **yes, as of 2026-07-28** (see update below) |
| `OnboardingViewModel.swift:50` (`complete(into:)`) | **yes, as of 2026-07-28** (see update below) |
| `DataImporter.swift:83,153,173` | not at call site — still unaudited |
| `DrinkControlImporter.swift:35` | not at call site — still unaudited |
| `DrinkDetailInputView+Logic.swift:92` | no — but checked and **safe** |
| `EventContextMenu.swift:16` | **yes** (the 2026-07-26 fix) |

**Update 2026-07-28:** Phase 3 code review (`03-REVIEW.md` CR-01/WR-01)
independently found and fixed the exact combination this todo predicted —
`UserProfileStore.fetchOrCreate` inserts a `UserProfile` observed (at the
time) by `RootShellView`'s onboarding-gating `@Query`, and
`OnboardingViewModel.complete(into:)` (the real onboarding-completion path)
had the same gap. Both now call `try? context.save()` immediately after
insert (commit `920749f`), with RED-first regression tests. The
`RootShellView.profiles` `@Query` mentioned above was also removed (dead
code, WR-03) — the direct intersection with
`2026-07-27-harden-onboarding-dual-source-of-truth.md` this todo called out
is resolved. **Remaining scope, unaudited:** `DataImporter.swift` and
`DrinkControlImporter.swift` bulk-insert call sites — this todo stays open
for that.

Preview/`UITestSeed` inserts (`*+Previews.swift`, `UITestSeed*.swift`,
`InsightsView.swift:40-42`, etc.) are out of scope — they are not production
paths.

**Important: insert-without-save is NOT by itself a bug.** The defect needs
the full combination:

1. an object is inserted and left unsaved, **and**
2. a SwiftUI presentation is keyed by that object's identity, **and**
3. the user can sit in that presentation long enough for autosave to fire
   (empirically ~7-8 s).

`DrinkDetailInputView.save()` is the proof: it inserts without saving and is
safe, because it inserts and dismisses in the same call — condition 3 is never
met. So this is an audit for that **combination**, not a mechanical
"add `save()` everywhere" sweep. Adding saves indiscriminately would be its
own defect: it would break the importers' batching and could partially commit
a failed import.

## Solution

TBD — audit, then fix only what actually matches:

- For each production insert site, answer: can the inserted object's identity
  reach a SwiftUI presentation (`.sheet(item:)`, navigation destination,
  `ForEach` id) **before** the context saves?
- Pay particular attention to `UserProfileStore.swift:30` — it inserts a
  `UserProfile` that `RootShellView`'s `@Query private var profiles` observes
  (`RootShellView.swift:17`), and that query drives the onboarding gate. This
  is the **direct intersection** with
  `2026-07-27-harden-onboarding-dual-source-of-truth.md` (cluster A); the two
  should be looked at together even though they are separate todos.
- Importers (`DataImporter`, `DrinkControlImporter`) insert in bulk. Confirm
  where their save actually happens and whether any imported object becomes
  presentable mid-import. If they save once at the end, that is likely correct
  — do not convert them to per-record saves.
- Where a genuine match is found, follow the `EventContextMenu.swift:16-28`
  pattern: save immediately after insert, with a comment explaining the
  temporary-identifier window (that comment is already written there and is
  the reference).

**Consider a lint-level guard.** If several matches turn up, a written rule in
`docs/architecture.md` ("a `@Model` that can be presented before the context
saves must be saved at insert time") is worth more than fixing the instances
silently — it stops the pattern coming back.

**Gate (CLAUDE.md):** any site that turns out to be genuinely affected is a
bug fix, so it needs a failing test first. `DuplicateEditPersistenceUITests`
(`test_editFreshDuplicate_survivesPastAutosaveWindow`) is the template — it
waits past the autosave window and asserts the state survived.

Size: audit is small; the fix depends entirely on what it finds. Start with
the audit as a `/gsd-quick` and re-scope if it turns up real matches.

## Why unclustered

This is an audit with an unknown outcome, not scoped work. If it finds
nothing, it closes as-is. If it finds real matches, they get triaged then —
possibly into cluster A alongside the onboarding hardening, since
`UserProfileStore` is already implicated there.
