# Requirements: DrinkPulse

**Milestone:** v1.4 iOS 27 Migration & Modernization
**Defined:** 2026-09-15
**Status:** Approved 2026-09-16
**Core Value:** Every logged drink and every guideline comparison stays accurate and private.

## v1.4 Requirements

### Platform baseline

- [x] **PLAT-01**: All app and test targets require iOS 27.0 in every relevant build configuration.
- [x] **PLAT-02**: Developers can build and test using the documented Xcode/iOS 27 toolchain; build scripts, resolved dependencies and living documentation match the selected baseline.

### Evidence-based modernization

- [x] **MOD-01**: A complete inventory covers app entry/startup, every feature area, design system, domain, persistence, services, tests and tooling. Each deprecated API, outdated pattern and workaround candidate has a change/retain/externally-blocked disposition with exact location, official Apple source, availability and rationale; areas with no changes are recorded.
- [x] **MOD-02**: Users retain navigation, forms, sheets, History and Insights behavior after all approved SwiftUI/design-system replacements are applied and verified. Known platform workarounds are removed only after iOS 27 evidence establishes they are obsolete. *Exception (owner decision 2026-11-13): complete with D1 deferred to backlog todo `2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md`. The cross-tab Liquid Glass flicker after Add Drink dismissal and the intermittent iOS 27 simulator `glassEffect` crash are NOT fixed and not device-confirmed; the todo stays pending.*
- [x] **MOD-03**: Approved modernization of domain, persistence, service and concurrency implementations is applied with documented isolation/lifecycle reasoning and regression evidence.
- [ ] **MOD-04**: App-owned deprecated API warnings are resolved without suppression; any externally blocked deprecation is individually documented with official source, impact and follow-up. *Basis: Phase 11 evidence section Zero-warning build (MOD-04): app-owned deprecation warnings 0 in the Debug build and in the Release build on the iphoneos 27.2 SDK; the only remaining warning lines are an external build-tool note with no impact. The Release build on the simulator SDK was not run (owner runner policy D11-20).*
- [x] **MOD-05**: When official Apple documentation or iOS 27 diagnostics reveal a substantial API replacement or rewrite, the owner can review a concrete analysis of current and proposed behavior, benefits, costs, compatibility, data/accessibility risks, alternatives and recommended scope before that rewrite enters an execution plan; discoveries made later in the milestone return to the same discussion.

### Data and integrations

- [x] **DATA-01**: Users upgrading with existing stores retain events, templates, profile, identities and stored values; supported legacy schema fixtures and a current-store upgrade scenario pass without reset or destructive recovery. Shipped schemas remain immutable; necessary model changes add a version and migration stage.
- [x] **INT-01**: Daily and weekly notifications preserve opt-in, scheduling, completed-week calculations and cold/warm tap routing on iOS 27.
- [x] **INT-02**: HealthKit preserves permission handling, opt-in behavior, write/delete operations and UUID-based deduplication on iOS 27; CloudKit remains disabled.

### Release verification

- [ ] **VER-01**: Debug and Release builds succeed with the chosen toolchain, and the relevant unit/integration/UI regression suites pass on iOS 27; results identify compiler, SDK, destination and remaining limitations. *Exceptions (owner decision D11-02, 2026-11-14): complete with named exceptions. Full run on the iOS 27.2 simulator: 834 tests, 0 failed, 18 skipped by gate; overall coverage 94.65 percent. Domain coverage is 90.06 percent against the 100 percent per-layer target, NOT met, listed as debt (WINDOWS.md row 7, ledger DL-W01 and DL-W07). Known failures on the ledger (DL-T01 to DL-T07): the two History edit tests failed in the scoped run only; the D1 harness tests are Skipped by their gate; no new flake. See 11-EVIDENCE.md.*
- [ ] **VER-02**: Users can complete onboarding, startup/retry, drink add/edit/delete, History list/calendar, Insights, settings and backup export/import on iOS 27 without loss of existing behavior or data. *Limitations (owner decisions D11-02 and D11-04): complete with named limitations. No UI test drives the backup import (L-01); edit coverage is partial and the data-integrity risk of the edit flow is undetermined (L-02); the Phase 10 device proof of data preservation is historical (L-03); UI tests run on an in-memory seeded store (L-04); interrupted migration and interrupted Health write are acknowledged residuals (L-09). See 11-EVIDENCE.md.*
- [ ] **VER-03**: VoiceOver (including both chart Audio Graphs), Reduce Motion, Dynamic Type through AX5, light/dark and Increase Contrast checks pass for affected flows on iOS 27; recorded tests distinguish automated and human evidence and outstanding debt. *Not complete (2026-11-16): the owner checklist run on the iOS 27.2 simulator has 3 fails (CHK-05 and CHK-06 Reduce Motion, CHK-07 Dynamic Type at AX5) and 5 open items (CHK-00, CHK-01, CHK-02, CHK-04, CHK-10; the VoiceOver rotor and both chart Audio Graphs need a device); the accessibility audit is red with 311 open findings, recorded as open and not allow-listed (owner decision D11-22). Owner briefs 11-DECISION-C014, C015, C016, OBS-A and OBS-C are pending. See 11-EVIDENCE.md.*

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
| PLAT-01 | Phase 08 | Complete |
| PLAT-02 | Phase 08 | Complete |
| MOD-01 | Phase 08 | Complete |
| MOD-05 | Phase 08 | Complete |
| MOD-02 | Phase 09 | Complete |
| MOD-03 | Phase 10 | Complete |
| MOD-04 | Phase 11 | Gaps Found |
| DATA-01 | Phase 10 | Complete |
| INT-01 | Phase 10 | Complete |
| INT-02 | Phase 10 | Complete |
| VER-01 | Phase 11 | Gaps Found |
| VER-02 | Phase 11 | Gaps Found |
| VER-03 | Phase 11 | Pending |

**Coverage:** 13 approved requirements; 13 mapped exactly once; 0 unmapped.

---
*Last updated: 2026-11-16 after Phase 11 evidence reconciliation: MOD-04 complete; VER-01 complete with named exceptions; VER-02 complete with named limitations; VER-03 stays Pending (checklist fails CHK-05, CHK-06, CHK-07 and 311 open audit findings).*
