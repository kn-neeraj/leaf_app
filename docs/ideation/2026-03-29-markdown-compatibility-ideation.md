---
date: 2026-03-29
topic: markdown-compatibility
focus: compatibility matrix, fixture suite, renderer coverage expansion
---

# Ideation: Markdown Compatibility for Leaf

## Codebase Context

Leaf is a native macOS SwiftUI Markdown reader with a shared render core in `Leaf/LeafCore/`.
The current architecture is strong: `swift-markdown` parses into AST, `MarkdownRenderModel.swift` maps AST into render blocks/segments, and `MarkdownView.swift` renders them in SwiftUI.
Current support is solid for core CommonMark blocks and key inline styles, but coverage is uneven for real-world GitHub-style Markdown.
Important observed gaps:
- nested list structure is flattened inside `ListItem` rendering
- task lists are not explicitly modeled or rendered
- image rendering only handles image-only paragraphs cleanly
- raw HTML has no declared fallback policy
- “support all markdown” is undefined without a compatibility target

## Ranked Ideas

### 1. Markdown Compatibility Matrix
**Description:** Define Leaf’s target dialect as `CommonMark + selected GFM` and classify each construct as `Supported`, `Partial`, `Fallback`, or `Out of scope`.
**Rationale:** This gives Leaf a product contract. Without it, “open any markdown file” is ambiguous and impossible to verify.
**Downsides:** Forces explicit exclusions and removes hand-wavy scope.
**Confidence:** 97%
**Complexity:** Low
**Status:** Explored

Initial matrix:

| Construct | Status | Notes |
| --- | --- | --- |
| ATX headings (`#`) | Supported | Explicit heading rendering exists |
| Setext headings | Supported | Parsed as headings by `swift-markdown` |
| Paragraphs | Supported | Primary text path |
| Bold | Supported | `Strong` handled |
| Italic | Supported | `Emphasis` handled |
| Strikethrough | Supported | `Strikethrough` handled |
| Inline code | Supported | `InlineCode.code` used correctly |
| Links | Supported | Clickable attributed links |
| Autolinks | Partial | Works if parser emits links; needs explicit fixture coverage |
| Soft/hard line breaks | Supported | Soft breaks -> space, hard breaks -> newline |
| Unordered lists | Supported | Top-level support exists |
| Ordered lists | Supported | Top-level support exists |
| Nested lists | Partial | Child paragraphs render, deeper structure is flattened |
| Mixed nested lists | Partial | Same limitation as nested lists |
| Task lists | Partial | Likely parsed as list text; no checkbox model/rendering |
| Blockquotes | Supported | Explicit blockquote rendering exists |
| Nested blockquotes | Partial | Basic recursion exists; needs fixtures for complex nesting |
| Horizontal rules | Supported | Explicit thematic break rendering exists |
| Fenced code blocks | Supported | Styled and syntax-highlighted |
| Indented code blocks | Supported | Parsed as `CodeBlock` by parser; needs fixture proof |
| Tables | Supported | Explicit table render path exists |
| Complex table cell content | Partial | Inline content works; advanced layout behavior is limited |
| Images in standalone paragraphs | Supported | Explicit image segment path exists |
| Inline images inside text | Partial | No dedicated inline image rendering path |
| Relative local images | Supported | Resolved against file base URL |
| Absolute local images | Supported | File-path resolution exists |
| Remote images | Fallback | Intentionally not loaded |
| Missing/bad image source | Fallback | Text fallback exists |
| Raw HTML blocks | Fallback | No dedicated render path; should be declared readable fallback |
| Raw inline HTML | Fallback | No dedicated inline render path |
| Footnotes | Out of scope | Not currently modeled |
| Mermaid/LaTeX/math | Out of scope | Explicitly out of scope in PRD |

### 2. Markdown Fixture Suite
**Description:** Build a fixture corpus with one file per construct plus one large “kitchen sink” file covering mixed real-world Markdown.
**Rationale:** The matrix only matters if each row has proof. Fixtures become the source of truth for QA and tests.
**Downsides:** Requires discipline to keep fixtures aligned with renderer behavior.
**Confidence:** 95%
**Complexity:** Medium
**Status:** Unexplored

Recommended first fixture set:
- `headings.md`
- `inline-styles.md`
- `lists-basic.md`
- `lists-nested.md`
- `task-lists.md`
- `blockquotes.md`
- `code-blocks.md`
- `tables.md`
- `images-local.md`
- `images-edge-cases.md`
- `links-and-autolinks.md`
- `html-fallback.md`
- `kitchen-sink.md`

### 3. Renderer Coverage Expansion
**Description:** Expand `MarkdownRenderModel.swift` and `MarkdownView.swift` only where the matrix or fixture suite shows real compatibility gaps.
**Rationale:** This keeps work disciplined and prevents speculative feature creep.
**Downsides:** Some “nice to have” markdown features will wait until fixtures justify them.
**Confidence:** 92%
**Complexity:** Medium
**Status:** Unexplored

Recommended implementation order:
1. Task lists
2. Nested and mixed lists
3. Stronger table edge-case handling
4. Autolinks and inline edge cases
5. Inline image behavior and image/path edge cases
6. Declared raw HTML fallback behavior

## Rejection Summary

| # | Idea | Reason Rejected |
|---|------|-----------------|
| 1 | Add `WKWebView` fallback renderer | Conflicts with current architecture and product constraints |
| 2 | Prioritize Mermaid/LaTeX support | Explicitly out of scope for current PRD |
| 3 | Focus on richer syntax highlighting first | Lower leverage than structural markdown compatibility |
| 4 | Jump to editor features | Not aligned with current reader-first goal |

## Session Log
- 2026-03-29: Initial ideation — 6 candidate directions considered, 3 survivors kept for follow-up
