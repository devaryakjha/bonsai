import XCTest
@testable import Bonsai

final class SplitDiffPaneContextTests: XCTestCase {
  func testWorkingTreeContextDistinguishesUnstagedAndStagedSides() {
    let unstaged = GitStatusEntry(
      path: "Sources/New.swift",
      originalPath: "Sources/Old.swift",
      indexStatus: " ",
      workTreeStatus: "M",
      kind: .modified
    )
    let staged = GitStatusEntry(
      path: "Sources/App.swift",
      originalPath: nil,
      indexStatus: "M",
      workTreeStatus: " ",
      kind: .modified
    )

    let unstagedContext = SplitDiffPaneContext.workingTree(entry: unstaged)
    let stagedContext = SplitDiffPaneContext.workingTree(entry: staged)

    XCTAssertEqual(unstagedContext.old.title, "HEAD")
    XCTAssertEqual(unstagedContext.old.detail, "Sources/Old.swift")
    XCTAssertEqual(unstagedContext.new.title, "Working tree")
    XCTAssertEqual(unstagedContext.new.detail, "Sources/New.swift")
    XCTAssertEqual(stagedContext.old.title, "HEAD")
    XCTAssertEqual(stagedContext.old.detail, "Sources/App.swift")
    XCTAssertEqual(stagedContext.new.title, "Index")
    XCTAssertEqual(stagedContext.new.detail, "Sources/App.swift")
  }

  func testWorkingTreeContextUsesNoFileForUntrackedOldSide() {
    let entry = GitStatusEntry(
      path: "Notes/todo.txt",
      originalPath: nil,
      indexStatus: "?",
      workTreeStatus: "?",
      kind: .untracked
    )

    let context = SplitDiffPaneContext.workingTree(entry: entry)

    XCTAssertEqual(context.old.title, "No file")
    XCTAssertNil(context.old.detail)
    XCTAssertEqual(context.new.title, "Working tree")
    XCTAssertEqual(context.new.detail, "Notes/todo.txt")
  }

  func testChangedFileContextKeepsRenameAndDeletionPathContext() {
    let renamed = GitChangedFile(status: "R100", path: "New.swift", oldPath: "Old.swift")
    let deleted = GitChangedFile(status: "D", path: "Gone.swift", oldPath: nil)

    let renamedContext = SplitDiffPaneContext.changedFile(renamed, oldTitle: "Parent", newTitle: "abc1234")
    let deletedContext = SplitDiffPaneContext.changedFile(deleted, oldTitle: "Parent", newTitle: "abc1234")

    XCTAssertEqual(renamedContext.old.detail, "Old.swift")
    XCTAssertEqual(renamedContext.new.detail, "New.swift")
    XCTAssertEqual(deletedContext.old.detail, "Gone.swift")
    XCTAssertNil(deletedContext.new.detail)
  }
}
