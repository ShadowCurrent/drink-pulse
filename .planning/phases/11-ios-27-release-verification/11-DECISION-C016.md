# C016 - Text truncation, clipping and overlap at the largest accessibility text size (AX5)

**Status:** owner decision recorded 2026-11-16; fix in plan 11-16
**Source:** owner checklist item CHK-07 (`11-A11Y-CHECKLIST.md`), plan 11-07, run on the iOS 27.2 simulator (not a device), at the accessibility-extra-extra-extra-large text size.
**Result:** fail (human observation; the item stays open).

## Current behavior

The owner walked every screen at AX5 and recorded the following. Screen names and visible UI strings only; no data values.

- Home: the "Moderate Risk" label is clipped by its rounded shape; the calories value is truncated; the bottom tiles are truncated (for example "No dri...", "Day str...", "0 so-be...").
- Insights: the Health Impact card text is truncated throughout; the weekday labels of the Weekday pattern chart overlap.
- Add Drink step 1: drink names are truncated.
- Add Drink step 2: the vertical volume carousel values overlap slightly and names are truncated; the same for percentages and quantity; "Price (optio..." is truncated.
- Settings: in Preferences, every choice option that wraps to more than one line is clipped vertically.
- Onboarding: several labels and descriptions on all pages are truncated (for example "Optional. Help...", "Biological...", "Date of Bi...", "Your Guide...", "Apple Heal...", "Weekly c...", "Get a weekly n...").
- Not affected: the guideline picker (OK in onboarding and Settings) and History (nothing truncated).

Cross-reference to the automated audit, which is gated and has 311 open findings (D11-22): the audit groups G01 (Add Drink tiles), G03 (Home cards, "kcal" clipped), G04 (Insights cards, "kcal" clipped) and G07 (Onboarding welcome step) record text-size findings on the same screens. This is a similarity of location, not a confirmation: the audit groups are not confirmed by this human observation, and the audit covers only the visible viewport. The Settings Preferences clipping and the Weekday chart label overlap have no matching audit group.

Session note: part of the early CHK-07 walk ran from an icon launch without the seeded dataset; layout observations do not depend on the dataset.

## Source-backed decision table

**Availability:** the APIs below are available at the iOS 27.0 deployment target. The documentation extracts returned by Xcode MCP DocumentationSearch carry no older-availability line, so no older-version claim is made here.

| Topic | Evidence |
| --- | --- |
| Official source | SwiftUI `DynamicTypeSize` ("Read this value from the environment to adapt a layout to the text size someone chooses", `isAccessibilitySize` for the five accessibility sizes, `/documentation/SwiftUI/DynamicTypeSize`); `ViewThatFits` (`/documentation/SwiftUI/ViewThatFits`); `View.minimumScaleFactor(_:)`; `ScaledMetric`. Read through Xcode MCP DocumentationSearch on 2026-11-16. |
| Option retain | Keep the layouts; accept truncation at AX5. Cost: AX5 users lose text content on the listed screens. |
| Option change | Adapt layouts per screen (for example vertical stacks when `isAccessibilitySize`, wrapping instead of single-line limits). Cost: many screens; each needs a regression proof. |
| Option defer | Fold the work into the pending todo `2026-11-14-fix-accessibility-audit-findings`, which already tracks the audit groups. |
| Recommendation | None in Phase 11 by plan rule; the owner chooses retain, change or defer, and whether to scope per screen. |
| Data, accessibility, lifecycle risk | No data or schema change. Accessibility risk is the open defect itself. |

## Recommendation and proposed scope

No fix in Phase 11. If the owner chooses change, split the scope per screen (Home, Insights, Add Drink, Settings Preferences, Onboarding) so each has its own verification, and rerun the audit at AX5 after the change.

## Owner decision record

decision: change
decision date: 2026-11-16
exact scope: adapt layouts at the accessibility text sizes in a single plan (11-16) for Home, Insights (including the AlcoholAreaChart fixed height and axis labels), Add Drink steps 1 and 2 (drink-type tiles, Cancel button), Settings Preferences and Onboarding, using DynamicTypeSize.isAccessibilitySize, ViewThatFits or AnyLayout, wrapping instead of single-line limits and ScaledMetric as appropriate; each screen gets a UI test at AX5; the owner re-observes CHK-07
owner reason: chosen in /gsd-plan-phase 11 --gaps session
