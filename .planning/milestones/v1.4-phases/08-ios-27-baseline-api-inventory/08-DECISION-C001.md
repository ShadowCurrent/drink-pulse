# C001 — AddDrink dismiss-closure ownership

**Status:** owner-approved eligibility recorded — modernization not started
**Proposed destination:** Phase 09

## Current behavior

`drinkpulse/Features/AddDrink/AddDrinkView.swift:4,12` declares a custom SwiftUI `@Entry` environment value carrying the dismiss closure. The iOS 27 baseline reports at `AddDrinkView.swift:5` that the stored closure may invalidate dependents because closures are not comparable. The sheet currently dismisses through that injected value.

## Source-backed decision table

**Availability:** The selected iOS 27 minimum satisfies the current API/toolchain availability described by the official source below; no replacement is inferred from age alone.

| Topic | Evidence |
| --- | --- |
| Official source | [SwiftUI Entry](https://developer.apple.com/documentation/swiftui/entry()) (checked 2026-09-16). It is available for the iOS 27 minimum; no deprecation is claimed. |
| Proposed behavior | Evaluate a behavior-preserving dismissal ownership/injection shape that removes the comparability warning without changing sheet presentation or navigation. |
| Benefit | Removes the recorded compiler warning and avoids unnecessary dependent invalidation. |
| Cost | Small implementation diff; focused add-drink/sheet regression plus full iOS 27 baseline rerun after C002 unblocks compilation. |
| Alternatives | **Retain** the current entry and warning; use a different ownership shape only if it preserves dismissal semantics. |
| Compatibility | iOS 27 availability is satisfied; no lower deployment target is supported. |
| Data / accessibility / lifecycle risk | No data shape change; an incorrect injection could fail to dismiss, dismiss the wrong presentation, or alter VoiceOver focus/navigation order. |

## Recommendation and proposed scope

Recommend an evaluation-only Phase 09 change limited to this closure’s ownership/injection and focused add-drink regression coverage. Do not alter forms, persistence, or navigation structure. This is substantial because even a tiny change can alter dismissal/navigation behavior.

## Owner decision record

**Outcome:** approve
**Decision date:** 2026-09-16
**Exact scope:** Usunąć wyłącznie ostrzeżenie o zamknięciu AddDrink przy zachowaniu prezentacji arkusza, nawigacji i zachowania VoiceOver; dodać skoncentrowaną regresję AddDrink/arkusza.
**Owner reason:** Modernizacja ma być ostrożna, oparta na mierzalnych problemach i testach regresji; bez szerokich przebudów ani zmian danych/formatów bez celu biznesowego.
**Owner response:** `zatwierdzam wszystkie C001–C012 z tym powodem, jednak nie zaczynaj modernizacji, jedynie zapisz stan tak abym po wyczyszczeniu kontekstu mogl go wznowic jutro`

No modernization has started. Only this bounded Phase 09 eligibility is recorded; implementation still requires the stated diagnostic and regression proof.
