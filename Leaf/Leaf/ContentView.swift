//
//  ContentView.swift
//  Leaf
//
//  Created by Neeraj Kumar on 24/01/26.
//

import AppKit
import Markdown
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    private static let themeStorageKey = "leaf.selectedThemeID"
    private let allowedTypes: [UTType] = [
        UTType(filenameExtension: "md") ?? .plainText,
        .plainText
    ]

    @State private var zoomScale: CGFloat = 1.0
    @State private var fileName: String = "Untitled"
    @State private var fileContent: String = ""
    @State private var statusMessage: String?
    @State private var isFileImporterPresented = false
    @State private var document: Document?
    @State private var renderSegments: [RenderSegment] = []
    @State private var isLoading = false
    @State private var renderToken = UUID()
    @State private var fileURL: URL?
    @State private var securityScopedURL: URL?
    @State private var selectedThemeID: LeafTheme.ThemeID
    @State private var isThemeSwitcherPresented = false
    @State private var themeShortcutMonitor: Any?
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

    var body: some View {
        ZStack(alignment: .trailing) {
            colors.background
                .ignoresSafeArea()
            ScrollView {
                HStack {
                    Spacer(minLength: 0)
                    VStack(alignment: .leading, spacing: metrics.paragraphSpacing) {
                        if let statusMessage = statusMessage {
                            Text(statusMessage)
                                .font(.system(size: max(12, metrics.bodyFontSize * 0.875)))
                                .foregroundStyle(colors.secondary)
                        }

                        if fileContent.isEmpty {
                            Text("Open a Markdown file to begin.")
                                .font(.system(size: metrics.bodyFontSize * 1.125, weight: .semibold))
                                .foregroundStyle(colors.secondary)
                        } else {
                            if document != nil {
                                MarkdownSegmentedView(
                                    segments: renderSegments,
                                    colors: colors,
                                    metrics: metrics
                                )
                            } else {
                                Text(fileContent)
                                    .font(.system(size: metrics.bodyFontSize))
                                    .foregroundStyle(colors.text)
                            }
                        }
                    }
                    .frame(maxWidth: metrics.contentMaxWidth, alignment: .leading)
                    .padding(.vertical, metrics.verticalPadding)
                    .padding(.horizontal, 24)
                    Spacer(minLength: 0)
                }
            }
            if isLoading {
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
        .frame(minWidth: 700, minHeight: 500)
        .preferredColorScheme(theme.isDark ? .dark : .light)
        .animation(.easeOut(duration: 0.35), value: isThemeSwitcherPresented)
        .environment(\.openURL, OpenURLAction { url in
            NSWorkspace.shared.open(url)
            return .handled
        })
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(fileName)
                    .font(.headline)
                    .foregroundStyle(colors.text)
            }
            ToolbarItemGroup(placement: .automatic) {
                Button(action: openFile) {
                    Image(systemName: "folder")
                }
                .help("Open Markdown File")
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
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    loadFile(from: url)
                }
            case .failure:
                statusMessage = "Unable to open file."
            }
        }
        .onOpenURL { url in
            loadFile(from: url)
        }
        .onChange(of: zoomScale) { _, _ in
            rebuildRenderContent()
        }
        .onChange(of: selectedThemeID) { _, _ in
            UserDefaults.standard.set(selectedThemeID.rawValue, forKey: Self.themeStorageKey)
            rebuildRenderContent()
        }
        .onAppear {
            setupThemeShortcutMonitor()
        }
        .onDisappear {
            tearDownThemeShortcutMonitor()
        }
    }

    private func openFile() {
        isFileImporterPresented = true
    }

    private func loadFile(from url: URL) {
        statusMessage = nil
        startLoading()
        releaseSecurityScopedAccess()

        let token = renderToken
        let currentColors = colors
        let currentMetrics = metrics
        let baseURL = url.deletingLastPathComponent()

        DispatchQueue.global(qos: .userInitiated).async {
            let didStartAccessing = url.startAccessingSecurityScopedResource()

            do {
                let data = try Data(contentsOf: url)
                let content = String(decoding: data, as: UTF8.self)
                let parsedDocument = Document(parsing: content)
                let segments = MarkdownRenderBuilder.buildSegments(
                    document: parsedDocument,
                    colors: currentColors,
                    metrics: currentMetrics,
                    baseURL: baseURL
                )
                DispatchQueue.main.async {
                    guard renderToken == token else { return }
                    fileContent = content
                    document = parsedDocument
                    fileName = url.lastPathComponent
                    renderSegments = segments
                    fileURL = url
                    if didStartAccessing {
                        securityScopedURL = url
                    }
                    statusMessage = nil
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    guard renderToken == token else { return }
                    fileContent = ""
                    document = nil
                    renderSegments = []
                    fileName = url.lastPathComponent
                    fileURL = nil
                    statusMessage = "Unable to open file."
                    isLoading = false
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
            }

            if renderToken != token, didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    private func zoomOut() {
        zoomScale = max(0.8, zoomScale - 0.1)
    }

    private func zoomIn() {
        zoomScale = min(1.6, zoomScale + 0.1)
    }

    private func rebuildRenderContent() {
        guard let document else {
            renderSegments = []
            return
        }
        startLoading()
        let token = renderToken
        let currentColors = colors
        let currentMetrics = metrics
        let baseURL = fileURL?.deletingLastPathComponent()

        DispatchQueue.global(qos: .userInitiated).async {
            let segments = MarkdownRenderBuilder.buildSegments(
                document: document,
                colors: currentColors,
                metrics: currentMetrics,
                baseURL: baseURL
            )
            DispatchQueue.main.async {
                guard renderToken == token else { return }
                renderSegments = segments
                isLoading = false
            }
        }
    }

    private func startLoading() {
        renderToken = UUID()
        isLoading = true
    }

    private func releaseSecurityScopedAccess() {
        if let url = securityScopedURL {
            url.stopAccessingSecurityScopedResource()
            securityScopedURL = nil
        }
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
        releaseSecurityScopedAccess()
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
