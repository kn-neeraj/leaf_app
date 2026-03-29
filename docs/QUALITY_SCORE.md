# Leaf Quality Score

Reviewed on 2026-03-29 against the current codebase and `docs/`.

| Area | Grade | Status | Notes |
| --- | --- | --- | --- |
| Build stability | B | ✅ | Fresh `xcodebuild` succeeds; project still has an `Info.plist` copy-phase warning |
| Test coverage | B | ✅ | Unit coverage now exists for parser, renderer, file store, sidebar state, and markdown fixtures; UI suite is still brittle |
| Markdown rendering | B+ | ✅ | Core reader coverage is stronger, with explicit compatibility docs, fixtures, and better fallback behavior |
| Sidebar | B | ✅ | Multi-file open/select/close works; no persistence or richer file management |
| Syntax highlighting | C | ⚠️ | Present, but regex-based and shallow |
| Accessibility | D | ❌ | A few labels and shortcuts exist; no clear accessibility pass or validation |
| Architecture compliance | B | ✅ | Mostly follows the documented layer split; `ContentView` is getting heavy |

## Detail

### Build stability — B

- `xcodebuild -project Leaf/Leaf.xcodeproj -scheme Leaf -destination 'platform=macOS' build` succeeds.
- App signs and includes the needed read-only file entitlement.
- Weak spot: Xcode warns that `Info.plist` is incorrectly included in Copy Bundle Resources.

### Test coverage — B

- `LeafTests` now covers parser behavior, render behavior, file service behavior, document store behavior, sidebar state, and fixture-backed compatibility cases.
- The new fixture corpus in `test_markdown_files/compatibility/` gives Leaf a reusable regression set for markdown support.
- Weak spot: the full `Leaf` scheme is still dragged down by flaky `LeafUITests`, so automated confidence is uneven across UI and core logic.

### Markdown rendering — B+

- Implemented: headings, paragraphs, ordered/unordered lists, nested list flattening, task list prefixes, blockquotes, rules, links, autolinks, inline code, strikethrough, tables, code blocks, local image resolution, inline-image fallback, and raw HTML fallback.
- Good architectural choice: AST-based rendering via `swift-markdown`, not HTML.
- There is now an explicit compatibility contract in `docs/design-docs/architecture-notes/markdown_compatibility_matrix.md`.
- Weak spots: inline images stay fallback-level, remote images remain blocked, and HTML/math/diagram content is still outside the native render scope.

### Sidebar — B

- Implemented: multi-select open, sidebar list, active selection, duplicate-open reuse, close, neighbor reselection, per-file security scope.
- Missing: persistence, reorder, pinning, grouping.

### Syntax highlighting — C

- Implemented in `MarkdownRenderModel.highlightedCode`.
- Works by regex over a small language set.
- Missing: parser-backed highlighting, broad language coverage, richer token theming.

### Accessibility — D

- Present: some keyboard shortcuts, selectable text, accessibility label on image placeholders.
- Missing: accessibility identifiers, clear VoiceOver review, focus-order review, broader semantic/accessibility annotations.

### Architecture compliance — B

- Good: app shell, store, theme, render-model, and rendering layers are visibly separated.
- Good: `DocumentStore` owns file lifecycle; `MarkdownRenderModel` owns Markdown policy.
- Weak spot: `ContentView` now owns too much orchestration logic.

## Bottom line

Leaf is now a more credible markdown reader: the parser/render core has real test coverage and a defined compatibility target. The remaining quality gaps are UI-test reliability, accessibility, and the still-lightweight syntax-highlighting path.
