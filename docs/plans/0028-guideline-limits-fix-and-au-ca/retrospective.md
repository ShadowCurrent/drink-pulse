# 0028 — Retrospective

**Completed**: 2026-06-15

## What went well

- The fix was surgical and low-risk: `limits(for:)` already stored daily and weekly as independent constants, so correcting four numbers (WHO/DE weeklies) and adding two enum cases (AU, CA) required no architectural change.
- No SwiftData migration needed — `GuidelineChoice` is a `String`-backed `Codable` enum; adding cases is additive and existing stored raw values still decode correctly.
- The `zeroGramsForAllUnits` test in `AlcoholUnitFormattingTests` iterates `GuidelineChoice.allCases`, so it automatically covered AU and CA without needing a new test line.
- The compiler's exhaustive switch checking caught nothing unhandled — all existing switches either had `default:` or were in files we updated (UserProfile, GuidelineChoice+Display, GuidelineStep).

## What to watch

- **User impact**: Existing users on WHO or DE guidelines will move from "within limit" to "exceeded" on their weekly view after this correction. This is the intended fix, not a regression, but worth a one-line in-app note or changelog if the app gains a version history feature.
- **InsightsViewModel `guidelineComparisons`**: hardcodes `[.who, .uk, .de]` for the comparison panel. AU and CA are not shown there yet. That is acceptable scope (the Insights comparison panel was out of scope for this plan) but should be tracked.
- **Monthly limit**: DrinkControl shows a 30-day figure (`weekly × 30/7`). This plan leaves monthly limits out of scope. If the feature is ever added, the AU and CA weekly values (100 and 201.75 / 134.5) are already correct.

## Key decisions made

- Stored daily + weekly as independent constants (not derived). Australia (40 g/day, 100 g/week) proves that `weekly = daily × n` is not universal across guidelines.
- Used `3 * 13.45` / `15 * 13.45` multipliers in code instead of literal grams so the Health Canada standard-drink origin stays legible in the source.
- Kept `.units` and `.standardDrinks` as separate `AlcoholUnit` cases — they differ in density (0.8 vs 0.789) and in the UK gram-per-unit (8.0 vs 10.0); they are not duplicates.
