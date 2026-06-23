# 0031 — Retrospective

**Status**: completed 2026-06-23
**Size**: large (as estimated)

## What shipped

The two coupled pieces that finish plan-0030's volume vision:

1. **Provenance (C′ / ADR-0007).** `ConsumptionEvent.enteredUnit: UnitSystem?` —
   the serving *name* now resolves via the unit in effect when the drink was
   logged, so it is stable across later unit-mode switches and never affects any
   calculation. Additive migration, back-compatible export key.
2. **Serving-list expansion (proposal-2 v3).** Realistic US/imperial/metric
   serving inventory with `regionNames`, pint/fraction display, the inline ml
   hint, and cross-borrows — adopting the region-tag policy reversal.

## What went well

- **Gates first.** Both owner sign-offs (pint/fraction rule, region-policy
  reversal) were secured up front with concrete hand-verifiable anchors, so the
  bulk of the work ran without mid-stream blocking.
- **Foundation-then-inventory ordering.** Building the domain formatter + model +
  resolution chain and compiling/building before the large preset rewrite caught
  the API shape early; the inventory rewrite was then mechanical.
- **Coverage held at the leaf.** The hand-verified domain rule landed at 100%
  with anchor-based tests, and the duplicate-ml invariant pins the merged-568
  model against future regressions.

## What was tricky

- **Proposal-2 self-conflict.** The proposal's stated `isRoundServing` rule
  ("whole/half oz OR pint fraction") contradicts a handful of its own table rows
  that show an ml hint on exact-half-oz real measures. Resolved by treating the
  *stated rule* as canonical (it keeps cocktail/hot-drink oz clean) and accepting
  that ~4 half-oz rows render without the optional hint. Documented in
  `execution.md` + `domain.md` so the deviation is intentional, not a bug.
- **Name-resolution semantics changed.** Moving from nearest-match to exact-ish
  (≤0.5 ml) match means orphaned ml now fall back to `formatVolume` ("490 ml")
  rather than snapping to a friendly name. Correct per ADR-0007, but it changed a
  few existing test expectations.

## Follow-ups / notes

- The History **subtitle** still uses `formatVolume` (fl oz), so an imperial pint
  event reads "Pint · 20.0 fl oz · …" in the subtitle while the name is "Pint".
  In scope only the name resolves via provenance; switching the subtitle to the
  pint-aware `servingVolumeLabel` is a possible polish follow-up.
- Custom user-created volume presets (DB-backed) remain deferred future work;
  `VolumeOption` is kept forward-compatible (`regionNames` defaulted).
- CLAUDE.md's "drinkpulseUITests is NOT file-system-synchronized" note is stale —
  that target is a `PBXFileSystemSynchronizedRootGroup`; new UI test files
  auto-include. (`drinkpulseTests` was not exercised for new files this plan.)

## Plan-0030 closure

plan-0030 was reopened `in-progress`, blocked by 0031. With 0031 landed, 0030's
full volume vision is delivered → both marked **completed**.
