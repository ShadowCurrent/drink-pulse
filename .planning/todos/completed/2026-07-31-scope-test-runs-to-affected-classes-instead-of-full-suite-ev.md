---
created: 2026-07-31T15:35:00.000Z
title: Scope test runs to affected classes instead of full suite every phase
area: testing
severity: minor
files:
  - CLAUDE.md
---

## Problem

Every GSD phase (and ad-hoc Claude Code work) currently runs the full
`xcodebuild test` suite as part of the end-of-task checklist / verify step.
The full suite takes ~25 minutes, which is slow for iterative work during a
single phase's implementation loop.

## Solution

TBD — change policy so a full-suite run is not required after every phase.
Rough shape of the idea:

- Default to running only the tests scoped to the phase's changed area (e.g.
  `-only-testing:` flags targeting the affected test class(es)/target),
  similar to how 06-01-PLAN.md's `<verification>` already scoped its run to
  `-only-testing:drinkpulseTests/HistoryViewTests
  -only-testing:drinkpulseUITests/HistoryInteractionUITests` instead of the
  full suite.
- Escalate to a full `xcodebuild test` run when the change is broad enough —
  proposed threshold: 3+ affected test classes, or when the change touches
  shared/Domain-layer code that many features depend on.
- Needs to reconcile with CLAUDE.md's current "Quality gates" section, which
  states `xcodebuild test` must be green as part of the definition of done —
  this todo would relax that to "scoped tests green during the phase, full
  suite green before milestone close" (or similar), not remove the gate
  entirely. Exact wording/threshold is a decision to make when picked up,
  not something to silently redefine.
- Should probably still require a full-suite pass at natural checkpoints
  (milestone close, before a real device/release build) to catch
  cross-feature regressions the scoped run wouldn't see.

## Resolution (2026-07-31)

Implemented per the sketch above. Updated three CLAUDE.md sections:
- **Quality gates**: relaxed from "`xcodebuild test` green" to a scoped
  `-only-testing:` run by default, escalating to full suite on 3+ affected
  test classes or any Domain-layer touch; full suite still required at
  milestone close / before a real-device or release build.
- **Build & verify**: added a scoped `-only-testing:` example alongside the
  existing full-suite command, both kept as reference.
- **End-of-task checklist** step 1: pointed at the Quality gates escalation
  criteria instead of unconditionally requiring the full suite.

The gate itself (tests green, coverage thresholds) was not removed or
weakened — only the required scope of the default run.
