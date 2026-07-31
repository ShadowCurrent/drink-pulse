---
created: 2026-07-31T15:30:00.000Z
title: Add mandatory doc-lookup rule to CLAUDE.md - no guessing
area: docs
severity: minor
files:
  - CLAUDE.md
---

## Problem

During research or implementation, the agent (in both plain Claude Code
sessions and GSD workflows — research agents, planners, executors) can
currently guess at how to implement an API or framework behavior instead of
verifying it against authoritative sources first. There is no explicit rule
in CLAUDE.md requiring a documentation check before implementation for the
project's actual target iOS version.

## Solution

TBD — add a new rule/section to CLAUDE.md (root project instructions, so it
applies to both ad-hoc Claude Code work and GSD's research/planning/execution
agents) stating something like:

- Never guess how to implement an unfamiliar API, framework behavior, or
  platform mechanic. Before implementing, check the official Apple Developer
  documentation (developer.apple.com) for the exact iOS version this project
  targets (currently iOS 26) — API availability, deprecations, and behavior
  changes differ by OS version.
- When official docs are incomplete, ambiguous, or don't cover a specific
  edge case, also check reputable third-party iOS developer resources (e.g.
  WWDC session transcripts, Hacking with Swift, SwiftLee, Swift Forums) for
  implementation guidance — but Apple's own docs are always the primary
  source of truth; third-party sources are supplementary, not a substitute.
- Applies during `/gsd-phase-researcher`, `/gsd-ai-researcher`, and any
  research/planning step, not just ad-hoc implementation — research phases
  should cite what was actually looked up, not assumed.

Placement: likely near the top of CLAUDE.md (a new short section, or folded
into "Documentation to consult before starting" / "Conventions") so it reads
as a standing instruction rather than a one-off note. Needs a decision on
exact wording/placement when picked up — CLAUDE.md edits are user-owned, not
something to change silently.
