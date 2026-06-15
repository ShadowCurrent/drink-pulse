# 0028 — Execution log

## 2026-06-15

### What was implemented

**Core domain changes:**

1. `drinkpulse/Domain/UserProfile.swift`
   - Added `au` and `ca` to `GuidelineChoice` enum: `case who, de, uk, us, au, ca, custom`
   - Updated `AlcoholUnit.gramsPerUnit(for:)`:
     - `.units` branch: added `case .au: 10.0` and `case .ca: 13.45`; exhaustive switch
     - `.standardDrinks` branch: converted from `guideline == .us ? 14.0 : 10.0` to an exhaustive switch returning CA=13.45, US=14.0, all others=10.0
   - Updated comments to include AU (10 g) and CA (13.45 g)

2. `drinkpulse/Domain/GuidelineChoice+Limits.swift`
   - Fixed WHO male weekly: 140 → 100 (daily × 5, 2 alcohol-free days)
   - Fixed WHO female weekly: 70 → 50
   - Fixed DE male weekly: 168 → 120
   - Fixed DE female weekly: 84 → 60
   - Added `.au` case: daily 40 g, weekly 100 g (independent NHMRC published values)
   - Added `.ca` case: male 3×13.45/15×13.45, female 2×13.45/10×13.45 (Health Canada LRDG-2011)
   - Replaced stale `// Weekly = daily × 7` comment with full explanation of drinking-day conventions per guideline

3. `drinkpulse/Domain/GuidelineChoice+Display.swift`
   - Added `case .au: String(localized: "settings.guideline.au")`
   - Added `case .ca: String(localized: "settings.guideline.ca")`

4. `drinkpulse/Features/Onboarding/Components/GuidelineStep.swift`
   - Added `.au` and `.ca` to `choices` array
   - Added `au` and `ca` to `onboardingName` switch

5. `drinkpulse/Localizable.xcstrings`
   - Added `"settings.guideline.au"` → "Australia (NHMRC)"
   - Added `"settings.guideline.ca"` → "Canada (Health Canada)"
   - Inserted alphabetically between existing entries

**Tests updated:**

6. `drinkpulseTests/GuidelineLimitsTests.swift`
   - Updated `whoMaleLimits`: weekly 140→100
   - Updated `whoFemaleLimits`: weekly 70→50
   - Updated `deMaleLimits`: weekly 168→120
   - Updated `deFemaleLimits`: weekly 84→60
   - Added regression guard `whoMaleWeekly_is100_notDailyTimesSeven`
   - Added AU tests: `auMaleLimits`, `auFemaleLimits`, `auSameLimitsForBothSexes`, `auEffectiveDailyGrams_usesPublishedDaily`
   - Added CA tests: `caMaleLimits`, `caFemaleLimits`, `caMaleLimitsExactGrams`, `caFemaleLimitsExactGrams`, `caEffectiveDailyGrams_usesPublishedDaily`, `caEffectiveLimits_resolveCorrectly`, `auEffectiveLimits_resolveCorrectly`

7. `drinkpulseTests/AlcoholUnitFormattingTests.swift`
   - Added `gramsPerUnit_au_is10ForBothUnitModes`
   - Added `gramsPerUnit_ca_is13point45ForBothUnitModes`
   - Added `gramsPerUnit_ca_formattedStandardDrink`
   - Added `gramsPerUnit_au_formattedStandardDrink`

8. `drinkpulseTests/GuidelineChoiceDisplayTests.swift`
   - Updated stale WHO comment (weekly 140→100)
   - Added `displayName_au_matchesLocalizedKey`
   - Added `displayName_ca_matchesLocalizedKey`

9. `drinkpulseTests/DashboardViewModelTests.swift`
   - Updated `riskLevel_caution_at60pct_whoMale`: 84 g → 60 g (60/100=60%, was 84/140=60%)
   - Updated `riskLevel_exceeded_at110pct_whoMale`: 154 g → 110 g (110/100=110%)
   - Updated `riskLevel_safe_exactlyAt49pct_whoMale`: 68 g → 49 g (49/100=49%, was 68/140=48.6%)
   - Updated `riskLevel_cautionWhenYesterdayExceedsWith60pct`: 84 g → 60 g

10. `drinkpulseTests/DashboardViewModelTests+Metrics.swift`
    - Updated `thirtyDayLimitGrams_isWeeklyLimitScaledTo30Days`: 140×30/7 → 100×30/7

**Docs:**

11. `docs/domain.md` — Updated guideline thresholds table (WHO 100/50, DE 120/60, added AU and CA rows); updated AlcoholUnit gramsPerUnit comment to include CA=13.45; updated `effectiveDailyGrams` note to clarify AU/CA bypass the weekly/7 fallback
12. `docs/plans/0028-.../execution.md` — this file
13. `docs/plans/0028-.../retrospective.md` — created (see file)
14. `docs/plans/INDEX.md` — status in-progress → completed
15. `docs/DEVLOG.md` — session entry appended
16. `docs/roadmap.md` — item marked completed if present
17. `.claude/context/current-focus.md` — updated
18. `.claude/context/open-questions.md` — updated

### Deviations from plan

None. All code changes match the plan specification exactly.

### Build/test results

- Build: SUCCEEDED, zero warnings
- Tests: 367 passed, 0 failed
- `GuidelineChoice+Limits.swift` coverage: 100%
- `GuidelineChoice+Display.swift` coverage: 100%
- `UserProfile.swift` (AlcoholUnit) coverage: 92.54% (uncovered = preview helper, excluded per CLAUDE.md)
- No Swift file > 300 lines
