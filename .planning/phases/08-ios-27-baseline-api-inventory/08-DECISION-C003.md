# C003 — History context menu and destructive confirmation

**Status:** owner outcome pending — not authorized  
**Proposed destination:** Phase 09

## Current behavior

`drinkpulse/Features/History/Components/EventContextMenu.swift:5-58` provides the History menu and explicit destructive confirmation. Its behavior is covered by `drinkpulse/Features/History/HistoryInteractionUITests.swift:88-132` and `drinkpulse/Features/History/WrongRowContextMenuTargetUITests.swift:26-83`. The prior Liquid Glass preview/zoom issue is documented in `contextmenu-zoom-glitch.md`.

## Source-backed decision table

**Availability:** The selected iOS 27 minimum satisfies the current API/toolchain availability described by the official source below; no replacement is inferred from age alone.

| Topic | Evidence |
| --- | --- |
| Official source | [contextMenu](https://developer.apple.com/documentation/swiftui/view/contextmenu%28menuitems%3Apreview%3A%29) and [confirmationDialog](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:message:)) (checked 2026-09-16); iOS 27 satisfies availability and no deprecation is claimed. |
| Proposed behavior | Retain by default; consider another menu/preview form only after deterministic iOS 27 evidence and applicable official guidance. |
| Benefit | No measured benefit exists today. |
| Cost | High-risk focused UI and manual Liquid Glass/VoiceOver verification after compilation succeeds. |
| Alternatives | **Retain** current correct-row targeting, duplicate/delete actions, and explicit destructive confirmation. |
| Compatibility | Current APIs are supported on iOS 27. |
| Data / accessibility / lifecycle risk | Deletion behavior, wrong-row targeting, VoiceOver actions, visual preview, and confirmation safety can change; persistence deletion is user-visible. |

## Recommendation and proposed scope

Recommend retain. Any approved scope must name a reproduced iOS 27 defect and preserve every current context-menu, VoiceOver, and destructive-confirmation assertion; lack of replacement documentation is not an external block.

## Owner decision record

**Outcome:** pending  
**Decision date:**  
**Exact scope:**  
**Owner reason:**  

No execution scope is approved.
