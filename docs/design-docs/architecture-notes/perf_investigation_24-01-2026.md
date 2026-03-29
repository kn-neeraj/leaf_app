# perf_investigation_24-01-2026.md

## Goal

Investigate scroll jank in Leaf and identify likely sources based on Instruments traces.

## Symptoms

- Scrolling feels jittery despite FPS overlay showing steady refresh.
- Instruments (Core Animation / Hitches) shows frame swap times of ~20–40 ms, indicating dropped frames.

## Trace files

- Instruments trace stored at `profiler_files/leaf_profile_24thjan.trace`.
- Time Profiler export (table of contents + time-profile) generated via `xcrun xctrace export`.

## Key observations (from exported time-profile)

The hottest app-related frames in the trace are dominated by:

1) **Hit-testing inside SwiftUI**
   - `HitTestingLeafPlatformView.responderBasedHitTest(_:radius:cacheKey:super:)`
   - `HitTestingLeafPlatformView.defaultHitTest(_:radius:cacheKey:super:)`
   - `HitTestingLeafPlatformView.pointContainmentHitTest(_:)`
   - `LeafViewResponder.containsGlobalPoints(_:cacheKey:options:)`

2) **Text resolution / measurement**
   - `ResolvedTextFilter.updateValue()`
   - `Text.resolveAttributedStringAndProperties(...)`
   - `ResolvedTextHelper.resolve(...)`
   - `NSAttributedString` measurement and draw calls
   - `MarkdownBlockView.attributedString(...)` appears in stack samples

These indicate a lot of view hit-testing and repeated text resolution while scrolling.

## Likely causes

- The view tree is large and **hit-tested** on every scroll frame.
- Rich text is **recomputed and measured** frequently due to SwiftUI body updates.
- Off-screen content is likely being laid out or checked unnecessarily.

## Proposed fixes (next steps)

1) **Use `LazyVStack`** in the Markdown renderer so off-screen blocks are not laid out/hit-tested.
2) **Cache attributed strings** when a file loads to avoid rebuilding them in `body`.
3) **Disable hit-testing** for non-interactive text (paragraphs without links).
4) Optionally reduce inline styling complexity if still heavy after the above.

## Notes

- The in-app FPS overlay measured display refresh, not render cost; it can show stable FPS even when frames are dropped.
- Core Animation hitches show the actual scroll stutter (swap times 20–40 ms).
