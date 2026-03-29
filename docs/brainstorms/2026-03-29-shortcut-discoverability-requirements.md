---
date: 2026-03-29
topic: shortcut-discoverability
---

# Shortcut Discoverability

## Problem Frame

Leaf now has a small but meaningful keyboard model for shell actions, but discoverability is still weak. The native macOS menu bar exposes shortcuts, yet that alone is easy to miss, and the current in-app surfaces do not help users learn the most important commands. The goal is to make shortcuts visible in a way that feels native and calm, not like a power-user utility layered onto a reading app.

## Requirements

**Empty-State Primer**
- R1. The empty state must include a compact keyboard primer below the primary orientation content.
- R2. The primer must show only the essential shell shortcuts, not a full command catalog.
- R3. The initial shortcut set must cover:
  - `Tab` for sidebar
  - `Shift+Tab` for themes
  - `⌘+` for larger text
  - `⌘-` for smaller text
- R4. Each shortcut in the primer must render as a styled keycap treatment paired with a short label.
- R5. The primer must feel like part of the empty-state design system, using the same visual language as the current shell rather than introducing a heavy “tips” panel.
- R6. The primer must stay compact enough that it does not compete with the main empty-state headline, CTA, and preview card.

**Shortcuts Sheet**
- R7. Leaf must provide an optional in-app keyboard shortcuts sheet that lists the currently supported shortcuts in one place.
- R8. The shortcuts sheet must be reachable from `View > Keyboard Shortcuts…`.
- R9. The sheet must group shortcuts into clear sections such as `Navigation`, `Themes`, and `Reading`.
- R10. The sheet should use the same keycap visual treatment as the empty-state primer so both surfaces feel related.
- R11. The sheet must present current supported shortcuts only; it must not advertise speculative or future shortcuts.
- R12. The sheet must be lightweight and calm, closer to a compact reference card than a complex settings screen.

**Interaction and Discoverability**
- R13. The empty-state primer and shortcuts sheet must complement the native macOS menu shortcuts rather than replace them.
- R14. The `View` menu command for `Keyboard Shortcuts…` must feel like a natural extension of the existing menu-discoverable keyboard controls.
- R15. If the app grows more shortcuts later, the sheet may expand, but the empty-state primer should remain limited to the highest-value 3-4 items.

## Success Criteria
- A new user can discover the core keyboard model without needing to hunt through menus.
- Shortcut education feels native to macOS and visually consistent with Leaf’s calm-reader shell.
- The empty state teaches only the most important commands and remains visually balanced.
- The shortcuts sheet provides a complete reference for supported commands without feeling like a power-user tool.

## Scope Boundaries
- No command palette.
- No onboarding wizard or one-time tutorial flow.
- No always-visible persistent shortcut bar in the main reading surface.
- No shortcut customization or rebinding.

## Key Decisions
- `View > Keyboard Shortcuts…` is the trigger for the optional sheet: this matches the existing location of keyboard-related shell commands better than overloading `Help`.
- The empty state should teach only the essential commands: Leaf should signal keyboard friendliness without turning the start screen into a cheat sheet.
- Keycaps should be rendered as designed UI elements, not plain inline text, so the shortcuts feel intentional and legible at a glance.

## Dependencies / Assumptions
- The current command set in the app menu remains the source of truth for supported keyboard actions.
- The existing empty-state layout has enough visual room to absorb a compact shortcut primer without a broader redesign.

## Outstanding Questions

### Deferred to Planning
- [Affects R4][Design] What exact keycap component and spacing rules should be shared between the empty-state primer and the shortcuts sheet?
- [Affects R8][Technical] Should the `Keyboard Shortcuts…` sheet be implemented as a standard SwiftUI sheet, a popover, or a lightweight overlay attached to the main window?
- [Affects R13][Technical] What is the cleanest way to derive the displayed shortcuts from the command source of truth without duplicating strings and key definitions?

## Next Steps
→ /prompts:ce-plan for structured implementation planning
