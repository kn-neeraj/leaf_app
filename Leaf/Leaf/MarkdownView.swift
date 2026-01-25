//
//  MarkdownView.swift
//  Leaf
//
//  Created by Neeraj Kumar on 24/01/26.
//

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

    var body: some View {
        LazyVStack(alignment: .leading, spacing: metrics.paragraphSpacing) {
            ForEach(segments) { segment in
                RenderSegmentView(segment: segment, colors: colors, metrics: metrics)
            }
        }
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

    var body: some View {
        switch segment.kind {
        case .text(let text):
            Text(text)
                .lineSpacing(metrics.lineSpacing)
                .allowsHitTesting(segment.isInteractive)
        case .codeBlock(let text, _):
            MarkdownCodeBlockView(text: text, colors: colors, metrics: metrics)
        case .table(let table):
            MarkdownTableView(table: table, colors: colors, metrics: metrics)
                .allowsHitTesting(segment.isInteractive)
        }
    }
}

struct MarkdownCodeBlockView: View {
    let text: String
    let colors: LeafTheme.Colors
    let metrics: LeafTheme.Metrics

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Text(text)
                .font(.system(size: metrics.codeFontSize, design: .monospaced))
                .foregroundStyle(colors.text)
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

    private var columnCount: Int {
        let headerCount = table.header.count
        let rowCount = table.rows.map { $0.count }.max() ?? 0
        let alignmentCount = table.alignments.count
        return max(headerCount, rowCount, alignmentCount)
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
            .background(colors.codeBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8 * metrics.scale))
            .overlay(
                RoundedRectangle(cornerRadius: 8 * metrics.scale)
                    .stroke(colors.quoteBorder, lineWidth: 1)
            )
        }
    }

    private func tableRow(_ cells: [AttributedString], isHeader: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<columnCount, id: \.self) { column in
                let alignment = alignmentForColumn(column)
                let text = column < cells.count ? cells[column] : AttributedString("")
                Text(text)
                    .lineSpacing(max(2, metrics.lineSpacing * 0.6))
                    .frame(maxWidth: .infinity, alignment: alignment)
                    .padding(.vertical, 8 * metrics.scale)
                    .padding(.horizontal, 10 * metrics.scale)
                    .background(isHeader ? colors.codeBackground.opacity(0.6) : Color.clear)
                if column < columnCount - 1 {
                    Rectangle()
                        .fill(colors.quoteBorder)
                        .frame(width: 1)
                }
            }
        }
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
}

#Preview {
    let document = Document(parsing: "# Heading\n\nBody text.")
    let colors = LeafTheme.theme(for: .highContrast).colors
    let metrics = LeafTheme.metrics(scale: 1.0)
    let blocks = MarkdownRenderBuilder.build(document: document, colors: colors, metrics: metrics)
    MarkdownView(blocks: blocks, colors: colors, metrics: metrics)
        .padding()
}
