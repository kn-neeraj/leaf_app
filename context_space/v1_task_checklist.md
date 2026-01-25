# v1_task_checklist.md

## Project setup

- [x] Create SwiftUI app project (macOS 15+ target)
- [ ] Configure app icon
- [x] Configure bundle metadata (display name, app category)
- [x] Set up basic window size and content container

## Toolbar and shell UI

- [x] Add minimal toolbar (file name center, Open button, zoom A- / A+)
- [x] Wire `Cmd+O` to open dialog

## Markdown parsing and model

- [x] Integrate Markdown parser dependency (e.g., `swift-markdown`)
- [x] Define render model for block and inline elements

## Core rendering

- [x] Headings (H1–H6) with hierarchy
- [x] Paragraphs with spacing and line height
- [x] Ordered and unordered lists
- [x] Blockquotes
- [x] Horizontal rules
- [x] Inline styles: bold, italic, links, inline code

## Advanced blocks

- [x] Code blocks with mono font, subtle background, rounded corners, horizontal scroll
- [x] Tables with simple readable layout and overflow handling
- [ ] Images from local/relative paths only (scale to content width, rounded corners)

## Styling polish

- [x] Apply light/dark palette per `context_space/style_spec.md`
- [x] Apply typography scale per `context_space/style_spec.md`
- [x] Enforce max content width and centered layout
- [ ] Smooth scrolling (no visible jank)
- [x] Spacing refinements (line/paragraph/list spacing)
- [x] Avoid pure black/white; use subtle contrast for long reading
- [x] Subtle separators only; no heavy borders or boxes
- [x] Lists slightly tighter than paragraphs
- [x] Blockquotes: soft border + secondary text
- [x] Link and bullet accent color defined and applied consistently

## Themes

- [x] Theme switcher (Shift+Tab) with Tab navigation and live preview/apply
- [x] Red Graphite theme
- [x] Dark Graphite theme
- [x] High Contrast theme
- [x] Rose Pine theme
- [x] Tokyo Night theme

## File handling

- [ ] Open `.md` via Finder (default app registration)
- [x] Handle security-scoped file access as needed
- [x] Basic error state (file not found / unreadable)

## QA and performance

- [x] Test large documents for performance
- [ ] Validate nested inline styles and edge cases
- [ ] Verify links open in default browser
- [ ] Confirm no remote image loading
