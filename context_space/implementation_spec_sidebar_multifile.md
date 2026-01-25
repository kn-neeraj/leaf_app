# implementation_spec_sidebar_multifile.md

## Overview

Add a left sidebar that lists open Markdown files and lets the user switch between them, similar to Apple Notes. The main reading view remains read-only and uses the current theme + zoom. The Open dialog should allow selecting multiple files to add to the list.

## Goals

- Let users open multiple `.md` files in one session.
- Provide a sidebar list to switch the active document.
- Keep the current rendering pipeline (Markdown -> segments) per file.
- Preserve security-scoped access per open file and release on close.

## Non-goals

- File management beyond the open list (no folders, tags, or sync).
- Editing, pinning, or reordering in v1.
- Persisting the open list across app launches.

## UX / UI

- Use `NavigationSplitView` (macOS 13+ style) with:
  - Sidebar: list of open files (name + subtle secondary detail like folder name).
  - Detail: current content view (existing scroll layout + overlays).
- Sidebar row states:
  - Selected row uses accent tint and clear highlight.
  - Unselected rows use `colors.text` + `colors.secondary`.
- Empty states:
  - No open files: show "Open a Markdown file to begin." in detail view.
  - Open files but none selected: auto-select most recently opened.
- Close affordance:
  - Row context menu "Close".
  - Optional inline "x" button on hover for macOS pointer users.
- Toolbar:
  - Keep file name centered, showing selected file or "Untitled".
  - Open button stays and now supports multi-select.

## Data model

Introduce an app-level store to manage open documents:

```
struct OpenDocument: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let displayName: String
    let baseURL: URL
    var content: String
    var parsed: Document?
    var segments: [RenderSegment]
    var statusMessage: String?
    var isLoading: Bool
    var securityScoped: Bool
    var renderKey: RenderKey
}

struct RenderKey: Hashable {
    let themeID: LeafTheme.ThemeID
    let zoomScale: CGFloat
}
```

`DocumentStore` (ObservableObject) responsibilities:

- `open(urls:)`: add new docs or select existing if already open.
- `select(id:)`: update selection.
- `close(id:)`: stop security scope, remove doc, select neighbor if needed.
- `rebuildSelected(themeID:zoomScale:colors:metrics:)`: rebuild segments for active doc.
- `markStaleIfNeeded(themeID:zoomScale:)`: mark documents when theme/zoom changes.

## File open flow

- `fileImporter` uses `allowsMultipleSelection: true`.
- For each selected URL:
  - Start security scope.
  - Read data, parse Markdown, build segments on background queue.
  - Store `OpenDocument` in the list.
- If a URL already exists in the list, select it instead of duplicating.
- `onOpenURL` (Finder open) should call `open(urls:[url])`.

## Rendering and caching

- Render segments are cached per document using `renderKey`.
- On theme/zoom change:
  - Update `renderKey` for selected document by rebuilding segments.
  - Mark other documents as stale (segments are recomputed on next selection).
- Keep background parsing/rendering behavior to avoid blocking UI.

## Security-scoped access

- Each `OpenDocument` tracks its own `securityScoped` flag.
- Release access on close and on app exit (store deinit or scene phase change).
- Do not call `stopAccessingSecurityScopedResource()` globally when switching docs.

## Keyboard shortcuts

- `Cmd+O`: Open files (multi-select enabled).
- `Cmd+W`: Close current file (if any).
- Optional: `Cmd+Shift+[` / `Cmd+Shift+]` to cycle selection later.

## Edge cases

- Failed load: show status in detail view, keep row but mark as error.
- Deleted/moved file: show error on next selection and allow closing.
- Duplicate open: reuse existing entry and focus it.

## Testing checklist

- Open 2-3 files in one dialog and switch between them.
- Open from Finder while app is running (adds to list and selects).
- Close active file and verify selection moves to next available.
- Theme/zoom changes update current document and do not crash on switch.
- Security-scope release happens when closing files.
