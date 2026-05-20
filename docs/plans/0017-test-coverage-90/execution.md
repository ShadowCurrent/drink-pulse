# 0017 — Execution Log

Append-only. Never edit or delete previous entries.

---

## 2026-05-20 — Plan frozen, execution started

### Done
- Plan approved by user, status set to in-progress.
- Open question resolved: use inline literal `1.0` for the SB-2 clamp
  (simpler; a named constant adds ceremony without clarity gain here).

### Deviations from plan
- None yet.

### Discoveries
- `xcodebuild` requires `CODE_SIGNING_ALLOWED=NO` on this machine to
  avoid resource-fork codesign failure on the test bundle. All build
  commands in this log include that flag.
