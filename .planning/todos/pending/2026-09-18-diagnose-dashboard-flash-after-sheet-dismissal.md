---
created: 2026-09-18T19:19:46.809Z
title: Diagnose Dashboard flash after sheet dismissal
area: general
severity: major
files:
  - drinkpulse/Features/Shell/RootShellView.swift
  - drinkpulse/Features/Dashboard/DashboardView.swift
  - drinkpulse/DesignSystem/DPGlass.swift
---

## Problem

On an iPhone 15 Pro Max running iOS 27, Dashboard visibly flashes after every
cycle of opening Add Drink, dismissing it, and switching to another tab. The
same navigation flow completes correctly on the iOS 27 simulator, but Xcode
MCP's first static screenshot is available only after the approximately
one-second artifact has elapsed, so it cannot prove the rendering cause.

The issue persists after Dashboard cards were placed in
`GlassEffectContainer(spacing: 0)`. The user explicitly deferred further work
on this problem to keep the iOS 27 modernization milestone focused.

## Solution

Diagnose this as a dedicated real-device rendering/presentation issue before
making another source change. Capture the transition on the affected device,
then correlate it with sheet dismissal, `TabView` selection, Dashboard view
invalidations, and Liquid Glass composition. Consult Apple documentation and
Xcode MCP first; retain the current navigation and accessibility behavior until
a reproducible cause supports a narrow fix.
