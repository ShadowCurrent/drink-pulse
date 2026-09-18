# Phase 09: SwiftUI & Design System Modernization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-18
**Phase:** 09-swiftui-design-system-modernization
**Areas discussed:** Add Drink dismissal ownership, History and Liquid Glass safeguards, Insights charts and motion, Verification emphasis

---

## Add Drink dismissal ownership

**User's choice:** Use standard SwiftUI dismissal access; test cancel and save independently in a focused UI test; retain semantic accessibility assertions and add a UI-level dismissal-control check.

## History and Liquid Glass safeguards

**User's choice:** Require reproducible iOS 27 evidence before changes; retain `List` and escalate any rewrite; retain Liquid Glass except for local defect fixes; check VoiceOver, AX5 Dynamic Type, and applicable Reduce Motion.

**Notes:** The owner briefly selected proactive glass simplification after its implications were explained. It conflicts with the approved no-cosmetic-rewrite boundary, so it was deferred; the owner then confirmed the evidence-backed retain policy.

## Insights charts and motion

**User's choice:** No proactive rewrite. Preserve selection, callout, hero-card, VoiceOver, Audio Graph, and Reduce Motion behavior; change only with reproduced defect evidence.

## Verification emphasis

**User's choice:** Focused automated regression plus documented human checks for approved changes; Debug/Release builds plus Dashboard regressions for `DPArcProgress`; one durable VoiceOver UI test for the most affected flow; complete evidence records for retained workarounds.

## the agent's Discretion

None.

## Deferred Ideas

- Proactively simplify or remove History Liquid Glass without a reproduced defect.
- History filtering and category/ABV-scoped autocomplete, which are future product capabilities.
