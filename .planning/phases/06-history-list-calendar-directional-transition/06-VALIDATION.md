---
phase: 06
slug: history-list-calendar-directional-transition
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-31
---

# Phase 06 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (`drinkpulseTests`) + XCUITest (`drinkpulseUITests`) — both already configured, `PBXFileSystemSynchronizedRootGroup`s |
| **Config file** | none — scheme-driven via `xcodebuild test -scheme drinkpulse` |
| **Quick run command** | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseUITests/HistoryInteractionUITests` |
| **Full suite command** | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` |
| **Estimated runtime** | ~120 seconds (full suite; project baseline per Phase 04/05 VALIDATION.md) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (`HistoryInteractionUITests`).
- **After every plan wave:** Full suite must be green.
- **Before `/gsd-verify-work`:** Full suite green, plus the two manual-only checkpoints below (direction-correctness on alternating switches; HIST-03's real-device/real-dataset pass).
- **Max feedback latency:** ~60 seconds (quick run subset).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD (assigned at planning) | TBD | TBD | HIST-01 — segment switch shows correct end-state content in both directions (List→Calendar→List) | — | N/A | UI (XCUITest, end-state only — cannot assert mid-animation frames) | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseUITests/HistoryInteractionUITests` | ✅ Exists — `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift:54-81`, needs extension for direction alternation | ⬜ pending |
| TBD (assigned at planning) | TBD | TBD | HIST-01 (direction-correctness) — slide direction visually correct, doesn't invert on alternating switches | — | N/A | manual-only | N/A — XCUITest cannot assert animation direction mid-transition | N/A | ⬜ pending |
| TBD (assigned at planning) | TBD | TBD | HIST-02 — Reduce Motion produces instant cut, no slide | — | N/A | UI if a working `accessibilityReduceMotion` toggle pattern exists in this codebase, else manual-only | TBD — planner must check for existing precedent (none found by research) | ❌ Wave 0 | ⬜ pending |
| TBD (assigned at planning) | TBD | TBD | HIST-03 — no layout pop/flash/`@Query` flicker across List, Calendar, empty state, real dataset, real device | — | N/A | manual-only, per the requirement's own wording | N/A — manual by requirement's own design; existing `-dp_uitest YES` single-event seed is too small, needs a larger seed for this pass | N/A | ⬜ pending |

*Task IDs are TBD until `/gsd-planner` creates PLAN.md for this phase; the planner must map each row above onto a concrete task ID. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift` (+ `+Helpers.swift`) — add an alternating-direction assertion (Calendar→List→Calendar, not just the existing List-first sequence) to close the Pitfall 1 gap (direction lag/invert on alternating switches).
- [ ] Decide during planning whether HIST-02's Reduce Motion gate can be exercised via any existing project convention for simulating `accessibilityReduceMotion` in XCUITest — no existing precedent found in this codebase for automating this specific environment toggle; may end up manual-only with justification.
- [ ] No new unit-test file required — this phase's changes are presentation-only inside `HistoryView.swift`'s `body`/state; `HistoryViewModel` is explicitly not touched (zero stored properties today, per CONTEXT.md), so no incremental unit-test coverage target beyond what `HistoryViewModelTests.swift` already covers.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|-------------|--------------------|
| Slide direction is visually correct and doesn't invert on alternating switches | HIST-01 | XCUITest cannot assert animation direction/frame content mid-transition — inherent tool limitation, not a gap to close with more automation | Real device/simulator: tap List→Calendar→List→Calendar repeatedly (not just once each way). Confirm slide direction stays correct and doesn't lag/invert on the 2nd+ switch (Pitfall 1 — direction and content `@State` must update in the same synchronous scope). |
| No layout pop, flash, or `@Query` re-fetch flicker across List, Calendar, and the empty state | HIST-03 | Requirement's own wording demands "verified with a real dataset on a real device"; List's structural remount on every switch back is expected SwiftUI behavior whose visual impact can't be judged from documentation or a small fixture | Real device, seeded with a realistic multi-event dataset (larger than the existing single-event `-dp_uitest YES` fixture). Switch List↔Calendar↔empty-state repeatedly; watch specifically for layout pop, flash, or a visible re-fetch flicker on `HistoryListQueryView`'s `@Query`. If found, escalate to D-02's crossfade fallback per CONTEXT.md — do not silently accept. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
