import Foundation
import Markdown
import Testing

@MainActor
struct DocumentStoreTests {
    private let colors = LeafTheme.theme(for: .highContrast).colors
    private let metrics = LeafTheme.metrics(scale: 1.0)
    private let defaultRenderKey = RenderKey(themeID: .highContrast, zoomScale: 1.0)

    @Test func openMultipleFilesSelectsNewestAndLoadsContent() async throws {
        let firstURL = URL(fileURLWithPath: "/tmp/first.md")
        let secondURL = URL(fileURLWithPath: "/tmp/second.md")
        let fileService = MockDocumentFileService(files: [
            firstURL: OpenedFile(content: "# First", didStartAccessingSecurityScopedResource: false),
            secondURL: OpenedFile(content: "# Second", didStartAccessingSecurityScopedResource: false)
        ])
        let renderService = MockDocumentRenderService()
        let store = makeStore(fileService: fileService, renderService: renderService)

        store.open(urls: [firstURL, secondURL], renderKey: defaultRenderKey, colors: colors, metrics: metrics)
        try await waitForDocuments(in: store, count: 2)

        #expect(store.documents.map(\.displayName) == ["first.md", "second.md"])
        #expect(store.selectedID == store.documents.last?.id)
        #expect(store.documents.map(\.content) == ["# First", "# Second"])
        #expect(renderService.segmentCallCount == 2)
    }

    @Test func openingDuplicateURLReusesExistingDocument() async throws {
        let firstURL = URL(fileURLWithPath: "/tmp/first.md")
        let secondURL = URL(fileURLWithPath: "/tmp/second.md")
        let fileService = MockDocumentFileService(files: [
            firstURL: OpenedFile(content: "# First", didStartAccessingSecurityScopedResource: false),
            secondURL: OpenedFile(content: "# Second", didStartAccessingSecurityScopedResource: false)
        ])
        let renderService = MockDocumentRenderService()
        let store = makeStore(fileService: fileService, renderService: renderService)

        store.open(urls: [firstURL, secondURL], renderKey: defaultRenderKey, colors: colors, metrics: metrics)
        try await waitForDocuments(in: store, count: 2)

        let firstDocumentID = try #require(store.documents.first(where: { $0.url == firstURL })?.id)
        store.open(urls: [firstURL], renderKey: defaultRenderKey, colors: colors, metrics: metrics)

        #expect(store.documents.count == 2)
        #expect(store.selectedID == firstDocumentID)
        #expect(fileService.openedURLs.filter { $0 == firstURL }.count == 1)
    }

    @Test func closingSelectedDocumentMovesSelectionToNeighbor() async throws {
        let firstURL = URL(fileURLWithPath: "/tmp/first.md")
        let secondURL = URL(fileURLWithPath: "/tmp/second.md")
        let fileService = MockDocumentFileService(files: [
            firstURL: OpenedFile(content: "# First", didStartAccessingSecurityScopedResource: false),
            secondURL: OpenedFile(content: "# Second", didStartAccessingSecurityScopedResource: false)
        ])
        let store = makeStore(fileService: fileService)

        store.open(urls: [firstURL, secondURL], renderKey: defaultRenderKey, colors: colors, metrics: metrics)
        try await waitForDocuments(in: store, count: 2)

        let firstID = try #require(store.documents.first(where: { $0.url == firstURL })?.id)
        let secondID = try #require(store.documents.first(where: { $0.url == secondURL })?.id)

        store.close(id: secondID)

        #expect(store.documents.count == 1)
        #expect(store.selectedID == firstID)
    }

    @Test func releaseAllSecurityScopedAccessOnlyStopsScopedDocuments() async throws {
        let scopedURL = URL(fileURLWithPath: "/tmp/scoped.md")
        let plainURL = URL(fileURLWithPath: "/tmp/plain.md")
        let fileService = MockDocumentFileService(files: [
            scopedURL: OpenedFile(content: "# Scoped", didStartAccessingSecurityScopedResource: true),
            plainURL: OpenedFile(content: "# Plain", didStartAccessingSecurityScopedResource: false)
        ])
        let store = makeStore(fileService: fileService)

        store.open(urls: [scopedURL, plainURL], renderKey: defaultRenderKey, colors: colors, metrics: metrics)
        try await waitForDocuments(in: store, count: 2)

        store.releaseAllSecurityScopedAccess()

        #expect(fileService.stoppedURLs == [scopedURL])
        #expect(store.documents.allSatisfy { $0.securityScoped == false })
    }

    @Test func refreshSelectedRebuildsSegmentsForNewThemeOrZoom() async throws {
        let url = URL(fileURLWithPath: "/tmp/theme.md")
        let fileService = MockDocumentFileService(files: [
            url: OpenedFile(content: "# Theme", didStartAccessingSecurityScopedResource: false)
        ])
        let renderService = MockDocumentRenderService()
        let store = makeStore(fileService: fileService, renderService: renderService)

        store.open(urls: [url], renderKey: defaultRenderKey, colors: colors, metrics: metrics)
        try await waitForDocuments(in: store, count: 1)

        let nextRenderKey = RenderKey(themeID: .darkGraphite, zoomScale: 1.2)
        let nextColors = LeafTheme.theme(for: .darkGraphite).colors
        let nextMetrics = LeafTheme.metrics(scale: 1.2)

        store.refreshSelected(renderKey: nextRenderKey, colors: nextColors, metrics: nextMetrics)
        try await waitForRenderPasses(on: renderService, count: 2)
        try await waitForDocuments(in: store, count: 1)

        #expect(renderService.segmentCallCount == 2)
        #expect(store.documents.first?.renderKey == nextRenderKey)
    }

    private func makeStore(
        fileService: MockDocumentFileService,
        renderService: MockDocumentRenderService = MockDocumentRenderService()
    ) -> DocumentStore {
        DocumentStore(
            fileService: fileService,
            markdownParser: MockDocumentMarkdownParser(),
            renderService: renderService
        )
    }
}

private final class MockDocumentFileService: FileServing {
    private let files: [URL: OpenedFile]
    private(set) var openedURLs: [URL] = []
    private(set) var stoppedURLs: [URL] = []

    init(files: [URL: OpenedFile]) {
        self.files = files
    }

    func open(_ url: URL) throws -> OpenedFile {
        openedURLs.append(url)
        if let file = files[url] {
            return file
        }
        throw CocoaError(.fileNoSuchFile)
    }

    func save(_ content: String, to url: URL) throws {}

    func stopAccessing(_ url: URL) {
        stoppedURLs.append(url)
    }
}

private struct MockDocumentMarkdownParser: MarkdownParsing {
    func parse(_ content: String) -> Document {
        Document(parsing: content)
    }
}

private final class MockDocumentRenderService: RenderServing {
    private(set) var segmentCallCount = 0

    func buildSegments(
        document: Document,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics,
        baseURL: URL?
    ) -> [RenderSegment] {
        segmentCallCount += 1
        return [
            RenderSegment(
                id: segmentCallCount,
                kind: .text(AttributedString("mock-render-\(segmentCallCount)")),
                isInteractive: false
            )
        ]
    }

    func buildFlatText(
        document: Document,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics
    ) -> (AttributedString, Bool) {
        (AttributedString("mock-flat-text"), false)
    }
}

@MainActor
private func waitForDocuments(
    in store: DocumentStore,
    count: Int,
    timeoutNanoseconds: UInt64 = 2_000_000_000
) async throws {
    let start = DispatchTime.now().uptimeNanoseconds
    while DispatchTime.now().uptimeNanoseconds - start < timeoutNanoseconds {
        if store.documents.count == count && store.documents.allSatisfy({ !$0.isLoading }) {
            return
        }
        try await Task.sleep(nanoseconds: 20_000_000)
    }
    Issue.record("Timed out waiting for \(count) documents to finish loading.")
}

private func waitForRenderPasses(
    on renderService: MockDocumentRenderService,
    count: Int,
    timeoutNanoseconds: UInt64 = 2_000_000_000
) async throws {
    let start = DispatchTime.now().uptimeNanoseconds
    while DispatchTime.now().uptimeNanoseconds - start < timeoutNanoseconds {
        if renderService.segmentCallCount >= count {
            return
        }
        try await Task.sleep(nanoseconds: 20_000_000)
    }
    Issue.record("Timed out waiting for \(count) render passes.")
}
