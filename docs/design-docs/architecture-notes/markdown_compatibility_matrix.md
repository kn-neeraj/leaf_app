# Markdown Compatibility Matrix

Leaf targets `CommonMark + selected GFM` for read-only rendering.

## Supported In This Phase

- Headings
- Paragraphs
- Bold
- Italic
- Strikethrough
- Inline code
- Links
- Ordered lists
- Unordered lists
- Nested lists
- Task lists
- Blockquotes
- Horizontal rules
- Fenced code blocks
- Tables
- Local images
- Autolinks

## Partial / Fallback

- Inline images inside text: kept readable, but not rendered as dedicated inline media
- Remote images: shown as blocked/unavailable image placeholders
- Bad local image paths: shown as unavailable image placeholders
- Raw HTML: not a native render target in this phase

## Out Of Scope

- Footnotes
- Mermaid
- LaTeX / math
- Remote image fetching
- HTML / WebKit rendering

## Fixture Source Of Truth

The fixture corpus for this matrix lives in `test_markdown_files/compatibility/`.
