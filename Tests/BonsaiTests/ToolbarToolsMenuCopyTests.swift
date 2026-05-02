import XCTest
@testable import Bonsai

final class ToolbarToolsMenuCopyTests: XCTestCase {
  func testToolbarToolsMenuGroupLabelsStayShortAndProfessional() {
    XCTAssertEqual(ToolbarToolsMenuCopy.inspectMenuTitle, "Inspect")
    XCTAssertEqual(ToolbarToolsMenuCopy.patchMenuTitle, "Patch")
    XCTAssertEqual(ToolbarToolsMenuCopy.fileMenuTitle, "File")
    XCTAssertEqual(ToolbarToolsMenuCopy.repositoryMenuTitle, "Repository")
    XCTAssertEqual(ToolbarToolsMenuCopy.integrationsMenuTitle, "Integrations")

    XCTAssertEqual(Set(ToolbarToolsMenuCopy.groupTitles).count, ToolbarToolsMenuCopy.groupTitles.count)
    XCTAssertTrue(ToolbarToolsMenuCopy.groupTitles.allSatisfy { $0.count <= 12 })
  }
}
