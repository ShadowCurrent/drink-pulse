# Phase 4: Branded Static Launch Screen - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-28
**Phase:** 4-Branded Static Launch Screen
**Areas discussed:** Background color, Icon artwork/treatment, Light/Dark adaptation

---

## Background color

| Option | Description | Selected |
|--------|-------------|----------|
| Match systemBackground | White/black, adapts light-dark automatically. Zero-diff match to `.loading` state in `drinkpulseApp.swift:75` — guarantees no flash (criterion #3) with no extra changes. | ✓ |
| Brand coral (AccentColor) | Bolder brand presence. Requires also changing `.loading`'s `Color(.systemBackground)` to coral so the two frames still match — small extra scope. | |
| You decide | Claude picks based on HIG + least-diff principle. | |

**User's choice:** Match systemBackground (Recommended)
**Notes:** No follow-up questions requested — moved straight to next area.

---

## Icon artwork/treatment

| Option | Description | Selected |
|--------|-------------|----------|
| Full flattened icon | Export/flatten the complete AppIcon.icon composition (drop + pulse) as a static image — matches Home Screen icon exactly, most recognizable. | ✓ |
| Drop mark only | Simpler single-layer mark, more minimal/HIG-style splash look, but diverges visually from the real Home Screen icon. | |
| You decide | Claude picks based on HIG guidance and asset availability during planning/research. | |

**User's choice:** Full flattened icon (Recommended)

Follow-up question — icon size/placement:

| Option | Description | Selected |
|--------|-------------|----------|
| Centered, Home Screen-icon-sized | Matches Apple HIG default for launch screens — icon appears same size/position as it would on the Home Screen, not full-bleed. | ✓ |
| Larger, more prominent | Bigger centered icon for stronger brand presence — diverges slightly from typical HIG scale. | |
| You decide | Claude follows HIG default during implementation. | |

**User's choice:** Centered, Home Screen-icon-sized (Recommended)
**Notes:** None further — moved to next area.

---

## Light/Dark adaptation

| Option | Description | Selected |
|--------|-------------|----------|
| One fixed icon, adaptive bg only | AppIcon.icon's own colors (coral/pulse) already read fine on both white and black — same as Home Screen icon behavior. Only the background swaps light/dark via systemBackground. | |
| Separate light/dark icon variants | Icon Composer supports light/dark/tinted renditions — use distinct icon appearance per mode. More work, matches full platform convention. | ✓ |
| You decide | Claude picks based on how the icon actually renders in both modes during implementation. | |

**User's choice:** Separate light/dark icon variants

Follow-up finding: `icon.json` has no explicit dark-mode override defined — only Xcode's Icon-Composer auto-derived dark rendition exists (no custom artwork sitting ready to export).

| Option | Description | Selected |
|--------|-------------|----------|
| Use Xcode's auto-derived dark rendition | Zero new artwork — export/use whatever Icon Composer already auto-generates for dark mode. Consistent with how the Home Screen icon itself behaves in dark mode. | ✓ |
| Design new dark-mode artwork | Out of scope for this phase — new artwork is a design task, not implementation. Would need to be deferred or handled separately. | |

**User's choice:** Use Xcode's auto-derived dark rendition (Recommended)
**Notes:** Resolves the apparent tension between wanting distinct light/dark variants and having no new artwork budget — auto-derived rendition satisfies both.

---

## Claude's Discretion

- Exact build-setting mechanism (`INFOPLIST_KEY_UILaunchScreen_*` vs. standalone `Info.plist`)
- Exact image-asset export mechanics for flattening the Icon Composer `.icon` bundle

## Deferred Ideas

None raised during discussion.
