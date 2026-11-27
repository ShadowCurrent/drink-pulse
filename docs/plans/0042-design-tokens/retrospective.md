# 0042 — Retrospective

**Completed**: 2026-11-20

## What went well
- The prototype's `riskTone` matched existing asset values exactly, so the one risk palette
  was three asset edits plus a call-site swap; WCAG contrast tests in both appearances pin it.
- Every appearance-dependent decision (tint, surface, track, fill visibility) is a pure static
  function, so the tokens are unit tested without rendering.
- Running the audit on the pre-0042 commit (`e074f2f`) separated real regressions from
  pre-existing History failures in minutes.

## What went wrong / surprises
- `Color.accentColor` resolved outside a view returns system blue, not the asset; the Frost
  accent test caught it. `Brand.accent` loads the asset by name.
- The target's default actor isolation is `MainActor`, so tokens read by tests or Charts need
  `nonisolated`.
- The darker Dark exceeded tone broke contrast on one old-UI badge (risk fill on glass); fixed
  with an outline. The first audit baseline covered only 3 of 8 ungated classes.
- The arc's first-log jump had two causes beyond `animatableData` (fill inserted at 0, settle
  flag set after the first change); the executor first deferred it, the final review sent it
  back, and it was fixed in this plan.

## Decisions made during execution
- See `execution.md` "Deviations from plan" and the final-review entry.

## Leftover open questions
- Increase Contrast variants for the accent and risk sets (open-questions).
- Old-UI audit failures, now including History / HistorySearch (open-questions).
- Owner device check: arc sweep from 0, Frost accent in Light / Dark, risk tones.
