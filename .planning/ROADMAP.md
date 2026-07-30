# Roadmap: DrinkPulse

## Milestones

- ✅ **v1.1 Weekly Summary Notification** — Phases 1-1.1 (shipped 2026-07-21)
- ✅ **v1.2 Swift 6 + App-Target Hardening** — Phases 2-3 (shipped 2026-07-28)
- 🚧 **v1.3 Native Feel** — Phases 4-6 (in progress)

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)
- Phase numbers continue across milestones — v1.1 used 1 and 01.1; v1.2 used 2-3; v1.3 continues at 4 (never restart at 01)

<details>
<summary>✅ v1.1 Weekly Summary Notification (Phases 1-1.1) — SHIPPED 2026-07-21</summary>

- [x] Phase 1: Weekly Summary Notification (5/5 plans) — completed 2026-07-20
- [x] Phase 01.1: Address tech debt: weekly summary notification (1/1 plan) — completed 2026-07-21

Full detail: `.planning/milestones/v1.1-ROADMAP.md`

</details>

<details>
<summary>✅ v1.2 Swift 6 + App-Target Hardening (Phases 2-3) — SHIPPED 2026-07-28</summary>

- [x] Phase 2: Swift 6 Language Mode Migration (2/2 plans) — completed 2026-07-27
- [x] Phase 3: App Startup Hardening (2/2 plans) — completed 2026-07-28

Full detail: `.planning/milestones/v1.2-ROADMAP.md`

</details>

### 🚧 v1.3 Native Feel (In Progress)

**Milestone Goal:** Make History, Insights, and cold-launch feel native
iOS 26 — chart scrubbing, a directional List↔Calendar slide transition,
and a branded launch screen (Cluster B from the pending-todos triage).

- [x] **Phase 4: Branded Static Launch Screen** - Cold launch shows a branded static launch screen instead of the auto-generated blank one
- [x] **Phase 5: Insights Chart Scrubbing** - Users can drag across Insights charts to read exact per-point values, with full VoiceOver parity (completed 2026-07-30)
- [ ] **Phase 6: History List↔Calendar Directional Transition** - Switching History's List/Calendar segments animates as directional navigation

## Phase Details

### Phase 4: Branded Static Launch Screen

**Goal**: Cold launch shows a branded, native-feeling launch screen instead of the auto-generated blank one.
**Depends on**: Nothing (first phase of this milestone; independent of Phase 5/6 — no shared files or state)
**Requirements**: LAUNCH-01
**Success Criteria** (what must be TRUE):

  1. On a genuine force-quit cold launch on a real device, the launch screen shows the app icon on a background color matching the app's real first screen — no text, no spinner, no auto-generated blank white screen.
  2. The launch screen is a static image only (no animation, no wordmark), consistent with Apple HIG launch-screen guidance.
  3. The transition from the launch screen into the app's first live frame (onboarding or Dashboard) shows no visible color/flash mismatch.

**Plans**: 1 plan
Plans:

- [x] 04-01-PLAN.md — Branded launch screen: Asset Catalog entries + launch-screen build-setting wiring, launch-handoff regression UI test, real-device cold-launch checkpoint

**UI hint**: yes
**Closed 2026-07-30** by owner decision after 19 real-device verification rounds
(see `.planning/debug/slow-container-cold-start.md`). Background match, icon
presence, and no-text/no-spinner all confirmed on real hardware. Exact on-screen
icon size could not be further diagnosed — two content-verified opposite-direction
size edits produced no visible on-device difference even after fresh install and
full reboot — and the owner chose to accept the current 60pt (Home Screen-icon-sized,
matching locked spec D-03) state rather than continue chasing it.

### Phase 5: Insights Chart Scrubbing

**Goal**: Users can drag across Insights charts to read exact per-point values, with the hero card following the touch and full VoiceOver parity.
**Depends on**: Nothing (independent of Phase 4/6 — no shared files or state)
**Requirements**: CHART-01, CHART-02, CHART-03, CHART-04
**Success Criteria** (what must be TRUE):

  1. User can drag a finger across `AlcoholAreaChart` or `WeekdayBarChart` and see a callout showing the value at the touched point.
  2. While scrubbing, the Insights hero card headline updates to reflect the touched point's value, and reverts to the period total when the touch is released.
  3. A VoiceOver user can access every chart data point's value through an accessible chart summary, without needing to perform the drag gesture.
  4. With Reduce Motion enabled, the scrub callout appears and disappears without a sliding/animated transition.

**Plans**: 2/2 plans executed
Plans:
**Wave 1**

- [x] 05-01-PLAN.md — Drag-to-scrub selection + callout for both charts, hero card follow/revert, Reduce Motion gating (CHART-01, CHART-02, CHART-04)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 05-02-PLAN.md — VoiceOver `AXChartDescriptorRepresentable` for both charts (CHART-03)

**UI hint**: yes

### Phase 6: History List↔Calendar Directional Transition

**Goal**: Switching between List and Calendar in History feels like directional navigation, not an abrupt swap, on any real dataset.
**Depends on**: Nothing (independent of Phase 4/5; sequenced last per research due to the List/ScrollView container-mismatch discovery risk)
**Requirements**: HIST-01, HIST-02, HIST-03
**Success Criteria** (what must be TRUE):

  1. Switching from List to Calendar slides content in one direction; switching back from Calendar to List slides in the opposite direction.
  2. With Reduce Motion enabled, switching between List and Calendar happens with no sliding animation.
  3. Switching among List, Calendar, and the empty state shows no layout pop, flash, or visible `@Query` re-fetch flicker, verified with a real dataset on a real device.

**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|-----------------|--------|-----------|
| 1. Weekly Summary Notification | v1.1 | 5/5 | Complete | 2026-07-20 |
| 01.1. Address tech debt | v1.1 | 1/1 | Complete | 2026-07-21 |
| 2. Swift 6 Language Mode Migration | v1.2 | 2/2 | Complete | 2026-07-27 |
| 3. App Startup Hardening | v1.2 | 2/2 | Complete | 2026-07-28 |
| 4. Branded Static Launch Screen | v1.3 | 1/1 | Complete | 2026-07-30 |
| 5. Insights Chart Scrubbing | v1.3 | 2/2 | Complete    | 2026-07-30 |
| 6. History List↔Calendar Directional Transition | v1.3 | 0/TBD | Not started | - |

---
*Last updated: 2026-07-28 — v1.3 Native Feel roadmap created: Phase 4 (Branded Static Launch Screen), Phase 5 (Insights Chart Scrubbing), Phase 6 (History List↔Calendar Directional Transition), continuing phase numbering from v1.2's Phase 3. 8/8 v1.3 requirements mapped (LAUNCH-01 → Phase 4; CHART-01..04 → Phase 5; HIST-01..03 → Phase 6).*
