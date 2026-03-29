//
//  MarkdownView.swift
//  Leaf
//
//  Created by Neeraj Kumar on 24/01/26.
//

import AppKit
import Markdown
import SwiftUI

struct MarkdownView: View {
    let blocks: [RenderBlock]
    let colors: LeafTheme.Colors
    let metrics: LeafTheme.Metrics

    var body: some View {
        LazyVStack(alignment: .leading, spacing: metrics.paragraphSpacing) {
            ForEach(blocks) { block in
                RenderBlockView(block: block, colors: colors, metrics: metrics)
            }
        }
    }
}

struct MarkdownSegmentedView: View {
    let segments: [RenderSegment]
    let colors: LeafTheme.Colors
    let metrics: LeafTheme.Metrics
    let isSelectionEnabled: Bool

    var body: some View {
        LazyVStack(alignment: .leading, spacing: metrics.paragraphSpacing) {
            ForEach(segments) { segment in
                RenderSegmentView(
                    segment: segment,
                    colors: colors,
                    metrics: metrics,
                    isSelectionEnabled: isSelectionEnabled
                )
            }
        }
        .conditionalTextSelection(isSelectionEnabled)
    }
}

struct RenderBlockView: View {
    let block: RenderBlock
    let colors: LeafTheme.Colors
    let metrics: LeafTheme.Metrics

    var body: some View {
        Group {
            switch block.kind {
            case .heading(let level, let text, let isInQuote):
                Text(text)
                    .font(LeafTheme.headingFont(level: level, scale: metrics.scale))
                    .foregroundStyle(isInQuote ? colors.secondary : colors.text)
                    .padding(.top, headingTopPadding(level: level))
                    .allowsHitTesting(false)
            case .paragraph(let text, let isInteractive):
                Text(text)
                    .lineSpacing(metrics.lineSpacing)
                    .allowsHitTesting(isInteractive)
                    .linkCursor(isInteractive)
            case .list(let isOrdered, let items):
                listView(items, isOrdered: isOrdered)
            case .blockQuote(let children):
                blockQuoteView(children)
            case .thematicBreak:
                Rectangle()
                    .fill(colors.quoteBorder)
                    .frame(height: 1)
            }
        }
        .allowsHitTesting(block.isInteractive)
    }

    private func listView(_ items: [RenderListItem], isOrdered: Bool) -> some View {
        VStack(alignment: .leading, spacing: metrics.listSpacing) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HStack(alignment: .top, spacing: 8) {
                    Text(isOrdered ? "\(index + 1)." : "•")
                        .font(.system(size: metrics.bodyFontSize, weight: .semibold))
                        .foregroundStyle(colors.accent)
                    Text(item.text)
                        .lineSpacing(metrics.lineSpacing)
                        .linkCursor(item.isInteractive)
                }
                .allowsHitTesting(item.isInteractive)
            }
        }
    }

    private func headingTopPadding(level: Int) -> CGFloat {
        let base: CGFloat
        switch level {
        case 1:
            base = 20
        case 2:
            base = 18
        case 3:
            base = 16
        default:
            base = 12
        }
        return base * metrics.scale
    }

    private func blockQuoteView(_ children: [RenderBlock]) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(colors.quoteBorder)
                .frame(width: 3)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: metrics.listSpacing) {
                ForEach(children) { child in
                    RenderBlockView(block: child, colors: colors, metrics: metrics)
                }
            }
        }
        .padding(.vertical, 4 * metrics.scale)
    }
}

struct RenderSegmentView: View {
    let segment: RenderSegment
    let colors: LeafTheme.Colors
    let metrics: LeafTheme.Metrics
    let isSelectionEnabled: Bool

    var body: some View {
        switch segment.kind {
        case .text(let text):
            Text(text)
                .lineSpacing(metrics.lineSpacing)
                .conditionalTextSelection(isSelectionEnabled)
                .allowsHitTesting(isSelectionEnabled || segment.isInteractive)
                .linkCursor(segment.isInteractive && !isSelectionEnabled)
        case .codeBlock(let text, _):
            MarkdownCodeBlockView(text: text, colors: colors, metrics: metrics)
        case .table(let table):
            MarkdownTableView(
                table: table,
                colors: colors,
                metrics: metrics,
                isSelectionEnabled: isSelectionEnabled
            )
            .allowsHitTesting(isSelectionEnabled || segment.isInteractive)
            .linkCursor(segment.isInteractive && !isSelectionEnabled)
        case .thematicBreak:
            Rectangle()
                .fill(colors.quoteBorder)
                .frame(height: 1)
                .allowsHitTesting(false)
        case .image(let renderImage):
            MarkdownImageView(renderImage: renderImage, colors: colors, metrics: metrics)
        }
    }
}

struct MarkdownCodeBlockView: View {
    let text: AttributedString
    let colors: LeafTheme.Colors
    let metrics: LeafTheme.Metrics

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Text(text)
                .lineSpacing(max(2, metrics.lineSpacing * 0.6))
                .textSelection(.enabled)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 10 * metrics.scale)
        .padding(.horizontal, 12 * metrics.scale)
        .background(
            RoundedRectangle(cornerRadius: 8 * metrics.scale)
                .fill(colors.codeBackground)
        )
    }
}

struct MarkdownTableView: View {
    let table: RenderTable
    let colors: LeafTheme.Colors
    let metrics: LeafTheme.Metrics
    let isSelectionEnabled: Bool

    private var columnCount: Int {
        let headerCount = table.header.count
        let rowCount = table.rows.map { $0.count }.max() ?? 0
        let alignmentCount = table.alignments.count
        return max(headerCount, rowCount, alignmentCount)
    }

    private var columnWidths: [CGFloat] {
        (0..<columnCount).map(preferredWidthForColumn)
    }

    private var totalTableWidth: CGFloat {
        let dividerWidth = CGFloat(max(0, columnCount - 1))
        let horizontalPadding = CGFloat(columnCount) * (20 * metrics.scale)
        return columnWidths.reduce(0, +) + dividerWidth + horizontalPadding
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                tableRow(table.header, isHeader: true)
                ForEach(table.rows.indices, id: \.self) { index in
                    Rectangle()
                        .fill(colors.quoteBorder)
                        .frame(height: 1)
                    tableRow(table.rows[index], isHeader: false)
                }
            }
            .frame(width: totalTableWidth, alignment: .leading)
            .background(colors.codeBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8 * metrics.scale))
            .overlay(
                RoundedRectangle(cornerRadius: 8 * metrics.scale)
                    .stroke(colors.quoteBorder, lineWidth: 1)
            )
        }
    }

    private func tableRow(_ cells: [AttributedString], isHeader: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(0..<columnCount, id: \.self) { column in
                tableCell(cells, column: column, isHeader: isHeader)
                if column < columnCount - 1 {
                    Rectangle()
                        .fill(colors.quoteBorder)
                        .frame(width: 1)
                }
            }
        }
    }

    private func tableCell(_ cells: [AttributedString], column: Int, isHeader: Bool) -> some View {
        let alignment = alignmentForColumn(column)
        let textAlignment = textAlignmentForColumn(column)
        let text = column < cells.count ? String(cells[column].characters) : ""
        let lineSpacing = max(2, metrics.lineSpacing * 0.6)
        let width = columnWidths[column]
        let background = isHeader ? colors.codeBackground.opacity(0.6) : Color.clear
        let fontWeight: Font.Weight = isHeader ? .semibold : .regular

        return VStack(alignment: horizontalAlignment(for: alignment), spacing: 0) {
            Text(verbatim: text)
                .font(.system(size: metrics.bodyFontSize, weight: fontWeight))
                .foregroundStyle(colors.text)
                .lineSpacing(lineSpacing)
                .lineLimit(nil)
                .multilineTextAlignment(textAlignment)
                .conditionalTextSelection(isSelectionEnabled)
                .frame(maxWidth: .infinity, alignment: alignment)
        }
        .frame(width: width, alignment: alignment)
        .padding(.vertical, 8 * metrics.scale)
        .padding(.horizontal, 10 * metrics.scale)
        .background(background)
    }

    private func alignmentForColumn(_ column: Int) -> Alignment {
        guard column < table.alignments.count else { return .leading }
        switch table.alignments[column] ?? .left {
        case .left:
            return .leading
        case .center:
            return .center
        case .right:
            return .trailing
        }
    }

    private func textAlignmentForColumn(_ column: Int) -> TextAlignment {
        guard column < table.alignments.count else { return .leading }
        switch table.alignments[column] ?? .left {
        case .left:
            return .leading
        case .center:
            return .center
        case .right:
            return .trailing
        }
    }

    private func preferredWidthForColumn(_ column: Int) -> CGFloat {
        let contents = ([table.header] + table.rows).map { row -> String in
            guard column < row.count else { return "" }
            return String(row[column].characters)
        }
        let wrapCap = 320 * metrics.scale
        let minWidth = max(120 * metrics.scale, metrics.bodyFontSize * 6)

        let measuredCells = contents
            .map { text in
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                let fullWidth = measureTableTextWidth(trimmed)
                let longestTokenWidth = trimmed
                    .split(whereSeparator: \.isWhitespace)
                    .map(String.init)
                    .map(measureTableTextWidth)
                    .max() ?? fullWidth
                let containsWhitespace = trimmed.contains { $0.isWhitespace }
                return (
                    fullWidth: fullWidth,
                    longestTokenWidth: longestTokenWidth,
                    containsWhitespace: containsWhitespace
                )
            }

        let widestToken = measuredCells.map(\.longestTokenWidth).max() ?? 0
        let widestFullCell = measuredCells.map(\.fullWidth).max() ?? 0
        let hasLongProse = measuredCells.contains { $0.containsWhitespace && $0.fullWidth > wrapCap }

        let contentWidth: CGFloat
        if hasLongProse {
            contentWidth = max(widestToken, min(widestFullCell, wrapCap))
        } else {
            contentWidth = max(widestToken, widestFullCell)
        }

        return max(contentWidth, minWidth)
    }

    private func measureTableTextWidth(_ text: String) -> CGFloat {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }

        let font = NSFont.systemFont(ofSize: metrics.bodyFontSize)
        return ceil((trimmed as NSString).size(withAttributes: [.font: font]).width)
    }

    private func horizontalAlignment(for alignment: Alignment) -> HorizontalAlignment {
        switch alignment {
        case .center:
            return .center
        case .trailing:
            return .trailing
        default:
            return .leading
        }
    }
}

struct MarkdownImageView: View {
    let renderImage: RenderImage
    let colors: LeafTheme.Colors
    let metrics: LeafTheme.Metrics

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 10 * metrics.scale)
                .fill(colors.codeBackground)
                .frame(width: 44 * metrics.scale, height: 44 * metrics.scale)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 18 * metrics.scale, weight: .semibold))
                        .foregroundStyle(colors.accent)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(displayTitle)
                    .font(.system(size: metrics.bodyFontSize, weight: .semibold))
                    .foregroundStyle(colors.text)

                Text(renderImage.source)
                    .font(.system(size: max(12, metrics.bodyFontSize * 0.8)))
                    .foregroundStyle(colors.secondary)
                    .lineLimit(2)

                if let statusText = statusText {
                    Text(statusText)
                        .font(.system(size: max(11, metrics.bodyFontSize * 0.75)))
                        .foregroundStyle(colors.secondary)
                }

                if let url = renderImage.resolvedURL, !renderImage.isRemote {
                    Button("Reveal") {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                    .font(.system(size: max(12, metrics.bodyFontSize * 0.8), weight: .semibold))
                    .buttonStyle(.borderless)
                    .foregroundStyle(colors.accent)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12 * metrics.scale)
        .background(
            RoundedRectangle(cornerRadius: 12 * metrics.scale)
                .fill(colors.codeBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12 * metrics.scale)
                .stroke(colors.quoteBorder, lineWidth: 1)
        )
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var displayTitle: String {
        if !renderImage.altText.isEmpty {
            return renderImage.altText
        }
        let trimmed = renderImage.source.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), url.scheme != nil {
            return url.lastPathComponent.isEmpty ? "Image" : url.lastPathComponent
        }
        let name = (trimmed as NSString).lastPathComponent
        return name.isEmpty ? "Image" : name
    }

    private var statusText: String? {
        if renderImage.isRemote {
            return "Remote images are blocked."
        }
        if renderImage.resolvedURL == nil {
            return "Image not found."
        }
        return nil
    }

    private var accessibilityLabel: String {
        if !renderImage.altText.isEmpty {
            return renderImage.altText
        }
        return "Image"
    }
}

extension View {
    @ViewBuilder
    func linkCursor(_ isEnabled: Bool) -> some View {
        if isEnabled {
            self.onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        } else {
            self
        }
    }
}

private extension View {
    @ViewBuilder
    func conditionalTextSelection(_ isEnabled: Bool) -> some View {
        if isEnabled {
            self.textSelection(.enabled)
        } else {
            self
        }
    }
}

#Preview {
    let document = Document(parsing: "# Heading\n\nBody text.")
    let colors = LeafTheme.theme(for: .highContrast).colors
    let metrics = LeafTheme.metrics(scale: 1.0)
    let blocks = MarkdownRenderBuilder.build(document: document, colors: colors, metrics: metrics)
    MarkdownView(blocks: blocks, colors: colors, metrics: metrics)
        .padding()
}
