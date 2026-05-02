import XCTest
@testable import Bonsai

final class ToolbarRevisionMenuCopyTests: XCTestCase {
  func testToolbarRevisionMenuGroupLabelsStayShortAndProfessional() {
    XCTAssertEqual(ToolbarRevisionMenuCopy.selectedCommitMenuTitle, "Selected Commit")
    XCTAssertEqual(ToolbarRevisionMenuCopy.currentOperationMenuTitle, "Current Operation")
    XCTAssertEqual(ToolbarRevisionMenuCopy.rebaseMenuTitle, "Rebase")
    XCTAssertEqual(ToolbarRevisionMenuCopy.bisectMenuTitle, "Bisect")

    XCTAssertEqual(Set(ToolbarRevisionMenuCopy.groupTitles).count, ToolbarRevisionMenuCopy.groupTitles.count)
    XCTAssertTrue(ToolbarRevisionMenuCopy.groupTitles.allSatisfy { $0.count <= 18 })
  }
}
