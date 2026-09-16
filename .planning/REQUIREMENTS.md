# Requirements: DrinkPulse

**Milestone:** v1.4 iOS 27 Migration & Modernization
**Defined:** 2026-09-15
**Status:** Approved 2026-09-16
**Core Value:** Every logged drink and every guideline comparison stays accurate and private.

## v1.4 Requirements

### Platform baseline

- [ ] **PLAT-01**: All app and test targets require iOS 27.0 in every relevant build configuration.
- [x] **PLAT-02**: Developers can build and test using the documented Xcode/iOS 27 toolchain; build scripts, resolved dependencies and living documentation match the selected baseline.

### Evidence-based modernization

- [x] **MOD-01**: A complete inventory covers app entry/startup, every feature area, design system, domain, persistence, services, tests and tooling. Each deprecated API, outdated pattern and workaround candidate has a change/retain/externally-blocked disposition with exact location, official Apple source, availability and rationale; areas with no changes are recorded.
- [ ] **MOD-02**: Users retain navigation, forms, sheets, History and Insights behavior after all approved SwiftUI/design-system replacements are applied and verified. Known platform workarounds are removed only after iOS 27 evidence establishes they are obsolete.
- [ ] **MOD-03**: Approved modernization of domain, persistence, service and concurrency implementations is applied with documented isolation/lifecycle reasoning and regression evidence.
- [ ] **MOD-04**: App-owned deprecated API warnings are resolved without suppression; any externally blocked deprecation is individually documented with official source, impact and follow-up.
- [x] **MOD-05**: When official Apple documentation or iOS 27 diagnostics reveal a substantial API replacement or rewrite, the owner can review a concrete analysis of current and proposed behavior, benefits, costs, compatibility, data/accessibility risks, alternatives and recommended scope before that rewrite enters an execution plan; discoveries made later in the milestone return to the same discussion.

### Data and integrations

- [ ] **DATA-01**: Users upgrading with existing stores retain events, templates, profile, identities and stored values; supported legacy schema fixtures and a current-store upgrade scenario pass without reset or destructive recovery. Shipped schemas remain immutable; necessary model changes add a version and migration stage.
- [ ] **INT-01**: Daily and weekly notifications preserve opt-in, scheduling, completed-week calculations and cold/warm tap routing on iOS 27.
- [ ] **INT-02**: HealthKit preserves permission handling, opt-in behavior, write/delete operations and UUID-based deduplication on iOS 27; CloudKit remains disabled.

### Release verification

- [ ] **VER-01**: Debug and Release builds succeed with the chosen toolchain, and the relevant unit/integration/UI regression suites pass on iOS 27; results identify compiler, SDK, destination and remaining limitations.
- [ ] **VER-02**: Users can complete onboarding, startup/retry, drink add/edit/delete, History list/calendar, Insights, settings and backup export/import on iOS 27 without loss of existing behavior or data.
- [ ] **VER-03**: VoiceOver (including both chart Audio Graphs), Reduce Motion, Dynamic Type through AX5, light/dark and Increase Contrast checks pass for affected flows on iOS 27; recorded tests distinguish automated and human evidence and outstanding debt.

## Future Requirements

History filtering, category/ABV-scoped autocomplete, weekly-summary wording, the separately deferred consumptionDate index, and broader feature backlog remain future work.

## Out of Scope

| Feature | Reason |
|---|---|
| CloudKit activation, BAC, AI entry, Watch/iPad features | Migration of existing capabilities only; separate product decisions |
| Cosmetic rewrites without evidence | Modernization must have a verified rationale |
| Changing shipped schemas in place or resetting user data | Preserve existing user data |
| New third-party dependencies without demonstrated migration need | Existing native stack retained |

## Traceability

| Requirement | Phase | Status |
|---|---|---|
| PLAT-01 | Phase 08 | Pending |
| PLAT-02 | Phase 08 | Complete |
| MOD-01 | Phase 08 | Complete |
| MOD-05 | Phase 08 | Complete |
| MOD-02 | Phase 09 | Pending |
| MOD-03 | Phase 10 | Pending |
| MOD-04 | Phase 11 | Pending |
| DATA-01 | Phase 10 | Pending |
| INT-01 | Phase 10 | Pending |
| INT-02 | Phase 10 | Pending |
| VER-01 | Phase 11 | Pending |
| VER-02 | Phase 11 | Pending |
| VER-03 | Phase 11 | Pending |

**Coverage:** 13 approved requirements; 13 mapped exactly once; 0 unmapped.

---
*Last updated: 2026-09-16 after roadmap approval and owner-requested discussion of substantial API replacements.*
