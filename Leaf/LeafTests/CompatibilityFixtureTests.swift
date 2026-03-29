import Foundation
import Markdown
import Testing

struct CompatibilityFixtureTests {
    private let parser = MarkdownParser()
    private let service = RenderService()
    private let colors = LeafTheme.theme(for: .highContrast).colors
    private let metrics = LeafTheme.metrics(scale: 1.0)

    @Test func taskListFixtureParsesCheckboxes() throws {
        let document = parser.parse(try loadFixture(named: "task-lists"))
        let listItems = descendants(in: document, as: ListItem.self)

        #expect(listItems.count == 3)
        #expect(listItems.map(\.checkbox) == [.checked, .unchecked, .checked])
    }

    @Test func nestedListFixtureRendersIndentedChildren() throws {
        let document = parser.parse(try loadFixture(named: "lists-nested"))
        let (text, _) = service.buildFlatText(document: document, colors: colors, metrics: metrics)
        let rendered = String(text.characters)

        #expect(rendered.contains("• Parent bullet"))
        #expect(rendered.contains("    • Nested bullet one"))
        #expect(rendered.contains("1. Parent ordered"))
        #expect(rendered.contains("    1. Nested ordered one"))
    }

    @Test func taskListFixtureRendersCheckboxPrefixes() throws {
        let document = parser.parse(try loadFixture(named: "task-lists"))
        let (text, _) = service.buildFlatText(document: document, colors: colors, metrics: metrics)
        let rendered = String(text.characters)

        #expect(rendered.contains("[x] Ship renderer tests"))
        #expect(rendered.contains("[ ] Add nested list fixtures"))
    }

    @Test func autolinkFixtureBuildsInteractiveText() throws {
        let document = parser.parse(try loadFixture(named: "links-and-autolinks"))
        let segments = service.buildSegments(document: document, colors: colors, metrics: metrics, baseURL: nil)

        #expect(segments.count == 1)
        #expect(segments[0].isInteractive == true)
        guard case .text(let text) = segments[0].kind else {
            Issue.record("Expected text segment")
            return
        }

        #expect(String(text.characters).contains("Leaf Docs"))
        #expect(String(text.characters).contains("https://example.com/autolink"))
        #expect(String(text.characters).contains("https://example.com/angle-autolink"))
    }

    @Test func localImageFixtureResolvesRelativeAndAbsolutePaths() throws {
        let document = parser.parse(try loadFixture(named: "images-local"))
        let baseURL = URL(fileURLWithPath: "/tmp/compatibility")
        let segments = service.buildSegments(document: document, colors: colors, metrics: metrics, baseURL: baseURL)
        let images = segments.compactMap { segment -> RenderImage? in
            guard case .image(let image) = segment.kind else { return nil }
            return image
        }

        #expect(images.count == 2)
        #expect(images[0].resolvedURL?.path(percentEncoded: false).hasSuffix("/images/leaf-hero.png") == true)
        #expect(images[1].resolvedURL?.path(percentEncoded: false) == "/tmp/leaf-absolute.png")
    }

    @Test func imageEdgeFixtureKeepsInlineImagesReadableAndRemoteImagesBlocked() throws {
        let document = parser.parse(try loadFixture(named: "images-edge-cases"))
        let segments = service.buildSegments(document: document, colors: colors, metrics: metrics, baseURL: URL(fileURLWithPath: "/tmp/compatibility"))

        let imageSegments = segments.compactMap { segment -> RenderImage? in
            guard case .image(let image) = segment.kind else { return nil }
            return image
        }
        #expect(imageSegments.count == 2)
        #expect(imageSegments[0].isRemote == true)
        #expect(imageSegments[1].resolvedURL?.path(percentEncoded: false).hasSuffix("/missing.png") == true)

        let (flatText, _) = service.buildFlatText(document: document, colors: colors, metrics: metrics)
        #expect(String(flatText.characters).contains("[Image: Inline Leaf]"))
    }

    @Test func htmlFixtureFallsBackToReadableText() throws {
        let document = parser.parse(try loadFixture(named: "html-fallback"))
        let segments = service.buildSegments(document: document, colors: colors, metrics: metrics, baseURL: nil)

        #expect(segments.count == 2)
        guard case .codeBlock(let text, let language) = segments[0].kind else {
            Issue.record("Expected HTML block fallback segment")
            return
        }

        #expect(language == "html")
        #expect(String(text.characters).contains("<div class=\"leaf-callout\">"))

        let (flatText, _) = service.buildFlatText(document: document, colors: colors, metrics: metrics)
        #expect(String(flatText.characters).contains("<span class=\"accent\">this</span>"))
    }

    @Test func tableFixtureSupportsUnevenRowsAndAlignmentMetadata() throws {
        let document = parser.parse(try loadFixture(named: "tables"))
        let segments = service.buildSegments(document: document, colors: colors, metrics: metrics, baseURL: nil)
        let tables = segments.compactMap { segment -> RenderTable? in
            guard case .table(let table) = segment.kind else { return nil }
            return table
        }

        #expect(tables.count == 5)

        let unevenTable = tables[0]
        #expect(unevenTable.header.count == 3)
        #expect(unevenTable.alignments.count == 3)
        #expect(unevenTable.rows.count == 3)
        #expect(unevenTable.rows[2].count == 3)
        #expect(String(unevenTable.rows[2][2].characters).isEmpty)

        let numericTable = tables[3]
        #expect(numericTable.header.map { String($0.characters) } == ["Metric", "Q1", "Q2", "Q3"])
        #expect(numericTable.rows.count == 3)
    }
}

private func loadFixture(named name: String) throws -> String {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("test_markdown_files")
        .appendingPathComponent("compatibility")
        .appendingPathComponent("\(name).md")
    return try String(contentsOf: url, encoding: .utf8)
}

private func descendants<T: Markup>(in root: Markup, as type: T.Type) -> [T] {
    var matches: [T] = []

    func walk(_ node: Markup) {
        if let match = node as? T {
            matches.append(match)
        }
        for child in node.children {
            walk(child)
        }
    }

    walk(root)
    return matches
}
