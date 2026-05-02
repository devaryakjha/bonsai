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
    XCTAssertFalse(store.splitDiff.oldText.contains("-two"))
    XCTAssertTrue(store.splitDiff.newText.contains("+two"))

    store.diffText = ""

    XCTAssertTrue(store.diffHunks.isEmpty)
    XCTAssertTrue(store.diffLineChanges.isEmpty)
    XCTAssertTrue(store.splitDiff.oldLines.isEmpty)
    XCTAssertTrue(store.splitDiff.newLines.isEmpty)
  }
}
