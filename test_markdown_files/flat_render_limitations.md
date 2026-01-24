# Flat Render Limitations Test

This file is designed to show how the flat renderer differs from rich block
rendering. Use it to compare layout, spacing, and visual structure.

---

## 1) Headings and Spacing

In a rich renderer, headings have clear top/bottom spacing and hierarchy.
In flat mode, headings are just larger text with minimal block separation.

### Subheading: Visual Rhythm

Notice how the spacing between headings and paragraphs feels more uniform.

---

## 2) Blockquotes (Multi-line + Multi-paragraph)

> This is a blockquote that should have a visible border and indentation.
> It also spans multiple lines to show how quote styling looks when wrapped.
>
> This is a second paragraph inside the same quote. In flat mode, only the
> first line has a "> " prefix, so the quote is not visually consistent.

---

## 3) Lists (Wrapping + Nesting)

- A short list item.
- A long list item that should wrap and indent on the next line, but in flat
  mode the wrapped line aligns with the bullet instead of the text.
- A list item with multiple sentences so you can see how the wrap behaves
  across a few lines and how spacing compares to paragraph spacing.

Nested list:
- Parent item
  - Child item that should be indented in a rich layout.
  - Another child item with a long line that should wrap with indentation
    aligned to the child bullet text.

Ordered list with nesting:
1. First item
2. Second item
   - Nested bullet under ordered list
   - Another nested bullet
3. Third item

List item with paragraph:
- First paragraph in list item. It should have a line break and indent.

  Second paragraph in the same list item. Flat mode will usually collapse
  this to single-spacing without a proper hanging indent.

---

## 4) Code Blocks (Monospace + Background)

```swift
func hello(name: String) -> String {
    return "Hello, \(name)"
}
```

Code blocks should have a subtle background, padding, and monospaced text.
If this appears as plain text, it's a regression.

---

## 5) Tables (Alignment + Grid)

| Column A | Column B | Column C |
|---------:|:---------|:---------|
| Right    | Left     | Center   |
| 12345    | Text     | 3.14159  |
| Wrap     | A long cell that should wrap inside a table cell | End |

Tables should render as a readable grid with column alignment.
If this appears as plain text with pipes, it's a regression.

---

## 6) Images (Inline vs Block)

![Sample Image](./sample.png)

In rich mode, images should be centered, scaled to content width, and have
rounded corners. Flat mode will not render images at all.

---

## 7) Links and Inline Styles

Inline styles should still work in flat mode:
*italic* **bold** ***bold italic*** `inline code`
[link to example](https://example.com).

---

## Summary

If the document above feels visually flat, cramped, or hard to scan, that is
the expected behavior of the flat renderer. This is the trade-off for better
scroll performance in large files.
