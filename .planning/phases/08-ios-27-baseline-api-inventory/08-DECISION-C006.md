# C006 — Deliberate Liquid Glass surface

**Status:** owner outcome pending — not authorized  
**Proposed destination:** Phase 09 only if a documented defect exists

## Current behavior

`drinkpulse/DesignSystem/DPGlass.swift:18-31` centralizes the app’s deliberate Liquid Glass treatment and it is consumed by cards/charts. The History context-menu evidence shows glass-related rendering can interact with preview and zoom behavior.

## Source-backed decision table

**Availability:** The selected iOS 27 minimum satisfies the current API/toolchain availability described by the official source below; no replacement is inferred from age alone.

| Topic | Evidence |
| --- | --- |
| Official source | [glassEffect(_:in:)](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)) (checked 2026-09-16); the API is iOS 26+, so iOS 27 satisfies availability. |
| Proposed behavior | Retain the centralized styling absent an observed visual/accessibility defect. |
| Benefit | A replacement has no established benefit. |
| Cost | Visual light/dark/contrast and interaction validation, including context-menu behavior. |
| Alternatives | **Retain** the design-system abstraction; adjust only a reproducible defect. |
| Compatibility | Current API is available at the selected minimum. |
| Data / accessibility / lifecycle risk | No data/lifecycle change, but contrast, legibility, context-menu rendering, and VoiceOver context can be affected. |

## Recommendation and proposed scope

Recommend retain. A future scoped change must cite a concrete defect and preserve the current interaction and accessibility behavior; it is not approved by this brief.

## Owner decision record

**Outcome:** pending  
**Decision date:**  
**Exact scope:**  
**Owner reason:**
