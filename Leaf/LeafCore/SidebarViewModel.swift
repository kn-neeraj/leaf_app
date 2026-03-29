//
//  SidebarViewModel.swift
//  Leaf
//

import Foundation

public final class SidebarViewModel: ObservableObject {
    @Published public var isExpanded: Bool
    @Published public var selectedDocumentID: UUID?

    public init(isExpanded: Bool = true, selectedDocumentID: UUID? = nil) {
        self.isExpanded = isExpanded
        self.selectedDocumentID = selectedDocumentID
    }

    public func toggleExpanded() {
        isExpanded.toggle()
    }

    public func expand() {
        isExpanded = true
    }

    public func collapse() {
        isExpanded = false
    }

    public func select(_ id: UUID?) {
        selectedDocumentID = id
    }
}
