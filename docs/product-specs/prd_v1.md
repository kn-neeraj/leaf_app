# prd_v1.md

## Goal

Build a **simple, elegant, read-only Markdown reader for macOS** that allows users to open any `.md` file instantly and read it in a **clean, distraction-free, and highly readable format**.

The app is optimized purely for **reading comfort**, not for editing or authoring markdown.

---

## Scope

- Native macOS application
- Can be set as the **default app** for `.md` files
- Supports opening markdown files via:
  - Double-click
  - Right-click → Open With
- Read-only rendering (no editing interactions)
- Instant file loading and rendering
- Clean, minimal UI with focus on content
- Support for macOS Light and Dark modes
- Use macOS-native, eye-friendly fonts optimized for long reading

---

## Out of Scope

- Markdown editing or writing
- Split view (raw markdown vs preview)
- Exporting to PDF, HTML, or other formats
- Plugin or extension system
- Advanced customization or theming
- Markdown linting or validation
- Diagrams, Mermaid, LaTeX, or math rendering
- Cloud sync, file management, or storage features

---

## List of Features

- Beautiful rendering of core Markdown elements:
  - Headings (H1–H6) with clear visual hierarchy
  - Paragraph text with optimal line width and spacing
  - Ordered and unordered lists
  - Inline and block code snippets
  - Tables with readable layout and overflow handling
  - Images rendered inline with proper scaling
  - Blockquotes
  - Horizontal rules
  - Bold, italic, links, and other rich markdown styles
- Typography-first design:
  - System fonts (e.g., SF / New York)
  - Comfortable line height and margins
- Distraction-free reading experience:
  - Minimal chrome
  - Centered content layout
- Clickable links that open in the default browser
- Smooth scrolling for long documents

