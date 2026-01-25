//
//  DocumentStore.swift
//  Leaf
//
//  Created by Codex on 24/02/26.
//

import Foundation
import Markdown
import SwiftUI

struct RenderKey: Hashable {
    let themeID: LeafTheme.ThemeID
    let zoomScale: CGFloat
}

struct OpenDocument: Identifiable {
    let id: UUID
    let url: URL
    let displayName: String
    let locationName: String
    let baseURL: URL
    var content: String
    var parsed: Document?
    var segments: [RenderSegment]
    var statusMessage: String?
    var isLoading: Bool
    var securityScoped: Bool
    var renderKey: RenderKey?
    var renderToken: UUID
}

final class DocumentStore: ObservableObject {
    @Published private(set) var documents: [OpenDocument] = []
    @Published private(set) var selectedID: UUID?

    private var currentRenderKey: RenderKey?
    private var currentColors: LeafTheme.Colors?
    private var currentMetrics: LeafTheme.Metrics?

    deinit {
        releaseAllSecurityScopedAccess()
    }

    func open(urls: [URL], renderKey: RenderKey, colors: LeafTheme.Colors, metrics: LeafTheme.Metrics) {
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

    func select(id: UUID?, renderKey: RenderKey, colors: LeafTheme.Colors, metrics: LeafTheme.Metrics) {
        updateRenderContext(renderKey: renderKey, colors: colors, metrics: metrics)
        selectedID = id
        guard let id else { return }
        ensureRendered(id: id, renderKey: renderKey, colors: colors, metrics: metrics)
    }

    func close(id: UUID) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let document = documents[index]
        if document.securityScoped {
            document.url.stopAccessingSecurityScopedResource()
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

    func refreshSelected(renderKey: RenderKey, colors: LeafTheme.Colors, metrics: LeafTheme.Metrics) {
        updateRenderContext(renderKey: renderKey, colors: colors, metrics: metrics)
        guard let selectedID else { return }
        ensureRendered(id: selectedID, renderKey: renderKey, colors: colors, metrics: metrics)
    }

    func releaseAllSecurityScopedAccess() {
        for document in documents where document.securityScoped {
            document.url.stopAccessingSecurityScopedResource()
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
            let segments = MarkdownRenderBuilder.buildSegments(
                document: parsed,
                colors: colors,
                metrics: metrics,
                baseURL: baseURL
            )
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
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            do {
                let data = try Data(contentsOf: url)
                let content = String(decoding: data, as: UTF8.self)
                let parsedDocument = Document(parsing: content)
                let segments = MarkdownRenderBuilder.buildSegments(
                    document: parsedDocument,
                    colors: colors,
                    metrics: metrics,
                    baseURL: baseURL
                )
                DispatchQueue.main.async {
                    guard let self else {
                        if didStartAccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                        return
                    }
                    guard let updateIndex = self.documents.firstIndex(where: { $0.id == id }) else {
                        if didStartAccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                        return
                    }
                    guard self.documents[updateIndex].renderToken == token else {
                        if didStartAccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                        return
                    }
                    self.documents[updateIndex].content = content
                    self.documents[updateIndex].parsed = parsedDocument
                    self.documents[updateIndex].segments = segments
                    self.documents[updateIndex].renderKey = renderKey
                    self.documents[updateIndex].statusMessage = nil
                    self.documents[updateIndex].isLoading = false
                    self.documents[updateIndex].securityScoped = didStartAccessing

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
                        if didStartAccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                        return
                    }
                    guard let updateIndex = self.documents.firstIndex(where: { $0.id == id }) else {
                        if didStartAccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                        return
                    }
                    guard self.documents[updateIndex].renderToken == token else {
                        if didStartAccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                        return
                    }
                    self.documents[updateIndex].content = ""
                    self.documents[updateIndex].parsed = nil
                    self.documents[updateIndex].segments = []
                    self.documents[updateIndex].renderKey = nil
                    self.documents[updateIndex].statusMessage = "Unable to open file."
                    self.documents[updateIndex].isLoading = false
                    self.documents[updateIndex].securityScoped = false
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
            }
        }
    }

    private func updateDocument(id: UUID, _ update: (inout OpenDocument) -> Void) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        update(&documents[index])
    }
}
