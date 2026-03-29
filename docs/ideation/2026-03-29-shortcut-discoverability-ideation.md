---
date: 2026-03-29
topic: shortcut-discoverability
focus: show keyboard shortcuts to users in a nice, design-conscious way
---

# Ideation: Shortcut Discoverability

## Codebase Context

Leaf is a native macOS SwiftUI Markdown reader with a calm-reader visual direction and a strong bias against noisy chrome. The current shell already exposes keyboard actions through native menu commands in `Leaf/Leaf/LeafCommands.swift`, while the visible app chrome in `Leaf/Leaf/ReaderChromeViews.swift` stays intentionally restrained. Empty-state and toolbar copy live in `Leaf/Leaf/UICopy.swift`, which makes it feasible to evolve shortcut language without scattering strings.

Relevant constraints and signals:
- Shortcut discoverability exists today mainly through the macOS `View` menu.
- The toolbar uses compact grouped controls and should not become visibly busier.
- The empty state is now the strongest designed surface for orientation and first-use guidance.
- `ContentView.swift` is already carrying too much interaction logic, so any shortcut UX that depends on more orchestration should be treated skeptically.
- There are no directly relevant past learnings in `docs/solutions/`; the existing solution docs are about unrelated UI bugs.

## Ranked Ideas

### 1. Empty-State Shortcut Primer
**Description:** Add a compact row or card of 3-4 keyboard shortcut chips directly under the empty-state primary action, using macOS-style keycaps such as `Tab`, `Shift+Tab`, and `⌘+ / ⌘-`.
**Rationale:** This is the cleanest design fit. It teaches the keyboard model exactly when users are still orienting themselves, without permanently adding chrome to the reading experience.
**Downsides:** Helps first-run and empty-state discovery more than ongoing rediscovery once a document is open.
**Confidence:** 96%
**Complexity:** Low
**Status:** Unexplored

### 2. Quiet “Keyboard” Sheet from Help/View
**Description:** Add a small, well-designed shortcuts sheet or panel reachable from the menu, showing the current supported shortcuts in grouped sections like Navigation, Themes, and Reading.
**Rationale:** The menu already advertises individual shortcuts, but a dedicated sheet gives users a single place to learn the whole model. It also fits native expectations better than building a custom onboarding flow.
**Downsides:** Slightly more implementation and copy work; low usage if not gently surfaced somewhere.
**Confidence:** 93%
**Complexity:** Medium
**Status:** Unexplored

### 3. Contextual Shortcut Hints in the Empty Reader Shell
**Description:** When no document is open, show a subtle “Try Tab for sidebar, Shift+Tab for themes” line near the hero or helper copy, with one or two rendered keycaps rather than a full cheat sheet.
**Rationale:** This is the lightest-weight version of shortcut education and aligns well with Leaf’s editorial voice. It keeps the UI calm while still signaling that the app is keyboard-friendly.
**Downsides:** Too little information if you want full discoverability; may feel redundant once the menu items exist.
**Confidence:** 90%
**Complexity:** Low
**Status:** Unexplored

### 4. Toolbar-Adjacent Shortcut Reveal on Hover or Press
**Description:** Reveal shortcut badges near toolbar controls on hover or via a deliberate reveal gesture, such as holding `Option`, instead of showing them all the time.
**Rationale:** This preserves the clean default shell while rewarding exploration. It also pairs naturally with the existing toolbar groups.
**Downsides:** Discoverability of the discoverability mechanism is weak unless paired with another cue.
**Confidence:** 78%
**Complexity:** Medium
**Status:** Unexplored

### 5. First-Use Shortcut Toast or Nudge
**Description:** Show a one-time transient hint after launch or after the user first opens a document, for example: “Keyboard: Tab toggles sidebar.”
**Rationale:** This can teach the highest-value behavior without adding permanent UI.
**Downsides:** Easy to feel like generic app coaching; ephemeral hints are easy to miss and often hard to repeat.
**Confidence:** 72%
**Complexity:** Low
**Status:** Unexplored

### 6. Embedded Keycaps in Selected Menu-Surface Copy
**Description:** Integrate rendered keycaps into existing helper copy, especially in the empty state and theme switcher, rather than introducing a new surface.
**Rationale:** This keeps the design minimal and uses existing copy surfaces that are already in the app.
**Downsides:** Works best for one or two shortcuts, not for a coherent system.
**Confidence:** 84%
**Complexity:** Low
**Status:** Unexplored

## Rejection Summary

| # | Idea | Reason Rejected |
|---|------|-----------------|
| 1 | Always-visible shortcut badges across the toolbar | Too noisy for Leaf’s calm-reader shell |
| 2 | Full command palette | Too expensive and shifts the product toward a power-user app |
| 3 | Onboarding wizard for shortcuts | Heavy-handed and out of scope for the product |
| 4 | Persistent footer bar listing shortcuts | Duplicates menu discoverability and adds permanent chrome |
| 5 | Tooltip-only shortcut education | Too hidden and too dependent on mouse behavior |
| 6 | Large floating cheat sheet overlay as the primary solution | Overwhelms the lightweight shell for a small command set |

## Session Log
- 2026-03-29: Initial ideation — 12 candidates considered, 6 survivors kept
