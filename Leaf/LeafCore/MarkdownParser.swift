//
//  MarkdownParser.swift
//  Leaf
//

import Markdown

public protocol MarkdownParsing {
    func parse(_ content: String) -> Document
}

public struct MarkdownParser: MarkdownParsing {
    public init() {}

    public func parse(_ content: String) -> Document {
        Document(parsing: content)
    }
}
