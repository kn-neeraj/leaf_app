# Leaf

## Introduction
- Leaf is a macOS app for reading Markdown files in a clean, distraction-free layout.
- The focus is typography-first reading with fast rendering and minimal chrome.
- It is intentionally read-only: no editing, exporting, or heavy customization.
- Built in collaboration with human agent (neeraj) + AI Agent (CodexCLI).
- Product goals and scope live in `context_space/prd_v1.md`.

## How it works
[Quick Demo](https://www.youtube.com/watch?v=JduYTtYZQ68) 


## How to install
- Build the app (Release) with Xcode: open `Leaf/Leaf.xcodeproj`, select **Leaf** scheme, then **Product → Archive** or **Build** (Release).
- Or build via CLI:
```bash
xcodebuild -project Leaf/Leaf.xcodeproj -scheme Leaf -configuration Release -derivedDataPath build
```
- Create a DMG from the built app (stored in `releases/`):
```bash
scripts/build_dmg.sh --manual --volname "Leaf Installer" "build/Build/Products/Release/Leaf.app" "releases/Leaf-$(date +%Y%m%d-%H%M%S).dmg"
```
- The DMG is written to `releases/` with a timestamped name.
- Open the DMG and drag **Leaf** into **Applications**.
- Launch from **Applications**. If macOS blocks it, right-click **Leaf** → **Open** once to approve.
- Set as default for `.md` files via Finder → **Get Info** → **Open with** → **Change All** (optional).

## Implementation plan
- Build a native SwiftUI app with a Markdown parsing + rendering pipeline tuned for smooth scrolling.
- Support multi-file browsing via a sidebar and per-file render caching.
- Keep the UI minimal, with themes, zoom controls, and clean typography.
- See `context_space/implementation_plan_v1.md` and `context_space/implementation_spec_sidebar_multifile.md` for details.

## Future plan
- Evolve Leaf into a full-blown open source Markdown editor over time.
