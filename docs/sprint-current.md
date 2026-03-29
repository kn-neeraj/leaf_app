# Current Sprint

## Focus

- Keep Leaf stable as a read-only macOS Markdown reader.
- Improve reader quality in the current weak areas called out in `docs/QUALITY_SCORE.md`.
- Raise markdown compatibility coverage with a defined matrix, fixture corpus, and renderer improvements.
- Polish shell chrome and theme coherence so the app feels intentional before any document is opened.
- Make core shell actions feel usable from the keyboard and discoverable in the macOS menu bar.
- Make shortcut discoverability feel native with a compact empty-state primer and lightweight in-app reference surface.
- Keep the launch state calm: centered empty hero first, with sidebar hidden by default and utility hints kept secondary.

## Current watchlist

- Scroll smoothness on large documents
- Full-scheme UI test reliability
- Keep extending markdown compatibility against the fixture corpus, especially remaining partial/fallback rows
- Validate the new sidebar/top-rail shell treatment across all themes and window sizes
- Validate keyboard-first shell controls across focus states, sidebar visibility states, and menu command routing
- Validate the new shortcut primer and shortcuts sheet across light/dark themes and smaller window sizes
- Accessibility pass
- Keep `ContentView.swift` from absorbing more logic
