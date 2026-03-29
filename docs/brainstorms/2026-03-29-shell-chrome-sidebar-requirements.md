---
date: 2026-03-29
topic: shell-chrome-sidebar
---

# Shell Chrome and Sidebar Theming

## Problem Frame

Leaf's current shell looks visually split in the wrong way. The toolbar chrome feels attached only to the detail pane, while the sidebar begins as a plain surface with no aligned top band. At the same time, selected sidebar rows do not consistently reflect the active Leaf theme and can inherit system-looking highlight colors that feel off-brand. This weakens the first impression of the app even though the underlying reader is now stronger.

## Requirements

**Theme Semantics**
- R1. Leaf must define shell-specific theme semantics for app chrome rather than styling all shell states from the current generic color tokens alone.
- R2. The shell theme semantics must support at minimum: sidebar surface, toolbar/group surface, chrome border/divider, selected-row fill, and selected-row stroke or equivalent selected outline treatment.
- R3. The new shell semantics must preserve the calm-reader identity across all existing themes and avoid louder contrast than the reading surface requires.

**Sidebar Chrome**
- R4. The sidebar must include a top rail or header band that visually aligns with the toolbar/titlebar region so the app chrome reads as one window-level system rather than detail-only chrome.
- R5. The sidebar top rail must remain minimal and must not introduce file-management features outside current scope.
- R6. The sidebar and detail area must remain visually related, but the split between them should feel intentional through subtle surface and divider treatment.

**Sidebar Selection**
- R7. Selected sidebar rows must use Leaf-owned themed styling rather than visibly default system highlight treatment.
- R8. Selected row styling must adapt per active theme and remain coherent in both light and dark themes, including accent-heavy themes such as rose and crimson variants.
- R9. Unselected sidebar rows must remain quiet and typography-first, with secondary metadata staying legible but subdued.
- R10. The selection treatment must preserve the current interaction model: click to select, context menu to close, and existing open-document behavior.

**Accent Behavior**
- R11. Accent color usage in shell chrome must be deliberate and scoped; selection and control states should not depend on a broad app-wide tint when that causes theme mismatch.
- R12. Toolbar controls, sidebar row states, and theme-switcher affordances should share a coherent active-state language rather than each improvising their own accent treatment.

## Success Criteria

- The window chrome reads as visually continuous across sidebar and detail surfaces.
- The sidebar no longer shows a theme-breaking pink or otherwise system-looking selected state.
- Switching between at least one light theme and one dark theme preserves coherent selection and shell chrome.
- The UI feels more finished without adding new product scope or making Leaf look like a file manager.
- The implementation stays bounded enough that it does not require replacing the entire sidebar stack.

## Scope Boundaries

- No new file-management features such as pinning, grouping, persistence, reorder, or inline rename.
- No redesign of the reader content area beyond changes needed to keep shell surfaces coherent.
- No full replacement of the native sidebar list container unless later work proves the balanced approach cannot meet the visual bar.
- No mascot or branding expansion as part of this pass.

## Key Decisions

- Balanced approach: keep the native `List` and improve visual ownership around it rather than replacing sidebar behavior end to end.
- Fix the shell semantics first: the problem is not only row color, but the lack of a proper chrome vocabulary across toolbar and sidebar.
- Keep the pass polish-focused: this is a visual/system consistency improvement, not a workflow expansion.

## Dependencies / Assumptions

- The existing theme system is the correct place to encode shell color semantics for this pass.
- The current split-view and sidebar behavior are functionally sufficient; only visual ownership and alignment are under discussion.

## Outstanding Questions

### Deferred to Planning
- [Affects R4][Technical] Should the sidebar top rail be a purely visual band, or should it also host the existing sidebar empty-state title treatment when no files are open?
- [Affects R7][Technical] What is the smallest implementation that guarantees Leaf-owned selected styling while still preserving native list accessibility and focus behavior?
- [Affects R11][Technical] Can root `.tint(...)` be removed entirely without creating regressions in file importer, theme switcher, or toolbar buttons?

## Next Steps

-> /prompts:ce-plan for structured implementation planning
