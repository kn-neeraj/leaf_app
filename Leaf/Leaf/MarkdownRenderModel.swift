//
//  MarkdownRenderModel.swift
//  Leaf
//
//  Created by Neeraj Kumar on 24/01/26.
//

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
    case codeBlock(text: String, language: String?)
    case table(RenderTable)
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
        metrics: LeafTheme.Metrics
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
                segments.append(
                    RenderSegment(
                        id: nextIdValue(&nextId),
                        kind: .codeBlock(text: codeBlock.code, language: codeBlock.language),
                        isInteractive: true
                    )
                )
            } else if let table = child as? Markdown.Table {
                flushText()
                let (renderTable, _) = renderTable(table, colors: colors, metrics: metrics)
                segments.append(
                    RenderSegment(
                        id: nextIdValue(&nextId),
                        kind: .table(renderTable),
                        isInteractive: true
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
}
