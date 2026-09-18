# Phase 09: SwiftUI & Design System Modernization - Context

**Gathered:** 2026-09-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Apply only the Phase 08-approved, evidence-backed SwiftUI and design-system replacements needed to preserve DrinkPulse behavior on iOS 27. Repair the identified Add Drink and `DPArcProgress` diagnostics, and audit History, Insights, motion, Liquid Glass, and accessibility only when a reproducible iOS 27 defect justifies a local correction. Preserve navigation, sheets, forms, History list/calendar, charts, accessibility, localization, and established platform workarounds. No speculative rewrites or new product capabilities.

</domain>

<decisions>
## Implementation Decisions

### Add Drink dismissal ownership
- **D-01:** Replace the custom `@Entry` dismissal closure with standard SwiftUI dismissal access inside the presented Add Drink view where possible. Preserve sheet presentation, navigation, and VoiceOver behavior.
- **D-02:** Add focused UI regression coverage for opening Add Drink and independently exercising cancel and successful-save dismissal; each returns to the originating tab.
- **D-03:** Retain semantic accessibility assertions and add a UI-level check that the dismissal control is reachable and correctly labeled.

### History and Liquid Glass safeguards
- **D-04:** Change History or Liquid Glass production code only for a reproducible iOS 27 defect with focused automated regression evidence or a clear documented human check.
- **D-05:** Keep `List` as the History implementation and make the smallest targeted correction. A List-to-`ScrollView`/lazy-stack rewrite requires a new owner decision brief.
- **D-06:** Retain the existing Liquid Glass layer unless a measured visual, contrast, accessibility, or context-menu interaction defect appears; modify only the affected modifier or component.
- **D-07:** For every approved History correction, verify VoiceOver actions and labels, Dynamic Type through AX5, and Reduce Motion whenever the changed view animates.

### Insights charts and motion
- **D-08:** Change an Insights chart only for a reproducible iOS 27 interaction or accessibility defect with focused regression evidence.
- **D-09:** Preserve drag selection, selected-value callouts, and the Insights hero card's follow/revert behavior exactly.
- **D-10:** Preserve both charts' semantic labels, VoiceOver descriptions, and Audio Graph descriptors; test the changed descriptor path.
- **D-11:** Preserve the existing Reduce Motion rule: callouts do not slide when Reduce Motion is enabled. Add a focused check if animation code changes.

### Verification evidence
- **D-12:** Every approved production change needs focused automated regression plus a documented human check for its affected visual or accessibility behavior.
- **D-13:** The `DPArcProgress` repair must clear iOS 27 Debug and Release builds and pass affected Dashboard regressions; the full suite is not a per-change gate.
- **D-14:** Add one durable Xcode 27 VoiceOver UI test for the Phase 09 flow with the most meaningful behavior change, retaining all existing semantic assertions.
- **D-15:** A retained workaround must record the exact path checked, iOS 27 evidence, protected behavior, and why no replacement is justified.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and owner rules
- `.planning/ROADMAP.md` — Phase 09 goal and success criteria.
- `.planning/REQUIREMENTS.md` — MOD-02 and the evidence-based-modernization boundaries, including the ban on cosmetic rewrites without evidence.
- `.planning/PROJECT.md` — privacy/data invariants, mandatory official Apple documentation rule, and owner-brief rule for substantial discoveries.
- `.planning/todos/pending/2026-09-15-migrate-project-to-ios-27-and-modernize-codebase.md` — originating migration request.
- `CLAUDE.md` — architecture, accessibility, testing, and documentation conventions.

### Phase 08 handoff and eligible scope
- `.planning/phases/08-ios-27-baseline-api-inventory/08-CONTEXT.md` — milestone-wide decisions, baseline, and implementation handoff.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-REGISTER.md` — authoritative approved scope for C001–C007; no broad rewrite is authorized.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md` — exact UI candidate locations, retained surfaces, official sources, and evidence requirements.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md` — iOS 27 baseline commands and the app-owned `DPArcProgress` compiler diagnostic.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C001.md` — Add Drink dismissal warning scope and behavior risks.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C002.md` — History audit scope and List rewrite boundary.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C003.md` — History context-menu safeguards.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C004.md` — Insights chart interaction/accessibility safeguards.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C005.md` — animation and Reduce Motion safeguards.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C006.md` — Liquid Glass audit boundary.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C007.md` — representative Xcode 27 VoiceOver UI test scope.

### Existing workaround and UI evidence
- `.planning/debug/resolved/history-scrollview-bugs.md` — History List/ScrollView revert evidence.
- `.planning/debug/resolved/contextmenu-zoom-glitch.md` — Liquid Glass context-menu workaround evidence.
- `.planning/milestones/v1.3-phases/07-swiftui-list-performance-gesture-audit/07-CONTEXT.md` — prior History identity, gesture, and accessibility decisions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `drinkpulse/DesignSystem/DPArcProgress.swift` — isolated compiler-correctness repair point; rendered arc, animation, and accessibility label must stay intact.
- `drinkpulse/Features/AddDrink/AddDrinkView.swift` and existing Add Drink UI tests — dismissal ownership and focused regression integration points.
- `drinkpulse/Features/History/HistoryListQueryView.swift`, `HistoryView.swift`, and `Components/EventContextMenu.swift` — established List, transition, and contextual-action surfaces.
- `drinkpulse/Features/Insights/Components/{AlcoholAreaChart.swift,WeekdayBarChart.swift}` and their `+Accessibility.swift` files — existing selection, callout, and Audio Graph implementation/test seams.

### Established Patterns
- SwiftUI views are structs; view models are `@Observable @MainActor final class`; all user-visible strings use `String(localized:)`.
- Existing UI accessibility behavior is guarded with semantic tests, `AXChartDescriptorRepresentable`, `accessibilityReduceMotion`, and focused UI tests.
- `DPGlass.swift` centralizes Liquid Glass and chart-callout styling; local changes should reuse these modifiers rather than duplicate styling.

### Integration Points
- `drinkpulse/Features/Shell/RootShellView.swift` owns tabs and sheet presentation; Add Drink dismissal tests must confirm return to the originating tab.
- `drinkpulseTests/Features/` and `drinkpulseUITests/Features/` mirror production feature directories and are the focused regression homes.

</code_context>

<specifics>
## Specific Ideas

The owner wants cautious modernization: measured iOS 27 problems and regression evidence justify local changes; API age, general best practice, or cosmetic preference alone do not.

</specifics>

<deferred>
## Deferred Ideas

- Proactively simplify or remove Liquid Glass styling in History without a reproduced defect — future design work, outside the evidence-first modernization scope.
- Practical History list filtering — product capability, outside Phase 09.
- Scope custom-name autocomplete by drink category and ABV — product capability, outside Phase 09.

</deferred>

---

*Phase: 09-swiftui-design-system-modernization*
*Context gathered: 2026-09-18*
