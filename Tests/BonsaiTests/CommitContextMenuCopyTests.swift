import XCTest
@testable import Bonsai

final class CommitContextMenuCopyTests: XCTestCase {
  func testCommitContextMenuGroupLabelsStayShortAndProfessional() {
    XCTAssertEqual(CommitContextMenuCopy.revisionMenuTitle, "Revision")
    XCTAssertEqual(CommitContextMenuCopy.createMenuTitle, "Create")
    XCTAssertEqual(CommitContextMenuCopy.hostingMenuTitle, "Hosting")
    XCTAssertEqual(CommitContextMenuCopy.copyMenuTitle, "Copy")

    XCTAssertEqual(Set(CommitContextMenuCopy.topLevelTitles).count, CommitContextMenuCopy.topLevelTitles.count)
    XCTAssertTrue(CommitContextMenuCopy.topLevelTitles.allSatisfy { $0.count <= 12 })
  }
}
