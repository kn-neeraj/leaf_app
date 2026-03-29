//
//  RenderService.swift
//  Leaf
//

import Foundation
import Markdown

public protocol RenderServing {
    func buildSegments(
        document: Document,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics,
        baseURL: URL?
    ) -> [RenderSegment]

    func buildFlatText(
        document: Document,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics
    ) -> (AttributedString, Bool)
}

public struct RenderService: RenderServing {
    public init() {}

    public func buildSegments(
        document: Document,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics,
        baseURL: URL?
    ) -> [RenderSegment] {
        MarkdownRenderBuilder.buildSegments(
            document: document,
            colors: colors,
            metrics: metrics,
            baseURL: baseURL
        )
    }

    public func buildFlatText(
        document: Document,
        colors: LeafTheme.Colors,
        metrics: LeafTheme.Metrics
    ) -> (AttributedString, Bool) {
        MarkdownRenderBuilder.buildFlatText(
            document: document,
            colors: colors,
            metrics: metrics
        )
    }
}
