//
//  MarkdownRenderModel.swift
//  Leaf
//
//  Created by Neeraj Kumar on 24/01/26.
//

import Foundation
import Markdown
import SwiftUI

struct RenderBlock: Identifiable {
    let id: Int
    let kind: RenderBlockKind
    let isInteractive: Bool
}

enum RenderBlockKind {
    case heading(level: Int, text: String, isInQuote: Bool)
    case paragraph(text: AttributedString, isInteractive: Bool)
    case list(isOrdered: Bool, items: [RenderListItem])
    case blockQuote(children: [RenderBlock])
    case thematicBreak
}

struct RenderSegment: Identifiable {
    let id: Int
    let kind: RenderSegmentKind
    let isInteractive: Bool
}

enum RenderSegmentKind {
    case text(AttributedString)
    case codeBlock(text: AttributedString, language: String?)
    case table(RenderTable)
    case thematicBreak
    case image(RenderImage)
}

struct RenderImage {
    let source: String
    let resolvedURL: URL?
    let isRemote: Bool
    let altText: String
}

struct RenderTable {
    let header: [AttributedString]
    let rows: [[AttributedString]]
    let alignments: [Markdown.Table.ColumnAlignment?]
}

struct RenderListItem: Identifiable {
    let id: Int
    let text: AttributedString
    let isInteractive: Bool
}

struct MarkdownRenderBuilder {
    static func build(
        document: Document,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics
    ) -> [RenderBlock] {
        var nextId = 0
        return buildBlocks(
            children: document.children,
            colors: colors,
            metrics: metrics,
            isInQuote: false,
            nextId: &nextId
        )
    }

    static func buildSegments(
        document: Document,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics,
        baseURL: URL? = nil
    ) -> [RenderSegment] {
        var segments: [RenderSegment] = []
        var currentText = AttributedString()
        var currentHasLink = false
        var nextId = 0

        func appendSeparator() {
            var separator = AttributedString("\n\n")
            applyAttributes(
                &separator,
                style: InlineStyle(isInQuote: false),
                colors: colors,
                metrics: metrics
            )
            currentText.append(separator)
        }

        func appendTextBlock(_ block: AttributedString, hasLink: Bool) {
            if !currentText.characters.isEmpty {
                appendSeparator()
            }
            currentText.append(block)
            if hasLink {
                currentHasLink = true
            }
        }

        func flushText() {
            guard !currentText.characters.isEmpty else { return }
            segments.append(
                RenderSegment(
                    id: nextIdValue(&nextId),
                    kind: .text(currentText),
                    isInteractive: currentHasLink
                )
            )
            currentText = AttributedString()
            currentHasLink = false
        }

        for child in document.children {
            if let codeBlock = child as? CodeBlock {
                flushText()
                let highlighted = highlightedCode(
                    codeBlock.code,
                    language: codeBlock.language,
                    colors: colors,
                    metrics: metrics
                )
                segments.append(
                    RenderSegment(
                        id: nextIdValue(&nextId),
                        kind: .codeBlock(text: highlighted, language: codeBlock.language),
                        isInteractive: false
                    )
                )
            } else if let table = child as? Markdown.Table {
                flushText()
                let (renderTable, hasLink) = renderTable(table, colors: colors, metrics: metrics)
                segments.append(
                    RenderSegment(
                        id: nextIdValue(&nextId),
                        kind: .table(renderTable),
                        isInteractive: hasLink
                    )
                )
            } else if let paragraph = child as? Paragraph,
                      let images = imageOnlyParagraph(paragraph) {
                flushText()
                for image in images {
                    if let segment = renderImageSegment(
                        image,
                        baseURL: baseURL,
                        colors: colors,
                        metrics: metrics,
                        nextId: &nextId
                    ) {
                        segments.append(segment)
                    }
                }
            } else if child is ThematicBreak {
                flushText()
                segments.append(
                    RenderSegment(
                        id: nextIdValue(&nextId),
                        kind: .thematicBreak,
                        isInteractive: false
                    )
                )
            } else {
                let (text, hasLink) = flatBlockText(
                    for: child,
                    colors: colors,
                    metrics: metrics,
                    isInQuote: false
                )
                if !text.characters.isEmpty {
                    appendTextBlock(text, hasLink: hasLink)
                }
            }
        }

        flushText()
        return segments
    }

    static func buildFlatText(
        document: Document,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics
    ) -> (AttributedString, Bool) {
        buildFlatBlocks(
            children: document.children,
            colors: colors,
            metrics: metrics,
            isInQuote: false
        )
    }

    private static func buildBlocks(
        children: MarkupChildren,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics,
        isInQuote: Bool,
        nextId: inout Int
    ) -> [RenderBlock] {
        var blocks: [RenderBlock] = []
        for child in children {
            if let heading = child as? Heading {
                blocks.append(
                    RenderBlock(
                        id: nextIdValue(&nextId),
                        kind: .heading(level: heading.level, text: heading.plainText, isInQuote: isInQuote),
                        isInteractive: false
                    )
                )
            } else if let paragraph = child as? Paragraph {
                let (text, hasLink) = attributedString(
                    from: paragraph,
                    colors: colors,
                    metrics: metrics,
                    isInQuote: isInQuote
                )
                blocks.append(
                    RenderBlock(
                        id: nextIdValue(&nextId),
                        kind: .paragraph(text: text, isInteractive: hasLink),
                        isInteractive: hasLink
                    )
                )
            } else if let list = child as? UnorderedList {
                let items = renderListItems(
                    listItems: Array(list.listItems),
                    colors: colors,
                    metrics: metrics,
                    isInQuote: isInQuote,
                    nextId: &nextId
                )
                let isInteractive = items.contains { $0.isInteractive }
                blocks.append(
                    RenderBlock(
                        id: nextIdValue(&nextId),
                        kind: .list(isOrdered: false, items: items),
                        isInteractive: isInteractive
                    )
                )
            } else if let list = child as? OrderedList {
                let items = renderListItems(
                    listItems: Array(list.listItems),
                    colors: colors,
                    metrics: metrics,
                    isInQuote: isInQuote,
                    nextId: &nextId
                )
                let isInteractive = items.contains { $0.isInteractive }
                blocks.append(
                    RenderBlock(
                        id: nextIdValue(&nextId),
                        kind: .list(isOrdered: true, items: items),
                        isInteractive: isInteractive
                    )
                )
            } else if let quote = child as? BlockQuote {
                let quoteBlocks = buildBlocks(
                    children: quote.children,
                    colors: colors,
                    metrics: metrics,
                    isInQuote: true,
                    nextId: &nextId
                )
                let isInteractive = quoteBlocks.contains { $0.isInteractive }
                blocks.append(
                    RenderBlock(
                        id: nextIdValue(&nextId),
                        kind: .blockQuote(children: quoteBlocks),
                        isInteractive: isInteractive
                    )
                )
            } else if child is ThematicBreak {
                blocks.append(
                    RenderBlock(
                        id: nextIdValue(&nextId),
                        kind: .thematicBreak,
                        isInteractive: false
                    )
                )
            }
        }
        return blocks
    }

    private static func flatBlockText(
        for child: Markup,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics,
        isInQuote: Bool
    ) -> (AttributedString, Bool) {
        if let heading = child as? Heading {
            var text = AttributedString(heading.plainText)
            text.font = LeafTheme.headingFont(level: heading.level, scale: metrics.scale)
            text.foregroundColor = isInQuote ? colors.secondary : colors.text
            return (text, false)
        } else if let paragraph = child as? Paragraph {
            return attributedString(from: paragraph, colors: colors, metrics: metrics, isInQuote: isInQuote)
        } else if let list = child as? UnorderedList {
            let (listText, hasLink) = buildFlatList(
                listItems: Array(list.listItems),
                isOrdered: false,
                colors: colors,
                metrics: metrics,
                isInQuote: isInQuote
            )
            return (listText, hasLink)
        } else if let list = child as? OrderedList {
            let (listText, hasLink) = buildFlatList(
                listItems: Array(list.listItems),
                isOrdered: true,
                colors: colors,
                metrics: metrics,
                isInQuote: isInQuote
            )
            return (listText, hasLink)
        } else if let quote = child as? BlockQuote {
            let (quoteText, quoteHasLink) = buildFlatBlocks(
                children: quote.children,
                colors: colors,
                metrics: metrics,
                isInQuote: true
            )
            var prefix = AttributedString("> ")
            applyAttributes(
                &prefix,
                style: InlineStyle(isInQuote: true),
                colors: colors,
                metrics: metrics
            )
            var combined = prefix
            combined.append(quoteText)
            return (combined, quoteHasLink)
        } else if child is ThematicBreak {
            var divider = AttributedString("---")
            applyAttributes(
                &divider,
                style: InlineStyle(isInQuote: isInQuote),
                colors: colors,
                metrics: metrics
            )
            return (divider, false)
        }
        return (AttributedString(), false)
    }

    private static func buildFlatBlocks(
        children: MarkupChildren,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics,
        isInQuote: Bool
    ) -> (AttributedString, Bool) {
        var result = AttributedString()
        var hasLink = false
        var isFirstBlock = true

        func appendBlock(_ block: AttributedString) {
            if !isFirstBlock {
                var separator = AttributedString("\n\n")
                applyAttributes(
                    &separator,
                    style: InlineStyle(isInQuote: isInQuote),
                    colors: colors,
                    metrics: metrics
                )
                result.append(separator)
            }
            result.append(block)
            isFirstBlock = false
        }

        for child in children {
            if let heading = child as? Heading {
                var text = AttributedString(heading.plainText)
                text.font = LeafTheme.headingFont(level: heading.level, scale: metrics.scale)
                text.foregroundColor = isInQuote ? colors.secondary : colors.text
                appendBlock(text)
            } else if let paragraph = child as? Paragraph {
                let (text, containsLink) = attributedString(
                    from: paragraph,
                    colors: colors,
                    metrics: metrics,
                    isInQuote: isInQuote
                )
                appendBlock(text)
                if containsLink {
                    hasLink = true
                }
            } else if let list = child as? UnorderedList {
                let (listText, listHasLink) = buildFlatList(
                    listItems: Array(list.listItems),
                    isOrdered: false,
                    colors: colors,
                    metrics: metrics,
                    isInQuote: isInQuote
                )
                appendBlock(listText)
                if listHasLink {
                    hasLink = true
                }
            } else if let list = child as? OrderedList {
                let (listText, listHasLink) = buildFlatList(
                    listItems: Array(list.listItems),
                    isOrdered: true,
                    colors: colors,
                    metrics: metrics,
                    isInQuote: isInQuote
                )
                appendBlock(listText)
                if listHasLink {
                    hasLink = true
                }
            } else if let quote = child as? BlockQuote {
                let (quoteText, quoteHasLink) = buildFlatBlocks(
                    children: quote.children,
                    colors: colors,
                    metrics: metrics,
                    isInQuote: true
                )
                var prefix = AttributedString("> ")
                applyAttributes(
                    &prefix,
                    style: InlineStyle(isInQuote: true),
                    colors: colors,
                    metrics: metrics
                )
                var combined = prefix
                combined.append(quoteText)
                appendBlock(combined)
                if quoteHasLink {
                    hasLink = true
                }
            } else if child is ThematicBreak {
                var divider = AttributedString("---")
                applyAttributes(
                    &divider,
                    style: InlineStyle(isInQuote: isInQuote),
                    colors: colors,
                    metrics: metrics
                )
                appendBlock(divider)
            }
        }

        return (result, hasLink)
    }

    private static func buildFlatList(
        listItems: [ListItem],
        isOrdered: Bool,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics,
        isInQuote: Bool
    ) -> (AttributedString, Bool) {
        var result = AttributedString()
        var hasLink = false

        for (index, item) in listItems.enumerated() {
            if index > 0 {
                var separator = AttributedString("\n")
                applyAttributes(
                    &separator,
                    style: InlineStyle(isInQuote: isInQuote),
                    colors: colors,
                    metrics: metrics
                )
                result.append(separator)
            }

            let prefixText = isOrdered ? "\(index + 1). " : "• "
            var prefix = AttributedString(prefixText)
            var prefixAttributes = AttributeContainer()
            prefixAttributes.font = .system(size: metrics.bodyFontSize, weight: .semibold)
            prefixAttributes.foregroundColor = colors.accent
            prefix.mergeAttributes(prefixAttributes)
            result.append(prefix)

            let (text, containsLink) = attributedString(
                for: item,
                colors: colors,
                metrics: metrics,
                isInQuote: isInQuote
            )
            result.append(text)
            if containsLink {
                hasLink = true
            }
        }

        return (result, hasLink)
    }

    private static func renderTable(
        _ table: Markdown.Table,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics
    ) -> (RenderTable, Bool) {
        let (header, headerHasLink) = tableCells(
            table.head.cells,
            colors: colors,
            metrics: metrics
        )
        var rows: [[AttributedString]] = []
        var hasLink = headerHasLink
        for row in table.body.rows {
            let (rowCells, rowHasLink) = tableCells(row.cells, colors: colors, metrics: metrics)
            rows.append(rowCells)
            if rowHasLink {
                hasLink = true
            }
        }
        return (
            RenderTable(header: header, rows: rows, alignments: table.columnAlignments),
            hasLink
        )
    }

    private static func tableCells<Cells: Sequence>(
        _ cells: Cells,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics
    ) -> ([AttributedString], Bool) where Cells.Element == Markdown.Table.Cell {
        var rendered: [AttributedString] = []
        var hasLink = false
        for cell in cells {
            let (text, cellHasLink) = attributedString(
                from: cell.children,
                style: InlineStyle(isInQuote: false),
                colors: colors,
                metrics: metrics
            )
            rendered.append(text)
            if cellHasLink {
                hasLink = true
            }
        }
        return (rendered, hasLink)
    }

    private static func renderListItems(
        listItems: [ListItem],
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics,
        isInQuote: Bool,
        nextId: inout Int
    ) -> [RenderListItem] {
        listItems.map { item in
            let (text, hasLink) = attributedString(
                for: item,
                colors: colors,
                metrics: metrics,
                isInQuote: isInQuote
            )
            return RenderListItem(id: nextIdValue(&nextId), text: text, isInteractive: hasLink)
        }
    }

    private static func nextIdValue(_ nextId: inout Int) -> Int {
        nextId += 1
        return nextId
    }

    private struct InlineStyle {
        var isStrong = false
        var isEmphasis = false
        var isCode = false
        var link: URL?
        var isInQuote = false
    }

    private static func attributedString(
        from paragraph: Paragraph,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics,
        isInQuote: Bool
    ) -> (AttributedString, Bool) {
        let baseStyle = InlineStyle(isInQuote: isInQuote)
        return attributedString(from: paragraph.children, style: baseStyle, colors: colors, metrics: metrics)
    }

    private static func attributedString(
        for listItem: ListItem,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics,
        isInQuote: Bool
    ) -> (AttributedString, Bool) {
        let paragraphs = listItem.children.compactMap { $0 as? Paragraph }
        var result = AttributedString()
        var hasLink = false
        for (index, paragraph) in paragraphs.enumerated() {
            if index > 0 {
                var spacer = AttributedString(" ")
                applyAttributes(&spacer, style: InlineStyle(isInQuote: isInQuote), colors: colors, metrics: metrics)
                result.append(spacer)
            }
            let (text, containsLink) = attributedString(
                from: paragraph,
                colors: colors,
                metrics: metrics,
                isInQuote: isInQuote
            )
            result.append(text)
            if containsLink {
                hasLink = true
            }
        }
        return (result, hasLink)
    }

    private static func attributedString(
        from children: MarkupChildren,
        style: InlineStyle,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics
    ) -> (AttributedString, Bool) {
        var result = AttributedString()
        var hasLink = false
        for child in children {
            let (text, childHasLink) = attributedString(
                from: child,
                style: style,
                colors: colors,
                metrics: metrics
            )
            result.append(text)
            if childHasLink {
                hasLink = true
            }
        }
        return (result, hasLink)
    }

    private static func attributedString(
        from markup: Markup,
        style: InlineStyle,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics
    ) -> (AttributedString, Bool) {
        if let text = markup as? Markdown.Text {
            var attributed = AttributedString(text.string)
            applyAttributes(&attributed, style: style, colors: colors, metrics: metrics)
            return (attributed, style.link != nil)
        } else if markup is SoftBreak {
            var attributed = AttributedString(" ")
            applyAttributes(&attributed, style: style, colors: colors, metrics: metrics)
            return (attributed, style.link != nil)
        } else if markup is LineBreak {
            var attributed = AttributedString("\n")
            applyAttributes(&attributed, style: style, colors: colors, metrics: metrics)
            return (attributed, style.link != nil)
        } else if let emphasis = markup as? Emphasis {
            var nextStyle = style
            nextStyle.isEmphasis = true
            return attributedString(from: emphasis.children, style: nextStyle, colors: colors, metrics: metrics)
        } else if let strong = markup as? Strong {
            var nextStyle = style
            nextStyle.isStrong = true
            return attributedString(from: strong.children, style: nextStyle, colors: colors, metrics: metrics)
        } else if let inlineCode = markup as? InlineCode {
            var nextStyle = style
            nextStyle.isCode = true
            var attributed = AttributedString(inlineCode.plainText)
            applyAttributes(&attributed, style: nextStyle, colors: colors, metrics: metrics)
            attributed.backgroundColor = colors.codeBackground
            return (attributed, style.link != nil)
        } else if let link = markup as? Markdown.Link {
            var nextStyle = style
            if let destination = link.destination, let url = URL(string: destination) {
                nextStyle.link = url
            }
            let (text, _) = attributedString(from: link.children, style: nextStyle, colors: colors, metrics: metrics)
            return (text, nextStyle.link != nil)
        } else if let strikethrough = markup as? Strikethrough {
            var attributed = attributedString(from: strikethrough.children, style: style, colors: colors, metrics: metrics).0
            attributed.strikethroughStyle = .single
            return (attributed, style.link != nil)
        } else if !markup.isEmpty {
            return attributedString(from: markup.children, style: style, colors: colors, metrics: metrics)
        } else {
            return (AttributedString(), false)
        }
    }

    private static func applyAttributes(
        _ attributed: inout AttributedString,
        style: InlineStyle,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics
    ) {
        var attributes = AttributeContainer()
        attributes.font = LeafTheme.inlineFont(
            isStrong: style.isStrong,
            isEmphasis: style.isEmphasis,
            isCode: style.isCode,
            scale: metrics.scale
        )
        let baseColor = style.isInQuote ? colors.secondary : colors.text
        attributes.foregroundColor = style.link == nil ? baseColor : colors.accent
        if let link = style.link {
            attributes.link = link
            attributes.underlineStyle = .single
        }
        attributed.mergeAttributes(attributes)
    }

    private static func imageOnlyParagraph(_ paragraph: Paragraph) -> [Markdown.Image]? {
        var images: [Markdown.Image] = []
        for child in paragraph.children {
            if let image = child as? Markdown.Image {
                images.append(image)
            } else if child is SoftBreak || child is LineBreak {
                continue
            } else if let text = child as? Markdown.Text, text.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            } else {
                return nil
            }
        }
        return images.isEmpty ? nil : images
    }

    private static func renderImageSegment(
        _ image: Markdown.Image,
        baseURL: URL?,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics,
        nextId: inout Int
    ) -> RenderSegment? {
        guard let source = image.source else {
            return imageFallbackSegment(image, colors: colors, metrics: metrics, nextId: &nextId)
        }
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let isRemote = trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")
        let resolvedURL = resolveImageURL(source: trimmed, baseURL: baseURL)
        let altText = image.plainText
        return RenderSegment(
            id: nextIdValue(&nextId),
            kind: .image(
                RenderImage(
                    source: trimmed,
                    resolvedURL: resolvedURL,
                    isRemote: isRemote,
                    altText: altText
                )
            ),
            isInteractive: false
        )
    }

    private static func resolveImageURL(source: String, baseURL: URL?) -> URL? {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return nil
        }
        if trimmed.hasPrefix("file://") {
            return URL(string: trimmed)
        }
        if trimmed.hasPrefix("/") {
            return URL(fileURLWithPath: trimmed)
        }
        guard let baseURL else { return nil }
        return URL(fileURLWithPath: trimmed, relativeTo: baseURL).standardizedFileURL
    }

    private static func imageFallbackSegment(
        _ image: Markdown.Image,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics,
        nextId: inout Int
    ) -> RenderSegment? {
        let altText = image.plainText
        let fallback = altText.isEmpty ? "Image unavailable" : altText
        var attributed = AttributedString(fallback)
        applyAttributes(&attributed, style: InlineStyle(isInQuote: false), colors: colors, metrics: metrics)
        attributed.foregroundColor = colors.secondary
        return RenderSegment(
            id: nextIdValue(&nextId),
            kind: .text(attributed),
            isInteractive: false
        )
    }

    private static func highlightedCode(
        _ code: String,
        language: String?,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics
    ) -> AttributedString {
        var attributed = AttributedString(code)
        let baseFont = Font.system(size: metrics.codeFontSize, design: .monospaced)
        attributed.font = baseFont
        attributed.foregroundColor = colors.text

        let maxHighlightCharacters = 20000
        guard code.utf16.count <= maxHighlightCharacters else {
            return attributed
        }

        let lowercased = language?.lowercased() ?? ""
        let usesSlashComments = lowercased.contains("swift")
            || lowercased.contains("js")
            || lowercased.contains("javascript")
            || lowercased.contains("ts")
            || lowercased.contains("typescript")
            || lowercased.contains("c")
            || lowercased.contains("cpp")
            || lowercased.contains("java")
        let usesHashComments = lowercased.contains("py")
            || lowercased.contains("python")
            || lowercased.contains("sh")
            || lowercased.contains("bash")
            || lowercased.contains("shell")
            || lowercased.contains("zsh")
        let isJSON = lowercased.contains("json")

        var keywordPattern: String?
        if lowercased.contains("swift") {
            keywordPattern = "\\\\b(class|struct|enum|protocol|extension|func|let|var|if|else|for|while|return|import|try|catch|throw|throws|guard|in|do|switch|case|default|break|continue|public|private|internal|open|static|final|defer|where|as|is|nil|true|false)\\\\b"
        } else if lowercased.contains("js") || lowercased.contains("javascript") || lowercased.contains("ts") || lowercased.contains("typescript") {
            keywordPattern = "\\\\b(const|let|var|function|return|if|else|for|while|switch|case|break|continue|class|extends|new|try|catch|finally|throw|import|export|from|async|await|true|false|null|undefined)\\\\b"
        } else if lowercased.contains("py") || lowercased.contains("python") {
            keywordPattern = "\\\\b(def|class|return|if|elif|else|for|while|try|except|finally|import|from|as|with|lambda|pass|break|continue|True|False|None)\\\\b"
        } else if lowercased.contains("sh") || lowercased.contains("bash") || lowercased.contains("shell") || lowercased.contains("zsh") {
            keywordPattern = "\\\\b(if|then|fi|for|in|do|done|case|esac|function|return|exit)\\\\b"
        } else if isJSON {
            keywordPattern = nil
        }

        let keywordColor = colors.accent
        let stringColor = colors.accent.opacity(0.8)
        let numberColor = colors.accent.opacity(0.65)
        let commentColor = colors.secondary

        if let pattern = keywordPattern {
            applyHighlight(pattern: pattern, to: &attributed, in: code, color: keywordColor)
        }
        applyHighlight(pattern: "\\\\b\\\\d+(?:\\\\.\\\\d+)?\\\\b", to: &attributed, in: code, color: numberColor)
        applyHighlight(pattern: "\"(?:\\\\\\\\.|[^\"\\\\\\\\])*\"", to: &attributed, in: code, color: stringColor)
        applyHighlight(pattern: "'(?:\\\\\\\\.|[^'\\\\\\\\])*'", to: &attributed, in: code, color: stringColor)
        if usesSlashComments {
            applyHighlight(pattern: "//.*", to: &attributed, in: code, color: commentColor, options: [.anchorsMatchLines])
            applyHighlight(pattern: "/\\\\*[\\\\s\\\\S]*?\\\\*/", to: &attributed, in: code, color: commentColor)
        }
        if usesHashComments {
            applyHighlight(pattern: "#.*", to: &attributed, in: code, color: commentColor, options: [.anchorsMatchLines])
        }

        return attributed
    }

    private static func applyHighlight(
        pattern: String,
        to attributed: inout AttributedString,
        in code: String,
        color: Color,
        options: NSRegularExpression.Options = []
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return
        }
        let range = NSRange(code.startIndex..<code.endIndex, in: code)
        for match in regex.matches(in: code, range: range) {
            guard let stringRange = Range(match.range, in: code),
                  let start = AttributedString.Index(stringRange.lowerBound, within: attributed),
                  let end = AttributedString.Index(stringRange.upperBound, within: attributed) else {
                continue
            }
            attributed[start..<end].foregroundColor = color
        }
    }
}
