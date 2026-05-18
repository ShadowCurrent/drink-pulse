# Retrospective — Plan 0006

**Completed**: 2026-05-18

## What went well

- Smallest possible plan: mostly deletion + config change. Nothing complex.
- SwiftData handled `appLockEnabled` removal transparently — no migration code needed.
- `Tab {}` syntax is noticeably cleaner; glad we finally restored it.
- Deep link row in Settings is a better UX than the old toggle for a system-managed feature.

## Decisions made during execution

- No deviations from the frozen plan.

## Notes

- `settings.section.privacy` key kept in xcstrings — still used as section header
  for the deep link row.
- `UIKit` import added to SettingsView.swift for `UIApplication.openSettingsURLString`.
