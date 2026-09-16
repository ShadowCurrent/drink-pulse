# C004 — Accessible Swift Charts interaction and Audio Graphs

**Status:** owner-approved eligibility recorded — modernization not started
**Proposed destination:** Phase 09

## Current behavior

`drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift:21-79` and `AlcoholAreaChart+Accessibility.swift:4-34`, plus `WeekdayBarChart.swift:16-62` and `WeekdayBarChart+Accessibility.swift:4-35`, provide selection, semantic labels, and `AXChartDescriptor` data for VoiceOver and Audio Graph.

## Source-backed decision table

**Availability:** The selected iOS 27 minimum satisfies the current API/toolchain availability described by the official source below; no replacement is inferred from age alone.

| Topic | Evidence |
| --- | --- |
| Official source | [accessibilityChartDescriptor](https://developer.apple.com/documentation/swiftui/view/accessibilitychartdescriptor(_:)), [chartXSelection](https://developer.apple.com/documentation/swiftui/view/chartxselection(value:)), and [Swift Charts](https://developer.apple.com/documentation/charts) (checked 2026-09-16). `chartXSelection` is iOS 17+; iOS 27 satisfies availability. |
| Proposed behavior | Retain current accessible charts unless an observed interaction or accessibility defect requires a specific replacement. |
| Benefit | No measured benefit supports a substitution. |
| Cost | Focused chart tests, Audio Graph/VoiceOver human checks, selection/scrubbing regression, and accessibility documentation. |
| Alternatives | **Retain** descriptors, labels, and selection; add only targeted evidence if a defect appears. |
| Compatibility | Existing APIs remain available on iOS 27. |
| Data / accessibility / lifecycle risk | Accessibility is release-critical: an API change can remove chart semantics, labels, selection, or Audio Graph representation. No data/lifecycle change is expected. |

## Recommendation and proposed scope

Recommend retain. Any later scope must be limited to a measured chart issue and preserve both chart families’ accessible output; it cannot be authorized merely because a newer API exists.

## Owner decision record

**Outcome:** approve
**Decision date:** 2026-09-16
**Exact scope:** Kontrolowany audyt wykresów i punktowe poprawki tylko dla konkretnie zmierzonego defektu interakcji lub dostępności; zachować oba wykresy, selekcję, opisy VoiceOver i Audio Graph, bez prewencyjnego zastępowania API.
**Owner reason:** Modernizacja ma być ostrożna, oparta na mierzalnych problemach i testach regresji; bez szerokich przebudów ani zmian danych/formatów bez celu biznesowego.
**Owner response:** `zatwierdzam wszystkie C001–C012 z tym powodem, jednak nie zaczynaj modernizacji, jedynie zapisz stan tak abym po wyczyszczeniu kontekstu mogl go wznowic jutro`

No modernization has started. Only this bounded Phase 09 eligibility is recorded; a measured defect and accessibility regressions remain prerequisites.
