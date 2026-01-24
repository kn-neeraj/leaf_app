# v1_task_checklist.md

## Project setup

- [x] Create SwiftUI app project (macOS 15+ target)
- [ ] Configure app icon and bundle metadata
- [x] Set up basic window size and content container

## Toolbar and shell UI

- [x] Add minimal toolbar (file name center, Open button, zoom A- / A+)
- [x] Wire `Cmd+O` to open dialog

## Markdown parsing and model

- [x] Integrate Markdown parser dependency (e.g., `swift-markdown`)
- [ ] Define render model for block and inline elements

## Core rendering

- [x] Headings (H1–H6) with hierarchy
- [x] Paragraphs with spacing and line height
- [x] Ordered and unordered lists
- [ ] Blockquotes
- [ ] Horizontal rules
- [ ] Inline styles: bold, italic, links, inline code

## Advanced blocks

- [ ] Code blocks with mono font, subtle background, rounded corners, horizontal scroll
- [ ] Tables with simple readable layout and overflow handling
- [ ] Images from local/relative paths only (scale to content width, rounded corners)

## Styling polish

- [ ] Apply light/dark palette per `context_space/style_spec.md`
- [ ] Apply typography scale per `context_space/style_spec.md`
- [ ] Enforce max content width and centered layout
- [ ] Smooth scrolling and spacing refinements
- [ ] Avoid pure black/white; use subtle contrast for long reading
- [ ] Subtle separators only; no heavy borders or boxes
- [ ] Lists slightly tighter than paragraphs
- [ ] Blockquotes: soft border + secondary text
- [ ] Link and bullet accent color defined and applied consistently

## File handling

- [ ] Open `.md` via Finder (default app registration)
- [ ] Handle security-scoped file access as needed
- [ ] Basic error state (file not found / unreadable)

## QA and performance

- [ ] Test large documents for performance
- [ ] Validate nested inline styles and edge cases
- [ ] Verify links open in default browser
- [ ] Confirm no remote image loading
