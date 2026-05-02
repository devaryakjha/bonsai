import XCTest
@testable import Bonsai

final class DiffInlineHighlighterTests: XCTestCase {
  func testChangedRangesTrimCommonPrefixAndSuffix() throws {
    let old = "let title = \"Fork\""
    let new = "let title = \"Bonsai\""
    let ranges = DiffInlineHighlighter.changedRanges(
      old: old,
      new: new
    )

    let oldRange = try XCTUnwrap(ranges.oldRange)
    let newRange = try XCTUnwrap(ranges.newRange)
    XCTAssertEqual(String(old[oldRange]), "Fork")
    XCTAssertEqual(String(new[newRange]), "Bonsai")
  }

  func testChangedRangesHandleInsertedToken() throws {
    let old = "git checkout branch"
    let new = "git checkout --track branch"
    let ranges = DiffInlineHighlighter.changedRanges(
      old: old,
      new: new
    )

    XCTAssertNil(ranges.oldRange)
    let newRange = try XCTUnwrap(ranges.newRange)
    XCTAssertEqual(String(new[newRange]), "--track ")
  }
}
