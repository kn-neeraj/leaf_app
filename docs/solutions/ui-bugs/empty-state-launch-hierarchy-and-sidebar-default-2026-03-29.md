---
title: Empty state launch hierarchy competed with itself and opened with unnecessary sidebar chrome
date: 2026-03-29
category: docs/solutions/ui-bugs/
module: Leaf
problem_type: ui_bug
component: tooling
symptoms:
  - The app launched with the sidebar open even when there were no documents, which split attention across two empty panes
  - The keyboard shortcut primer drew more attention than the reading preview and could fall below the first viewport on shorter windows
  - The preview card body and quote treatment added noise instead of supporting the launch-state message
root_cause: logic_error
resolution_type: code_fix
severity: medium
tags: [empty-state, sidebar, keyboard-shortcuts, swiftui, launch-state]
---

# Empty state launch hierarchy competed with itself and opened with unnecessary sidebar chrome

## Problem

Leaf's launch state stopped feeling like a calm reader and started feeling like several competing onboarding surfaces. The sidebar opened by default with no useful content, the shortcut primer sat too high in the hierarchy, and the empty-state stack grew tall enough that important supporting UI could drop below the fold.

## Symptoms

- Launching Leaf with no files open showed an empty sidebar and an empty reader at the same time.
- The `welcome.md` preview was no longer the primary visual anchor in the home state.
- The keyboard row could be pushed low enough that it was not fully visible without scrolling on shorter window heights.
- The preview card body text and quote block felt busy for a supposedly quiet launch state.

## What Didn't Work

- Treating shortcut discoverability as a feature card. Putting the shortcut primer above the preview made the app explain itself before it showed what it was for.
- Using large, fixed empty-state spacing. The layout looked fine on taller windows but became vertically wasteful on shorter ones.
- Leaving the split view open by default. Even with a nicer empty sidebar, the extra chrome still pulled focus away from the centered reading invitation.
- Keeping the preview quote block. It read more like design commentary than product UI and made the card taller without adding orientation.

## Solution

Keep the launch state centered on one primary reading invitation and demote utility guidance to a secondary role.

In [ContentView.swift](/Users/kn_neeraj/Documents/ai-projects/leaf_project/Leaf/Leaf/ContentView.swift), default the split view to detail-only so the app opens without sidebar chrome:

```swift
@State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
```

In [ReaderChromeViews.swift](/Users/kn_neeraj/Documents/ai-projects/leaf_project/Leaf/Leaf/ReaderChromeViews.swift):

1. Move the `welcome.md` preview above the shortcut primer.
2. Make the empty-state stack adaptive to viewport height with a compact layout path.
3. Narrow the content column so the hero stays visually centered on large windows.
4. Tone the shortcut primer down from a card-like panel into a lighter reference row.
5. Remove the preview quote block and keep the preview body to a clean two-line paragraph.

Representative structure:

```swift
let isCompactLayout = geometry.size.height < 860

VStack(spacing: 0) {
    Spacer(minLength: max(28, geometry.size.height * 0.055))

    VStack(spacing: contentSpacing) {
        LeafMascotMark(...)
        headline
        openButton
        helperText
        EmptyStatePreviewCard(...)
        ShortcutPrimerView(...)
    }
    .frame(maxWidth: 600)

    Spacer(minLength: max(28, geometry.size.height * 0.065))
}
```

And in the preview card:

```swift
Text(UICopy.PreviewCard.body)
    .lineLimit(2)
    .fixedSize(horizontal: false, vertical: true)
    .frame(maxWidth: isCompact ? 392 : 420, alignment: .leading)
```

The copy cleanup lives in [UICopy.swift](/Users/kn_neeraj/Documents/ai-projects/leaf_project/Leaf/Leaf/UICopy.swift), where the preview body was shortened and the quote string was removed:

```swift
static let body = "Markdown should feel like a page, not a parser dump. Leaf softens the chrome and lets the writing lead."
```

## Why This Works

The launch state is fundamentally an information hierarchy problem, not a missing-component problem. By hiding the sidebar until the user asks for it, the app regains a single focal plane. By putting the preview above shortcuts, the home state shows the product before it explains controls. By making the stack height adaptive, the entire composition stays visible on shorter windows instead of assuming generous vertical space.

The copy and preview-card cleanup matter for the same reason: every extra line in the launch state competes with the central promise of “open a Markdown file and read.” Removing the quote and constraining the body to a short paragraph keeps the preview demonstrative without becoming another content block to scan.

## Prevention

- For empty states, order surfaces by product meaning first and utility second: preview/demo content should usually sit above shortcuts and hints.
- In split-view apps, default to `.detailOnly` when the sidebar has no meaningful first-run content.
- Avoid fixed empty-state spacing for macOS windows; use viewport-aware compact rules when the height drops below a threshold.
- Keep launch-state copy product-facing. Remove manifesto-style text unless it directly helps the user orient themselves.
- For UI verification of macOS windows, prefer a targeted window capture over a generic desktop screenshot. This avoids false validation when another registered app bundle is frontmost:

```sh
swift -e 'import Cocoa; import CoreGraphics; let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []; for window in info { let owner = window[kCGWindowOwnerName as String] as? String ?? ""; if owner == "Leaf" { print(window[kCGWindowNumber as String] ?? "?") } }'
screencapture -x -l <window-number> /tmp/leaf-window.png
```

## Related Issues

- Existing overlap in `docs/solutions/` was low. [markdown-table-cell-wrapping-and-scroll-2026-03-29.md](/Users/kn_neeraj/Documents/ai-projects/leaf_project/docs/solutions/ui-bugs/markdown-table-cell-wrapping-and-scroll-2026-03-29.md) is a different rendering problem with different files and prevention rules.
- GitHub issue search was skipped in this pass.
