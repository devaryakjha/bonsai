import XCTest
@testable import Bonsai

final class GitStatusRowActionPolicyTests: XCTestCase {
  func testPrimaryActionStagesNormalUnstagedRows() {
    let entry = GitStatusEntry(
      path: "Sources/App.swift",
      originalPath: nil,
      indexStatus: " ",
      workTreeStatus: "M",
      kind: .modified
    )

    XCTAssertEqual(entry.primaryRowAction, .stage)
    XCTAssertEqual(entry.primaryRowAction.title, "Stage")
    XCTAssertEqual(entry.primaryRowAction.systemImage, "plus.circle")
  }

  func testPrimaryActionUnstagesNormalStagedRows() {
    let entry = GitStatusEntry(
      path: "Sources/App.swift",
      originalPath: nil,
      indexStatus: "M",
      workTreeStatus: " ",
      kind: .modified
    )

    XCTAssertEqual(entry.primaryRowAction, .unstage)
    XCTAssertEqual(entry.primaryRowAction.title, "Unstage")
    XCTAssertEqual(entry.primaryRowAction.systemImage, "minus.circle")
  }

  func testPrimaryActionResolvesConflictedRows() {
    let entry = GitStatusEntry(
      path: "Sources/App.swift",
      originalPath: nil,
      indexStatus: "U",
      workTreeStatus: "U",
      kind: .conflicted
    )

    XCTAssertEqual(entry.primaryRowAction, .resolveConflict)
    XCTAssertEqual(entry.primaryRowAction.title, "Resolve conflict")
    XCTAssertEqual(entry.primaryRowAction.systemImage, "wrench.and.screwdriver")
  }
}
