import XCTest
@testable import Bonsai

final class DiffSearchTests: XCTestCase {
  func testDiffSearchMatchesCaseInsensitively() {
    let text = """
    @@ -1,2 +1,2 @@
    -let value = oldName
    +let value = NewName
    +let other = newname
    """

    XCTAssertEqual(DiffSearch.matchCount(in: text, query: "newname"), 2)
    XCTAssertEqual(DiffSearch.ranges(in: text, query: "NEWNAME").count, 2)
  }

  func testDiffSearchIgnoresEmptyQueries() {
    XCTAssertEqual(DiffSearch.normalizedQuery("  \n "), "")
    XCTAssertEqual(DiffSearch.matchCount(in: "abc abc", query: " "), 0)
    XCTAssertTrue(DiffSearch.ranges(in: "abc", query: "").isEmpty)
    XCTAssertNil(DiffSearch.matchLabel(for: 0, query: " "))
  }

  func testDiffSearchLabelsMatchesAndNoMatches() {
    XCTAssertEqual(DiffSearch.matchLabel(for: 0, query: "needle"), "No matches")
    XCTAssertEqual(DiffSearch.matchLabel(for: 1, query: "needle"), "1 match")
    XCTAssertEqual(DiffSearch.matchLabel(for: 2, query: "needle"), "2 matches")
  }

  func testDiffSearchRangeLimitBoundsWork() {
    XCTAssertEqual(DiffSearch.ranges(in: "abc abc abc", query: "abc", limit: 2).count, 2)
  }

  func testVisibleUnifiedTextSkipsHiddenPatchMetadata() {
    let text = """
    diff --git a/App.swift b/App.swift
    index abc..def 100644
    --- a/App.swift
    +++ b/App.swift
    @@ -1 +1 @@
    -old
    +new
    """

    XCTAssertFalse(DiffSearch.visibleUnifiedText(from: text).contains("diff --git"))
    XCTAssertTrue(DiffSearch.visibleUnifiedText(from: text).contains("+new"))
  }

  func testVisibleSplitTextUsesDisplayedLineContent() {
    let split = SplitDiff(
      oldLines: [
        SplitDiffLine(number: 1, text: "-old value")
      ],
      newLines: [
        SplitDiffLine(number: 1, text: "+new value")
      ]
    )

    XCTAssertEqual(DiffSearch.matchCount(in: DiffSearch.visibleSplitText(from: split), query: "value"), 2)
    XCTAssertEqual(DiffSearch.matchCount(in: DiffSearch.visibleSplitText(from: split), query: "1"), 0)
  }
}
