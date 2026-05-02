import XCTest
@testable import Bonsai

final class BranchWorktreeIndicatorTests: XCTestCase {
  func testCurrentBranchKeepsCheckmarkPriority() {
    let branch = GitRef(
      name: "refs/heads/main",
      shortName: "main",
      objectName: "abc123",
      isHead: true,
      kind: .localBranch
    )
    let worktree = GitWorktree(
      path: "/repo/linked-main",
      head: "abc123",
      branch: "refs/heads/main",
      isDetached: false,
      isBare: false,
      isPrunable: false
    )

    let indicator = BranchWorktreeIndicator(
      branch: branch,
      worktrees: [worktree],
      selectedRepositoryPath: "/repo/main"
    )

    XCTAssertEqual(indicator.kind, .current)
    XCTAssertEqual(indicator.systemImage, "checkmark.circle.fill")
    XCTAssertEqual(indicator.helpText, "Current branch")
  }

  func testLinkedWorktreeMatchesFullBranchReference() {
    let branch = GitRef(
      name: "refs/heads/feature/dashboard",
      shortName: "feature/dashboard",
      objectName: "def456",
      isHead: false,
      kind: .localBranch
    )
    let worktree = GitWorktree(
      path: "/repo/worktrees/dashboard",
      head: "def456",
      branch: "refs/heads/feature/dashboard",
      isDetached: false,
      isBare: false,
      isPrunable: false
    )

    let indicator = BranchWorktreeIndicator(
      branch: branch,
      worktrees: [worktree],
      selectedRepositoryPath: "/repo/main"
    )

    XCTAssertEqual(indicator.kind, .linkedWorktree(name: "dashboard", path: "/repo/worktrees/dashboard"))
    XCTAssertEqual(indicator.systemImage, "square.stack.3d.up.fill")
    XCTAssertEqual(indicator.helpText, "Checked out in dashboard\n/repo/worktrees/dashboard")
  }

  func testSelectedRepositoryWorktreeDoesNotMarkAnotherBranchState() {
    let branch = GitRef(
      name: "refs/heads/feature",
      shortName: "feature",
      objectName: "def456",
      isHead: false,
      kind: .localBranch
    )
    let currentRepositoryWorktree = GitWorktree(
      path: "/repo/main",
      head: "def456",
      branch: "refs/heads/feature",
      isDetached: false,
      isBare: false,
      isPrunable: false
    )

    let indicator = BranchWorktreeIndicator(
      branch: branch,
      worktrees: [currentRepositoryWorktree],
      selectedRepositoryPath: "/repo/main"
    )

    XCTAssertEqual(indicator.kind, .available)
    XCTAssertEqual(indicator.systemImage, "circle")
    XCTAssertNil(indicator.helpText)
  }
}
