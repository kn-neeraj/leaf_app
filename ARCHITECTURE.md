# Architecture

## Purpose

Leaf is a native macOS SwiftUI Markdown reader. The architecture is intentionally small: app shell, screen composition, document/session state, render model building, and pure SwiftUI rendering.

## SwiftUI layer map

### 1. App shell

- `Leaf/Leaf/LeafApp.swift`
- Owns the `WindowGroup` and top-level window sizing.

### 2. Screen and interaction layer

- `Leaf/Leaf/ContentView.swift`
- Composes `NavigationSplitView`, toolbar, file importer, `onOpenURL`, theme switcher, zoom, selection toggle, and empty/loading/error states.
- This is the only place that should orchestrate app-wide UI interactions.

### 3. Session/document state layer

- `Leaf/Leaf/DocumentStore.swift`
- Owns open documents, selected document, security-scoped file access, background loading, parse/render refresh, and close/release behavior.
- `OpenDocument` and `RenderKey` are the main state contracts between UI and rendering.

### 4. Theme and presentation tokens

- `Leaf/Leaf/LeafTheme.swift`
- Defines theme palette, typography, spacing, zoom-scaled metrics, and theme catalog.
- No file I/O or Markdown parsing should live here.

### 5. Markdown render-model layer

- `Leaf/Leaf/MarkdownRenderModel.swift`
- Converts `swift-markdown` AST into app-specific render data: `RenderBlock`, `RenderSegment`, tables, images, and attributed text.
- This is the Markdown policy layer: flattening, segmentation, inline styling, code highlighting, and image/table decisions belong here.

### 6. Rendering views

- `Leaf/Leaf/MarkdownView.swift`
- Renders the render model into SwiftUI using `LazyVStack`, `Text`, table/code/image subviews, and hit-testing/text-selection behavior.
- This layer should stay dumb: render what it receives, do not parse files or own app state.

### 7. Debug-only instrumentation

- `Leaf/Leaf/FPSOverlay.swift`
- Debug performance overlay only; not part of production document flow.

## Dependency rules

- `LeafApp` may import and instantiate the screen layer only.
- `ContentView` may depend on `DocumentStore`, `LeafTheme`, and render/view types.
- `DocumentStore` may depend on Foundation, SwiftUI types needed for metrics, `swift-markdown`, and `MarkdownRenderBuilder`.
- `MarkdownRenderModel` may depend on `swift-markdown`, Foundation, SwiftUI text/color/font primitives, and theme metrics/colors.
- `MarkdownView` may depend on render-model types and `LeafTheme`.
- `LeafTheme` must not import Markdown or depend on document state.
- Rendering views must not read files, start security scope, or own parsing logic.
- Upward dependencies are not allowed: render/model code must not import `ContentView` or `DocumentStore`.

## Key technical decisions already made

- Native macOS SwiftUI app, single window, read-only reader.
- `swift-markdown` is the parser; Markdown is rendered from a structured AST, not from HTML.
- Rendering is pure SwiftUI `Text`/`AttributedString` plus custom table/code/image views.
- No `WKWebView` HTML renderer.
- No editor architecture; editing is out of scope.
- `NavigationSplitView` is the shell for multi-file navigation.
- Multi-file state is app-level in `DocumentStore`, with per-file security-scoped access.
- Rendering work is cached per `RenderKey` (`themeID` + `zoomScale`) and rebuilt asynchronously.
- `LazyVStack` and segmented rendering are used to reduce scroll jank from large SwiftUI view trees.
- Remote images are blocked; only local/relative image paths are supported.
- No persistence for the open file list across launches.

## Architectural guidance that should be explicit

- Keep Markdown parsing and render-model building together, separate from SwiftUI view code.
- Add new reader features by extending `RenderSegment`/`RenderBlock` first, then rendering views, not by branching inside `ContentView`.
- Treat `DocumentStore` as the only owner of file lifecycle and security-scope release.
- If future performance work is needed, add it below the UI layer first: cache policy, render segmentation, and measurement hotspots.
- If a richer text engine is introduced later, add it as a renderer beneath the render-model layer rather than letting HTML/WebKit leak into screen code.
