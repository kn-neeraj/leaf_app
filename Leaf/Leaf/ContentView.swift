//
//  ContentView.swift
//  Leaf
//
//  Created by Neeraj Kumar on 24/01/26.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    private enum FocusTarget: Hashable {
        case sidebar
    }

    private static let themeStorageKey = "leaf.selectedThemeID"
    private static let uiTestLaunchArgument = "--ui-testing"
    private static let uiTestOpenFileEnvKey = "LEAF_UI_TEST_OPEN_FILE"
    private static let uiTestFileNameEnvKey = "LEAF_UI_TEST_FILE_NAME"
    private static let uiTestFileContentsEnvKey = "LEAF_UI_TEST_FILE_CONTENTS"
    private let allowedTypes: [UTType] = [
        UTType(filenameExtension: "md") ?? .plainText,
        .plainText
    ]

    @StateObject private var documentStore: DocumentStore
    @StateObject private var sidebarViewModel: SidebarViewModel
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var zoomScale: CGFloat = 1.0
    @State private var isFileImporterPresented = false
    @State private var selectedThemeID: LeafTheme.ThemeID
    @State private var isThemeSwitcherPresented = false
    @State private var isKeyboardShortcutsPresented = false
    @State private var themeShortcutMonitor: Any?
    @State private var selectionShortcutMonitor: Any?
    @State private var sidebarShortcutMonitor: Any?
    @State private var isSelectionLocked = false
    @State private var didApplyUITestLaunchState = false
    @FocusState private var focusedPane: FocusTarget?
#if DEBUG
    @State private var isFpsOverlayVisible = true
#endif

    init(
        documentStore: DocumentStore = DocumentStore(),
        sidebarViewModel: SidebarViewModel = SidebarViewModel()
    ) {
        _documentStore = StateObject(wrappedValue: documentStore)
        _sidebarViewModel = StateObject(wrappedValue: sidebarViewModel)
        let storedTheme = UserDefaults.standard.string(forKey: Self.themeStorageKey)
        _selectedThemeID = State(initialValue: ThemeSelection.initialThemeID(storedRawValue: storedTheme))
    }

    private var theme: LeafTheme.Theme {
        LeafTheme.theme(for: selectedThemeID)
    }

    private var colors: LeafTheme.Colors {
        theme.colors
    }

    private var metrics: LeafTheme.Metrics {
        LeafTheme.metrics(scale: zoomScale)
    }

    private var renderKey: RenderKey {
        RenderKey(themeID: selectedThemeID, zoomScale: zoomScale)
    }

    private var selectedDocument: OpenDocument? {
        documentStore.documents.first { $0.id == documentStore.selectedID }
    }

    private var isSelectionEnabled: Bool {
        isSelectionLocked
    }

    private var isSidebarVisible: Bool {
        columnVisibility != .detailOnly
    }

    private var commandContext: LeafCommandContext {
        LeafCommandContext(
            isSidebarVisible: isSidebarVisible,
            toggleSidebar: toggleSidebar,
            openThemes: openThemeSwitcher,
            showKeyboardShortcuts: openKeyboardShortcuts,
            zoomIn: zoomIn,
            zoomOut: zoomOut
        )
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarView
        } detail: {
            detailView
        }
        .accessibilityIdentifier("mainWindow")
        .frame(minWidth: 700, minHeight: 500)
        .preferredColorScheme(theme.isDark ? .dark : .light)
        .animation(.easeOut(duration: 0.35), value: isThemeSwitcherPresented)
        .environment(\.openURL, OpenURLAction { url in
            NSWorkspace.shared.open(url)
            return .handled
        })
        .focusedSceneValue(\.leafCommandContext, commandContext)
        .toolbar {
            ToolbarItem(placement: .principal) {
                LeafToolbarTitleView(
                    documentTitle: selectedDocument?.displayName,
                    colors: colors
                )
            }
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 8) {
                    LeafChromeGroup(colors: colors) {
                        LeafToolbarChromeButton(colors: colors, isActive: false, action: openFile, accessibilityIdentifier: nil, accessibilityValue: nil) {
                            Image(systemName: "folder")
                        }
                        .help(UICopy.Toolbar.openFilesHelp)
                        .keyboardShortcut("o", modifiers: [.command])

                        LeafToolbarChromeButton(colors: colors, isActive: isThemeSwitcherPresented, action: toggleThemeSwitcher, accessibilityIdentifier: nil, accessibilityValue: nil) {
                            Image(systemName: "swatchpalette")
                        }
                        .help(UICopy.Toolbar.themeHelp)

                        LeafToolbarChromeButton(
                            colors: colors,
                            isActive: isSelectionLocked,
                            action: toggleSelectionLock,
                            accessibilityIdentifier: "copyModeToggle",
                            accessibilityValue: CopyModeState.accessibilityValue(isEnabled: isSelectionLocked)
                        ) {
                            Label(UICopy.Toolbar.selectionLabel(isLocked: isSelectionLocked), systemImage: "text.cursor")
                                .labelStyle(.titleAndIcon)
                        }
                        .help(UICopy.Toolbar.selectionHelp(isLocked: isSelectionLocked))
                    }

                    LeafChromeGroup(colors: colors) {
                        LeafToolbarChromeButton(colors: colors, isActive: false, action: zoomOut, accessibilityIdentifier: nil, accessibilityValue: nil) {
                            Text(UICopy.Toolbar.zoomOut)
                        }
                        .help(UICopy.Toolbar.zoomOutHelp)

                        LeafToolbarChromeButton(colors: colors, isActive: false, action: zoomIn, accessibilityIdentifier: nil, accessibilityValue: nil) {
                            Text(UICopy.Toolbar.zoomIn)
                        }
                        .help(UICopy.Toolbar.zoomInHelp)
                    }
                }
            }
#if DEBUG
            ToolbarItem(placement: .automatic) {
                LeafToolbarChromeButton(colors: colors, isActive: isFpsOverlayVisible, action: { isFpsOverlayVisible.toggle() }, accessibilityIdentifier: nil, accessibilityValue: nil) {
                    Image(systemName: "speedometer")
                }
                .help(UICopy.Toolbar.fpsOverlayHelp)
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }
#endif
        }
#if DEBUG
        .overlay(alignment: .topTrailing) {
            if isFpsOverlayVisible {
                FPSOverlay()
                    .padding(.top, 8)
                    .padding(.trailing, 8)
            }
        }
#endif
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                if !urls.isEmpty {
                    documentStore.open(
                        urls: urls,
                        renderKey: renderKey,
                        colors: colors,
                        metrics: metrics
                    )
                }
            case .failure:
                break
            }
        }
        .sheet(isPresented: $isKeyboardShortcutsPresented) {
            KeyboardShortcutsSheet(theme: theme)
                .frame(width: 540, height: 448)
        }
        .onOpenURL { url in
            documentStore.open(
                urls: [url],
                renderKey: renderKey,
                colors: colors,
                metrics: metrics
            )
        }
        .onChange(of: zoomScale) { _, _ in
            documentStore.refreshSelected(
                renderKey: renderKey,
                colors: colors,
                metrics: metrics
            )
        }
        .onChange(of: sidebarViewModel.selectedDocumentID) { _, newValue in
            guard newValue != documentStore.selectedID else { return }
            documentStore.select(
                id: newValue,
                renderKey: renderKey,
                colors: colors,
                metrics: metrics
            )
        }
        .onChange(of: documentStore.selectedID) { _, newValue in
            if sidebarViewModel.selectedDocumentID != newValue {
                sidebarViewModel.select(newValue)
            }
        }
        .onChange(of: selectedThemeID) { _, _ in
            UserDefaults.standard.set(selectedThemeID.rawValue, forKey: Self.themeStorageKey)
            documentStore.refreshSelected(
                renderKey: renderKey,
                colors: colors,
                metrics: metrics
            )
        }
        .onChange(of: columnVisibility) { _, newValue in
            if newValue == .detailOnly {
                focusedPane = nil
            }
        }
        .onAppear {
            setupThemeShortcutMonitor()
            setupSelectionShortcutMonitor()
            setupSidebarShortcutMonitor()
            applyUITestLaunchStateIfNeeded()
        }
        .onDisappear {
            tearDownThemeShortcutMonitor()
            tearDownSelectionShortcutMonitor()
            tearDownSidebarShortcutMonitor()
            documentStore.releaseAllSecurityScopedAccess()
        }
    }

    private var sidebarView: some View {
        Group {
            if documentStore.documents.isEmpty {
                SidebarEmptyStateView(colors: colors)
            } else {
                ScrollViewReader { proxy in
                    List {
                        ForEach(documentStore.documents) { document in
                            SidebarRow(
                                document: document,
                                colors: colors,
                                isSelected: sidebarViewModel.selectedDocumentID == document.id
                            )
                            .id(document.id)
                            .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                            .listRowBackground(Color.clear)
                            .onTapGesture {
                                focusedPane = .sidebar
                                sidebarViewModel.select(document.id)
                            }
                            .contextMenu {
                                Button(UICopy.Sidebar.closeAction) {
                                    documentStore.close(id: document.id)
                                }
                            }
                        }
                    }
                    .focusable()
                    .focused($focusedPane, equals: .sidebar)
                    .onChange(of: sidebarViewModel.selectedDocumentID) { _, newValue in
                        guard let newValue else { return }
                        withAnimation(.easeOut(duration: 0.18)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            focusedPane = .sidebar
                        }
                    )
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .background(colors.sidebarBackground)
            }
        }
        .background(colors.sidebarBackground)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sidebar")
    }

    private var detailView: some View {
        ZStack(alignment: .trailing) {
            colors.background
                .ignoresSafeArea()
            Group {
                if let document = selectedDocument {
                    documentDetailView(document)
                } else {
                    ReaderEmptyStateView(
                        theme: theme,
                        metrics: metrics,
                        openAction: openFile
                    )
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("preview")
            .help(UICopy.Reader.selectionHelp)
            if isThemeSwitcherPresented {
                ThemeSwitcherOverlay(
                    themes: LeafTheme.themes,
                    selectedThemeID: $selectedThemeID,
                    isPresented: $isThemeSwitcherPresented
                )
                .frame(width: 360)
                .padding(.vertical, 24)
                .padding(.trailing, 24)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if let selectedDocument {
                ReaderSubheaderView(
                    colors: colors,
                    documentTitle: selectedDocument.displayName
                )
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                focusedPane = nil
            }
        )
    }

    private func documentDetailView(_ document: OpenDocument) -> some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: metrics.paragraphSpacing) {
                    if let statusMessage = document.statusMessage {
                        Text(statusMessage)
                            .font(.system(size: max(12, metrics.bodyFontSize * 0.875)))
                            .foregroundStyle(colors.secondary)
                    } else if document.isLoading {
                        VStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text(UICopy.Reader.loading)
                                .font(.system(size: max(12, metrics.bodyFontSize * 0.875), weight: .semibold))
                        }
                        .foregroundStyle(colors.secondary)
                        .padding(.vertical, 12)
                    } else if document.content.isEmpty {
                        Text(UICopy.Reader.emptyDocument)
                            .font(.system(size: metrics.bodyFontSize * 1.125, weight: .semibold))
                            .foregroundStyle(colors.secondary)
                    } else if document.parsed != nil {
                        MarkdownSegmentedView(
                            segments: document.segments,
                            colors: colors,
                            metrics: metrics,
                            isSelectionEnabled: isSelectionEnabled
                        )
                    } else {
                        Text(document.content)
                            .font(.system(size: metrics.bodyFontSize))
                            .foregroundStyle(colors.text)
                            .conditionalTextSelection(isSelectionEnabled)
                    }
                }
                .frame(maxWidth: metrics.contentMaxWidth, alignment: .leading)
                .padding(.vertical, metrics.verticalPadding)
                .padding(.horizontal, 24)
                Spacer(minLength: 0)
            }
        }
    }

    private func openFile() {
        isFileImporterPresented = true
    }

    private func zoomOut() {
        zoomScale = max(0.8, zoomScale - 0.1)
    }

    private func zoomIn() {
        zoomScale = min(1.6, zoomScale + 0.1)
    }

    private func setupThemeShortcutMonitor() {
        guard themeShortcutMonitor == nil else { return }
        themeShortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard !isKeyboardShortcutsPresented else { return event }
            let inertFlags: NSEvent.ModifierFlags = [.numericPad]
            let flags = event.modifierFlags
                .intersection(.deviceIndependentFlagsMask)
                .subtracting(inertFlags)
            let isTabKey = event.keyCode == 48
            let isPlainTab = isTabKey && flags.isEmpty
            let isShiftTab = isTabKey && flags == [.shift]
            let isReturnKey = event.keyCode == 36 || event.keyCode == 76
            let characters = event.charactersIgnoringModifiers ?? ""

            if isShiftTab {
                toggleThemeSwitcher()
                return nil
            }

            if isThemeSwitcherPresented, isPlainTab {
                cycleTheme()
                return nil
            }

            if isPlainTab {
                toggleSidebar()
                return nil
            }

            if isThemeSwitcherPresented, isReturnKey, flags.isEmpty {
                isThemeSwitcherPresented = false
                return nil
            }

            if flags == [.command] || flags == [.command, .shift] {
                if characters == "=" {
                    zoomIn()
                    return nil
                }
                if characters == "-" {
                    zoomOut()
                    return nil
                }
            }

            return event
        }
    }

    private func tearDownThemeShortcutMonitor() {
        if let monitor = themeShortcutMonitor {
            NSEvent.removeMonitor(monitor)
            themeShortcutMonitor = nil
        }
    }

    private func setupSelectionShortcutMonitor() {
        guard selectionShortcutMonitor == nil else { return }
        selectionShortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let isPlainCommandC =
                flags == [.command] &&
                event.charactersIgnoringModifiers?.lowercased() == "c"
            guard isPlainCommandC else { return event }
            if hasActiveTextSelectionForCopy() {
                return event
            }
            toggleSelectionLock()
            return nil
        }
    }

    private func tearDownSelectionShortcutMonitor() {
        if let monitor = selectionShortcutMonitor {
            NSEvent.removeMonitor(monitor)
            selectionShortcutMonitor = nil
        }
    }

    private func setupSidebarShortcutMonitor() {
        guard sidebarShortcutMonitor == nil else { return }
        sidebarShortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isSidebarVisible, !isThemeSwitcherPresented, !isKeyboardShortcutsPresented else { return event }

            let allowedFlags: NSEvent.ModifierFlags = [.numericPad, .function]
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard flags.subtracting(allowedFlags).isEmpty else { return event }

            switch event.keyCode {
            case 126:
                moveSidebarSelection(offset: -1)
                return nil
            case 125:
                moveSidebarSelection(offset: 1)
                return nil
            default:
                return event
            }
        }
    }

    private func tearDownSidebarShortcutMonitor() {
        if let monitor = sidebarShortcutMonitor {
            NSEvent.removeMonitor(monitor)
            sidebarShortcutMonitor = nil
        }
    }

    private func toggleSelectionLock() {
        isSelectionLocked = CopyModeState.toggled(from: isSelectionLocked)
    }

    private func hasActiveTextSelectionForCopy() -> Bool {
        guard let responder = NSApp.keyWindow?.firstResponder else {
            return false
        }
        if let textView = responder as? NSTextView {
            return textView.selectedRange.length > 0
        }
        return false
    }

    private func cycleTheme() {
        selectedThemeID = ThemeSelection.nextThemeID(after: selectedThemeID)
    }

    private func toggleThemeSwitcher() {
        isThemeSwitcherPresented.toggle()
        if isThemeSwitcherPresented {
            focusedPane = nil
        }
    }

    private func openThemeSwitcher() {
        isThemeSwitcherPresented = true
        focusedPane = nil
    }

    private func openKeyboardShortcuts() {
        isThemeSwitcherPresented = false
        isKeyboardShortcutsPresented = true
        focusedPane = nil
    }

    private func toggleSidebar() {
        let willShowSidebar = !isSidebarVisible
        withAnimation(.easeOut(duration: 0.18)) {
            columnVisibility = willShowSidebar ? .all : .detailOnly
        }
        if !willShowSidebar {
            focusedPane = nil
        }
    }

    private func applyUITestLaunchStateIfNeeded() {
        guard !didApplyUITestLaunchState else { return }
        didApplyUITestLaunchState = true

        let processInfo = ProcessInfo.processInfo
        guard processInfo.arguments.contains(Self.uiTestLaunchArgument) else { return }
        let environment = processInfo.environment

        let url: URL?
        if let path = environment[Self.uiTestOpenFileEnvKey], !path.isEmpty {
            let candidate = URL(fileURLWithPath: path)
            url = FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
        } else if let contents = environment[Self.uiTestFileContentsEnvKey], !contents.isEmpty {
            let fileName = environment[Self.uiTestFileNameEnvKey] ?? "leaf-ui-test.md"
            let candidate = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            do {
                try contents.write(to: candidate, atomically: true, encoding: .utf8)
                url = candidate
            } catch {
                url = nil
            }
        } else {
            url = nil
        }

        guard let url else { return }

        documentStore.open(
            urls: [url],
            renderKey: renderKey,
            colors: colors,
            metrics: metrics
        )
    }

    private func moveSidebarSelection(offset: Int) {
        let documentIDs = documentStore.documents.map(\.id)
        guard !documentIDs.isEmpty else { return }

        let baseIndex: Int
        if let selectedID = sidebarViewModel.selectedDocumentID,
           let currentIndex = documentIDs.firstIndex(of: selectedID) {
            baseIndex = currentIndex
        } else {
            baseIndex = offset > 0 ? -1 : documentIDs.count
        }

        let nextIndex = min(max(baseIndex + offset, 0), documentIDs.count - 1)
        let nextID = documentIDs[nextIndex]
        if nextID != sidebarViewModel.selectedDocumentID {
            sidebarViewModel.select(nextID)
        }
    }
}

struct SidebarRow: View {
    let document: OpenDocument
    let colors: LeafTheme.Colors
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(isSelected ? colors.accent : .clear)
                .frame(width: 3, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(colors.text)
                Text(document.locationName)
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? colors.text.opacity(0.72) : colors.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if document.isLoading {
                ProgressView()
                    .controlSize(.mini)
                    .tint(colors.accent)
            } else if document.statusMessage != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isSelected ? colors.accent : colors.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? colors.chromeSurface : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? colors.chromeBorder : .clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

struct ThemeSwitcherOverlay: View {
    let themes: [LeafTheme.Theme]
    @Binding var selectedThemeID: LeafTheme.ThemeID
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(UICopy.ThemeSwitcher.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(panelColors.text)
                Spacer()
                Button(UICopy.ThemeSwitcher.done) {
                    isPresented = false
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(panelColors.secondary)
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16)], spacing: 16) {
                        ForEach(themes) { theme in
                            Button {
                                selectedThemeID = theme.id
                            } label: {
                                ThemePreviewCard(
                                    theme: theme,
                                    isSelected: theme.id == selectedThemeID,
                                    isFocused: theme.id == selectedThemeID
                                )
                            }
                            .buttonStyle(.plain)
                            .id(theme.id)
                            .accessibilityIdentifier("theme-\(theme.id.rawValue)")
                        }
                    }
                }
                .onAppear {
                    scrollToSelection(proxy, animated: false)
                }
                .onChange(of: selectedThemeID) { _, _ in
                    scrollToSelection(proxy, animated: true)
                }
            }
        }
        .onExitCommand {
            isPresented = false
        }
        .accessibilityIdentifier("themeSwitcher")
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(panelColors.codeBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(panelColors.quoteBorder, lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
    }

    private var panelColors: LeafTheme.Colors {
        LeafTheme.theme(for: selectedThemeID).colors
    }

    private func scrollToSelection(_ proxy: ScrollViewProxy, animated: Bool) {
        if animated {
            withAnimation(.easeOut(duration: 0.35)) {
                proxy.scrollTo(selectedThemeID, anchor: .center)
            }
        } else {
            proxy.scrollTo(selectedThemeID, anchor: .center)
        }
    }
}

struct ThemePreviewCard: View {
    let theme: LeafTheme.Theme
    let isSelected: Bool
    let isFocused: Bool

    private var borderColor: Color {
        if isSelected || isFocused {
            return theme.colors.accent
        }
        return theme.colors.quoteBorder
    }

    private var borderWidth: CGFloat {
        (isSelected || isFocused) ? 2 : 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(theme.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.colors.text)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.colors.accent)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                (Text(UICopy.ThemeSwitcher.previewLineOneLeading) + Text(UICopy.ThemeSwitcher.previewLineOneStrong).fontWeight(.semibold))
                    .foregroundStyle(theme.colors.text)
                Text(UICopy.ThemeSwitcher.previewLineTwo)
                    .foregroundStyle(theme.colors.secondary)
                (Text(UICopy.ThemeSwitcher.previewLineThreeLeading).foregroundStyle(theme.colors.secondary)
                    + Text(UICopy.ThemeSwitcher.previewLineThreeAccent).foregroundStyle(theme.colors.accent)
                    + Text(UICopy.ThemeSwitcher.previewLineThreeTrailing).foregroundStyle(theme.colors.secondary))
            }
            .font(.system(size: 12))
            .lineLimit(3)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}

private extension View {
    @ViewBuilder
    func conditionalTextSelection(_ isEnabled: Bool) -> some View {
        if isEnabled {
            self.textSelection(.enabled)
        } else {
            self
        }
    }
}
