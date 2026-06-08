# 0024 — Domain bug fixes (backup signature + custom-guideline limit)

**Status**: in-progress
**Size**: small
**Created**: 2026-06-06
**Frozen**: 2026-06-06

## Summary

A focused audit of `Domain/` (2026-06-06) found two correctness bugs. Both are
"silent" — no crash, no warning — which is why they survived. Neither is in the
hand-verified calculation core (`pureAlcoholGrams`, guideline gram thresholds);
both are in derived/plumbing logic.

1. **Stale backups on edit.** `DataExporter.contentSignature` keys the
   auto-backup change-detection on the *deprecated* `name` field and omits the
   live `customName`, `category`, and `icon`. Editing any of those leaves the
   signature unchanged, so the backup/share file silently goes stale. This is
   the same guarantee plan-0022 intended ("regenerate from content, not
   count") — the fix was keyed on the wrong fields.

2. **Custom-guideline daily limit broken in History.** The "effective daily
   limit" fallback (handle `.custom` → use `weeklyGoalGrams`; handle UK
   `dailyGrams == 0` → `weeklyGrams / 7`) is reimplemented in three view layers.
   Two (`DashboardViewModel`, `InsightsViewModel`) handle `.custom`;
   `HistoryCalendarView.dailyLimit` does not, so a custom-guideline profile
   gets a `0` daily limit and the History calendar loses all risk shading.
   `.custom` is not selectable in the picker but is reachable by importing a
   backup whose `ProfileRecord.guidelineChoice == .custom`.

## Context

- Triggered by a Domain audit (2026-06-06).
- Bug 1 is an incomplete carry-over from plan-0022 (backup integrity); the
  `name` field it hashes was deprecated for display by plan-0014/0001-era work
  (`displayName` now derives from `category` + `volumeMl` + `customName`).
- Bug 2's root cause is that `GuidelineChoice.limits(for:)` returns sentinel
  zeros (`(0,0)` for custom, `(0, weekly)` for UK) that every call site must
  decode by hand — a footgun. The fix consolidates the resolution into one
  domain function so no view can get it wrong again.
- Constraints from CLAUDE.md: BAC/guideline/calculation changes must be
  proposed, not silently refactored — Bug 2 touches the guideline engine, so
  the domain helper below is **proposed for confirmation before implementing**.
  Privacy-first (no logging of contents), ≥90% coverage / 100% domain,
  files < 300 lines, no force-unwraps.

## Scope

### In
- **Bug 1:** Update `DataExporter.contentSignature` to hash the fields that
  actually define a drink's current state: `customName`, `category.rawValue`,
  `icon` (and keep `volumeMl`, `abv`, `notes`, `price`, `timestamp`). Drop the
  deprecated `name` from the signature. Keep the profile fields as-is.
- **Bug 2:** Add a single domain resolver for the effective limits of a profile
  (proposed signature — confirm before coding):
  `GuidelineChoice.effectiveLimits(weeklyGoalGrams:for:)` returning a
  `GuidelineLimits` where `.custom` uses the goal and UK's zero-daily is left
  intact, **plus** a derived `effectiveDailyGrams` that applies the
  `dailyGrams > 0 ? dailyGrams : weeklyGrams / 7` fallback in one place.
  Then route `DashboardViewModel`, `InsightsViewModel`, and
  `HistoryCalendarView` through it, deleting the three duplicated
  implementations.
- Tests: signature changes when (and only when) each live field changes;
  custom-guideline profile yields a non-zero effective daily limit and History
  produces risk colors consistent with Dashboard/Insights. Domain resolver
  100% covered (all guidelines × both sexes × custom-with-goal).
- Living-docs audit: `domain.md` (limit resolution now lives in domain),
  `architecture.md` if the helper changes a boundary, DEVLOG, roadmap, context.

### Out
- Removing the deprecated `ConsumptionEvent.name` field entirely (owned by
  plan-0023 CloudKit migration — needs a schema migration).
- Renaming the `RiskLevel.safe` enum case (cosmetic; plan-0015 already shipped
  the user-facing "Low Risk" string).
- Making `.custom` guideline selectable in the picker (product decision, not a
  bug fix).
- Any change to the hand-verified gram thresholds or `pureAlcoholGrams` /
  Widmark math.

## Risks & notes
- Changing `contentSignature` will (correctly) cause one extra backup
  regeneration on first launch after the update, because the signature value
  shifts. Harmless.
- Bug 2 fix touches the guideline engine surface — get explicit confirmation on
  the resolver name/shape before implementing, per CLAUDE.md.

## Acceptance
- Editing a drink's custom name / category / icon regenerates the backup file.
- A profile with `guidelineChoice == .custom` (set via import) shows identical
  risk shading across Dashboard, Insights, and the History calendar.
- No duplicated daily-limit fallback remains in the three view layers.
- Build clean (zero warnings), tests green, domain coverage 100%, overall ≥90%.
