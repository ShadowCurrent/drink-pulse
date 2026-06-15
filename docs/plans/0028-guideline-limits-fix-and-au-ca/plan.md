# 0028 — Guideline limits fix (weekly = drinking-days, not ×7) + Australia & Canada profiles

**Status**: in-progress
**Size**: medium
**Created**: 2026-06-15
**Frozen**: 2026-06-15

## Summary

A comparison against DrinkControl (men, 5000 ml @ 5% → 197.25 g with the
scientific 0.789 density) showed our **weekly** WHO and DE limits are too high.
Root cause: `GuidelineChoice.limits(for:)` derives weekly as `daily × 7`, but
WHO and the German (DHS) guideline both assume **2 alcohol-free days per week**
(max 5 drinking days). The correct weekly figure is `daily × 5`:

| Guideline | Sex | Daily (g) | Weekly now (×7) | Weekly correct |
|-----------|-----|-----------|-----------------|----------------|
| WHO | male | 20 | 140 ❌ | **100** (20×5) |
| WHO | female | 10 | 70 ❌ | **50** (10×5) |
| DE (DHS) | male | 24 | 168 ❌ | **120** (24×5) |
| DE (DHS) | female | 12 | 84 ❌ | **60** (12×5) |

US and UK are already correct and stay unchanged: US (NIAAA) assumes **0**
alcohol-free days → `daily × 7` (M 28→196, F 14→98); UK (NHS) has **no daily
limit** — its 112 g/week is an independent value (14 units × 8.0 g). Source for
the drinking-day convention: EU knowledge4policy "National low-risk drinking
recommendations" compilation (2016).

This plan also **adds Australia and Canada** as selectable guidelines (the
DrinkControl comparison listed both), and explicitly **keeps both `.units` and
`.standardDrinks`** alcohol units — they are *not* duplicates (different density
0.8 vs 0.789, and different UK gram-per-unit 8 vs 10), confirmed 2026-06-15.

## Context

- Triggered by a guideline audit vs DrinkControl (2026-06-15, this session).
  The consumption-side math (`pureAlcoholGrams`, density-by-unit, gramsPerUnit)
  was verified **correct** — UK even reads more correctly than DrinkControl
  (25.0 vs their 24.7, because our 0.8 density matches the NHS volume definition
  of a unit = 10 ml ethanol). The bug is **only** in the weekly limit values.
- `limits(for:)` lives in `Domain/GuidelineChoice+Limits.swift`. It already
  stores daily and weekly as **independent** constants, so the fix is to correct
  four numbers and add two cases — not to introduce a derived formula.
- **Rejected alternative — a stored `alcoholFreeDaysPerWeek` with
  `weekly = daily × (7 − free)`:** Australia breaks it. NHMRC 2020 caps ≤4
  drinks/day (40 g) **and** ≤10/week (100 g); `40 × anything` never lands on
  100. Weekly is genuinely independent of daily for some guidelines, so we keep
  daily + weekly as independent per-guideline constants (the `×5` is only a
  comment-level justification for WHO/DE).
- Constraints from CLAUDE.md: guideline/calculation changes are **proposed, not
  silently implemented** — this plan stays `draft` until the numbers below are
  hand-verified and confirmed. Adding enum cases to the `String`-backed
  `GuidelineChoice` is **additive and backward-compatible** (existing stored
  values still decode; no SwiftData migration needed). ≥90% coverage / 100%
  domain, files < 300 lines, no force-unwraps, en-only strings.

## Proposed guideline table (full, post-change)

Hand-verify before implementation. Daily/weekly in **physical grams**.

| Guideline | Sex | Daily (g) | Weekly (g) | Std drink (g) | Basis |
|-----------|-----|-----------|------------|---------------|-------|
| WHO | male / female | 20 / 10 | **100 / 50** | 10 | daily × 5 (2 free days) |
| DE (DHS) | male / female | 24 / 12 | **120 / 60** | 10 | daily × 5 (2 free days) |
| UK (NHS) | both | — (no daily) | 112 | 8.0 | 14 units, independent |
| US (NIAAA) | male / female | 28 / 14 | 196 / 98 | 14 | daily × 7 (no free days) |
| **AU (NHMRC 2020)** | both | **40** | **100** | 10 | ≤4/day & ≤10/week, independent |
| **CA (Health Canada)** | male / female | **40.35 / 26.9** | **201.75 / 134.5** | 13.45 | 3/15 & 2/10 std drinks (daily × 5) |

### Canada — resolved (official Health Canada)

Confirmed 2026-06-15 against canada.ca *Low-risk alcohol drinking guidelines*
(page "Date modified: 2025-03-25"). Health Canada still publishes the LRDG-2011
numbers — it did **not** adopt the stricter CCSA-2023 "2 drinks/week" guidance.

- Standard drink = **17.05 ml = 13.45 g** pure alcohol (a 341 ml 5% beer; check:
  341 × 0.05 × 0.789 = 13.45 g ✓).
- **Men:** 3 std/day, 15 std/week → **40.35 g/day, 201.75 g/week**.
- **Women:** 2 std/day, 10 std/week → **26.9 g/day, 134.5 g/week**.

In code, prefer `3 * 13.45` / `15 * 13.45` etc. over hard-coded gram literals so
the std-drink origin stays legible. Note CA weekly = daily × 5 (same 2-free-day
pattern as WHO/DE), but **still keep it as an independent stored value** —
Australia (4/day, 10/week) proves the ×5 rule is not universal.

## Scope

### In
- **Fix WHO & DE weekly** in `GuidelineChoice+Limits.swift`: WHO M 140→100,
  F 70→50; DE M 168→120, F 84→60. Update the `// Weekly = daily × 7` comment to
  explain the 5-drinking-day basis and why US (×7) and UK (independent) differ.
- **Add `au` and `ca`** to the `GuidelineChoice` enum (`Domain/UserProfile.swift`),
  with `limits(for:)` cases per the table above, and the Canada std-drink size
  **13.45 g** wired into `AlcoholUnit.gramsPerUnit(for:)` for both `.units` and
  `.standardDrinks` (Australia = 10 g, the existing European default — verify the
  `.standardDrinks` branch, currently `guideline == .us ? 14 : 10`, becomes a
  switch so CA returns 13.45).
- **Settings picker + localization**: `GuidelineChoice` display names for AU/CA,
  any per-guideline standard-drink label strings, `Localizable.xcstrings` (en).
  Confirm the guideline picker (driven by `CaseIterable`) renders the new cases.
- **Keep both alcohol units** — no enum removal, no migration. (Records the
  2026-06-15 decision; closes the "are they duplicates?" question.)
- **Tests** (domain 100%): `limits(for:)` for every guideline × both sexes incl.
  the corrected WHO/DE weeklies and the new AU/CA; `gramsPerUnit` for CA = 13.45
  and AU = 10 across `.units` / `.standardDrinks`; `effectiveDailyGrams` /
  `effectiveLimits` still resolve correctly for AU (independent daily+weekly) and
  CA. Regression test pinning WHO male weekly = 100 (guards against re-introducing
  the ×7 bug, reverting commit 77227e6's direction).
- **Living-docs audit**: `domain.md` guideline-thresholds table + the
  density/limit notes; `roadmap.md`; DEVLOG; context files. README only if the
  guideline list is public-facing there.

### Out
- **Monthly limit** (DrinkControl shows a 30-day figure = weekly × 30/7). Not in
  this plan; track as a separate feature if wanted.
- Removing/merging `.units` vs `.standardDrinks` (explicitly decided to keep
  both, 2026-06-15).
- Any change to the hand-verified `pureAlcoholGrams`, density-by-unit values,
  calorie, or (future) BAC math — consumption math is correct as-is.
- Reworking ADR-0005 / the 0.8-density UK convention.
- Making `.custom` selectable in the picker.

## Risks & notes
- Lowering WHO/DE weekly limits will (correctly) push some existing users from
  "within limit" to "exceeded" on their weekly view — this is the intended
  correction, not a regression. Worth a one-line DEVLOG callout.
- `effectiveDailyGrams` uses `weeklyGrams / 7` only as the UK no-daily fallback;
  AU/CA supply a real daily so they bypass it — verify no call site assumes
  `weekly = daily × 7`.
- Adding enum cases is backward-compatible, but confirm nothing exhaustively
  switches on `GuidelineChoice` without a `default`/all-cases handling (compiler
  will flag non-exhaustive switches — fix at source, no `default` that hides
  future cases in domain code).

## Acceptance
- WHO male weekly limit = 100 g, DE male = 120 g (and female 50 / 60); US & UK
  unchanged. A 5000 ml @ 5% male week reads against the corrected limits.
- Australia and Canada are selectable in Settings and produce correct daily/
  weekly risk percentages and History shading.
- Both `.units` and `.standardDrinks` remain available and unchanged.
- Canada uses the official Health Canada values (M 40.35/201.75, F 26.9/134.5,
  std drink 13.45 g) in code + `domain.md`.
- Build clean (zero warnings), tests green, domain coverage 100%, overall ≥90%,
  no file > 300 lines.
