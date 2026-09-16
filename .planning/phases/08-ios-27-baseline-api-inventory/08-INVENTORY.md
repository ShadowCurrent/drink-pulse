# Phase 08 — Master iOS 27 API and Source Inventory

**Reconciled:** 2026-09-16  
**Purpose:** This dated index joins the UI and data inventories with the truthful
[baseline](08-BASELINE.md). It is evidence and a decision queue, **not** approval
for Phase 09 or Phase 10 implementation. Owner outcomes remain pending in the
[decision register](08-DECISION-REGISTER.md).

## Evidence and coverage boundary

| Evidence | What it establishes | Limit |
| --- | --- | --- |
| [08-INVENTORY-UI.md](08-INVENTORY-UI.md) | Every UI production/resource path and every UI-test path, exact grouped locations, candidates UI-C-01…10, and UI no-candidate rows | It does not claim an unavailable iOS 27 UI test ran. |
| [08-INVENTORY-DATA.md](08-INVENTORY-DATA.md) | Every domain, persistence, service, remaining-test, and Xcode-tooling path, exact grouped locations, candidates D-01…05 and S-01…06, and data/tooling no-candidate rows | It does not authorize a schema, export, HealthKit, notification, or concurrency rewrite. |
| [08-BASELINE.md](08-BASELINE.md) and [08-BASELINE.json](08-BASELINE.json) | Xcode 27.0 (27A266a), Swift 6.4, iOS 27.0 SDK/simulator, Swift 6 language mode, commands, hashes, exit codes, and diagnostic classification | Debug, Release, and the full suite failed before tests started; unavailable counts are not zero or passing. |
| [08-DOC-AUDIT.md](08-DOC-AUDIT.md) | Current setup/build/test docs use the selected baseline and historical references are labeled | Historical plans and ADRs are not current toolchain evidence. |

`git ls-files drinkpulse drinkpulseTests drinkpulseUITests drinkpulse.xcodeproj`
returns **254** tracked paths: 156 app, 56 unit-test, 39 UI-test, and 3 Xcode
project paths. The literal manifests in the two detailed inventories now contain
all 254, including `drinkpulse/UITestSeed.swift` and
`drinkpulse/UITestSeed+Fixtures.swift`; their launch-only in-memory container,
fixture insertion, and `@MainActor` seed behavior were reviewed as NC-UI-01.
Active build/test documentation is separately reconciled in 08-DOC-AUDIT.md.

## Area and no-candidate index

Every reviewed area has an explicit no-candidate record even when a related
candidate exists. “No-candidate” means no additional evidence-backed
modernization candidate; it never means the area was not reviewed.

| Coverage area | Detailed evidence | Explicit no-candidate rows | Result |
| --- | --- | --- | --- |
| App entry/startup, AddDrink, Dashboard, History, Insights, Onboarding, Settings, Shell, design system, diagnostics, and UI resources | UI production/resource census | NC-UI-01…11 | 90 production/resource Swift paths plus 16 resources reviewed; candidates and retained workarounds are listed below. |
| UI-test AddDrink, Dashboard, History, Insights, Onboarding, Settings, Shell | UI-test census | NC-TEST-01…07 | 39 UI-test paths reviewed; the full baseline did not compile, so execution status is unavailable. |
| Domain models/calculations, data transfer, persistence, frozen schemas, and corresponding unit tests | Data domain census | N-D01…06 | 61 domain/data/persistence/test paths reviewed; schemas, data formats, identities, and calculations are retained. |
| Notification and HealthKit services, service/feature/diagnostic/performance tests, concurrency, and Xcode tooling | Data service/tooling census | N-S01…06 | 47 service/test/tooling paths reviewed; behavior-sensitive boundaries remain retain-pending-proof. |

### Disposition and destination count

| Disposition | Candidate rows | Destination | Count | Meaning |
| --- | --- | --- | --- | --- |
| change | C001, C002, C010 | Phase 09 | 2 | C001 is owner-gated; C002 is a targeted compiler-correctness repair. |
| change candidate, deferred for decision | C011 | Phase 11 | 1 | Accessibility-test capability lead; no current test is deprecated. |
| retain | C003, C004, C005, C006, C007, C008, C009, C012, C013, C014, C015, C019, C020, C021 | Phase 09/10/11 verification or none | 14 | Retain preserves an established contract; several rows remain separately owner-gated if a rewrite is proposed. |
| retain pending proof | C016, C017, C018 | Phase 10 | 3 | No external block: an iOS 27 diagnostic or interrupted/parallel-operation reproduction is required before a rewrite. |
| externally-blocked | none | — | 0 | No affirmative external evidence supports this disposition. |
| no-candidate | NC-UI-01…11, NC-TEST-01…07, N-D01…06, N-S01…06 | — | 30 | Explicit reviewed-area records; zero is not omitted coverage. |

## Distinct candidate crosswalk

Each `C` ID is stable, unique, and points to exactly one detailed-inventory row.
All exact current file:line occurrences and official Apple/Swift URLs are in the
linked source row; the source URL was checked there on 2026-09-16 and its stated
availability/deprecation claim is preserved verbatim. A recommendation does not
authorize downstream scope.

| Master ID | Detailed row (one only) | Disposition and proposed destination | Substantial test / brief | Protected behavior or required evidence |
| --- | --- | --- | --- | --- |
| C001 | [UI-C-01](08-INVENTORY-UI.md#candidate-and-retain-register) | change / Phase 09 | **yes**, [brief](08-DECISION-C001.md) | Dismiss-sheet ownership may alter navigation; preserve dismissal behavior and show a warning-free injection shape. |
| C002 | [UI-C-02](08-INVENTORY-UI.md#candidate-and-retain-register) | change / Phase 09 | no (reclassify if visual/AX contract changes) | Repair `DPArcProgress.swift:33` actor-isolation compile error while preserving rendered arc, animation, and label. |
| C003 | [UI-C-03](08-INVENTORY-UI.md#candidate-and-retain-register) | retain / Phase 09 only if measured defect | no | Stable model/enum identity, especially History UUID identity, stays intact. |
| C004 | [UI-C-04](08-INVENTORY-UI.md#candidate-and-retain-register) | retain / Phase 09 | **yes**, [brief](08-DECISION-C002.md) | List/calendar scrolling, grouping, paging, gestures, Dynamic Type, and accessibility need focused iOS 27 reproduction. |
| C005 | [UI-C-05](08-INVENTORY-UI.md#candidate-and-retain-register) | retain / Phase 09 | **yes**, [brief](08-DECISION-C003.md) | Correct-row long press, VoiceOver actions, and destructive confirmation need focused iOS 27 evidence. |
| C006 | [UI-C-06](08-INVENTORY-UI.md#candidate-and-retain-register) | retain / Phase 09 or 11 only if evidence requires | **yes**, [brief](08-DECISION-C004.md) | Audio Graph/VoiceOver descriptors and chart selection need an observed defect before substitution. |
| C007 | [UI-C-07](08-INVENTORY-UI.md#candidate-and-retain-register) | retain / none | no | Existing `@Observable @MainActor` owners and `@State` ownership are already current. |
| C008 | [UI-C-08](08-INVENTORY-UI.md#candidate-and-retain-register) | retain / Phase 11 verification | **yes**, [brief](08-DECISION-C005.md) | Reduce Motion behavior stays explicit; simulator/human accessibility verification is still due. |
| C009 | [UI-C-09](08-INVENTORY-UI.md#candidate-and-retain-register) | retain / Phase 09 only if documented defect | **yes**, [brief](08-DECISION-C006.md) | Deliberate Liquid Glass and context-menu interactions need behavior and accessibility evidence. |
| C010 | [UI-C-10](08-INVENTORY-UI.md#ui-test-candidate-and-workaround-evidence) | change candidate / Phase 11 | **yes**, [brief](08-DECISION-C007.md) | `XCUIVoiceOverService` can add coverage, not replace existing semantic UI tests. |
| C011 | [D-01](08-INVENTORY-DATA.md#distinct-candidates-and-retain-decisions--domain-persistence-and-tests) | retain / Phase 10 verification | **yes**, [brief](08-DECISION-C008.md) | Immutable V1–V4 snapshots, UUID/LWW, and migrations require new version/stage if model shape changes. |
| C012 | [D-02](08-INVENTORY-DATA.md#distinct-candidates-and-retain-decisions--domain-persistence-and-tests) | retain / Phase 10 verification | **yes**, [brief](08-DECISION-C009.md) | v2 JSON/import compatibility, UUID/LWW upsert, and profile restore remain contracts. |
| C013 | [D-03](08-INVENTORY-DATA.md#distinct-candidates-and-retain-decisions--domain-persistence-and-tests) | retain / none | no | Current `defer` is synchronous fixture cleanup; async cleanup/shielding has no demonstrated need. |
| C014 | [D-04](08-INVENTORY-DATA.md#distinct-candidates-and-retain-decisions--domain-persistence-and-tests) | retain / none | no | Swift Testing/XCTest mix and `measure` have no observed interoperability problem. |
| C015 | [D-05](08-INVENTORY-DATA.md#distinct-candidates-and-retain-decisions--domain-persistence-and-tests) | retain / none | no candidate proposal | Calculations, identity, and stored values are not changed without separate evidence and a future D-09 gate. |
| C016 | [S-01](08-INVENTORY-DATA.md#distinct-candidates-and-retain-decisions--services-concurrency-remaining-tests-and-tooling) | retain pending proof / Phase 10 | **yes**, [brief](08-DECISION-C010.md) | Authorization, request cancellation, and cold/warm routing must survive any isolation rewrite. |
| C017 | [S-02](08-INVENTORY-DATA.md#distinct-candidates-and-retain-decisions--services-concurrency-remaining-tests-and-tooling) | retain pending proof / Phase 10 | **yes**, [brief](08-DECISION-C011.md) | Opt-in/non-blocking Health behavior, `dp_event_uuid` dedup, device-local cache, and delete ordering remain fixed. |
| C018 | [S-03](08-INVENTORY-DATA.md#distinct-candidates-and-retain-decisions--services-concurrency-remaining-tests-and-tooling) | retain pending proof / Phase 10 | **yes**, [brief](08-DECISION-C012.md) | No task lifetime/cancellation loss is reproduced; shields must not extend work after user intent. |
| C019 | [S-04](08-INVENTORY-DATA.md#distinct-candidates-and-retain-decisions--services-concurrency-remaining-tests-and-tooling) | retain / none | no | Existing focused tests and test doubles are not deprecated. |
| C020 | [S-05](08-INVENTORY-DATA.md#distinct-candidates-and-retain-decisions--services-concurrency-remaining-tests-and-tooling) | retain / Phase 11 verification | no | Settings are already iOS 27 / Swift 6.0; scheme testables remain enabled. |
| C021 | [S-06](08-INVENTORY-DATA.md#distinct-candidates-and-retain-decisions--services-concurrency-remaining-tests-and-tooling) | retain / Phase 09 | no | The sole app-owned compiler diagnostic is crosswalked below; no services/tooling diagnostic exists. |

## Baseline diagnostic and test-result crosswalk

| Invocation / finding | Class and source location | Evidence | Disposition | Remediation |
| --- | --- | --- | --- | --- |
| Debug build, exit 65 | app-owned compiler error — `drinkpulse/DesignSystem/DPArcProgress.swift:33` | [08-BASELINE.md](08-BASELINE.md#diagnostics-and-remediation), `debug-build.{stdout,stderr}.log` hash in 08-BASELINE.json | failed; C002 change | Phase 09 targeted compile repair; then Phase 11 recaptures Debug evidence. |
| Release build, exit 65 | same app-owned compiler error at `DPArcProgress.swift:33` | 08-BASELINE.md, `release-build.{stdout,stderr}.log` hash | failed; C002 change | Phase 09 repair; then Phase 11 recaptures Release evidence. |
| Full unfiltered test, exit 65 | app target failed before `drinkpulseTests` or `drinkpulseUITests` began | 08-BASELINE.md, `full-test.{stdout,stderr}.log` hash | unavailable test totals/passes/failures/skips; no false green result | Phase 09 unblocks compilation; Phase 11 runs focused then full suite. |
| `@Entry` closure warning | app-owned warning — `drinkpulse/Features/AddDrink/AddDrinkView.swift:5` | 08-BASELINE.md; C001 / UI-C-01 | warning retained pending owner-gated recommendation | Phase 09 only if owner later approves a bounded behavior-preserving ownership change. |
| Dependency resolution, exit 0 | tooling/dependency state; no package sources resolved | 08-BASELINE.md and 08-BASELINE.json | passed | no change; maintain the documented Xcode 27 baseline. |

No raw log, Health value, signing value, or `xcresulttool` output is copied into
this committed index. Raw streams and result bundles remain outside Git at the
baseline manifest's hashed paths. There are no test skips to classify: tests did
not begin.

## Swift 6.4 and iOS 27 coverage

| Surface | Source-backed result | Disposition |
| --- | --- | --- |
| Language mode and compiler | Xcode 27 bundles Swift 6.4; all app/test Debug and Release configurations retain `SWIFT_VERSION = 6.0`. [Swift concurrency migration guidance](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/enabledataracesafety/) distinguishes language mode from compiler release. | retain settings; C020 verifies. |
| Standard library / async cleanup | [Swift 6.4 release notes](https://www.swift.org/blog/swift-6.4-released/) describe async `defer` and cancellation shields; reviewed call sites only need synchronous cleanup and have no cancellation-loss reproduction. | C013/C018 retain pending proof. |
| Concurrency | Swift data-race guidance supports reviewing actor/sendability boundaries, but does not itself justify moving notification or HealthKit isolation. | C016/C017 retain pending proof. |
| Observation | Current feature models already use `@Observable @MainActor`, owners use `@State`, and cache-only state uses `@ObservationIgnored`; [Observation `Observable`](https://developer.apple.com/documentation/observation/observable()) is iOS 17+. | C007 retain. |
| Testing | Swift 6.4 interop does not replace the current Swift Testing/XCTest split; Xcode 27 exposes `XCUIVoiceOverService` only as a capability lead. | C014 retain; C010 decision-gated additive evaluation. |

## Flagged assumptions and stale discovery boundary

| ID | Status | Protected behavior / required follow-up |
| --- | --- | --- |
| A01 — PLAT-01 adjacency | resolved | The effective-settings matrix records `27.0` per target/config, not a loose `27` comparison. |
| A02 — PLAT-01 empty value | resolved | Six target/configuration pairs are explicit; missing/null values would be noncompliant, not counted. |
| A03 — PLAT-01 ordering | resolved | Matrix labels target and configuration, supporting comparison across captures. |
| A04 — MOD-01 grouped occurrences | resolved | Detailed rows group only while retaining every listed repository-relative file:line; this master maps each source row once. |
| A05 — MOD-01 no-candidate | resolved | Thirty explicit no-candidate rows preserve every reviewed area. |
| A06 — MOD-01 ordering | resolved | C001…C021 and the detailed UI-C/D/S IDs are stable, ordered crosswalks. |
| A07 — MOD-01 concurrency | **unresolved** | Do not modernize lifecycle/sendability until interrupted or parallel service/test operations have observed guarantees. |
| A08 — PLAT-02 unclassified environment edge | **unresolved** | No undocumented dependency/toolchain edge is observed; if one affects reproducibility, record it before claiming the baseline reproducible. |
| A09 — MOD-05 independent decision outcomes | **unresolved until Wave 4** | Related discussions still require a separately recorded outcome, exact scope, and reason for every brief. |

[`.planning/intel/API-SURFACE.md`](../../intel/API-SURFACE.md) contains zero
symbols because its regex/JS extraction is incomplete. It is a stale discovery
hint only; it is neither evidence of absence nor a source for this inventory.

## Decision-gate rule

The twelve substantial rows above have a source-backed brief and a **pending**
owner-outcome register row. No brief, recommendation, or pending row makes any
substantial replacement eligible for a Phase 09 or Phase 10 execution plan.
If a later discovery could alter user behavior, accessibility, persisted data,
startup/lifecycle, or system-integration semantics, create its own brief and
obtain an independent owner outcome before planning only that rewrite; unrelated
approved work may continue.
