# Leaf Agents Guide

## 1. What is Leaf

Leaf is a native macOS SwiftUI app for reading Markdown in a calm, typography-first layout. It is intentionally read-only: no editing, no HTML/WebKit renderer, no remote image loading, and no persistent multi-file workspace.

## 2. Start Every Session By Reading

1. `docs/product-specs/prd_v1.md`
2. `docs/sprint-current.md`
3. `docs/QUALITY_SCORE.md`
4. `docs/design-docs/architecture-notes/implementation_plan_v1.md`
5. `docs/design-docs/architecture-notes/implementation_spec_sidebar_multifile.md`
6. `docs/design-docs/architecture-notes/style_spec.md`
7. `docs/design-docs/architecture-notes/perf_investigation_24-01-2026.md`
8. `docs/design-docs/architecture-notes/v1_task_checklist.md`
9. `docs/design-docs/interaction-summaries/session1_24-02-2026.md`
10. `docs/design-docs/interaction-summaries/session2_24-01-2026.md`
11. `docs/design-docs/interaction-summaries/session3_24-01-2026.md`
12. `docs/design-docs/interaction-summaries/session4_25-01-2026.md`
13. `docs/design-docs/interaction-summaries/session5_26-01-2026.md`
14. `docs/README.md`

## 3. Verification

Use `scripts/verify.sh`. Run it after any SwiftUI, store, renderer, theme, project, or entitlement change, and always before ending a coding session. It currently performs the canonical macOS Debug build for `Leaf/Leaf.xcodeproj`.

## 4. Hard Constraints

- Keep Leaf read-only. Do not add editing, export, sync, persistence of open files, or cloud/file-management features unless the product docs change first.
- Do not introduce `WKWebView`, HTML rendering, or a parallel web-based renderer. Markdown must continue through `swift-markdown` into `MarkdownRenderModel.swift` and `MarkdownView.swift`.
- `DocumentStore.swift` is the only owner of file loading, `startAccessingSecurityScopedResource()`, and `stopAccessingSecurityScopedResource()`.
- `LeafTheme.swift` must stay limited to palette, typography, spacing, and theme selection data. No parsing, file I/O, or app state there.
- Keep rendering views dumb. `MarkdownView.swift` should render supplied models, not load files or make product decisions.
- Do not add more orchestration to `ContentView.swift` unless there is no alternative. It is already 564 lines; new feature logic should usually move out.
- Do not add more parsing/render policy into views. `MarkdownRenderModel.swift` is already 877 lines; extend render types carefully and extract helpers when adding new block/inline behavior.
- No force unwraps or crash-first guards for normal app flows. Handle unreadable files, bad links, missing images, and parse failures as user-visible states.
- No ad-hoc `print`, `NSLog`, or scattered debug logging in production code. Keep instrumentation deliberate and isolated, like `FPSOverlay.swift`.
- Preserve the current performance posture: `LazyVStack`, segmented rendering, async rebuilds, and no remote image fetches.

## 5. End Every Session

- Run `scripts/verify.sh`.
- Use `/prompts:ce-compound [brief context]` after a real fix lands so the solution is captured while context is fresh.
- Update `docs/design-docs/interaction-summaries/` with a dated session note for the work you just finished.
- Update `docs/sprint-current.md` to reflect the new focus, open risks, or next step.
- Update `docs/QUALITY_SCORE.md` if the session materially changed build stability, tests, rendering quality, sidebar behavior, syntax highlighting, accessibility, or architecture compliance.
