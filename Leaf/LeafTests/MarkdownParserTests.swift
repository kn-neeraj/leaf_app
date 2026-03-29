import Markdown
import Testing

struct MarkdownParserTests {
    private let parser = MarkdownParser()

    @Test func parsesH1Heading() {
        let document = parser.parse("# Leaf")
        let headings = descendants(in: document, as: Heading.self)

        #expect(headings.count == 1)
        #expect(headings.first?.level == 1)
        #expect(headings.first?.plainText == "Leaf")
    }

    @Test func parsesMultipleHeadingLevels() {
        let document = parser.parse("# One\n\n## Two\n\n### Three")
        let headings = descendants(in: document, as: Heading.self)

        #expect(headings.map(\.level) == [1, 2, 3])
    }

    @Test func parsesStrongText() {
        let document = parser.parse("A **bold** word")
        let strong = descendants(in: document, as: Strong.self)

        #expect(strong.count == 1)
        #expect(strong.first?.plainText == "bold")
    }

    @Test func parsesItalicText() {
        let document = parser.parse("An *italic* word")
        let emphasis = descendants(in: document, as: Emphasis.self)

        #expect(emphasis.count == 1)
        #expect(emphasis.first?.plainText == "italic")
    }

    @Test func parsesInlineCode() {
        let document = parser.parse("Use `leaf` here")
        let inlineCode = descendants(in: document, as: InlineCode.self)

        #expect(inlineCode.count == 1)
        #expect(inlineCode.first?.code == "leaf")
    }

    @Test func parsesFencedCodeBlockWithLanguage() {
        let document = parser.parse("```swift\nlet leaf = true\n```")
        let codeBlocks = descendants(in: document, as: CodeBlock.self)

        #expect(codeBlocks.count == 1)
        #expect(codeBlocks.first?.language == "swift")
        #expect(codeBlocks.first?.code.trimmingCharacters(in: .whitespacesAndNewlines) == "let leaf = true")
    }

    @Test func parsesFencedCodeBlockWithoutLanguage() {
        let document = parser.parse("```\nplain block\n```")
        let codeBlocks = descendants(in: document, as: CodeBlock.self)

        #expect(codeBlocks.count == 1)
        #expect(codeBlocks.first?.language == nil)
        #expect(codeBlocks.first?.code.trimmingCharacters(in: .whitespacesAndNewlines) == "plain block")
    }

    @Test func parsesMixedInlineFormattingInSameParagraph() {
        let document = parser.parse("**bold** *italic* `code`")

        #expect(descendants(in: document, as: Strong.self).count == 1)
        #expect(descendants(in: document, as: Emphasis.self).count == 1)
        #expect(descendants(in: document, as: InlineCode.self).count == 1)
    }

    @Test func preservesMultilineCodeBlockContent() {
        let source = "```swift\nlet a = 1\nlet b = 2\n```"
        let document = parser.parse(source)
        let codeBlock = descendants(in: document, as: CodeBlock.self).first

        #expect(codeBlock?.code.contains("let a = 1") == true)
        #expect(codeBlock?.code.contains("let b = 2") == true)
    }

    @Test func parsesHeadingAndCodeBlocksTogether() {
        let source = "# Leaf\n\n```swift\nlet a = 1\n```\n\n```bash\necho leaf\n```"
        let document = parser.parse(source)

        #expect(descendants(in: document, as: Heading.self).count == 1)
        #expect(descendants(in: document, as: CodeBlock.self).map(\.language) == ["swift", "bash"])
    }
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
