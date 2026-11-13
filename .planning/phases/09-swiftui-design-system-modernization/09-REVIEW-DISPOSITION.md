---
phase: 09
review: 09-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: deferred
    title: "DPArcProgress animation never interpolates (ArcShape has no `animatableData`)"
  - id: WR-02
    severity: warning
    disposition: deferred
    title: "DPArcProgress accessibility label hardcoded English; reduce-motion not honored"
  - id: WR-03
    severity: warning
    disposition: deferred
    title: "Custom drink in US/imperial mode saves a volume that is not in the picker options"
  - id: WR-04
    severity: warning
    disposition: deferred
    title: "`parsedPrice` accepts NaN, infinity, negatives; silently drops grouped input"
  - id: WR-05
    severity: warning
    disposition: fixed
    title: "VoiceOver UI test does not verify dismissal under VoiceOver and has no availability guard"
  - id: IN-01
    severity: info
    disposition: deferred
    title: "Preview of DrinkDetailInputView no longer previews the detail screen"
  - id: IN-02
    severity: info
    disposition: deferred
    title: "Save has no re-entry guard"
  - id: IN-03
    severity: info
    disposition: deferred
    title: "ArcShape radius ignores stroke width"
  - id: IN-04
    severity: info
    disposition: deferred
    title: "Weak UI test locators"
open: 0
total: 9
recorded: 2026-11-12T20:50:57.307Z
---

# Phase 09: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | deferred | pre-existing behavior preserved by Phase 09: the arc animation without animatableData dates from 2026-05-19 and 2026-07-28, Phase 09 only added nonisolated |
| WR-02 | warning | deferred | pre-existing behavior preserved by Phase 09: the hardcoded label and missing Reduce Motion check predate the phase, Phase 09 changed only isolation |
| WR-03 | warning | deferred | pre-existing behavior preserved by Phase 09: the custom-volume onAppear logic dates from June 2026 and was not touched by plan 09-02 |
| WR-04 | warning | deferred | pre-existing behavior preserved by Phase 09: parsedPrice dates from 2026-06-27 and Phase 09 did not change it |
| WR-05 | warning | fixed | 09-05 rewrite, mutation control |
| IN-01 | info | deferred | informational: Phase 09 plan 09-02 replaced the previews with AddDrinkView, preview-only with no runtime effect |
| IN-02 | info | deferred | pre-existing behavior preserved by Phase 09: save() had no re-entry guard before, plan 09-02 only swapped the dismiss call |
| IN-03 | info | deferred | pre-existing behavior preserved by Phase 09: the ArcShape radius line dates from 2026-05-19 and is unchanged |
| IN-04 | info | deferred | pre-existing behavior preserved by Phase 09: both locators date from 2026-06-24 and are outside the lines plan 09-02 changed |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
