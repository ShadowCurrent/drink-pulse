---
created: 2026-07-31T15:44:24.261Z
title: Add branch-per-milestone workflow to GSD config
area: tooling
severity: minor
files:
---

## Problem

GSD workflows (milestone execution, `gsd-quick`, `gsd-fast`) currently commit
directly to `main`. There is no config option to isolate a milestone's (or,
where warranted, a quick/fast task's) work on its own branch, then merge back
and clean up automatically once the work succeeds.

Requested behavior:
- For each milestone: open a new branch at milestone start.
- For `gsd-quick` / `gsd-fast`, when the task is non-trivial enough to warrant
  isolation: also open a branch.
- On success (phase/milestone verified, tests green): merge the branch into
  `main` and delete the branch.
- On failure or abandonment: leave branch in place (do not force-merge broken
  work).

## Solution

TBD. Likely touches:
- `gsd-config`/`gsd-settings` — new `workflow.branching` toggle (e.g.
  `per-milestone`, `per-quick-task`, off).
- Milestone start/execute-phase workflow — branch creation step.
- `gsd-ship` / milestone-complete workflow — merge + branch deletion step,
  gated on verification passing.
- Needs a decision on merge strategy (fast-forward vs squash vs merge commit)
  and what happens to `.planning/` commits already interleaved with app code
  (see existing `gsd-pr-branch` skill, which already filters `.planning/`
  commits out for PR review branches — related but separate concern).
