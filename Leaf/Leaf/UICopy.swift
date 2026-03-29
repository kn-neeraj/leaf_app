enum UICopy {
    enum Toolbar {
        static let appTitle = "Leaf"
        static let readyStateTitle = "Ready to read"
        static let openFilesHelp = "Open Markdown Files"
        static let themeHelp = "Choose Theme (Shift+Tab)"
        static let zoomOut = "A-"
        static let zoomIn = "A+"
        static let zoomOutHelp = "Zoom Out"
        static let zoomInHelp = "Zoom In"
        static let fpsOverlayHelp = "Toggle FPS Overlay"

        static func selectionLabel(isLocked: Bool) -> String {
            isLocked ? "Select On" : "Select"
        }

        static func selectionHelp(isLocked: Bool) -> String {
            isLocked ? "Text selection locked on" : "Lock text selection on (Cmd+C when nothing is selected)"
        }
    }

    enum Sidebar {
        static let emptyTitle = "Reading stack"
        static let emptyMessage = "Open one or more Markdown files to build a quiet reading queue."
        static let closeAction = "Close"
    }

    enum ReaderBar {
        static let untitled = "Untitled"
    }

    enum Reader {
        static let selectionHelp = "Use the Select button or Cmd+C (when nothing is selected) to toggle text selection."
        static let loading = "Loading..."
        static let emptyDocument = "Empty document."
    }

    enum EmptyState {
        static let headline = "Open a Markdown file and settle in."
        static let primaryAction = "Open Markdown"
    }

    enum PreviewCard {
        static let fileName = "welcome.md"
        static let label = "Preview"
        static let title = "A quieter read"
        static let body = "Markdown should feel like a page, not a parser dump. Leaf softens the chrome and lets the writing lead."
        static let codeLanguage = "swift"
        static let codeLineOne = "let reader = \"Leaf\""
        static let codeLineTwo = "print(reader)"
    }

    enum ThemeSwitcher {
        static let title = "Themes"
        static let done = "Done"
        static let previewLineOneLeading = "Lorem ipsum "
        static let previewLineOneStrong = "dolor sit amet,"
        static let previewLineTwo = "consectetur adipiscing elit. Mauris"
        static let previewLineThreeLeading = "iaculis "
        static let previewLineThreeAccent = "semper"
        static let previewLineThreeTrailing = " pharetra."
    }

    enum Commands {
        static let showSidebar = "Show Sidebar"
        static let hideSidebar = "Hide Sidebar"
        static let themes = "Themes..."
        static let keyboardShortcuts = "Keyboard Shortcuts..."
        static let increaseTextSize = "Increase Text Size"
        static let decreaseTextSize = "Decrease Text Size"
    }

    enum Shortcuts {
        static let inlineHint = "Check keyboard shortcuts in View > Keyboard Shortcuts..."

        static let sheetTitle = "Keyboard Shortcuts"
        static let sheetSubtitle = "The core shell controls are small enough to memorize."
        static let done = "Done"

        static let navigationSection = "Navigation"
        static let themesSection = "Themes"
        static let readingSection = "Reading"

        static let toggleSidebar = "Toggle sidebar"
        static let moveThroughFiles = "Move through open files"
        static let moveThroughFilesContext = "When the sidebar is visible"

        static let toggleThemes = "Toggle themes"
        static let nextTheme = "Next theme"
        static let nextThemeContext = "While the theme switcher is open"

        static let increaseTextSize = "Increase text size"
        static let decreaseTextSize = "Decrease text size"
    }
}
