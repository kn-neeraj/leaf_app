import SwiftUI

struct LeafCommandContext {
    let isSidebarVisible: Bool
    let toggleSidebar: () -> Void
    let openThemes: () -> Void
    let showKeyboardShortcuts: () -> Void
    let zoomIn: () -> Void
    let zoomOut: () -> Void
}

private struct LeafCommandContextKey: FocusedValueKey {
    typealias Value = LeafCommandContext
}

extension FocusedValues {
    var leafCommandContext: LeafCommandContext? {
        get { self[LeafCommandContextKey.self] }
        set { self[LeafCommandContextKey.self] = newValue }
    }
}

struct LeafAppCommands: Commands {
    @FocusedValue(\.leafCommandContext) private var commandContext

    private var sidebarLabel: String {
        commandContext?.isSidebarVisible == false ? UICopy.Commands.showSidebar : UICopy.Commands.hideSidebar
    }

    var body: some Commands {
        CommandGroup(replacing: .sidebar) {
            Button(sidebarLabel) {
                commandContext?.toggleSidebar()
            }
            .keyboardShortcut(.tab, modifiers: [])
            .disabled(commandContext == nil)
        }

        CommandGroup(after: .sidebar) {
            Button(UICopy.Commands.themes) {
                commandContext?.openThemes()
            }
            .keyboardShortcut(.tab, modifiers: [.shift])
            .disabled(commandContext == nil)

            Button(UICopy.Commands.keyboardShortcuts) {
                commandContext?.showKeyboardShortcuts()
            }
            .disabled(commandContext == nil)

            Divider()

            Button(UICopy.Commands.increaseTextSize) {
                commandContext?.zoomIn()
            }
            .keyboardShortcut("=", modifiers: [.command])
            .disabled(commandContext == nil)

            Button(UICopy.Commands.decreaseTextSize) {
                commandContext?.zoomOut()
            }
            .keyboardShortcut("-", modifiers: [.command])
            .disabled(commandContext == nil)
        }
    }
}
