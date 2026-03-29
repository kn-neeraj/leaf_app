import Foundation
import Testing

struct SidebarViewModelTests {
    @Test func startsExpandedByDefault() {
        let viewModel = SidebarViewModel()

        #expect(viewModel.isExpanded == true)
        #expect(viewModel.selectedDocumentID == nil)
    }

    @Test func togglesExpandedState() {
        let viewModel = SidebarViewModel()

        viewModel.toggleExpanded()
        #expect(viewModel.isExpanded == false)

        viewModel.toggleExpanded()
        #expect(viewModel.isExpanded == true)
    }

    @Test func supportsExplicitExpandCollapse() {
        let viewModel = SidebarViewModel(isExpanded: false)

        viewModel.expand()
        #expect(viewModel.isExpanded == true)

        viewModel.collapse()
        #expect(viewModel.isExpanded == false)
    }

    @Test func updatesSelectionState() {
        let viewModel = SidebarViewModel()
        let documentID = UUID()

        viewModel.select(documentID)
        #expect(viewModel.selectedDocumentID == documentID)

        viewModel.select(nil)
        #expect(viewModel.selectedDocumentID == nil)
    }
}
