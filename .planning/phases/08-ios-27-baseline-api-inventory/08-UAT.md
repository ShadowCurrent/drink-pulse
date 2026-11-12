---
status: testing
phase: 08-ios-27-baseline-api-inventory
source: [08-VERIFICATION.md]
started: 2026-11-12T16:00:01Z
updated: 2026-11-12T16:00:01Z
---

## Current Test

number: 1
name: Decide the Polish-language prose policy for Phase 08 artifacts (WARNING W1).
expected: |
  Either translate the paraphrased fields to English (08-DECISION-REGISTER.md 'Exact scope' and 'Owner reason' columns for C001-C012; 08-INVENTORY.md handoff 'Approved scope' column, lines 136-147; the owner-response and scope blocks of 08-DECISION-C001..C012.md; the narrative of 08-06-SUMMARY.md) and keep the verbatim owner transcript as quoted source, or record an explicit acceptance of the Polish text under AGENTS.md 'Language: English only'.
awaiting: user response

## Tests

### 1. Decide the Polish-language prose policy for Phase 08 artifacts (WARNING W1).
expected: Either translate the paraphrased fields to English (08-DECISION-REGISTER.md 'Exact scope' and 'Owner reason' columns for C001-C012; 08-INVENTORY.md handoff 'Approved scope' column, lines 136-147; the owner-response and scope blocks of 08-DECISION-C001..C012.md; the narrative of 08-06-SUMMARY.md) and keep the verbatim owner transcript as quoted source, or record an explicit acceptance of the Polish text under AGENTS.md 'Language: English only'.
result: [pending]

### 2. Decide whether AGENTS.md should carry the Xcode 27 / Swift 6.4 toolchain pin (WARNING W2 / Truth 4).
expected: Either add one line to AGENTS.md 'Build & verify' or 'Local iOS 27 simulator destination' stating Xcode 27 (Swift 6.4 compiler, Swift 6 language mode), matching README.md line 119, or accept README.md plus docs/architecture.md as the sole toolchain pin.
result: [pending]

### 3. Confirm the eight judgment-tier prohibitions (P1-P8; non-authoritative LLM-judge verdicts).
expected: Owner reads each verdict and its evidence in 08-VERIFICATION.md and confirms, or opens a gap. Flag: unverified-prohibition - human review recommended.
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
