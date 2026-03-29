# implementation_plan_v1.md

## Overview

Leaf v1 is a native macOS 15+ SwiftUI app for elegant, read-only Markdown reading. The app focuses on typography, calm layout, and fast rendering. No editing, no sync, no remote images, no live reload.

## Locked v1 decisions

- macOS 15+ target, SwiftUI native app
- Single window, single document at a time
- Minimal, always-visible toolbar
- No live reload, no last-file restore
- Local/relative images only; remote images blocked
- Simple tables (readable layout, no advanced grid behavior)
- Zoom is a single control that scales all typography uniformly

## Rendering approach

- Parse Markdown with a robust library (e.g., `swift-markdown`) into a structured model.
- Render block elements with SwiftUI views for precise spacing and hierarchy.
- Render inline styles (bold/italic/links/inline code) with `Text` / `AttributedString` as appropriate.
- Use file-based image loading with size constraints and rounded corners.
- Open links in the default browser.

## Design principles (Bear-inspired)

- Typography-first: text is the product; prioritize legibility and calm hierarchy.
- Low chrome: minimize visible UI while reading; content is primary.
- Subtle contrast: avoid pure black/white; prefer softer contrast for long reads.
- Whitespace as structure: spacing defines sections and hierarchy.
- Soft rendering for rich blocks: rounded images, subtle code backgrounds, readable tables.

## UI and layout requirements

- Centered content column with max width 680–740 px.
- Typography per `context_space/style_spec.md`:
  - SF Pro Text for body/headings
  - SF Mono for code
  - Line height 1.55–1.65, paragraph spacing 0.8–1.0em
- Light/Dark colors per spec.
- Code blocks: subtle background, rounded corners, horizontal scroll.
- Images: centered, max width of content column, preserve aspect ratio, rounded corners.
- Smooth scrolling for long documents.

## Toolbar (minimal)

- File name (centered)
- Open button
- Zoom controls (A- / A+), single global scale

## File open flows

- Set as default app for `.md`
- Open via Finder (double-click / Open With)
- `Cmd+O` file picker

## Implementation milestones

1) Project setup and app shell
   - SwiftUI app structure
   - Toolbar layout (placeholder)
   - Basic window sizing and centered content container

2) Markdown parsing and block model
   - Integrate Markdown parser
   - Map Markdown blocks to renderable nodes

3) Core rendering
   - Headings, paragraphs, lists, blockquotes, horizontal rules
   - Inline formatting (bold, italic, links, inline code)

4) Advanced blocks
   - Code blocks with styling + horizontal scroll
   - Tables with simple readable layout
   - Images from local/relative paths only

5) Styling polish
   - Apply typography scale, spacing, colors
   - Light/Dark mode parity
   - Refine margins and hierarchy to match the desired "calm" look
   - Ensure low-chrome feel (subtle separators, minimal visual noise)
   - Ensure soft rendering for rich blocks (images, code, tables)

6) File handling
   - Open file dialog
   - Open via default app flow
   - Security-scoped access if needed

7) QA and performance
   - Large document rendering
   - Mixed Markdown edge cases
   - Link handling validation

## Risks and mitigations

- Tables: start with simple layout and revisit only if readability issues appear.
- Large files: use lazy stacks and avoid heavy re-rendering.
- Inline style edge cases: test nested and mixed spans early.

## Non-goals (v1)

- Editing or authoring
- Split view or raw markdown display
- Export or sharing features
- Remote image loading
- Custom themes or preferences beyond zoom
