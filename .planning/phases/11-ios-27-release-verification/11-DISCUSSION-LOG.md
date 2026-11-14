# Phase 11: iOS 27 Release Verification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-14
**Phase:** 11-ios-27-release-verification
**Areas discussed:** Readiness, Regression scope, Accessibility checks, Flow proof

---

## Readiness

| Option | Description | Selected |
|--------|-------------|----------|
| Proceed, re-verify inside 11 | Phase 11's plan re-runs the verifier for 08, 09 and 10 first. Phase 11 then inherits any new gaps found. | |
| Stop, re-verify 09 first | Halt this run, re-verify 09 (and 08/10) separately, then re-launch Phase 11. | |
| Proceed, ignore prior status | Treat 08–10 as done per their closure plans and reconcile their debt in the ledger. | ✓ |

**User's choice:** Proceed, ignore prior status

---

## Regression scope

| Option | Description | Selected |
|--------|-------------|----------|
| Record as open limitations | No fixes. Each failure is listed with its cause, todo and owner. | ✓ |
| Fix History + Insights tests | Fix the 3 deterministic failures and analyze the flake. | |
| Fix all incl. flake | Also find the root cause of the Export dismiss flake. | |

**User's choice:** Record as open limitations

---

## Accessibility checks

| Option | Description | Selected |
|--------|-------------|----------|
| Owner on iPhone | Guided device checklist. | |
| Owner on simulator | Checklist on the iOS 27 simulator. | ✓ |
| Automated only, rest open | XCUITest and audits only. Human items stay open. | |

**User's choice:** Owner on simulator

---

## Flow proof

| Option | Description | Selected |
|--------|-------------|----------|
| Automated + reuse Phase 10 | UI tests, plus the Phase 10 device session as the data-preservation proof. | ✓ |
| New device pass on final build | Install over the existing app and walk through all flows. | |

**User's choice:** Automated + reuse Phase 10

---

## Decided autonomously

[auto] [Warnings] — Q: "How to find deprecation warnings (MOD-04)?" → Selected: "Clean Debug and Release builds, extract warnings, classify them, fix app-owned warnings at the source, and send behavior changes through the D-09 brief" (reversible technical — decided autonomously: evidence method only)
[auto] [Evidence] — Q: "Where does the evidence go?" → Selected: "One 11-EVIDENCE.md, with raw logs kept outside git" (reversible technical — decided autonomously: document layout only)
[auto] [Tooling] — Q: "How are builds and tests run?" → Selected: "Xcode MCP first, with CLI only for the known MCP timeout on long UI suites" (reversible technical — decided autonomously: runner choice)
[auto] [Phase 05 debt] — Q: "How are the 3 skipped Phase 05 checks handled?" → Selected: "Fold them into the VER-03 human checklist, linked to 05-UAT tests 4–6" (reversible technical — decided autonomously: checklist mapping)
[auto] [Debt ledger] — Q: "How is the do-not-silently-close-debt criterion met?" → Selected: "A ledger table of all open debt with status and owner" (reversible technical — decided autonomously: record only)
[auto] [Discoveries] — Q: "How is SC5 checked?" → Selected: "Cross-check C001–C013 and F2–F4 against their decision records" (reversible technical — decided autonomously: read-only audit)

## Claude's Discretion

None.

## Deferred Ideas

- Re-verify Phases 08–10 (refresh the stale 09-VERIFICATION.md).
- Fix the known red or flaky UI tests and D1.
- A fresh device pass and device-level accessibility checks.
