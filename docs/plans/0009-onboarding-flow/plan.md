# 0009 — Onboarding flow (3 steps, skippable)

**Status**: draft
**Size**: medium
**Created**: 2026-05-19

## Summary

Add a first-launch onboarding flow with three steps: welcome, optional
profile (sex + age), and guideline pick. Each step can be skipped
individually and the whole flow can be skipped from step 0. Completion is
persisted with `@AppStorage("dp_onboarding_done")` so the flow runs once
per install.

Default guideline is **WHO**. If the profile step is skipped, no
`UserProfile` row is created — the existing fallbacks in
`DashboardViewModel` already handle `profile == nil`.

## Context

The Claude Design handoff (2026-05-19) introduces an onboarding pattern
matching DrinkPulse's privacy-first stance: no account, optional profile,
default guideline. Currently the app drops straight to the Dashboard on
first launch with no orientation, which leaves first-time users guessing
about guidelines and units.

Design reference: `dp-screens.jsx::OnboardingFlow`.

## Scope

### In
- New feature folder `Features/Onboarding/`.
- `OnboardingView` — three-step `TabView(selection:)` with `.page` style
  (or a custom step container — TBD in open questions).
- `OnboardingViewModel` — owns step index, transient sex/age/guideline
  selections, persists final state on `complete()`.
- Top-level routing: `drinkpulseApp` wraps `ContentView` and shows
  `OnboardingView` when `@AppStorage("dp_onboarding_done") == false`.
- Step 1 ("Welcome") — large emoji, app pitch, "Get started" CTA,
  "Skip all setup" secondary button.
- Step 2 ("Profile, optional") — Picker for `biologicalSex` (segmented),
  `Stepper` for age, both visibly tagged "optional". Saves to `UserProfile`
  on completion only if any field was touched.
- Step 3 ("Guideline") — radio list of WHO / NHS / NIAAA / DHS with the
  daily + weekly limits previewed beneath each option. Default selected:
  WHO.
- Skip semantics:
  - Step 0 "Skip all setup" → mark onboarding done, no profile created.
  - Step 1/2 "Skip this step" → advance to next step without saving.
  - Step 3 final "Skip" → mark onboarding done; use WHO default.

### Out
- Body weight input (deferred until BAC plan).
- Welcome-screen brand graphic — emoji 🫀 placeholder.
- Localized copy beyond the three step keys (final copywriting on user).
- Re-running onboarding from Settings — separate small follow-up plan.

## Implementation steps

1. **Routing** — modify `drinkpulseApp.swift` (or introduce a `RootView`):
   ```swift
   @AppStorage("dp_onboarding_done") private var done = false
   if done { ContentView() } else { OnboardingView(onFinish: { done = true }) }
   ```
2. **`OnboardingViewModel`** — `@Observable @MainActor final class`,
   `step: Int`, `sex: BiologicalSex?`, `age: Int?`, `guideline: GuidelineChoice = .who`,
   `func skipStep()`, `func advance()`, `func complete(into context: ModelContext)`.
3. **`OnboardingView`** — vertical layout: progress dots, current step,
   primary CTA, secondary "Skip" button. Use `withAnimation(.spring)` on step
   transitions; honour `reduceMotion`.
4. **Step subviews** in `Features/Onboarding/Components/`:
   `WelcomeStep.swift`, `ProfileStep.swift`, `GuidelineStep.swift`.
5. **`completeOnboarding`** behaviour:
   - If `sex` or `age` set: insert `UserProfile(sex: sex ?? .male, age: age ?? 30, guideline: guideline)`.
   - Else: only persist `guideline` if user explicitly picked one — otherwise
     no profile row, defaults remain.
6. **Settings**: add "Re-run onboarding" menu item that flips
   `dp_onboarding_done = false` (acceptable since it just shows the flow on
   next launch; or use a presented sheet — see open Q3).
7. **Tests** in `drinkpulseTests/OnboardingViewModelTests.swift`:
   - `complete(skipAll:)` inserts no UserProfile.
   - `complete()` with sex+age inserts UserProfile with those values.
   - `complete()` with guideline only inserts UserProfile only if guideline
     was changed from default (otherwise no row).
   - Default `guideline == .who`.

## Files

| File | Action |
|------|--------|
| `drinkpulse/drinkpulseApp.swift` | Modify (routing) |
| `drinkpulse/Features/Onboarding/OnboardingView.swift` | Create |
| `drinkpulse/Features/Onboarding/OnboardingViewModel.swift` | Create |
| `drinkpulse/Features/Onboarding/Components/WelcomeStep.swift` | Create |
| `drinkpulse/Features/Onboarding/Components/ProfileStep.swift` | Create |
| `drinkpulse/Features/Onboarding/Components/GuidelineStep.swift` | Create |
| `drinkpulse/Localizable.xcstrings` | Add onboarding keys |
| `drinkpulseTests/OnboardingViewModelTests.swift` | Create |
| `docs/roadmap.md` | Move "First-launch onboarding" 🗓 → ✅ on close |

## Open questions

- [ ] **Q1 — Step container**: native `TabView(.page)` or custom
  `ZStack + offset` with our own step manager?
  - A) `TabView(.page)` — native swipe affordance; matches iOS 26 page-style
    onboarding (default)
  - B) Custom — full control over transitions, ignores horizontal swipe

- [ ] **Q2 — Step order**: keep design order (Welcome → Profile → Guideline)
  or swap so the *less skippable* one is last? Default: A.

- [ ] **Q3 — Re-run mechanism in Settings**: full-screen presentation or
  navigation push? Default: A (full-screen, matches first-launch feel).

- [ ] **Q4 — Welcome graphic**: emoji 🫀 vs. a custom SF Symbol composition?
  Default: A (emoji — fastest to ship; revisit when brand assets exist).

## Tests required

- ViewModel unit tests above.
- A snapshot/screenshot review via Previews for each step in light + dark.

## Future links

- [[plan-0011]] — Dashboard arc hero may show different greeting copy for
  brand-new users (zero events). Not coupled but informs first-impression.
- [[plan-0008]] — Theme picker likely lives in Settings, not in onboarding,
  to keep the flow short.
