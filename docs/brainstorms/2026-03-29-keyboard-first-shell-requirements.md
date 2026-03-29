---
date: 2026-03-29
topic: keyboard-first-shell
---

# Keyboard-First Shell Control

## Problem Frame

Leaf already exposes some shortcuts, but keyboard behavior is fragmented and not reliably discoverable. The app should feel usable without reaching for the mouse for core shell actions: showing or hiding the sidebar, moving between open files in the sidebar, opening the theme switcher, and changing text size. The shortcut system should also feel native on macOS by surfacing those commands in the menu bar.

## Requirements

**Keyboard Control**
- R1. When Leaf is the active app, pressing `Tab` toggles the sidebar open or closed.
- R2. When the sidebar is open and focused, pressing `Up Arrow` or `Down Arrow` moves the active document selection to the previous or next item in the sidebar.
- R3. Sidebar arrow-key navigation must update both the selected sidebar row and the reader pane so the newly selected document opens immediately.
- R4. `Shift+Tab` opens the theme switcher and, while the theme switcher is open, `Tab` cycles themes as it does today.
- R5. Pressing `Command` `+` increases text size and pressing `Command` `-` decreases text size using the existing reader zoom/text-scale behavior.
- R6. Keyboard controls must be mode-aware so shortcuts do not conflict with text selection, theme switcher behavior, or unrelated focused controls.

**Focus and Interaction Model**
- R7. The sidebar must have a clear focused state for keyboard navigation, entered by interacting with the sidebar and exited by interacting with the reader or another control.
- R8. Sidebar keyboard navigation must not reintroduce the native macOS list-selection highlight that conflicts with Leaf’s custom themed sidebar styling.
- R9. If the sidebar is hidden, `Up Arrow` and `Down Arrow` should not change the active document.
- R10. If there is no document open, sidebar navigation keys should do nothing gracefully.

**Menu Discoverability**
- R11. Leaf must expose the new keyboard actions as native menu commands so users can discover shortcuts from the macOS menu bar.
- R12. `Show Sidebar` / `Hide Sidebar`, `Increase Text Size`, `Decrease Text Size`, and `Themes…` must appear in the `View` menu.
- R13. The menu items must display their keyboard shortcuts using native macOS shortcut presentation.
- R14. Menu commands and keyboard shortcuts must invoke the same underlying app actions so behavior stays consistent regardless of how the action is triggered.

## Success Criteria
- A user can control the core shell without the mouse for sidebar visibility, sidebar document switching, theme switching, and text size.
- The `View` menu accurately advertises the supported shortcuts.
- Keyboard behavior feels consistent across empty state, open-document state, and theme-switcher state.
- The solution does not reintroduce unwanted native sidebar highlight styling.

## Scope Boundaries
- No new editor behavior, command palette, or global shortcut customization.
- No broad accessibility overhaul beyond the keyboard behavior directly required here.
- No expansion into many additional shortcuts beyond the requested shell controls.

## Key Decisions
- `View` menu is the home for keyboard-discoverable shell actions: this matches native macOS expectations better than overloading the `Leaf` app menu.
- The app should stay keyboard-first for shell control, not keyboard-everything: focus is limited to the most important reader-shell actions.
- Sidebar navigation remains Leaf-owned visually: keyboard support should not require reverting to native selection styling.

## Dependencies / Assumptions
- The existing theme switcher behavior for `Shift+Tab` and `Tab` remains the intended baseline.
- Text size shortcuts should reuse the current zoom/text-scale behavior rather than introduce a second sizing system.

## Outstanding Questions

### Deferred to Planning
- [Affects R1][Technical] What is the cleanest way to own sidebar visibility state in the split view without adding more orchestration to `ContentView.swift`?
- [Affects R6][Technical] Should app-level keyboard handling live in a dedicated coordinator or command layer instead of additional local monitors?
- [Affects R11][Technical] What is the cleanest way to share actions between SwiftUI toolbar controls, menu commands, and keyboard handlers?

## Next Steps
→ /prompts:ce-plan for structured implementation planning
