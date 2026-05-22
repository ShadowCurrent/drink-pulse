# 0012 Retrospective

## What went well

- Swift Charts AreaMark + LineMark combo with `.monotone` interpolation gave a clean area chart without extra dependencies.
- Splitting VM into `InsightsViewModel.swift` + `InsightsViewModel+Heatmap.swift` kept both files comfortably under 200 lines.
- Locale-aware heatmap via `Calendar.current.firstWeekday` was easy — the Calendar API handles it cleanly.
- Per-guideline binge thresholds (Q2) fit naturally as a small private switch; no architectural cost.
- Auto-extraction of localization keys by the build system meant I only had to fill in translations, not restructure the xcstrings file.

## What was harder than expected

- Xcode's xcodeproj does not auto-include test files the way it auto-includes source files under `PBXFileSystemSynchronizedRootGroup`. Had to manually edit project.pbxproj to add `InsightsViewModelTests.swift`. Introduced duplicate entries on first attempt; cleaned up via targeted edits.
- `private` modifiers in the main class body are inaccessible from extensions in separate files (Swift scoping rule). Changed `cal`, `sex`, `guidelineChoice` to `internal`.
- `chartYScale(domain: 0...)` uses `UnboundedRange_` which Swift Charts doesn't accept; replaced with `.automatic(includesZero: true)`.

## Scope accuracy

Plan sized as "large" — delivered in one session. The scope estimate was accurate; the component count was right and none of the components grew beyond expected.

## Open items carried forward

- PDF export of Insights remains a 💡 idea in the roadmap (out-of-scope for this plan).
- `monthSpend` currency is taken from `UserProfile.currency` — multi-currency per-event tracking is a separate open question.
- plan-0001 (Dashboard Redesign) can now close: plan-0011 and plan-0012 were its two remaining sub-tasks.
