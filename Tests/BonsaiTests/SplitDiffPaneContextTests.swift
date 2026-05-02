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

  func testWorkingTreeContextUsesNoFileForStagedAddedAndDeletedSides() {
    let added = GitStatusEntry(
      path: "Sources/New.swift",
      originalPath: nil,
      indexStatus: "A",
      workTreeStatus: " ",
      kind: .added
    )
    let deleted = GitStatusEntry(
      path: "Sources/Gone.swift",
      originalPath: nil,
      indexStatus: "D",
      workTreeStatus: " ",
      kind: .deleted
    )

    let addedContext = SplitDiffPaneContext.workingTree(entry: added)
    let deletedContext = SplitDiffPaneContext.workingTree(entry: deleted)

    XCTAssertEqual(addedContext.old.title, "No file")
    XCTAssertNil(addedContext.old.detail)
    XCTAssertEqual(addedContext.new.title, "Index")
    XCTAssertEqual(addedContext.new.detail, "Sources/New.swift")

    XCTAssertEqual(deletedContext.old.title, "HEAD")
    XCTAssertEqual(deletedContext.old.detail, "Sources/Gone.swift")
    XCTAssertEqual(deletedContext.new.title, "No file")
    XCTAssertNil(deletedContext.new.detail)
  }

  func testWorkingTreeContextUsesNoFileForUnstagedDeletedSide() {
    let deleted = GitStatusEntry(
      path: "Sources/Gone.swift",
      originalPath: nil,
      indexStatus: " ",
      workTreeStatus: "D",
      kind: .deleted
    )

    let context = SplitDiffPaneContext.workingTree(entry: deleted)

    XCTAssertEqual(context.old.title, "HEAD")
    XCTAssertEqual(context.old.detail, "Sources/Gone.swift")
    XCTAssertEqual(context.new.title, "No file")
    XCTAssertNil(context.new.detail)
  }

  func testConflictResolutionContextNamesComparedStageAndWorkingTree() {
    let entry = GitStatusEntry(
      path: "Sources/App.swift",
      originalPath: nil,
      indexStatus: "U",
      workTreeStatus: "U",
      kind: .conflicted
    )

    let context = SplitDiffPaneContext.conflictResolution(entry: entry, base: .theirs)

    XCTAssertEqual(context.old.title, "Theirs")
    XCTAssertEqual(context.old.detail, "Sources/App.swift")
    XCTAssertEqual(context.new.title, "Working tree")
    XCTAssertEqual(context.new.detail, "Sources/App.swift")
  }

  func testChangedFileContextKeepsRenamePathContext() {
    let renamed = GitChangedFile(status: "R100", path: "New.swift", oldPath: "Old.swift")

    let renamedContext = SplitDiffPaneContext.changedFile(renamed, oldTitle: "Parent", newTitle: "abc1234")

    XCTAssertEqual(renamedContext.old.detail, "Old.swift")
    XCTAssertEqual(renamedContext.new.detail, "New.swift")
  }

  func testChangedFileContextUsesNoFileForAddedAndDeletedSides() {
    let added = GitChangedFile(status: "A", path: "New.swift", oldPath: nil)
    let deleted = GitChangedFile(status: "D", path: "Gone.swift", oldPath: nil)

    let addedContext = SplitDiffPaneContext.changedFile(added, oldTitle: "Parent", newTitle: "abc1234")
    let deletedContext = SplitDiffPaneContext.changedFile(deleted, oldTitle: "Parent", newTitle: "abc1234")

    XCTAssertEqual(addedContext.old.title, "No file")
    XCTAssertNil(addedContext.old.detail)
    XCTAssertEqual(addedContext.new.title, "abc1234")
    XCTAssertEqual(addedContext.new.detail, "New.swift")

    XCTAssertEqual(deletedContext.old.title, "Parent")
    XCTAssertEqual(deletedContext.old.detail, "Gone.swift")
    XCTAssertEqual(deletedContext.new.title, "No file")
    XCTAssertNil(deletedContext.new.detail)
  }
}
