import XCTest
@testable import Bonsai

@MainActor
final class DiffParseCacheTests: XCTestCase {
  func testDiffParseArtifactsUpdateWhenDiffTextChanges() {
    let store = RepositoryStore()

    store.diffText = """
    diff --git a/file.txt b/file.txt
    index 1111111..2222222 100644
    --- a/file.txt
    +++ b/file.txt
    @@ -1,2 +1,2 @@
     one
    -two
    +deux
    """

    XCTAssertEqual(store.diffHunks.count, 1)
    XCTAssertEqual(store.diffLineChanges.count, 1)
    XCTAssertEqual(store.diffSummary?.additions, 1)
    XCTAssertEqual(store.diffSummary?.deletions, 1)
    XCTAssertEqual(store.diffSummary?.hunkCount, 1)
    XCTAssertEqual(store.diffRenderVersion, 1)
    XCTAssertTrue(store.splitDiff.oldText.contains("-two"))

    store.diffText = """
    diff --git a/file.txt b/file.txt
    index 2222222..3333333 100644
    --- a/file.txt
    +++ b/file.txt
    @@ -1,1 +1,2 @@
     one
    +two
    """

    XCTAssertEqual(store.diffHunks.count, 1)
    XCTAssertEqual(store.diffLineChanges.first?.kind, .addition)
    XCTAssertEqual(store.diffSummary?.additions, 1)
    XCTAssertEqual(store.diffSummary?.deletions, 0)
    XCTAssertEqual(store.diffRenderVersion, 2)
    XCTAssertFalse(store.splitDiff.oldText.contains("-two"))
    XCTAssertTrue(store.splitDiff.newText.contains("+two"))

    store.diffText = ""

    XCTAssertTrue(store.diffHunks.isEmpty)
    XCTAssertTrue(store.diffLineChanges.isEmpty)
    XCTAssertTrue(store.splitDiff.oldLines.isEmpty)
    XCTAssertTrue(store.splitDiff.newLines.isEmpty)
    XCTAssertNil(store.diffSummary)
    XCTAssertEqual(store.diffRenderVersion, 3)
  }

  func testLargeDiffParseCacheKeepsHunksAndSplitButSkipsLineChangeActions() {
    let store = RepositoryStore()
    let addedLines = (0...DiffRenderPolicy.maxLineChangeActionLineCount)
      .map { "+line \($0)" }
      .joined(separator: "\n")

    store.diffText = """
    diff --git a/file.txt b/file.txt
    index 1111111..2222222 100644
    --- a/file.txt
    +++ b/file.txt
    @@ -1,0 +1,\(DiffRenderPolicy.maxLineChangeActionLineCount + 1) @@
    \(addedLines)
    """

    XCTAssertEqual(store.diffHunks.count, 1)
    XCTAssertTrue(store.diffLineChanges.isEmpty)
    XCTAssertEqual(store.splitDiff.newLines.filter { $0.text.hasPrefix("+line") }.count, DiffRenderPolicy.maxLineChangeActionLineCount + 1)
  }
}
