# 0014 — Retrospective

**Completed**: 2026-05-30

## What went well

- Implementation fit in a single pass with no surprises. The plan's scope was well-defined.
- `notes: String?` was already in the schema — one less field to migrate.
- `fileSystemSynchronizedGroups` in the main target meant the two new component files were picked up automatically — only the test file needed pbxproj registration.
- `displayName` is a clean extension property: no logic in views, fully testable, transparent fallback.
- All 6 `displayName` tests pass; no regressions in the 220 existing tests.

## What went wrong / surprises

- **`notes` already in schema**: the plan described adding `notes: String?` as a new field, but it was already there (from an earlier session). Only `customName` was genuinely new. The migration scope was smaller than planned.
- **`EditCategorySection` not extracted**: the plan listed it as a subview to create. The existing inline picker in `EditEventView` was already compact; extracting it would not have reduced line count. Skipped as unnecessary.
- **Migration smoke test skipped**: the plan's test requirements included a migration smoke test. In-memory SwiftData containers don't exercise real migrations, so the test would be vacuous. Documented in execution.md as a known gap.

## Decisions made during execution

- `customName` NOT reset on category change — it's a persistent user label, independent of the category snapshot `name`.
- Placeholder for custom name field = category default name (Q1: option A — leave empty + placeholder).
- Notes capped at 500 chars; counter appears at 400+ (Q3: option A).
- Note indicator in history row = `note.text` icon only, no text preview (Q4: option A).
- Notes whitespace-trimmed before save; empty string stored as `nil` (same pattern as other optional string fields).

## Leftover open questions

None. All open questions resolved.
