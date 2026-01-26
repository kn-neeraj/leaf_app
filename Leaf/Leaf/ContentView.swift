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
    private static let themeStorageKey = "leaf.selectedThemeID"
    private let allowedTypes: [UTType] = [
        UTType(filenameExtension: "md") ?? .plainText,
        .plainText
    ]

    @StateObject private var documentStore = DocumentStore()
    @State private var zoomScale: CGFloat = 1.0
    @State private var isFileImporterPresented = false
    @State private var selectedThemeID: LeafTheme.ThemeID
    @State private var isThemeSwitcherPresented = false
    @State private var themeShortcutMonitor: Any?
    @State private var sidebarSelection: UUID?
#if DEBUG
    @State private var isFpsOverlayVisible = true
#endif

    init() {
        if let stored = UserDefaults.standard.string(forKey: Self.themeStorageKey),
           let id = LeafTheme.ThemeID(rawValue: stored) {
            _selectedThemeID = State(initialValue: id)
        } else {
            _selectedThemeID = State(initialValue: LeafTheme.defaultThemeID)
        }
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

    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailView
        }
        .frame(minWidth: 700, minHeight: 500)
        .preferredColorScheme(theme.isDark ? .dark : .light)
        .animation(.easeOut(duration: 0.35), value: isThemeSwitcherPresented)
        .environment(\.openURL, OpenURLAction { url in
            NSWorkspace.shared.open(url)
            return .handled
        })
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(selectedDocument?.displayName ?? "Untitled")
                    .font(.headline)
                    .foregroundStyle(colors.text)
            }
            ToolbarItemGroup(placement: .automatic) {
                Button(action: openFile) {
                    Image(systemName: "folder")
                }
                .help("Open Markdown Files")
                .keyboardShortcut("o", modifiers: [.command])

                Button(action: zoomOut) {
                    Text("A-")
                }
                .help("Zoom Out")

                Button(action: zoomIn) {
                    Text("A+")
                }
                .help("Zoom In")
            }
#if DEBUG
            ToolbarItem(placement: .automatic) {
                Button(action: { isFpsOverlayVisible.toggle() }) {
                    Image(systemName: "speedometer")
                }
                .help("Toggle FPS Overlay")
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }
#endif
        }
        .tint(colors.accent)
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
        .onChange(of: sidebarSelection) { _, newValue in
            guard newValue != documentStore.selectedID else { return }
            documentStore.select(
                id: newValue,
                renderKey: renderKey,
                colors: colors,
                metrics: metrics
            )
        }
        .onChange(of: documentStore.selectedID) { _, newValue in
            if sidebarSelection != newValue {
                sidebarSelection = newValue
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
        .onAppear {
            setupThemeShortcutMonitor()
        }
        .onDisappear {
            tearDownThemeShortcutMonitor()
            documentStore.releaseAllSecurityScopedAccess()
        }
    }

    private var sidebarView: some View {
        ZStack {
            List(selection: $sidebarSelection) {
                ForEach(documentStore.documents) { document in
                    SidebarRow(document: document, colors: colors)
                        .tag(document.id)
                        .contextMenu {
                            Button("Close") {
                                documentStore.close(id: document.id)
                            }
                        }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            if documentStore.documents.isEmpty {
                Text("No open files")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(colors.secondary)
            }
        }
        .background(colors.background)
    }

    private var detailView: some View {
        ZStack(alignment: .trailing) {
            colors.background
                .ignoresSafeArea()
            ScrollView {
                HStack {
                    Spacer(minLength: 0)
                    VStack(alignment: .leading, spacing: metrics.paragraphSpacing) {
                        if let document = selectedDocument {
                            if let statusMessage = document.statusMessage {
                                Text(statusMessage)
                                    .font(.system(size: max(12, metrics.bodyFontSize * 0.875)))
                                    .foregroundStyle(colors.secondary)
                            } else if document.isLoading {
                                EmptyView()
                            } else if document.content.isEmpty {
                                Text("Empty document.")
                                    .font(.system(size: metrics.bodyFontSize * 1.125, weight: .semibold))
                                    .foregroundStyle(colors.secondary)
                            } else if document.parsed != nil {
                                MarkdownSegmentedView(
                                    segments: document.segments,
                                    colors: colors,
                                    metrics: metrics
                                )
                            } else {
                                Text(document.content)
                                    .font(.system(size: metrics.bodyFontSize))
                                    .foregroundStyle(colors.text)
                            }
                        } else {
                            Text("Open a Markdown file to begin.")
                                .font(.system(size: metrics.bodyFontSize * 1.125, weight: .semibold))
                                .foregroundStyle(colors.secondary)
                        }
                    }
                    .frame(maxWidth: metrics.contentMaxWidth, alignment: .leading)
                    .padding(.vertical, metrics.verticalPadding)
                    .padding(.horizontal, 24)
                    Spacer(minLength: 0)
                }
            }
            if selectedDocument?.isLoading == true {
                LoadingOverlayView(colors: colors, metrics: metrics)
                    .transition(.opacity)
                    .zIndex(1)
            }
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
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let isTabKey = event.keyCode == 48
            let hasDisallowedModifier = flags.contains(.command) || flags.contains(.option) || flags.contains(.control)
            let isReturnKey = event.keyCode == 36 || event.keyCode == 76
            if isTabKey, flags.contains(.shift), !hasDisallowedModifier {
                isThemeSwitcherPresented.toggle()
                return nil
            }
            if isThemeSwitcherPresented, isReturnKey, !hasDisallowedModifier {
                isThemeSwitcherPresented = false
                return nil
            }
            if isThemeSwitcherPresented, isTabKey, !hasDisallowedModifier {
                cycleTheme()
                return nil
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

    private func cycleTheme() {
        let themeIDs = LeafTheme.themes.map(\.id)
        guard let index = themeIDs.firstIndex(of: selectedThemeID), !themeIDs.isEmpty else {
            selectedThemeID = LeafTheme.defaultThemeID
            return
        }
        let nextIndex = (index + 1) % themeIDs.count
        selectedThemeID = themeIDs[nextIndex]
    }
}

struct SidebarRow: View {
    let document: OpenDocument
    let colors: LeafTheme.Colors

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(colors.text)
                Text(document.locationName)
                    .font(.system(size: 11))
                    .foregroundStyle(colors.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if document.isLoading {
                ProgressView()
                    .controlSize(.mini)
            } else if document.statusMessage != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(colors.secondary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

struct LoadingOverlayView: View {
    let colors: LeafTheme.Colors
    let metrics: LeafTheme.Metrics

    var body: some View {
        ZStack {
            colors.background.opacity(0.85)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                Image("LeafLoading")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 200 * metrics.scale, height: 200 * metrics.scale)
                Text("Loading...")
                    .font(.system(size: 14 * metrics.scale, weight: .semibold))
                    .foregroundStyle(colors.secondary)
            }
        }
        .allowsHitTesting(true)
    }
}

struct ThemeSwitcherOverlay: View {
    let themes: [LeafTheme.Theme]
    @Binding var selectedThemeID: LeafTheme.ThemeID
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Themes")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(panelColors.text)
                Spacer()
                Button("Done") {
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
                (Text("Lorem ipsum ") + Text("dolor sit amet,").fontWeight(.semibold))
                    .foregroundStyle(theme.colors.text)
                Text("consectetur adipiscing elit. Mauris")
                    .foregroundStyle(theme.colors.secondary)
                (Text("iaculis ").foregroundStyle(theme.colors.secondary)
                    + Text("semper").foregroundStyle(theme.colors.accent)
                    + Text(" pharetra.").foregroundStyle(theme.colors.secondary))
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
