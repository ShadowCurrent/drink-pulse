# C005 — Reduce Motion-aware transitions and animations

**Status:** owner-approved eligibility recorded — modernization not started
**Proposed destination:** Phase 09

## Current behavior

`drinkpulse/Features/History/HistoryView.swift:9,84-109`, `EventContextMenu.swift:5-13`, `AlcoholAreaChart.swift:10,100-105`, `WeekdayBarChart.swift:10,75-86`, and `OnboardingView.swift:9,78-88` explicitly avoid or remove animation when Reduce Motion is enabled.

## Source-backed decision table

**Availability:** The selected iOS 27 minimum satisfies the current API/toolchain availability described by the official source below; no replacement is inferred from age alone.

| Topic | Evidence |
| --- | --- |
| Official source | [accessibilityReduceMotion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion) and [animation(_:value:)](https://developer.apple.com/documentation/swiftui/view/animation(_:value:)) (checked 2026-09-16); iOS 27 satisfies availability. |
| Proposed behavior | Retain explicit Reduce Motion handling; Phase 11 verifies current simulator/device behavior. |
| Benefit | No newer API creates a demonstrated benefit. |
| Cost | Accessibility test/human checks across History, charts, and onboarding. |
| Alternatives | **Retain** current gating; avoid cosmetic animation rewrites. |
| Compatibility | Current APIs are supported on iOS 27. |
| Data / accessibility / lifecycle risk | Accessibility risk is high: changing gating can reintroduce motion. No data or lifecycle change is expected. |

## Recommendation and proposed scope

Recommend retain and verify, not rewrite. Any behavior change requires an exact accessibility defect, focused regression proof, and a separately approved scope.

## Owner decision record

**Outcome:** approve
**Decision date:** 2026-09-16
**Exact scope:** Kontrolowany audyt animacji z Reduce Motion i punktowe poprawki tylko dla konkretnie zmierzonego naruszenia; bez kosmetycznego przepisywania animacji i z zachowaniem braku ruchu po włączeniu ustawienia.
**Owner reason:** Modernizacja ma być ostrożna, oparta na mierzalnych problemach i testach regresji; bez szerokich przebudów ani zmian danych/formatów bez celu biznesowego.
**Owner response:** `zatwierdzam wszystkie C001–C012 z tym powodem, jednak nie zaczynaj modernizacji, jedynie zapisz stan tak abym po wyczyszczeniu kontekstu mogl go wznowic jutro`

No modernization has started. Only this bounded Phase 09 eligibility is recorded; a measured accessibility defect and regression proof remain prerequisites.
