import XCTest
@testable import Bonsai

final class SidebarInfrastructureCopyTests: XCTestCase {
  func testWorktreeDisclosureCopyUsesNounLabels() {
    XCTAssertEqual(SidebarInfrastructureCopy.worktreesTitle(count: 0), "No linked worktrees")
    XCTAssertEqual(SidebarInfrastructureCopy.worktreesTitle(count: 2), "Linked worktrees")
  }

  func testRemoteDisclosureCopyUsesConfiguredState() {
    XCTAssertEqual(SidebarInfrastructureCopy.remotesTitle(count: 0), "No configured remotes")
    XCTAssertEqual(SidebarInfrastructureCopy.remotesTitle(count: 1), "Configured remotes")
  }

  func testSubmoduleDisclosureCopyUsesRepositoryCategory() {
    XCTAssertEqual(SidebarInfrastructureCopy.submodulesTitle(count: 0), "No submodules")
    XCTAssertEqual(SidebarInfrastructureCopy.submodulesTitle(count: 3), "Repository submodules")
  }
}
