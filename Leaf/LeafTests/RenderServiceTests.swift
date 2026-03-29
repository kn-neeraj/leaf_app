import Foundation
import Markdown
import Testing

struct RenderServiceTests {
    private let parser = MarkdownParser()
    private let service = RenderService()
    private let colors = LeafTheme.theme(for: .highContrast).colors
    private let metrics = LeafTheme.metrics(scale: 1.0)

    @Test func rendersPlainTextIntoAttributedString() {
        let document = parser.parse("Leaf reader")
        let (text, hasLink) = service.buildFlatText(document: document, colors: colors, metrics: metrics)

        #expect(String(text.characters) == "Leaf reader")
        #expect(hasLink == false)
    }

    @Test func rendersInlineTokensIntoAttributedString() {
        let document = parser.parse("**Bold** *italic* `code`")
        let (text, _) = service.buildFlatText(document: document, colors: colors, metrics: metrics)

        #expect(String(text.characters) == "Bold italic code")
    }

    @Test func rendersCodeBlockSegment() {
        let document = parser.parse("```swift\nlet leaf = true\n```")
        let segments = service.buildSegments(document: document, colors: colors, metrics: metrics, baseURL: nil)

        #expect(segments.count == 1)
        guard case .codeBlock(let text, let language) = segments[0].kind else {
            Issue.record("Expected a code block segment")
            return
        }

        #expect(language == "swift")
        #expect(String(text.characters).contains("let leaf = true"))
    }

    @Test func rendersLinkTextAsInteractive() {
        let document = parser.parse("[Leaf](https://example.com)")
        let segments = service.buildSegments(document: document, colors: colors, metrics: metrics, baseURL: nil)

        #expect(segments.count == 1)
        #expect(segments[0].isInteractive == true)
        guard case .text(let text) = segments[0].kind else {
            Issue.record("Expected a text segment")
            return
        }
        #expect(String(text.characters) == "Leaf")
    }

    @Test func rendersThematicBreakAsDedicatedSegment() {
        let document = parser.parse("Before\n\n---\n\nAfter")
        let segments = service.buildSegments(document: document, colors: colors, metrics: metrics, baseURL: nil)

        #expect(segments.count == 3)
        guard case .thematicBreak = segments[1].kind else {
            Issue.record("Expected a thematic break segment in the middle")
            return
        }
    }

    @Test func rendersTableAsStructuredSegment() {
        let document = parser.parse("""
        | Name | Role |
        | --- | --- |
        | Leaf | Reader |
        """)
        let segments = service.buildSegments(document: document, colors: colors, metrics: metrics, baseURL: nil)

        #expect(segments.count == 1)
        guard case .table(let table) = segments[0].kind else {
            Issue.record("Expected a table segment")
            return
        }

        #expect(table.header.map { String($0.characters) } == ["Name", "Role"])
        #expect(table.rows.count == 1)
        #expect(table.rows.first?.map { String($0.characters) } == ["Leaf", "Reader"])
    }

    @Test func rendersLocalImageWithResolvedBaseURL() {
        let document = parser.parse("![Leaf Alt](images/leaf.png)")
        let baseURL = URL(fileURLWithPath: "/tmp/docs")
        let segments = service.buildSegments(document: document, colors: colors, metrics: metrics, baseURL: baseURL)

        #expect(segments.count == 1)
        guard case .image(let image) = segments[0].kind else {
            Issue.record("Expected an image segment")
            return
        }

        #expect(image.altText == "Leaf Alt")
        #expect(image.isRemote == false)
        #expect(image.resolvedURL?.lastPathComponent == "leaf.png")
        #expect(image.resolvedURL?.path(percentEncoded: false).hasSuffix("/images/leaf.png") == true)
    }

    @Test func rendersInlineImageAsReadableFallbackText() {
        let document = parser.parse("Before ![Leaf Alt](images/leaf.png) after")
        let (text, hasLink) = service.buildFlatText(document: document, colors: colors, metrics: metrics)
        let rendered = String(text.characters)

        #expect(rendered.contains("Before"))
        #expect(rendered.contains("[Image: Leaf Alt]"))
        #expect(rendered.contains("after"))
        #expect(hasLink == false)
    }

    @Test func rendersHTMLBlockAsCodeStyleFallbackSegment() {
        let document = parser.parse("<div class=\"leaf\">HTML block</div>")
        let segments = service.buildSegments(document: document, colors: colors, metrics: metrics, baseURL: nil)

        #expect(segments.count == 1)
        guard case .codeBlock(let text, let language) = segments[0].kind else {
            Issue.record("Expected HTML fallback code block segment")
            return
        }

        #expect(language == "html")
        #expect(String(text.characters).contains("<div class=\"leaf\">HTML block</div>"))
    }

    @Test func rendersInlineHTMLAsReadableFallbackText() {
        let document = parser.parse("Leaf <span>inline</span> HTML")
        let (text, _) = service.buildFlatText(document: document, colors: colors, metrics: metrics)

        #expect(String(text.characters).contains("<span>inline</span>"))
    }

    @Test func preservesAutolinkAsInteractiveText() {
        let document = parser.parse("https://example.com/autolink")
        let segments = service.buildSegments(document: document, colors: colors, metrics: metrics, baseURL: nil)

        #expect(segments.count == 1)
        #expect(segments[0].isInteractive == true)
        guard case .text(let text) = segments[0].kind else {
            Issue.record("Expected text segment for autolink")
            return
        }
        #expect(String(text.characters).contains("https://example.com/autolink"))
    }

    @Test func preservesTableAlignmentAndUnevenRows() {
        let document = parser.parse("""
        | Name | Role | Status |
        | --- | :---: | ---: |
        | Leaf | Reader | Stable |
        | Uneven | Missing trailing cell | |
        """)
        let segments = service.buildSegments(document: document, colors: colors, metrics: metrics, baseURL: nil)

        #expect(segments.count == 1)
        guard case .table(let table) = segments[0].kind else {
            Issue.record("Expected table segment")
            return
        }

        #expect(table.alignments.count == 3)
        #expect(table.rows.count == 2)
        #expect(table.rows[1].count == 3)
        #expect(String(table.rows[1][0].characters) == "Uneven")
        #expect(String(table.rows[1][2].characters).isEmpty)
    }

    @Test func rendersListsAndQuotesIntoReadableFlatText() {
        let document = parser.parse("""
        > Quoted line

        - First
        - Second
        """)
        let (text, hasLink) = service.buildFlatText(document: document, colors: colors, metrics: metrics)
        let rendered = String(text.characters)

        #expect(rendered.contains("Quoted line"))
        #expect(rendered.contains("First"))
        #expect(rendered.contains("Second"))
        #expect(hasLink == false)
    }
}
