---
title: Markdown table cells wrapped incorrectly and looked like horizontal scroll was broken
date: 2026-03-29
category: docs/solutions/ui-bugs/
module: Leaf
problem_type: ui_bug
component: tooling
symptoms:
  - Table cells showed ellipses even after widening columns
  - Horizontal scroll looked broken for markdown tables with long prose
  - Fresh builds still showed clipped table text until the cell renderer changed
root_cause: wrong_api
resolution_type: code_fix
severity: medium
tags: [markdown, tables, swiftui, attributedstring, layout]
---

# Markdown table cells wrapped incorrectly and looked like horizontal scroll was broken

## Problem

Leaf's markdown tables looked broken when cells contained longer prose. The UI appeared to have a horizontal-scroll bug, but the deeper issue was that table cell text was not wrapping under the real column constraint.

## Symptoms

- Cells such as `Inspiration` and `Compared` rendered as `...` even after column width heuristics were improved.
- Wider prose tables still clipped text, which made the horizontal scrollbar seem ineffective.
- Rebuilding the app changed table width, but the inner cell text continued to ellipsize.

## What Didn't Work

- Increasing column widths with rough character-count heuristics. That improved the outer table width but did not fix truncation inside the cell.
- Switching to measured widths alone. The table container changed size, but `Text(AttributedString)` in the cell still behaved like a single-line label.
- Treating the issue as a pure scroll-view problem. The scroll view was not the primary failure point.

## Solution

Keep measured column widths, but change the table cell rendering path in [MarkdownView.swift](/Users/kn_neeraj/Documents/ai-projects/leaf_project/Leaf/Leaf/MarkdownView.swift):

1. Stop rendering table cells with `Text(AttributedString)` for layout-sensitive table content.
2. Convert each table cell to a plain string for rendering.
3. Make the cell container own the width first, then let the text lay out inside that constrained width.
4. Cap long prose columns to a wrap width, while allowing shorter columns to use their natural measured width.

Before:

```swift
Text(text)
    .lineLimit(nil)
    .fixedSize(horizontal: false, vertical: true)
    .frame(width: columnWidths[column], alignment: alignment)
```

After:

```swift
VStack(alignment: horizontalAlignment(for: alignment), spacing: 0) {
    Text(verbatim: text)
        .lineLimit(nil)
        .multilineTextAlignment(textAlignment)
        .frame(maxWidth: .infinity, alignment: alignment)
}
.frame(width: width, alignment: alignment)
```

The final width policy remained:

- short and medium cells use measured natural width
- long prose cells cap to a wrap width
- explicit total table width is used so real wide tables can still scroll horizontally

## Why This Works

The original table cell layout applied the width constraint too late. `Text(AttributedString)` effectively chose its line shape first, and the later frame caused clipping and ellipsis instead of reflow.

By moving the width ownership to the cell container and rendering plain text inside that width, SwiftUI performs layout under the correct constraint. That makes prose columns wrap normally and reserves horizontal scrolling for genuinely wide tables rather than ordinary sentence cells.

## Prevention

- For SwiftUI table-like layouts, apply width constraints at the container level before asking `Text` to lay out.
- Be skeptical when a problem looks like scroll failure; inspect whether inner content is clipping before it ever reaches the scroll boundary.
- Add visual regression fixtures for:
  - short-token tables
  - long prose tables
  - alignment tables
  - numeric tables
- Keep table fixtures in [tables.md](/Users/kn_neeraj/Documents/ai-projects/leaf_project/test_markdown_files/compatibility/tables.md) broad enough to exercise both wrapping and horizontal overflow cases.
- Verify UI rendering fixes with a fresh app build, not only incremental local runs:
  ```sh
  xcodebuild -project Leaf/Leaf.xcodeproj -scheme Leaf -destination 'platform=macOS' -derivedDataPath /tmp/leaf_derived_data build
  open /tmp/leaf_derived_data/Build/Products/Debug/Leaf.app
  ```

## Related Issues

- [tables.md](/Users/kn_neeraj/Documents/ai-projects/leaf_project/test_markdown_files/compatibility/tables.md)
- [MarkdownView.swift](/Users/kn_neeraj/Documents/ai-projects/leaf_project/Leaf/Leaf/MarkdownView.swift)
- [markdown_compatibility_matrix.md](/Users/kn_neeraj/Documents/ai-projects/leaf_project/docs/design-docs/architecture-notes/markdown_compatibility_matrix.md)
