# secondary_research.md

## Purpose
Understand what makes a beautiful Markdown editor and extract design lessons to apply to **Leaf**, a macOS Markdown *reader*.

---

## What a beautiful markdown reader app looks like
- Exceptional typography
- Minimal, distraction-free UI
- Beautiful live Markdown rendering
- Thoughtful Apple-native polish
- Native macOS behaviors (scrolling, selection, animations)
- Smooth transitions, no lag
- Everything feels intentional, not accidental

---

## Core Design Principles

### 1. Typography-First Design
- Large, readable body text
- Generous line height and paragraph spacing
- Clear visual hierarchy for headings
- Subtle contrast (never harsh blacks/whites)

**Key idea:** Text is the product.

---

### 2. Minimal UI (Low Chrome)
- Almost no visible buttons while reading/writing
- Toolbars appear only when needed
- Sidebar is quiet, not dominant

**Key idea:** Remove visual noise so content breathes.

---

### 3. Live Markdown Rendering
- Markdown is rendered inline (headings look like headings)
- Optional hiding of raw syntax (`#`, `**`, etc.)
- Seamless switch between “writing” and “reading”

**Key idea:** Markdown should *look like a document*, not code.

---

### 4. Beautiful Defaults (Zero Setup)
- Default theme already looks great
- Sensible font choices out of the box
- No need to tweak settings to enjoy reading

**Key idea:** First impression matters more than customization depth.

---

### 5. Thoughtful Use of White Space
- Comfortable margins
- Clear separation between sections
- Lists, code blocks, and quotes are visually distinct

**Key idea:** White space is an active design tool.

---

### 6. Rich Content, Softly Rendered
- Images appear inline with rounded corners
- Code blocks have subtle backgrounds
- Tables are readable, not boxed aggressively

**Key idea:** Visual richness without heaviness.

---

### 7. Themes Without Visual Chaos
- Light & dark themes designed holistically
- Consistent colors across text, code, highlights
- No “neon” or overly decorative themes by default

**Key idea:** Calm over clever.

---

**Key idea:** Polish is the sum of small details.

---

## Key Takeaways for Leaf (Markdown Reader)

### Must-Have for Leaf
- Typography-led reading experience
- Clean, centered reading canvas
- Beautiful rendering of:
  - Headings
  - Lists
  - Images
  - Tables
  - Code blocks

### Strong Recommendations
- Optional “pure reading mode” (no raw Markdown)
- Excellent default theme (users shouldn’t need settings)
- Generous spacing and margins
- Subtle UI that disappears while reading

### What NOT to Do
- Too many controls on screen
- Over-styled themes
- Treating Markdown like developer syntax instead of prose

---

