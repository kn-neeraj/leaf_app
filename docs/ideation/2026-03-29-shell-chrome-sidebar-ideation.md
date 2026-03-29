---
date: 2026-03-29
topic: shell-chrome-sidebar
focus: sidebar chrome alignment and theme-owned selection styling
---

# Ideation: Shell Chrome and Sidebar Alignment

## Codebase Context

- Leaf is a read-only macOS SwiftUI Markdown reader with a `NavigationSplitView` shell and minimal chrome.
- The current toolbar is attached at the split-view level in [Leaf/Leaf/ContentView.swift](/Users/kn_neeraj/Documents/ai-projects/leaf_project/Leaf/Leaf/ContentView.swift), but the sidebar has no matching top chrome, so the window reads as if the toolbar belongs only to the detail pane.
- Sidebar selection currently relies on `List(selection:)` with only light row styling, so theme-inappropriate AppKit/SwiftUI selection visuals can leak through.
- `LeafTheme.Colors` currently exposes reader-oriented tokens (`background`, `text`, `secondary`, `accent`, `codeBackground`, `quoteBorder`) but not shell/chrome-specific colors, which limits consistent theming of toolbar groups, sidebar surfaces, and selected rows.
- Existing docs and code emphasize minimal chrome, typography-first reading, and avoiding unnecessary complexity in `ContentView.swift`.

## Ranked Ideas

### 1. Add a semantic chrome layer to `LeafTheme`
**Description:** Extend the theme model with shell-specific tokens for toolbar surfaces, sidebar surfaces, and selected row treatment instead of overloading `accent` and `quoteBorder`.
**Rationale:** This addresses the root cause of inconsistent shell visuals and gives the app a stable styling vocabulary for future polish.
**Downsides:** Requires touching multiple themes and updating several views at once.
**Confidence:** 96%
**Complexity:** Medium
**Status:** Explored

### 2. Add a sidebar top rail that visually continues the toolbar
**Description:** Introduce a shallow top band for the sidebar that aligns with the titlebar/toolbar height and uses the same surface and divider language as the toolbar chrome.
**Rationale:** This directly fixes the "toolbar not coming into sidebar" perception without making Leaf feel like a heavier file-management app.
**Downsides:** Needs careful restraint to avoid adding unnecessary controls or making the shell too busy.
**Confidence:** 93%
**Complexity:** Medium
**Status:** Explored

### 3. Use Leaf-owned selected-row styling while keeping `List`
**Description:** Keep the native sidebar list, but make each row visually own its selected state with theme-driven fill, stroke, and text treatment layered over the list behavior.
**Rationale:** This removes theme-breaking pink/default selection and keeps the code cost much lower than replacing the sidebar container entirely.
**Downsides:** Some native list behavior still remains under the surface, so the implementation must be tested across themes.
**Confidence:** 95%
**Complexity:** Medium
**Status:** Explored

### 4. Remove global root tint and scope accent usage explicitly
**Description:** Stop applying a root-level `.tint(colors.accent)` and instead apply accent only where Leaf deliberately wants it.
**Rationale:** This reduces unintended system tint bleed into selection and shell controls.
**Downsides:** A few controls may need local restyling to preserve the intended accent.
**Confidence:** 88%
**Complexity:** Low
**Status:** Explored

### 5. Slightly separate sidebar and reader surfaces
**Description:** Keep both surfaces theme-matched, but introduce a subtle difference in depth or tone so the split feels intentional rather than flat.
**Rationale:** This improves information hierarchy and supports the unified top chrome.
**Downsides:** Too much separation would fight the calm-reader identity.
**Confidence:** 84%
**Complexity:** Low
**Status:** Unexplored

## Rejection Summary

| # | Idea | Reason Rejected |
|---|------|-----------------|
| 1 | Only recolor the current selection highlight | Too shallow; does not solve the sidebar/toolbar mismatch |
| 2 | Add more mascot/branding in the sidebar | Solves the wrong problem; this is a shell semantics issue |
| 3 | Rebuild the sidebar as a fully custom container | Too expensive relative to the value of the current UI issue |
| 4 | Expand the sidebar into richer file-management UI | Outside Leaf's current scope and product intent |

## Session Log
- 2026-03-29: Initial ideation - 9 candidates considered, 5 survivors retained
- 2026-03-29: Idea 1, 2, 3, and 4 selected as the handoff set for brainstorming
