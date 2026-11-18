# Dashboard arc evidence — Phase 09

**Date:** 2026-09-18  
**Toolchain:** Xcode 27.0 (27A266a), iPhoneSimulator SDK 27.0  
**Runtime:** iOS 27.0 — iPhone 18 Pro  
**LOCAL_IOS_27_UDID:** `1D35E1B8-4141-4EFF-A493-52CB37B600A5`

## Changed and checked paths

- `drinkpulse/DesignSystem/DPArcProgress.swift` — `ArcShape` is explicitly `nonisolated`; its fixed 60-degree start, 240-degree sweep, `Path.addArc` geometry, round stroke, and `hasSettledOnce` animation keyed by `pct` are unchanged.
- `drinkpulse/Features/Dashboard/Components/DashboardHeroCard.swift` — still renders `DPArcProgress` in the combined Dashboard hero accessibility element.
- `drinkpulseUITests/Features/Dashboard/DashboardUITests.swift` — focused seeded Dashboard regression suite.
- `drinkpulse/Domain/GuidelineLimits.swift` — pure `effectiveDailyGrams` accessor is explicitly `nonisolated`, allowing the test bundle to compile under the project’s default main-actor isolation.

## Automated checks

| Check | Command / source | Result |
|---|---|---|
| Debug app build | `xcodebuild build -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" -derivedDataPath /tmp/drinkpulse-phase09-debug CODE_SIGNING_ALLOWED=NO` | Pass |
| Release app build | `xcodebuild build -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Release -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" -derivedDataPath /tmp/drinkpulse-phase09-release CODE_SIGNING_ALLOWED=NO` | Pass |
| Focused UI regression | Xcode MCP `RunSomeTests`: `drinkpulseUITests/DashboardUITests` | Pass — 5/5 |
| Simulator accessibility capture | Xcode MCP, seeded launch arguments `-dp_onboarding_done YES -dp_uitest YES` | Pass — Home hero exposes `Today's Intake: 2.0 std` |

The focused suite passed: hero seeded value, chip row, overview/this-week cards, post-save intake update, and progress-view update after entrance animation.

## Human check

**Result: pass.** On the selected iOS 27 simulator, the owner verified the Dashboard hero with VoiceOver. At `Today's Intake`, VoiceOver announces only the combined value (for example, `Today's Intake 7.8 std`); it does not separately announce `128% of daily limit`. Tapping the drawn arc is not recognized as a separate accessibility target. The whole `Today's Intake` card consistently announces the same combined content.

This confirms the intended combined-card accessibility behavior. The Xcode accessibility hierarchy contains an implementation-level arc label (`100% of daily limit`), but the observed VoiceOver focus does not expose it as a separate user-facing element.

No full-suite result is claimed.
