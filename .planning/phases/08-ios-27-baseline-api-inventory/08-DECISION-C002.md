# C002 — History List and calendar scroll architecture

**Status:** owner-approved eligibility recorded — modernization not started
**Proposed destination:** Phase 09

## Current behavior

`drinkpulse/Features/History/HistoryListQueryView.swift:39-81` uses native `List` history; `drinkpulse/Features/History/HistoryView.swift:82-109,147-162` uses a separate calendar scroll branch; and `drinkpulse/Features/History/Components/HistoryEventCardRow.swift:55,75` handles horizontal cards. The earlier List-to-`ScrollView`/`LazyVStack` attempt caused variable row heights, grouping, pagination, and gesture failures and was reverted.

## Source-backed decision table

**Availability:** The selected iOS 27 minimum satisfies the current API/toolchain availability described by the official source below; no replacement is inferred from age alone.

| Topic | Evidence |
| --- | --- |
| Official source | [List](https://developer.apple.com/documentation/swiftui/list), [ScrollView](https://developer.apple.com/documentation/swiftui/scrollview), and [iOS/iPadOS 27 release notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes) (checked 2026-09-16). No deprecation/replacement claim exists. |
| Proposed behavior | Retain by default; only evaluate a concrete iOS 27-supported replacement after focused reproduction proves it preserves List/calendar interaction. |
| Benefit | A replacement could only be justified by a measured current defect; none is established. |
| Cost | High: simulator reproduction, History UI tests, Dynamic Type, paging/grouping/gesture checks, and human accessibility validation. |
| Alternatives | **Retain** native List plus the distinct calendar scroll surface; do not revive the prior ScrollView rewrite. |
| Compatibility | iOS 27 satisfies all current APIs. |
| Data / accessibility / lifecycle risk | No data migration, but user-visible scrolling, paging, Dynamic Type, VoiceOver traversal, and gesture behavior can regress. |

## Recommendation and proposed scope

Recommend retain. If approved for exploration, scope only a documented, reproduced defect and an exact replacement with the named History regressions; do not place a general List-to-ScrollView rewrite in Phase 09.

## Owner decision record

**Outcome:** approve
**Decision date:** 2026-09-16
**Exact scope:** Kontrolowany audyt History i punktowe poprawki wyłącznie dla konkretnie zmierzonych defektów listy, kalendarza, grupowania, stronicowania, gestów, Dynamic Type lub VoiceOver; bez z góry zakładanego przepisywania List do ScrollView.
**Owner reason:** Modernizacja ma być ostrożna, oparta na mierzalnych problemach i testach regresji; bez szerokich przebudów ani zmian danych/formatów bez celu biznesowego.
**Owner response:** `zatwierdzam wszystkie C001–C012 z tym powodem, jednak nie zaczynaj modernizacji, jedynie zapisz stan tak abym po wyczyszczeniu kontekstu mogl go wznowic jutro`

No modernization has started. Only this bounded Phase 09 eligibility is recorded; a documented measured defect and named regressions remain prerequisites.
