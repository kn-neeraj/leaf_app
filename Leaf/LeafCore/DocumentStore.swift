//
//  DocumentStore.swift
//  Leaf
//
//  Created by Codex on 24/02/26.
//

import Foundation
import Markdown
import SwiftUI

public struct RenderKey: Hashable {
    public let themeID: LeafTheme.ThemeID
    public let zoomScale: CGFloat

    public init(themeID: LeafTheme.ThemeID, zoomScale: CGFloat) {
        self.themeID = themeID
        self.zoomScale = zoomScale
    }
}

public struct OpenDocument: Identifiable {
    public let id: UUID
    public let url: URL
    public let displayName: String
    public let locationName: String
    public let baseURL: URL
    public var content: String
    public var parsed: Document?
    public var segments: [RenderSegment]
    public var statusMessage: String?
    public var isLoading: Bool
    public var securityScoped: Bool
    public var renderKey: RenderKey?
    public var renderToken: UUID
}

public final class DocumentStore: ObservableObject {
    @Published public private(set) var documents: [OpenDocument] = []
    @Published public private(set) var selectedID: UUID?

    private let fileService: any FileServing
    private let markdownParser: any MarkdownParsing
    private let renderService: any RenderServing
    private var currentRenderKey: RenderKey?
    private var currentColors: LeafTheme.Colors?
    private var currentMetrics: LeafTheme.Metrics?

    public init(
        fileService: any FileServing = FileService(),
        markdownParser: any MarkdownParsing = MarkdownParser(),
        renderService: any RenderServing = RenderService()
    ) {
        self.fileService = fileService
        self.markdownParser = markdownParser
        self.renderService = renderService
    }

    deinit {
        releaseAllSecurityScopedAccess()
    }

    public func open(urls: [URL], renderKey: RenderKey, colors: LeafTheme.Colors, metrics: LeafTheme.Metrics) {
        updateRenderContext(renderKey: renderKey, colors: colors, metrics: metrics)
        for url in urls {
            if let existingIndex = documents.firstIndex(where: { $0.url == url }) {
                select(id: documents[existingIndex].id, renderKey: renderKey, colors: colors, metrics: metrics)
                continue
            }

            let baseURL = url.deletingLastPathComponent()
            let locationName = baseURL.lastPathComponent.isEmpty ? baseURL.path : baseURL.lastPathComponent
            let documentID = UUID()
            let newDocument = OpenDocument(
                id: documentID,
                url: url,
                displayName: url.lastPathComponent,
                locationName: locationName,
                baseURL: baseURL,
                content: "",
                parsed: nil,
                segments: [],
                statusMessage: nil,
                isLoading: true,
                securityScoped: false,
                renderKey: nil,
                renderToken: UUID()
            )
            documents.append(newDocument)
            selectedID = documentID
            loadDocument(id: documentID, url: url, baseURL: baseURL, renderKey: renderKey, colors: colors, metrics: metrics)
        }
    }

    public func select(id: UUID?, renderKey: RenderKey, colors: LeafTheme.Colors, metrics: LeafTheme.Metrics) {
        updateRenderContext(renderKey: renderKey, colors: colors, metrics: metrics)
        selectedID = id
        guard let id else { return }
        ensureRendered(id: id, renderKey: renderKey, colors: colors, metrics: metrics)
    }

    public func close(id: UUID) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let document = documents[index]
        if document.securityScoped {
            fileService.stopAccessing(document.url)
        }
        documents.remove(at: index)
        if selectedID == id {
            let nextID: UUID?
            if documents.indices.contains(index) {
                nextID = documents[index].id
            } else if documents.indices.contains(index - 1) {
                nextID = documents[index - 1].id
            } else {
                nextID = nil
            }
            if let nextID,
               let renderKey = currentRenderKey,
               let colors = currentColors,
               let metrics = currentMetrics {
                select(id: nextID, renderKey: renderKey, colors: colors, metrics: metrics)
            } else {
                selectedID = nextID
            }
        }
    }

    public func refreshSelected(renderKey: RenderKey, colors: LeafTheme.Colors, metrics: LeafTheme.Metrics) {
        updateRenderContext(renderKey: renderKey, colors: colors, metrics: metrics)
        guard let selectedID else { return }
        ensureRendered(id: selectedID, renderKey: renderKey, colors: colors, metrics: metrics)
    }

    public func releaseAllSecurityScopedAccess() {
        for document in documents where document.securityScoped {
            fileService.stopAccessing(document.url)
        }
        for index in documents.indices {
            documents[index].securityScoped = false
        }
    }

    private func updateRenderContext(renderKey: RenderKey, colors: LeafTheme.Colors, metrics: LeafTheme.Metrics) {
        currentRenderKey = renderKey
        currentColors = colors
        currentMetrics = metrics
    }

    private func ensureRendered(
        id: UUID,
        renderKey: RenderKey,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics
    ) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        if documents[index].isLoading { return }
        if documents[index].renderKey == renderKey { return }
        guard let parsed = documents[index].parsed else { return }

        let baseURL = documents[index].baseURL
        let token = UUID()
        documents[index].isLoading = true
        documents[index].renderToken = token

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let segments = self?.renderService.buildSegments(
                document: parsed,
                colors: colors,
                metrics: metrics,
                baseURL: baseURL
            ) ?? []
            DispatchQueue.main.async {
                guard let self else { return }
                guard let updateIndex = self.documents.firstIndex(where: { $0.id == id }) else { return }
                guard self.documents[updateIndex].renderToken == token else { return }
                self.documents[updateIndex].segments = segments
                self.documents[updateIndex].renderKey = renderKey
                self.documents[updateIndex].isLoading = false
            }
        }
    }

    private func loadDocument(
        id: UUID,
        url: URL,
        baseURL: URL,
        renderKey: RenderKey,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics
    ) {
        let token = UUID()
        updateDocument(id: id) { document in
            document.isLoading = true
            document.statusMessage = nil
            document.renderToken = token
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self else { return }
                let openedFile = try self.fileService.open(url)
                let parsedDocument = self.markdownParser.parse(openedFile.content)
                let segments = self.renderService.buildSegments(
                    document: parsedDocument,
                    colors: colors,
                    metrics: metrics,
                    baseURL: baseURL
                )
                DispatchQueue.main.async { [weak self] in
                    guard let self else {
                        return
                    }
                    guard let updateIndex = self.documents.firstIndex(where: { $0.id == id }) else {
                        if openedFile.didStartAccessingSecurityScopedResource {
                            self.fileService.stopAccessing(url)
                        }
                        return
                    }
                    guard self.documents[updateIndex].renderToken == token else {
                        if openedFile.didStartAccessingSecurityScopedResource {
                            self.fileService.stopAccessing(url)
                        }
                        return
                    }
                    self.documents[updateIndex].content = openedFile.content
                    self.documents[updateIndex].parsed = parsedDocument
                    self.documents[updateIndex].segments = segments
                    self.documents[updateIndex].renderKey = renderKey
                    self.documents[updateIndex].statusMessage = nil
                    self.documents[updateIndex].isLoading = false
                    self.documents[updateIndex].securityScoped = openedFile.didStartAccessingSecurityScopedResource

                    if let currentRenderKey = self.currentRenderKey,
                       let currentColors = self.currentColors,
                       let currentMetrics = self.currentMetrics,
                       currentRenderKey != renderKey {
                        self.ensureRendered(
                            id: id,
                            renderKey: currentRenderKey,
                            colors: currentColors,
                            metrics: currentMetrics
                        )
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    guard let self else {
                        return
                    }
                    guard let updateIndex = self.documents.firstIndex(where: { $0.id == id }) else {
                        return
                    }
                    guard self.documents[updateIndex].renderToken == token else {
                        return
                    }
                    self.documents[updateIndex].content = ""
                    self.documents[updateIndex].parsed = nil
                    self.documents[updateIndex].segments = []
                    self.documents[updateIndex].renderKey = nil
                    self.documents[updateIndex].statusMessage = "Unable to open file."
                    self.documents[updateIndex].isLoading = false
                    self.documents[updateIndex].securityScoped = false
                }
            }
        }
    }

    private func updateDocument(id: UUID, _ update: (inout OpenDocument) -> Void) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        update(&documents[index])
    }
}
